//
//  ViewController.swift
//  FaceDetect
//
//  Created by Shyan Hua on 04/01/2019.
//  Copyright © 2019 Shyan Hua. All rights reserved.
//

import UIKit
import AVFoundation
import GoogleMobileVision

class SSRealTimeSelfieCaptureViewController: UIViewController, SSRealTimeSelfieCaptureDelegate
{
    // ===========================================================================
    // MARK:- IBOutlets
    // ===========================================================================
    @IBOutlet weak var placeholder: UIView!
    
    // ===========================================================================
    // MARK:- Stored Properties
    // ===========================================================================
    private var scanner : SSRealTimeSelfieCaptureView?
    
    // ===========================================================================
    // MARK:- Override Functions
    // ===========================================================================
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        initFaceScanner()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        scanner?.startScanner()
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        scanner?.stopScanner()
    }
    
//    override func viewWillDisappear(_ animated: Bool)
//    {
//        super.viewWillDisappear(animated)
//        scanner?.stopScanner()
//    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval)
    {
        // Camera rotation needs to be manually set when rotation changes.
        scanner?.cameraOrientation(orientation: toInterfaceOrientation)
    }
    
    // ===========================================================================
    // MARK:- Private method
    // ===========================================================================
    private func initFaceScanner()
    {
        scanner = SSRealTimeSelfieCaptureView(frame: placeholder.bounds, delegate: self)
        scanner?.setupFaceDetector()
        if scanner != nil
        {
            placeholder.addSubview(scanner!)
        }
        scanner?.framePosition(updateCamera: self.view.layer.bounds)
    }
    
    // ===========================================================================
    // MARK:- SSRealTimeSelfieCaptureDelegate
    // ===========================================================================
    //Face is verified and image has captured ready to return from SSRealTimeSelfieCaptureView
    func faceVerified(controller: SSRealTimeSelfieCaptureView, image: UIImage)
    {
        print("success")
    }
    
    //Action for directions of face detected
    func ssRealTimeSelfieCaptureDidDetectedFaceDirection(controller: SSRealTimeSelfieCaptureView, directionType: FaceDirectionType)
    {
        if(directionType == .didDetectedFrontFace)
        {
            let myAlert = UIAlertController(title:"Face", message:"Front face detected, please show your left face.", preferredStyle: .alert)
            let okAction = UIAlertAction(title:"Ok", style: .default)
            myAlert.addAction(okAction)
            
            if self.presentedViewController == nil
            {
                self.present(myAlert, animated: true,completion: nil)
            }
            else
            {
                self.dismiss(animated: false, completion: nil)
                self.present(myAlert, animated: true,completion: nil)
            }
            
        }
        else if(directionType == .didDetectedLeftFace)
        {
            let myAlert = UIAlertController(title:"Face", message:"Left face detected, please show your right face.", preferredStyle: .alert)
            let okAction = UIAlertAction(title:"Ok", style: .default)
            myAlert.addAction(okAction)
            
            if self.presentedViewController == nil
            {
                self.present(myAlert, animated: true,completion: nil)
            }
            else
            {
                self.dismiss(animated: false, completion: nil)
                self.present(myAlert, animated: true,completion: nil)
            }
        }
        else if(directionType == .didDetectedRightFace)
        {
            let myAlert = UIAlertController(title:"Face", message:"Right face detected, please smile to the camera for selfie capture.", preferredStyle: .alert)
            let okAction = UIAlertAction(title:"Ok", style: .default)
            myAlert.addAction(okAction)
            
            if self.presentedViewController == nil
            {
                self.present(myAlert, animated: true,completion: nil)
            }
            else
            {
                self.dismiss(animated: false, completion: nil)
                self.present(myAlert, animated: true,completion: nil)
            }
        }
        else if(directionType == .didDetectedSmileFace)
        {
            let myAlert = UIAlertController(title:"Face", message:"Captured !", preferredStyle: .alert)
            let okAction = UIAlertAction(title:"Ok", style: .default)
            myAlert.addAction(okAction)
            
            if self.presentedViewController == nil
            {
                self.present(myAlert, animated: true,completion: nil)
            }
            else
            {
                self.dismiss(animated: false, completion: nil)
                self.present(myAlert, animated: true,completion: nil)
            }
        }
    }
    
}

