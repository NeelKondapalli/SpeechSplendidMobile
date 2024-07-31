import SwiftUI
import NaturalLanguage
import UIKit
import Foundation
import Combine
import Speech
import AVKit
import Vision
import Charts


struct ContentView: View {
    @EnvironmentObject var appData: AppData
    @ObservedObject var adState = AdState()
    //@StateObject var appData = AppData()
    private var BANNER1_ID: String? = ""
    private var BANNER2_ID: String? = ""
    private var TEST_ID: String? = ""
   // @Environment(\.colorScheme) var colorScheme
    @State private var countdown: Int = 0
    @State private var isGeneratingReport: Bool = false
    @State private var showLingFeedbackPopover: Bool = false
    @State private var cooldownSeconds = UserDefaults.standard.integer(forKey: "cooldownSeconds")
    let maxCooldownSeconds = 15
    @State private var transcriptErrorFlag: Bool = false
    let userDefaultsKey = "cooldownSeconds"
    @State private var disableGenButton: Bool = false
    @State private var showTranscriptPopover = false
    @State private var showTonePopover = false
    @State private var showLingPop: Bool = false
    @State private var audioDuration: Double = 0.0
    @State private var wordsMinute: Double = -1.0
    @State private var fillerPercent: Double = -1.0
    @State private var tokenResponse: String = ""
    @State private var selectedVideoURL: URL? = nil
    @State private var isSelected = false
    @State private var reportGenerated = false
    @State private var invalidVideo = false
    @State private var processedResult: String = ""
    @State private var transcript = "Please upload a video to see your transcript."
    @State private var isTranscriptLoading: Bool = false
    @State private var transcriptLoaded: Bool = false
    
    @State private var showingAlert: Bool = false

    @State private var emotionResponse = "Please generate an analysis to see tone feedback."
    
    @State private var isPickerPresented = false
    @State private var isVideoTooLargeAlertPresented = false
    @State private var adLoaded = false

    @State private var isAnalysisStarted = false
    @State private var videoCaptureManager:VideoCaptureManager? = nil
    @StateObject private var videoCaptureManagerDelegate = VideoCaptureManagerDelegate()

    private var cancellables: Set<AnyCancellable> = []
    @State private var emotionFramePairs: [(String, Int)] = []
    
    enum VideoProcessingError: Error {
        case noVideoTrackFound
        case failedToLoadModel
        case failedToLoadVNCoreMLModel
    }

    init() {
        let ad1 = Bundle.main.object(forInfoDictionaryKey: "BANNER1_ID") as? String

        // Check if the key is not nil and not empty
        if let testad = ad1, !testad.isEmpty {
            // The key is valid, you can use it here
            self.BANNER1_ID = testad
        } else {
            // Handle the case where the key is missing or empty
            print("API key does not exist or is empty")
        }
        
        let ad2 = Bundle.main.object(forInfoDictionaryKey: "BANNER2_ID") as? String

        // Check if the key is not nil and not empty
        if let testad = ad2, !testad.isEmpty {
            // The key is valid, you can use it here
            self.BANNER2_ID = testad
        } else {
            // Handle the case where the key is missing or empty
            print("API key does not exist or is empty")
        }
        
        let ad3 = Bundle.main.object(forInfoDictionaryKey: "TEST_ID") as? String

        // Check if the key is not nil and not empty
        if let testad = ad3, !testad.isEmpty {
            // The key is valid, you can use it here
            self.TEST_ID = testad
        } else {
            // Handle the case where the key is missing or empty
            print("API key does not exist or is empty")
        }
    }
    func startVideoAnalysis() {
        guard let videoURL = selectedVideoURL else {
            print("No video selected")
            return
        }
        print("Starting Analysis of Video")
        if isAnalysisStarted {
            videoCaptureManagerDelegate.stopCapture()
            isAnalysisStarted = false
        } else {
            do {
                try videoCaptureManagerDelegate.startCapture(videoURL: videoURL)
                emotionFramePairs = videoCaptureManagerDelegate.getEmotionFramePairs()
                isAnalysisStarted = true
                invalidVideo = false
            } catch VideoProcessingError.noVideoTrackFound {
                print("Error: A problem occured loading that video.")
                invalidVideo = true
            } catch VideoProcessingError.failedToLoadModel {
                print("Error: A problem occured loading the ML model")
                invalidVideo = true
            } catch VideoProcessingError.failedToLoadVNCoreMLModel {
                print("Error: A problem converting the ML model to VNCoreMLModel.")
                invalidVideo = true
            } catch {
                print("Error: Unknown error: \(error)")
                invalidVideo = true
            }
        }
    }
    
