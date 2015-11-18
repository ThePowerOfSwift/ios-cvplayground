//
//  OpenCVWrapper.m
//  CVPlayground
//
//  Created by iwat on 11/9/15.
//  Copyright © 2015 Chaiwat Shuetrakoonpaiboon (iwat). All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/highgui/ios.h>
#import "CVWrapper.h"

using namespace std;
using namespace cv;

static float targetRatio = 0.0;

@implementation CVWrapper

#pragma mark - Public Functions

+ (UIImage *)findPaper:(UIImage *)src error:(NSError **)errorPtr {
	Mat srcMat;
	if (![CVWrapper UIImageToMat:src mat:srcMat alphaExist:NO error:errorPtr]) {
		return nil;
	}
	cout << "CVWrapper.findPaper: input image " << srcMat.cols << "x" << srcMat.rows << endl;

	vector<cv::Point> corners;
	[CVWrapper findLargestBlob:srcMat edges:4 minArea:(srcMat.rows * srcMat.cols * 0.3) output:corners];
	return [CVWrapper warpPerspective:srcMat corners:corners error:errorPtr];
}

+ (UIImage *)findCornerMarkers:(UIImage *)src error:(NSError **)errorPtr {
	Mat srcMat;
	if (![CVWrapper UIImageToMat:src mat:srcMat alphaExist:NO error:errorPtr]) {
		return nil;
	}
	cout << "CVWrapper.findCornerMarkers: input image " << srcMat.cols << "x" << srcMat.rows << endl;

	Mat grayMat;
	cvtColor(srcMat, grayMat, CV_BGR2GRAY);
	blur(grayMat, grayMat, cv::Size(3, 3));

	vector<KeyPoint> keypoints;

	int width = srcMat.cols * 0.03;
	int size = width * width;

	SimpleBlobDetector::Params params;
	params.minRepeatability = 1;
	params.minArea = size * 0.8;
	params.maxArea = size * 1.2;

	SimpleBlobDetector detector(params);
	detector.detect(grayMat, keypoints);

	[CVWrapper debugContour:srcMat minArea:params.minArea*0.5 maxArea:params.maxArea*1.5];

	// NOTE: example uses drawKeypoints, but it does work on srcMat, so I'm going
	//       to use circle() instead.
	// drawKeypoints(grayMat, keypoints, srcMat, Scalar(0, 0, 255), DrawMatchesFlags::DRAW_RICH_KEYPOINTS);
	for (vector<KeyPoint>::iterator it = keypoints.begin(); it != keypoints.end(); it++) {
		cout << "CVWrapper.findCornerMarkers: blob point: " << it->pt << " size: " << it->size * 0.5 << endl;
		circle(srcMat, it->pt, it->size * 1.5, Scalar(0, 200, 0), 2);
	}

	return MatToUIImage(srcMat);
}

+ (UIImage *)debugDrawLargestBlob:(UIImage *)src edges:(NSUInteger)edges error:(NSError **)errorPtr {
	Mat srcMat;
	if (![CVWrapper UIImageToMat:src mat:srcMat alphaExist:NO error:errorPtr]) {
		return nil;
	}
	cout << "CVWrapper.debugDrawLargestBlob: input image " << srcMat.cols << "x" << srcMat.rows << endl;

	vector<cv::Point> corners;
	[CVWrapper findLargestBlob:srcMat edges:edges minArea:(srcMat.rows * srcMat.cols * 0.3) output:corners];

	vector<vector<cv::Point>> contours;
	contours.push_back(corners);
	drawContours(srcMat, contours, 0, Scalar(255, 0, 0));
	return MatToUIImage(srcMat);
}

+ (void)debugDrawLargestBlobOnMat:(Mat &)srcMat edges:(NSUInteger)edges {
	vector<cv::Point> corners;
	[CVWrapper findLargestBlob:srcMat edges:edges minArea:(srcMat.rows * srcMat.cols * 0.3)  output:corners];

	vector<vector<cv::Point>> contours;
	contours.push_back(corners);
	drawContours(srcMat, contours, 0, Scalar(255, 0, 0));
}

