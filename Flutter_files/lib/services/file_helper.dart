// File helper for non-web platforms
// This file is only imported on non-web platforms

import 'dart:io' as io;
import 'dart:typed_data';

class FileHelper {
  static Future<Uint8List> readFileAsBytes(String path) async {
    final file = io.File(path);
    return await file.readAsBytes();
  }
  
  static Future<io.File> copyFile(io.File source, String destination) async {
    return await source.copy(destination);
  }
  
  static io.File createFile(String path) {
    return io.File(path);
  }
}

