import MediaPlayer

#if os(iOS)
  import AVFoundation

  // The iPhoneOS 26.4 SDK exposes the Swift 4.2-era nested refinements
  // (AVAudioSession.Category.playback) only to targets compiling in Swift
  // 4/5 language mode; in newer modes the type degrades to the ObjC
  // NSString typedef and only the flat global constants exist. Resolve the
  // six categories once, valid in either mode. (The podspec also pins
  // swift_version 5.0, so the >=6.0 branch is a safety net.)
  #if swift(>=6.0)
    private let kCategoryAmbient = AVAudioSessionCategoryAmbient
    private let kCategorySoloAmbient = AVAudioSessionCategorySoloAmbient
    private let kCategoryPlayback = AVAudioSessionCategoryPlayback
    private let kCategoryRecord = AVAudioSessionCategoryRecord
    private let kCategoryPlayAndRecord = AVAudioSessionCategoryPlayAndRecord
    private let kCategoryMultiRoute = AVAudioSessionCategoryMultiRoute
  #else
    private let kCategoryAmbient = AVAudioSession.Category.ambient
    private let kCategorySoloAmbient = AVAudioSession.Category.soloAmbient
    private let kCategoryPlayback = AVAudioSession.Category.playback
    private let kCategoryRecord = AVAudioSession.Category.record
    private let kCategoryPlayAndRecord = AVAudioSession.Category.playAndRecord
    private let kCategoryMultiRoute = AVAudioSession.Category.multiRoute
  #endif

  struct AudioContext {
    let category: AVAudioSession.Category
    let options: [AVAudioSession.CategoryOptions]

    init() {
      self.category = kCategoryPlayback
      self.options = []
    }

    init(
      category: AVAudioSession.Category,
      options: [AVAudioSession.CategoryOptions]
    ) {
      self.category = category
      self.options = options
    }

    public func activateAudioSession(
      active: Bool
    ) throws {
      let session = AVAudioSession.sharedInstance()
      try session.setActive(active)
    }

    public func apply() throws {
      let session = AVAudioSession.sharedInstance()
      let combinedOptions = options.reduce(AVAudioSession.CategoryOptions()) {
        [$0, $1]
      }
      #if swift(>=6.0)
        try session.setCategory(category as String, options: combinedOptions)
      #else
        try session.setCategory(category, options: combinedOptions)
      #endif
    }

    public static func parse(args: [String: Any]) throws -> AudioContext? {
      guard let categoryString = args["category"] as! String? else {
        throw AudioPlayerError.error("Null value received for category")
      }
      guard let category = try parseCategory(category: categoryString) else {
        return nil
      }

      guard let optionStrings = args["options"] as! [String]? else {
        throw AudioPlayerError.error("Null value received for options")
      }
      let options = try optionStrings.compactMap {
        try parseCategoryOption(option: $0)
      }
      if optionStrings.count != options.count {
        return nil
      }

      return AudioContext(
        category: category,
        options: options
      )
    }

    private static func parseCategory(category: String) throws -> AVAudioSession.Category? {
      switch category {
      case "ambient":
        return kCategoryAmbient
      case "soloAmbient":
        return kCategorySoloAmbient
      case "playback":
        return kCategoryPlayback
      case "record":
        return kCategoryRecord
      case "playAndRecord":
        return kCategoryPlayAndRecord
      case "multiRoute":
        return kCategoryMultiRoute
      default:
        throw AudioPlayerError.error("Invalid Category \(category)")
      }
    }

    private static func parseCategoryOption(option: String) throws -> AVAudioSession
      .CategoryOptions?
    {
      switch option {
      case "mixWithOthers":
        return .mixWithOthers
      case "duckOthers":
        return .duckOthers
      case "allowBluetooth":
        return .allowBluetooth
      case "defaultToSpeaker":
        return .defaultToSpeaker
      case "interruptSpokenAudioAndMixWithOthers":
        return .interruptSpokenAudioAndMixWithOthers
      case "allowBluetoothA2DP":
        if #available(iOS 10.0, *) {
          return .allowBluetoothA2DP
        } else {
          throw AudioPlayerError.warning(
            "Category Option allowBluetoothA2DP is only available on iOS 10+")
        }
      case "allowAirPlay":
        if #available(iOS 10.0, *) {
          return .allowAirPlay
        } else {
          throw AudioPlayerError.warning(
            "Category Option allowAirPlay is only available on iOS 10+")
        }
      case "overrideMutedMicrophoneInterruption":
        if #available(iOS 14.5, *) {
          return .overrideMutedMicrophoneInterruption
        } else {
          throw AudioPlayerError.warning(
            "Category Option overrideMutedMicrophoneInterruption is only available on iOS 14.5+")
        }
      default:
        throw AudioPlayerError.error("Invalid Category Option \(option)")
      }
    }
  }
#else
  // no-op impl of AudioContext for macos
  struct AudioContext {
    func activateAudioSession(active: Bool) throws {
    }

    func apply() throws {
      throw AudioPlayerError.warning("AudioContext configuration is not available on macOS")
    }

    static func parse(args: [String: Any]) throws -> AudioContext? {
      return AudioContext()
    }
  }
#endif
