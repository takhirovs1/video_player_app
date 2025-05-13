
import Flutter
import UIKit
import AVFoundation

// MARK: - Stream handler for a single download id
private class DownloadStreamHandler: NSObject, FlutterStreamHandler {
  var sink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
}

// MARK: - Main plugin
public class HlsDownloaderPlugin: NSObject, FlutterPlugin, AVAssetDownloadDelegate {

  // Channels & messenger
  private var channel: FlutterMethodChannel!
  private var messenger: FlutterBinaryMessenger!

  // Active download sessions keyed by id
  private var sessions: [String: AVAssetDownloadURLSession] = [:]

  // Progress event stream handlers keyed by id
  private var streamHandlers: [String: DownloadStreamHandler] = [:]

  // Map download id -> final local file path
  private var localPaths: [String: String] = [:]

  // MARK: - Plugin entry
  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger()
    let channel = FlutterMethodChannel(name: "hls_downloader", binaryMessenger: messenger)

    let instance = HlsDownloaderPlugin()
    instance.channel = channel
    instance.messenger = messenger

    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  // MARK: - MethodChannel handler
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {

    case "startDownload":
      guard
        let args = call.arguments as? [String: Any],
        let urlStr = args["url"] as? String,
        let url = URL(string: urlStr)
      else {
        result(FlutterError(code: "INVALID_URL",
                            message: "Argument 'url' missing or invalid",
                            details: nil))
        return
      }

      // Unique id for this download
      let id = UUID().uuidString

      // Progress EventChannel for this id
      let handler = DownloadStreamHandler()
      let progressChannel = FlutterEventChannel(
        name: "hls_downloader/progress_\(id)",
        binaryMessenger: messenger)
      progressChannel.setStreamHandler(handler)
      streamHandlers[id] = handler

      // Background URLSession
      let cfg = URLSessionConfiguration.background(withIdentifier: id)
      let session = AVAssetDownloadURLSession(
        configuration: cfg,
        assetDownloadDelegate: self,
        delegateQueue: OperationQueue.main)

      sessions[id] = session

      // Start AVAssetDownloadTask
      let asset = AVURLAsset(url: url)
      let task = session.makeAssetDownloadTask(asset: asset,
                                               assetTitle: id,
                                               assetArtworkData: nil,
                                               options: nil)!
      task.resume()

      result(id) // Return id to Dart

    case "localPath":
      guard
        let args = call.arguments as? [String: Any],
        let id = args["id"] as? String
      else {
        result(FlutterError(code: "INVALID_ID",
                            message: "Argument 'id' missing",
                            details: nil))
        return
      }
      result(localPaths[id])

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - AVAssetDownloadDelegate

  public func urlSession(_ session: URLSession,
                         assetDownloadTask: AVAssetDownloadTask,
                         didLoad timeRange: CMTimeRange,
                         totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                         timeRangeExpectedToLoad: CMTimeRange) {
    // Running on main queue
    let loaded = loadedTimeRanges
      .map { $0.timeRangeValue.duration.seconds }
      .reduce(0, +)
    let percent = loaded / timeRangeExpectedToLoad.duration.seconds

    if
      let id = session.configuration.identifier,
      let sink = streamHandlers[id]?.sink
    {
      sink(percent)
    }
  }

  public func urlSession(_ session: URLSession,
                         assetDownloadTask: AVAssetDownloadTask,
                         didFinishDownloadingTo location: URL) {
    guard let id = session.configuration.identifier else { return }

    // Persist file: Documents/VideoCache/<filename>
    let fm = FileManager.default
    let docsDir = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let cacheDir = docsDir.appendingPathComponent("VideoCache", isDirectory: true)
    try? fm.createDirectory(at: cacheDir,
                            withIntermediateDirectories: true)

    let dstURL = cacheDir.appendingPathComponent(location.lastPathComponent)
    try? fm.removeItem(at: dstURL)          // Remove old if exists
    do {
      try fm.moveItem(at: location, to: dstURL)
    } catch {
      // If move fails, keep original tmp URL
    }

    localPaths[id] = dstURL.path

    if let sink = streamHandlers[id]?.sink {
      sink(1.0)                       // final progress
      sink(FlutterEndOfEventStream)   // close stream
    }
  }

  public func urlSession(_ session: URLSession,
                         task: URLSessionTask,
                         didCompleteWithError error: Error?) {

    guard let id = session.configuration.identifier else { return }

    if let sink = streamHandlers[id]?.sink {
      if let err = error {
        sink(FlutterError(code: "DL_ERROR",
                          message: err.localizedDescription,
                          details: nil))
      }
      // Stream already closed in didFinishDownloadingTo
    }

    streamHandlers.removeValue(forKey: id)
    sessions.removeValue(forKey: id)
  }
}
