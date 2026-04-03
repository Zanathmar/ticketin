import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';

class CheckInDatasource {
  final ApiClient _client;

  CheckInDatasource(this._client);

  Future<ApiResult<Map<String, dynamic>>> checkIn(String qrData) async {
    try {
      final response = await _client.post(ApiConstants.checkIn, data: {
        'qr_data': qrData,
      });
      return ApiResult.success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return ApiResult.error(ApiFailure.fromDioError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> checkOut(String qrData) async {
    try {
      final response = await _client.post(ApiConstants.checkOut, data: {
        'qr_data': qrData,
      });
      return ApiResult.success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return ApiResult.error(ApiFailure.fromDioError(e));
    }
  }
}
