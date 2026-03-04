import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Enum for WebSocket connection states
enum WebSocketStatus {
  connecting,
  connected,
  disconnected,
  error,
  reconnecting,
}

/// Configuration class for WebSocket connection
class WebSocketConfig {
  final String url;
  final Duration pingInterval;
  final Duration connectionTimeout;
  final int maxReconnectAttempts;
  final Duration reconnectDelay;
  final Map<String, dynamic>? headers;
  final Iterable<String>? protocols;

  const WebSocketConfig({
    required this.url,
    this.pingInterval = const Duration(seconds: 30),
    this.connectionTimeout = const Duration(seconds: 10),
    this.maxReconnectAttempts = 5,
    this.reconnectDelay = const Duration(seconds: 3),
    this.headers,
    this.protocols,
  });
}

class WebSocketService {
  /*
Utility class to handle all the websocket functionality and others to be expected. The complexity of webscoket will be reduced while using this service by just calling either functions
  */
  WebSocketService(this.config);

  final WebSocketConfig config;

  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer? _connectionTimeoutTimer;

  int _reconnectAttempts = 0;
  bool _isManualDisconnect = false;
  bool _isDisposed = false;

  // Stream controllers
  final _statusController = StreamController<WebSocketStatus>.broadcast();
  final _messageController = StreamController<dynamic>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Public streams
  Stream<WebSocketStatus> get statusStream => _statusController.stream;
  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Current status
  WebSocketStatus _currentStatus = WebSocketStatus.disconnected;
  WebSocketStatus get status => _currentStatus;
  bool get isConnected => _currentStatus == WebSocketStatus.connected;

  /// Connect to the WebSocket server
  Future<void> connect() async {
    if (_isDisposed) {
      debugPrint('WebSocket: Cannot connect - service is disposed');
      return;
    }

    if (_channel != null && isConnected) {
      debugPrint('WebSocket: Already connected');
      return;
    }

    _isManualDisconnect = false;
    _updateStatus(WebSocketStatus.connecting);

    try {
      debugPrint('WebSocket: Connecting to ${config.url}');

      // Create WebSocket channel
      _channel = WebSocketChannel.connect(
        Uri.parse(config.url),
        protocols: config.protocols,
      );

      // Start connection timeout
      _startConnectionTimeout();

      // Listen to the channel stream
      _listenToMessages();
    } catch (e) {
      _handleConnectionError('Connection error: $e');
    }
  }

  /// Disconnect from the WebSocket server
  Future<void> disconnect() async {
    debugPrint('WebSocket: Disconnecting');
    _isManualDisconnect = true;
    _reconnectAttempts = 0;

    _cancelTimers();
    _cancelMessageSubscription();

    if (_channel != null) {
      try {
        await _channel?.sink.close(status.goingAway);
      } catch (e) {
        debugPrint('WebSocket: Error closing channel: $e');
      }
      _channel = null;
    }

    _updateStatus(WebSocketStatus.disconnected);
  }

  /// Send a message to the WebSocket server
  void send(dynamic message) {
    if (_isDisposed) {
      debugPrint('WebSocket: Cannot send - service is disposed');
      return;
    }

    if (!isConnected || _channel == null) {
      final error = 'Cannot send message: WebSocket not connected';
      debugPrint('WebSocket: $error');
      _errorController.add(error);
      return;
    }

    try {
      if (message is String) {
        _channel!.sink.add(message);
        debugPrint('WebSocket: Sent text message: $message');
      } else if (message is Map || message is List) {
        final jsonMessage = jsonEncode(message);
        _channel!.sink.add(jsonMessage);
        debugPrint('WebSocket: Sent JSON message: $jsonMessage');
      } else if (message is List<int>) {
        _channel!.sink.add(message);
        debugPrint('WebSocket: Sent binary message');
      } else {
        throw ArgumentError('Unsupported message type: ${message.runtimeType}');
      }
    } catch (e) {
      final error = 'Failed to send message: $e';
      debugPrint('WebSocket: $error');
      _errorController.add(error);
    }
  }

  /// Send a JSON message
  void sendJson(Map<String, dynamic> json) {
    send(jsonEncode(json));
  }

  /// Send a text message
  void sendText(String text) {
    send(text);
  }

  /// Send binary data
  void sendBinary(List<int> data) {
    send(data);
  }

