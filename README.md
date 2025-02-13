## 下载依赖

~~~
flutter pub get
~~~

## 打包

### windows

~~~
1. flutter build windows
2. 打包之后的exe在 build/windows/x64/runner/Release/read_app.exe
3. 将项目根目录下的 sqlite3.dll 复制到 build/windows/x64/runner/Release/ 路径下
~~~

### android

~~~
1. flutter build android
2. 打包之后的apk在 build/app/outputs/apk/release/app-release.apk
~~~