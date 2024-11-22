import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "Method", binaryMessenger: controller.binaryMessenger)
    
    // Set up the method call handler
    channel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        guard call.method == "getSum" else {
            result(FlutterMethodNotImplemented)
            return
        }
        
        // Call getSum and pass the result back to Flutter
        let sum = self?.getSum() ?? 0
        result(sum)  // Send the result back to Flutter
    })
    
    // Register plugins
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
  // Function to return the sum
  private func getSum() -> Int {
      print("Swift code running")
      return 2 + 2
  }
}

