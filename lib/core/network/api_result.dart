import 'package:dio/dio.dart';

class ApiFailure {
  final String message;
  final int? statusCode;

  const ApiFailure({required this.message, this.statusCode});

  factory ApiFailure.fromDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiFailure(
            message: 'Connection timed out. Please check your internet.');

      case DioExceptionType.connectionError:
        // On Flutter Web, CORS errors show up as connectionError.
        // On mobile, this is a genuine network issue.
        final msg = e.message?.toLowerCase() ?? '';
        if (msg.contains('xmlhttprequest') ||
            msg.contains('cors') ||
            msg.contains('failed')) {
          return ApiFailure(
            message:
                'CORS error — add the Flutter Web origin to Laravel\'s config/cors.php '
                '(allowed_origins: ["*"]). Raw: ${e.message}',
          );
        }
        return ApiFailure(
          message:
              'Cannot reach server. Check that Laravel is running and the base URL is correct.\n'
              'Current URL: ${e.requestOptions.baseUrl}\n'
              'Error: ${e.message}',
        );

      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final data = e.response?.data;
        String msg = 'Server error ($code).';
        if (data is Map) {
          if (data.containsKey('message')) {
            msg = data['message'];
          } else if (data.containsKey('errors')) {
            final errors = data['errors'] as Map;
            msg = errors.values
                .expand((v) => v is List ? v : [v])
                .join('\n');
          }
        }
        return ApiFailure(message: msg, statusCode: code);

      case DioExceptionType.cancel:
        return const ApiFailure(message: 'Request was cancelled.');

      default:
        return ApiFailure(
            message: e.message ?? 'An unexpected error occurred.');
    }
  }
}

class ApiResult<T> {
  final T? data;
  final ApiFailure? failure;

  const ApiResult._({this.data, this.failure});

  factory ApiResult.success(T data) => ApiResult._(data: data);
  factory ApiResult.error(ApiFailure failure) => ApiResult._(failure: failure);

  bool get isSuccess => failure == null;
  bool get isError => failure != null;
}