    func stopVideoAnalysis() {
        print("stopping video analysis")
            videoCaptureManager?.stopCapture()
            isAnalysisStarted = false
        }
    
    func processData(emotionFramePairs: [(String, Int)]) -> [EmotionPoint] {
            return emotionFramePairs.map { pair in
                EmotionPoint(emotion: pair.0, second: pair.1)
            }
        }
    
    func toggleVideoAnalysis() {
            if isAnalysisStarted {
                stopVideoAnalysis()
            } else {
                startVideoAnalysis()
            }
        }
    
    private func emotionFramePairsToString() -> String {
            let emotionFramePairs = videoCaptureManagerDelegate.getEmotionFramePairs()
            return emotionFramePairs.map { "\($0.0): \($0.1)" }.joined(separator: ", ")
        }
    
   
    
    
    func processVideo(videoURL: URL?, completion: @escaping (String) -> Void) {
        isSelected = true
        transcriptErrorFlag = false
        guard let videoURL = videoURL else {
            completion("No video selected")
            return
        }

        guard let recognizer = SFSpeechRecognizer() else {
            completion("System doesn't support default language")
            return
        }

        guard recognizer.isAvailable else {
            completion("Recognizer not available")
            return
        }
        
        Task {
                do {
                    let audioURL = try await extractAudioFromVideo(videoURL: videoURL)
                    
                    if let audioURL = audioURL {
                        let request = SFSpeechURLRecognitionRequest(url: audioURL)
                        
                        do {
                            recognizer.recognitionTask(with: request) { result, error in
                                if let result = result {
                                    if result.isFinal {
                                        let transcription = result.bestTranscription.formattedString
                                        //print(transcription)
                                        wordsMinute = (Double(wordCount(text: transcription)) / audioDuration ) * 60
                                        fillerPercent = (Double(countFillerLanguage(text: transcription)) / Double(wordCount(text: transcription)) ) * 100
                                        processedResult = transcription
                                    
                                        completion(transcription)
                                    }
                                } else if let error = error {
                                    print("Error: \(error.localizedDescription)")
                                    processedResult = ""
                                    transcriptErrorFlag = true
                                    completion("\(error.localizedDescription)")
                                }
                            }
                        } catch {
                            print("Error: \(error.localizedDescription)")
                            processedResult = ""
                            transcriptErrorFlag = true
                            completion("\(error.localizedDescription)")
                        }
                    } else {
                        print("Failed to extract audio from video")
                        processedResult = ""
                        transcriptErrorFlag = true
                        completion("Failed to extract audio from video")
                    }
                } catch {
                    print("Error: \(error.localizedDescription)")
                    processedResult = ""
                    transcriptErrorFlag = true
                    completion("\(error.localizedDescription)")
                }
            }
    }
    func printDouble (num: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        let nsNumber = NSNumber(value: num)
        return formatter.string(from: nsNumber) ?? ""
    }
    
    func extractAudioFromVideo(videoURL: URL) async throws -> URL? {
        let asset = AVURLAsset(url: videoURL)
        print("Extracting audio...")
        // Create a unique audio file URL using a timestamp
        let audioFileName = "extractedAudio_\(Date().timeIntervalSince1970).m4a"
        audioDuration = asset.duration.seconds
        
        // Get the document directory URL
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let audioOutputURL = documentsDirectory.appendingPathComponent(audioFileName)
            
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
                return nil
            }
            
            exportSession.outputFileType = .m4a
            exportSession.outputURL = audioOutputURL
            
