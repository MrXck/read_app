import 'package:dio/dio.dart';

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
    // var value = await SharedPreferences.getInstance();
    // var token = value.getString('token') ?? '';
    // if (token.isNotEmpty) {
    //   options.headers['authorization'] = token;
    // }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // var token = response.headers['authorization']?[0] ?? '';
    // if (token.isNotEmpty) {
    //   SharedPreferences.getInstance().then((value) => value.setString('token', token));
    // }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handlerError(err);
    return handler.next(err);
  }

  void handlerError(DioException err) {
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
  static Future<Response> getForm(String url, Map<String, dynamic>? data, Map<String, String> headers) async {
    if (data == null) {
      return Request.getInstance().dio.get(url,
          options: Options(responseType: ResponseType.plain, headers: headers));
    } else {
      return Request.getInstance().dio.get(url,
          queryParameters: data,
          options: Options(responseType: ResponseType.plain, headers: headers));
    }
  }

  static Future<Response> getJson(String url, Map<String, dynamic>? data, Map<String, String> headers) async {
    if (data == null) {
      return Request.getInstance().dio.get(url,
          options: Options(responseType: ResponseType.json, headers: headers));
    } else {
      return Request.getInstance().dio.get(url,
          queryParameters: data,
          options: Options(responseType: ResponseType.json, headers: headers));
    }
  }

  static Future<Response> postForm(String url, Map? data, Map<String, String> headers) async {
    return Request.getInstance().dio.post(url,
        data: data,
        options: Options(responseType: ResponseType.plain, headers: headers));
  }

  static Future<Response> postJson(String url, Map? data, Map<String, String> headers) async {
    return Request.getInstance().dio.post(url,
        data: data,
        options: Options(responseType: ResponseType.json, headers: headers));
  }
}
