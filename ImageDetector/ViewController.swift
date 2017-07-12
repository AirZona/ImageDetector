//
//  ViewController.swift
//  ImageDetector
//
//  Created by Thomas Smallwood on 7/12/17.
//  Copyright © 2017 Agile Rocket Software PLLC. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var identifierLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideoSession()
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
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
}

