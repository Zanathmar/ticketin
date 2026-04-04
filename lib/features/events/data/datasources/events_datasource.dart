import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../models/event_model.dart';

class EventsDatasource {
  final ApiClient _client;

  EventsDatasource(this._client);

  Future<ApiResult<List<EventModel>>> getEvents({
    bool upcoming = false,
    String? search,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (upcoming) params['upcoming'] = true;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response =
          await _client.get(ApiConstants.events, queryParameters: params);
      final data = response.data as Map<String, dynamic>;
      final items = (data['data'] as List)
          .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(items);
    } on DioException catch (e) {
      return ApiResult.error(ApiFailure.fromDioError(e));
    }
  }

  Future<ApiResult<EventModel>> getEvent(int id) async {
    try {
      final response = await _client.get(ApiConstants.eventById(id));
      return ApiResult.success(
          EventModel.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return ApiResult.error(ApiFailure.fromDioError(e));
    }
  }

  /// Create event — supports multipart file upload or plain JSON with URL.
  Future<ApiResult<EventModel>> createEvent({
    required String title,
    required String description,
    required int capacity,
    required String startTime,
    required String endTime,
    String? imageUrl,
    List<int>? imageBytes,
    String? imageFileName,
    required Map<String, dynamic> venue,
  }) async {
    try {
      final bool hasFile = imageBytes != null && imageBytes.isNotEmpty;

      if (hasFile) {
        // Flatten venue map for FormData (multipart doesn't support nested objects)
        final formData = FormData.fromMap({
          'title': title,
          'description': description,
          'capacity': capacity.toString(),
          'start_time': startTime,
          'end_time': endTime,
          'venue[name]': venue['name'],
          'venue[address]': venue['address'],
          'venue[city]': venue['city'],
          if (venue['state'] != null) 'venue[state]': venue['state'],
          'venue[country]': venue['country'],
          if (venue['postal_code'] != null)
            'venue[postal_code]': venue['postal_code'],
          'image': MultipartFile.fromBytes(
            imageBytes,
            filename: imageFileName ?? 'event_image.jpg',
          ),
        });

        final response = await _client.post(
          ApiConstants.events,
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
        return ApiResult.success(
            EventModel.fromJson(response.data as Map<String, dynamic>));
      } else {
        final response = await _client.post(ApiConstants.events, data: {
          'title': title,
          'description': description,
          'capacity': capacity,
          'start_time': startTime,
          'end_time': endTime,
          if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
          'venue': venue,
        });
        return ApiResult.success(
            EventModel.fromJson(response.data as Map<String, dynamic>));
      }
    } on DioException catch (e) {
      return ApiResult.error(ApiFailure.fromDioError(e));
    }
  }

  /// Update event — supports multipart file upload (POST with _method=PUT)
  /// or plain PUT with JSON / URL.
  Future<ApiResult<EventModel>> updateEvent({
    required int id,
    required String title,
    required String description,
    required int capacity,
    required String startTime,
    required String endTime,
    String? imageUrl,
    List<int>? imageBytes,
    String? imageFileName,
    String? status,
  }) async {
    try {
      final bool hasFile = imageBytes != null && imageBytes.isNotEmpty;

      if (hasFile) {
        // Laravel doesn't support PUT with multipart, so we POST with _method=PUT
        final formData = FormData.fromMap({
          '_method': 'PUT',
          'title': title,
          'description': description,
          'capacity': capacity.toString(),
          'start_time': startTime,
          'end_time': endTime,
          if (status != null) 'status': status,
          'image': MultipartFile.fromBytes(
            imageBytes,
            filename: imageFileName ?? 'event_image.jpg',
          ),
        });

        final response = await _client.post(
          ApiConstants.eventById(id),
          data: formData,
          options: Options(contentType: 'multipart/form-data'),
        );
        return ApiResult.success(
            EventModel.fromJson(response.data as Map<String, dynamic>));
      } else {
        final response = await _client.put(ApiConstants.eventById(id), data: {
          'title': title,
          'description': description,
          'capacity': capacity,
          'start_time': startTime,
          'end_time': endTime,
          if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
          if (status != null) 'status': status,
        });
        return ApiResult.success(
            EventModel.fromJson(response.data as Map<String, dynamic>));
      }
    } on DioException catch (e) {
      return ApiResult.error(ApiFailure.fromDioError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> registerForEvent(int eventId) async {
    try {
      final response = await _client.post(ApiConstants.eventRegister(eventId));
      return ApiResult.success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return ApiResult.error(ApiFailure.fromDioError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> getQrCode(int eventId) async {
    try {
      final response = await _client.get(ApiConstants.eventQrCode(eventId));
      return ApiResult.success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return ApiResult.error(ApiFailure.fromDioError(e));
    }
  }

  Future<ApiResult<List<Map<String, dynamic>>>> getMyRegistrations() async {
    try {
      final response = await _client.get(ApiConstants.myRegistrations);
      final items = (response.data as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      return ApiResult.success(items);
    } on DioException catch (e) {
      return ApiResult.error(ApiFailure.fromDioError(e));
    }
  }
}