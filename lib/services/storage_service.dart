import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:go_study/services/course_material.dart';

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

  /// Download and encrypt a file, caching the display metadata (title,
  /// file type, category) alongside it — that cache is what lets
  /// [getOfflineMaterials] list this material later without any network
  /// access, instead of the Offline Library having to re-fetch it from
  /// Supabase (which fails with no internet) just to know what to show.
  Future<void> downloadAndEncrypt(String url, CourseMaterial material) async {
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
    final file = File('${offlineDir.path}/${material.id}.enc');
    final combined = Uint8List.fromList(iv.bytes + encrypted.bytes);
    await file.writeAsBytes(combined);

    await _storage.write(
      key: 'meta_${material.id}',
      value: jsonEncode({
        'fileName': material.fileName,
        'title': material.title,
        'fileType': material.fileType,
        'materialCategory': material.materialCategory,
      }),
    );
  }

  /// The filename cached by [downloadAndEncrypt] for [materialId], tolerant
  /// of the old cache format (a bare filename string, from before metadata
  /// was cached as JSON) for files downloaded before this change.
  Future<String> _readCachedFileName(String materialId) async {
    final raw = await _storage.read(key: 'meta_$materialId');
    if (raw == null) return 'material.pdf';
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map['fileName'] as String? ?? 'material.pdf';
    } catch (_) {
      return raw; // Legacy format: the raw value was the filename itself.
    }
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
    final fileName = await _readCachedFileName(materialId);
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

  /// Every locally-downloaded material, built entirely from the metadata
  /// [downloadAndEncrypt] cached on-device — no network access, so this
  /// works with no internet connection (unlike fetching the same details
  /// via DatabaseService.getMaterialsByIds, which needs Supabase). A file
  /// downloaded before metadata caching existed still lists, with a
  /// best-effort title/type guessed from its cached bare filename.
  Future<List<CourseMaterial>> getOfflineMaterials() async {
    final ids = await getOfflineMaterialIds();
    final materials = <CourseMaterial>[];
    for (final id in ids) {
      final raw = await _storage.read(key: 'meta_$id');
      Map<String, dynamic>? meta;
      if (raw != null) {
        try {
          meta = jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {
          meta = null; // Legacy format: raw is a bare filename, not JSON.
        }
      }
      materials.add(
        CourseMaterial(
          id: id,
          title: (meta?['title'] as String?) ?? raw ?? id,
          fileUrl: '', // Never dereferenced offline — see decryptAndGetFile.
          fileName: (meta?['fileName'] as String?) ?? raw ?? 'material.pdf',
          fileType: (meta?['fileType'] as String?) ?? 'pdf',
          uploadedAt: DateTime.now(),
          materialCategory: (meta?['materialCategory'] as String?) ?? 'regular',
        ),
      );
    }
    return materials;
  }
}
