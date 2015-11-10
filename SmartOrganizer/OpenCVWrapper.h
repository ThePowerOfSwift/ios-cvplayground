//
//  OpenCVWrapper.h
//  SmartOrganizer
//
//  Created by iwat on 11/9/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpenCVWrapper: NSObject

+ (UIImage *)warpLargestRectangle:(UIImage *)src;

+ (UIImage *)debugDrawLargestBlob:(UIImage *)src edges:(NSUInteger)edges;
+ (UIImage *)debugDrawBlobs:(UIImage *)src aspectRatio:(CGFloat)ratio;

@end
