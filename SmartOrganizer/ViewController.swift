//
//  ViewController.swift
//  SmartOrganizer
//
//  Created by iwat on 11/5/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	@IBOutlet weak var photoView: UIImageView?

	// MARK: - ViewController

	func cornersForImage(inputImage: UIImage) {
		guard let photoView = photoView else {
			return
		}

		let blendFilter = GPUImageAlphaBlendFilter()
		blendFilter.forceProcessingAtSize(photoView.bounds.size)

		let gammaFilter = GPUImageGammaFilter()
		gammaFilter.addTarget(blendFilter)

		let crosshairGenerator = GPUImageCrosshairGenerator()
		crosshairGenerator.crosshairWidth = 15.0
		crosshairGenerator.forceProcessingAtSize(photoView.bounds.size)
		crosshairGenerator.addTarget(blendFilter)

		let cornerFilter = GPUImageHarrisCornerDetectionFilter()
		cornerFilter.threshold = 0.15
		cornerFilter.forceProcessingAtSize(photoView.bounds.size)
		cornerFilter.cornersDetectedBlock = { (cornersArray, numberOfCorners, frameTime) in
			print("Got \(numberOfCorners) corner(s)")
			for var i = UInt(0); i < numberOfCorners; i++ {
				print("Corner[\(i)]: \(cornersArray[Int(i*2)])x\(cornersArray[Int(i*2+1)])")
			}
			crosshairGenerator.renderCrosshairsFromArray(cornersArray, count: numberOfCorners, frameTime: frameTime)
		}

		let stillImageSource = GPUImagePicture(image: inputImage)
		stillImageSource.addTarget(cornerFilter)
		stillImageSource.addTarget(gammaFilter)

		blendFilter.useNextFrameForImageCapture()

		stillImageSource.processImageWithCompletionHandler({
			dispatch_async(dispatch_get_main_queue(), {
				print("Finishing")
				photoView.image = blendFilter.imageFromCurrentFramebuffer()
			})
		})
	}

	// MARK: - UIViewController

	override func viewDidLoad() {
		super.viewDidLoad()
		photoView?.backgroundColor = UIColor.cyanColor()
		photoView?.image = UIImage(named: "test2")
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		cornersForImage(UIImage(named: "test2")!)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

}
