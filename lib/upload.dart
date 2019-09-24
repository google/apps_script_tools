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
import 'package:googleapis/drive/v3.dart';
import 'package:path/path.dart' as p;

import 'src/api_client.dart';

const List<String> _SCOPES = [DriveApi.DriveScope, DriveApi.DriveScriptsScope];

const String _SCRIPT_MIME_TYPE = "application/vnd.google-apps.script";
const String _CONTENT_TYPE = "application/vnd.google-apps.script+json";

const String apiId =
    "182739467893-iq44a0gc3h2easrua3mru8n84pdvpi4h.apps.googleusercontent.com";
const String apiSecret = "SNmwenVx4fd5aE7aeEixPoxI";

String get _savedCredentialsPath {
  String fileName = "auth.json";
  if (io.Platform.environment.containsKey('APPS_SCRIPT_TOOLS_CACHE')) {
    return io.Platform.environment['APPS_SCRIPT_TOOLS_CACHE'];
  } else if (io.Platform.operatingSystem == 'windows') {
    var appData = io.Platform.environment['APPDATA'];
    return p.join(appData, 'AppsScriptTools', 'Cache', fileName);
  } else {
    return p.join(
        io.Platform.environment['HOME'], '.apps_script_tools-cache', fileName);
  }
}

/// A Script Uploader.
///
/// Once authenticated, the uploader can upload new versions of the script.
class Uploader {
  final ApiClient _apiClient = ApiClient();
  final String _destination;
  DriveApi _drive;

  String _projectName;
  String _destinationFolderId;

  /// Instantiates an uploader with the provided Google Drive destination.
  Uploader(this._destination);

  /// Authenticates this uploader.
  ///
  /// Uses Google APIs to authenticate with [id] and [secret]. If id
  Future authenticate() async {
    await _apiClient.authenticate(
        apiId, apiSecret, _SCOPES, _savedCredentialsPath);
    _drive = DriveApi(_apiClient.client);
  }

  /// Shuts down this uploader.
  Future close() async {
    await _apiClient.close();
  }

  String _createPayload(
      String source, String projectName, Map<String, dynamic> existing) {
    // See https://developers.google.com/apps-script/guides/import-export.
    var payload = {
      "name": projectName,
      "type": "server_js",
      "source": source,
    };
    if (existing != null) {
      payload["id"] = existing["files"][0]["id"];
    }
    return json.encode({
      "files": [payload]
    });
  }

  Future<String> _findFolder(DriveApi drive, Iterable<String> segments) async {
    var parentId = "root";
    for (var segment in segments) {
      var q =
          "name = '$segment' and '$parentId' in parents and trashed = false";
      var nestedFiles = (await drive.files.list(q: q)).files;
      var folders = nestedFiles
          .where(
              (file) => file.mimeType == "application/vnd.google-apps.folder")
          .toList();
      if (folders.length == 1) {
        parentId = folders.first.id;
      } else if (folders.isEmpty) {
        throw "Couldn't find folder $segment";
      } else {
        throw "Couldn't find single folder $segment";
      }
    }
    return parentId;
  }

  /// Uploads the given [source] to the location provided at construction.
  ///
  /// If the script already exists replaces the unique source file within the
  /// script with the provided source.
  Future uploadScript(String source) async {
    if (_projectName == null) {
      var segments = _destination.split("/");
      var folderSegments = segments.take(segments.length - 1);
      _projectName = segments.last;
      _destinationFolderId = await _findFolder(_drive, folderSegments);
    }

    var query = "name = '$_projectName' and "
        "'$_destinationFolderId' in parents and "
        "trashed = false";
    var sameNamedFiles = (await _drive.files.list(q: query)).files;
    var scripts = sameNamedFiles
        .where((file) => file.mimeType == "application/vnd.google-apps.script")
        .toList();
    var existing;
    if (scripts.isEmpty) {
      print("Need to create new project.");
    } else if (scripts.length == 1) {
      print("Need to update existing project.");
      Media media = await _drive.files.export(
          sameNamedFiles[0].id, _CONTENT_TYPE,
          downloadOptions: DownloadOptions.FullMedia);
      existing = await media.stream
          .transform(utf8.decoder)
          .transform(json.decoder)
          .first;
    } else {
      print("Multiple scripts of same name. Don't know which one to update.");
      return;
    }

    var file = File()
      ..name = _projectName
      ..mimeType = _SCRIPT_MIME_TYPE;

    var payload = _createPayload(source, _projectName, existing);
    var utf8Encoded = utf8.encode(payload);
    var media = Media(
        Stream<List<int>>.fromIterable([utf8Encoded]), utf8Encoded.length,
        contentType: _CONTENT_TYPE);

    if (scripts.isEmpty) {
      print("Creating new file ${_projectName}");
      file.parents = [_destinationFolderId];
      await _drive.files.create(file, uploadMedia: media);
    } else if (scripts.length == 1) {
      // Update the existing file.
      print("Updating existing file ${_projectName}");
      await _drive.files.update(file, sameNamedFiles[0].id, uploadMedia: media);
    }
    print("Uploading ${_projectName} done");
  }
}

/// Uploads the given [sourcePath] to the [destination] in Google Drive.
///
Future upload(String sourcePath, String destination) async {
  var uploader = Uploader(destination);
  await uploader.authenticate();
  var source = io.File(sourcePath).readAsStringSync();
  await uploader.uploadScript(source);
  await uploader.close();
}