            do {
                let audioURL = try await withUnsafeContinuation { continuation in
                    exportSession.exportAsynchronously {
                        continuation.resume(returning: exportSession.status == .completed ? audioOutputURL : nil)
                    }
                }
                return audioURL
            } catch {
                return nil
            }
        }
        
        // Unable to get the document directory or export failed, return nil
        return nil
    }
    
    func getResponse(prompt: String, maxTokens: Int, minTokens: Int) async -> String {
        //print("hello")
        let text = processedResult

        let projectedUse = wordCount(text: text)
        let userDefaults = UserDefaults.standard

        if !text.isEmpty {
            do {
                let API = OpenAIConnector()
                let response = try await API.processPrompt(prompt: "\(prompt): \(text)", maxTokens: maxTokens, minTokens: minTokens)
                //let response = "hello"
                return response ?? ""
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        } else {
            print("TEXT IS EMPTY")
        }

        return "Please generate a report to see analysis"
    }


    
    func countFillerLanguage(text: String) -> Int {
        // Define a regular expression pattern to match filler language
        let pattern = "\\b(um|uh|ahh|ah|er|you know|basically|actually|really)\\b"
        
        do {
            // Create a regular expression object
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            
            // Find all matches in the input text
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
            
            // Return the count of matches (occurrences of filler language)
            return matches.count
        } catch {
            // Handle any errors related to regular expressions
            print("Error creating regular expression: \(error)")
            return 0
        }
    }
    
    
    func wordCount(text: String) -> Int {
        let words = text.split(separator: " ")
        return words.count
    }
    
    
    func startCountdown() {
        print("Starting countdown...")
        disableGenButton = true
        let seconds = UserDefaults.standard.integer(forKey: userDefaultsKey)
        cooldownSeconds = seconds != 0 ? seconds : maxCooldownSeconds

        var countdownTimer: DispatchSourceTimer?

        // Create a background task to run the timer
        let backgroundTask = Task {
            countdownTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())

            // Set up the timer to fire every second
            countdownTimer?.schedule(deadline: .now(), repeating: .seconds(1))

            // Set the event handler to update the UI
            countdownTimer?.setEventHandler {
                self.cooldownSeconds -= 1

                print("Seconds remaining... \(self.cooldownSeconds), \(disableGenButton)")

                if self.cooldownSeconds == 0 {
                    // Stop the timer
                    disableGenButton = false
                    countdownTimer?.cancel()
                }

                // Save the remaining seconds in UserDefaults
                UserDefaults.standard.set(self.cooldownSeconds, forKey: userDefaultsKey)
            }

            // Start the timer
            countdownTimer?.resume()
        }

        Task {
            // Start the background task
            await backgroundTask.value
        }
    }

    
    var body: some View {
        VStack() {
            ZStack() {
                //LinearGradient(Color.darkStart, Color.darkEnd)
                ScrollView() {
                    VStack(alignment: .center, spacing: 5) {
                        VStack() {

                            Text("SpeechSplendid")
                                .font(Font.custom("Arial", size: 25))
                                .lineSpacing(22)
                                .foregroundColor(Color.black)
                                .padding(.top, 15)

                            Image("logo")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 200, height: 200)
                                .clipShape(Circle())
                                .background(Color.offWhite)


                            HStack(alignment: .center) {
                                Spacer()
                                Spacer()
                                Button(action:  {
                                    //showingAlert = true
                                }) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.clear)
                                }
                                Spacer()
                                Button("Select Video") {
                                    isPickerPresented = true
                                    print("Video Selected")
                                }
                                //.buttonStyle(FancyButtonStyle())
                                .buttonStyle(FancyButtonStyle())
                                .foregroundColor(Color.black)
                                .padding([.bottom], 20)
                                Spacer()
                                Button(action:  {
                                    showingAlert = true
                                }) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.black)
                                }
                                .alert("Select a speech video to process it. A speech video should be a spoken speech that shows a face clearly in frame throughout the entire speech.\n\nVideos must be 5 minutes or less.", isPresented: $showingAlert) {
                                    Button("OK", role: .cancel) {}
                                }
                                .offset(x: -10, y: -8)
                                
                                Spacer()
                                Spacer()
                            }
                
                      
                        
                    
                          
                
                        
                        
                                
                             


                            if let selectedVideoURL = selectedVideoURL {
                                // URL is not nil, you can access and use it here
                                // You can also check if the URL's absoluteString is empty if needed
                                if !selectedVideoURL.absoluteString.isEmpty {
                                    Button("Process Video") {
                                        reportGenerated = false
                                        isTranscriptLoading = true
                                        transcriptLoaded = false
                                        Task {
                                            await processVideo(videoURL: selectedVideoURL) { transcription in
                                                 //Handle the transcription here
                                                print("Transcription: \(transcription)") // You can print it if needed
                                                processedResult = transcription
                                                isTranscriptLoading = false // Unset loading flag
                                                transcriptLoaded = true
                                            }
                                          
                                            
                                            
                                         }
                                    }
                                    .buttonStyle(FancyButtonStyle())
                                    .foregroundColor(Color.black)
                                    .padding(.bottom, 10)
                                    .padding(.bottom, 10)
                                }
                            }

                            if isTranscriptLoading {
                                Text("Loading transcript...")
                            } else if transcriptLoaded{
                                Button("View Transcript") {
                                    showTranscriptPopover.toggle()

                                }
                                .popover(isPresented: $showTranscriptPopover) {
                                    ScrollView() {
                                        VStack() {
                                            Text("Transcript")
                                                .font(.headline)
                                                .padding([.top, .bottom], 10)
                                            if !processedResult.isEmpty {
                                                Text("\(processedResult)")
                                            } else {
                                                Text("There was a problem creating the transcript. Please try again in a moment or choose a different speech. Ensure your voice is clear.")
                                            }
                                        }
                                    }
                                    .padding(15)
                                }
                                .buttonStyle(FancyButtonStyle())
                                .foregroundColor(Color.black)
                                .padding(.bottom, 10)
                                .padding(.bottom, 10)
                            }



                            Button(action: {
                                if (transcriptLoaded && !transcriptErrorFlag ) {
                                    Task {
                                        withAnimation {
                                            isGeneratingReport = true // Show loading indicator
                                        }
                                        do {
                                            if let response = try? await getResponse(prompt: "First, summarize the text briefly. Then, describe the primary emotions in this text. Second, analyze the sentiment of the text through word choice and polarity. Then, on a newline, list 1 specific tip for the user to improve their writing and tone in the future. What specificially should the user change in this speech? Then, on a newline,  describe the topics and entities in this text. Then, on a newline, explain if the topics are efficiently linked to each other. List 1 specific tip for the user to choose topics better based on the text. Text: ", maxTokens: 250, minTokens: 300) {
                                                emotionResponse = response
                                            } else {
                                                print("getResponse returned empty or nil")
                                                emotionResponse = ""
                                            }
//
                                            self.toggleVideoAnalysis()
                                            self.toggleVideoAnalysis()
                                            print(emotionResponse)

                                            print("Finished Generating")
                                            reportGenerated = true
                                        } catch {
                                            // Handle errors
                                            print("Error: \(error)")
                                        }
                                        withAnimation {
                                            isGeneratingReport = false
                                            //startCoundown()// Hide loading indicator when done
                                            //startCountdown()
                                        }
                                    }
                                }
                            }) {
                                if isGeneratingReport {
                                    ProgressView("Generating Report...") // Show a loading indicator
                                } else if transcriptErrorFlag {
                                    Text("A valid speech is needed to generate a report.")
                                } else if transcriptLoaded {
                                    Text("Generate Report")
                                }
                            }
                            .buttonStyle(FancyButtonStyle())
                            .foregroundColor(transcriptErrorFlag ? Color.gray: Color.black)
                            .disabled(transcriptErrorFlag)




                        }
                        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
                        .NeumorphicStyle()


                        .sheet(isPresented: $isPickerPresented) {
                            VideoPicker(selectedVideoURL: $selectedVideoURL, isVideoTooLargeAlertPresented: $isVideoTooLargeAlertPresented)
                        }

                        .alert(isPresented: $isVideoTooLargeAlertPresented) {
                            Alert(
                                title: Text("Video Too Large"),
                                message: Text("Please select a video that is 5 minutes or less."),
                                dismissButton: .default(Text("OK"))
                            )
                        }



                        VStack () {

                            Text("Linguistic Analysis")
                                .font(Font.custom("Arial", size: 16).weight(.bold))
                                .foregroundColor(Color.black)

                                .padding(.vertical, 18.0)
                            if !reportGenerated {
                                Text("Please generate a report to see linguistic analysis.")
                                    .padding([.top, .bottom], 20)
                            } else {
                                VStack() {
                                    HStack() {
                                        VStack () {
                                            if (wordsMinute != -1.0) {
                                                Text("Words Per Minute: \(printDouble(num: wordsMinute))")
                                                    .font(Font.custom("Arial", size: 14).weight(.bold))
                                                    .foregroundColor(Color.black)
                                                    .offset(x: -20, y: -10)
                                                    .padding([.top, .bottom], 18.0)
                                                    .padding(.trailing, 80.0)

                                            } else {
                                                Text("Words Per Minute: ")
                                                    .font(Font.custom("Arial", size: 14).weight(.bold))
                                                    .foregroundColor(Color.black)
                                                    .offset(x: -20, y: -10)
                                                    .padding([.top, .bottom], 18.0)
                                                    .padding(.trailing, 80.0)


                                            }
                                        }
                                        if (fillerPercent != -1.0) {
                                            Text("Filler Word %: \(printDouble(num: fillerPercent))")
                                                .font(Font.custom("Arial", size: 14).weight(.bold))
                                                .foregroundColor(Color.black)
                                                .offset(x: 10, y: -10)
                                                .padding(.vertical, 5)

                                        } else {
                                            Text("Filler Word %: ")
                                                .font(Font.custom("Arial", size: 14).weight(.bold))
                                                .foregroundColor(Color.black)
                                                .offset(x: 10, y: -10)
                                                .padding(.vertical, 5)
                                        }
                                    }

                                    Button("Linguistic Feedback") {
                                        showLingFeedbackPopover.toggle()

                                    }
                                    .popover(isPresented: $showLingFeedbackPopover) {
                                        ScrollView() {
                                            VStack() {
                                                Text("Linguistic Feedback")
                                                    .font(.headline)
                                                    .padding([.top, .bottom], 10)
                                                Text("WPM: \(printDouble(num: wordsMinute))")
                                                    .font(.headline)
                                                Text("An ideal WPM range for professional conversations is 125-150 WPM. For casual conversations, speaking rate can be slower at 150-180 WPM.")
                                                    .padding(.bottom, 10)
                                                if (wordsMinute < 125) {
                                                    Text("Your WPM fell below both ranges, so consider speaking a little faster.")
                                                        .padding(.bottom, 30)
                                                } else if (wordsMinute>180) {
                                                    Text("Your WPM was above both ranges, so consider slowing down and taking pauses.")
                                                        .padding(.bottom, 30)
                                                } else {
                                                    Text("You had an appropriate WPM in between the ranges. Remember to take pauses when speaking.")
                                                        .padding(.bottom, 30)
                                                }

                                                Text("Filler %: \(printDouble(num: fillerPercent))")
                                                    .font(.headline)
                                                    .padding([.top, .bottom], 10)
                                                Text("Filler language (um, uh, ahh, ah, er, you know, basically, actually, really etc.) generally decreases the confidence of your speech. It should be avoided when possible. Consider taking a pause instead to collect your thoughts.")
                                                    .padding(.bottom, 10)
                                                if (fillerPercent > 10) {
                                                    Text("Your filler percentage was greater than 10%. Pay attention to your language next time and take pauses when you think a filler word will come up.")
                                                        .padding(.bottom, 20)
                                                } else if (fillerPercent == 0) {
                                                    Text("You had minimal filler language! Keep it up, and remember to take pauses when speaking.")
                                                        .padding(.bottom, 20)
                                                }
                                                else if (fillerPercent <= 10) {
                                                    Text("You had 10% or less filler language in your speech. This is good, but be sure to actively try and remove such language to improve the confidence of your speech.")
                                                        .padding(.bottom, 20)
                                                }
                                            }
                                            .padding(15)
                                        }

                                    }
                                    .buttonStyle(FancyButtonStyle())
                                    .foregroundColor(Color.black)
                                    .padding(.bottom, 10)
                                    .padding(.bottom, 10)


                                }
                            }
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .NeumorphicStyle()

//                        if let adID1 = TEST_ID, !adID1.isEmpty {
//                            BannerAd(unitID: adID1).frame(height: 100)
//                        }

//                        if let adID1 = BANNER1_ID, !adID1.isEmpty {
//                            if adState.adLoadedSuccessfully {
//                                BannerAd(adState: adState, unitID: adID1).frame(height: 100)
//                            }
//                        }

                        VStack() {
                            Text("Behavioral Analysis")
                                .font(Font.custom("Arial", size: 16).weight(.bold))
                                .foregroundColor(Color.black)
                                .padding(.vertical, 18.0)
                            if !tokenResponse.isEmpty {
                                Text("Cannot perform semantic analysis. \(tokenResponse)")
                                    .font(Font.custom("Arial", size: 16))
                                    .lineSpacing(22)
                                    .foregroundColor(Color.black)
                                    .padding([.top, .bottom], 20)



                            }

                            if !reportGenerated {
                                Text("Please generate a report to see behavioral analysis.")
                                    .padding([.top, .bottom], 20)
                            }

                            if reportGenerated {
                                HStack() {
                                    Button("Behavioral Analysis") {
                                        showTonePopover.toggle()

                                    }
                                    .popover(isPresented: $showTonePopover) {
                                        ScrollView() {
                                            VStack() {
                                                Text("Behavioral Analysis")
                                                    .font(.headline)
                                                    .padding([.top, .bottom], 10)
                                                if !emotionResponse.isEmpty {
                                                    Text("\(emotionResponse)")
                                                } else {
                                                    Text("Could not generate analsyis. Ensure you have a stable internet connection.")
                                                }
                                            }
                                        }
                                        .padding(15)
                                    }
                                    .buttonStyle(FancyButtonStyle())
                                    .padding(.bottom, 10)
                                    .padding(.bottom, 10)


                                }
                            }

                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .NeumorphicStyle()
                        Spacer()
                        VStack () {
                            Text("Face Emotion Analysis")
                                .font(Font.custom("Arial", size: 16).weight(.bold))
                                .foregroundColor(Color.black)
                                .padding(.vertical, 18.0)
                            if !reportGenerated {
                                Text("Please generate a report to see face expressional analysis.")
                                    .padding([.top, .bottom], 20)
                            } else if invalidVideo {
                                Text("There was a problem analyzing that video. Please select a video with a face clearly in frame.")
                                    .padding([.top, .bottom], 20)
                            } else {
                                let data: [EmotionPoint] = processData(emotionFramePairs: videoCaptureManagerDelegate.getEmotionFramePairs())
                               
                            
                                ScrollView(.horizontal, showsIndicators: true) {
                                    BarChart(data: data)
                                        .frame(minWidth: UIScreen.main.bounds.width, minHeight: 75, maxHeight: 125)
                                }
                            }
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .NeumorphicStyle()

                         if let adID2 = TEST_ID, !adID2.isEmpty {
                             if adState.adLoadedSuccessfully {
                                 BannerAd(adState: adState, unitID: adID2).frame(height: 100)
                             }
                         }

//                         if let adID2 = BANNER2_ID, !adID2.isEmpty {
//                             if adState.adLoadedSuccessfully {
//                                 BannerAd(adState: adState, unitID: adID2).frame(height: 100)
//
//                             }
//                         }

                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    //.background(Color.offWhite)
                    //.ignoresSafeArea()
                }
                //.background(Color.offWhite)
            }
            .background(Color.offWhite)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .edgesIgnoringSafeArea(.all)
      //  .background(Color.offWhite)

        
    }
}

