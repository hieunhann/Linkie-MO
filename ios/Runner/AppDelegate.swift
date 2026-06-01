import Flutter
import UIKit
import AVFoundation
import CoreVideo
import CoreMedia

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.linkie.app/timelapse",
                                              binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "generateVideo" {
        guard let args = call.arguments as? [String: Any],
              let imagePaths = args["imagePaths"] as? [String],
              let outputPath = args["outputPath"] as? String,
              let width = args["width"] as? Int,
              let height = args["height"] as? Int,
              let fps = args["fps"] as? Int else {
          result(false)
          return
        }
        
        self.buildVideo(imagePaths: imagePaths, outputPath: outputPath, width: width, height: height, fps: fps) { success in
          DispatchQueue.main.async {
            result(success)
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func buildVideo(imagePaths: [String], outputPath: String, width: Int, height: Int, fps: Int, completion: @escaping (Bool) -> Void) {
    let outputURL = URL(fileURLWithPath: outputPath)
    
    // Delete existing file if present
    if FileManager.default.fileExists(atPath: outputPath) {
      try? FileManager.default.removeItem(at: outputURL)
    }
    
    guard let videoWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
      completion(false)
      return
    }
    
    let videoSettings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height
    ]
    
    let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: writerInput,
      sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height
      ]
    )
    
    guard videoWriter.canAdd(writerInput) else {
      completion(false)
      return
    }
    videoWriter.add(writerInput)
    
    videoWriter.startWriting()
    videoWriter.startSession(atSourceTime: .zero)
    
    let durationPerFrame = CMTimeMake(value: 1, timescale: Int32(fps))
    var frameCount: Int64 = 0
    var index = 0
    
    let queue = DispatchQueue(label: "com.linkie.app.timelapse.queue", qos: .userInitiated)
    
    writerInput.requestMediaDataWhenReady(on: queue) {
      while writerInput.isReadyForMoreMediaData {
        if index >= imagePaths.count {
          writerInput.markAsFinished()
          videoWriter.finishWriting {
            completion(videoWriter.status == .completed)
          }
          break
        }
        
        let path = imagePaths[index]
        if let image = UIImage(contentsOfFile: path),
           let pixelBuffer = self.newPixelBuffer(from: image, width: width, height: height) {
          let presentationTime = CMTimeMultiply(durationPerFrame, multiplier: Int32(frameCount))
          adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
          frameCount += 1
        }
        index += 1
      }
    }
  }

  private func newPixelBuffer(from image: UIImage, width: Int, height: Int) -> CVPixelBuffer? {
    var pixelBuffer: CVPixelBuffer? = nil
    let attrs = [
      kCVPixelBufferCGImageCompatibilityKey as String: kCFBooleanTrue,
      kCVPixelBufferCGBitmapContextCompatibilityKey as String: kCFBooleanTrue
    ] as CFDictionary
    
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault,
      width,
      height,
      kCVPixelFormatType_32BGRA,
      attrs,
      &pixelBuffer
    )
    
    guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
      return nil
    }
    
    CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
    let context = CGContext(
      data: CVPixelBufferGetBaseAddress(buffer),
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    )
    
    guard let ctx = context, let cgImage = image.cgImage else {
      CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
      return nil
    }
    
    ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
    
    return buffer
  }
}
