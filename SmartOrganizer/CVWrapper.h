//
//  OpenCVWrapper.h
//  SmartOrganizer
//
//  Created by iwat on 11/9/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

@interface CVWrapper : NSObject

+ (UIImage *)warpLargestRectangle:(UIImage *)src;

+ (UIImage *)debugDrawLargestBlob:(UIImage *)src edges:(NSUInteger)edges;

+ (UIImage *)debugDrawBlobs:(UIImage *)src aspectRatio:(CGFloat)ratio;

#ifdef __cplusplus
+ (void)debugDrawLargestBlobOnMat:(cv::Mat &)srcMat edges:(NSUInteger)edges;
#endif

@end
