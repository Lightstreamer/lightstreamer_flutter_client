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
#include "file_logger.h"

#include <sstream>
#include <iostream>
#include <iomanip>
#include <chrono>
#include <ctime> 

namespace lightstreamer_flutter_client {

std::unique_ptr<std::ofstream> FileLogger::_of;

FileLogger::FileLogger(LS::ConsoleLogLevel level, const std::string& category) :
  _category(category),
  _traceEnabled(level <= LS::ConsoleLogLevel::Trace),
  _debugEnabled(level <= LS::ConsoleLogLevel::Debug),
  _infoEnabled(level <= LS::ConsoleLogLevel::Info),
  _warnEnabled(level <= LS::ConsoleLogLevel::Warn),
  _errorEnabled(level <= LS::ConsoleLogLevel::Error),
  _fatalEnabled(level <= LS::ConsoleLogLevel::Fatal)
{
  if (_of == nullptr) {
    _of = std::make_unique<std::ofstream>("lightstreamer-flutter-log.txt");
  }
}

void FileLogger::print(const std::string& level, const std::string& line) const {
  std::tm tm;
  std::time_t t = std::time(nullptr);
  localtime_s(&tm, &t);
  std::stringstream ss;
  ss << std::put_time(&tm, "%F %T") << "|" << level << "|" << _category << "|" << line;
  *_of << ss.str() << std::endl;
}

LS::Logger* FileLoggerProvider::getLogger(const std::string& category) {
  auto it = _loggers.find(category);
  if (it == _loggers.end()) {
    LS::Logger* p = new FileLogger(_level, category);
    _loggers.emplace(category, p);
    return p;
  }
  return it->second.get();
}

}  // namespace lightstreamer_flutter_client
