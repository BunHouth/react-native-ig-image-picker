//
//  IGImagePicker.swift
//  IGImagePicker
//
//  Created by Bunhouth on 3/3/20.
//  Copyright © 2020 Facebook. All rights reserved.
//

import Foundation
import YPImagePicker
import AVKit
import AVFoundation

@objc(IGImagePicker)
class IGImagePicker: UIViewController {
  private var defaultOptions: [AnyHashable : Any]?
  private var imageCropDimension: [AnyHashable : Any]?
  let compression = IGCompression()


  @objc class func requiresMainQueueSetup() -> Bool {
    return true
  }

  @objc func videoPicker(_ options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async(execute: {
      var config = YPImagePickerConfiguration()
      var startOnScreen = YPPickerScreen.video

      if(options.value(forKeyPath: "startOnScreen") as? String ?? "video" == "library") {
        startOnScreen = YPPickerScreen.video
      }

      config.video.compression = AVAssetExportPresetHighestQuality
      config.video.fileType = .mp4
      config.library.mediaType = YPlibraryMediaType.video
      config.library.maxNumberOfItems = options.value(forKeyPath: "library.maxNumberOfItems") as? Int ?? 5
      config.usesFrontCamera = options.value(forKeyPath: "usesFrontCamera") as? Bool ?? false
      config.gallery.hidesRemoveButton = false
      config.video.recordingTimeLimit = options.value(forKeyPath: "video.recordingTimeLimit") as? TimeInterval ?? 60.0
      config.video.libraryTimeLimit = options.value(forKeyPath: "video.libraryTimeLimit") as? TimeInterval ?? 60.0
      config.video.minimumTimeLimit = options.value(forKeyPath: "video.minimumTimeLimit") as? TimeInterval ?? 3.0
      config.video.trimmerMaxDuration = options.value(forKeyPath: "video.trimmerMaxDuration") as? TimeInterval ?? 60.0
      config.video.trimmerMinDuration = options.value(forKeyPath: "video.trimmerMinDuration") as? TimeInterval ?? 3.0
      config.showsVideoTrimmer =  ((options.value(forKeyPath: "showsVideoTrimmer") as? DarwinBoolean) != nil)
      config.library.defaultMultipleSelection =  options.value(forKeyPath: "library.defaultMultipleSelection") as? Bool ?? false
      config.screens = [.library, .video]
      config.startOnScreen = startOnScreen

      let picker = YPImagePicker(configuration: config)

      picker.didFinishPicking { [unowned picker] items, cancelled in
          if cancelled {
            picker.dismiss(animated: true, completion: nil)
            reject("", "Picker was canceled", nil)
            return
          }

          var selections = [[String:Any]]()
        for item in items {
          switch item {
            case .video(let video):
              let dimension = self.resolutionSizeForLocalVideo(url: video.url as NSURL)
              let videoDict = ["path": video.url.absoluteString, "width": dimension?.width, "height": dimension?.height, "filename": video.asset?.value(forKey: "filename"), "mime": "video/mp4", "size": 0]
              selections.append(videoDict as [String : Any])
            case .photo( _):
              print("Photo..")
              break
          }
        }

        picker.dismiss(animated: true, completion: nil)
        resolve(selections)
      }
        let root = RCTPresentedViewController()
        root?.present(picker, animated: true)
    })
  }

