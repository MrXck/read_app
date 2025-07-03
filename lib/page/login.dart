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
      appBar: AppBar(
        title: const Center(
          child: Text('登录'),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: width * 0.9,
          child: Column(
            children: [
              SizedBox(
                height: height * 0.2,
              ),
              const Text(
                "用户登录",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "用户名:",
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(
                    width: width * 0.8 * 0.8,
                    child: TextField(
                      controller: usernameController,
                    ),
                  )
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "密    码:",
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(
                    width: width * 0.8 * 0.8,
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
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
                  ElevatedButton(
                      onPressed: () {
                        Get.offNamed('/register');
                      },
                      child: const Text("去注册")),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
