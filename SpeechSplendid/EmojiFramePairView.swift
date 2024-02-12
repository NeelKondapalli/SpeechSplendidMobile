//
//  EmotionFramePairsView.swift
//  SpeechSplendidv3
//
//  Created by Neel Kondapalli on 9/20/23.
//

import Foundation
import SwiftUI
import SwiftUI
//@_spi(Advanced) import SwiftUIIntrospect
import Charts

struct EmotionPoint: Identifiable {
     let emotion: String
     let second: Int
     var id: Int { second }
}
//let data: [EmotionPoint] = [
//    EmotionPoint(emotion: "Happy", frame: 1),
//    EmotionPoint(emotion: "Sad", frame: 25),
//    EmotionPoint(emotion: "Angry", frame: 50)
//]

struct BarChart: View {
    let data: [EmotionPoint]
    var body: some View {
    
        Chart(data) { element in
            // Construct the image name outside of the closure
            let imageName = element.emotion 

            PointMark(
                x: .value("Second", element.second),
                y: .value("Emotion", 0.2)
            )
            .annotation(position: .overlay, alignment: .center) {
                VStack(spacing: 4) {
                    Image(imageName)
                        .resizable()
                        .frame(width: 16, height: 16)
                }
                .symbolRenderingMode(.multicolor)
            }
            .symbolSize(0)
        }
        .chartXScale(range: .plotDimension(padding: 20))
        .chartYAxis(.hidden)
        .chartXAxisLabel(position: .bottom, alignment: .center) {
            Text("Time (seconds)")
        }
    }
}


//struct EmojiSymbolView: View {
//    let emoji: String
//    let emotionEmojiMapping: [String: String] = [
//                "Happy": "😄",
//                "Sad": "😢",
//                "Angry": "😡",
//                "Neutral": "😐",
//                "Disgust": "🤢"
//                // Add more mappings as needed
//    //        ]
//    var body: some View {
//        Text(emoji)
//            .font(.largeTitle)
//    }
//}


//
//struct EmotionPoint: Identifiable {
//     let emotion: String
//     let frame: Int
//     var id: Int { frame }
//}
////let data: [EmotionPoint] = [
////    EmotionPoint(emotion: "Happy", frame: 1),
////    EmotionPoint(emotion: "Sad", frame: 25),
////    EmotionPoint(emotion: "Angry", frame: 50)
////]
//
//struct BarChart: View {
//    let data: [EmotionPoint]
//    var body: some View {
//    
//        Chart(data) { element in
//            // Construct the image name outside of the closure
//            let imageName = element.emotion
//
//            PointMark(
//                x: .value("Frame", element.frame),
//                y: .value("Emotion", 0.2)
//            )
//            .annotation(position: .overlay, alignment: .center) {
//                VStack(spacing: 4) {
//                    Image(imageName)
//                        .resizable()
//                        .frame(width: 16, height: 16)
//                }
//                .symbolRenderingMode(.multicolor)
//            }
//            .symbolSize(0)
//        }
//        .chartXScale(range: .plotDimension(padding: 20))
//        .chartYAxis(.hidden)
//        .chartXAxisLabel(position: .bottom, alignment: .center) {
//            Text("Frame Number")
//        }
//    }
//}
//
//
////struct EmojiSymbolView: View {
////    let emoji: String
////    let emotionEmojiMapping: [String: String] = [
////                "Happy": "😄",
////                "Sad": "😢",
////                "Angry": "😡",
////                "Neutral": "😐",
////                "Disgust": "🤢"
////                // Add more mappings as needed
////    //        ]
////    var body: some View {
////        Text(emoji)
////            .font(.largeTitle)
////    }
////}
//
//
