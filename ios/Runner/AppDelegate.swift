import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // تسجيل iOS Privacy Guard Plugin المخصص
    if let controller = window?.rootViewController as? FlutterViewController {
      let registrar = self.registrar(forPlugin: "IOSPrivacyGuardPlugin")!
      IOSPrivacyGuardPlugin.register(with: registrar)
      print("✅ iOS Privacy Guard Plugin registered successfully")
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
