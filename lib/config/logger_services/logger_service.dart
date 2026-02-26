part of '../get_it.dart';


abstract class LoggerService {
  void log(String message);

  void info(String message, [Object? error, StackTrace? stackTrace]);

  void verbose(String message, [Object? error, StackTrace? stackTrace]);

  void warning(String message, [Object? error, StackTrace? stackTrace]);

  void handle(Object exception, [StackTrace? stackTrace]);

  void error(String message, [Object? error, StackTrace? stackTrace]);

  void debug(String message, [Object? error, StackTrace? stackTrace]);

  void success(String message, [Object? error, StackTrace? stackTrace]);

}

class LoggerServiceDevelop extends LoggerService {
  LoggerServiceDevelop() {
    _logger = TalkerFlutter.init(
    );
    Bloc.observer = TalkerBlocObserver(
      settings: const TalkerBlocLoggerSettings(
        printChanges: true,
        printClosings: true,
        printCreations: true,
        printTransitions: false,
      ),
    );
    FlutterError.onError = (errorDetails) {
      _logger.error(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _logger.error(error, stack);
      return true;
    };
  }

  late Talker _logger;

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.info(message, error, stackTrace);
  }

  @override
  void log(String message) {
    _logger.log(message);
  }

  @override
  void verbose(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.verbose(message, error, stackTrace);
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning(message, error, stackTrace);
  }

  @override
  void handle(Object exception, [StackTrace? stackTrace]) {
    _logger.handle(exception, stackTrace);
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.error(message, error, stackTrace);
  }

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.debug(message, error, stackTrace);
  }

  @override
  void success(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.logCustom(
      TalkerSuccessLog(
        message,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

}