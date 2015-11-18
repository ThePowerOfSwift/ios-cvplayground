//
//  IWiOSPhotoCameraCtrl.swift
//  CVPlayground
//
//  Created by iwat on 11/11/15.
//  Copyright © 2015 Chaiwat Shuetrakoonpaiboon (iwat). All rights reserved.
//

import UIKit
import AVFoundation
import ImageIO

class IWiOSPhotoCameraCtrl: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

	@IBOutlet weak var previewView: UIView?

	private var captureSession: AVCaptureSession?
	private var captureStillImageOutput: AVCaptureStillImageOutput?
	private var captureVideoDataOutput: AVCaptureVideoDataOutput?
	private var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer?
	private var captureConnection: AVCaptureConnection?

	// MARK: - IWiOSPhotoCameraCtrl

	@IBAction func takePicture() {
		var optVideoConnection: AVCaptureConnection?
		guard let connections = captureStillImageOutput?.connections else {
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

		print("about to request a capture from: \(captureStillImageOutput)")
		captureStillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: { (imageDataSampleBuffer, error) -> Void in
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

		guard let previewView = previewView else {
			print("IWiOSPhotoCameraCtrl.previewView was nil")
			return
		}

		let session = AVCaptureSession()
		session.sessionPreset = AVCaptureSessionPresetPhoto

		let input: AVCaptureDeviceInput?
		do {
			let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
			input = try AVCaptureDeviceInput(device: device)
		} catch let e {
			print("AVCaptureDeviceInput.deviceInputWithDevice: \(e)")
			return
		}

		session.addInput(input)

		let imageOutput = AVCaptureStillImageOutput()
		imageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
		session.addOutput(imageOutput)

		let videoOutputQueue = dispatch_queue_create("IWiOSPhotoCameraCtrl_videoDataOutput", DISPATCH_QUEUE_SERIAL)

		let videoOutput = AVCaptureVideoDataOutput()
		videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
		videoOutput.alwaysDiscardsLateVideoFrames = true
		videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
		session.addOutput(videoOutput)

		let previewLayer = AVCaptureVideoPreviewLayer(session: session)
		previewLayer.frame = previewView.bounds
		previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
		previewView.layer.addSublayer(previewLayer)

		let connection = videoOutput.connectionWithMediaType(AVMediaTypeVideo)
		//connection.enabled = true

		captureSession = session
		captureStillImageOutput = imageOutput
		captureVideoDataOutput = videoOutput
		captureVideoPreviewLayer = previewLayer
		captureConnection = connection
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		captureSession?.startRunning()
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		if let previewView = previewView {
			captureVideoPreviewLayer?.frame = previewView.bounds
		}
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		switch UIApplication.sharedApplication().statusBarOrientation {
		case .Portrait: captureConnection?.videoOrientation = .Portrait
		case .PortraitUpsideDown: captureConnection?.videoOrientation = .PortraitUpsideDown
		case .LandscapeRight: captureConnection?.videoOrientation = .LandscapeRight
		case .LandscapeLeft: captureConnection?.videoOrientation = .LandscapeLeft
		default: break
		}
	}

	// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

	func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
		let image = imageFromSampleBuffer(sampleBuffer)
		_ = image
	}

	// MARK: - Private Functions

	private func imageFromSampleBuffer(sampleBuffer: CMSampleBufferRef) -> UIImage? {
		// Get a CMSampleBuffer's Core Video image buffer for the media data
		guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			return nil
		}
		// Lock the base address of the pixel buffer
		CVPixelBufferLockBaseAddress(imageBuffer, 0)

		// Get the number of bytes per row for the pixel buffer
		let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)

		// Get the number of bytes per row for the pixel buffer
		let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
		// Get the pixel buffer width and height
		let width = CVPixelBufferGetWidth(imageBuffer)
		let height = CVPixelBufferGetHeight(imageBuffer)

		// Create a device-dependent RGB color space
		let colorSpace = CGColorSpaceCreateDeviceRGB()

		// Create a bitmap graphics context with the sample buffer data
		let context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue)
		// Create a Quartz image from the pixel data in the bitmap graphics context
		guard let quartzImage = CGBitmapContextCreateImage(context) else {
			return nil
		}
		// Unlock the pixel buffer
		CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

		dispatch_sync(dispatch_get_main_queue(), {
			self.captureVideoPreviewLayer?.contents = quartzImage
		});

		// Create an image object from the Quartz image
		return UIImage(CGImage: quartzImage)
	}
}
