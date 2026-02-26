// iOS URL Scheme 配置
// 在 ios/Runner/Info.plist 中添加：

/*
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.example.accounting</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>accounting</string>
    </array>
  </dict>
</array>
*/

// AppDelegate.swift 中添加 URL 处理：
/*
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // 发送 URL 到 Flutter
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.example.accounting/url",
        binaryMessenger: controller.binaryMessenger
      )
      channel.invokeMethod("handleUrl", arguments: url.absoluteString)
    }
    return true
  }
}
*/