struct DarkBackground<S: Shape>: View {
    var isHighlighted: Bool
    var shape: S
    
    var body: some View {
        ZStack {
            if isHighlighted {
                shape
                    .fill(LinearGradient(Color.darkEnd, Color.darkStart))
                    .shadow(color: Color.darkStart, radius: 10, x: 5, y: 5)
                    .shadow(color: Color.darkEnd, radius: 10, x: -5, y: -5)
            } else {
                shape
                    .fill(LinearGradient(Color.darkStart, Color.darkEnd))
                    .shadow(color: Color.darkStart, radius: 10, x: -10, y: -10)
                    .shadow(color: Color.darkEnd, radius: 10, x: 10, y: 10)
            }
        }
    }
}

struct DarkButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(15)
            .contentShape(RoundedRectangle(cornerRadius: 4))
            .background{
                DarkBackground(isHighlighted: configuration.isPressed, shape: RoundedRectangle(cornerRadius: 4))
            }
            .animation(nil)
    }
}
extension LinearGradient {
    init(_ colors: Color...) {
        self.init(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
struct FancyButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(15)
            .contentShape(RoundedRectangle(cornerRadius: 4))// Add padding to the button
            .background(
                Group {
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.offWhite)
//                            .shadow(color: Color.black.opacity(0.3), radius: 10, x: -5, y: -5) // Add a shadow
//                            .shadow(color: Color.white.opacity(0.7), radius: 10, x: 10, y:10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray, lineWidth: 4)
                                    .blur(radius: 4)
                                    .offset(x: 2, y: 2)
                                    .mask(RoundedRectangle(cornerRadius: 4).fill(LinearGradient(Color.black, Color.clear)))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white, lineWidth: 8)
                                    .blur(radius: 4)
                                    .offset(x: -2, y: -2)
                                    .mask(RoundedRectangle(cornerRadius: 4).fill(LinearGradient(Color.clear, Color.black)))
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.offWhite)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 10, y: 10) // Add a shadow
                            .shadow(color: Color.white.opacity(0.7), radius: 10, x: -5, y:-5)
                        // .cornerRadius(8) // Add rounded corners
                            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // Add a slight scale effect on press
                    }
                }
                    
                    
                    //                colorScheme == .dark ? Color.white : Color.black) // Set the background color to grey
                    )
                }
        
            
            //.foregroundColor(colorScheme == .dark ? Color.black : Color.white) // Set the text color to white
}

