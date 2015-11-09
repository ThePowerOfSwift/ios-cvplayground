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

		guard let image = UIImage(named: "test4") else {
			print("Could not load image")
			return
		}

		let mat = OpenCVWrapper.matWithImage(image)
		let corners = OpenCVWrapper.findBiggestContour(mat, size: 4)
		imageView?.image = OpenCVWrapper.highlightCorners(image, corners: corners)

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3*Int64(NSEC_PER_SEC)), dispatch_get_main_queue()) {
			self.imageView?.image = OpenCVWrapper.warpPerspective(mat, corners: corners)
		}
	}
}
