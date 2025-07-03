import 'package:dio/dio.dart';
import 'package:get/get.dart' as Get;
import 'package:read_app/utils/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Request {
  static Request? _instance = Request._internal();

  late Dio dio;

  static Request getInstance() {
    _instance ??= Request._internal();
    return _instance!;
  }

  Request._internal() {
    BaseOptions options = BaseOptions(
        baseUrl: '',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json;Charset=UTF-8',
        responseType: ResponseType.json);
    dio = Dio(options);
    dio.interceptors.add(RequestInterceptor());
  }
}

class RequestInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.path.startsWith(Constant.syncUrl)) {
      var value = await SharedPreferences.getInstance();
      var token = value.getString('token') ?? '';
      if (token.isNotEmpty) {
        options.headers['authorization'] = token;
      }
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.path.startsWith(Constant.syncUrl)) {
      if (response.statusCode == 401) {
        Get.Get.offNamed('login');
      }
      var token = response.headers['authorization']?[0] ?? '';
      if (token.isNotEmpty) {
        SharedPreferences.getInstance()
            .then((value) => value.setString('token', token));
      }
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handlerError(err);
    return handler.next(err);
  }

  void handlerError(DioException err) {
    if (err.response?.statusCode == 401) {
      Get.Get.offNamed('/login');
    }

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        break;
      case DioExceptionType.sendTimeout:
        break;
      case DioExceptionType.receiveTimeout:
        break;
      case DioExceptionType.badCertificate:
        break;
      case DioExceptionType.badResponse:
        break;
      case DioExceptionType.cancel:
        break;
      case DioExceptionType.connectionError:
        break;
      case DioExceptionType.unknown:
        break;
      default:
        break;
    }
  }
}

class RequestUtils {
  static Future<Response> getForm(String url, Map<String, dynamic>? data,
      Map<String, String> headers) async {
    if (data == null) {
      return Request.getInstance().dio.get(url,
          options: Options(responseType: ResponseType.plain, headers: headers));
    } else {
      return Request.getInstance().dio.get(url,
          queryParameters: data,
          options: Options(responseType: ResponseType.plain, headers: headers));
    }
  }

  static Future<Response> getJson(String url, Map<String, dynamic>? data,
      Map<String, String> headers) async {
    if (data == null) {
      return Request.getInstance().dio.get(url,
          options: Options(responseType: ResponseType.json, headers: headers));
    } else {
      return Request.getInstance().dio.get(url,
          queryParameters: data,
          options: Options(responseType: ResponseType.json, headers: headers));
    }
  }

  static Future<Response> postForm(
      String url, Map? data, Map<String, String> headers) async {
    return Request.getInstance().dio.post(url,
        data: data,
        options: Options(responseType: ResponseType.plain, headers: headers));
  }

  static Future<Response> postJson(
      String url, Map? data, Map<String, String> headers) async {
    return Request.getInstance().dio.post(url,
        data: data,
        options: Options(responseType: ResponseType.json, headers: headers));
  }

  static Future<Response> postFileJson(
      String url, FormData? data, Map<String, String> headers) async {
    return Request.getInstance().dio.post(url,
        data: data,
        options: Options(responseType: ResponseType.json, headers: headers, contentType: 'multipart/form-data'));
  }
  
  static Future<Response> getDownloadFile(String url, String savePath) async {
    return Request.getInstance().dio.download(url, savePath);
  }
}