struct DisabledButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(15)
            .contentShape(RoundedRectangle(cornerRadius: 4))// Add padding to the button
            .background(
                Group {
                    if configuration.isPressed {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray)
//                            .shadow(color: Color.black.opacity(0.3), radius: 10, x: -5, y: -5) // Add a shadow
//                            .shadow(color: Color.white.opacity(0.7), radius: 10, x: 10, y:10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray, lineWidth: 4)
                                    .blur(radius: 4)
                                    .offset(x: 2, y: 2)
                                    .mask(RoundedRectangle(cornerRadius: 4).fill(LinearGradient(Color.black, Color.clear)))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white, lineWidth: 8)
                                    .blur(radius: 4)
                                    .offset(x: -2, y: -2)
                                    .mask(RoundedRectangle(cornerRadius: 4).fill(LinearGradient(Color.clear, Color.black)))
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 10, y: 10) // Add a shadow
                            .shadow(color: Color.white.opacity(0.7), radius: 10, x: -5, y:-5)
                        // .cornerRadius(8) // Add rounded corners
                            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // Add a slight scale effect on press
                    }
                }
                    
                    
                    //                colorScheme == .dark ? Color.white : Color.black) // Set the background color to grey
                    )
                }
        
            
            //.foregroundColor(colorScheme == .dark ? Color.black : Color.white) // Set the text color to white
}

