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
          child: Text('注册'),
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
                "用户注册",
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
                    child: ElevatedButton(onPressed: () async {
                      var username = usernameController.text;
                      var password = passwordController.text;
                      if (username.isEmpty || password.isEmpty) {
                        Get.snackbar("提示", "用户名密码不能为空");
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
                  ElevatedButton(
                      onPressed: () {
                        Get.offNamed('/login');
                      },
                      child: const Text("去登录")),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
