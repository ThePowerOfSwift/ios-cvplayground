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


@implementation OpenCVWrapper

+ (UIImage *) drawOverlay:(UIImage *)image {
	cv::Mat src = [image CVMat];
	if (src.empty()) {
		return nil;
	}

	cv::Mat bw;
	cv::cvtColor(src, bw, CV_BGR2GRAY);
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
			if (area > maxArea && approx.size() == 4) {
				biggest = std::vector<cv::Point>(approx);
				maxArea = area;
			}
		}
	}

	cv::Mat dst(src.size(), CV_8UC3, cv::Scalar(0, 0, 0));

	cv::Scalar colors[3];
	colors[0] = cv::Scalar(255, 0, 0);
	colors[1] = cv::Scalar(0, 255, 0);
	colors[2] = cv::Scalar(0, 0, 255);

	for (int i = 0; i < contours.size(); i++) {
		cv::drawContours(dst, contours, i, colors[i % 3]);
	}

	if (biggest.size() != 4) {
		std::cout << "The object is not quadrilateral! " << std::endl;
		return nil;
	}

	cv::circle(dst, biggest[0], 3, CV_RGB(255,0,0), 2);
	cv::circle(dst, biggest[1], 3, CV_RGB(0,255,0), 2);
	cv::circle(dst, biggest[2], 3, CV_RGB(0,0,255), 2);
	cv::circle(dst, biggest[3], 3, CV_RGB(255,255,255), 2);

	cv::Mat quad = cv::Mat::zeros(300, 220, CV_8UC3);

	std::vector<cv::Point2f> biggest2f;
	biggest2f.push_back(cv::Point2f(biggest[0].x, biggest[0].y));
	biggest2f.push_back(cv::Point2f(biggest[1].x, biggest[1].y));
	biggest2f.push_back(cv::Point2f(biggest[2].x, biggest[2].y));
	biggest2f.push_back(cv::Point2f(biggest[3].x, biggest[3].y));

	std::vector<cv::Point2f> quad_pts;
	quad_pts.push_back(cv::Point2f(0, 0));
	quad_pts.push_back(cv::Point2f(quad.cols, 0));
	quad_pts.push_back(cv::Point2f(quad.cols, quad.rows));
	quad_pts.push_back(cv::Point2f(0, quad.rows));

	cv::Mat transmtx = cv::getPerspectiveTransform(biggest2f, quad_pts);
	cv::warpPerspective(src, quad, transmtx, quad.size());

	return [UIImage imageWithCVMat:quad];
}

@end
