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
            let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
            let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, pixelBufferPointer)
            guard let pixelBuffer = pixelBufferPointer.pointee else {
                return
            }
            guard status == 0 else {
                return
            }
            
            fill(pixelBuffer: pixelBuffer, with: image)
            if adaptor.append(pixelBuffer, withPresentationTime: presentationTime) {
              pixelBufferPointer.deinitialize(count:1)
                pixelBufferPointer.deallocate()
                success()
            } else {
            }
        }
    } catch let error {
        throw error
    }
}

// Populates the pixel buffer with the contents of the current image
private func fill(pixelBuffer buffer: CVPixelBuffer, with image: UIImage) {
    CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
    
    guard let context = CGContext(
        data: CVPixelBufferGetBaseAddress(buffer),
        width: Int(image.size.width),
        height: Int(image.size.height),
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return }
    guard let cgImage = image.cgImage else { return }
    
    let rect = CGRect(origin: .zero, size: image.size)
    context.draw(cgImage, in: rect)
    
    CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
}
