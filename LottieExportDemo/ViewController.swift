//
//  ViewController.swift
//  LottieExportDemo
//
//  Created by Damik Minnegalimov on 10.09.2019.
//  Copyright © 2019 Damik Minnegalimov. All rights reserved.
//

import UIKit
import Lottie
import AVKit


class ViewController: UIViewController {
    var animationView: AnimationView?
    var animation: Animation?
    var button: UIButton?
    let size = UIScreen.main.bounds.size

    private var videoWriter: AVAssetWriter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        Animation.loadedFrom(url: URL(string: "https://assets9.lottiefiles.com/packages/lf20_dH29dn.json")!,
                             closure: { animation in self.animationLoaded(newAnimation: animation) },
                             animationCache: nil)
    }
    
    func animationLoaded(newAnimation: Animation?) {
        animationView = AnimationView(animation: newAnimation)
        animationView?.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        animationView?.center = view.center
        
        animationView?.loopMode = .loop
        animationView?.play()
        
        view.addSubview(animationView!)
        
        animation = newAnimation
        startExport()
//        try? oldExport()
        
        button = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        button?.backgroundColor = .lightGray
        
        button?.setTitle("Start export", for: .normal)
        button?.addTarget(self, action: #selector(startExport), for: .touchUpInside)
        
        button?.center = view.center
        button?.frame.origin.y = button!.frame.origin.y + 200
        
        view.addSubview(button!)
    }
    
    @objc func startExport() {
        guard let animation = animation else {
            print("Set up Animation first")
            return
        }
        
        let bundleURL = Bundle.main.resourceURL!
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsDirectory.appendingPathComponent("processed.mov")
        try? FileManager.default.removeItem(at: outputURL)
        
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
                playVideo(url: outputURL)
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
            
            self.toggleButton(needEnable: false)
            
            exportSession.exportAsynchronously {
                print("- \(startTime.timeIntervalSinceNow * -1) seconds elapsed for processing")
                
                self.toggleButton(needEnable: true)
                
                if exportSession.status.rawValue == 4 {
                    print("Export failed -> Reason: \(exportSession.error!.localizedDescription))")
                    print(exportSession.error!)
                    return
                }
                
                completion?(outputUrl)
            }
        }
    }
    
    @objc func oldExport() throws {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let outputURL = documentsDirectory.appendingPathComponent("processed.mov")
        try? FileManager.default.removeItem(at: outputURL)
        
        let fps = Int64(animation?.framerate ?? 30)
        var framesMax = CGFloat(fps)
                        
        if let animation = animation {
            framesMax = CGFloat(animation.duration * Double(fps))
        }
        
        animationView?.loopMode = .playOnce
        animationView?.stop()
                
        /*
         * Set up VideoWriter
         */
        do {
            try videoWriter = AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mov)
        } catch let error {
            throw(error)
        }
        
        guard let videoWriter = videoWriter else {
            return
        }
        
        let videoSettings: [String : Any] = [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : size.width,
            AVVideoHeightKey : size.height,
        ]
        
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        
        let sourceBufferAttributes: [String : Any] = [
            (kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32ARGB),
            (kCVPixelBufferWidthKey as String): Float(size.width),
            (kCVPixelBufferHeightKey as String): Float(size.height)
        ]
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,
                                                                      sourcePixelBufferAttributes: sourceBufferAttributes)
        
        assert(videoWriter.canAdd(videoWriterInput))
        videoWriter.add(videoWriterInput)
        
        if videoWriter.startWriting() {
            videoWriter.startSession(atSourceTime: CMTime.zero)
            assert(pixelBufferAdaptor.pixelBufferPool != nil)
            
            let startTime = Date()
                        
            videoWriterInput.requestMediaDataWhenReady(on: .main, using: {
                let frameDuration = CMTimeMake(value: 1, timescale: Int32(fps))
                var frameCount: Int64 = 0
                
                /*
                 * Start render loop
                 */
                while(Int(frameCount) < Int(framesMax)) {
                    if videoWriterInput.isReadyForMoreMediaData {
                        let lastFrameTime = CMTimeMake(value: frameCount, timescale: Int32(fps))
                        let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)
                        
                        // Set up Lottie
                        self.animationView?.currentProgress = CGFloat(frameCount) / framesMax
                                               
                        UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)
                        self.view.drawHierarchy(in: CGRect(x:0, y:0, width: self.size.width, height: self.size.height),
                                                afterScreenUpdates: true)
                        
                        let image = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        
                        do {
                            try append(pixelBufferAdaptor: pixelBufferAdaptor,
                                            with: image!,
                                            at: presentationTime,
                                            success: {
                                                frameCount += 1
                            })
                        } catch {
                        } // Do not throw here
                    }
                }
                
                videoWriterInput.markAsFinished()
                
                videoWriter.finishWriting {
                    print("finishWriting")
                    print("--- finish in \(startTime.timeIntervalSinceNow * -1)")

                    self.animationView?.loopMode = .loop
                    playVideo(url: videoWriter.outputURL)
                }
            })
        }
    }
    
    func toggleButton(needEnable: Bool) {
        DispatchQueue.main.async {
            self.button?.setTitle(needEnable ? "Start export" : "Processing...", for: .normal)
            self.button?.isEnabled = needEnable
        }
    }    
}

