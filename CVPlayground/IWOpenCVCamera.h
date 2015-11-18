//
//  IWOpenCVCamera.h
//
//  Created by Pavlo Razumovkyi on  Jul 17, 2015.
//  @see http://stackoverflow.com/a/31479032/185371
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