  @objc func libraryPicker(_ options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    DispatchQueue.main.async(execute: {
        var config = YPImagePickerConfiguration()
        var startOnScreen = YPPickerScreen.library
        let cropWidth = options.value(forKeyPath: "cropWidth") as? Int ?? 0
        let cropHeight = options.value(forKeyPath: "cropHeight") as? Int ?? 0
        if(cropWidth != 0 && cropHeight != 0) {
            let ratio = cropWidth/cropHeight
            config.showsCrop = .rectangle(ratio: Double(ratio))
        }

        if(options.value(forKeyPath: "startOnScreen") as? String ?? "library" == "photo") {
            startOnScreen = YPPickerScreen.photo
        }

        config.library.onlySquare = false
        config.library.isSquareByDefault = true
        config.library.minWidthForItem = nil
        config.library.mediaType = YPlibraryMediaType.photo
        config.library.defaultMultipleSelection =  options.value(forKeyPath: "library.defaultMultipleSelection") as? Bool ?? false
        config.library.maxNumberOfItems = options.value(forKeyPath: "library.maxNumberOfItems") as? Int ?? 1
        config.library.minNumberOfItems = options.value(forKeyPath: "library.minNumberOfItems") as? Int ?? 1
        config.library.numberOfItemsInRow = options.value(forKeyPath: "library.numberOfItemsInRow") as? Int ?? 4
        config.library.spacingBetweenItems = 1.0
        config.library.skipSelectionsGallery = false
        config.library.preselectedItems = nil
        config.showsPhotoFilters = options.value(forKeyPath: "showsPhotoFilters") as? Bool ?? true
        config.usesFrontCamera = options.value(forKeyPath: "usesFrontCamera") as? Bool ?? false
        config.startOnScreen = startOnScreen
        config.screens = [.library, .photo]
        config.library.mediaType = .photo
        config.maxCameraZoomFactor = 2.0
        config.gallery.hidesRemoveButton = false
        config.library.maxNumberOfItems = options.value(forKeyPath: "library.maxNumberOfItems") as? Int ?? 5

        let picker = YPImagePicker(configuration: config)
        picker.didFinishPicking { [unowned picker] items, cancelled in
            if cancelled {
                picker.dismiss(animated: true, completion: nil)
                reject("", "Picker was canceled", nil)
                return
            }

            var selections = [[String:Any]]()
            for item in items {
                switch item {
                    case .photo(let photo):
                        let imageResult = self.compression.compressImage(photo.image, withOptions: options as? [AnyHashable : Any])
                        let filePath = self.persistFile(imageResult?.data)!
                        let url = URL(fileURLWithPath: filePath)
                        let fileName = url.lastPathComponent
                        let photoDict = ["filename": fileName, "path": url.absoluteString, "mime": imageResult?.mime as Any, "height": imageResult?.height as Any, "width": imageResult?.width as Any, "size": imageResult?.data.count as Any] as [String : Any]
                        selections.append(photoDict)

                case .video( _):
                    print("Photo..")
                    break
                }
            }

            picker.dismiss(animated: true, completion: nil)
            resolve(selections)
        }
        let root = RCTPresentedViewController()
        root?.present(picker, animated: true)
    })
  }

