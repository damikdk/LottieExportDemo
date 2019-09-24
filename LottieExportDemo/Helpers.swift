//
//  Helpers.swift
//  LottieExportDemo
//
//  Created by Damik Minnegalimov on 12.09.2019.
//  Copyright © 2019 Damik Minnegalimov. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import Photos


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

func append(pixelBufferAdaptor adaptor: AVAssetWriterInputPixelBufferAdaptor, with image: UIImage, at presentationTime: CMTime, success: @escaping (() -> ())) throws {
    do {
        if let pixelBufferPool = adaptor.pixelBufferPool {
            let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: MemoryLayout<CVPixelBuffer?>.size)
            let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
              kCFAllocatorDefault,
              pixelBufferPool,
              pixelBufferPointer
            )
            guard let pixelBuffer = pixelBufferPointer.pointee else {
                return
            }
            guard status == 0 else {
                return
            }
            
            fill(pixelBuffer: pixelBuffer, with: image)
            if adaptor.append(pixelBuffer, withPresentationTime: presentationTime) {
                pixelBufferPointer.deinitialize(count:1)
                success()
            } else {
            }
            
            pixelBufferPointer.deallocate()
        }
    } catch let error {
        throw error
    }
}

// Populates the pixel buffer with the contents of the current image
private func fill(pixelBuffer: CVPixelBuffer, with image: UIImage) {
    // lock the buffer memoty so no one can access it during manipulation
    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
    
    // get the pixel data from the address in the memory
    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
    
    // create a color scheme
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    
    /// set the context size
    let contextSize = image.size
    
    // generate a context where the image will be drawn
    if let context = CGContext(data: pixelData,
                               width: Int(contextSize.width),
                               height: Int(contextSize.height),
                               bitsPerComponent: 8,
                               bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                               space: rgbColorSpace,
                               bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) {
        
        var imageHeight = image.size.height
        var imageWidth = image.size.width
        
        if Int(imageHeight) > context.height {
            imageHeight = 16 * (CGFloat(context.height) / 16).rounded(.awayFromZero)
        } else if Int(imageWidth) > context.width {
            imageWidth = 16 * (CGFloat(context.width) / 16).rounded(.awayFromZero)
        }
        
        let center = CGPoint.zero
        
        context.clear(CGRect(x: 0.0, y: 0.0, width: imageWidth, height: imageHeight))
        
        // set the context's background color
        context.fill(CGRect(x: 0.0, y: 0.0, width: CGFloat(context.width), height: CGFloat(context.height)))
        context.concatenate(.identity)
        
        // draw the image in the context
        
        if let cgImage = image.cgImage {
            context.draw(cgImage, in: CGRect(x: center.x, y: center.y, width: imageWidth, height: imageHeight))
        }
        
        // unlock the buffer memory
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
    }
}
