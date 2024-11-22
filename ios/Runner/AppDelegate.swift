import Flutter
import UIKit
import Speech
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {

    // Declare audio engine, speech recognizer, and other variables for continuous listening
    private var audioEngine: AVAudioEngine!
    private var speechRecognizer: SFSpeechRecognizer!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Setup Flutter channel
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "Method", binaryMessenger: controller.binaryMessenger)
        
        // Initialize the speech recognizer for English (US)
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        // Check if the recognizer supports on-device recognition
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            print("On-device recognition supported")
        } else {
            print("On-device recognition is not supported")
        }

        // Channel handler
        channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "getSum" {
                let sum = self?.getSum() ?? 0
                result(sum)
            } else if call.method == "permissions" {
                self?.requestMicrophonePermission { granted in
                    result(granted)
                }
            } else if call.method == "startListening" {
                self?.startListening(result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Function to return the sum (just for testing)
    private func getSum() -> Int {
        print("Swift code running")
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

    // Start continuous listening for speech
    func startListening(result: @escaping FlutterResult) {
        // Set up the AVAudioSession for recording
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            result(FlutterError(code: "AUDIO_SESSION_ERROR", message: "Audio session setup failed", details: error.localizedDescription))
            return
        }

        // Create a new recognition request and audio engine every time
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        // Check if the recognizer supports on-device recognition
        if let recognitionRequest = recognitionRequest {
            // Set the recognition request to use on-device recognition
            recognitionRequest.requiresOnDeviceRecognition = true
        }

        guard let recognitionRequest = recognitionRequest else {
            result(FlutterError(code: "REQUEST_ERROR", message: "Failed to create recognition request", details: nil))
            return
        }

        // Initialize the audio engine and set up the input node
        audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Install a tap on the audio input node to get microphone input in real-time
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer: AVAudioPCMBuffer, time: AVAudioTime) in
            self?.recognitionRequest?.append(buffer)
        }

        // Create a new recognition task for each listening session
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] (speechResult: SFSpeechRecognitionResult?, error: Error?) in
            if let speechResult = speechResult {
                let recognizedText = speechResult.bestTranscription.formattedString
                print("Recognized Text: \(recognizedText)")
                result("Recognized Text: \(recognizedText)")
                
                // After recognizing the speech, recreate the task to listen for new input
                self?.restartListening()
            }

            if let error = error {
                print("Recognition error: \(error.localizedDescription)")
                self?.restartListening()
                result(FlutterError(code: "RECOGNITION_ERROR", message: "Recognition failed", details: error.localizedDescription))
            }
        }

        // Prepare and start the audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            result(FlutterError(code: "AUDIO_ENGINE_ERROR", message: "Audio engine failed to start", details: error.localizedDescription))
        }

        print("Listening started...")
    }

    // Stop continuous listening (if needed)
    func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    // Recreate the listening process to keep it continuous
    func restartListening() {
        // Stop and reset the current task and session
        stopListening()

        // Restart listening after a small delay to avoid any race conditions
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.startListening { result in
                // Optionally handle the result or errors
            }
        }
    }
}

