import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Unsigned upload — only Cloud Name + Upload Preset needed (no secret exposed)
  static const String _cloudName = 'dbztfelok';
  static const String _uploadPreset = 'HealthSnap';
  // For signed delete — fill from Cloudinary Dashboard → Settings → Access Keys
  static const String _apiKey = '578355662348789';
  static const String _apiSecret = '0yLWZAPl7zzRSLURrcWA5g2AnSE';

  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Uploads [imageFile] to Cloudinary and returns the secure URL.
  /// Throws an Exception on failure.
  static Future<String> uploadImage(File imageFile) async {
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

    request.fields['upload_preset'] = _uploadPreset;
    request.fields['folder'] = 'medical_documents';
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary returned no URL');
    }
    return url;
  }

  /// Deletes an image from Cloudinary by its secure URL.
  /// Silently does nothing if URL is empty or public_id cannot be extracted.
  static Future<void> deleteImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    final publicId = _extractPublicId(imageUrl);
    if (publicId == null) return;

    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final toSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    final signature =
        sha1.convert(utf8.encode(toSign)).toString();

    await http.post(
      Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
      body: {
        'public_id': publicId,
        'timestamp': timestamp,
        'api_key': _apiKey,
        'signature': signature,
      },
    );
  }

  /// Extracts Cloudinary public_id from a secure URL.
  /// e.g. https://res.cloudinary.com/cloud/image/upload/v123/folder/file.jpg → folder/file
  static String? _extractPublicId(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final uploadIdx = segments.indexOf('upload');
      if (uploadIdx == -1) return null;
      final rest = segments.sublist(uploadIdx + 1);
      // Skip version segment (e.g. v1234567890)
      final withoutVersion = rest.isNotEmpty &&
              RegExp(r'^v\d+$').hasMatch(rest[0])
          ? rest.sublist(1)
          : rest;
      final joined = withoutVersion.join('/');
      final dotIdx = joined.lastIndexOf('.');
      return dotIdx != -1 ? joined.substring(0, dotIdx) : joined;
    } catch (_) {
      return null;
    }
  }
}
