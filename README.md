## LottieExportDemo

Demo project with Lottie-animation export with both `AVAssetExportSession` and `AVAssetWriter`. `AVAssetWriter` works fine, but `AVAssetExportSession` doesn't.

### Why it works
[I removed](https://github.com/airbnb/lottie-ios/issues/999) this line from `AnimationView`:
```
guard self.window != nil else { waitingToPlayAimation = true; return }
```
### What will happen on start
You will see glorious 60 FPS animation and `AVAssetExportSession` export will be started immediately. But result animation will be much slower.
