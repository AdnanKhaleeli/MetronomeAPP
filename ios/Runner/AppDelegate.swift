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
    private var lastRecognizedText: String? = nil // Track the last recognized text
    private var lastSentTime: Date? = nil // To control the time interval between sending text
    
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
            self.recognitionRequest?.shouldReportPartialResults = false
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

                    // Throttle: Only send text if it's significantly different or after a short delay
                    let currentTime = Date()
                    if let lastTime = self?.lastSentTime, currentTime.timeIntervalSince(lastTime) < 1.0 {
                        // Do not send if less than 1 second has passed since the last update
                        return
                    }

                    // If the recognized text has changed, or it's a new sentence, send it
                    if recognizedText != self?.lastRecognizedText {
                        self?.lastRecognizedText = recognizedText
                        self?.lastSentTime = currentTime // Update the last sent time
                        result("Recognized Text: \(recognizedText)") // Send the recognized text to Flutter
                        self?.sendToFlutter(recognizedText)
                    }

                } else if let error = error {
                    print("Recognition error: \(error.localizedDescription)")
                    self?.startListening(result: result) // Restart listening if an error occurs
                    result(FlutterError(code: "RECOGNITION_ERROR", message: "Recognition failed", details: error.localizedDescription))
                } else {
                    print("No speech detected")
                    self?.startListening(result: result) // Restart listening if no speech detected
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
        lastRecognizedText = nil // Reset the last recognized text when stopping
        lastSentTime = nil // Reset the time
    }

    // Helper method to send recognized text to Flutter
    func sendToFlutter(_ text: String) {
        channel?.invokeMethod("onSpeechRecognized", arguments: text)
    }
}

