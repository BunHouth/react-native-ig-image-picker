//
//  Compression.h
//  imageCropPicker
//
//  Created by Ivan Pusic on 12/24/16.
//  Copyright © 2016 Ivan Pusic. All rights reserved.
//  Original URL: https://github.com/ivpusic/react-native-image-crop-picker/blob/master/ios/src/Compression.m

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ImageResult : NSObject

@property NSData *data;
@property NSNumber *width;
@property NSNumber *height;
@property NSString *mime;
@property UIImage *image;

@end

@interface VideoResult : NSObject

@end

@interface IGCompression : NSObject

- (ImageResult*) compressImage:(UIImage*)image withOptions:(NSDictionary*)options;
- (void)compressVideo:(NSURL*)inputURL
            outputURL:(NSURL*)outputURL
          withOptions:(NSDictionary*)options
              handler:(void (^)(AVAssetExportSession*))handler;

@property NSDictionary *exportPresets;

@end
