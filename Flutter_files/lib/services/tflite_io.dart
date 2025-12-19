// IO implementation for non-web platforms
// This file is used when compiling for mobile/desktop platforms

import 'package:tflite_flutter/tflite_flutter.dart';

Future<Interpreter> loadInterpreter(String modelPath) async {
  return await Interpreter.fromAsset(modelPath);
}

void runInference(Interpreter interpreter, dynamic input, dynamic output) {
  interpreter.run(input, output);
}

void closeInterpreter(Interpreter interpreter) {
  interpreter.close();
}

