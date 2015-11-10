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

		imageView?.image = OpenCVWrapper.debugDrawLargestBlob(image, edges: 4);
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC)*5), dispatch_get_main_queue(), {
			self.imageView?.image = OpenCVWrapper.warpLargestRectangle(image)
		})
	}
}
