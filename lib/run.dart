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

import 'dart:async';
import 'dart:convert' show json;

import 'package:googleapis/script/v1.dart';

import 'src/api_client.dart';

const String _SCRIPT_MIME_TYPE = "application/vnd.google-apps.script";
const String _CONTENT_TYPE = "application/vnd.google-apps.script+json";

dynamic _convertArg(String arg) {
  try {
    return json.decode(arg);
  } catch(e) {
    return arg;
  }
}

Future runScript(String scriptId, String funName, String clientId,
    String clientSecret, List<String> scopes, List<String> unconvertedArgs,
    {bool devMode = false, String authCachePath}) async {
  var apiClient = new ApiClient();

  await apiClient.authenticate(clientId, clientSecret, scopes, authCachePath);

  List convertedArgs = unconvertedArgs.map(_convertArg).toList();

  var api = new ScriptApi(apiClient.client);

  var request = new ExecutionRequest()
    ..devMode = devMode
    ..function = funName
    ..parameters = convertedArgs;
  var operation = await api.scripts.run(request, scriptId);
  print(operation.response);
}
