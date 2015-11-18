//
//  IWOpenCVCamera.h
//  CVPlayground
//
//  Created by iwat on 11/9/15.
//  Copyright © 2015 Chaiwat Shuetrakoonpaiboon (iwat). All rights reserved.
//
//  Use of this source code is governed by MIT license that can be found in the
//  LICENSE file.
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/ios.h>

@class IWOpenCVCamera;

@protocol IWOpenCVCameraDelegate <CvVideoCameraDelegate>

- (void)openCVCamera:(IWOpenCVCamera *)camera capturedImage:(UIImage *)image;

@end

@interface IWOpenCVCamera : CvVideoCamera {
	AVCaptureStillImageOutput *stillImageOutput;
}

@property (nonatomic, weak) id<IWOpenCVCameraDelegate> delegate;

- (void)takePicture;

@end
