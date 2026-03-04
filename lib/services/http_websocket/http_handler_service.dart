import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class HttpHandlerService {
  /*
  A utility service to handle HTTP requests across the app. It uses the dio package to provide a simple interface for making GET, POST, PUT, and DELETE requests. It also includes methods for upload and downloading files. The service is designed to be reusable and can be easily extended to include additional functionality such as interceptors, error handling, or custom headers.
   */
  final Dio _dio = Dio();

  Future<Response> get(String url) async {
    try {
      return await _dio.get(url);
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }
  }

  Future<Response> post(String url, {dynamic data}) async {
    try {
      return await _dio.post(url, data: data);
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }
  }

  Future<Response> put(String url, {dynamic data}) async {
    try {
      return await _dio.put(url, data: data);
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }
  }

  Future<Response> delete(String url) async {
    try {
      return await _dio.delete(url);
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }
  }

  Future<Response> uploadFile(String url, String filePath) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      return await _dio.post(url, data: formData);
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }
  }

  Future<Response> downloadFile(String url, String savePath) async {
    try {
      return await _dio.download(url, savePath);
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }
  }
}

final httpHandlerService = HttpHandlerService();
