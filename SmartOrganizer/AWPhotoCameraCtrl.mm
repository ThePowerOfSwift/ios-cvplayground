//
//  AWPhotoCameraCtrl.m
//  SmartOrganizer
//
//  Created by iwat on 11/11/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

#import <opencv2/highgui/ios.h>

#import "CVWrapper.h"

#import "AWOpenCVCamera.h"
#import "AWPhotoCameraCtrl.h"

@interface AWPhotoCameraCtrl () <AWOpenCVCameraDelegate>
@end

@implementation AWPhotoCameraCtrl {
	AWOpenCVCamera *photoCamera;
}

#pragma mark - AWPhotoCameraCtrl

- (IBAction)takePicture {
	[photoCamera takePicture];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	photoCamera = [[AWOpenCVCamera alloc] initWithParentView:self.previewView];
	photoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetPhoto;
	photoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
	photoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
	photoCamera.defaultFPS = 15;
	photoCamera.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[photoCamera start];
}

#pragma mark - AWOpenCVCameraDelegate

- (void)openCVCamera:(AWOpenCVCamera *)_photoCamera capturedImage:(UIImage *)image {
	if (photoCamera != _photoCamera) {
		return;
	}

	[photoCamera stop];

	UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	indicator.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
	[self.view addSubview:indicator];
	[indicator startAnimating];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *error = nil;
		UIImage *warped = [CVWrapper warpLargestRectangle:image error:&error];
		if (error != nil) {
			NSLog(@"CVWrapper.warpLargestRectangle error: %@", error);
			dispatch_async(dispatch_get_main_queue(), ^{
				[photoCamera start];
				[indicator stopAnimating];
				[indicator removeFromSuperview];
			});
			return;
		}

		dispatch_async(dispatch_get_main_queue(), ^{
			UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
			imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
			imageView.contentMode = UIViewContentModeScaleAspectFit;
			imageView.image = warped;
			[self.view addSubview:imageView];

			self.previewView.hidden = YES;

			[indicator stopAnimating];
			[indicator removeFromSuperview];

			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[imageView removeFromSuperview];
				[photoCamera start];
				self.previewView.hidden = NO;
			});
		});
	});
}

- (void)processImage:(cv::Mat &)image {
	[CVWrapper debugDrawLargestBlobOnMat:image edges:4];
}

@end
