import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:read_app/request/request.dart';
import 'package:read_app/utils/constant.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late double width;
  late double height;
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController repeatPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const FlutterLogo(size: 80.0),
              const SizedBox(height: 30.0),
              const Text(
                '创建新账户',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              const Text(
                '请填写以下信息完成注册',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40.0),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: '用户名',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '设置密码',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: repeatPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '确认密码',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(onPressed: () async {
                  var username = usernameController.text;
                  var password = passwordController.text;
                  var repeatPassword = repeatPasswordController.text;
                  if (username.isEmpty || password.isEmpty) {
                    Get.snackbar("提示", "用户名密码不能为空");
                    return;
                  }
                  if (password != repeatPassword) {
                    Get.snackbar("提示", "两次输入的密码不一致");
                    return;
                  }
                  var result = await RequestUtils.postJson(Constant.registerUrl, {
                    'username': username,
                    'password': password,
                  }, Constant.headers);
                  if (result.data['code'] == 1) {
                    Get.snackbar("提示", result.data['msg']);
                  } else {
                    Get.toNamed("/login");
                  }

                }, child: const Text("注册")),
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('已有账号？'),
                  GestureDetector(
                    onTap: () {
                      Get.offNamed('/login');
                    },
                    child: const Text(
                      '去登录',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
