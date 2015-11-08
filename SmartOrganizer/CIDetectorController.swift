//
//  CIDetectorController.swift
//  SmartOrganizer
//
//  Created by iwat on 11/7/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

import UIKit
import Accelerate
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

	private func drawOverlay(input: UIImage, features: [CIFeature]) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(input.size, false, input.scale)
		input.drawAtPoint(CGPointZero)

		let context = UIGraphicsGetCurrentContext()
		CGContextSetRGBStrokeColor(context, 0.0, 1.0, 0.0, 1.0);
		CGContextSetLineWidth(context, 1.0);

		var biggest: CIRectangleFeature?

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

			print("Rectangle area: \((maxX - minX)*(maxY - minY))")
			print("Quad area: \((maxX - minX)*(maxY - minY) - area)")

			CGContextMoveToPoint(context, r.topLeft.x, flip(r.topLeft.y, input.size.height))
			CGContextAddLineToPoint(context, r.topRight.x, flip(r.topRight.y, input.size.height))
			CGContextAddLineToPoint(context, r.bottomRight.x, flip(r.bottomRight.y, input.size.height))
			CGContextAddLineToPoint(context, r.bottomLeft.x, flip(r.bottomLeft.y, input.size.height))

			CGContextSetFillColorWithColor(context, UIColor.redColor().CGColor)
			CGContextFillPath(context);

			biggest = r

			break;
		}

		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext();

		guard let srcCoord = biggest else {
			print("No biggest rectangle")
			return image
		}
		print("Got rectangle:")
		print("  \(srcCoord.topLeft.x) \(flip(srcCoord.topLeft.y, image.size.height))")
		print("  \(srcCoord.topRight.x) \(flip(srcCoord.topRight.y, image.size.height))")
		print("  \(srcCoord.bottomRight.x) \(flip(srcCoord.bottomRight.y, image.size.height))")
		print("  \(srcCoord.bottomLeft.x) \(flip(srcCoord.bottomLeft.y, image.size.height))")

		guard let cgImage = image.CGImage else {
			print("No CGImage")
			return image
		}

		guard let cgColorSpace = CGImageGetColorSpace(cgImage) else {
			print("Could not retrieve color space")
			return image
		}

		let bitsPerComponent = CGImageGetBitsPerComponent(cgImage)
		let bitmapInfo = CGImageGetBitmapInfo(cgImage)
		var buffer = vImage_Buffer()
		var format = vImage_CGImageFormat(
			bitsPerComponent: UInt32(bitsPerComponent),
			bitsPerPixel: UInt32(CGImageGetBitsPerPixel(cgImage)),
			colorSpace: Unmanaged.passUnretained(cgColorSpace),
			bitmapInfo: bitmapInfo,
			version: 0,
			decode: CGImageGetDecode(cgImage),
			renderingIntent: .RenderingIntentDefault)

		var error = vImageBuffer_InitWithCGImage(&buffer, &format, nil, cgImage, UInt32(kvImageNoFlags))
		if error != kvImageNoError {
			print("Error creating buffer: \(error)")
			return image
		}

		print("Prepared source buffer:", buffer.width, buffer.height)

		var transform = perspectiveTransform(
			Float(srcCoord.topLeft.x), Float(flip(srcCoord.topLeft.y, image.size.height)),
			Float(srcCoord.topRight.x), Float(flip(srcCoord.topRight.y, image.size.height)),
			Float(srcCoord.bottomRight.x), Float(flip(srcCoord.bottomRight.y, image.size.height)),
			Float(srcCoord.bottomLeft.x), Float(flip(srcCoord.bottomLeft.y, image.size.height)),
			0, 0, 220, 0, 220, 300, 0, 300)

		error = vImageAffineWarp_ARGB8888(&buffer, &buffer, nil, &transform, [0, 0, 0, 0], UInt32(kvImageNoFlags))
		if error != kvImageNoError {
			print("Error scalling: \(error)")
			return image
		}

		let vCtx = CGBitmapContextCreate(buffer.data, Int(buffer.width), Int(buffer.height), bitsPerComponent, buffer.rowBytes, cgColorSpace, bitmapInfo.rawValue)
		guard let imageRef = CGBitmapContextCreateImage(vCtx) else {
			print("Error creating bitmap ref")
			return image
		}

		print("Returning warped image")
		return UIImage(CGImage: imageRef)
	}

	func perspectiveTransform(x1: Float, _ y1: Float, _ x2: Float, _ y2: Float, _ x3: Float, _ y3: Float, _ x4: Float, _ y4: Float, _ u1: Float, _ v1: Float, _ u2: Float, _ v2: Float, _ u3: Float, _ v3: Float, _ u4: Float, _ v4: Float) -> vImage_AffineTransform {
		var xyuv: [Float] = [
			x1, y1, 1,  0,  0, 0, -x1*u1, -y1*u1,
			 0,  0, 0, x1, y1, 1, -x1*v1, -y1*v1,
			x2, y2, 1,  0,  0, 0, -x2*u2, -y2*u2,
			 0,  0, 0, x2, y2, 1, -x2*v2, -y2*v2,
			x3, y3, 1,  0,  0, 0, -x3*u3, -y3*u3,
			 0,  0, 0, x3, y3, 1, -x3*v3, -y3*v3,
			x4, y4, 1,  0,  0, 0, -x4*u4, -y4*u4,
			 0,  0, 0, x4, y4, 1, -x4*v4, -y4*v4
		]

		let uv: [Float] = [
			u1,
			v1,
			u2,
			v2,
			u3,
			v3,
			u4,
			v4
		]

		var m = [Float](count: 8, repeatedValue: 0)

		xyuv = invert(xyuv)

		vDSP_mmul(xyuv, 1, uv, 1, &m, 1, 8, 1, 8)
		return vImage_AffineTransform(a: m[0], b: m[1], c: m[3], d: m[4], tx: m[2], ty: m[5])
	}

	func invert(matrix : [Float]) -> [Float] {
		var inMatrix = matrix.map { (f) -> Double in
			return Double(f)
		}
		var N = __CLPK_integer(sqrt(Double(matrix.count)))
		var pivots = [__CLPK_integer](count: Int(N), repeatedValue: 0)
		var workspace = [Double](count: Int(N), repeatedValue: 0.0)
		var error : __CLPK_integer = 0
		dgetrf_(&N, &N, &inMatrix, &N, &pivots, &error)
		dgetri_(&N, &inMatrix, &N, &pivots, &workspace, &N, &error)
		return inMatrix.map({ (d) -> Float in
			return Float(d)
		})
	}
}
