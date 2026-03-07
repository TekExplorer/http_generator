// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:http_annotation/http_annotation.dart';
import 'package:http_parser/http_parser.dart';

import 'file_part.dart';

Future<FilePart> filePartFromPath(
  String filePath, {
  String? filename,
  MediaType? contentType,
}) => throw UnsupportedError(
  'MultipartFile is only supported where dart:io is available.',
);
