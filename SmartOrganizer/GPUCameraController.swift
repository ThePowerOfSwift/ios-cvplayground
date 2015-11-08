//
//  ViewController.swift
//  SmartOrganizer
//
//  Created by iwat on 11/5/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

import UIKit

class GPUCameraController: UIViewController {

	@IBOutlet weak var cameraView: GPUImageView?

	var videoCamera: GPUImageVideoCamera?

	// MARK: - ViewController

	/*
	 * camera --> houghDetector ==> lineGenerator --> cameraView
	 *        --> gammaFilter ---------------------->
	 */
	func setupCameraDetector() {
		guard let cameraView = cameraView else {
			print("cameraView is nil")
			return
		}

		let blendFilter = GPUImageAlphaBlendFilter()
		blendFilter.forceProcessingAtSize(CGSizeMake(640, 480))

		let gammaFilter = GPUImageGammaFilter()
		gammaFilter.addTarget(blendFilter)

		let lineGenerator = GPUImageLineGenerator()
		lineGenerator.lineWidth = 5.0
		lineGenerator.forceProcessingAtSize(CGSizeMake(640, 480))
		lineGenerator.addTarget(blendFilter)

		let houghDetector = GPUImageHoughTransformLineDetector()
		houghDetector.edgeThreshold = 0.9
		houghDetector.lineDetectionThreshold = 0.15
		houghDetector.linesDetectedBlock = { (lineArray, linesDetected, frameTime) in
			print("#\(frameTime.seconds): Got \(linesDetected) line(s)")
			for var i = 0; i < Int(linesDetected); i++ {
				print("#\(frameTime.seconds): Line[\(i)]: y=\(lineArray[i*2])x + \(lineArray[i*2+1])")
			}
			lineGenerator.renderLinesFromArray(lineArray, count: linesDetected, frameTime: frameTime)
		}

		let camera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: .Back)
		camera.outputImageOrientation = .Portrait
		camera.addTarget(houghDetector)
		camera.addTarget(gammaFilter)

		blendFilter.addTarget(cameraView)
		camera.startCameraCapture()

		videoCamera = camera
	}

	// MARK: - UIViewController

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		setupCameraDetector()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
}
