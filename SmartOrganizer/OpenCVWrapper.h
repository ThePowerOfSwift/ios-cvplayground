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

// return [NSValue<CGPoint>] clock-wise order
+ (NSArray *)findBiggestContour:(OpenCVMat *)src size:(NSInteger)size;

// return [[NSValue<CGPoint>]] clock-wise order
+ (NSArray *)findRectangles:(OpenCVMat *)src aspectRatio:(CGFloat)ratio;
+ (UIImage *)imageRectangles:(OpenCVMat *)src aspectRatio:(CGFloat)ratio;

+ (UIImage *)highlightRectangles:(UIImage *)image corners:(NSArray *)rectangles;
+ (UIImage *)highlightCorners:(UIImage *)image corners:(NSArray *)corners;
+ (UIImage *)warpPerspective:(OpenCVMat *)src corners:(NSArray *)corners;

+ (UIImage *)test:(UIImage *)image;

// MARK: - Algorithms Graveyard

/*
 * This function does not work because small blob is very hard to do image analysis.
 * So detecting with approxPolyDP is quite impossible and very error prone.
 */
+ (NSArray *)findRectanglesEx:(OpenCVMat *)src aspectRatio:(CGFloat)ratio;

@end
