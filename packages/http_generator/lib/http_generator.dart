/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator.dart';

Builder httpClientBuilder([BuilderOptions options = BuilderOptions.empty]) =>
    // LibraryBuilder(HttpClientGenerator(), generatedExtension: '.http.dart');
    SharedPartBuilder(
      [HttpClientGenerator()],
      'http_client',
      formatOutput: (code, languageVersion) {
        try {
          return DartFormatter(languageVersion: languageVersion).format(code);
        } catch (e) {
          print(e);
          return code;
        }
      },
    );
