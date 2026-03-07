import 'dart:async';

import 'package:http/http.dart' as http;

import 'file_part_stub.dart' if (dart.library.io) 'file_part_io.dart';

/// An intermediary representation of [http.MultipartFile] That does not require the field name, which is determined by the parameter name in the endpoint method.
abstract final class FilePart {
  factory FilePart(
    Stream<List<int>> stream,
    int length, {
    String? filename,
    http.MediaType? contentType,
  }) = _FilePartFromStream;

  factory FilePart.fromBytes(
    List<int> bytes, {
    String? filename,
    http.MediaType? contentType,
  }) = _FilePartFromBytes;

  factory FilePart.fromString(
    String content, {
    String? filename,
    http.MediaType? contentType,
  }) = _FilePartFromString;

  static Future<FilePart> fromPath(
    String filePath, {
    String? filename,
    http.MediaType? contentType,
  }) =>
      filePartFromPath(filePath, filename: filename, contentType: contentType);

  /// Creates a [FilePart] from an existing [http.MultipartFile].
  ///
  /// Generally not recommended as the endpoint usually prefers to control the field name
  factory FilePart.fromMultipartFile(http.MultipartFile multipartFile) =
      _FilePartFromMultipartFile;

  http.MultipartFile toHttpMultipartFile(String field);
}

final class _FilePartFromStream implements FilePart {
  _FilePartFromStream(
    this.stream,
    this.length, {
    this.filename,
    this.contentType,
  });
  final Stream<List<int>> stream;
  final int length;
  final String? filename;
  final http.MediaType? contentType;

  @override
  http.MultipartFile toHttpMultipartFile(String field) => http.MultipartFile(
    field,
    stream,
    length,
    filename: filename,
    contentType: contentType,
  );
}

final class _FilePartFromBytes implements FilePart {
  _FilePartFromBytes(this.bytes, {this.filename, this.contentType});
  final List<int> bytes;
  final String? filename;
  final http.MediaType? contentType;

  @override
  http.MultipartFile toHttpMultipartFile(String field) =>
      http.MultipartFile.fromBytes(
        field,
        bytes,
        filename: filename,
        contentType: contentType,
      );
}

final class _FilePartFromString implements FilePart {
  _FilePartFromString(this.content, {this.filename, this.contentType});
  final String content;
  final String? filename;
  final http.MediaType? contentType;

  @override
  http.MultipartFile toHttpMultipartFile(String field) =>
      http.MultipartFile.fromString(
        field,
        content,
        filename: filename,
        contentType: contentType,
      );
}

final class _FilePartFromMultipartFile implements FilePart {
  _FilePartFromMultipartFile(this.multipartFile);
  final http.MultipartFile multipartFile;

  @override
  http.MultipartFile toHttpMultipartFile(String field) => multipartFile;
}
