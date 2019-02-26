//
//  SSRealTimeSelfieCaptureView.swift
//  FaceDetect
//
//  Created by Shyan Hua on 19/02/2019.
//  Copyright © 2019 Shyan Hua. All rights reserved.
//

import GoogleMobileVision

// ===========================================================================
// MARK:- Enum
// ===========================================================================
public enum FaceDirectionType
{
    case didDetectedFrontFace
    case didDetectedLeftFace
    case didDetectedRightFace
    case didDetectedSmileFace
}

// ===========================================================================
// MARK:- Delegation
// ===========================================================================
public protocol SSRealTimeSelfieCaptureDelegate: class
{
    //Delegate based on face direction
    func ssRealTimeSelfieCaptureDidDetectedFaceDirection(controller: SSRealTimeSelfieCaptureView, directionType : FaceDirectionType) -> Void
    
    //Delegate to capture a selfie once verified
    func faceVerified(controller: SSRealTimeSelfieCaptureView, image : UIImage) -> Void
}

// ===========================================================================
// MARK:- Controller
// ===========================================================================
open class SSRealTimeSelfieCaptureView : UIView, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate
{
    private var faceDetector: GMVDetector?
    private var faceId : UInt = 0
    private var flagFrontFace = false, flagSmile = false, flagFaceRight = false, flagFaceLeft = false, flagFaceId = false, flagCapture = false
    private weak var selfieDelegate : SSRealTimeSelfieCaptureDelegate?

    //Video objects
    private var session: AVCaptureSession?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var videoDataOutputQueue: DispatchQueue?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    //Selfie object
    private var stillImageOutput = AVCapturePhotoOutput()
    
    // ===========================================================================
    // MARK:- Public method
    // ===========================================================================
    required public init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    public func startScanner()
    {
        session?.startRunning()
    }
    
    public func stopScanner()
    {
        session?.stopRunning()
    }
    
    public func framePosition(updateCamera : CGRect)
    {
        previewLayer?.frame = updateCamera
        previewLayer?.position = CGPoint(x: (previewLayer?.frame.midX)!, y: (previewLayer?.frame.midY)!)
    }
    
    public func cameraOrientation(orientation : UIInterfaceOrientation)
    {
        if previewLayer != nil
        {
            if orientation == UIInterfaceOrientation.portrait
            {
                previewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            }
            else if orientation == UIInterfaceOrientation.portraitUpsideDown
            {
                previewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
            }
            else if orientation == UIInterfaceOrientation.landscapeLeft
            {
                previewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
            }
            else if orientation == UIInterfaceOrientation.landscapeRight
            {
                previewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.landscapeRight
            }
        }
    }
    
    public func setupFaceDetector()
    {
        session = AVCaptureSession()
        session?.sessionPreset = AVCaptureSession.Preset.medium
        
        
        updateCameraSelection()
        setupVideoProcessing()
        setupCameraPreview()
        
        faceDetector = GMVDetector(ofType: GMVDetectorTypeFace, options: [GMVDetectorFaceLandmarkType: GMVDetectorFaceLandmark.all.rawValue,
                                                                          GMVDetectorFaceClassificationType: GMVDetectorFaceClassification.all.rawValue,
                                                                          GMVDetectorFaceMinSize: 0.3,
                                                                          GMVDetectorFaceTrackingEnabled: true])
    }
    
    override public init(frame: CGRect)
    {
        super.init(frame : frame)
    }
    
    convenience public init(frame: CGRect , delegate : SSRealTimeSelfieCaptureDelegate)
    {
        self.init(frame: frame)
        self.selfieDelegate = delegate
    }
    
    // ===========================================================================
    // MARK:- Private method
    // ===========================================================================
    private func resetFlag()
    {
        flagSmile = false
        flagFrontFace = false
        flagFaceLeft = false
        flagFaceRight = false
        flagFaceId = false
        flagCapture = false
    }
    
    private func capturePhoto()
    {
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160,
                             kCVPixelBufferHeightKey as String: 160]
        settings.previewPhotoFormat = previewFormat
        
        stillImageOutput.isHighResolutionCaptureEnabled = true
        stillImageOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func deviceOrientationFromInterfaceOrientation() -> UIDeviceOrientation
    {
        var defaultOrientation: UIDeviceOrientation = UIDeviceOrientation.portrait
        switch UIApplication.shared.statusBarOrientation
        {
        case UIInterfaceOrientation.landscapeLeft :
            defaultOrientation = UIDeviceOrientation.landscapeRight
            break
        case UIInterfaceOrientation.landscapeRight :
            defaultOrientation = UIDeviceOrientation.landscapeLeft
            break
        case UIInterfaceOrientation.portraitUpsideDown :
            defaultOrientation = UIDeviceOrientation.portraitUpsideDown
            break
        case UIInterfaceOrientation.portrait :
            break
        default:
            defaultOrientation = UIDeviceOrientation.portrait
            break
        }
        return defaultOrientation
    }
    
    // ===========================================================================
    // MARK:- Camera setup
    // ===========================================================================
    private func cleanUpVideoProcessing() -> Void
    {
        if videoDataOutput != nil
        {
            session?.removeOutput(videoDataOutput!)
        }
        videoDataOutput = nil
    }
    
    private func setupVideoProcessing() -> Void
    {
        videoDataOutput = AVCaptureVideoDataOutput()
        let rgbOutputSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoDataOutput?.videoSettings = rgbOutputSettings
        
        if !(session?.canAddOutput(videoDataOutput!))!
        {
            cleanUpVideoProcessing()
            print("Failed to setup video output")
            return
        }
        
        if !(session?.canAddOutput(stillImageOutput))!
        {
            cleanUpVideoProcessing()
            print("Failed to setup video output")
            return
        }
        
        videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        videoDataOutput?.alwaysDiscardsLateVideoFrames = true
        videoDataOutput?.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        session?.addOutput(videoDataOutput!)
        session?.addOutput(stillImageOutput)
    }
    
