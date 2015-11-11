//
//  AWPhotoCameraCtrl.m
//  SmartOrganizer
//
//  Created by iwat on 11/11/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

#import <opencv2/highgui/ios.h>

#import "CVWrapper.h"
#import "CVPhotoCameraMod.h"

#import "AWPhotoCameraCtrl.h"

//#define CVPhotoCameraMod CvPhotoCamera
//#define CVPhotoCameraModDelegate CvPhotoCameraDelegate

@interface AWPhotoCameraCtrl () <CVPhotoCameraModDelegate>
@end

@implementation AWPhotoCameraCtrl {
	CVPhotoCameraMod *photoCamera;
}

#pragma mark - AWPhotoCameraCtrl

- (IBAction)takePicture {
	[photoCamera takePicture];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	photoCamera = [[CVPhotoCameraMod alloc] initWithParentView:self.imageView];
	photoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetPhoto;
	photoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
	photoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
	photoCamera.defaultFPS = 15;
	photoCamera.delegate = self;
	photoCamera.useAVCaptureVideoPreviewLayer = YES;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[photoCamera start];
	//[photoCamera createCustomVideoPreview];
}

#pragma mark - CVPhotoCameraModDelegate

- (void)photoCamera:(CVPhotoCameraMod *)_photoCamera capturedImage:(UIImage *)image {
	if (photoCamera != _photoCamera) {
		return;
	}

	//[photoCamera stop];
	image = [CVWrapper warpLargestRectangle:image];
}

- (void)photoCameraCancel:(CVPhotoCameraMod *)photoCamera {
	//
}

- (void)processImage:(cv::Mat&)image {
	[CVWrapper debugDrawLargestBlobOnMat:image edges:4];
}

@end
