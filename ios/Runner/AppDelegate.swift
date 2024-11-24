import Flutter
import UIKit
import Speech
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {

    private var audioEngine: AVAudioEngine!
    private var speechRecognizer: SFSpeechRecognizer!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var channel: FlutterMethodChannel? // Reference to the Flutter channel
    private var audioSession: AVAudioSession!
   
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        channel = FlutterMethodChannel(name: "Method", binaryMessenger: controller.binaryMessenger)
        
        // Initialize speech recognizer for English (US)
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        // Check if the recognizer supports on-device recognition
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            print("On-device recognition supported")
        } else {
            print("On-device recognition is not supported")
        }

        // Channel handler for Flutter method calls
        channel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "getSum" {
                let sum = self?.getSum() ?? 0
                result(sum)
            } else if call.method == "permissions" {
                self?.requestMicrophonePermission { granted in
                    result(granted)
                }
            } else if call.method == "startListening" {
                self?.startListening(result: result)
            } else if call.method == "stopListening" {
                self?.stopListening()
                result("Listening stopped")
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func getSum() -> Int {
        return 2 + 2
    }

    // Request microphone permission
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func startListening(result: @escaping FlutterResult) {
        print("Setting up audio session for recording...")

        // Ensure microphone permission is granted before starting
        requestMicrophonePermission { granted in
            guard granted else {
                result(FlutterError(code: "PERMISSION_DENIED", message: "Microphone permission not granted", details: nil))
                return
            }

            // Set up the AVAudioSession for recording
            self.audioSession = AVAudioSession.sharedInstance()
            do {
                try self.audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers, .allowBluetooth])
                try self.audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                print("Audio session set up successfully.")
            } catch {
                result(FlutterError(code: "AUDIO_SESSION_ERROR", message: "Audio session setup failed", details: error.localizedDescription))
                return
            }

            // Create a new recognition request and audio engine every time
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            //self.recognitionRequest?.shouldReportPartialResults = true

            // Set requiresOnDeviceRecognition based on whether it's supported
            if let speechRecognizer = self.speechRecognizer, speechRecognizer.supportsOnDeviceRecognition {
                self.recognitionRequest?.requiresOnDeviceRecognition = true
                print("Using on-device recognition.")
            } else {
                self.recognitionRequest?.requiresOnDeviceRecognition = false
                print("Using server-based recognition.")
            }

            guard let recognitionRequest = self.recognitionRequest else {
                result(FlutterError(code: "REQUEST_ERROR", message: "Failed to create recognition request", details: nil))
                return
            }

            // Initialize the audio engine and set up the input node
            self.audioEngine = AVAudioEngine()
            let inputNode = self.audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer: AVAudioPCMBuffer, time: AVAudioTime) in
                self?.recognitionRequest?.append(buffer)
            }

            // Create a new recognition task for each listening session
            self.recognitionTask = self.speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] (speechResult: SFSpeechRecognitionResult?, error: Error?) in
                if let speechResult = speechResult {
                    let recognizedText = speechResult.bestTranscription.formattedString
                    print("Recognized Text: \(recognizedText)")
                    result("Recognized Text: \(recognizedText)") // Send the recognized text to Flutter
                    self?.sendToFlutter(recognizedText)
                  
                } else if let error = error {
                    print("Recognition error: \(error.localizedDescription)")
                    self?.restartListening() // Restart listening if an error occurs
                    result(FlutterError(code: "RECOGNITION_ERROR", message: "Recognition failed", details: error.localizedDescription))
                } else {
                    print("No speech detected")
                    self?.restartListening() // Restart listening if no speech detected
                    result(FlutterError(code: "NO_SPEECH_DETECTED", message: "No speech detected", details: nil))
                }
            }

            // Prepare and start the audio engine
            self.audioEngine.prepare()
            do {
                try self.audioEngine.start()
                print("Audio engine started successfully.")
            } catch {
                result(FlutterError(code: "AUDIO_ENGINE_ERROR", message: "Audio engine failed to start", details: error.localizedDescription))
            }

            print("Listening started...")
        }
    }

    // Stop continuous listening
    func stopListening() {
        print("Stopping listening...")
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    func restartListening() {
        // Stop and reset the current task and session
        stopListening()
        
        // Re-initialize everything
        recognitionRequest = nil
        recognitionTask = nil
        
        // Deactivate the audio session before setting a new category
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            print("Audio session deactivated.")
        } catch {
            print("Error deactivating audio session: \(error.localizedDescription)")
        }
        
        // Set the new audio session category
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session restarted and activated.")
        } catch {
            // Handle error if setting the audio session category fails
            print("Error setting audio session category: \(error.localizedDescription)")
        }
        
        // Initialize a new audio engine to avoid issues with the old one
        self.audioEngine.reset()
        
        // Call startListening after a small delay to avoid any race conditions
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.startListening(result: { _ in
                // Optionally handle result or errors
            })
        }
    }

    // Helper method to send recognized text to Flutter
    func sendToFlutter(_ text: String) {
        channel?.invokeMethod("onSpeechRecognized", arguments: text)
    }
}

