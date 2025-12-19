// Stub file for web platform
// This file is used when compiling for web

import 'dart:typed_data';

class FileHelper {
  static Future<Uint8List> readFileAsBytes(String path) async {
    throw UnsupportedError('File operations not supported on web');
  }
  
  static Future<String> copyFile(dynamic source, String destination) async {
    throw UnsupportedError('File operations not supported on web');
  }
  
  static dynamic createFile(String path) {
    throw UnsupportedError('File operations not supported on web');
  }
}

