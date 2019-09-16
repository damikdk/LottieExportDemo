## LottieExportDemo

Demo project with Lottie-animation export with both `AVAssetExportSession` and `AVAssetWriter`. `AVAssetWriter` works fine, but `AVAssetExportSession` doesn't.

### How to run
1. Run `pod install` for Lottie-iOS
2. [Comment or remove](https://github.com/airbnb/lottie-ios/issues/999) from `AnimationView` line that contains this:
```
guard self.window != nil
```
3. Run

### What will happen then
You will see glorious 60 FPS animation and `AVAssetExportSession` export will be started immediately. But result animation will be much slower.

![screenshot](https://i.imgsafe.org/f2/f2de7107e4.jpeg)
