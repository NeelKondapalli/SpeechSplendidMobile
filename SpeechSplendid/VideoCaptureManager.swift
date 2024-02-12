
import SwiftUI
import NaturalLanguage
import UIKit
import Foundation
import Combine
import Speech
import AVKit
import Vision
import AVFoundation
import Vision
import CoreVideo
import CoreML
import AVFoundation
import CoreImage
protocol VideoCaptureDelegate: AnyObject {
    func didCaptureVideoFrame(sampleBuffer: CMSampleBuffer)
}
class VideoCaptureManager: ObservableObject {
//    private let batchSize = 10
//    private var frameBuffer: [CMSampleBuffer] = []
    @Published var isCapturing: Bool = false
    weak var delegate: VideoCaptureManagerDelegate? 
    private var frameCount = 0
    private var asset: AVAsset
    private var assetReader: AVAssetReader?
    //private let emotionAnalyzer = EmotionAnalyzer()
    private let model: VNCoreMLModel
    private var emotionFramePairs: [(String, Int)] = []
    private var numFrames: Int
    private var increment: Int
    private var targetFrame = 0
    private var frameRate: Float

    enum VideoProcessingError: Error {
        case noVideoTrackFound
        case failedToLoadModel
        case failedToLoadVNCoreMLModel
    }
    
    init(videoURL: URL) throws {
//        guard let videoAsset = AVAsset(url: videoURL) else {
//            fatalError("")
//        }
        self.asset = AVAsset(url: videoURL)
//        if self.asset.tracks(withMediaType: .video).isEmpty {
//                    fatalError("No video track found in the asset.")
//        }
        
        guard !self.asset.tracks(withMediaType: .video).isEmpty else {
                throw VideoProcessingError.noVideoTrackFound
        }
        
        let duration = CMTimeGetSeconds(self.asset.duration)
        self.frameRate = self.asset.tracks(withMediaType: .video).first?.nominalFrameRate ?? 30.0
        self.numFrames = Int(duration * Double(frameRate))
        self.increment = Int(Double(numFrames)/15)
        guard let mlModel = try? EmotionClassifier(configuration: MLModelConfiguration()).model else {
                throw VideoProcessingError.failedToLoadModel
        }
        
//        guard let mlModel = try? EmotionClassifier(configuration: MLModelConfiguration()).model else {
//            fatalError("Failed to load the CNNEmotions model.")
//        }
        
        guard let model = try? VNCoreMLModel(for: mlModel) else {
            throw VideoProcessingError.failedToLoadVNCoreMLModel
        }
        self.model = model
        
//        do {
//            model = try VNCoreMLModel(for: mlModel) // Convert the MLModel to VNCoreMLModel
//        } catch {
//            fatalError("Failed to create the VNCoreMLModel: \(error)")
//        }
    }
    private func didCaptureVideoFrame(sampleBuffer: CMSampleBuffer) {
        //let increment = Int(Double(numFrames)/15)
//        if frameCount % 40 == 0 {
//            if detectFaceInFrame(sampleBuffer) {
//                    print("Face detected on frame \(frameCount)")
//                    //print("in: \(self.getEmotionFramePairs())")
//                }
//            }
//        if frameCount == -1 {
//            print("Analyzing frame: \(targetFrame); Frames: \(numFrames); Increment: \(increment)")
//            targetFrame += increment
//            if detectFaceInFrame(sampleBuffer) {
//                    print("Face detected on frame \(frameCount)")
//                    //print("in: \(self.getEmotionFramePairs())")
//                }
//            }
//       
//            //print("outin: \(self.getEmotionFramePairs())")
//            // Notify observers or delegate if necessary
        
        print("Analyzing frame: \(targetFrame); Frames: \(numFrames); Increment: \(increment); FrameIndex: \(frameCount)")
        if detectFaceInFrame(sampleBuffer) {
            print("Face detected on frame \(frameCount)")
        
                //print("in: \(self.getEmotionFramePairs())")
        }
        delegate?.didCaptureVideoFrame(sampleBuffer: sampleBuffer, emotionFramePairs: emotionFramePairs)

            // Increment the frame counter
        //frameCount += 1
    }
     


