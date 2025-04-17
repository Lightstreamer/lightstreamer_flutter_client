/*
 * Copyright (C) 2022 Lightstreamer Srl
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#ifndef INCLUDED_Lightstreamer_Flutter_FileLogger
#define INCLUDED_Lightstreamer_Flutter_FileLogger

#include "Lightstreamer\Logger.h"
#include "Lightstreamer\LoggerProvider.h"
#include <Lightstreamer\ConsoleLoggerProvider.h>

#include <map>
#include <fstream>

namespace lightstreamer_flutter_client {

namespace LS = Lightstreamer;

class EmptyLogger : public LS::Logger {
public:
  void error(const std::string& line) override {}
  void warn(const std::string& line) override {}
  void info(const std::string& line) override {}
  void debug(const std::string& line) override {}
  void trace(const std::string& line) override {}
  void fatal(const std::string& line) override {}
  bool isTraceEnabled() override { return false; }
  bool isDebugEnabled() override { return false; }
  bool isInfoEnabled() override { return false; }
  bool isWarnEnabled() override { return false; }
  bool isErrorEnabled() override { return false; }
  bool isFatalEnabled() override { return false; }
};

class FileLogger : public LS::Logger {
  static std::unique_ptr<std::ofstream> _of;
  std::string _category;
  bool _traceEnabled;
  bool _debugEnabled;
  bool _infoEnabled;
  bool _warnEnabled;
  bool _errorEnabled;
  bool _fatalEnabled;
  void print(const std::string& level, const std::string& line) const;
public:
  FileLogger(LS::ConsoleLogLevel level, const std::string& category);
  ~FileLogger() {}
  // Inherited via Logger
  void error(const std::string& line) override
  {
    if (_errorEnabled) print("ERROR", line);
  }
  void warn(const std::string& line) override
  {
    if (_warnEnabled) print("WARN", line);
  }
  void info(const std::string& line) override
  {
    if (_infoEnabled) print("INFO", line);
  }
  void debug(const std::string& line) override
  {
    if (_debugEnabled) print("DEBUG", line);
  }
  void trace(const std::string& line) override
  {
    if (_traceEnabled) print("TRACE", line);
  }
  void fatal(const std::string& line) override
  {
    if (_fatalEnabled) print("FATAL", line);
  }
  bool isTraceEnabled() override
  {
    return _traceEnabled;
  }
  bool isDebugEnabled() override
  {
    return _debugEnabled;
  }
  bool isInfoEnabled() override
  {
    return _infoEnabled;
  }
  bool isWarnEnabled() override
  {
    return _warnEnabled;
  }
  bool isErrorEnabled() override
  {
    return _errorEnabled;
  }
  bool isFatalEnabled() override
  {
    return _fatalEnabled;
  }
};

class FileLoggerProvider : public LS::LoggerProvider {
  LS::ConsoleLogLevel _level;
  std::map<std::string, std::unique_ptr<LS::Logger>> _loggers;
public:
  FileLoggerProvider(LS::ConsoleLogLevel level) : _level(level) {}
  LS::Logger* getLogger(const std::string& category) override;
};

}  // namespace lightstreamer_flutter_client

#endif
