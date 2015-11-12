//
//  AWiOSPhotoCameraCtrl.swift
//  SmartOrganizer
//
//  Created by iwat on 11/11/15.
//  Copyright © 2015 AuthorWise. All rights reserved.
//

import UIKit
import AVFoundation
import ImageIO

class AWiOSPhotoCameraCtrl: UIViewController {

	@IBOutlet weak var imageView: UIImageView?

	private var captureSession: AVCaptureSession?
	private var stillImageOutput: AVCaptureStillImageOutput?

	// MARK: - AWiOSPhotoCameraCtrl

	@IBAction func takePicture() {
		var optVideoConnection: AVCaptureConnection?
		guard let connections = stillImageOutput?.connections else {
			print("No available connections")
			return
		}
		for any in connections {
			guard let connection = any as? AVCaptureConnection else {
				continue
			}
			for any2 in connection.inputPorts {
				guard let port = any2 as? AVCaptureInputPort else {
					continue
				}
				if port.mediaType == AVMediaTypeVideo {
					optVideoConnection = connection
					break;
				}
			}
			if optVideoConnection != nil {
				break;
			}
		}

		guard let videoConnection = optVideoConnection else {
			print("No video connection available")
			return
		}

		print("about to request a capture from: \(stillImageOutput)")
		stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: { (imageDataSampleBuffer, error) -> Void in
			let exifAttachments = CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyExifDictionary, nil)
			if exifAttachments != nil {
				// Do something with the attachments.
				print("attachements: \(exifAttachments)")
			} else {
				print("no attachments")
			}

			let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)
			guard let image = UIImage(data: imageData) else {
				print("Error decoding image")
				return
			}
			print("\(NSStringFromCGSize(image.size))")
			_ = image
		})
	}

	// MARK: - UIViewController

	override func viewDidLoad() {
		super.viewDidLoad()

		guard let imageView = imageView else {
			print("AWiOSPhotoCameraCtrl.imageView was nil")
			return
		}

		let session = AVCaptureSession()
		session.sessionPreset = AVCaptureSessionPresetPhoto

		let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
		captureVideoPreviewLayer.frame = imageView.bounds
		captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
		imageView.layer.addSublayer(captureVideoPreviewLayer)

		let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)

		let input: AVCaptureDeviceInput?
		do {
			input = try AVCaptureDeviceInput(device: device)
		} catch let e {
			print("AVCaptureDeviceInput.deviceInputWithDevice(\(device)): \(e)")
			return
		}

		session.addInput(input)

		let output = AVCaptureStillImageOutput()
		output.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
		session.addOutput(output)

		captureSession = session
		stillImageOutput = output


		//READ MORE AT https://developer.apple.com/library/ios/qa/qa1702/_index.html
	}
}
