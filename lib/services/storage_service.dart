import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _keyAlias = 'ub_hub_encryption_key';

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Get or create an encryption key
  Future<encrypt.Key> _getEncryptionKey() async {
    String? keyStr = await _storage.read(key: _keyAlias);
    if (keyStr == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      await _storage.write(key: _keyAlias, value: key.base64);
      return key;
    }
    return encrypt.Key.fromBase64(keyStr);
  }

  /// Download and encrypt a file
  Future<void> downloadAndEncrypt(
    String url,
    String materialId,
    String fileName,
  ) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) throw Exception("Failed to download file");

    final key = await _getEncryptionKey();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encryptBytes(response.bodyBytes, iv: iv);

    final directory = await getApplicationDocumentsDirectory();
    final offlineDir = Directory('${directory.path}/offline_materials');
    if (!await offlineDir.exists()) await offlineDir.create();

    // Store IV separately or prepend to file. We'll prepend for simplicity.
    final file = File('${offlineDir.path}/$materialId.enc');
    final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);
    await file.writeAsBytes(combined);

    // Also save metadata (like original filename) in secure storage or simple JSON
    await _storage.write(key: 'meta_$materialId', value: fileName);
  }

  /// Decrypt and get a temporary file for viewing
  Future<File> decryptAndGetFile(String materialId) async {
    final directory = await getApplicationDocumentsDirectory();
    final encryptedFile = File(
      '${directory.path}/offline_materials/$materialId.enc',
    );
    if (!await encryptedFile.exists()) {
      throw Exception("File not found offline");
    }

    final combined = await encryptedFile.readAsBytes();
    final iv = encrypt.IV(combined.sublist(0, 16));
    final encryptedBytes = combined.sublist(16);

    final key = await _getEncryptionKey();
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final decrypted = encrypter.decryptBytes(
      encrypt.Encrypted(encryptedBytes),
      iv: iv,
    );

    final tempDir = await getTemporaryDirectory();
    final fileName =
        await _storage.read(key: 'meta_$materialId') ?? 'material.pdf';
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(decrypted);

    return tempFile;
  }

  /// Check if a material is available offline
  Future<bool> isDownloaded(String materialId) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/offline_materials/$materialId.enc').exists();
  }

  /// Remove an offline material
  Future<void> deleteOffline(String materialId) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/offline_materials/$materialId.enc');
    if (await file.exists()) await file.delete();
    await _storage.delete(key: 'meta_$materialId');
  }

  /// Get list of all offline material IDs
  Future<List<String>> getOfflineMaterialIds() async {
    final directory = await getApplicationDocumentsDirectory();
    final offlineDir = Directory('${directory.path}/offline_materials');
    if (!await offlineDir.exists()) return [];

    return offlineDir
        .listSync()
        .whereType<File>()
        .map((f) => f.path.split('/').last.replaceAll('.enc', ''))
        .toList();
  }
}
