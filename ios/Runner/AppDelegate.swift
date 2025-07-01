import Flutter
import AVFAudio
import UIKit
import Firebase
import app_links

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      FirebaseApp.configure()
      GeneratedPluginRegistrant.register(with: self)
      
      let controller = window?.rootViewController as! FlutterViewController
      let channel = FlutterMethodChannel(name: "com.example.audio",
                                         binaryMessenger: controller.binaryMessenger)

      channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: FlutterResult) in
          if call.method == "enableSpeaker" {
              self?.enableSpeaker()
              result(nil)
          } else {
              result(FlutterMethodNotImplemented)
          }
      }
      if let url = AppLinks.shared.getLink(launchOptions: launchOptions) 
        { 
          AppLinks.shared.handleLink(url: url) 
          return true // Returning true will stop propagation to other packages 
        }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    private func enableSpeaker() {
           let audioSession = AVAudioSession.sharedInstance()
           do {
               try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
               try audioSession.setMode(.videoChat)
               try audioSession.setActive(true)
           } catch {
               print("Failed to set audio session category: \(error)")
           }
       }
}
