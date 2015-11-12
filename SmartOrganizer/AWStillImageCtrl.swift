//
//  OpenCVController.swift
//  SmartOrganizer
//
//  Created by iwat on 11/9/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

import UIKit

class AWStillImageCtrl: UIViewController {

	@IBOutlet weak var imageView: UIImageView?

	// MARK: - UIViewController

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		guard let image = UIImage(named: "test4") else {
			print("Could not load image")
			return
		}

		imageView?.image = CVWrapper.debugDrawLargestBlob(image, edges: 4);
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC)*5), dispatch_get_main_queue(), {
			do {
				self.imageView?.image = try CVWrapper.warpLargestRectangle(image)
			} catch let e {
				print("CVWrapper.warpLargestRectangle error: \(e)")
			}
		})
	}
}
