//
//  ViewController.swift
//  LottieExportDemo
//
//  Created by Damik Minnegalimov on 10.09.2019.
//  Copyright © 2019 Damik Minnegalimov. All rights reserved.
//

import UIKit
import Lottie
import Photos
import AVKit


class ViewController: UIViewController {
    var animation: Animation?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Animation.loadedFrom(url: URL(string: "https://assets9.lottiefiles.com/packages/lf20_dH29dn.json")!,
                             closure: { animation in self.animationLoaded(newAnimation: animation) },
                             animationCache: nil)
    }
    
    func animationLoaded(newAnimation: Animation?) {
        let animationView = AnimationView(animation: newAnimation)
        animationView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        animationView.center = view.center
        
        animationView.loopMode = .loop
        animationView.play()
        
        view.addSubview(animationView)
        
        animation = newAnimation
        startExport()
    }
    
    func startExport() {
        guard let animation = animation else {
            print("Set up Animation first")
            return
        }
        
        let bundleURL = Bundle.main.resourceURL!
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsDirectory.appendingPathComponent("processed.mov")
        try? FileManager.default.removeItem(at: outputURL)

        let size = CGSize(width: 1000, height: 1250)
        let duration = CMTime(seconds: animation.duration * 3, preferredTimescale: 600)

        
        /// Create composition
        let compositionRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let timerange: CMTimeRange = CMTimeRange(start: .zero, duration: duration)
        
        let composition = AVMutableComposition()
        let videoComposition = AVMutableVideoComposition()
        
        let instructions = AVMutableVideoCompositionInstruction()
        instructions.backgroundColor = UIColor.clear.cgColor
        instructions.timeRange = timerange
        
        
        /// Create main parent layer for AVVideoCompositionCoreAnimationTool
        let parentLayer = CALayer()
        parentLayer.isGeometryFlipped = true
        parentLayer.frame = compositionRect
        
        let videoCALayer = CALayer()
        videoCALayer.frame = compositionRect
        parentLayer.addSublayer(videoCALayer)
        

        /// Create needed assets and tracks (AVFoundation classes)
        let avAsset = AVAsset(url: URL(string:"poppets.mov", relativeTo:bundleURL)!)
        
        guard let videoTrack = avAsset.tracks(withMediaType: .video).first else {
            NSLog("Error: there is no video track in video")
            return
        }
        
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video,
                                                                preferredTrackID: kCMPersistentTrackID_Invalid)
        try! compositionVideoTrack?.insertTimeRange(timerange, of: videoTrack, at: .zero)
        
        /// Set up effects for current layer (video)
        let layerIntruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack!)
        layerIntruction.setOpacity(1, at: .zero)
        
        /// Add effects to global instructions
        instructions.layerInstructions.append(layerIntruction)
        
        /// Add Lottie
        addLottie(animation: animation, to: parentLayer, with: compositionRect)
    
        /// Set up composition size and framerate
        videoComposition.instructions = [instructions]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(animation.framerate));
        videoComposition.renderSize = size
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoCALayer, in: parentLayer)
        
        /// Run export
        export(
            composition: composition,
            videoComposition: videoComposition,
            outputUrl: outputURL) { outputURL in
                self.playVideo(url: outputURL)
            }
    }
    
    func addLottie(animation: Animation,
                   to layer: CALayer,
                   with frame: CGRect) {
        
        let animationView = AnimationView()
        animationView.animation = animation
        animationView.loopMode = .loop
        animationView.respectAnimationFrameRate = true

        let animationLayer = animationView.layer
        animationLayer.frame = frame
        animationLayer.layoutSublayers()

        layer.addSublayer(animationLayer)
        animationView.play()
    }
    
    func export(composition: AVMutableComposition,
                videoComposition: AVMutableVideoComposition,
                outputUrl: URL,
                completion: ((URL) -> Void)?) {
        if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) {
            exportSession.videoComposition = videoComposition
            exportSession.outputURL = outputUrl
            exportSession.timeRange = CMTimeRangeMake(start: .zero, duration: composition.duration)
            exportSession.outputFileType = .mov
            
            let startTime = Date()
            
            exportSession.exportAsynchronously {
                print("- \(startTime.timeIntervalSinceNow * -1) seconds elapsed for processing")
                
                if exportSession.status.rawValue == 4 {
                    print("Export failed -> Reason: \(exportSession.error!.localizedDescription))")
                    print(exportSession.error!)
                    return
                }
                
                completion?(outputUrl)
            }
        }
    }

    
    func playVideo(url: URL) {
        DispatchQueue.main.async {
            let player = AVPlayer(url: url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            
            let viewController = UIApplication.shared.keyWindow!.rootViewController
            viewController?.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
        }
    }
    
    func saveToLibrary(url: URL?) {
        if let assetUrl = url {
            let startSaveTime = Date()
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: assetUrl)
            }) { saved, error in
                if saved {
                    print("----------- \(startSaveTime.timeIntervalSinceNow * -1) seconds for saving to Library")
                }
            }
        }
    }
}

