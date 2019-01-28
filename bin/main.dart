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

import 'package:args/args.dart';
import 'package:apps_script_tools/main.dart';

void help(ArgParser parser) {
  print("Watches the source-javaScript file and uploads it automatically as a");
  print("Google Apps Script whenever it changes.");
  print("");
  print(parser.usage);
}

main(List<String> args) async {
  var parser = new ArgParser();
  parser.addMultiOption("stub", abbr: 's', help: "provides a function stub");
  parser.addFlag("only-current-document",
      help: "only accesses the current document "
          "(https://developers.google.com/apps-script/"
          "guides/services/authorization)", negatable: false);
  parser.addFlag("not-only-current-document",
      help: "force multi-document access", negatable: false);
  parser.addFlag("help", abbr: "h", help: "this help", negatable: false);
  var parsedArgs = parser.parse(args);
  if (parsedArgs['help'] ||
      parsedArgs.rest.length != 2) {
    help(parser);
    return parsedArgs['help'] ? 0 : 1;
  }

  var sourcePath = parsedArgs.rest.first;
  var destination = parsedArgs.rest.last;
  List<String> interfaceFunctions = parsedArgs['stub'];
  bool onlyCurrentDocument = parsedArgs['only-current-document'];
  bool notOnlyCurrentDocument = parsedArgs['not-only-current-document'];

  startWatching(sourcePath, destination,
      interfaceFunctions: interfaceFunctions,
      onlyCurrentDocument: onlyCurrentDocument,
      notOnlyCurrentDocument: notOnlyCurrentDocument);
}