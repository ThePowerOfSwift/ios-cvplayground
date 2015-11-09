//
//  OpenCVWrapper.m
//  SmartOrganizer
//
//  Created by iwat on 11/9/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

#import <opencv2/opencv.hpp>

#import "UIImage+OpenCV.h"

#import "OpenCVWrapper.h"


@interface OpenCVMat (Private)
@property (nonatomic) cv::Mat *mat;
@end

@implementation OpenCVMat { cv::Mat *_mat; }
- (cv::Mat *)mat { return self->_mat; }
- (void)setMat:(cv::Mat *)mat { self->_mat = mat; }
- (void)dealloc {
	if (self.mat != nil) {
		self.mat->release();
	}
}
@end

@implementation OpenCVWrapper

+ (OpenCVMat *)matWithImage:(UIImage *)image {
	cv::Mat cvMat = [image CVMat];
	if (cvMat.empty()) {
		std::cout << "Input image is invalid!" << std::endl;
		return nil;
	}

	OpenCVMat *mat = [[OpenCVMat alloc] init];
	mat.mat = new cv::Mat(cvMat);
	return mat;
}

+ (NSArray *)findBiggestContour:(OpenCVMat *)src size:(NSInteger)size {
	cv::Mat bw;
	cv::cvtColor(*src.mat, bw, CV_BGR2GRAY);
	cv::threshold(bw, bw, 128, 255, CV_THRESH_BINARY);

	std::vector<std::vector<cv::Point> > contours;
	cv::findContours(bw, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);

	std::vector<cv::Point> biggest;
	double maxArea = 0;
	for (int i = 0; i < contours.size(); i++) {
		double area = cv::contourArea(contours[i]);
		if (area > 100) {
			double peri = cv::arcLength(contours[i], true);
			std::vector<cv::Point> approx;
			cv::approxPolyDP(contours[i], approx, 0.02*peri, true);
			if (area > maxArea && approx.size() == size) {
				biggest = std::vector<cv::Point>(approx);
				maxArea = area;
			}
		}
	}

	if (biggest.size() != size) {
		std::cout << "No object found!" << std::endl;
		return nil;
	}

	NSMutableArray *result = [[NSMutableArray alloc] init];
	for (int i = 0; i < biggest.size(); i++) {
		[result addObject:[NSValue valueWithCGPoint:CGPointMake(biggest[i].x, biggest[i].y)]];
	}

	return result;
}

+ (UIImage *)highlightCorners:(UIImage *)image corners:(NSArray *)corners {
	cv::Mat src = [image CVMat];
	if (src.empty()) {
		std::cout << "Input image is invalid!" << std::endl;
		return nil;
	}

	CGFloat offset = 0;
	CGFloat step = 1.0 / [corners count];
	for (int i = 0; i < [corners count]; i++) {
		NSValue *corner = [corners objectAtIndex:i];
		CGPoint point = [corner CGPointValue];
		CGFloat r, g, b;
		[[UIColor colorWithHue:offset saturation:1 brightness:1 alpha:1] getRed:&r green:&g blue:&b alpha:nil];
		cv::circle(src, cv::Point(point.x, point.y), 3, CV_RGB(r*255,g*255,b*255), 2);
		offset += step;
	}

	return [UIImage imageWithCVMat:src];
}

+ (UIImage *)warpPerspective:(OpenCVMat *)src corners:(NSArray *)corners {
	std::vector<cv::Point2f> corners2f;
	for (int i = 0; i < [corners count]; i++) {
		NSValue *corner = [corners objectAtIndex:i];
		CGPoint point = [corner CGPointValue];
		corners2f.push_back(cv::Point2f(point.x, point.y));
	}

	cv::Mat quad = cv::Mat::zeros(300, 220, CV_8UC3);

	std::vector<cv::Point2f> quad_pts;
	quad_pts.push_back(cv::Point2f(0, 0));
	quad_pts.push_back(cv::Point2f(quad.cols, 0));
	quad_pts.push_back(cv::Point2f(quad.cols, quad.rows));
	quad_pts.push_back(cv::Point2f(0, quad.rows));

	cv::Mat transmtx = cv::getPerspectiveTransform(corners2f, quad_pts);
	cv::warpPerspective(*src.mat, quad, transmtx, quad.size());

	return [UIImage imageWithCVMat:quad];
}

@end
