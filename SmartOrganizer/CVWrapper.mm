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

static float targetRatio = 0.0;

@implementation CVWrapper

#pragma mark - Public Functions

+ (UIImage *)warpLargestRectangle:(UIImage *)src error:(NSError **)errorPtr {
	Mat srcMat;
	[CVWrapper UIImageToMat:src mat:srcMat alphaExist:NO];
	if (srcMat.empty()) {
		*errorPtr = [NSError errorWithDomain:@"CVWrapper"
										code:CVWrapperErrorEmptyImage
									userInfo:@{NSLocalizedDescriptionKey: @"Input is empty"}];
		return nil;
	}

	vector<cv::Point> corners;
	[CVWrapper findLargestBlob:srcMat edges:4 output:corners];
	return [CVWrapper warpPerspective:srcMat corners:corners error:errorPtr];
}

+ (UIImage *)debugDrawLargestBlob:(UIImage *)src edges:(NSUInteger)edges {
	Mat srcMat;
	[CVWrapper UIImageToMat:src mat:srcMat alphaExist:NO];
	if (srcMat.empty()) {
		cout << "Input image is invalid!" << endl;
		return nil;
	}

	vector<cv::Point> corners;
	[CVWrapper findLargestBlob:srcMat edges:edges output:corners];

	vector<vector<cv::Point>> contours;
	contours.push_back(corners);
	drawContours(srcMat, contours, 0, Scalar(255, 0, 0));
	return MatToUIImage(srcMat);
}

+ (void)debugDrawLargestBlobOnMat:(Mat &)srcMat edges:(NSUInteger)edges {
	vector<cv::Point> corners;
	[CVWrapper findLargestBlob:srcMat edges:edges output:corners];

	vector<vector<cv::Point>> contours;
	contours.push_back(corners);
	drawContours(srcMat, contours, 0, Scalar(255, 0, 0));
}

+ (UIImage *)debugDrawBlobs:(UIImage *)src aspectRatio:(CGFloat)ratio {
	Mat srcMat;
	[CVWrapper UIImageToMat:src mat:srcMat alphaExist:NO];
	if (srcMat.empty()) {
		cout << "Input image is invalid!" << endl;
		return nil;
	}

	vector<cv::Rect> boxes;
	vector<vector<cv::Point>> contours;

	// NOTE: This is not vert effective since we can reuse the result of
	// cvtColor, threshold, and bitwise_not.
	[CVWrapper findBlobBoundingBoxes:srcMat aspectRatio:ratio output:boxes];
	[CVWrapper findBlobContours:srcMat aspectRatio:ratio output:contours];

	drawContours(srcMat, contours, -1, Scalar(255, 0, 0));
	for (vector<cv::Rect>::iterator it = boxes.begin(); it != boxes.end(); it++) {
		rectangle(srcMat, *it, Scalar(0, 255, 0));
	}
	return MatToUIImage(srcMat);
}

#pragma mark - Private Utilities

+ (void)UIImageToMat:(UIImage *)image mat:(cv::Mat &)m alphaExist:(BOOL)alphaExist {
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
	CGFloat cols = image.size.width, rows = image.size.height;
	CGContextRef contextRef;
	CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
	if (CGColorSpaceGetModel(colorSpace) == 0)
	{
		m.create(rows, cols, CV_8UC1);
		bitmapInfo = kCGImageAlphaNone;
		if (!alphaExist)
			bitmapInfo = kCGImageAlphaNone;
		contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
										   m.step[0], colorSpace,
										   bitmapInfo);
	}
	else
	{
		m.create(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
		if (!alphaExist)
			bitmapInfo = kCGImageAlphaNoneSkipLast |
			kCGBitmapByteOrderDefault;
		contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
										   m.step[0], colorSpace,
										   bitmapInfo);
	}
	CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows),
					   image.CGImage);
	CGContextRelease(contextRef);
}

#pragma mark - OpenCV Algorithms

/*
 * Find largest multi-edge object using contour algorithm.
 *
 * @param largest Allocated vector of cv::Point, needs to be initially cleared
 *                so this function can operate properly.
 */
