// Stub file for web platform - tflite_flutter is not available on web
// This file is used when compiling for web

dynamic loadInterpreter(String modelPath) {
  throw UnsupportedError('TensorFlow Lite is not supported on web platform');
}

void runInference(dynamic interpreter, dynamic input, dynamic output) {
  throw UnsupportedError('TensorFlow Lite is not supported on web platform');
}

void closeInterpreter(dynamic interpreter) {
  // No-op for web
}

