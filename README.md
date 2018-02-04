# Apps Script Uploader

This is not an official Google product.

This package provides tools for using dart2js-compiled programs as Google Apps
scripts.

The `gsify` program adds boilerplate and necessary preambles, and the
`upload` program uploads the resulting `gs` script to Google Drive.

The `main` program makes the development process easier by automatically
using those two tools whenever the input JS file is changed.

## Usage

The most common use case is to watch the output file of a dart2js
compilation and upload it as Google Apps script whenever it changes.

This is accomplished with the `main`-script (aka `apps_script_watch` when
enabled through `pub global activate`).

In its simplest form it just needs two arguments: the input file and
a Google Drive destination. Every time the input file changes (and also
initially at startup) it converts the JS file into a valid
Google Apps script (prefixing it with a necessary preamble) and then
uploads it to Google drive at the given location. (This requires an
OAuth authentication).

Similar to `gsify` it can also add stub functions (see "Stub Functions"
below) or the
`/* @OnlyCurrentDoc */` or `/* @NotOnlyCurrentDoc */` comments (see
[https://developers.google.com/apps-script/guides/services/authorization]).

*Note that Google Apps script must be compiled with the `--cps` flag of
dart2js.*

Example
```
pub global activate apps_script_uploader
apps_script_watch in.js folder/script_name
```
or, without running `pub global activate`
```
pub global run apps_script_uploader:main in.js folder/script_name
```

### Gsify

The `gsify` executable converts a dart2js-compiled program into a valid
Google Apps script.
It prefixes the necessary preamble and optionally add some stub functions,
and `/* @OnlyCurrentDoc */` or `/* @NotOnlyCurrentDoc */` comments (see
[https://developers.google.com/apps-script/guides/services/authorization]).

The input file must be the output of `dart2js` with the `--cps` flag.

Example:
```
pub global activate apps_script_uploader
gsify in.js out.gs
```
or, without running `pub global activate`:
```
pub global run apps_script_uploader:gsify in.js out.gs
```

The following example adds the `/* @OnlyCurrentDoc */` comment and a
stub-function called `onOpen`:
```
gsify -s onOpen --only-current-document in.js out.gs
```

### Upload

`upload` takes a valid Google Apps script and uploads it to Google Drive.

If there exists already a Google Apps script at the provided destination
replaces the content with the given input script. This only works if the
existing Google Apps script only contains one source file.

The destination may be prefixed with folders (which must exist).

This script uses Google APIs and thus requires an OAuth authentication
which is cached for future uses.

Example:
```
pub global activate apps_script_uploader
apps_script_upload in.gs folder/script_name
```
or, without running `pub global activate`:
```
pub global run apps_script_uploader:upload in.gs folder/script_name
```

### Run

`run` executes the uploaded script. Scripts must be run in the same
Google Cloud project as the Google API that makes the invocation. This
means that the request to run the script must use a clientId/Secret that
is provided by the user.

See below ("Remote Script Execution") for detailed instructions on how to
set this up.


## Stub Functions
Whenever the Google Apps Script service needs to call into the provided script
it needs to statically see the target function. That is, the provided
JavaScript must contain a function with the given name. For example,
Spreadsheet Addons that want to add a menu entry must have a statically visible
`onOpen` function. The output of dart2js avoids modifying the global environment
and the current JS interop functionality does not give any means to export a
Dart function. To work around this limitation, one can use a stub function that
is then overwritten from withing the Dart program.

Concretely, running `main` or `gsify` with `-s onOpen` will add the following
JavaScript function to the generated `.gs`:

``` JS
function onOpen() {}
```

From within Dart one can then use JS interop to overwrite this function before
it is invoked:

``` dart
@JS()
library main;

import 'package:js/js.dart';

@JS()
external set onOpen(value);

void onOpenDart(e) {
  // Run on-open things like adding a menu.
}

main() {
  onOpen = allowInterop(onOpenDart);
}
```

This (or a similar setup) must be done for any function that the Apps framework
wants to use as an entry point. This includes simple triggers (see
[https://developers.google.com/apps-script/guides/triggers/), the  menu entries,
and callbacks from html services
([https://developers.google.com/apps-script/guides/html/reference/run]).

## Attached Scripts / Addons
TODO.

## Walk-throughs
TODO.

### Create Document

### Hello World Addon

### Remote Script Execution