struct PopoverView: View {
    let option: String
    let content: String
    let feedback: String
    var body: some View {
        VStack {
            Text(option)
                .font(.system(size: 20))
                .padding()
            Text(content)
                .font(.system(size: 16))
                .padding()
            Text(feedback)
                .font(.system(size: 16))
                .padding()
            Spacer()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct VideoPicker: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?
    @Binding var isVideoTooLargeAlertPresented: Bool
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let videoPicker = UIImagePickerController()
        videoPicker.sourceType = .photoLibrary
        videoPicker.mediaTypes = ["public.movie"]
        videoPicker.delegate = context.coordinator
        return videoPicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: VideoPicker

        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            //print("Checking")
            if let videoURL = info[.mediaURL] as? URL {
                let asset = AVAsset(url: videoURL)
                let duration = CMTimeGetSeconds(asset.duration)
                
                if duration <= 300 {
                    print("Video duration: \(duration) seconds")
                    parent.selectedVideoURL = videoURL
                } else {
                    // Video is too long, present an alert
                    print("Video is too long")
                    parent.isVideoTooLargeAlertPresented = true
                }
//                print("Video duration: \(duration) seconds")
//                parent.selectedVideoURL = videoURL
            }

            picker.dismiss(animated: true, completion: nil)
        }

        
        
        func getFileSize(atURL url: URL) -> Int64? {
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let fileSize = fileAttributes[FileAttributeKey.size] as? Int64 {
                    print("Filesize: \(fileSize)")
                    return fileSize
                }
            } catch {
                print("Error: \(error)")
            }
            return nil
        }
    }
}


