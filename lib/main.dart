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
import 'package:watcher/watcher.dart';
import 'package:path/path.dart' as p;
import 'gsify.dart';
import 'upload.dart';

/// Watches the given [path] and emits an event everytime it changes.
///
/// When [emitAtListen] is true, also emits an event when this function is
/// started and the file already exists.
Stream watchPath(String path, {bool emitAtListen = false}) async* {
  var file = io.File(path);
  if (file.existsSync() && emitAtListen) yield null;

  outerLoop:
  while (true) {
    if (!file.existsSync()) {
      var directory = p.dirname(path);
      while (!io.Directory(directory).existsSync()) {
        directory = p.dirname(directory);
      }
      await for (var _ in DirectoryWatcher(directory).events) {
        if (file.existsSync()) {
          yield null;
          break;
        } else {
          // In case we are listening for directories to be created.
          continue outerLoop;
        }
      }
    }
    if (file.existsSync()) {
      await for (var event in FileWatcher(path).events) {
        if (event.type != ChangeType.REMOVE) yield null;
      }
    }
  }
}

/// Watches the given [sourcePath] and uploads it to [destination] whenever it
/// changes.
///
/// When gsifying the input source uses [interfaceFunctions],
/// [onlyCurrentDocument] and [notOnlyCurrentDocument] to, optionally, add
/// some boilerplate. See [gsify] for more information.
Future startWatching(String sourcePath, String destination,
    {List<String> interfaceFunctions,
    bool onlyCurrentDocument,
    bool notOnlyCurrentDocument}) async {
  var uploader = Uploader(destination);
  await uploader.authenticate();

  await for (var _ in watchPath(sourcePath, emitAtListen: true)) {
    var source = io.File(sourcePath).readAsStringSync();
    var gsified = gsify(source,
        interfaceFunctions: interfaceFunctions,
        onlyCurrentDocument: onlyCurrentDocument,
        notOnlyCurrentDocument: notOnlyCurrentDocument);
    await uploader.uploadScript(gsified);
  }
  await uploader.close();
}