    private func resizeImage(_ image: CIImage, to size: CGSize) -> CIImage {
        let scaleX = size.width / image.extent.width
        let scaleY = size.height / image.extent.height
        return image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
    
    private func detectFaceInFrame(_ sampleBuffer: CMSampleBuffer) -> Bool{
            // ... (your existing face detection logic)

            let faceDetectionRequest = VNDetectFaceRectanglesRequest()

            // Perform face detection on the provided sample buffer
            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer)
            do {
                try handler.perform([faceDetectionRequest])
            } catch {
                print("Error performing face detection: \(error)")
                return false
            }

            if let results = faceDetectionRequest.results as? [VNFaceObservation], !results.isEmpty {
                // A face is detected in the frame
                if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                    // Convert the pixel buffer to a CIImage
                    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                
                    let resizedImage = ciImage.transformed(by: CGAffineTransform(scaleX: 299.0 / CGFloat(ciImage.extent.width), y: 299.0 / CGFloat(ciImage.extent.height)))
                    // Call the emotion analyzer with the CIImage
                    self.analyzeEmotion(image: resizedImage, frameNumber: frameCount)

                   // print("Printing")

                    //self.emotions = emotionAnalyzer.getEmotionFramePairs()
                   // print(self.emotions)
                }
            } else {
                // No face detected in the frame
                print("No face detected")
                return false
            }
//        print(self.emotions)
        return true
        }

    func updateEmotionFrames(FramePair: (String, Int)) {
        DispatchQueue.main.async {
            self.emotionFramePairs.append(FramePair)
        }
    }
//    
    func analyzeEmotion(image: CIImage, frameNumber: Int) {
        // Resize the image to 224x224
//        let resizedImage = image
//            .transformed(by: CGAffineTransform(scaleX: 224.0 / CGFloat(image.extent.width), y: 224.0 / CGFloat(image.extent.height)))
        
        // Create a request for emotion analysis
        let request = VNCoreMLRequest(model: model) { request, _ in
            if let results = request.results as? [VNClassificationObservation], let topResult = results.first {
                // The top result contains the predicted emotion and confidence
                let classLabel = topResult.identifier
                print(classLabel)
                let confidences = topResult.confidence
                print(confidences)
                let confidence = topResult.confidence
                self.emotionFramePairs.append((classLabel, Int(Double(frameNumber)/Double(self.frameRate))))
               // print(self.emotionFramePairs)
                //print("Emotion: \(emotion), Confidence: \(confidence)")
            }
        }

        // Create a Vision request handler
        let handler = VNImageRequestHandler(ciImage: image, options: [:])

        do {
            // Perform emotion analysis
            try handler.perform([request])
        } catch {
            print("Error performing emotion analysis: \(error)")
        }

    }
    func getEmotionFramePairs() -> [(String, Int)] {
       // print(self.emotionFramePairs)
        return self.emotionFramePairs
        }
    func startCapture() {
//        guard let asset = asset else {
//            print("Failed to initialize AVAsset.")
//            return
//        }
        if self.asset.tracks(withMediaType: .video).isEmpty {
            print("Failed to initialize AVAsset.")
            return
        }
        print("capturing")

//        do {
//            assetReader = try AVAssetReader(asset: self.asset)
//        } catch {
//            print("Failed to create AVAssetReader: \(error)")
//            return
//        }

        guard let videoTrack = self.asset.tracks(withMediaType: .video).first else {
            print("Video track not found in the asset.")
            return
        }

        let videoSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]

        let videoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoSettings)
        assetReader = try? AVAssetReader(asset: self.asset)
        assetReader?.add(videoOutput)
        assetReader?.startReading()
        
        //print("helloTESTING5")
        
        //var frameIndex = 0
        self.frameCount = 0
        while let sampleBuffer = videoOutput.copyNextSampleBuffer() {
            if self.frameCount % self.increment == 0 {
                
                self.didCaptureVideoFrame(sampleBuffer: sampleBuffer)
                
            }
            self.frameCount += 1
            
            if self.frameCount >= self.numFrames {
                break
            }
            // Notify observers (your SwiftUI view) that a frame is captured
        }

