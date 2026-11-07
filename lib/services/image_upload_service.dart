import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

class ImageUploadService {
  const ImageUploadService(this._dio);

  final Dio _dio;

  Future<String?> uploadImage({
    required String localPath,
    required String apiKey,
  }) async {
    if (localPath.isEmpty || apiKey.isEmpty) return null;

    final bytes = await File(localPath).readAsBytes();
    final encoded = base64Encode(bytes);

    final response = await _dio.post<Map<String, dynamic>>(
      'https://api.imgbb.com/1/upload',
      data: FormData.fromMap({
        'key': apiKey,
        'image': encoded,
      }),
    );

    final data = response.data?['data'] as Map<String, dynamic>?;
    return data?['url'] as String?;
  }
}