extension Color {
    static let offWhite = Color(red: 225 / 255, green: 225 / 255, blue: 235 / 255)
    
    static let darkStart = Color(red: 50/255, green: 60/255, blue: 65/255)
    
    static let darkEnd = Color(red: 25/255, green: 25/255, blue: 30/255 )
}

extension View {
    func NeumorphicStyle() -> some View {
        self.padding(30)
            .frame(maxWidth: .infinity)
            .background(Color.offWhite)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 10, y: 10)
            .shadow(color: Color.white.opacity(0.7), radius: 10, x: -5, y: -5)
//            .cornerRadius(20)
//            .background(LinearGradient(Color.darkEnd, Color.darkStart))
//            .shadow(color: Color.darkStart, radius: 10, x: 5, y: 5)
//            .shadow(color: Color.darkEnd, radius: 10, x: -5, y: -5)
        
    }
}

struct NeumorphicCardView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("This is a Neumorphic Card")
                .font(.system(size: 25).bold())
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ")
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
        }
        .NeumorphicStyle()
    }
}



struct User: Codable {
    var tokenCount: Int
    var lastReportGenerationTime: Date?
    // Other user-related attributes, if needed
}

extension Double {
    func rounded(toDecimalPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}


extension View {

    public func popup<PopupContent: View>(
        isPresented: Binding<Bool>,
        view: @escaping () -> PopupContent) -> some View {
        self.modifier(
            Popup(
                isPresented: isPresented,
                view: view)
        )
    }
}

public struct Popup<PopupContent>: ViewModifier where PopupContent: View {
    @State private var presenterContentRect: CGRect = .zero
    
