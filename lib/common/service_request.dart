import 'dart:async';

import 'package:colorize_logger/colorize_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' as Gett;
import 'package:get_storage/get_storage.dart';
import 'package:oktoast/oktoast.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'MyString.dart';

class ServiceRequest {
  static Future get(
    String url, {
    required Map<String, dynamic>? data,
    required Function? success,
    required Function? error,
  }) async {
    Map<String, dynamic> headers = {};
    // 发送get请求
    await _sendRequest(url, 'get', success!,
        data: data!, headers: headers, error: error!);
  }

  static Future post(
    String url, {
    Map<String, dynamic>? h,
    required Map<String, dynamic>? data,
    required Function? success,
    required Function? error,
  }) async {
    // 发送post请求
    Map<String, dynamic> headers = {};
    if (h != null) {
      headers.addAll(h);
    }
    print("请求头 $headers");
    return _sendRequest(url, 'post', success!,
        data: data!, headers: headers, error: error!);
  }

  static Future put(
    String url, {
    required Map<String, dynamic>? data,
    required Function? success,
    required Function? error,
  }) async {
    // 发送post请求
    Map<String, dynamic> headers = {};
    return _sendRequest(url, 'put', success!,
        data: data!, headers: headers, error: error!);
  }

  ///上传文件
  static Future upload(
    String url, {
    required Map<String, dynamic>? data,
    required Function? success,
    required Function? error,
  }) async {
    // 发送post请求
    Map<String, dynamic> headers = {};
    return _sendRequest(url, 'upload', success!,
        data: data!, headers: headers, error: error!);
  }

  static String _tag = "ServiceRequest";
  static String baseurl = "http://xxxx.jhwangluo.com/";

  // 请求处理
  static Future _sendRequest(String url, String method, Function success,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? headers,
      Function? error}) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    print(data); //  请求传参
    int _code;
    String _msg;
    var _backData;
    String? token = GetStorage().read(MyString.Token);
    String deviceUnique = "";
    token = token ?? "";
    try {
      Map<String, dynamic> dataMap = data ?? {};
      Map<String, dynamic> headersMap = headers ?? {};
      if (token != "") {
        ///请求参数添加token
        headersMap.addAll({
          'token': token,
          'v-name': packageInfo.version,
          'version': packageInfo.buildNumber,
          'unique': deviceUnique,
        });
      }
      Logger.debug("${method}-${headersMap},${url}", tag: _tag);

      // 配置dio请求信息
      Response? response;
      Dio dio = Dio();
      dio.options.connectTimeout = Duration(seconds: 30 * 1000); // 服务器链接超时，毫秒
      // 取消重定向
      dio.options.followRedirects = false;
// 当响应状态不为200时，会拿不到响应数据，于是要先进行设置
      dio.options.validateStatus = (status) {
        return status! < 600;
      };
      dio.options.receiveTimeout =
          Duration(seconds: 3 * 1000); // 响应流上前后两次接受到数据的间隔，毫秒
      dio.options.headers
          .addAll(headersMap); // 添加headers,如需设置统一的headers信息也可在此添加

      url = baseurl + url;
      if (method == 'get') {
        response = await dio.get(url, queryParameters: dataMap);
      } else if (method == 'post') {
        response = await dio.post(url, data: dataMap);
      } else if (method == 'put') {
        response = await dio.put(url, data: dataMap);
      } else if (method == 'upload') {
        FormData formData = FormData.fromMap(dataMap);
        response = await dio.post(url, data: formData);
      }
      print(response); // 返回参数
      // print("状态  ${response?.statusCode.toString()}");
      // print("数据  ${response?.data}");
      /*if (response?.statusCode != 200) {
        _msg = '网络请求错误,状态码:' + response!.statusCode.toString();
        _handError(error!, _msg);
        return;
      }*/
      // 返回结果处理
      Map<String, dynamic> resCallbackMap = response?.data;
      _code = resCallbackMap['code'];
      _msg = resCallbackMap['msg'];
      _backData = resCallbackMap['data'];

      ///401 重新登录
      if (_code.toInt() == 401) {
        Logger.error("需要登录");
        showToast("请先登录");
        // logout();
        return;
      }
      if (_code.toInt() != 1) {
        // Logger.error("数据不妥");
        // _handError(error!, _msg);
      }
      success(resCallbackMap);
    } catch (exception) {
      Logger.error(exception, tag: 'request error');
      if (Gett.Get.isDialogOpen == false) {
        Gett.Get.defaultDialog(
          title: "提示",
          middleText: "数据异常~",
          //确定按钮
          confirm: ElevatedButton(
              onPressed: () {
                //单击后删除弹框
                Gett.Get.back();
              },
              child: const Text("确定")),
        );
      }
    }
  }

  // 返回错误信息
  static Future? _handError(Function errorCallback, String errorMsg) {
    errorCallback(errorMsg);
  }

  ///下载
  static Future<String> downloadImage(url, localFile) async {
    Dio dio = Dio();
    String path = localFile;
    await dio.download(url, path);
    return path;
  }
}
