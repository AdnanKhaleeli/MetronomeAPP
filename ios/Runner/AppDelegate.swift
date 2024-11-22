import Flutter
import UIKit
import Speech
import AVFoundation

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
        
        // Handle "getSum" method call
        if call.method == "getSum" {
            let sum = self?.getSum() ?? 0
            result(sum)  // Send the result back to Flutter
        }
        // Handle "permissions" method call
        else if call.method == "permissions" {
            self?.requestMicrophonePermission { granted in
                if granted {
                    result(true)  // Permission granted
                } else {
                    result(false)  // Permission denied
                }
            }
        }
        // Handle unimplemented method
        else {
            result(FlutterMethodNotImplemented)
        }
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
    
  // Request microphone permission
  func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
    AVAudioSession.sharedInstance().requestRecordPermission { granted in
        DispatchQueue.main.async {
            completion(granted)  // Call completion with the permission status
        }
    }
  }
}

