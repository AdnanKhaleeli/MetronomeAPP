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
    private var channel: FlutterMethodChannel? 
    private var audioSession: AVAudioSession!
    private var lastRecognizedText: String? = nil 
    private var lastSentTime: Date? = nil 
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        channel = FlutterMethodChannel(name: "Method", binaryMessenger: controller.binaryMessenger)
        
       
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
       
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            print("On-device recognition supported")
        } else {
            print("On-device recognition is not supported")
        }

       
        channel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
             if call.method == "permissions" {
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

   
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func startListening(result: @escaping FlutterResult) {
        print("Setting up audio session for recording...")

     
        requestMicrophonePermission { granted in
            guard granted else {
                result(FlutterError(code: "PERMISSION_DENIED", message: "Microphone permission not granted", details: nil))
                return
            }

            
            self.audioSession = AVAudioSession.sharedInstance()
          
            do {
                // Set the category to allow both playback and recording
                try self.audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .allowBluetooth])
                 if let preferredInput = self.audioSession.availableInputs?.first(where: { $0.portType == .builtInMic }) {
                    try self.audioSession.setPreferredInput(preferredInput)
                }
                try self.audioSession.overrideOutputAudioPort(.speaker)
                try self.audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                print("Audio session set up successfully for both playback and recording.")
            } catch {
                result(FlutterError(code: "AUDIO_SESSION_ERROR", message: "Audio session setup failed", details: error.localizedDescription))
                return
            }

           
            self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            self.recognitionRequest?.shouldReportPartialResults = true
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

          
            self.audioEngine = AVAudioEngine()
            let inputNode = self.audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 256, format: recordingFormat) { [weak self] (buffer: AVAudioPCMBuffer, time: AVAudioTime) in
                self?.recognitionRequest?.append(buffer)
            }

          
            self.recognitionTask = self.speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] (speechResult: SFSpeechRecognitionResult?, error: Error?) in
                if let speechResult = speechResult {
                    let recognizedText = speechResult.bestTranscription.formattedString
                    print("Recognized Text: \(recognizedText)")

                 
                    let currentTime = Date()
                    if let lastTime = self?.lastSentTime, currentTime.timeIntervalSince(lastTime) < 0.2 {
                       
                        return
                    }

                    
                    if recognizedText != self?.lastRecognizedText {
                        self?.lastRecognizedText = recognizedText
                        self?.lastSentTime = currentTime 
                        result("Recognized Text: \(recognizedText)") 
                        self?.sendToFlutter(recognizedText)
                    }

                } else if let error = error {
                    print("Recognition error: \(error.localizedDescription)")
                    self?.startListening(result: result) 
                    result(FlutterError(code: "RECOGNITION_ERROR", message: "Recognition failed", details: error.localizedDescription))
                } else {
                    print("No speech detected")
                    self?.startListening(result: result) // Restart listening if no speech detected
                    result(FlutterError(code: "NO_SPEECH_DETECTED", message: "No speech detected", details: nil))
                }
            }

      
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


    func stopListening() {
        print("Stopping listening...")
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        lastRecognizedText = nil 
        lastSentTime = nil 
    }


    func sendToFlutter(_ text: String) {
        channel?.invokeMethod("onSpeechRecognized", arguments: text)
    }
}

