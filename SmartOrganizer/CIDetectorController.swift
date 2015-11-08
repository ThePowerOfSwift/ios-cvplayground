//
//  CIDetectorController.swift
//  SmartOrganizer
//
//  Created by iwat on 11/7/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

import UIKit
import CoreImage

class CIDetectorController: UIViewController {

	@IBOutlet weak var imageView: UIImageView?

	// MARK: - UIViewController

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		guard let image = UIImage(named: "test4") else {
			print("Could not load image")
			return
		}

		guard let ciimage = CIImage(image: image) else {
			print("Could not initialize CIImage")
			return
		}

		let detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: nil)
		let features = detector.featuresInImage(ciimage, options: [CIDetectorReturnSubFeatures: true])
		imageView?.image = drawOverlay(image, features: features)
	}

	// MARK: - Private functions

	private func flip(y: CGFloat, _ h: CGFloat) -> CGFloat {
		return h - y
	}

	private func drawOverlay(image: UIImage, features: [CIFeature]) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
		image.drawAtPoint(CGPointZero)

		let context = UIGraphicsGetCurrentContext()
		CGContextSetRGBStrokeColor(context, 0.0, 1.0, 0.0, 1.0);
		CGContextSetLineWidth(context, 1.0);

		for f in features {
			guard let r = f as? CIRectangleFeature else {
				print("Skipping \(f)")
				continue
			}

			let minX = min(r.topLeft.x, r.bottomLeft.x)
			let minY = min(r.topLeft.y, r.topRight.y)
			let maxX = max(r.topRight.x, r.bottomRight.x)
			let maxY = max(r.bottomLeft.y, r.bottomRight.y)

			var area = (r.topLeft.x - minX) * (r.bottomLeft.y - minY) * 0.5
			area += (maxX - r.topLeft.x) * (r.topRight.y - minY) * 0.5
			area += (r.bottomRight.x - minX) * (maxY - r.bottomLeft.y) * 0.5
			area += (maxX - r.bottomRight.x) * (maxY - r.topRight.y) * 0.5

			CGContextMoveToPoint(context, r.topLeft.x, flip(r.topLeft.y, image.size.height))
			CGContextAddLineToPoint(context, r.topRight.x, flip(r.topRight.y, image.size.height))
			CGContextAddLineToPoint(context, r.bottomRight.x, flip(r.bottomRight.y, image.size.height))
			CGContextAddLineToPoint(context, r.bottomLeft.x, flip(r.bottomLeft.y, image.size.height))

			CGContextSetFillColorWithColor(context, UIColor.redColor().CGColor)
			CGContextFillPath(context);

			break;
		}

		let returnImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext();

		return returnImage
	}
}
