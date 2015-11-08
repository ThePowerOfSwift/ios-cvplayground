//
//  ViewController.swift
//  SmartOrganizer
//
//  Created by iwat on 11/5/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

import UIKit

class GPUController: UIViewController {

	@IBOutlet weak var photoView: UIImageView?

	// MARK: - ViewController

	/*
	 * stillImageSource --> houghDetector ==> lineGenerator --> blendFilter
	 *                  --> gammaFilter ---------------------->
	 */
	func rectanglesForImage(inputImage: UIImage) {
		guard let photoView = photoView else {
			return
		}

		let blendFilter = GPUImageAlphaBlendFilter()
		blendFilter.forceProcessingAtSize(inputImage.size)

		let gammaFilter = GPUImageGammaFilter()
		gammaFilter.addTarget(blendFilter)

		let crosshairGenerator = GPUImageCrosshairGenerator()
		crosshairGenerator.crosshairWidth = 15.0
		crosshairGenerator.setCrosshairColorRed(1, green: 0, blue: 0)
		crosshairGenerator.forceProcessingAtSize(inputImage.size)
		crosshairGenerator.addTarget(blendFilter)

		let lineGenerator = GPUImageLineGenerator()
		lineGenerator.lineWidth = 5.0
		lineGenerator.forceProcessingAtSize(inputImage.size)
//		lineGenerator.addTarget(blendFilter)

		let harrisDetector = GPUImageHarrisCornerDetectionFilter()
		harrisDetector.cornersDetectedBlock = { (cornerArray, cornersDetected, frameTime) in
			print("Got \(cornersDetected) corner(s)")
			for var i = 0; i < Int(cornersDetected); i++ {
				print("Corner[\(i)]: (\(cornerArray[i*2]),\(cornerArray[i*2+1]))")
			}
			crosshairGenerator.renderCrosshairsFromArray(cornerArray, count: cornersDetected, frameTime: frameTime)
		}

		let houghDetector = GPUImageHoughTransformLineDetector()
		houghDetector.edgeThreshold = 0.9
		houghDetector.lineDetectionThreshold = 0.15
		houghDetector.linesDetectedBlock = { (lineArray, linesDetected, frameTime) in
			print("Got \(linesDetected) line(s)")
			var corners = [GLfloat]()
			for var i = 0; i < Int(linesDetected); i++ {
				print("Line[\(i)]: y=\(lineArray[i*2])x + \(lineArray[i*2+1])")
				for var j = i+1; j < Int(linesDetected); j++ {
					let mb1 = [lineArray[i*2], lineArray[i*2+1]]
					let mb2 = [lineArray[j*2], lineArray[j*2+1]]
					if var corner = self.computeIntersect(mb1, mb2) {
						corners.append(corner[0])
						corners.append(corner[1])
					}
				}
			}
			print("Got \(corners.count/2) corner(s)")
			for var i = 0; i < corners.count/2; i++ {
				print("Corner[\(i)]: (\(corners[i*2]),\(corners[i*2+1]))")
			}
			crosshairGenerator.renderCrosshairsFromArray(&corners, count: UInt(corners.count)/2, frameTime: frameTime)
			lineGenerator.renderLinesFromArray(lineArray, count: linesDetected, frameTime: frameTime)
		}

		let stillImageSource = GPUImagePicture(image: inputImage)
		stillImageSource.addTarget(houghDetector)
//		stillImageSource.addTarget(harrisDetector)
		stillImageSource.addTarget(gammaFilter)

		blendFilter.useNextFrameForImageCapture()

		print("Processing")
		stillImageSource.processImageWithCompletionHandler({
			dispatch_async(dispatch_get_main_queue(), {
				print("Finishing")
				photoView.image = blendFilter.imageFromCurrentFramebuffer()
				photoView.contentMode = .ScaleAspectFit
			})
		})
	}

	// MARK: - UIViewController

	override func viewDidLoad() {
		super.viewDidLoad()
		photoView?.backgroundColor = UIColor.cyanColor()
		photoView?.image = UIImage(named: "test4")
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		rectanglesForImage(self.photoView!.image!)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: - Private functions

	private func computeIntersect(mb1: [GLfloat], _ mb2: [GLfloat]) -> [GLfloat]? {
		if fabs( mb1[0] - mb2[0]) < 0.00001 && fabs( mb1[1] - mb2[1]) < 0.00001 {
			return nil
		}

		let x = (mb2[1] - mb1[1]) / (mb1[0] - mb2[0])
		let y = mb1[0]*x + mb1[1]
		let x_ = (x + 1) * 0.5
		let y_ = (y + 1) * 0.5

		return [x_, y_]
	}
}
