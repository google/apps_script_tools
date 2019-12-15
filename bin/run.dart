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
import 'package:apps_script_tools/run.dart';

const scriptId = "M3QyfgU45qAOUdM-H2VBGr4gwnYFpKilg";

void help(ArgParser parser) {
  print("""
Runs the given function in the script
  run [--dev-mode] [scopes*] --client-id <id> --client-secret <secret> scriptId function-name [args*]

The scriptId can be found in the Project Properties.
From the Script Editor:
  -> File
  -> Project Properties
  -> Info Tab.

The scopes can be found in the Project Properties.
From the Script Editor:
  -> File
  -> Project Properties
  -> Scopes Tab

The client-id and client-secret are OAuth ids for the script's project.
They need to be created for each script (or the script must be moved into a
project that already has one).

From the Script Editor:
  -> Resources
  -> Cloud Platform project
  -> <click on project name>
  -> Getting started: Enable APIs and get credentials such as keys
  -> Credentials
    If necessary create a new ("Other") OAuth client ID.
This page can also be accessed by https://console.cloud.google.com/apis/credentials?project=PROJECT_ID
  where PROJECT_ID is the ID from step 3.

The function-name is the entry-point of the function.

The script generally does not cache the authentication since the scopes may
change for different scripts or versions. Users can provide an explicit
auth-cache path where the authentication is stored.

Each argument to the Apps Script is parsed as JSON, and if that fails, passed
verbatim as a string.

Example:
  run --dev-mode -s https://www.googleapis.com/auth/documents <script-id> helloWorld
""");
  print(parser.usage);
}

main(List<String> args) async {
  var parser = ArgParser();
  parser.addFlag("dev-mode",
      help: "Runs the most recently saved version rather than the deployed "
          "version.");
  parser.addMultiOption("scope", abbr: "s");
  parser.addOption("auth-cache",
      help: "The file-path where the authentication should be cached");
  parser.addFlag("help", abbr: "h", help: "this help", negatable: false);
  parser.addOption(
    "client-id",
    help: "the client id",
  );
  parser.addOption("client-secret", help: "the client secret");

  var parsedArgs = parser.parse(args);
  if (parsedArgs['help'] ||
      parsedArgs["client-id"] == null ||
      parsedArgs["client-secret"] == null ||
      parsedArgs.rest.length < 2) {
    help(parser);
    return parsedArgs['help'] ? 0 : 1;
  }

  bool devMode = parsedArgs['dev-mode'];

  String scriptId = parsedArgs.rest[0];
  String scriptFun = parsedArgs.rest[1];

  String clientId = parsedArgs["client-id"];
  String clientSecret = parsedArgs["client-secret"];

  List<String> scopes = parsedArgs['scope'];

  String authCachePath = parsedArgs['auth-cache'];

  await runScript(scriptId, scriptFun, clientId, clientSecret, scopes,
      parsedArgs.rest.skip(2).toList(),
      devMode: devMode, authCachePath: authCachePath);
}
