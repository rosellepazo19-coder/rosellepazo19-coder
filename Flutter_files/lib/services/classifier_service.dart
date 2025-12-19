import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

// Conditional import for tflite_flutter (not available on web)
import 'tflite_stub.dart'
    if (dart.library.io) 'tflite_io.dart' as tflite;

// Conditional import for file operations
import 'file_helper_stub.dart'
    if (dart.library.io) 'file_helper.dart' as file_helper;

class ClassifierResult {
  final String label;
  final double confidence;
  final int index;
  final List<LabelScore> distribution;

  ClassifierResult({
    required this.label,
    required this.confidence,
    required this.index,
    required this.distribution,
  });
}

class LabelScore {
  final String label;
  final double confidence; // 0-1 normalized
  final int index;

  LabelScore({
    required this.label,
    required this.confidence,
    required this.index,
  });
}

class ClassifierService {
  static const String modelPath = 'assets/model_unquant.tflite';
  static const String labelsPath = 'assets/labels.txt';
  static const int inputSize = 224;

  dynamic _interpreter; // Use dynamic to avoid type errors on web
  List<String> _labels = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  List<String> get labels => _labels;

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      // Web platform - ML not supported
      _isInitialized = true;
      _labels = ['Web Platform - ML Not Supported'];
      print('Classifier initialized (web mode - ML disabled)');
      return;
    }

    try {
      // Load model
      _interpreter = await tflite.loadInterpreter(modelPath);
      
      // Load labels
      final labelsData = await rootBundle.loadString(labelsPath);
      _labels = labelsData
          .split('\n')
          .where((line) => line.isNotEmpty)
          .map((line) {
            // Remove the index prefix (e.g., "0 Aluminum Can" -> "Aluminum Can")
            final parts = line.split(' ');
            if (parts.length > 1) {
              return parts.sublist(1).join(' ');
            }
            return line;
          })
          .toList();

      _isInitialized = true;
      print('Classifier initialized with ${_labels.length} labels');
    } catch (e) {
      print('Error initializing classifier: $e');
      rethrow;
    }
  }

  Future<ClassifierResult?> classifyImage(dynamic imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (kIsWeb) {
      return ClassifierResult(
        label: 'ML Not Available on Web',
        confidence: 0.0,
        index: 0,
        distribution: [
          LabelScore(label: 'ML Not Available on Web', confidence: 0.0, index: 0),
        ],
      );
    }

    if (_interpreter == null) {
      return null;
    }

    try {
      // Read and preprocess image
      // On non-web, imageFile should be a dart:io File
      Uint8List imageBytes;
      if (imageFile is String) {
        // If it's a path string, read it using file helper
        imageBytes = await file_helper.FileHelper.readFileAsBytes(imageFile);
      } else {
        // For other types, try to extract bytes
        throw Exception('Invalid file type - expected String path');
      }
      
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image to model input size
      final resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
      );

      // Convert to input tensor
      final input = _imageToByteListFloat32(resizedImage);

      // Prepare output tensor
      final output = [List.filled(_labels.length, 0.0)];

      // Run inference
      tflite.runInference(_interpreter, input, output);

      // Find the label with highest confidence
      final outputList = output[0] as List<double>;
      final normalized = _normalizeScores(outputList);
      final scores = List<LabelScore>.generate(
        _labels.length,
        (i) => LabelScore(
          label: _labels[i],
          confidence: normalized[i],
          index: i,
        ),
      )..sort((a, b) => b.confidence.compareTo(a.confidence));

      final top = scores.first;

      return ClassifierResult(
        label: top.label,
        confidence: top.confidence,
        index: top.index,
        distribution: scores,
      );
    } catch (e) {
      print('Error classifying image: $e');
      return null;
    }
  }

  Future<ClassifierResult?> classifyBytes(Uint8List imageBytes) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (kIsWeb) {
      return ClassifierResult(
        label: 'ML Not Available on Web',
        confidence: 0.0,
        index: 0,
        distribution: [
          LabelScore(label: 'ML Not Available on Web', confidence: 0.0, index: 0),
        ],
      );
    }

    if (_interpreter == null) {
      return null;
    }

    try {
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image to model input size
      final resizedImage = img.copyResize(
        image,
        width: inputSize,
        height: inputSize,
      );

      // Convert to input tensor
      final input = _imageToByteListFloat32(resizedImage);

      // Prepare output tensor
      final output = [List.filled(_labels.length, 0.0)];

      // Run inference
      tflite.runInference(_interpreter, input, output);

      // Find the label with highest confidence
      final outputList = output[0] as List<double>;
      final normalized = _normalizeScores(outputList);
      final scores = List<LabelScore>.generate(
        _labels.length,
        (i) => LabelScore(
          label: _labels[i],
          confidence: normalized[i],
          index: i,
        ),
      )..sort((a, b) => b.confidence.compareTo(a.confidence));

      final top = scores.first;

      return ClassifierResult(
        label: top.label,
        confidence: top.confidence,
        index: top.index,
        distribution: scores,
      );
    } catch (e) {
      print('Error classifying image bytes: $e');
      return null;
    }
  }

  List<double> _normalizeScores(List<double> scores) {
    final sum = scores.fold<double>(0.0, (p, c) => p + c.abs());
    if (sum == 0) {
      // Avoid divide-by-zero; fallback to even distribution
      final fallback = 1.0 / scores.length;
      return List.filled(scores.length, fallback);
    }
    return scores.map((s) => s.abs() / sum).toList();
  }

  List<List<List<List<double>>>> _imageToByteListFloat32(img.Image image) {
    final convertedBytes = List.generate(
      1,
      (batch) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
    return convertedBytes;
  }

  void dispose() {
    if (!kIsWeb && _interpreter != null) {
      tflite.closeInterpreter(_interpreter);
    }
    _isInitialized = false;
  }
}

