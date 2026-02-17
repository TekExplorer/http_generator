# HTTP Annotation

A Dart package providing annotations for generating type-safe HTTP REST clients. This package defines the annotations used by code generators to create HTTP client implementations from abstract class definitions.

## Features

- **HTTP Method Annotations**: `@Get`, `@Post`, `@Put`, `@Delete`, `@Patch`
- **Parameter Annotations**: `@Path`, `@Query`, `@Body`, `@Field`, `@Fields`
- **Client Configuration**: `@RestClient` for base URL and client setup
- **File Upload Support**: `FilePart` class for handling file uploads in multipart requests
- **Request Cancellation**: `@Cancel` annotation for cancellable requests
- **URL Fragments**: `@Fragment` annotation for URL fragment handling

## Getting Started

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  http_annotation: ^0.0.1

dev_dependencies:
  http_generator: ^0.0.1
  build_runner: ^2.11.1
```

## Usage

Define your REST API client using annotations:

```dart
import 'package:http/http.dart' as http;
import 'package:http_annotation/http_annotation.dart';

part 'api_client.g.dart';

@RestClient("https://api.example.com")
abstract class ApiClient with _$ApiClient {
  ApiClient(this.client);

  final http.Client client;

  @override
  Future<StreamedResponse> $send(BaseRequest request) {
    return client.send(request);
  }

  @override
  @Get("/users/{id}")
  Future<User> getUser(@Path("id") String userId);

  @override
  @Post("/users")
  Future<User> createUser(@Body() User request);

  @override
  @Get("/users")
  Future<List<User>> getUsers(
    @Query("page") int page,
    @QueryAll() Map<String, dynamic> filters,
  );

  @override
  @Post("/upload", multipart: true)
  Future<UploadResponse> uploadFile(
    @Field("description") String description,
    @Field("file") FilePart file,
  );
}
```

### Available Annotations

#### Client Annotations

- `@RestClient(baseUrl)` - Marks a class as a REST client with optional base URL

#### HTTP Method Annotations

- `@Get(path)` - HTTP GET request
- `@Post(path)` - HTTP POST request  
- `@Put(path)` - HTTP PUT request
- `@Delete(path)` - HTTP DELETE request
- `@Patch(path)` - HTTP PATCH request

Each method annotation supports optional parameters:

- `headers` - Additional headers for the request
- `multipart` - Boolean flag for multipart requests (for file uploads)

Example: `@Post("/upload", multipart: true)`

#### Parameter Annotations

- `@Path("name")` - URL path parameter replacement
- `@Query("name")` - Single query parameter
- `@QueryAll()` - Multiple query parameters from a `Map<String, dynamic>`
- `@Body()` - Request body (JSON serialized by default, use `raw: true` for plain text)
- `@Field("name")` - Single form field
- `@fields` - Multiple form fields from an object or map
- `@Fragment()` - URL fragment
- `@Cancel()` - Request cancellation token

#### File Handling

The `FilePart` class provides several constructors for file uploads:

```dart
// From bytes
final filePart = FilePart.fromBytes(
  bytes, 
  filename: 'document.pdf',
  contentType: MediaType('application', 'pdf'),
);

// From string content
final textPart = FilePart.fromString(
  'Hello, World!',
  filename: 'hello.txt',
  contentType: MediaType('text', 'plain'),
);

// From file path
final imagePart = FilePart.fromPath(
  '/path/to/image.jpg',
  contentType: MediaType('image', 'jpeg'),
);
```

#### Request Cancellation

Use the `@Cancel()` annotation with a `Future<void>` parameter:

```dart
@override
@Get("/long-running-task")
Future<Result> getLongRunningTask(@Cancel() Future<void> cancelToken);

// Usage
final completer = Completer<void>();
final futureResult = client.getLongRunningTask(completer.future);

// Cancel the request after 5 seconds
Timer(Duration(seconds: 5), () => completer.complete());
```

## Code Generation

This package is designed to work with a code generator. After defining your client interface, run:

```bash
dart run build_runner build
```

This will generate the mixin implementation (e.g., `_$ApiClient`) that handles the actual HTTP requests. Your abstract class uses this mixin to provide the HTTP functionality.

### Class Structure

The generated code follows this pattern:

- Your abstract class extends with a generated mixin: `abstract class MyClient with _$MyClient`
- All HTTP methods must be marked with `@override`
- You need to implement a `$send` method that takes a `BaseRequest` and returns a `Future<StreamedResponse>`
- You can inject an `http.Client` or use the default implementation

## Additional Information

- **Repository**: [https://github.com/TekExplorer/http_generator](https://github.com/TekExplorer/http_generator)
- **Issues**: Please file issues on the GitHub repository
- **License**: BSD-3-Clause

This package is part of a larger HTTP client generation system. For the code generator component, see the `http_generator` package.
