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
import 'package:apps_script_uploader/gsify.dart';

void help(ArgParser parser) {
  print("Converts a dart2js compiled output file into a valid"
      " Google Apps Script.");
  print("");
  print(parser.usage);
}

main(args) {
  var parser = new ArgParser();
  parser.addOption("stub",
      abbr: 's', help: "provides a function stub", allowMultiple: true);
  parser.addFlag("only-current-document",
      help: "only accesses the current document "
          "(https://developers.google.com/apps-script/"
          "guides/services/authorization)",
      negatable: false);
  parser.addFlag("not-only-current-document",
      help: "force multi-document access", negatable: false);
  parser.addOption("out", abbr: "o", help: "path of generated gs script");
  parser.addFlag("help", abbr: "h", help: "this help", negatable: false);
  var parsedArgs = parser.parse(args);
  if (parsedArgs['out'] == null ||
      parsedArgs['help'] ||
      parsedArgs.rest.length != 1) {
    help(parser);
    return parsedArgs['help'] ? 0 : 1;
  }

  var sourcePath = parsedArgs.rest.first;
  String outPath = parsedArgs['out'];
  List<String> interfaceFunctions = parsedArgs['stub'];
  bool onlyCurrentDocument = parsedArgs['only-current-document'];
  bool notOnlyCurrentDocument = parsedArgs['not-only-current-document'];

  gsifyFile(sourcePath, outPath,
      interfaceFunctions: interfaceFunctions,
      onlyCurrentDocument: onlyCurrentDocument,
      notOnlyCurrentDocument: notOnlyCurrentDocument);
}
