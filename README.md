## LottieExportDemo

This is demo project with Lottie animation exported with AVAssetExportSession. It's not work right now

### How to run
1. Run `pod install` for Lottie-iOS
2. [Comment or remove](https://github.com/airbnb/lottie-ios/issues/999) from `AnimationView` line that contains this:
```
guard self.window != nil
```
3. Run

### What will happen then
You will see glorious 60 FPS Heart animation and export will be started immediately. But animation in result video will be much slower.