  @objc func showImagePicker(_ options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {

    DispatchQueue.main.async(execute: {
        var config = YPImagePickerConfiguration()
            let cropWidth = options.value(forKeyPath: "cropWidth") as? Int ?? 0
            let cropHeight = options.value(forKeyPath: "cropHeight") as? Int ?? 0
            if(cropWidth != 0 && cropHeight != 0) {
                let ratio = cropWidth/cropHeight
                config.showsCrop = .rectangle(ratio: Double(ratio))
            }
            config.library.mediaType = .photoAndVideo
            config.shouldSaveNewPicturesToAlbum = false
            config.video.compression = AVAssetExportPresetMediumQuality
            config.startOnScreen = .library
            config.screens = [.library, .photo, .video]
            config.usesFrontCamera = options.value(forKeyPath: "usesFrontCamera") as? Bool ?? false
            config.showsPhotoFilters = options.value(forKeyPath: "showsPhotoFilters") as? Bool ?? true
            config.video.libraryTimeLimit =  options.value(forKeyPath: "video.libraryTimeLimit") as? TimeInterval ?? 500.0
            config.showsCrop = .none
            config.video.fileType = .mp4
            config.maxCameraZoomFactor = 2.0
            config.showsVideoTrimmer =  ((options.value(forKeyPath: "showsVideoTrimmer") as? DarwinBoolean) != nil)
            config.library.maxNumberOfItems = options.value(forKeyPath: "library.maxNumberOfItems") as? Int ?? 5
            config.video.minimumTimeLimit = options.value(forKeyPath: "video.minimumTimeLimit") as? TimeInterval ?? 3.0
            config.video.trimmerMaxDuration = options.value(forKeyPath: "video.trimmerMaxDuration") as? TimeInterval ?? 60.0
            config.video.trimmerMinDuration = options.value(forKeyPath: "video.trimmerMinDuration") as? TimeInterval ?? 3.0
            config.library.defaultMultipleSelection =  options.value(forKeyPath: "library.defaultMultipleSelection") as? Bool ?? false
            config.gallery.hidesRemoveButton = false
            config.library.minNumberOfItems = options.value(forKeyPath: "library.minNumberOfItems") as? Int ?? 1

            let picker = YPImagePicker(configuration: config)

            picker.didFinishPicking { [unowned picker] items, cancelled in
                if cancelled {
                    print("Picker was canceled")
                  picker.dismiss(animated: true, completion: nil)
                  reject("", "Picker was canceled", nil)
                  return
                }

              var selections = [[String:Any]]()
                for item in items {
                  switch item {
                  case .photo(let photo):
                    let imageResult = self.compression.compressImage(photo.image, withOptions: options as? [AnyHashable : Any])
                    let filePath = self.persistFile(imageResult?.data)!
                    let url = URL(fileURLWithPath: filePath)
                    let fileName = url.lastPathComponent
                    let photoDict = ["filename": fileName, "path": url.absoluteString, "mime": imageResult?.mime as Any, "height": imageResult?.height as Any, "width": imageResult?.width as Any, "size": imageResult?.data.count as Any] as [String : Any]
                    selections.append(photoDict)

                  case .video(let video):
                    let dimension = self.resolutionSizeForLocalVideo(url: video.url as NSURL)
                    let videoDict = ["path": video.url.absoluteString, "width": dimension?.width, "height": dimension?.height, "filename": video.asset?.value(forKey: "filename"), "mime": "video/mp4", "size": self.videoFileSize(filePath: video.url.path)]
                    selections.append(videoDict as [String : Any])
                  }
              }
                picker.dismiss(animated: true, completion: nil)
                resolve(selections)
            }

      let root = RCTPresentedViewController()
      root?.present(picker, animated: true)
    })
  }

  // based on showImagePicker
  @objc func libraryPickerExtended(_ options: NSDictionary, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {

    DispatchQueue.main.async(execute: {
        var config = YPImagePickerConfiguration()
            let cropWidth = options.value(forKeyPath: "cropWidth") as? Int ?? 0
            let cropHeight = options.value(forKeyPath: "cropHeight") as? Int ?? 0
            if(cropWidth != 0 && cropHeight != 0) {
                let ratio = cropWidth/cropHeight
                config.showsCrop = .rectangle(ratio: Double(ratio))
            }

            // let screens = [.library]
            // let showCaptureImage = options.value(forKeyPath: "showCaptureImage") as? Bool ?? false
            // let showCaptureVideo = options.value(forKeyPath: "showCaptureVideo") as? Bool ?? false
            // if showCaptureImage {
            //   screens.append(.photo)
            // }
            // if showCaptureImage {
            //   screens.append(.video)
            // }
            config.library.mediaType = .photoAndVideo
            config.shouldSaveNewPicturesToAlbum = false
            config.video.compression = AVAssetExportPresetMediumQuality
            config.startOnScreen = .library
            // config.screens = screens
            config.screens = [.library]
            config.usesFrontCamera = options.value(forKeyPath: "usesFrontCamera") as? Bool ?? false
            config.showsPhotoFilters = options.value(forKeyPath: "showsPhotoFilters") as? Bool ?? true
            config.video.libraryTimeLimit =  options.value(forKeyPath: "video.libraryTimeLimit") as? TimeInterval ?? 500.0
            config.showsCrop = .none
            config.video.fileType = .mp4
            config.maxCameraZoomFactor = 2.0
            config.showsVideoTrimmer =  ((options.value(forKeyPath: "showsVideoTrimmer") as? DarwinBoolean) != nil)
            config.library.maxNumberOfItems = options.value(forKeyPath: "library.maxNumberOfItems") as? Int ?? 99
            config.video.minimumTimeLimit = options.value(forKeyPath: "video.minimumTimeLimit") as? TimeInterval ?? 3.0
            config.video.trimmerMaxDuration = options.value(forKeyPath: "video.trimmerMaxDuration") as? TimeInterval ?? 60.0
            config.video.trimmerMinDuration = options.value(forKeyPath: "video.trimmerMinDuration") as? TimeInterval ?? 3.0
            config.library.defaultMultipleSelection =  options.value(forKeyPath: "library.defaultMultipleSelection") as? Bool ?? false
            config.gallery.hidesRemoveButton = false
            config.library.minNumberOfItems = options.value(forKeyPath: "library.minNumberOfItems") as? Int ?? 1

            let picker = YPImagePicker(configuration: config)

            picker.didFinishPicking { [unowned picker] items, cancelled in
                if cancelled {
                    print("Picker was canceled")
                  picker.dismiss(animated: true, completion: nil)
                  reject("", "Picker was canceled", nil)
                  return
                }

              var selections = [[String:Any]]()
                for item in items {
                  switch item {
                  case .photo(let photo):
                    let imageResult = self.compression.compressImage(photo.image, withOptions: options as? [AnyHashable : Any])
                    let filePath = self.persistFile(imageResult?.data)!
                    let url = URL(fileURLWithPath: filePath)
                    let fileName = url.lastPathComponent
                    let photoDict = ["filename": fileName, "path": url.path, "mime": imageResult?.mime as Any, "height": imageResult?.height as Any, "width": imageResult?.width as Any, "size": imageResult?.data.count as Any] as [String : Any]
                    selections.append(photoDict)

                  case .video(let video):
                    print(video)
                    let dimension = self.resolutionSizeForLocalVideo(url: video.url as NSURL)
                    let videoDict = ["path": video.url.path, "width": dimension?.width, "height": dimension?.height, "filename": video.asset?.value(forKey: "filename"), "mime": "video/mp4", "size": self.videoFileSize(filePath: video.url.path), "duration": video.asset?.value(forKey: "duration")]
                  selections.append(videoDict as [String : Any])
                  }
              }
                picker.dismiss(animated: true, completion: nil)
                resolve(selections)
            }

      let root = RCTPresentedViewController()
      root?.present(picker, animated: true)
    })
  }

  func methodQueue() -> DispatchQueue {
         return DispatchQueue.main
  }

  func persistFile(_ data: Data?) -> String? {
      // create temp file
    let tmpDirFullPath = getTmpDirectory()!
    var filePath = tmpDirFullPath + (UUID().uuidString)
    filePath = filePath + (".jpg")

    // save cropped file
    do {
        try data?.write(to: URL(fileURLWithPath: filePath), options: .atomic)
    } catch {
        print(error)
      return nil
    }

    return filePath
  }


  func getTmpDirectory() -> String? {
      let TMP_DIRECTORY = "ig-image-picker/"
      let tmpFullPath = NSTemporaryDirectory() + (TMP_DIRECTORY)

      let exists = directoryExists(atPath: tmpFullPath)
      if !exists {
          do {
              try FileManager.default.createDirectory(atPath: tmpFullPath, withIntermediateDirectories: true, attributes: nil)
          } catch {
          }
      }

      return tmpFullPath
  }

  func directoryExists (atPath path: String) -> Bool {
      var directoryExists = ObjCBool.init(false)
      let fileExists = FileManager.default.fileExists(atPath: path, isDirectory: &directoryExists)

      return fileExists && directoryExists.boolValue
  }

  func resolutionSizeForLocalVideo(url:NSURL) -> CGSize? {
      guard let track = AVAsset(url: url as URL).tracks(withMediaType: AVMediaType.video).first else { return nil }
      let size = track.naturalSize.applying(track.preferredTransform)
    return CGSize(width: abs(size.width), height: abs(size.height))
  }

  func videoFileSize (filePath: String) -> Int {
    let fileURL = URL(fileURLWithPath: filePath)
    var fileSizeObj: AnyObject?

    do {
      try (fileURL as NSURL).getResourceValue(&fileSizeObj, forKey: .fileSizeKey)
    } catch {
    }
    return fileSizeObj as? Int ?? 0
  }
}
