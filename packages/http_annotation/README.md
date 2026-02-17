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
import 'package:http_annotation/http_annotation.dart';

part 'api_client.g.dart';

@RestClient("https://api.example.com")
abstract class ApiClient {
  factory ApiClient() = _ApiClient;

  @Get("/users/{id}")
  Future<User> getUser(@Path("id") String userId);

  @Post("/users")
  Future<User> createUser(@Body() CreateUserRequest request);

  @Get("/users")
  Future<List<User>> getUsers({
    @Query("page") int? page,
    @Query("limit") int? limit,
  });

  @Post("/upload")
  @multipart
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
- `multipart` - Whether the request should be multipart (for file uploads)

#### Parameter Annotations

- `@Path("name")` - URL path parameter replacement
- `@Query("name")` - Single query parameter
- `@queryAll` - Multiple query parameters from an object
- `@Body()` - Request body (JSON serialized by default)
- `@Field("name")` - Single form field
- `@fields` - Multiple form fields from an object
- `@fragment` - URL fragment
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

This will generate the implementation class (e.g., `_ApiClient`) that handles the actual HTTP requests.

## Additional Information

- **Repository**: [https://github.com/TekExplorer/http_generator](https://github.com/TekExplorer/http_generator)
- **Issues**: Please file issues on the GitHub repository
- **License**: BSD-3-Clause

This package is part of a larger HTTP client generation system. For the code generator component, see the `http_generator` package.
