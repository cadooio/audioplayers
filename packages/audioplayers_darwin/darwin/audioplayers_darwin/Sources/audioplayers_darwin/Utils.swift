import AVKit

extension String {
  func deletingPrefix(_ prefix: String) -> String {
    guard self.hasPrefix(prefix) else {
      return self
    }
    return String(self.dropFirst(prefix.count))
  }
}

func toCMTime(millis: Int) -> CMTime {
  return toCMTime(millis: Float(millis))
}

func toCMTime(millis: Double) -> CMTime {
  return toCMTime(millis: Float(millis))
}

func toCMTime(millis: Float) -> CMTime {
  // CMTime(seconds:preferredTimescale:) instead of CMTimeMakeWithSeconds: the
  // iPhoneOS 26.4 SDK dropped the `preferredTimescale:` label from the C shim's
  // Swift overlay, breaking compilation. The Swift-native initializer is stable.
  return CMTime(seconds: Float64(millis) / 1000, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
}

func fromCMTime(time: CMTime) -> Int {
  guard CMTIME_IS_NUMERIC(time) else {
    return 0
  }
  let seconds: Float64 = CMTimeGetSeconds(time)
  let milliseconds: Int = Int(seconds * 1000)
  return milliseconds
}

class TimeObserver {
  let player: AVPlayer
  let observer: Any

  init(
    player: AVPlayer,
    observer: Any
  ) {
    self.player = player
    self.observer = observer
  }
}
