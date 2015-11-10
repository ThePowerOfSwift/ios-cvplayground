//
//  OpenCVWrapper.m
//  SmartOrganizer
//
//  Created by iwat on 11/9/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/highgui/ios.h>
#import "CVWrapper.h"

using namespace std;
using namespace cv;

@implementation CVWrapper

#pragma mark - Public Functions

+ (UIImage *)warpLargestRectangle:(UIImage *)src {
	Mat srcMat;
	UIImageToMat(src, srcMat);
	if (srcMat.empty()) {
		cout << "Input image is invalid!" << endl;
		return nil;
	}

	vector<cv::Point> corners;
	[CVWrapper findLargestBlob:srcMat edges:4 output:&corners];
	return [CVWrapper warpPerspective:srcMat corners:corners];
}

+ (UIImage *)debugDrawLargestBlob:(UIImage *)src edges:(NSUInteger)edges {
	Mat srcMat;
	UIImageToMat(src, srcMat);
	if (srcMat.empty()) {
		cout << "Input image is invalid!" << endl;
		return nil;
	}

	vector<cv::Point> corners;
	[CVWrapper findLargestBlob:srcMat edges:edges output:&corners];

	vector<vector<cv::Point>> contours;
	contours.push_back(corners);
	drawContours(srcMat, contours, 0, Scalar(255, 0, 0));
	return MatToUIImage(srcMat);
}

+ (UIImage *)debugDrawBlobs:(UIImage *)src aspectRatio:(CGFloat)ratio {
	Mat srcMat;
	UIImageToMat(src, srcMat);
	if (srcMat.empty()) {
		cout << "Input image is invalid!" << endl;
		return nil;
	}

	vector<cv::Rect> boxes;
	vector<vector<cv::Point>> contours;

	// NOTE: This is not vert effective since we can reuse the result of
	// cvtColor, threshold, and bitwise_not.
	[CVWrapper findBlobBoundingBoxes:srcMat.clone() aspectRatio:ratio output:&boxes];
	[CVWrapper findBlobContours:srcMat.clone() aspectRatio:ratio output:&contours];

	drawContours(srcMat, contours, -1, Scalar(255, 0, 0));
	for (vector<cv::Rect>::iterator it = boxes.begin(); it != boxes.end(); it++) {
		rectangle(srcMat, *it, Scalar(0, 255, 0));
	}
	return MatToUIImage(srcMat);
}

#pragma mark - Private Utilities

#pragma mark - OpenCV Algorithms

/*
 * Find largest multi-edge object using contour algorithm.
 *
 * @param largest Allocated vector of cv::Point, needs to be initially cleared
 *                so this function can operate properly.
 */
+ (void)findLargestBlob:(Mat)srcMat edges:(NSInteger)edges output:(vector<cv::Point> *)largest {
	Mat bw;
	cvtColor(srcMat, bw, CV_BGR2GRAY);
	threshold(bw, bw, 128, 255, CV_THRESH_BINARY);

	vector<vector<cv::Point> > contours;
	findContours(bw, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);

	double maxArea = 0;
	for (vector<vector<cv::Point>>::iterator it = contours.begin(); it != contours.end(); it++) {
		double area = contourArea(*it);
		if (area > 100) {
			double peri = arcLength(*it, true);
			vector<cv::Point> approx;
			approxPolyDP(*it, approx, 0.02*peri, true);
			if (area > maxArea && approx.size() == edges) {
				// Credit: http://stackoverflow.com/questions/2551775/c-appending-a-vector-to-a-vector
				largest->clear();
				largest->insert(end(*largest), begin(approx), end(approx));
				maxArea = area;
			}
		}
	}
}

/*
 * Find bounding boxes of all blobs with bounding aspect ratio approximately to
 * the given ratio.
 *
 * @param boxes Allocated vector of cv::Rect.
 */
+ (void)findBlobBoundingBoxes:(Mat)srcMat aspectRatio:(CGFloat)ratio output:(vector<cv::Rect> *)boxes {
	Mat bw;
	cvtColor(srcMat, bw, CV_BGR2GRAY);
	threshold(bw, bw, 128, 255, CV_THRESH_BINARY);
	bitwise_not(bw, bw);

	vector<vector<cv::Point> > contours;
	findContours(bw, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);

	for (vector<vector<cv::Point>>::iterator it = contours.begin(); it != contours.end(); it++) {
		cv::Rect rect = boundingRect(*it);
		double k = (rect.height+0.0)/rect.width;
		if (fabs(k - ratio) < 0.1 && rect.area() > 100) {
			boxes->push_back(rect);
		}
	}
}

/*
 * Find contours of all blobs with bounding aspect ratio approximately to the
 * given ratio.
 *
 * @param contours Allocated vector of vector of cv::Point, needs to be
 *                 initially cleared so this function can operate properly.
 */
+ (void)findBlobContours:(Mat)srcMat aspectRatio:(CGFloat)ratio output:(vector<vector<cv::Point>> *)contours {
	Mat bw;
	cvtColor(srcMat, bw, CV_BGR2GRAY);
	threshold(bw, bw, 128, 255, CV_THRESH_BINARY);
	bitwise_not(bw, bw);

	vector<vector<cv::Point> > allContours;
	findContours(bw, allContours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);

	for (vector<vector<cv::Point>>::iterator it = allContours.begin(); it != allContours.end(); it++) {
		cv::Rect rect = boundingRect(*it);
		double k = (rect.height+0.0)/rect.width;
		if (fabs(k - ratio) < 0.1 && rect.area() > 100) {
			contours->push_back(*it);
		}
	}
}

#pragma mark - UIImage Output Functions

+ (UIImage *)warpPerspective:(Mat)srcMat corners:(vector<cv::Point>)corners {
	if (corners.size() != 4) {
		cout << "4 corners only" << endl;
		return nil;
	}

	// HACK: Too bad, seems that all functions work well with cv::Point except
	// getPerspectiveTransform that needs cv::Point2f
	vector<Point2f> corners2f;
	for (vector<cv::Point>::iterator it = corners.begin(); it != corners.end(); it++) {
		corners2f.push_back(Point2f(it->x, it->y));
	}

	Mat quad = Mat::zeros(300, 220, CV_8UC3);

	vector<Point2f> quad_pts;
	quad_pts.push_back(Point2f(0, 0));
	quad_pts.push_back(Point2f(quad.cols, 0));
	quad_pts.push_back(Point2f(quad.cols, quad.rows));
	quad_pts.push_back(Point2f(0, quad.rows));

	Mat transmtx = getPerspectiveTransform(corners2f, quad_pts);
	warpPerspective(srcMat, quad, transmtx, quad.size());

	return MatToUIImage(quad);
}

@end
