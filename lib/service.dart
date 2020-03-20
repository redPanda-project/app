import 'dart:async';
import 'dart:core';

import 'package:sentry/sentry.dart';

class Service {
  static final SentryClient sentry =
      new SentryClient(dsn: "https://5ab6bb5e18a84fc1934b438139cc13d1@sentry.io/3871436");

  // Methods for Sentry
  static bool get isInDebugMode {
    // Assume you're in production mode.
    bool inDebugMode = false;

    // Assert expressions are only evaluated during development. They are ignored
    // in production. Therefore, this code only sets `inDebugMode` to true
    // in a development environment.
    assert(inDebugMode = true);

    return inDebugMode;
  }

  static Future<void> reportError(dynamic error, dynamic stackTrace) async {
    // Print the exception to the console.
    print('Caught error: $error');
    if (isInDebugMode) {
      // Print the full stacktrace in debug mode.
      print(stackTrace);
      return;
    } else {
      // Send the Exception and Stacktrace to Sentry in Production mode.
      Service.sentry.captureException(
        exception: error,
        stackTrace: stackTrace,
      );
    }
  }
}
