// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:http/http.dart' as http;

import 'file_part.dart';

Future<FilePart> filePartFromPath(
  String filePath, {
  String? filename,
  http.MediaType? contentType,
}) async {
  late var segments = Uri.file(filePath).pathSegments;
  filename ??= segments.isEmpty ? '' : segments.last;
  var file = File(filePath);
  var length = await file.length();
  var stream = http.ByteStream(file.openRead());
  return FilePart(stream, length, filename: filename, contentType: contentType);
}