    /// The rect of popup content
    @State private var sheetContentRect: CGRect = .zero
    
    /// The offset when the popup is displayed
    private var displayedOffset: CGFloat {
        -presenterContentRect.midY + screenHeight/2
    }
    
    /// The offset when the popup is hidden
    private var hiddenOffset: CGFloat {
        if presenterContentRect.isEmpty {
            return 1000
        }
        return screenHeight - presenterContentRect.midY + sheetContentRect.height/2 + 5
    }
    
    /// The current offset, based on the "presented" property
    private var currentOffset: CGFloat {
        return isPresented ? displayedOffset : hiddenOffset
    }
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.size.width
    }
    
    private var screenHeight: CGFloat {
        UIScreen.main.bounds.size.height
    }
    
    init(isPresented: Binding<Bool>,
         view: @escaping () -> PopupContent) {
        self._isPresented = isPresented
        self.view = view
    }
    
    /// Controls if the sheet should be presented or not
    @Binding var isPresented: Bool
    
    public func body(content: Content) -> some View {
        ZStack {
            content
              .frameGetter($presenterContentRect)
        }
        .overlay(sheet())
    }

    func sheet() -> some View {
        ZStack {
            self.view()
              .simultaneousGesture(
                  TapGesture().onEnded {
                      dismiss()
              })
              .frameGetter($sheetContentRect)
              .frame(width: screenWidth)
              .offset(x: 0, y: currentOffset)
              .animation(Animation.easeOut(duration: 0.3), value: currentOffset)
        }
    }

    private func dismiss() {
        isPresented = false
    }
    
    /// The content to present
    var view: () -> PopupContent
    
}



extension View {
    func frameGetter(_ frame: Binding<CGRect>) -> some View {
        modifier(FrameGetter(frame: frame))
    }
}
  
struct FrameGetter: ViewModifier {
  
    @Binding var frame: CGRect
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy -> AnyView in
                    let rect = proxy.frame(in: .global)
                    // This avoids an infinite layout loop
                    if rect.integral != self.frame.integral {
                        DispatchQueue.main.async {
                            self.frame = rect
                        }
                    }
                return AnyView(EmptyView())
            })
    }
}

