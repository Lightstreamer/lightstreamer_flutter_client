// ignore_for_file: constant_identifier_names, avoid_print

/** 
 * Interface to be implemented to consume log from the library.
 * 
 * Instances of implemented classes are obtained by the library through the LoggerProvider instance set on [LightstreamerClient.setLoggerProvider].
*/
abstract interface class Logger {
  /** 
   * Receives log messages at Fatal level and a related exception.
   * 
   * @param line The message to be logged.
   * 
   * @param exception An Exception instance related to the current log message.
   */
  void fatal(String line, [ Exception? exception ]);
  /** 
   * Receives log messages at Error level and a related exception.
   * 
   * @param line The message to be logged.
   * 
   * @param exception An Exception instance related to the current log message.
   */
  void error(String line, [ Exception? exception ]);
  /** 
   * Receives log messages at Warn level and a related exception.
   * 
   * @param line The message to be logged.
   * 
   * @param exception An Exception instance related to the current log message. 
   */
  void warn(String  line, [ Exception? exception ]);
  /** 
   * Receives log messages at Info level and a related exception.
   * 
   * @param line The message to be logged.
   * 
   * @param exception An Exception instance related to the current log message.
   */
  void info(String  line, [ Exception? exception ]);
  /** 
   * Receives log messages at Debug level and a related exception.
   * 
   * @param line The message to be logged.
   * 
   * @param exception An Exception instance related to the current log message.
   */
  void debug(String line, [ Exception? exception ]);
  /** 
   * Receives log messages at Trace level and a related exception.
   * 
   * @param line The message to be logged.
   * 
   * @param exception An Exception instance related to the current log message.
   */
  void trace(String line, [ Exception? exception ]);
  /** 
   * Checks if this logger is enabled for the Fatal level.
   * 
   * The property should be true if this logger is enabled for Fatal events, false otherwise. <BR> 
   * This property is intended to lessen the computational cost of disabled log Fatal statements. Note 
   * that even if the property is false, Fatal log lines may be received anyway by the Fatal methods.
   * @return true if the Fatal logger is enabled
   */
  bool isFatalEnabled();
  /** 
   * Checks if this logger is enabled for the Error level.
   * 
   * The property should be true if this logger is enabled for Error events, false otherwise. <BR> 
   * This property is intended to lessen the computational cost of disabled log Error statements. Note 
   * that even if the property is false, Error log lines may be received anyway by the Error methods.
   * @return true if the Error logger is enabled
   */
  bool isErrorEnabled();
  /** 
   * Checks if this logger is enabled for the Warn level.
   * 
   * The property should be true if this logger is enabled for Warn events, false otherwise. <BR> 
   * This property is intended to lessen the computational cost of disabled log Warn statements. Note 
   * that even if the property is false, Warn log lines may be received anyway by the Warn methods.
   * @return true if the Warn logger is enabled
   */
  bool isWarnEnabled();
  /** 
   * Checks if this logger is enabled for the Info level.
   * 
   * The property should be true if this logger is enabled for Info events, false otherwise. <BR> 
   * This property is intended to lessen the computational cost of disabled log Info statements. Note 
   * that even if the property is false, Info log lines may be received anyway by the Info methods.
   * @return true if the Info logger is enabled
   */
  bool isInfoEnabled();
  /** 
   * Checks if this logger is enabled for the Debug level.
   * 
   * The property should be true if this logger is enabled for Debug events, false otherwise. <BR> 
   * This property is intended to lessen the computational cost of disabled log Debug statements. Note 
   * that even if the property is false, Debug log lines may be received anyway by the Debug methods.
   * @return true if the Debug logger is enabled
   */
  bool isDebugEnabled();
  /** 
   * Checks if this logger is enabled for the Trace level.
   * 
   * The property should be true if this logger is enabled for Trace events, false otherwise. <BR> 
   * This property is intended to lessen the computational cost of disabled log Trace statements. Note 
   * that even if the property is false, Trace log lines may be received anyway by the Trace methods.
   * @return true if the Trace logger is enabled
   */
  bool isTraceEnabled();
}

/** 
 * Simple interface to be implemented to provide custom log consumers to the library.
 * 
 * An instance of the custom implemented class has to be passed to the library through the 
 * [LightstreamerClient.setLoggerProvider].
 */
abstract interface class LoggerProvider {
  /** 
   * Request for a Logger instance that will be used for logging occurring on the given 
   * category. 
   * 
   * It is suggested, but not mandatory, that subsequent calls to this method
   * related to the same category return the same Logger instance.
   * 
   * @param category the log category all messages passed to the given Logger instance will pertain to.
   * 
   * @return A Logger instance that will receive log lines related to the given category.
   */
  Logger getLogger(String category);
}

/**
 Logging level.
 */
class ConsoleLogLevel {
  /**
    Trace logging level.
   
    This level enables all logging.
   */
  static const TRACE = 0;
  /**
    Debug logging level.
     
    This level enables all logging except tracing.
   */
  static const DEBUG = 10;
  /**
    Info logging level.
     
    This level enables logging for information, warnings, errors and fatal errors.
   */
  static const INFO = 20;
  /**
    Warn logging level.
     
    This level enables logging for warnings, errors and fatal errors.
   */
  static const WARN = 30;
  /**
    Error logging level.
     
    This level enables logging for errors and fatal errors.
   */
  static const ERROR = 40;
    /**
    Fatal logging level.
     
    This level enables logging for fatal errors only.
   */
  static const FATAL = 50;

  ConsoleLogLevel._();
}

/**
  Simple concrete logging provider that logs on the system console.
 
  To be used, an instance of this class has to be passed to the library through the [LightstreamerClient.setLoggerProvider].
 */
class ConsoleLoggerProvider implements LoggerProvider {
  final int _level;

 /**
    Creates an instance of the concrete system console logger.
     
    @param level The desired logging level. See [ConsoleLogLevel].
  */
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