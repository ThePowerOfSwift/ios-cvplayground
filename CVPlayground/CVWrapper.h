//
//  OpenCVWrapper.h
//  CVPlayground
//
//  Created by iwat on 11/9/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

typedef NS_ENUM(NSInteger, CVWrapperError) {
	CVWrapperErrorEmptyImage   = -1001,
	CVWrapperError4CornersOnly = -1002
};

@interface CVWrapper : NSObject

+ (UIImage *)findPaper:(UIImage *)src error:(NSError **)errorPtr;
+ (UIImage *)findCornerMarkers:(UIImage *)src error:(NSError **)errorPtr;

+ (UIImage *)debugDrawLargestBlob:(UIImage *)src edges:(NSUInteger)edges error:(NSError **)errorPtr;
+ (UIImage *)debugDrawBlobs:(UIImage *)src aspectRatio:(CGFloat)ratio error:(NSError **)errorPtr;

#ifdef __cplusplus
+ (void)debugDrawLargestBlobOnMat:(cv::Mat &)srcMat edges:(NSUInteger)edges;
#endif

@end
