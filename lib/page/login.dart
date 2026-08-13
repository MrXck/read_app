import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:read_app/request/request.dart';
import 'package:read_app/utils/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late double width;
  late double height;
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const FlutterLogo(size: 80.0),
              const SizedBox(height: 40.0),
              const Text('欢迎回来',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              const Text('请登录您的账户', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40.0),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: '用户名',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.account_box_outlined),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                    onPressed: () async {
                      var username = usernameController.text;
                      var password = passwordController.text;
                      if (username.isEmpty || password.isEmpty) {
                        Get.snackbar("提示", "用户名密码不能为空");
                        return;
                      }
                      var result = await RequestUtils.postJson(Constant.loginUrl, {
                        'username': username,
                        'password': password,
                      }, Constant.headers);



                      if (result.data['code'] == 1) {
                        Get.snackbar("提示", result.data['msg']);
                      } else {
                        var shard = await SharedPreferences.getInstance();
                        shard.setString(Constant.tokenKey, result.data['data']['token']);
                        shard.setString("user", const JsonEncoder().convert(result.data['data']['user']));
                        Get.offAndToNamed("/");
                      }
                    }, child: const Text("登录")),
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('还没有账号？'),
                  TextButton(
                      onPressed: () {
                        Get.offNamed('/register');
                      },
                      child: const Text('立即注册',
                          style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold))),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
