## LottieExportDemo
Demo project with Lottie-animation export with both `AVAssetExportSession` and `AVAssetWriter`. `AVAssetWriter` works fine, but `AVAssetExportSession` **DOESN'T**.

### What is happening
We have a Lottie-animations and we need to export it as video on iPhone. Our current AVAssetWriter implementation and frame-by-frame rendering is too slow, so we want to make it faster.

### What is the problem
We have `AVAssetExportSession` export implementation, but it works wrong because of lottie-ios architecture.

### How our AVAssetExportSession works
We create `AVMutableVideoComposition` and add `AnimationView.layer` (`CALayer`) on it by `AVVideoCompositionCoreAnimationTool`. Then just export it with `AVAssetExportSession`:

https://github.com/damikdk/LottieExportDemo/blob/ddb256e209d0f6a5a02f419f4fcc54eb56519c5e/LottieExportDemo/ViewController.swift#L136

### What's wrong with it
Timings are broken and animation is much slower on result video.

### More details
- This repo: https://github.com/damikdk/LottieExportDemo
- Main thread: https://github.com/airbnb/lottie-ios/issues/30
- Our last commentary in it: https://github.com/airbnb/lottie-ios/issues/30#issuecomment-531698005
- Main issue with feature request: https://github.com/airbnb/lottie-ios/issues/1001

### Why does it even run? (important)
[I removed](https://github.com/airbnb/lottie-ios/issues/999) this line from `AnimationView`:
```
guard self.window != nil else { waitingToPlayAimation = true; return }
```
