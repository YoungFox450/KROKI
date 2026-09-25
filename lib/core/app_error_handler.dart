import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppErrorHandler {
  static void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      developer.log('Flutter error', error: details.exception, stackTrace: details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      developer.log('Unhandled async error', error: error, stackTrace: stack);
      return true;
    };
  }

  static Widget errorScreen(Object error, StackTrace stack) {
    developer.log('Widget build error', error: error, stackTrace: stack);
    return const Material(
      child: Center(child: Text('Une erreur inattendue est survenue.')),
    );
  }
}
