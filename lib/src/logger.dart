// ignore_for_file: constant_identifier_names, avoid_print

abstract interface class Logger {
  void fatal(String line, [ Exception? exception ]);
  void error(String line, [ Exception? exception ]);
  void warn(String  line, [ Exception? exception ]);
  void info(String  line, [ Exception? exception ]);
  void debug(String line, [ Exception? exception ]);
  void trace(String line, [ Exception? exception ]);
  bool isFatalEnabled();
  bool isErrorEnabled();
  bool isWarnEnabled();
  bool isInfoEnabled();
  bool isDebugEnabled();
  bool isTraceEnabled();
}

abstract interface class LoggerProvider {
  Logger getLogger(String category);
}

class ConsoleLogLevel {
  static const TRACE = 0;
  static const DEBUG = 10;
  static const INFO = 20;
  static const WARN = 30;
  static const ERROR = 40;
  static const FATAL = 50;

  ConsoleLogLevel._();
}

class ConsoleLoggerProvider implements LoggerProvider {
  final int _level;

  ConsoleLoggerProvider(int level) : _level = level;

  @override
  Logger getLogger(String category) {
    return _ConsoleLogger(_level, category);
  }
}

class _ConsoleLogger implements Logger {
  final String _category;
  final bool _traceEnabled;
  final bool _debugEnabled;
  final bool _infoEnabled;
  final bool _warnEnabled;
  final bool _errorEnabled;
  final bool _fatalEnabled;

  _ConsoleLogger(int level, String category) :
    _category = category,
    _traceEnabled = level <= ConsoleLogLevel.TRACE,
    _debugEnabled = level <= ConsoleLogLevel.DEBUG,
    _infoEnabled  = level <= ConsoleLogLevel.INFO,
    _warnEnabled  = level <= ConsoleLogLevel.WARN,
    _errorEnabled = level <= ConsoleLogLevel.ERROR,
    _fatalEnabled = level <= ConsoleLogLevel.FATAL;

  void _format(String level, String line, Exception? exception) {
    var now = DateTime.now();
    print('$now|$level|$_category|$line');
    if (exception != null) {
      print(exception);
    }
  }

  @override
  void fatal(String line, [ Exception? exception ]) {
    if (_fatalEnabled) {
      _format("FATAL", line, exception);
    }
  }

  @override
  void error(String line, [ Exception? exception ]) {
    if (_errorEnabled) {
      _format("ERROR", line, exception);
    }
  }

  @override
  void warn(String line, [ Exception? exception ]) {
    if (_warnEnabled) {
      _format("WARN ", line, exception);
    }
  }

  @override
  void info(String line, [ Exception? exception ]) {
    if (_infoEnabled) {
      _format("INFO ", line, exception);
    }
  }

  @override
  void debug(String line, [ Exception? exception ]) {
    if (_debugEnabled) {
      _format("DEBUG", line, exception);
    }
  }

  @override
  void trace(String line, [ Exception? exception ]) {
    if (_traceEnabled) {
      _format("TRACE", line, exception);
    }
  }

  @override
  bool isFatalEnabled() {
    return _fatalEnabled;
  }

  @override
  bool isErrorEnabled() {
    return _errorEnabled;
  }

  @override
  bool isWarnEnabled() {
    return _warnEnabled;
  }

  @override
  bool isInfoEnabled() {
    return _infoEnabled;
  }

  @override
  bool isDebugEnabled() {
    return _debugEnabled;
  }

  @override
  bool isTraceEnabled() {
    return _traceEnabled;
  }
}