+ (UIImage *)debugDrawBlobs:(UIImage *)src aspectRatio:(CGFloat)ratio error:(NSError **)errorPtr {
	Mat srcMat;
	if (![CVWrapper UIImageToMat:src mat:srcMat alphaExist:NO error:errorPtr]) {
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

/*
 * NOTE: OpenCV provides UIImageToMat() but turns out that it crashes for some unknown
 *       conditions. Reimplementing the same function here does not crash. Yet,
 *       I don't know why.
 */
+ (BOOL)UIImageToMat:(UIImage *)image mat:(cv::Mat &)m alphaExist:(BOOL)alphaExist error:(NSError **)errorPtr {
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
	CGFloat cols = image.size.width, rows = image.size.height;
	CGContextRef contextRef;
	CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
	if (CGColorSpaceGetModel(colorSpace) == 0) {
		m.create(rows, cols, CV_8UC1);
		bitmapInfo = kCGImageAlphaNone;
		if (!alphaExist) {
			bitmapInfo = kCGImageAlphaNone;
		}
		contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8, m.step[0], colorSpace, bitmapInfo);
	} else {
		m.create(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
		if (!alphaExist) {
			bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;
		}
		contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8, m.step[0], colorSpace, bitmapInfo);
	}
	CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
	CGContextRelease(contextRef);

	if (m.empty()) {
		*errorPtr = [NSError errorWithDomain:@"CVWrapper"
										code:CVWrapperErrorEmptyImage
									userInfo:@{NSLocalizedDescriptionKey: @"Input is empty"}];
		return NO;
	}

	return YES;
}

#pragma mark - OpenCV Algorithms

/*
 * Find largest multi-edge object using contour algorithm.
 *
 * @param largest Allocated vector of cv::Point, needs to be initially cleared
 *                so this function can operate properly.
 */
+ (void)findLargestBlob:(Mat &)srcMat edges:(NSInteger)edges minArea:(double)minArea output:(vector<cv::Point> &)largest {
	Mat grayMat;
	cvtColor(srcMat, grayMat, CV_BGR2GRAY);
	blur(grayMat, grayMat, cv::Size(3, 3));

	for (float lowerBound = 220; lowerBound >= 50; lowerBound -= 10) {
		cout << "CVWrapper.findLargestBlob: iterating threshold @" << lowerBound << endl;

		Mat bwMat;
		// NOTE: for some conditions, threshold works better than canny
		//Canny(grayMat, bwMat, lowerBound, lowerBound*3, 3);
		threshold(grayMat, bwMat, lowerBound, 255, CV_THRESH_BINARY);

		// NOTE: uncomment this code for canny/threshold debugging
		//bwMat.copyTo(srcMat);

		vector<vector<cv::Point>> contours;
		findContours(bwMat, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);

		double maxArea = 0;
		for (vector<vector<cv::Point>>::iterator it = contours.begin(); it != contours.end(); it++) {
			double area = contourArea(*it);
			if (area >= minArea) {
				cout << "CVWrapper.findLargestBlob: found large contour of size " << area << endl;
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
		if (maxArea > 0) {
			break;
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

+ (void)debugContour:(Mat &)srcMat minArea:(double)minArea maxArea:(double)maxArea {
	Mat grayMat;
	cvtColor(srcMat, grayMat, CV_BGR2GRAY);
	blur(grayMat, grayMat, cv::Size(3, 3));
	threshold(grayMat, grayMat, 210, 255, CV_THRESH_BINARY);

	vector<vector<cv::Point>> contours;
	findContours(grayMat, contours, RETR_LIST, CHAIN_APPROX_NONE);
	for (vector<vector<cv::Point>>::iterator it = contours.begin(); it != contours.end();) {
		double area = contourArea(*it);
		if (minArea <= area && area < maxArea) {
			it++;
		} else {
			it = contours.erase(it);
		}
	}
	drawContours(srcMat, contours, -1, Scalar(0, 0, 255), CV_FILLED);
}

#pragma mark - UIImage Output Functions

+ (UIImage *)warpPerspective:(Mat &)srcMat corners:(vector<cv::Point>)corners error:(NSError **)errorPtr {
	if (corners.size() != 4) {
		*errorPtr = [NSError errorWithDomain:@"CVWrapper"
										code:CVWrapperError4CornersOnly
									userInfo:@{NSLocalizedDescriptionKey: @"rectangle is required"}];
		return nil;
	}

	// HACK: All functions work well with cv::Point except getPerspectiveTransform
	//       that needs cv::Point2f
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

	cout << "CVWrapper.warpPerspective: corners "
			"TR " << corners[0].x << "x" << corners[0].y << ", "
			"TL " << corners[1].x << "x" << corners[1].y << ", "
			"BL " << corners[2].x << "x" << corners[2].y << ", "
			"BR " << corners[3].x << "x" << corners[3].y << endl;
	cout << "CVWrapper.warpPerspective: average rectangle size " << width << "x" << height << endl;

	if (targetRatio > 0) {
		double peri = arcLength(corners, true);
		height = peri * 0.5 / (targetRatio + 1);
		width = targetRatio * height;
	}

	cout << "Creating warpped Mat of size " << width << "x" << height << endl;
	Mat quad = Mat::zeros(height, width, CV_8UC3);

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
