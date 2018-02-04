// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:io';
import 'package:apps_script_uploader/src/preamble.dart';

/// Takes a dart2js compiled code [source] and converts it into a valid
/// Google Apps Script.
///
/// Always includes a necessary preamble.
///
/// Optionally includes function stubs for functions listed in
/// [interfaceFunctions]. These stubs can be used as entry points (which
/// must be statically visible), but can be overwritten from withing the
/// Dart code (before they are executed).
///
/// When [onlyCurrentDocument] is true, adds a `/* @OnlyCurrentDoc */` comment.
/// When [notOnlyCurrentDocument] is true, adds a `/* @NotOnlyCurrentDoc */`
/// comment. It doesn't make sense to set both booleans to true.
String gsify(String source,
    {List<String> interfaceFunctions = const [],
    bool onlyCurrentDocument = false,
    bool notOnlyCurrentDocument = false}) {
  var result = new StringBuffer();
  if (onlyCurrentDocument) {
    result.writeln("/* @OnlyCurrentDoc */");
  }
  if (notOnlyCurrentDocument) {
    result.writeln("/* @NotOnlyCurrentDoc */");
  }
  for (var fun in interfaceFunctions) {
    // These functions can be overridden by the Dart program.
    result.writeln("function $fun() {}");
  }
  result.writeln(PREAMBLE);
  result.write(source);
  return result.toString();
}


/// Takes a dart2js compiled output file [sourcePath] and converts it into a
/// valid Google Apps Script writing it into [outPath].
///
/// Always includes a necessary preamble.
///
/// Optionally includes function stubs for functions listed in
/// [interfaceFunctions]. These stubs can be used as entry points (which
/// must be statically visible), but can be overwritten from withing the
/// Dart code (before they are executed).
///
/// When [onlyCurrentDocument] is true, adds a `/* @OnlyCurrentDoc */` comment.
/// When [notOnlyCurrentDocument] is true, adds a `/* @NotOnlyCurrentDoc */`
/// comment. It doesn't make sense to set both booleans to true.
void gsifyFile(String sourcePath, String outPath,
    {List<String> interfaceFunctions = const [],
    bool onlyCurrentDocument = false,
    bool notOnlyCurrentDocument = false}) {
  var source = new File(sourcePath).readAsStringSync();
  var gsified = gsify(source,
      interfaceFunctions: interfaceFunctions,
      onlyCurrentDocument: onlyCurrentDocument,
      notOnlyCurrentDocument: notOnlyCurrentDocument);
  new File(outPath).writeAsStringSync(gsified);
}