//        }
//        while let sampleBuffer = videoOutput.copyNextSampleBuffer() {
//                frameBuffer.append(sampleBuffer)
//
//                if frameBuffer.count >= batchSize {
//                    processFrameBatch()
//                }
//            }



        // Notify observers (your SwiftUI view) when capture is stopped
        DispatchQueue.main.async {
            self.isCapturing = false
        }
       // self.isCapturing = false

        assetReader?.cancelReading()
    }
    
//    func processFrameBatch() {
//        // Process the frames in the batch
//        for sampleBuffer in frameBuffer {
//            DispatchQueue.global().async {
//                self.didCaptureVideoFrame(sampleBuffer: sampleBuffer)
//            }
//        }
//
//        // Clear the processed frames
//        frameBuffer.removeAll()
//    }

    func stopCapture() {
        assetReader?.cancelReading()
    }
    
    func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) async {
        // You can add asynchronous processing logic here
        // For example, call detectFaceInFrame and await it if it's asynchronous
        await didCaptureVideoFrame(sampleBuffer: sampleBuffer)
        // Notify observers or delegate if necessary
        delegate?.didCaptureVideoFrame(sampleBuffer: sampleBuffer, emotionFramePairs: emotionFramePairs)
        
        // Increment the frame counter
        frameCount += 1
    }

    
}


//extension VideoCaptureManager: AVCaptureVideoDataOutputSampleBufferDelegate {
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        delegate?.didCaptureVideoFrame(sampleBuffer: sampleBuffer)
//    }
//}


//func startCapture() {
////        guard let asset = asset else {
////            print("Failed to initialize AVAsset.")
////            return
////        }
//    if self.asset.tracks(withMediaType: .video).isEmpty {
//        print("Failed to initialize AVAsset.")
//        return
//    }
//    print("capturing")
//
//    do {
//        assetReader = try AVAssetReader(asset: self.asset)
//    } catch {
//        print("Failed to create AVAssetReader: \(error)")
//        return
//    }
//
//    guard let videoTrack = self.asset.tracks(withMediaType: .video).first else {
//        print("Video track not found in the asset.")
//        return
//    }
//
//    let videoSettings: [String: Any] = [
//        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
//    ]
//
//    let videoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoSettings)
//    assetReader?.add(videoOutput)
//    assetReader?.startReading()
//    print("helloTESTING5")
//    while let sampleBuffer = videoOutput.copyNextSampleBuffer() {
//        // Notify observers (your SwiftUI view) that a frame is captured
//        DispatchQueue.main.async {
//            self.didCaptureVideoFrame(sampleBuffer: sampleBuffer)
//        }
//    }
//
////        }
////        while let sampleBuffer = videoOutput.copyNextSampleBuffer() {
////                frameBuffer.append(sampleBuffer)
////
////                if frameBuffer.count >= batchSize {
////                    processFrameBatch()
////                }
////            }
//
//
//
//    // Notify observers (your SwiftUI view) when capture is stopped
//    DispatchQueue.main.async {
//        self.isCapturing = false
//    }
//    self.isCapturing = false
//
//    assetReader?.cancelReading()
//}

//
//private func didCaptureVideoFrame(sampleBuffer: CMSampleBuffer) {
//    //let increment = Int(Double(numFrames)/15)
//    if frameCount % 40 == 0 {
//        if detectFaceInFrame(sampleBuffer) {
//                print("Face detected on frame \(frameCount)")
//                //print("in: \(self.getEmotionFramePairs())")
//            }
//        }
////        if frameCount == -1 {
////            print("Analyzing frame: \(targetFrame); Frames: \(numFrames); Increment: \(increment)")
////            targetFrame += increment
////            if detectFaceInFrame(sampleBuffer) {
////                    print("Face detected on frame \(frameCount)")
////                    //print("in: \(self.getEmotionFramePairs())")
////                }
////            }
////
////            //print("outin: \(self.getEmotionFramePairs())")
////            // Notify observers or delegate if necessary
//    delegate?.didCaptureVideoFrame(sampleBuffer: sampleBuffer, emotionFramePairs: emotionFramePairs)
//
//        // Increment the frame counter
//        frameCount += 1
//    }
