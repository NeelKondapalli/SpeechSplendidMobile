//
//  BannerAd.swift
//  SpeechSplendid
//
//  Created by Neel Kondapalli on 10/21/23.
//

import Foundation
import SwiftUI
import GoogleMobileAds

struct BannerAd: UIViewRepresentable{
    @ObservedObject var adState: AdState
    var unitID: String
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(adState: adState)
    }
    
    func makeUIView(context: Context) -> GADBannerView {
      //  let adSize = GADAdSizeFromCGSize(CGSize(width: 320, height: 25))
        let adView = GADBannerView(adSize: GADAdSizeBanner)
        
        adView.adUnitID = unitID
        adView.rootViewController = UIApplication.shared.getRootViewController()
        adView.delegate = context.coordinator
        print("hhh")
        let request = GADRequest()
        request.scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        adView.load(request)
        print("Req: \(request)")
        return adView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
    }
    
    class Coordinator: NSObject, GADBannerViewDelegate {
        @ObservedObject var adState: AdState
        init(adState: AdState) {
                self.adState = adState
            }
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
          print("bannerViewDidReceiveAd")
          adState.adLoadedSuccessfully = true
           //print("true")
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
          print("bannerView:didFailToReceiveAdWithError: \(error.localizedDescription)")
            adState.adLoadedSuccessfully = false
           // print(adState.adLoadedSuccessfully)
        }

        func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
          print("bannerViewDidRecordImpression")
        }

        func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
          print("bannerViewWillPresentScreen")
        }

        func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
          print("bannerViewWillDIsmissScreen")
        }

        func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
          print("bannerViewDidDismissScreen")
        }
    }
}

extension UIApplication{
    func getRootViewController()->UIViewController{
        guard let screen = self.connectedScenes.first as? UIWindowScene else{
            return .init()
        }
        
        guard let root = screen.windows.first?.rootViewController else{
            return .init()
        }
        
        return root
    }
    
}






