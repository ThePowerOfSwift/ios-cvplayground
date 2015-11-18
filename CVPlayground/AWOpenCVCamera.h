//
//  AWOpenCVCamera.h
//
//  Created by Pavlo Razumovkyi on  Jul 17, 2015.
//  @see http://stackoverflow.com/a/31479032/185371
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/ios.h>

@class AWOpenCVCamera;

@protocol AWOpenCVCameraDelegate <CvVideoCameraDelegate>

- (void)openCVCamera:(AWOpenCVCamera *)camera capturedImage:(UIImage *)image;

@end

@interface AWOpenCVCamera : CvVideoCamera {
	AVCaptureStillImageOutput *stillImageOutput;
}

@property (nonatomic, weak) id<AWOpenCVCameraDelegate> delegate;

- (void)takePicture;

@end
