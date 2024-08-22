import 'package:lightstreamer_flutter_client/src/logger.dart';

var channelLogger = LogManager.getLogger('lightstreamer.flutter');

class LogManager {
  static final Map<String, _LoggerProxy> _logInstances  = {};
  static final _emptyLogger = _EmptyLogger();
  static LoggerProvider? _currentLoggerProvider;

  LogManager._();

  static Logger getLogger(String category) {
    var log = _logInstances[category];
    if (log == null) {
      log = _logInstances[category] = _LoggerProxy(_newLogger(category));
    }
    return log;
  }

  static void setLoggerProvider(LoggerProvider? provider) {
    _currentLoggerProvider = provider;
    _logInstances.forEach((category, proxy) { 
      proxy.wrappedLogger = _newLogger(category);
    });
  }

  static Logger _newLogger(category) {
    var p = _currentLoggerProvider;
    return p == null ? _emptyLogger : p.getLogger(category);
  }
}

class _EmptyLogger implements Logger {
  @override void fatal(String line, [ Exception? exception ]) {}
	@override void error(String line, [ Exception? exception ]) {}
	@override void warn(String line, [ Exception? exception ]) {}
	@override void info(String line, [ Exception? exception ]) {}
	@override void debug(String line, [ Exception? exception ]) {}
	@override void trace(String line, [ Exception? exception ]) {}
  @override bool isFatalEnabled() => false;
  @override bool isErrorEnabled() => false;
  @override bool isWarnEnabled() => false;
  @override bool isInfoEnabled() => false;
  @override bool isDebugEnabled() => false;
  @override bool isTraceEnabled() => false;
}

class _LoggerProxy implements Logger {
  Logger wrappedLogger;

  _LoggerProxy(Logger logger) : wrappedLogger = logger;

  @override
  void fatal(String line, [ Exception? exception ]) {
    wrappedLogger.fatal(line, exception);
  }
	@override
  void error(String line, [ Exception? exception ]) {
    wrappedLogger.error(line, exception);
  }
	@override
  void warn(String line, [ Exception? exception ]) {
    wrappedLogger.warn(line, exception);
  }
	@override
  void info(String line, [ Exception? exception ]) {
    wrappedLogger.info(line, exception);
  }
	@override
  void debug(String line, [ Exception? exception ]) {
    wrappedLogger.debug(line, exception);
  }
  @override
  void trace(String line, [ Exception? exception ]) {
    wrappedLogger.trace(line, exception);
  }
  @override
  bool isFatalEnabled() {
    return wrappedLogger.isFatalEnabled();
  }
  @override
  bool isErrorEnabled() {
    return wrappedLogger.isErrorEnabled();
  }
  @override
  bool isWarnEnabled() {
    return wrappedLogger.isWarnEnabled();
  }
  @override
  bool isInfoEnabled() {
    return wrappedLogger.isInfoEnabled();
  }
  @override
  bool isDebugEnabled() {
    return wrappedLogger.isDebugEnabled();
  }
  @override
  bool isTraceEnabled() {
    return wrappedLogger.isTraceEnabled();
  }
}