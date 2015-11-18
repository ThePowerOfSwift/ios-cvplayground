//
//  AWVideoCameraCtrl.m
//  CVPlayground
//
//  Created by iwat on 11/10/15.
//  Copyright © 2015 Chaiwat Shuetrakoonpaiboon (iwat). All rights reserved.
//

#import <opencv2/highgui/ios.h>

#import "CVWrapper.h"

#import "AWVideoCameraCtrl.h"

@interface AWVideoCameraCtrl () <CvVideoCameraDelegate>
@end

@implementation AWVideoCameraCtrl {
	CvVideoCamera *videoCamera;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	videoCamera = [[CvVideoCamera alloc] initWithParentView:self.previewView];
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
