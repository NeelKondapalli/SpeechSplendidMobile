import Combine
import Foundation
import Vision
import AVFoundation

class VideoCaptureManagerDelegate: ObservableObject {
    @Published var videoCaptureManager: VideoCaptureManager?
    @Published var emotionFramePairs: [(String, Int)] = []
    
    enum VideoProcessingError: Error {
        case noVideoTrackFound
        case failedToLoadModel
        case failedToLoadVNCoreMLModel
    }
    
    private var cancellable: AnyCancellable?
    func didCaptureVideoFrame(sampleBuffer: CMSampleBuffer,emotionFramePairs: [(String, Int)]) {
        // Implement your logic for handling the captured video frame here
        DispatchQueue.main.async {
                    self.emotionFramePairs = emotionFramePairs
                    //print("Updated emotionFramePairs: \(self.emotionFramePairs)")
                }
    }

//    func startCapture(videoURL: URL) -> [(String, Int)]? {
//        videoCaptureManager = VideoCaptureManager(videoURL: videoURL)
//        videoCaptureManager?.delegate = self
//        videoCaptureManager?.startCapture()
//        print(videoCaptureManager?.getEmotionFramePairs())
//        return videoCaptureManager?.getEmotionFramePairs()
//    }
    func startCapture(videoURL: URL) throws {
        do {
            videoCaptureManager = try VideoCaptureManager(videoURL: videoURL)
            videoCaptureManager?.delegate = self
            videoCaptureManager?.startCapture()
        } catch VideoProcessingError.noVideoTrackFound {
            throw VideoProcessingError.noVideoTrackFound
        } catch VideoProcessingError.failedToLoadModel {
            throw VideoProcessingError.failedToLoadModel
        } catch VideoProcessingError.failedToLoadVNCoreMLModel {
            throw VideoProcessingError.failedToLoadVNCoreMLModel
        }
        
        // Subscribe to changes in emotionFramePairs
    
    }
    func getEmotionFramePairs() -> [(String, Int)] {
        return self.emotionFramePairs
    }


    func stopCapture() {
        videoCaptureManager?.stopCapture()
        
    }
}
