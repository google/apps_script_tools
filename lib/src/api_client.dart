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

import 'dart:io' as io;
import 'dart:async';
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' show Client;

/// An Google API Client.
///
/// Asks the user to authenticate and caches the tokens.
class ApiClient {
  Client _baseClient;
  AuthClient client;

  /// Authenticates this uploader.
  ///
  /// Uses Google APIs to authenticate with [id] and [secret]. If id
  Future authenticate(String id, String secret, List<String> scopes,
      String authCachePath) async {
    _baseClient = Client();
    var clientId = ClientId(id, secret);
    // TODO(floitsch): this probably doesn't work when the scopes change.
    var credentials = _readSavedCredentials(authCachePath);
    if (credentials == null ||
        credentials.refreshToken == null &&
            credentials.accessToken.hasExpired) {
      credentials = await obtainAccessCredentialsViaUserConsent(
          clientId, scopes, _baseClient, (String str) {
        print("Please authorize at this URL: $str");
      });
      _saveCredentials(authCachePath, credentials);
    }
    client = credentials.refreshToken == null
        ? authenticatedClient(_baseClient, credentials)
        : autoRefreshingClient(clientId, credentials, _baseClient);
  }

  /// Shuts down this uploader.
  Future close() async {
    await client.close();
    await _baseClient.close();
  }

  AccessCredentials _readSavedCredentials(String savedCredentialsPath) {
    if (savedCredentialsPath == null) return null;

    var file = io.File(savedCredentialsPath);
    if (!file.existsSync()) return null;
    var decoded = json.decode(file.readAsStringSync());
    var refreshToken = decoded['refreshToken'];
    if (refreshToken == null) {
      print("refreshToken missing. Users will have to authenticate again.");
    }
    var jsonAccessToken = decoded['accessToken'];
    var accessToken = AccessToken(
        jsonAccessToken['type'],
        jsonAccessToken['data'],
        DateTime.fromMillisecondsSinceEpoch(jsonAccessToken['expiry'],
            isUtc: true));
    var scopes = (decoded['scopes'] as List).cast<String>();
    return AccessCredentials(accessToken, refreshToken, scopes);
  }

  void _saveCredentials(
      String savedCredentialsPath, AccessCredentials credentials) {
    if (savedCredentialsPath == null) return;

    try {
      var accessToken = credentials.accessToken;
      var encoded = json.encode({
        'refreshToken': credentials.refreshToken,
        'accessToken': {
          "type": accessToken.type,
          "data": accessToken.data,
          "expiry": accessToken.expiry.millisecondsSinceEpoch
        },
        'scopes': credentials.scopes
      });
      var directory = io.Directory(p.dirname(savedCredentialsPath));
      if (!directory.existsSync()) directory.createSync(recursive: true);
      io.File(savedCredentialsPath).writeAsStringSync(encoded);
    } catch (e) {
      print("Couldn't save credentials: $e");
    }
  }
}
