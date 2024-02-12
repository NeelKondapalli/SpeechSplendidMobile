//
//  SpeechSplendidApp.swift
//  SpeechSplendid
//
//  Created by Neel Kondapalli on 9/26/23.
//

import SwiftUI

@main
struct SpeechSplendidApp: App {
   // @StateObject private var appData = AppData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppData())
        }
    }
}

class AppData: ObservableObject {
 //   @AppStorage("tokenCount") var tokenCount: Int = 0
//    @Published var wordLimit = 24
//    @Published var adSpanLimit = 2
//    @Published var timeSpan = 0.5
//    @Published var transcript = "Please upload a video to generate a transcript"
//    @Published var wordsMinute: Double = -3.0 //change to -1
//    @Published var fillerPercent: Double = -3.0
//    @Published var tokenResponse: String = ""
//    @Published var emotionResponse = "Please generate an analysis to see tone feedback."
//    @Published var emotionFeedback = ""
//    
//    @Published var topicResponse = "Please generate an analysis to see topic feedback."
//    @Published var topicFeedback = ""
//    
//    @Published var faceEmotionData: [EmotionPoint] = []
//    @Published var selectedVideoURL: URL? = nil
    // Define other properties and methods here
}
