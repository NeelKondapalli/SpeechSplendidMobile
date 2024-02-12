//
//  AdState.swift
//  SpeechSplendid
//
//  Created by Neel Kondapalli on 10/24/23.
//

import Foundation
import SwiftUI

class AdState: ObservableObject {
    @Published var adLoadedSuccessfully = true // Set the default value to true
}

//let data: [EmotionPoint] = processData(emotionFramePairs: [("happy", 10), ("happy", 30),("neutral", 50),("neutral", 70),("happy", 90),("neutral", 110),("disgusted", 130),("disgusted", 150),("happy", 170),("neutral", 190),("neutral", 210),("fearful", 230),("happy", 250),("sad", 270),("happy", 290)])

//processedResult = "Hello! I hope you are having an amazing day. I am here to present my startup idea, which is revolves around using robots to enhance learning. Um. I am really excited to help improve communication and um...help my community!"
//transcriptLoaded = true
//fillerPercent = (Double(countFillerLanguage(text: processedResult)) / Double(wordCount(text: processedResult)) ) * 100
//wordsMinute = 120
//reportGenerated = true
