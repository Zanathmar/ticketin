import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../models/user_model.dart';

class AuthDatasource {
  final ApiClient _client;

  AuthDatasource(this._client);

  Future<ApiResult<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String role = 'attendee',
  }) async {
    try {
      final response = await _client.post(ApiConstants.register, data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
      });
      final data = response.data as Map<String, dynamic>;
      return ApiResult.success(data);
    } on DioException catch (e) {
      return ApiResult.error(ApiFailure.fromDioError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      return ApiResult.success(data);
    } on DioException catch (e) {
      return ApiResult.error(ApiFailure.fromDioError(e));
    }
  }

  Future<ApiResult<void>> logout() async {
    try {
      await _client.post(ApiConstants.logout);
      await _client.clearToken();
      return ApiResult.success(null);
    } on DioException catch (e) {
      await _client.clearToken();
      return ApiResult.success(null); // Always clear locally
    }
  }

  Future<ApiResult<UserModel>> getMe() async {
    try {
      final response = await _client.get(ApiConstants.me);
      final data = response.data as Map<String, dynamic>;
      return ApiResult.success(UserModel.fromJson(data));
    } on DioException catch (e) {
      return ApiResult.error(ApiFailure.fromDioError(e));
    }
  }
}
