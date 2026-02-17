# HTTP Client Generator

A powerful code generation package for Dart that automatically creates type-safe HTTP clients from annotated abstract classes. Inspired by Retrofit and Chopper, this package eliminates boilerplate code and provides compile-time safety for REST API calls.

## Features

### 🔥 Core Features

- **Code Generation**: Automatically generates HTTP client implementations from annotated classes
- **Type Safety**: Full compile-time type checking for requests and responses  
- **JSON Serialization**: Automatic JSON encoding/decoding with custom serializers
- **Multiple HTTP Methods**: Support for GET, POST, PUT, DELETE, PATCH
- **Flexible Base URLs**: Configure base URLs per client or at runtime
- **Stream Support**: Handle streamed requests and responses

### 📝 Request Configuration

- **Path Parameters**: Dynamic URL path substitution with `@Path()`
- **Query Parameters**: Single parameters with `@Query()` and multiple with `@QueryAll()`
- **Request Bodies**: Support for JSON, raw strings, and complex object serialization
- **Form Fields**: Individual fields with `@Field()` or grouped with `@Fields()`
- **Headers**: Custom headers and multipart support
- **URL Fragments**: Fragment identifier support with `@Fragment()`

### 🎯 Advanced Features

- **Generic Type Support**: Full support for generic types like `Gen<Data>` and `List<Map<String, Gen<Data>>>`
- **Record Types**: Support for Dart 3 records including named records `({int id, String name})`
- **Raw Body Mode**: Send pre-serialized strings with `@Body(raw: true)`
- **Request Cancellation**: Cancel requests with `@Cancel()` parameter
- **Custom HTTP Clients**: Integrate with any HTTP client (built-in support for Dio)
- **Stream Bodies**: Send data as streams for large uploads

## Getting Started

Add the packages to your `pubspec.yaml`:

```yaml
dependencies:
  http_annotation: ^1.0.0
  http: ^1.0.0

dev_dependencies:
  http_generator: ^1.0.0
  build_runner: ^2.4.0
```

## Usage

### Basic Client

```dart
import 'package:http_annotation/http_annotation.dart';
import 'package:http/http.dart' as http;

part 'api_client.g.dart';

@RestClient('https://api.example.com')
abstract class ApiClient with _$ApiClient {
  ApiClient(this.client);
  
  final http.Client client;

  @override
  Future<http.StreamedResponse> $send(http.BaseRequest request) {
    return client.send(request);
  }

  @Get('/users/{id}')
  Future<User> getUser(@Path('id') String id);

  @Post('/users')
  Future<User> createUser(@Body() User user);

  @Get('/users')
  Future<List<User>> getUsers(@Query('page') int page);
}
```

### Dynamic Base URL

```dart
@RestClient()
class ApiClient with _$ApiClient {
  ApiClient({required this.baseUrl});

  @override
  final String baseUrl;

  @Get('/data')
  Future<http.Response> getData();
}
```

### Complex Request Examples

```dart
@RestClient('https://api.example.com')  
abstract class AdvancedClient with _$AdvancedClient {
  // Generic types
  @Get('/generic-data')
  Future<Response<List<User>>> getGenericData();

  // Records (Dart 3)
  @Get('/record-data')
  Future<({int id, String name, bool active})> getRecordData();

  // Multiple parameters
  @Post('/complex/{id}')
  Future<List<Map<String, Response<User>>>> complexRequest(
    @Path('id') String id,
    @Query('search') String search,
    @Fragment() String fragment,
    @Body() Response<Map<String, User>> body,
    @Cancel() Future<void> cancelToken,
  );

  // Form fields
  @Post('/form-data')
  Future<void> submitForm(
    @Field('name') String name,
    @Field('age') int age,
    @Fields() Map<String, String> additionalFields,
  );

  // Raw body
  @Post('/raw')
  Future<void> sendRaw(@Body(raw: true) String jsonString);

  // Stream upload
  @Put('/upload')
  Future<http.StreamedResponse> uploadStream(@Body() Stream<List<int>> data);
}
```

### Custom Serialization

Your data classes need `fromJson` and `toJson` methods:

```dart
class User {
  final String name;
  final int age;
  
  User({required this.name, required this.age});
  
  factory User.fromJson(Map<String, dynamic> json) => User(
    name: json['name'] as String,
    age: json['age'] as int,
  );
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
  };
}

// Generic types need additional serializer functions
class Response<T> {
  final T data;
  
  Response(this.data);
  
  factory Response.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => Response(fromJsonT(json['data']));
  
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) => {
    'data': toJsonT(data),
  };
}
```

### Code Generation

Run the code generator:

```bash
dart pub run build_runner build
```

For continuous generation during development:

```bash
dart pub run build_runner watch
```

## Integration with Dio

Use the provided Dio client adapter:

```dart
import 'package:http_dio_client/http_dio_client.dart';
import 'package:dio/dio.dart';

final dio = Dio();
final client = ApiClient(DioClient(dio));
```

## Supported Types

- **Primitives**: `String`, `int`, `double`, `bool`
- **Collections**: `List<T>`, `Map<String, T>`, `Set<T>`
- **Records**: `(int, String)`, `({int id, String name})`
- **Generic Types**: `Response<T>`, `List<Response<User>>`
- **Streams**: `Stream<List<int>>`, `Stream<Uint8List>`
- **HTTP Types**: `http.Response`, `http.StreamedResponse`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