+ (void)findLargestBlob:(Mat &)srcMat edges:(NSInteger)edges output:(vector<cv::Point> &)largest {
	Mat bw;
	cvtColor(srcMat, bw, CV_BGR2GRAY);
	blur(bw, bw, cv::Size(3, 3));
	Canny(bw, bw, 50, 200, 3);

	vector<vector<cv::Point>> contours;
	findContours(bw, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);

	double maxArea = 0;
	for (vector<vector<cv::Point>>::iterator it = contours.begin(); it != contours.end(); it++) {
		double area = contourArea(*it);
		if (area > 500) {
			double peri = arcLength(*it, true);
			vector<cv::Point> approx;
			approxPolyDP(*it, approx, 0.02*peri, true);
			if (area > maxArea && approx.size() == edges) {
				// Credit: http://stackoverflow.com/questions/2551775/c-appending-a-vector-to-a-vector
				largest.clear();
				largest.insert(end(largest), begin(approx), end(approx));
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
+ (void)findBlobBoundingBoxes:(Mat &)srcMat aspectRatio:(CGFloat)ratio output:(vector<cv::Rect> &)boxes {
	Mat bw;
	cvtColor(srcMat, bw, CV_BGR2GRAY);
	threshold(bw, bw, 128, 255, CV_THRESH_BINARY);
	bitwise_not(bw, bw);

	vector<vector<cv::Point>> contours;
	findContours(bw, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);

	for (vector<vector<cv::Point>>::iterator it = contours.begin(); it != contours.end(); it++) {
		cv::Rect rect = boundingRect(*it);
		double k = (rect.height+0.0)/rect.width;
		if (fabs(k - ratio) < 0.1 && rect.area() > 100) {
			boxes.push_back(rect);
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
+ (void)findBlobContours:(Mat &)srcMat aspectRatio:(CGFloat)ratio output:(vector<vector<cv::Point>> &)contours {
	Mat bw;
	cvtColor(srcMat, bw, CV_BGR2GRAY);
	threshold(bw, bw, 128, 255, CV_THRESH_BINARY);
	bitwise_not(bw, bw);

	vector<vector<cv::Point>> allContours;
	findContours(bw, allContours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE);

	for (vector<vector<cv::Point>>::iterator it = allContours.begin(); it != allContours.end(); it++) {
		cv::Rect rect = boundingRect(*it);
		double k = (rect.height+0.0)/rect.width;
		if (fabs(k - ratio) < 0.1 && rect.area() > 100) {
			contours.push_back(*it);
		}
	}
}

#pragma mark - UIImage Output Functions

+ (UIImage *)warpPerspective:(Mat &)srcMat corners:(vector<cv::Point>)corners error:(NSError **)errorPtr {
	if (corners.size() != 4) {
		*errorPtr = [NSError errorWithDomain:@"CVWrapper"
										code:CVWrapperError4CornersOnly
									userInfo:@{NSLocalizedDescriptionKey: @"rectangle is required"}];
		return nil;
	}

	// HACK: Too bad, seems that all functions work well with cv::Point except
	// getPerspectiveTransform that needs cv::Point2f
	vector<Point2f> corners2f;
	for (vector<cv::Point>::iterator it = corners.begin(); it != corners.end(); it++) {
		corners2f.push_back(Point2f(it->x, it->y));
	}

	float xs[] = {
		(float)corners[0].x - corners[1].x,
		(float)corners[1].x - corners[2].x,
		(float)corners[2].x - corners[3].x,
		(float)corners[3].x - corners[0].x};
	float ys[] = {
		(float)corners[0].y - corners[1].y,
		(float)corners[1].y - corners[2].y,
		(float)corners[2].y - corners[3].y,
		(float)corners[3].y - corners[0].y};
	float dst[] = {0, 0, 0, 0};
	magnitude(xs, ys, dst, 4);

	float width = (dst[0] + dst[2]) * 0.5;
	float height = (dst[1] + dst[3]) * 0.5;

	cout << corners[0].x << "x" << corners[0].y << "," << corners[1].x << "x" << corners[1].y << "," << corners[2].x << "x" << corners[2].y << "," << corners[3].x << "x" << corners[3].y << endl;
	cout << dst[0] << "," << dst[1] << "," << dst[2] << "," << dst[3] << endl;
	cout << width << "x" << height << endl;

	if (targetRatio > 0) {
		double peri = arcLength(corners, true);
		height = peri * 0.5 / (targetRatio + 1);
		width = targetRatio * height;
	}

	cout << "Creating warpped Mat of size " << width << "x" << height << endl;
	Mat quad = Mat::zeros(width, height, CV_8UC3);

	vector<Point2f> quad_pts;
	quad_pts.push_back(Point2f(quad.cols, 0));
	quad_pts.push_back(Point2f(0, 0));
	quad_pts.push_back(Point2f(0, quad.rows));
	quad_pts.push_back(Point2f(quad.cols, quad.rows));

	Mat transmtx = getPerspectiveTransform(corners2f, quad_pts);
	warpPerspective(srcMat, quad, transmtx, quad.size());

	return MatToUIImage(quad);
}

@end
