//
//  IWOpenCVCamera.mm
//  CVPlayground
//
//  Created by iwat on 11/9/15.
//  Copyright © 2015 Chaiwat Shuetrakoonpaiboon (iwat). All rights reserved.
//
//  Use of this source code is governed by MIT license that can be found in the
//  LICENSE file.
//

#import <CoreGraphics/CoreGraphics.h>

#import "IWOpenCVCamera.h"

@implementation IWOpenCVCamera

@dynamic delegate;

#pragma mark - IWOpenCVCamera

- (void)takePicture {
	if (cameraAvailable == NO) {
		NSLog(@"Camera not available");
		return;
	}

	cameraAvailable = NO;

	[stillImageOutput captureStillImageAsynchronouslyFromConnection:self.videoCaptureConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
		if (error != nil || imageSampleBuffer == nil) {
			NSLog(@"Capture error: %@", error);
			return;
		}

		NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.captureSession stopRunning];

			// Make sure we create objects on the main thread in the main context
			UIImage* newImage = [UIImage imageWithData:jpegData];

			// We have captured the image, we can allow the user to take another picture
			cameraAvailable = YES;

			NSLog(@"Captured image: %@", newImage);
			if (self.delegate) {
				[self.delegate openCVCamera:self capturedImage:newImage];
			}

			[self.captureSession startRunning];
		});
	}];
}

#pragma mark - CvVideoCamera

// override
- (void)createCaptureOutput {
	[super createCaptureOutput];
	[self createStillImageOutput];
}

// override
- (void)stop {
	[super stop];
	stillImageOutput = nil;
}

#pragma mark - Private Functions

- (void)createStillImageOutput {
	// setup still image output with jpeg codec
	stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
	stillImageOutput.outputSettings = @{AVVideoCodecKey: AVVideoCodecJPEG};
	[self.captureSession addOutput:stillImageOutput];

	for (AVCaptureConnection *connection in stillImageOutput.connections) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([port.mediaType isEqual:AVMediaTypeVideo]) {
				self.videoCaptureConnection = connection;
				NSLog(@"Got connection: %@", self.videoCaptureConnection);
				return;
			}
		}
	}

	NSLog(@"No connection available");
}

@end
