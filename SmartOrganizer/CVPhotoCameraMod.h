//
//  CVPhotoCameraMod.h
//
//  Created by Pavlo Razumovkyi on  Jul 17, 2015.
//  @see http://stackoverflow.com/a/31479032/185371
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/ios.h>

@class CVPhotoCameraMod;

@protocol CVPhotoCameraModDelegate <CvPhotoCameraDelegate>

- (void)processImage:(cv::Mat&)image;

@end

@interface CVPhotoCameraMod : CvPhotoCamera <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, retain) CALayer *customPreviewLayer;
@property (nonatomic, retain) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, weak) id <CVPhotoCameraModDelegate> delegate;

- (void)createCustomVideoPreview;

@end
