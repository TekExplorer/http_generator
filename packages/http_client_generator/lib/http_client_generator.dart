/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator.dart';

Builder httpClientBuilder([BuilderOptions? options]) =>
    SharedPartBuilder([HttpClientGenerator()], 'http_client');
