//
//  OpenCVWrapper.h
//  SmartOrganizer
//
//  Created by iwat on 11/9/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpenCVMat: NSObject
@end

@interface OpenCVWrapper: NSObject

+ (OpenCVMat *)matWithImage:(UIImage *)image;
+ (NSArray *)findBiggestContour:(OpenCVMat *)src size:(NSInteger)size; // return [NSValue<CGPoint>] clock-wise order
+ (UIImage *)highlightCorners:(UIImage *)image corners:(NSArray *)corners;
+ (UIImage *)warpPerspective:(OpenCVMat *)src corners:(NSArray *)corners;

@end
