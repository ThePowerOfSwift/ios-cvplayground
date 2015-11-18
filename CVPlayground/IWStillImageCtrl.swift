//
//  OpenCVController.swift
//  CVPlayground
//
//  Created by iwat on 11/9/15.
//  Copyright © 2015 Chaiwat Shuetrakoonpaiboon (iwat). All rights reserved.
//
//  Use of this source code is governed by MIT license that can be found in the
//  LICENSE file.
//

import UIKit

class IWStillImageCtrl: UIViewController {

	@IBOutlet weak var imageView: UIImageView?

	// MARK: - UIViewController

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		guard let image = UIImage(named: "test7") else {
			print("Could not load image")
			return
		}

		do {
			imageView?.image = try CVWrapper.debugDrawLargestBlob(image, edges: 4);
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC)*2), dispatch_get_main_queue(), {
				do {
					let paper = try CVWrapper.findPaper(image)
					self.imageView?.image = paper

					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC)*2), dispatch_get_main_queue(), {
						do {
							self.imageView?.image = try CVWrapper.findCornerMarkers(paper)
						} catch let e {
							print("CVWrapper.findPaper error: \(e)")
						}
					})
				} catch let e {
					print("CVWrapper.findPaper error: \(e)")
				}
			})
		} catch let e {
			print("CVWrapper.findPaper error: \(e)")
		}
	}
}
