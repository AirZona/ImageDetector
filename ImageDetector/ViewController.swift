//
//  ViewController.swift
//  ImageDetector
//
//  Created by Thomas Smallwood on 7/12/17.
//  Copyright © 2017 Agile Rocket Software PLLC. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {

    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var visionRequests = [VNRequest]()
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var identifierLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideoSession()
        modelSetup()
    }
    
    func setupVideoSession() {
        guard let video = AVCaptureDevice.default(for: .video), let videoInput = try? AVCaptureDeviceInput(device: video) else {
            fatalError("No video camera available")
        }
        
        session.addInput(videoInput)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoView.layer.addSublayer(previewLayer)
        
        let videoOutput = AVCaptureVideoDataOutput()
        let queue = DispatchQueue(label: "videoQueue")
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        session.sessionPreset = .high
        session.addOutput(videoOutput)
        
        // force portrait only
        let connection = videoOutput.connection(with: .video)
        connection?.videoOrientation = .portrait
        
        session.startRunning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = self.videoView.bounds;
    }
    
    func modelSetup() {
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {
            fatalError("Can't load Resnet50 ML model")
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("unexpected result type from VNCoreMLRequest")
            }
            
            // only want the top 3 observations
            let topObservations = results[0...3].flatMap({ $0.confidence > 0.5 ? $0: nil }).map({ "\($0.identifier) \(String(format:"%.2f", $0.confidence))" })
                .joined(separator: "\n")
            
            DispatchQueue.main.async {
                self?.identifierLabel.text = topObservations
            }
        }
        request.imageCropAndScaleOption = .centerCrop
        visionRequests = [request]
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        connection.videoOrientation = .portrait
        
        var requestOptions:[VNImageOption: Any] = [:]
        
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        
        // for orientation see kCGImagePropertyOrientation
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation(rawValue: 1)!, options: requestOptions)
        do {
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print(error)
        }
    }
    
}