  /// Listen to incoming messages from the channel
  void _listenToMessages() {
    _messageSubscription?.cancel();

    _messageSubscription = _channel?.stream.listen(
      (dynamic data) {
        // Cancel connection timeout on first message
        _connectionTimeoutTimer?.cancel();

        // Update status to connected if not already
        if (_currentStatus != WebSocketStatus.connected) {
          debugPrint('WebSocket: Connected successfully');
          _reconnectAttempts = 0;
          _updateStatus(WebSocketStatus.connected);
          _startPingTimer();
        }

        _handleIncomingMessage(data);
      },
      onError: (error) {
        final errorMsg = 'WebSocket stream error: $error';
        debugPrint('WebSocket: $errorMsg');
        _errorController.add(errorMsg);
        _handleConnectionError(errorMsg);
      },
      onDone: () {
        debugPrint('WebSocket: Connection closed');
        _handleDisconnection();
      },
      cancelOnError: false,
    );
  }

  /// Handle incoming messages
  void _handleIncomingMessage(dynamic data) {
    try {
      if (data is String) {
        debugPrint('WebSocket: Received text message: $data');

        // Ignore ping/pong messages
        if (data.toLowerCase() == 'ping' || data.toLowerCase() == 'pong') {
          debugPrint('WebSocket: Received ping/pong');
          return;
        }

        // Try to parse as JSON
        try {
          final jsonData = jsonDecode(data);
          _messageController.add(jsonData);
        } catch (_) {
          // Not JSON, send as plain text
          _messageController.add(data);
        }
      } else if (data is List<int>) {
        debugPrint('WebSocket: Received binary message');
        _messageController.add(data);
      } else {
        debugPrint('WebSocket: Received unknown message type');
        _messageController.add(data);
      }
    } catch (e) {
      final error = 'Error handling message: $e';
      debugPrint('WebSocket: $error');
      _errorController.add(error);
    }
  }

  /// Handle connection errors
  void _handleConnectionError(String error) {
    debugPrint('WebSocket: Error - $error');
    _updateStatus(WebSocketStatus.error);
    _errorController.add(error);

    _cancelTimers();
    _cancelMessageSubscription();

    if (!_isManualDisconnect && !_isDisposed) {
      _attemptReconnect();
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    _cancelTimers();
    _cancelMessageSubscription();
    _channel = null;

    if (!_isManualDisconnect && !_isDisposed) {
      _updateStatus(WebSocketStatus.disconnected);
      _attemptReconnect();
    } else {
      _updateStatus(WebSocketStatus.disconnected);
    }
  }

  /// Attempt to reconnect
  void _attemptReconnect() {
    if (_isDisposed) {
      return;
    }

    if (_reconnectAttempts >= config.maxReconnectAttempts) {
      final error =
          'Max reconnection attempts (${config.maxReconnectAttempts}) reached';
      debugPrint('WebSocket: $error');
      _errorController.add(error);
      _updateStatus(WebSocketStatus.disconnected);
      return;
    }

    _reconnectAttempts++;
    _updateStatus(WebSocketStatus.reconnecting);

    debugPrint(
      'WebSocket: Reconnecting (attempt $_reconnectAttempts/${config.maxReconnectAttempts})',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(config.reconnectDelay, () {
      if (!_isDisposed) {
        connect();
      }
    });
  }

  /// Start connection timeout timer
  void _startConnectionTimeout() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(config.connectionTimeout, () {
      if (_currentStatus == WebSocketStatus.connecting) {
        _handleConnectionError('Connection timeout');
      }
    });
  }

  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(config.pingInterval, (timer) {
      if (isConnected && _channel != null) {
        try {
          _channel!.sink.add('ping');
          debugPrint('WebSocket: Ping sent');
        } catch (e) {
          debugPrint('WebSocket: Ping failed - $e');
          _handleConnectionError('Ping failed: $e');
        }
      }
    });
  }

  /// Cancel message subscription
  void _cancelMessageSubscription() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
  }

  /// Cancel all timers
  void _cancelTimers() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
  }

  /// Update connection status
  void _updateStatus(WebSocketStatus status) {
    if (_isDisposed) return;

    _currentStatus = status;
    _statusController.add(status);
    debugPrint('WebSocket: Status changed to $status');
  }

  /// Reset reconnection attempts
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
    debugPrint('WebSocket: Reconnection attempts reset');
  }

  /// Get current reconnection attempt count
  int get reconnectAttempts => _reconnectAttempts;

  /// Manually trigger reconnection
  Future<void> reconnect() async {
    debugPrint('WebSocket: Manual reconnection triggered');
    await disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    await connect();
  }

  /// Check if service is disposed
  bool get isDisposed => _isDisposed;

  /// Dispose of the service and clean up resources
  void dispose() {
    if (_isDisposed) {
      return;
    }

    debugPrint('WebSocket: Disposing service');
    _isDisposed = true;
    _isManualDisconnect = true;

    _cancelTimers();
    _cancelMessageSubscription();

    _channel?.sink.close(status.goingAway);
    _channel = null;

    _statusController.close();
    _messageController.close();
    _errorController.close();
  }
}
