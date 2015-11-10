//
//  AWCameraCtrl.m
//  SmartOrganizer
//
//  Created by iwat on 11/10/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

#import <opencv2/highgui/ios.h>

#import "CVWrapper.h"

#import "AWCameraCtrl.h"

@interface AWCameraCtrl () <CvVideoCameraDelegate>
@end

@implementation AWCameraCtrl {
	CvVideoCamera *videoCamera;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	videoCamera = [[CvVideoCamera alloc] initWithParentView:self.imageView];
	videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
	videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
	videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
	videoCamera.defaultFPS = 15;
	videoCamera.delegate = self;
	videoCamera.grayscaleMode = NO;
	videoCamera.rotateVideo = YES;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[videoCamera start];
}

#pragma mark - CvVideoCameraDelegate

- (void)processImage:(cv::Mat &)image {
	[CVWrapper debugDrawLargestBlobOnMat:image edges:4];
}

@end
