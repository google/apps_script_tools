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
import 'package:apps_script_tools/upload.dart';


void help(ArgParser parser) {
  print("Uploads a given '.gs' script to Google Drive as a Google Apps script");
  print("Usage: upload compiled.gs destination");
  print(parser.usage);
}

main(List<String> args) async {
  var parser = new ArgParser();
  parser.addFlag("help", abbr: "h", help: "this help", negatable: false);
  var parsedArgs = parser.parse(args);
  if (parsedArgs['help'] ||
      parsedArgs.rest.length != 2) {
    help(parser);
    return parsedArgs['help'] ? 0 : 1;
  }

  var sourcePath = parsedArgs.rest.first;
  var destination = parsedArgs.rest.last;
  upload(sourcePath, destination);
}