    private func setupCameraPreview() -> Void
    {
        previewLayer = AVCaptureVideoPreviewLayer(session: session!)
        previewLayer?.backgroundColor = UIColor.white.cgColor
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
        let rootLayer : CALayer = self.layer
        rootLayer.masksToBounds = true
        previewLayer?.frame = rootLayer.bounds
        rootLayer.addSublayer(previewLayer!)
    }
    
    private func cameraForPosition(for desiredPosition: AVCaptureDevice.Position) -> AVCaptureDeviceInput?
    {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        
        for device in devices.devices
        {
            if device.position == desiredPosition
            {
                let input = try? AVCaptureDeviceInput(device: device)
                if (session?.canAddInput(input!))!
                {
                    return input
                }
            }
        }
        
        return nil
    }
    
    private func updateCameraSelection() -> Void
    {
        session?.beginConfiguration()
        
        // Remove old inputs
        let oldInputs = session?.inputs
        
        for oldInput: AVCaptureInput in oldInputs!
        {
            session?.removeInput(oldInput)
        }
        
        let desiredPosition: AVCaptureDevice.Position = .front
        let input: AVCaptureDeviceInput? = cameraForPosition(for: desiredPosition)
        if input == nil
        {
            // Failed, restore old inputs
            for oldInput: AVCaptureInput? in oldInputs!
            {
                if let oldInput = oldInput
                {
                    session?.addInput(oldInput)
                }
            }
        }
        else
        {
            // Succeeded, set input and update connection states
            if let input = input
            {
                session?.addInput(input)
            }
        }
        session?.commitConfiguration()
    }
    
    // ===========================================================================
    // MARK:- AVCapturePhotoCaptureDelegate
    // ===========================================================================
    @available(iOS 11.0, *)
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?)
    {
        if let error = error
        {
            print(error.localizedDescription)
        }

        let imageData = photo.fileDataRepresentation()
        UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData!)!, nil, nil, nil)
        
        //Delegate here to get the selfie
        selfieDelegate?.faceVerified(controller: self, image: UIImage(data: imageData!)!)
    }
    
    @available(iOS 10.0, *) //Only available from 10.0 to 11.0
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?)
    {
        if let error = error
        {
            print(error.localizedDescription)
        }
        
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer)
        {
            UIImageWriteToSavedPhotosAlbum(UIImage(data: dataImage)!,nil, nil, nil)
            //Delegate here to get the selfie
            self.selfieDelegate?.faceVerified(controller: self, image: UIImage(data: dataImage)!)
        }

    }

    // ===========================================================================
    // MARK:- AVCaptureVideoDataOutputSampleBufferDelegate
    // ===========================================================================
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    {
        //         Establish the image orientation.
        let deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
        let orientation: GMVImageOrientation = GMVUtility.imageOrientation(from: deviceOrientation, with: AVCaptureDevice.Position.front, defaultDeviceOrientation: deviceOrientationFromInterfaceOrientation())
        let options = [GMVDetectorImageOrientation: orientation.rawValue]
        //         Detect features using GMVDetector.
        let faces : [GMVFaceFeature] = faceDetector?.features(in: sampleBuffer, options: options) as! [GMVFaceFeature]
        
        print(String(format: "Detected %lu face(s).", faces.count))
        
        for face in faces
        {
            // Tracking id.
            if face.hasTrackingID
            {
                //get faceId
                if flagFaceId == false
                {
                    faceId = face.trackingID
                    flagFaceId = true
                }
                
                //reset flag if faceId changed
                if flagFaceId == true && face.trackingID > faceId
                {
                    resetFlag()
                }
            }
            
            // Tracking face.
            let faceY = face.headEulerAngleY
            
            //Detect front face
            if flagFrontFace == false
            {
                if CGFloat(faceY) > -12 && CGFloat(faceY) < 12
                {
                    selfieDelegate?.ssRealTimeSelfieCaptureDidDetectedFaceDirection(controller: self, directionType: .didDetectedFrontFace)
                    sleep(2)
                    flagFrontFace = true
                    return
                }
            }
            
            //If front face detected, then detect left face and then right face
            if flagFrontFace == true
            {
                //Detect left face
                if flagFaceLeft == false
                {
                    if CGFloat(faceY) > 36
                    {
                        selfieDelegate?.ssRealTimeSelfieCaptureDidDetectedFaceDirection(controller: self, directionType: .didDetectedLeftFace)
                        sleep(2)
                        flagFaceLeft = true
                        return
                    }
                }
                
                //Detect right face
                if flagFaceLeft == true
                {
                    if flagFaceRight == false
                    {
                        if CGFloat(faceY) < -36
                        {
                            selfieDelegate?.ssRealTimeSelfieCaptureDidDetectedFaceDirection(controller: self, directionType: .didDetectedRightFace)
                            sleep(2)
                            flagFaceRight = true
                            return
                        }
                    }
                }
            }
            
            //Detect smile
            if flagFaceLeft == true && flagFaceRight == true
            {
                if flagSmile == false
                {
                    if face.hasSmilingProbability
                    {
                        if CGFloat(face.smilingProbability) > 0.6
                        {
                            selfieDelegate?.ssRealTimeSelfieCaptureDidDetectedFaceDirection(controller: self, directionType: .didDetectedSmileFace)
                            sleep(2)
                            flagSmile = true
                            return
                        }
                    }
                }
            }
            
            //Selfie
            if(flagSmile == true && flagCapture == false)
            {
                capturePhoto()
                flagCapture = true
                return
            }
            
        }
    }

}
