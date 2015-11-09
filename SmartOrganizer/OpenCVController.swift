//
//  OpenCVController.swift
//  SmartOrganizer
//
//  Created by iwat on 11/9/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

import UIKit

class OpenCVController: UIViewController {

	@IBOutlet weak var imageView: UIImageView?

	// MARK: - UIViewController

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		guard let image = UIImage(named: "test5") else {
			print("Could not load image")
			return
		}

		let mat = OpenCVWrapper.matWithImage(image)

		//let corners = OpenCVWrapper.findBiggestContour(mat, size: 4)
		//imageView?.image = OpenCVWrapper.highlightCorners(image, corners: corners)

		//imageView?.image = OpenCVWrapper.warpPerspective(mat, corners: corners)

		let rectangles = OpenCVWrapper.findRectanglesEx(mat, aspectRatio: 1) as! [[AnyObject]]
		imageView?.image = OpenCVWrapper.highlightRectangles(image, corners: rectangles)

		//imageView?.image = OpenCVWrapper.test(image)

		//imageView?.image = OpenCVWrapper.imageRectangles(mat, aspectRatio: 1)
	}
}
