//
//  Copyright (c) 2018 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AVFoundation
import CoreVideo
//import MLImage
//import MLKit
import Vision
import CoreImage
import MediaPipeTasksVision

typealias handSide = String

protocol InferenceResultDeliveryDelegate: AnyObject {
  func didPerformInference(result: ResultHandBundle?)
    func didPerformFaceInference(result: ResultFaceBundle?)

}

protocol InterfaceUpdatesDelegate: AnyObject {
  func shouldClicksBeEnabled(_ isEnabled: Bool)
}
@objc(CameraViewController)
class CameraViewController: UIViewController {
    
    var onPhotoCaptured: ((UIImage, handSide?) -> Void)?
    var cameraModel: CameraModel?

    private var documentDetected = false
    private var isDocumentProcessing = false

    private var consecutiveFrameDetectionCount = 0
    private let requiredDetectionFrames = 10  // Adjust as needed for reliable detection

    private var cropRect: CGRect = CGRect.zero
    private var viewWidth: CGFloat = 0
    private var viewHeight: CGFloat = 0

    private let documentDetectionOverlay = CAShapeLayer()

    private var isTapped = false
    
    private var maskLayer = CAShapeLayer()
    private let videoDataOutput = AVCaptureVideoDataOutput()

    private let detectors: [Detector] = [
        .onDeviceFace,
        .onDeviceText,
        .onDeviceTextChinese,
        .onDeviceTextDevanagari,
        .onDeviceTextJapanese,
        .onDeviceTextKorean,
        .onDeviceBarcode,
        .onDeviceImageLabel,
        .onDeviceImageLabelsCustom,
        .onDeviceObjectProminentNoClassifier,
        .onDeviceObjectProminentWithClassifier,
        .onDeviceObjectMultipleNoClassifier,
        .onDeviceObjectMultipleWithClassifier,
        .onDeviceObjectCustomProminentNoClassifier,
        .onDeviceObjectCustomProminentWithClassifier,
        .onDeviceObjectCustomMultipleNoClassifier,
        .onDeviceObjectCustomMultipleWithClassifier,
        .pose,
        .poseAccurate,
        .segmentationSelfie,
    ]
    
    
    private var currentDetector: Detector = .onDeviceFace
    private var isUsingFrontCamera = true
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private lazy var captureSession = AVCaptureSession()
    private lazy var sessionQueue = DispatchQueue(label: Constant.sessionQueueLabel)
    private var lastFrame: CMSampleBuffer?
    
    
//    /// Initialized when one of the pose detector rows are chosen. Reset to `nil` when neither are.
//    private var poseDetector: PoseDetector? = nil
//    
//    /// Initialized when a segmentation row is chosen. Reset to `nil` otherwise.
//    private var segmenter: Segmenter? = nil
    
    /// The detector mode with which detection was most recently run. Only used on the video output
    /// queue. Useful for inferring when to reset detector instances which use a conventional
    /// lifecyle paradigm.
    private var lastDetector: Detector?
    
    private lazy var cameraView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var previewOverlayView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var annotationOverlayView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var lastDocObservation:VNRectangleObservation?
    
    private let outputPhoto = AVCapturePhotoOutput()

    /////////=======================
 
    private let workQueue = DispatchQueue(label: "VisionRequest", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
   
    private var currentCameraIndex = 0

    
    /////////=======================
    ///
    
    private let faceDetectionQueue = DispatchQueue(label: "FaceDetectionQueue", qos: .userInitiated)
     private var isProcessingFrame = false // Prevent overlapping processing
    
    
    
    private let backgroundQueue = DispatchQueue(label: "com.google.mediapipe.cameraController.backgroundQueue")
    private let handLandmarkerServiceQueue = DispatchQueue(
      label: "com.google.mediapipe.cameraController.handLandmarkerServiceQueue",
      attributes: .concurrent)
    
    weak var inferenceResultDeliveryDelegate: InferenceResultDeliveryDelegate?
    weak var interfaceUpdatesDelegate: InterfaceUpdatesDelegate?
    
    // Queuing reads and writes to handLandmarkerService using the Apple recommended way
    // as they can be read and written from multiple threads and can result in race conditions.
    private var _handLandmarkerService: HandLandmarkerService?
    private var handLandmarkerService: HandLandmarkerService? {
      get {
        handLandmarkerServiceQueue.sync {
          return self._handLandmarkerService
        }
      }
      set {
        handLandmarkerServiceQueue.async(flags: .barrier) {
          self._handLandmarkerService = newValue
        }
      }
    }
    
    private let faceLandmarkerServiceQueue = DispatchQueue(
      label: "com.google.mediapipe.cameraController.faceLandmarkerServiceQueue",
      attributes: .concurrent)
    
    // Queuing reads and writes to faceLandmarkerService using the Apple recommended way
    // as they can be read and written from multiple threads and can result in race conditions.
    private var _faceLandmarkerService: FaceLandmarkerService?
    private var faceLandmarkerService: FaceLandmarkerService? {
      get {
        faceLandmarkerServiceQueue.sync {
          return self._faceLandmarkerService
        }
      }
      set {
        faceLandmarkerServiceQueue.async(flags: .barrier) {
          self._faceLandmarkerService = newValue
        }
      }
    }
    
    var handSide: String?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.consecutiveFrameDetectionCount = 0
        self.documentDetected = false
        isTapped = false
        if cameraModel?.captureType == .faceHand {
            currentDetector = .poseAccurate
        }else if cameraModel?.captureType == .hand{
            currentDetector = .onDeviceBarcode

        } else{
            currentDetector = .onDeviceFace
        }
        view.addSubview(cameraView)
        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        
        view.addSubview(previewOverlayView)
        view.addSubview(annotationOverlayView)
        
        setUpPreviewOverlayView()
        setUpAnnotationOverlayView()

        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        cameraView.layer.addSublayer(previewLayer)
        
        
        setUpCaptureSessionInput()
        
        setUpCaptureSessionOutput()

        if cameraModel?.captureType == .document{
            documentDetectionOverlay.strokeColor = UIColor.green.cgColor
            documentDetectionOverlay.lineWidth = 4
            documentDetectionOverlay.fillColor = UIColor.clear.cgColor
            view.layer.addSublayer(documentDetectionOverlay)
        }
        
        self.addTapGestureRecognizer()
        if cameraModel?.captureType == .hand || cameraModel?.captureType == .faceHand{
            
            clearAndInitializeHandLandmarkerService()
        }
        if cameraModel?.captureType == .face{
            clearAndInitializeFaceLandmarkerService()
            
        }
    }
    
    func addTapGestureRecognizer() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = cameraView.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopSession()
    }
    

    
    func switchCamera() {
        isUsingFrontCamera = !isUsingFrontCamera
        removeDetectionAnnotations()
        setUpCaptureSessionInput()
    }
 
  
    // MARK: - Private
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        if cameraModel?.captureType == .hand {
            settings.flashMode = .on
        } else {
            settings.flashMode = .off
        }
        outputPhoto.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func clearAndInitializeHandLandmarkerService() {
      handLandmarkerService = nil
      handLandmarkerService = HandLandmarkerService
        .liveStreamHandLandmarkerService(
          modelPath: InferenceConfigurationManager.sharedInstance.modelPath,
          numHands: InferenceConfigurationManager.sharedInstance.numHands,
          minHandDetectionConfidence: InferenceConfigurationManager.sharedInstance.minHandDetectionConfidence,
          minHandPresenceConfidence: InferenceConfigurationManager.sharedInstance.minHandPresenceConfidence,
          minTrackingConfidence: InferenceConfigurationManager.sharedInstance.minTrackingConfidence,
          liveStreamDelegate: self,
          delegate: InferenceConfigurationManager.sharedInstance.delegate)
    }
    
    @objc private func clearAndInitializeFaceLandmarkerService() {
      faceLandmarkerService = nil
      faceLandmarkerService = FaceLandmarkerService
        .liveStreamFaceLandmarkerService(
          modelPath: InferenceConfigurationManager.sharedInstance.modelFacePath,
          numFaces: InferenceConfigurationManager.sharedInstance.numFaces,
          minFaceDetectionConfidence: InferenceConfigurationManager.sharedInstance.minFaceDetectionConfidence,
          minFacePresenceConfidence: InferenceConfigurationManager.sharedInstance.minFacePresenceConfidence,
          minTrackingConfidence: InferenceConfigurationManager.sharedInstance.minTrackingConfidence,
          liveStreamDelegate: self,
          delegate: InferenceConfigurationManager.sharedInstance.facedelegate)
    }
    private func setUpCaptureSessionOutput() {
        self.consecutiveFrameDetectionCount = 0
        weak var weakSelf = self
        sessionQueue.async {
            guard let strongSelf = weakSelf else {
                print("Self is nil!")
                return
            }
         //   strongSelf.captureSession.beginConfiguration()
          //  if self.cameraModel?.captureType == .document{
                
                strongSelf.captureSession.sessionPreset = AVCaptureSession.Preset.high
//            }else{
//              //  strongSelf.captureSession.sessionPreset = AVCaptureSession.Preset.photo
//
//                strongSelf.captureSession.sessionPreset = AVCaptureSession.Preset.medium
//
//            }
            if strongSelf.captureSession.canAddOutput(strongSelf.outputPhoto) {
                strongSelf.captureSession.addOutput(strongSelf.outputPhoto)
            }
            
//            let output = AVCaptureVideoDataOutput()
//            output.videoSettings = [
//                (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
//            ]
//            output.alwaysDiscardsLateVideoFrames = true
//            let outputQueue = DispatchQueue(label: Constant.videoDataOutputQueueLabel)
//            output.setSampleBufferDelegate(strongSelf, queue: outputQueue)
//            
//            guard strongSelf.captureSession.canAddOutput(output) else {
//                print("Failed to add capture session output.")
//                return
//            }
//            strongSelf.captureSession.addOutput(output)
            
            strongSelf.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
            
            strongSelf.videoDataOutput.alwaysDiscardsLateVideoFrames = true
            strongSelf.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
            strongSelf.captureSession.addOutput(strongSelf.videoDataOutput)
            
            guard let connection = strongSelf.videoDataOutput.connection(with: AVMediaType.video),
                connection.isVideoOrientationSupported else { return }
            if self.cameraModel?.captureType != .face{
                connection.videoOrientation = .portrait
            }
            strongSelf.captureSession.commitConfiguration()
        }
    }

    
    private func setUpCaptureSessionInput() {
        
        weak var weakSelf = self
        sessionQueue.async {
            guard let strongSelf = weakSelf else {
                print("Self is nil!")
                return
            }
            if strongSelf.cameraModel?.captureType == .document || strongSelf.cameraModel?.captureType == .hand{
                strongSelf.isUsingFrontCamera = false
            }else{
                strongSelf.isUsingFrontCamera = true
            }
            let cameraPosition: AVCaptureDevice.Position = strongSelf.isUsingFrontCamera ? .front : .back
            guard let device = strongSelf.captureDevice(forPosition: cameraPosition) else {
                print("Failed to get capture device for camera position: \(cameraPosition)")
                return
            }
            
            
           // if self.cameraModel?.captureType == .document || self.cameraModel?.captureType == .face{
                do {
                    // Lock the device for configuration
                    try device.lockForConfiguration()
                    
                    
                    // Set highest resolution
//                    if let bestFormat = device.formats.max(by: { $0.highResolutionStillImageDimensions.width < $1.highResolutionStillImageDimensions.width }) {
//                        device.activeFormat = bestFormat
//                    }
                    
                    // Enable auto-focus
//                    if device.isFocusModeSupported(.autoFocus) {
//                        device.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
//                        device.focusMode = .autoFocus
//                    }
                    
                    // Enable auto-exposure
//                    if device.isExposureModeSupported(.autoExpose) {
//                        device.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
//                        device.exposureMode = .autoExpose
//                    }
//                    if self.cameraModel?.captureType == .face{
//                        
//                        let maxZoom = min(device.activeFormat.videoMaxZoomFactor, 0.5) // Ensure we don’t exceed limits
//                        device.videoZoomFactor = maxZoom
//                    }
                    
                                        // Enable autofocus (continuous focus mode)
                                        if device.isFocusModeSupported(.continuousAutoFocus) {
                                           // device.focusPointOfInterest =  CGPoint(x: 0.5, y: 0.5)
                                            device.focusMode = .continuousAutoFocus
                                        }
                    
                    //                    // Enable auto exposure (important for document capture)
                    ////                    if device.isExposureModeSupported(.autoExpose) {
                    ////                        device.exposureMode = .autoExpose
                    ////                    }
                    //
                    //                    // Convert the CGPoint to a normalized point within the camera's preview layer
                    //                    let focusPoint = CGPoint(x: UIScreen.main.bounds.midX ,
                    //                                             y: UIScreen.main.bounds.midY)
                    //
                    //                    // Set focus point of interest
                    ////                    if device.isFocusPointOfInterestSupported {
                    ////                        device.focusPointOfInterest = focusPoint
                    ////                        device.focusMode = .autoFocus  // Use autoFocus or continuousAutoFocus
                    ////                    }
                    
                    // Unlock the device after configuration
                    device.unlockForConfiguration()
                } catch {
                    print("Error configuring the camera: \(error)")
                }
         //   }
            do {
//                if self.cameraModel?.captureType != .document{
                     strongSelf.captureSession.beginConfiguration()
//                }
                let currentInputs = strongSelf.captureSession.inputs
                for input in currentInputs {
                    strongSelf.captureSession.removeInput(input)
                }
                
                let input = try AVCaptureDeviceInput(device: device)
                guard strongSelf.captureSession.canAddInput(input) else {
                    print("Failed to add capture session input.")
                    return
                }
                strongSelf.captureSession.addInput(input)
//                if self.cameraModel?.captureType != .document{
//                      strongSelf.captureSession.commitConfiguration()
//                }
            } catch {
                print("Failed to create capture device input: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func handleTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        
    //    self.switchToNextCamera()
        // Get the tap location in the view's coordinate system
        let tapPoint = gestureRecognizer.location(in: self.view)
        
        // Convert the tap location to normalized coordinates for the camera
        let focusPoint = CGPoint(x: tapPoint.x / self.previewLayer.bounds.size.width,
                                 y: tapPoint.y / self.previewLayer.bounds.size.height)
        
        // Set focus at the tap point
        setFocus(at: focusPoint)
    }
    
    func resetFocus() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            try captureDevice.lockForConfiguration()
            
            // Reset the focus mode and set to continuous autofocus
            captureDevice.focusMode = .autoFocus
            
            // Unlock for configuration
            captureDevice.unlockForConfiguration()
        } catch {
            print("Error resetting focus: \(error)")
        }
    }
    
    func setFocus(at point: CGPoint) {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            try captureDevice.lockForConfiguration()
            
            // Set the focus point of interest to the tap location
            if captureDevice.isFocusPointOfInterestSupported {
                captureDevice.focusPointOfInterest = point
                captureDevice.focusMode = .autoFocus  // Auto-focus mode
            }
            
            captureDevice.unlockForConfiguration()
        } catch {
            print("Error setting focus point: \(error)")
        }
    }

    private func startSession() {
        weak var weakSelf = self
        sessionQueue.async {
            guard let strongSelf = weakSelf else {
                print("Self is nil!")
                return
            }
            strongSelf.captureSession.startRunning()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                strongSelf.configureTorchIfNeeded()
            }
        }
    }
    
    private func configureTorchIfNeeded() {
//        guard let device = captureDevice(forPosition: .back),
//              device.hasTorch,
//              cameraModel?.captureType == .hand else {
//            return
//        }
//
//        do {
//            try device.lockForConfiguration()
//            if device.isTorchModeSupported(.on) {
//                try device.setTorchModeOn(level: 1.0)
//            }
//            device.unlockForConfiguration()
//        } catch {
//            print("Torch configuration error: \(error)")
//        }
    }
    
    private func stopSession() {
        weak var weakSelf = self
        sessionQueue.async {
            guard let strongSelf = weakSelf else {
                print("Self is nil!")
                return
            }
            strongSelf.captureSession.stopRunning()
        }
    }
   

    private func setUpPreviewOverlayView() {
        cameraView.addSubview(previewOverlayView)
        NSLayoutConstraint.activate([
            previewOverlayView.centerXAnchor.constraint(equalTo: cameraView.centerXAnchor),
            previewOverlayView.centerYAnchor.constraint(equalTo: cameraView.centerYAnchor),
            previewOverlayView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
            previewOverlayView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
            
        ])
    }
    
    private func setUpAnnotationOverlayView() {
        cameraView.addSubview(annotationOverlayView)
        NSLayoutConstraint.activate([
            annotationOverlayView.topAnchor.constraint(equalTo: cameraView.topAnchor),
            annotationOverlayView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
            annotationOverlayView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
            annotationOverlayView.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),
        ])
    }
    
    private func captureDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if #available(iOS 10.0, *) {
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [
                    .builtInTripleCamera,
                    .builtInDualCamera,
                    .builtInUltraWideCamera,
                    .builtInDualWideCamera,
                    .builtInWideAngleCamera,
                    .builtInTrueDepthCamera
                ],
                mediaType: .video,
                position: position
            )
            print(discoverySession.devices)
            return discoverySession.devices.first { $0.position == position }
        }
        return nil
    }

    private func removeDetectionAnnotations() {
        for annotationView in annotationOverlayView.subviews {
            annotationView.removeFromSuperview()
        }
    }
    
    private func updatePreviewOverlayViewWithLastFrame() {
        guard let lastFrame = lastFrame,
              let imageBuffer = CMSampleBufferGetImageBuffer(lastFrame)
        else {
            return
        }
        self.updatePreviewOverlayViewWithImageBuffer(imageBuffer)
        self.removeDetectionAnnotations()
    }
    
    private func updatePreviewOverlayViewWithImageBuffer(_ imageBuffer: CVImageBuffer?) {
        guard let imageBuffer = imageBuffer else {
            return
        }
        let orientation: UIImage.Orientation = isUsingFrontCamera ? .leftMirrored : .right
        let image = UIUtilities.createUIImage(from: imageBuffer, orientation: orientation)
        previewOverlayView.image = image
    }
    
    private func convertedPoints(
        from points: [NSValue]?,
        width: CGFloat,
        height: CGFloat
    ) -> [NSValue]? {
        return points?.map {
            let cgPointValue = $0.cgPointValue
            let normalizedPoint = CGPoint(x: cgPointValue.x / width, y: cgPointValue.y / height)
            let cgPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
            let value = NSValue(cgPoint: cgPoint)
            return value
        }
    }
    
    
    private func rotate(_ view: UIView, orientation: UIImage.Orientation) {
        var degree: CGFloat = 0.0
        switch orientation {
        case .up, .upMirrored:
            degree = 90.0
        case .rightMirrored, .left:
            degree = 180.0
        case .down, .downMirrored:
            degree = 270.0
        case .leftMirrored, .right:
            degree = 0.0
        }
        view.transform = CGAffineTransform.init(rotationAngle: degree * 3.141592654 / 180)
    }
}

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate ,AVCapturePhotoCaptureDelegate{
    private func initiateCaptureProcess() {
        // Start the capture process (e.g., take a photo or perform other actions)
        print("Document detected reliably. Initiating capture process...")
        // Add your capture logic here
        capturePhoto()
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        DispatchQueue.main.async {
            if let imag = UIImage(data: imageData),let img = self.rotateImage(image: imag, by: 0) {
                
                
                if self.cameraModel?.captureType == .document{
                    if let observation = self.lastDocObservation,var ciImage = CIImage(image: img){
                        
                        let topLeft = observation.topLeft.scaled(to: ciImage.extent.size)
                        let topRight = observation.topRight.scaled(to: ciImage.extent.size)
                        let bottomLeft = observation.bottomLeft.scaled(to: ciImage.extent.size)
                        let bottomRight = observation.bottomRight.scaled(to: ciImage.extent.size)
                        
                        // pass those to the filter to extract/rectify the image
                        ciImage = ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
                            "inputTopLeft": CIVector(cgPoint: CGPoint(x: topLeft.x - 20, y: topLeft.y + 20) ),
                            "inputTopRight": CIVector(cgPoint: CGPoint(x: topRight.x + 20, y: topRight.y + 20)),
                            "inputBottomLeft": CIVector(cgPoint: CGPoint(x: bottomLeft.x - 20, y: bottomLeft.y - 20) ),
                            "inputBottomRight": CIVector(cgPoint: CGPoint(x: bottomRight.x + 20, y: bottomRight.y - 20)),
                        ])
                        
                        let context = CIContext()
                        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
                        let output = UIImage(cgImage: cgImage!)
                        self.onPhotoCaptured?(output, nil)

                    }else{
                        self.documentDetected = false
                        self.consecutiveFrameDetectionCount -= 1
                    }
                }else{
                    self.onPhotoCaptured?(img, self.handSide)
                }
                
            }
        }
    }
    
    
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      print("Failed to get image buffer from sample buffer.")
      return
    }
    // Evaluate `self.currentDetector` once to ensure consistency throughout this method since it
    // can be concurrently modified from the main thread.
    let activeDetector = self.currentDetector

    lastFrame = sampleBuffer
    let orientation = UIUtilities.imageOrientation(
      fromDevicePosition: isUsingFrontCamera ? .front : .back
    )
    

    let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
    let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
    var shouldEnableClassification = false
    var shouldEnableMultipleObjects = false
    switch activeDetector {
    case .onDeviceObjectProminentWithClassifier, .onDeviceObjectMultipleWithClassifier,
      .onDeviceObjectCustomProminentWithClassifier, .onDeviceObjectCustomMultipleWithClassifier:
      shouldEnableClassification = true
    default:
      break
    }
    switch activeDetector {
    case .onDeviceObjectMultipleNoClassifier, .onDeviceObjectMultipleWithClassifier,
      .onDeviceObjectCustomMultipleNoClassifier, .onDeviceObjectCustomMultipleWithClassifier:
      shouldEnableMultipleObjects = true
    default:
      break
    }

    switch activeDetector {
    case .onDeviceBarcode:
        print("")
        let currentTimeMs = Date().timeIntervalSince1970 * 1000

        backgroundQueue.async { [weak self] in
          self?.handLandmarkerService?.detectAsync(
            sampleBuffer: sampleBuffer,
            orientation: orientation,
            timeStamps: Int(currentTimeMs))
        }
     // scanBarcodesOnDevice(in: visionImage, width: imageWidth, height: imageHeight)
    case .onDeviceFace:
        if cameraModel?.captureType == .document{
//            detectFacesOnDevice(in: visionImage, width: imageWidth, height: imageHeight)
            detectRectangle(in: imageBuffer,width: imageWidth, height: imageHeight)
            //detectDocument(in: imageBuffer,image:  visionImage, width: imageWidth, height: imageHeight)
        }else{
          //  detectfaces(in: sampleBuffer, orientation: orientation)
            
            let currentTimeMs = Date().timeIntervalSince1970 * 1000
            // Pass the pixel buffer to mediapipe
            backgroundQueue.async { [weak self] in
              self?.faceLandmarkerService?.detectAsync(
                sampleBuffer: sampleBuffer,
                orientation: orientation,
                timeStamps: Int(currentTimeMs))
            }
        }

    case .onDeviceText, .onDeviceTextChinese, .onDeviceTextDevanagari, .onDeviceTextJapanese,
      .onDeviceTextKorean:
        print("")
//      recognizeTextOnDevice(
//        in: visionImage, width: imageWidth, height: imageHeight, detectorType: activeDetector)
    case .onDeviceImageLabel:
        print("")

//      detectLabels(
//        in: visionImage, width: imageWidth, height: imageHeight, shouldUseCustomModel: false)
    case .onDeviceImageLabelsCustom:
        print("")

//      detectLabels(
//        in: visionImage, width: imageWidth, height: imageHeight, shouldUseCustomModel: true)
    case .onDeviceObjectProminentNoClassifier, .onDeviceObjectProminentWithClassifier,
      .onDeviceObjectMultipleNoClassifier, .onDeviceObjectMultipleWithClassifier:
        print("")

      // The `options.detectorMode` defaults to `.stream`
//      let options = ObjectDetectorOptions()
//      options.shouldEnableClassification = shouldEnableClassification
//      options.shouldEnableMultipleObjects = shouldEnableMultipleObjects
//      detectObjectsOnDevice(
//        in: visionImage,
//        width: imageWidth,
//        height: imageHeight,
//        options: options)
    case .onDeviceObjectCustomProminentNoClassifier, .onDeviceObjectCustomProminentWithClassifier,
      .onDeviceObjectCustomMultipleNoClassifier, .onDeviceObjectCustomMultipleWithClassifier:
        print("")

//      guard
//        let localModelFilePath = Bundle.main.path(
//          forResource: Constant.localModelFile.name,
//          ofType: Constant.localModelFile.type
//        )
//      else {
//        print("Failed to find custom local model file.")
//        return
//      }
//      let localModel = LocalModel(path: localModelFilePath)
//      // The `options.detectorMode` defaults to `.stream`
//      let options = CustomObjectDetectorOptions(localModel: localModel)
//      options.shouldEnableClassification = shouldEnableClassification
//      options.shouldEnableMultipleObjects = shouldEnableMultipleObjects
//      detectObjectsOnDevice(
//        in: visionImage,
//        width: imageWidth,
//        height: imageHeight,
//        options: options)

    case .pose, .poseAccurate:
        print("")
        detectfaces(in: sampleBuffer, orientation: orientation)

     // detectPose(in: inputImage, width: imageWidth, height: imageHeight)
    case .segmentationSelfie:
        print("")

     // detectSegmentationMask(in: visionImage, sampleBuffer: sampleBuffer)
    }
  }
    
    func detectfaces(in sampleBuffer:CMSampleBuffer,orientation:UIImage.Orientation)
    {
        guard !isProcessingFrame else { return } // Drop frame if busy
        
        isProcessingFrame = true
        
        faceDetectionQueue.async { [weak self] in
            guard let self = self else { return }
            defer { self.isProcessingFrame = false } // Reset flag after processing
            
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                print("Failed to get image buffer from sample buffer.")
                self.consecutiveFrameDetectionCount = 0
                
                return
            }
            
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let imageSize = CGSize(width: CVPixelBufferGetWidth(imageBuffer),
                                   height: CVPixelBufferGetHeight(imageBuffer))
            
            let request = VNDetectFaceLandmarksRequest { request, error in
                guard let results = request.results as? [VNFaceObservation], !results.isEmpty else {
                    print("No faces detected")
                    self.consecutiveFrameDetectionCount = 0
                    return
                }
                
                var bestFace: VNFaceObservation?
                var highestQuality = 0.0
                
                guard results.count == 1 else{
                    print("multiple faces detected")
                    self.consecutiveFrameDetectionCount = 0
                    
                    return
                }
                for face in results {
                    let faceBounds = self.convertBoundingBox(face.boundingBox, to: imageSize)
                    let faceQuality = self.estimateFaceQuality(ciImage, in: faceBounds)
                    let faceAngle = self.getFaceAngle(from: face)
                    
                    print("Face Quality: \(faceQuality), Yaw: \(faceAngle.yaw), Pitch: \(faceAngle.pitch), Roll: \(faceAngle.roll)")
                    
                    // Find the best face based on quality
                    if faceQuality > highestQuality {
                        highestQuality = faceQuality
                        bestFace = face
                    }
                }
                
                if let bestFace = bestFace ,highestQuality > 100.0{
                    
                    if self.cameraModel?.captureType == .faceHand{
                        let currentTimeMs = Date().timeIntervalSince1970 * 1000

                        self.backgroundQueue.async { [weak self] in
                          self?.handLandmarkerService?.detectAsync(
                            sampleBuffer: sampleBuffer,
                            orientation: orientation,
                            timeStamps: Int(currentTimeMs))
                        }
                    }else{
                        let bestFaceBounds = self.convertBoundingBox(bestFace.boundingBox, to: imageSize)
                        
                        if let croppedFace = self.cropFace(ciImage, to: bestFaceBounds) {
                            DispatchQueue.main.async {
                                let faceImage = UIImage(ciImage: croppedFace)
                                self.consecutiveFrameDetectionCount += 1
                                
                                // If the document has been detected for the required number of consecutive frames, initiate capture
                                if self.consecutiveFrameDetectionCount >= 20 {
                                    if !self.documentDetected {
                                        DispatchQueue.main.async {
                                            if  let faceImage = self.rotateImage(image: UIImage(ciImage: croppedFace), by: 90) {
                                                
                                                self.onPhotoCaptured?(faceImage, nil)
                                            }else{
                                                self.documentDetected = false
                                                
                                            }
                                            // Use faceImage (e.g., display, save, process further)
                                        }
                                        self.documentDetected = true
                                    }
                                } else {
                                    // If the document is detected but not for enough frames yet, don't initiate capture
                                    self.documentDetected = false
                                }
                                
                                // Use faceImage (e.g., display, save, process further)
                            }
                        }else{
                            self.consecutiveFrameDetectionCount = 0
                        }
                    }
                }else{
                    self.consecutiveFrameDetectionCount = 0
                }
            }
            
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            try? handler.perform([request])
        }
    }
    
    
    // Convert Vision bounding box to Core Image coordinates with 3:4 aspect ratio padding
    private func convertBoundingBox(_ boundingBox: CGRect, to imageSize: CGSize) -> CGRect {
        let width = boundingBox.width * imageSize.width
        let height = boundingBox.height * imageSize.height
        let x = boundingBox.minX * imageSize.width
        let y = (1 - boundingBox.maxY) * imageSize.height  // Flip Y-axis

        var rect = CGRect(x: x, y: y, width: width, height: height)

        // Add padding (e.g., 20% of the face size)

        rect = addPadding(rect, paddingRatio: 0.15, imageSize: imageSize)

        // Adjust to maintain a 3:4 aspect ratio
        rect = adjustToAspectRatio(rect, targetRatio: 4.0 / 3.0, imageSize: imageSize)
        
        return rect
    }

    // Ensure the bounding box maintains the 3:4 aspect ratio and stays within bounds
    private func adjustToAspectRatio(_ rect: CGRect, targetRatio: CGFloat, imageSize: CGSize) -> CGRect {
        var newWidth = rect.width
        var newHeight = rect.height
        
        let currentRatio = rect.width / rect.height

        if currentRatio > targetRatio {
            // Wider than 3:4 → Adjust height
            newHeight = rect.width / targetRatio
        } else {
            // Taller than 3:4 → Adjust width
            newWidth = rect.height * targetRatio
        }

        // Center the new bounding box
        let newX = max(0, min(rect.midX - newWidth / 2, imageSize.width - newWidth))
        let newY = max(0, min(rect.midY - newHeight / 2, imageSize.height - newHeight))

        return CGRect(x: newX, y: newY, width: newWidth, height: newHeight)
    }

    // Add padding while keeping the bounding box within the image bounds
    private func addPadding(_ rect: CGRect, paddingRatio: CGFloat, imageSize: CGSize) -> CGRect {
        let paddingWidth = rect.width * paddingRatio
        let paddingHeight = rect.height * paddingRatio
        
        var newRect = rect.insetBy(dx: -paddingWidth, dy: -paddingHeight)

        // Ensure the bounding box does not exceed image boundaries
        newRect.origin.x = max(0, newRect.origin.x)
        newRect.origin.y = max(0, newRect.origin.y)
        newRect.size.width = min(imageSize.width - newRect.origin.x, newRect.width)
        newRect.size.height = min(imageSize.height - newRect.origin.y, newRect.height)

        return newRect
    }
    // Crop the face region from the image
    private func cropFace(_ image: CIImage, to rect: CGRect) -> CIImage? {
        return image.cropped(to: rect)
    }

      
      // Estimate face quality using contrast heuristics
      private func estimateFaceQuality(_ image: CIImage, in rect: CGRect) -> Double {
          let croppedFace = image.cropped(to: rect)
          let filter = CIFilter(name: "CISharpenLuminance")!
          filter.setValue(croppedFace, forKey: kCIInputImageKey)
          filter.setValue(0.5, forKey: kCIInputSharpnessKey)
          
          let processedImage = filter.outputImage ?? croppedFace
          let context = CIContext()
          
          guard let cgImage = context.createCGImage(processedImage, from: processedImage.extent) else {
              return 0.0
          }
          
          let brightness = self.calculateImageSharpness(cgImage)
          return brightness
      }
      
      // Simple sharpness calculation by measuring contrast
      private func calculateImageSharpness(_ image: CGImage) -> Double {
          let width = image.width
          let height = image.height
          let bytesPerRow = width * 4
          let totalBytes = height * bytesPerRow
          let bitmapData = UnsafeMutablePointer<UInt8>.allocate(capacity: totalBytes)
          defer { bitmapData.deallocate() }
          
          let context = CGContext(
              data: bitmapData,
              width: width,
              height: height,
              bitsPerComponent: 8,
              bytesPerRow: bytesPerRow,
              space: CGColorSpaceCreateDeviceRGB(),
              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
          )
          
          guard let ctx = context else { return 0.0 }
          ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
          
          var totalLuminance: Double = 0
          for i in stride(from: 0, to: totalBytes, by: 4) {
              let r = Double(bitmapData[i])
              let g = Double(bitmapData[i + 1])
              let b = Double(bitmapData[i + 2])
              let luminance = (0.2126 * r + 0.7152 * g + 0.0722 * b)
              totalLuminance += luminance
          }
          
          return totalLuminance / Double(width * height)
      }
      
      // Get face angles (yaw, pitch, roll)
      private func getFaceAngle(from face: VNFaceObservation) -> (yaw: Double, pitch: Double, roll: Double) {
          let yaw = face.yaw?.doubleValue ?? 0.0
          let pitch = face.pitch?.doubleValue ?? 0.0
          let roll = face.roll?.doubleValue ?? 0.0
          return (yaw, pitch, roll)
      }
//    // Convert Vision bounding box to Core Image coordinates
//       private func convertBoundingBox(_ boundingBox: CGRect, to imageSize: CGSize) -> CGRect {
//           let width = boundingBox.width * imageSize.width
//           let height = boundingBox.height * imageSize.height
//           let x = boundingBox.minX * imageSize.width
//           let y = (1 - boundingBox.maxY) * imageSize.height  // Flip Y-axis
//           return CGRect(x: x - 100, y: y - 50, width: width + 100, height: height + 100)
//       }
//       
//       // Crop the face region from the image
//       private func cropFace(_ image: CIImage, to rect: CGRect) -> CIImage? {
//           
//           return image.cropped(to: rect)
//       }
}

// MARK: - Constants

public enum Detector: String {
  case onDeviceBarcode = "Barcode Scanning"
  case onDeviceFace = "Face Detection"
  case onDeviceText = "Text Recognition"
  case onDeviceTextChinese = "Text Recognition Chinese"
  case onDeviceTextDevanagari = "Text Recognition Devanagari"
  case onDeviceTextJapanese = "Text Recognition Japanese"
  case onDeviceTextKorean = "Text Recognition Korean"
  case onDeviceImageLabel = "Image Labeling"
  case onDeviceImageLabelsCustom = "Image Labeling Custom"
  case onDeviceObjectProminentNoClassifier = "ODT, single, no labeling"
  case onDeviceObjectProminentWithClassifier = "ODT, single, labeling"
  case onDeviceObjectMultipleNoClassifier = "ODT, multiple, no labeling"
  case onDeviceObjectMultipleWithClassifier = "ODT, multiple, labeling"
  case onDeviceObjectCustomProminentNoClassifier = "ODT, custom, single, no labeling"
  case onDeviceObjectCustomProminentWithClassifier = "ODT, custom, single, labeling"
  case onDeviceObjectCustomMultipleNoClassifier = "ODT, custom, multiple, no labeling"
  case onDeviceObjectCustomMultipleWithClassifier = "ODT, custom, multiple, labeling"
  case pose = "Pose Detection"
  case poseAccurate = "Pose Detection, accurate"
  case segmentationSelfie = "Selfie Segmentation"
}

private enum Constant {
  static let alertControllerTitle = "Vision Detectors"
  static let alertControllerMessage = "Select a detector"
  static let cancelActionTitleText = "Cancel"
  static let videoDataOutputQueueLabel = "com.google.mlkit.visiondetector.VideoDataOutputQueue"
  static let sessionQueueLabel = "com.google.mlkit.visiondetector.SessionQueue"
  static let noResultsMessage = "No Results"
  static let localModelFile = (name: "bird", type: "tflite")
  static let labelConfidenceThreshold = 0.75
  static let smallDotRadius: CGFloat = 4.0
  static let lineWidth: CGFloat = 3.0
  static let originalScale: CGFloat = 1.0
  static let padding: CGFloat = 10.0
  static let resultsLabelHeight: CGFloat = 200.0
  static let resultsLabelLines = 5
  static let imageLabelResultFrameX = 0.4
  static let imageLabelResultFrameY = 0.1
  static let imageLabelResultFrameWidth = 0.5
  static let imageLabelResultFrameHeight = 0.8
  static let segmentationMaskAlpha: CGFloat = 0.5
}


extension CameraViewController{
    
    private func detectRectangle(in image: CVPixelBuffer, width: CGFloat, height: CGFloat) {

        let request = VNDetectRectanglesRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                
                guard let results = request.results as? [VNRectangleObservation] else {
                    print("No valid document detected")
                    self.consecutiveFrameDetectionCount = 0
                    self.documentDetected = false
                    return
                }
                guard let observation = results.first else{
                   
                    return
                }
                
                self.removeMask()
                let confidenceThreshold: Float = 0.8
                if observation.confidence < confidenceThreshold {
                    print("Document detected but confidence too low: \(observation.confidence)")
                    self.consecutiveFrameDetectionCount = 0
                    self.documentDetected = false
                    return
                }
                
                // Check aspect ratio (expected to be close to standard paper sizes)
                let width = observation.boundingBox.width
                let height = observation.boundingBox.height
                let aspectRatio = width / height
                if aspectRatio < 0.5 || aspectRatio > 3.5 {  // Example: Reject overly wide/tall shapes
                    print("Document aspect ratio out of expected range: \(aspectRatio)")
                    self.consecutiveFrameDetectionCount = 0
                    self.documentDetected = false
                    return
                }
                
                // Check if document is mostly upright (not tilted too much)
                let angleThreshold: CGFloat = 15.0  // Allow some tilt, but not extreme
                let topLeft = observation.topLeft
                let topRight = observation.topRight
                let bottomLeft = observation.bottomLeft
                let bottomRight = observation.bottomRight
                
                let topEdgeAngle = self.angleBetweenPoints(p1: topLeft, p2: topRight)
                let leftEdgeAngle = self.angleBetweenPoints(p1: topLeft, p2: bottomLeft)
                
                if abs(topEdgeAngle) > angleThreshold || (abs(leftEdgeAngle) - 90) > angleThreshold {
                    print("Document is tilted too much: \(topEdgeAngle)° (top), \(leftEdgeAngle)° (left)")
                    self.consecutiveFrameDetectionCount = 0
                    self.documentDetected = false
                    return
                }
                print("Document is tilted too much: \(topEdgeAngle)° (top), \(leftEdgeAngle)° (left)")

               // print("Document is well placed and ready for capture!")
                self.drawBoundingBox(rect: observation)
                
                self.doPerspectiveCorrection(observation, from: image)
                
            }
        })
        
        request.minimumAspectRatio = 0.5
            request.maximumAspectRatio = 2.0
            request.minimumConfidence = 0.8
            request.quadratureTolerance = 15.0

        
//        request.minimumAspectRatio = VNAspectRatio(1.1)
//        request.maximumAspectRatio = VNAspectRatio(1.7)
        request.minimumSize = Float(0.4)
        request.maximumObservations = 1

        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        try? imageRequestHandler.perform([request])
    }
    
    // Helper function to calculate angle between two points
    func angleBetweenPoints(p1: CGPoint, p2: CGPoint) -> CGFloat {
        let deltaY = p2.y - p1.y
        let deltaX = p2.x - p1.x
        return atan2(deltaY, deltaX) * 180 / .pi  // Convert to degrees
    }
    
    func drawBoundingBox(rect : VNRectangleObservation) {
    
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -self.previewLayer.frame.height)
        let scale = CGAffineTransform.identity.scaledBy(x: self.previewLayer.frame.width, y: self.previewLayer.frame.height)

        let bounds = rect.boundingBox.applying(scale).applying(transform)
        createLayer(in: bounds)

    }
    
    private func createLayer(in rect: CGRect) {

        maskLayer = CAShapeLayer()
        maskLayer.frame = rect
        maskLayer.cornerRadius = 10
        maskLayer.opacity = 0.75
        maskLayer.borderColor = UIColor.yellow.cgColor
        maskLayer.borderWidth = 2.0
        
        previewLayer.insertSublayer(maskLayer, at: 1)

    }
    
    func removeMask() {
            maskLayer.removeFromSuperlayer()

    }
    func getVideoOrientation() -> AVCaptureVideoOrientation {
        // Use the current device orientation or AVCaptureSession orientation
        if let connection = previewLayer.connection {
            return connection.videoOrientation
        }
        
        // Fallback to device orientation if previewLayer connection is nil
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }

    }

   
     
    func doPerspectiveCorrection(_ observation: VNRectangleObservation, from buffer: CVImageBuffer) {
        var ciImage = CIImage(cvImageBuffer: buffer)

        let topLeft = observation.topLeft.scaled(to: ciImage.extent.size)
        let topRight = observation.topRight.scaled(to: ciImage.extent.size)
        let bottomLeft = observation.bottomLeft.scaled(to: ciImage.extent.size)
        let bottomRight = observation.bottomRight.scaled(to: ciImage.extent.size)

        // pass those to the filter to extract/rectify the image
        ciImage = ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: CGPoint(x: topLeft.x - 20, y: topLeft.y + 20) ),
            "inputTopRight": CIVector(cgPoint: CGPoint(x: topRight.x + 20, y: topRight.y + 20)),
            "inputBottomLeft": CIVector(cgPoint: CGPoint(x: bottomLeft.x - 20, y: bottomLeft.y - 20) ),
            "inputBottomRight": CIVector(cgPoint: CGPoint(x: bottomRight.x + 20, y: bottomRight.y - 20)),
        ])

        let context = CIContext()
        let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        let output = UIImage(cgImage: cgImage!)
      //  if isImageBlurredLegacy(ciImage){
            if let cgImage = cgImage{
                self.lastDocObservation = observation
                workQueue.async {
                    
                    let request = VNDetectFaceCaptureQualityRequest()
                    
                    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    do{
                        try requestHandler.perform([request])
                        if let faceObservation = request.results?.first as? VNFaceObservation{
                            if let faceCaptureQuality = faceObservation.faceCaptureQuality{
                                
                                if faceCaptureQuality > 0.1{
                                    if self.cameraModel?.captureType == .document{
                                        self.isDocumentProcessing = false
                                      //  print(self.consecutiveFrameDetectionCount)

                                        self.consecutiveFrameDetectionCount += 1
                                        
                                        // If the document has been detected for the required number of consecutive frames, initiate capture
                                        if self.consecutiveFrameDetectionCount >= self.requiredDetectionFrames {
                                            if !self.documentDetected {

                                                self.documentDetected = true

                                                self.initiateCaptureProcess()
                                            }
                                        } else {
//                                            self.consecutiveFrameDetectionCount = 0
//                                            self.documentDetected = false
                                        }
                                    }
                                    
                                }else{
                                    print("Document face quality is low!")
                                    self.consecutiveFrameDetectionCount = 0
                                    self.documentDetected = false
                                }
                            }
                        }
                        
                    }catch(let error){
                        print(error.localizedDescription)
//                        self.consecutiveFrameDetectionCount = 0
//                        self.documentDetected = false
                    }
                    
                }
            }
      //  }
        //UIImageWriteToSavedPhotosAlbum(output, nil, nil, nil)
        
//        let secondVC = TextExtractorVC()
//        secondVC.scannedImage = output
   //     self.navigationController?.pushViewController(secondVC, animated: false)
        
    }
    // for ios 15 and later

    func isImageBlurred(_ image: CIImage) -> Bool {
        
        let filter = CIFilter(name: "CIVarianceOfLaplacian")!
        filter.setValue(image, forKey: kCIInputImageKey)

        guard let outputImage = filter.outputImage else { return false }
        
        // Get variance value
        var variance: Float = 0
        let context = CIContext()
        context.render(outputImage, toBitmap: &variance, rowBytes: MemoryLayout<Float>.size, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .Rf, colorSpace: nil)
        
        print("Sharpness Variance: \(variance)")

        return variance < 10.0  // Adjust threshold based on testing
    }
   // for ios 14 and earlier
    func isImageBlurredLegacy(_ image: CIImage) -> Bool {
        
        let filter = CIFilter(name: "CIEdges")! // Edge detection filter
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(5.0, forKey: kCIInputIntensityKey) // Adjust edge detection strength

        guard let outputImage = filter.outputImage else { return false }
        
        let context = CIContext()
        let histogram = CIFilter(name: "CIAreaHistogram", parameters: [
            kCIInputImageKey: outputImage,
            "inputCount": 256
        ])!

        guard let histogramOutput = histogram.outputImage else { return false }
        
        // Analyze brightness to estimate sharpness
        var brightness: Float = 0
        context.render(histogramOutput, toBitmap: &brightness, rowBytes: MemoryLayout<Float>.size, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .Rf, colorSpace: nil)
        
        print("Brightness Variance: \(brightness)")

        return brightness < 0.9 // Adjust based on testing
    }

  

    // Helper method to rotate a UIImage
    private func rotateImage(image: UIImage, by degrees: CGFloat) -> UIImage? {
        let radians = degrees * .pi / 180
        var newSize = image.size
        if degrees == 90 || degrees == 270 {
            newSize = CGSize(width: image.size.height, height: image.size.width)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move the origin to the center of the image
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        
        // Rotate the image context
        context.rotate(by: radians)
        
        // Draw the image at the center
        image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))
        
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotatedImage
    }
    

    private func cropUIImage(image: UIImage, cropRect: CGRect) -> UIImage? {
        // Ensure the cropRect is within the bounds of the image
        
        let imageWidth = image.size.width
        let imageHeight = image.size.height
     
        // Convert the cropRect from view coordinates to pixel buffer coordinates
        let scaleX = CGFloat(imageWidth) / self.viewWidth
        let scaleY = CGFloat(imageHeight) / self.viewHeight
        
        let cropRectInPixelBuffer = CGRect(
            x: cropRect.origin.x ,
            y: imageHeight / 4,
            width: imageWidth - cropRect.origin.x,
            height: imageHeight / 2
        )
        // Clip the rect to the image bounds
        let clippedRect = cropRectInPixelBuffer.intersection(CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        
        // Get the CGImage of the UIImage
        guard let cgImage = image.cgImage?.cropping(to: clippedRect) else {
            self.consecutiveFrameDetectionCount = 0
            self.documentDetected = false
            return nil
        }
        
        // Create a new UIImage from the cropped CGImage
        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        
        return croppedImage
    }


    private func captureImage() {
        let photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            let settings = AVCapturePhotoSettings()
            if #available(iOS 18.0, *) {
                settings.isShutterSoundSuppressionEnabled = true
            } else {
                // Fallback on earlier versions
            }
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}


extension CGPoint {
   func scaled(to size: CGSize) -> CGPoint {
       return CGPoint(x: self.x * size.width,
                      y: self.y * size.height)
   }
}

extension CameraViewController:HandLandmarkerServiceLiveStreamDelegate,FaceLandmarkerServiceLiveStreamDelegate{
    
    func faceLandmarkerService(_ faceLandmarkerService: FaceLandmarkerService, didFinishDetection result: ResultFaceBundle?, error: (any Error)?) {
        let workItem = DispatchWorkItem { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.inferenceResultDeliveryDelegate?.didPerformFaceInference(result: result)
            guard let faceLandmarkerResult = result?.faceLandmarkerResults.first as? FaceLandmarkerResult else { return }
            if FaceAnalyzer.isValidFace(faceLandmarkerResult: faceLandmarkerResult) {
                print("Face is valid: Open eyes, neutral expression, and straight to camera")
                self?.isDocumentProcessing = false
                
                self?.consecutiveFrameDetectionCount += 1
                
                // If the document has been detected for the required number of consecutive frames, initiate capture
                if self?.consecutiveFrameDetectionCount ?? 0 >= 20 {
                    if !(self?.documentDetected ?? false) {
                        self?.documentDetected = true
                        
                        if let landmarks = faceLandmarkerResult.faceLandmarks.first {
                            let imageWidth: CGFloat = 640 // Image width (example)
                            let imageHeight: CGFloat = 480 // Image height (example)
                            
                            // Get the bounding box with padding and 4:3 aspect ratio
                            if let lastFrame = self?.lastFrame{
                                if let croppedFace = FaceAnalyzer.cropFaceFromSampleBuffer(sampleBuffer: lastFrame, landmarks: landmarks, padding: 0.7){
                                    
                                    if let croppedFace = self?.rotateImage(image: croppedFace, by: 90) {
                                        // Use croppedFace here
                                        self?.onPhotoCaptured?(croppedFace, nil)
                                        
                                    }
                                }
                            }
                            
                        }

                       // self?.initiateCaptureProcess()  // Start the capture process when document is reliably detected
                    }
                } else {
                    // If the document is detected but not for enough frames yet, don't initiate capture
                    self?.documentDetected = false
                }

            } else {
                print("Invalid face detected")
                self?.consecutiveFrameDetectionCount = 0
                self?.documentDetected = false
            }
        }
        
        DispatchQueue.main.async(execute: workItem)

    }
    
    
    
    
    func handLandmarkerService(_ handLandmarkerService: HandLandmarkerService, didFinishDetection result: ResultHandBundle?, error: (any Error)?) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.inferenceResultDeliveryDelegate?.didPerformInference(result: result)
            guard let handLandmarkerResult = result?.handLandmarkerResults.first as? HandLandmarkerResult else { return }
            print(handLandmarkerResult.handedness.first?.first?.categoryName)
            if let firt = handLandmarkerResult.landmarks.first,
               let side = handLandmarkerResult.handedness.first?.first?.categoryName {
                if self?.isPalmOpenAndFacingCamera(landmarks: firt, isLeft: side == "Left") ?? false {
                    self?.handSide = side
                    print("Palm is open and facing the camera!")
                    
                    self?.isDocumentProcessing = false
                    
                    self?.consecutiveFrameDetectionCount += 1
                    
                    // If the document has been detected for the required number of consecutive frames, initiate capture
                    if self?.consecutiveFrameDetectionCount ?? 0 >= 5 {
                        if !(self?.documentDetected ?? false) {
                            self?.documentDetected = true
                            self?.initiateCaptureProcess()  // Start the capture process when document is reliably detected
                        }
                    } else {
                        // If the document is detected but not for enough frames yet, don't initiate capture
                        self?.documentDetected = false
                    }
                } else {
                    self?.consecutiveFrameDetectionCount = 0
                    self?.documentDetected = false

                    print("Hand is not fully open or not facing the camera.")
                }
            }else{
                self?.consecutiveFrameDetectionCount = 0
                self?.documentDetected = false
                print("No hand.")

            }
        }
    }
    
    // GPT
    func isLeftPalmOpenAndFacingCamera(
        landmarks: [NormalizedLandmark],
        isLeft: Bool
    ) -> Bool {
        guard landmarks.count == 21 else { return false } // Ensure we have all landmarks
        
        // 1. Check if palm is facing camera (z-depth)
        let isPalmer = landmarks[20].x > landmarks[16].x &&
        landmarks[16].x > landmarks[12].x &&
        landmarks[12].x > landmarks[8].x &&
        landmarks[8].x > landmarks[4].x &&
        (landmarks[17].z - landmarks[1].z) < 0.08
        print("Z difference ", landmarks[17].z - landmarks[1].z )
        guard isPalmer else {
            print("dolser view \(landmarks[20].x) \(landmarks[4].x)")
            return false
        }
        
        // 2. Setup finger tip and joint landmarks
        let wrist = landmarks[0]
        let fingerTips = [landmarks[4], landmarks[8], landmarks[12], landmarks[16], landmarks[20]]
        let pipJoints = [landmarks[3], landmarks[7], landmarks[11], landmarks[15], landmarks[19]]
        let dipJoints = [landmarks[2], landmarks[6], landmarks[10], landmarks[14], landmarks[18]]
        let mcpJoints = [landmarks[1], landmarks[5], landmarks[9], landmarks[13], landmarks[17]]
    
#if DEBUG
        print("First: \n \(landmarks[5].y) , \(landmarks[6].y) , \(landmarks[7].y) , \( landmarks[8].y)")
        print("Second: \n \(landmarks[9].y) , \(landmarks[10].y) , \(landmarks[11].y) , \( landmarks[12].y)")
        print("Third: \n \(landmarks[13].y) , \(landmarks[14].y) , \(landmarks[15].y) , \( landmarks[16].y)")
        print("forth: \n \(landmarks[17].y) , \(landmarks[18].y) , \(landmarks[19].y) , \( landmarks[20].y)")
        print("Fifth: \n \(landmarks[1].y) , \(landmarks[2].y) , \(landmarks[3].y) , \( landmarks[4].y)")
#endif
        // 3. Check if each finger is open and extended
        for (index, tip) in fingerTips.enumerated() {
            let pip = pipJoints[index]
            let dip = dipJoints[index]
            let mcp = mcpJoints[index]
            
            // Simple check: tip should be farther from the wrist along the Y axis (in camera space)
            // Depending on hand orientation, you might need to adjust comparisons
            let isFingerOpen = tip.y < pip.y && pip.y < mcp.y
            if !isFingerOpen {
                print("fingers not open")
                return false
            }
            
            // Also optionally check Z distance if needed (tip closer to camera)
            let avgZ = fingerTips.map { $0.z }.reduce(0, +) / Float(fingerTips.count)
            //        print("=============")
                    let wristZ = wrist.z
                    let isFingerFacingCamera = abs(avgZ - wristZ) < 0.1
//            let isFingerFacingCamera = tip.z < pip.z && pip.z < mcp.z
            if !isFingerFacingCamera {
                print("hand not facing camera")
                return false
            }
            
        }
        
        // 4. Check if all landmarks are inside the view frame
        let pointsToCheck = fingerTips + [wrist]
        for landmark in pointsToCheck {
            let x = CGFloat(landmark.x) * self.previewLayer.frame.width
            let y = CGFloat(landmark.y) * self.previewLayer.frame.height
            if !previewLayer.frame.contains(CGPoint(x: x, y: y)) {
                print("not in frame")
                return false
            }
        }
        
        
        return true
    }
    
    func isRightPalmOpenAndFacingCamera(
        landmarks: [NormalizedLandmark],
        isLeft: Bool = false
    ) -> Bool {
        guard landmarks.count == 21 else { return false } // Ensure we have all landmarks

        // 1. Check if palm is facing camera (z-depth)
        // Flip x comparison for right hand
        let isPalmer = landmarks[20].x < landmarks[16].x &&
        landmarks[16].x < landmarks[12].x &&
        landmarks[12].x < landmarks[8].x &&
        landmarks[8].x < landmarks[4].x &&
        (landmarks[17].z - landmarks[1].z) < 0.08
        print("Z difference ", landmarks[17].z - landmarks[1].z )
        guard isPalmer else {
            print("dorsal view \(landmarks[20].x) \(landmarks[4].x)")
            return false
        }

        // 2. Setup finger tip and joint landmarks
        let wrist = landmarks[0]
        let fingerTips = [landmarks[4], landmarks[8], landmarks[12], landmarks[16], landmarks[20]]
        let pipJoints = [landmarks[3], landmarks[7], landmarks[11], landmarks[15], landmarks[19]]
        let dipJoints = [landmarks[2], landmarks[6], landmarks[10], landmarks[14], landmarks[18]]
        let mcpJoints = [landmarks[1], landmarks[5], landmarks[9], landmarks[13], landmarks[17]]

        // 3. Check if each finger is open and extended
        for (index, tip) in fingerTips.enumerated() {
            let pip = pipJoints[index]
            let dip = dipJoints[index]
            let mcp = mcpJoints[index]

            // Finger extended: tip.y < pip.y < mcp.y
            let isFingerOpen = tip.y < pip.y && pip.y < mcp.y
            if !isFingerOpen {
                print("fingers not open")
                return false
            }

            // Optional Z check: finger tip shouldn't be too far from wrist in z-depth
            let avgZ = fingerTips.map { $0.z }.reduce(0, +) / Float(fingerTips.count)
            let wristZ = wrist.z
            let isFingerFacingCamera = abs(avgZ - wristZ) < 0.1
            if !isFingerFacingCamera {
                print("hand not facing camera")
                return false
            }
        }
        
        // 4. Check if all landmarks are inside the view frame
        let pointsToCheck = fingerTips + [wrist]
        for landmark in pointsToCheck {
            let x = CGFloat(landmark.x) * previewLayer.frame.width
            let y = CGFloat(landmark.y) * previewLayer.frame.height
            if !previewLayer.frame.contains(CGPoint(x: x, y: y)) {
                
                print("not in frame")
                return false
            }
        }

        return true
    }
   
    //old
    func isPalmOpenAndFacingCamera(landmarks: [NormalizedLandmark], isLeft: Bool) -> Bool {
        guard landmarks.count == 21 else { return false } // Ensure we have all landmarks
        
      
        
        let wrist = landmarks[0]
        let fingerTips = [landmarks[4], landmarks[8], landmarks[12], landmarks[16], landmarks[20]]
        let pipJoints = [landmarks[3], landmarks[7], landmarks[11], landmarks[15], landmarks[19]]
        let dipJoints = [landmarks[2], landmarks[6], landmarks[10], landmarks[14], landmarks[18]]
        let tipJoints = [landmarks[1], landmarks[5], landmarks[9], landmarks[13], landmarks[17]]
        
#if DEBUG
        let fingerNames = ["Thumb", "Index", "Middle", "Ring", "Pinky"]
        for (index, fingerName) in fingerNames.enumerated() {
               let tip = fingerTips[index]
               let pip = pipJoints[index]
               let dip = dipJoints[index]
               let mcp = tipJoints[index]
               
               print("\(fingerName) Finger:")
               print("  MCP  (Base)     - x: \(mcp.x), y: \(mcp.y), z: \(mcp.z)")
               print("  DIP  (Middle)   - x: \(dip.x), y: \(dip.y), z: \(dip.z)")
               print("  PIP  (Near Tip) - x: \(pip.x), y: \(pip.y), z: \(pip.z)")
               print("  Tip  (Fingertip)- x: \(tip.x), y: \(tip.y), z: \(tip.z)")
               print("----------------------------")
           }
        // Optionally, also print wrist:
            print("Wrist:")
            print("  x: \(wrist.x), y: \(wrist.y), z: \(wrist.z)")
#endif
        
        if isLeft {
            return isLeftPalmOpenAndFacingCamera(landmarks: landmarks, isLeft: isLeft)
        } else {
            return isRightPalmOpenAndFacingCamera(landmarks: landmarks, isLeft: false)
        }
    }
    
    func isThumbExtended(landmarks: [NormalizedLandmark]) -> Bool {
        let tip = landmarks[4]      // Thumb tip
        let ip = landmarks[3]       // Thumb IP joint
        let mcp = landmarks[2]      // Thumb MCP joint
        let cmc = landmarks[1]      // Thumb CMC joint

        // Check if thumb is "pointing away" from the palm
        let vector1 = SIMD2<Float>(ip.x - mcp.x, ip.y - mcp.y)
        let vector2 = SIMD2<Float>(tip.x - ip.x, tip.y - ip.y)

        let dotProduct = vector1.x * vector2.x + vector1.y * vector2.y
        let magnitude1 = sqrt(vector1.x * vector1.x + vector1.y * vector1.y)
        let magnitude2 = sqrt(vector2.x * vector2.x + vector2.y * vector2.y)

        let angle = acos(dotProduct / (magnitude1 * magnitude2 + 1e-6)) * 180 / .pi

        return angle < 30 || angle > 150 // smaller angle means straighter thumb
    }
    
    func getHandSide(landmarks: [NormalizedLandmark]) -> String {
        guard landmarks.count == 21 else { return "Unknown" } // Ensure we have all landmarks
        
        let wrist = landmarks[0]
        let thumb = landmarks[4]
        let pinky = landmarks[20]
        
        // Use thumb and pinky X-coordinates to determine hand side
        if thumb.x < pinky.x {
            return "Left Hand"
        } else if thumb.x > pinky.x {
            return "Right Hand"
        } else {
            // If thumb and pinky are aligned, use wrist position as fallback
            if wrist.x < 0.5 {
                return "Left Hand"
            } else {
                return "Right Hand"
            }
        }
    }
    
    func getHandSideWithOrientation(landmarks: [NormalizedLandmark]) -> String {
        guard landmarks.count == 21 else { return "Unknown" } // Ensure we have all landmarks
        
        let thumb = landmarks[4]
        let pinky = landmarks[20]
        
        // Thumb for left hand will be on the left (lower x value) compared to pinky
        if thumb.x < pinky.x {
            return "Left Hand"
        } else {
            return "Right Hand"
        }
    }
}

struct FaceAnalyzer {
    
    // Function to calculate Euclidean distance between two landmarks
    static func distance(_ p1: NormalizedLandmark, _ p2: NormalizedLandmark) -> CGFloat {
        let dx = CGFloat(p1.x - p2.x)
        let dy = CGFloat(p1.y - p2.y)
        return sqrt(dx * dx + dy * dy) // Euclidean distance
    }
    
    // Calculate Eye Aspect Ratio (EAR) to determine if eyes are open
    static func calculateEAR(eyeLandmarks: [NormalizedLandmark]) -> CGFloat {
        guard eyeLandmarks.count >= 6 else { return 0.0 }
        
        let A = self.distance(eyeLandmarks[1], eyeLandmarks[5]) // Vertical
        let B = self.distance(eyeLandmarks[2], eyeLandmarks[4]) // Vertical
        let C = self.distance(eyeLandmarks[0], eyeLandmarks[3]) // Horizontal
        
        return (A + B) / (2.0 * C) // EAR Formula
    }
    
    // Calculate Mouth Aspect Ratio (MAR) to check if the user is smiling
    static func calculateMAR(mouthLandmarks: [NormalizedLandmark]) -> CGFloat {
        guard mouthLandmarks.count >= 11 else { return 0.0 }

        // Get the vertical distances between the upper and lower lips
        let A = self.distance(mouthLandmarks[3], mouthLandmarks[9])  // Left side vertical
        let B = self.distance(mouthLandmarks[2], mouthLandmarks[10]) // Right side vertical
        let C = self.distance(mouthLandmarks[4], mouthLandmarks[8])  // Center vertical

        // Get the horizontal distance across the mouth (corner to corner)
        let D = self.distance(mouthLandmarks[0], mouthLandmarks[6])  // Horizontal distance

        // Avoid division by zero and scale the MAR to reasonable values
        guard D > 0 else { return 0.0 }

        // Return the MAR formula: (sum of vertical distances) / (3 * horizontal distance)
        let mar = (A + B + C) / (3.0 * D)
        return mar
    }


    
    // Check if the detected face meets conditions
    static func isValidFace(faceLandmarkerResult: FaceLandmarkerResult?) -> Bool {
        guard let face = faceLandmarkerResult, !face.faceLandmarks.isEmpty else {
            return false
        }
        
        let landmarks = face.faceLandmarks[0] // Assume first detected face
        
        // Extract landmarks for both eyes and mouth
       
        let mouthLandmarks = Array(landmarks[0..<11] ) // Example indices for mouth
        
        // Calculate EAR for both eyes
        let leftEyeIndices = [33, 159, 158, 153, 145, 133]
            let rightEyeIndices = [362, 386, 385, 380, 374, 263]
            
            let avgEAR = self.calculateEAR(landmarks: landmarks, leftEyeIndices: leftEyeIndices, rightEyeIndices: rightEyeIndices)
          //  print("Average EAR: \(avgEAR)")
            
         //   print("Average EAR: \(avgEAR)")

        // Calculate MAR for the mouth
        let mar = calculateMAR(mouthLandmarks: mouthLandmarks)
        //print("Mouth mar: \(mar)") // Should be close to 0 if face is straight

        // Get head pose angles (assuming MediaPipe provides these)
        let yawAngle = abs(self.calculateYaw(landmarks: landmarks)) - 90
        let rollAngle = abs(self.calculateRoll(landmarks: landmarks)) - 90
        let pitchAngle = self.calculatePitch(landmarks: landmarks)
        
        print("Yaw Angle: \(yawAngle)°") // Should be close to 0 if face is straight
        print("Roll Angle: \(rollAngle)°") // Should be close to 0 if head is not tilted
        print("Pitch Angle: \(pitchAngle)°") // Should be close to 0 if face is level
//        
        
        // Define thresholds
        let EAR_THRESHOLD: CGFloat = 0.2  // Eyes open if EAR > 0.2
        let MAR_THRESHOLD: CGFloat = 1.20  // Not smiling if MAR < 0.5
        let MAX_YAW: CGFloat = 10.0       // Face straight if Yaw within ±10°
        let MAX_PITCH: CGFloat = 30.0     // Face straight if Pitch within ±10°
        let MAX_ROLL: CGFloat = 10.0       // No head tilt if Roll within ±5°
        
        // Validate conditions
        let eyesOpen = avgEAR > EAR_THRESHOLD
        let notSmiling = mar < MAR_THRESHOLD
        let faceStraight = abs(yawAngle) <= MAX_YAW &&
        abs(pitchAngle) <= MAX_PITCH &&
        abs(rollAngle) <= MAX_ROLL
        
        return eyesOpen && notSmiling && faceStraight
    }
    
    static func calculateEAR(landmarks: [NormalizedLandmark], leftEyeIndices: [Int], rightEyeIndices: [Int]) -> CGFloat {
        guard landmarks.count > 468 else { return 0.0 }

        func eyeAspectRatio(eye: [Int]) -> CGFloat {
            // Get the landmarks for the eye
            let p1 = landmarks[eye[1]] // Upper eyelid
            let p2 = landmarks[eye[5]] // Lower eyelid
            let p3 = landmarks[eye[2]] // Upper eyelid
            let p4 = landmarks[eye[4]] // Lower eyelid
            let p5 = landmarks[eye[0]] // Left corner
            let p6 = landmarks[eye[3]] // Right corner

            // Calculate vertical and horizontal distances
            let vertical1 = self.distance(p1, p2)
            let vertical2 = self.distance(p3, p4)
            let horizontal = self.distance(p5, p6)

            // Avoid division by zero
            if horizontal == 0 {
                return 0.0
            }
            let scale = 3.0
            // Calculate and return the Eye Aspect Ratio
            let ear = (vertical1 + vertical2) / (2.0 * horizontal * scale)
            return ear
        }

        // Calculate EAR for both eyes
        let leftEAR = eyeAspectRatio(eye: leftEyeIndices)
        let rightEAR = eyeAspectRatio(eye: rightEyeIndices)
        
        // Debugging: print out the values
//        print("leftEAR: \(leftEAR)")  // Should be close to 0 for closed eyes
//        print("rightEAR: \(rightEAR)") // Should be close to 0 for closed eyes

        // Return the average EAR of both eyes
        return (leftEAR + rightEAR) / 2.0
    }

    // Function to get the midpoint of two landmarks
    static func midpoint(_ p1: NormalizedLandmark, _ p2: NormalizedLandmark) -> NormalizedLandmark {
        return NormalizedLandmark(
            x: (p1.x + p2.x) / 2,
            y: (p1.y + p2.y) / 2,
            z: (p1.z + p2.z) / 2,
            visibility: 1.0,  // Default visibility
            presence: 1.0     // Default presence
        )
    }

    
    // Function to calculate Yaw (Left/Right Turn)
    static func calculateYaw(landmarks: [NormalizedLandmark]) -> CGFloat {
        guard landmarks.count > 468 else { return 0.0 }

        let nose = landmarks[1]      // Nose tip
        let leftEye = landmarks[33]  // Outer left eye corner
        let rightEye = landmarks[263] // Outer right eye corner

        let eyeMidX = (leftEye.x + rightEye.x) / 2 // Midpoint between eyes
        let dx = nose.x - eyeMidX // Nose offset from center
        let dy = leftEye.x - rightEye.x // Eye horizontal distance

        let yaw = atan2(dx, dy) * (180.0 / .pi)
        return CGFloat(yaw) // Positive = Turned Right, Negative = Turned Left
    }

    
    // Function to calculate Roll (Head Tilt)
    static func calculateRoll(landmarks: [NormalizedLandmark]) -> CGFloat {
        guard landmarks.count > 468 else { return 0.0 }

        let leftEye = landmarks[33]  // Outer left eye corner
        let rightEye = landmarks[263] // Outer right eye corner

        let dx = rightEye.x - leftEye.x
        let dy = rightEye.y - leftEye.y

        let roll = atan2(dy, dx) * (180.0 / .pi) // Corrected order
        return CGFloat(roll) // Should be ~0° if head is straight
    }

    // Calculate Pitch (Up/Down Tilt)
    static func calculatePitch(landmarks: [NormalizedLandmark]) -> CGFloat {
        guard landmarks.count > 468 else { return 0.0 }

        let nose = landmarks[1]      // Nose tip
        let leftEye = landmarks[33]  // Outer left eye corner
        let rightEye = landmarks[263] // Outer right eye corner
        let chin = landmarks[152]    // Chin bottom

        let eyeMid = midpoint(leftEye, rightEye) // Midpoint between both eyes
        let noseToEye = self.distance(nose, eyeMid)   // Distance from nose to eye midpoint
        let noseToChin = self.distance(nose, chin)    // Distance from nose to chin

        // Normalize using eye-chin distance to prevent scaling issues
        let normalizedPitch = (noseToChin - noseToEye) / self.distance(eyeMid, chin)

        let pitch = atan2(normalizedPitch, 1.0) * (180.0 / .pi)
        return CGFloat(pitch) // Should be ~0° when looking straight
    }

    //============================
    

    // Helper function to extract UIImage from CMSampleBuffer
    static func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }

        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }

    // Function to calculate bounding box from face landmarks
    static func getBoundingBox(from landmarks: [NormalizedLandmark]) -> CGRect {
        var minX: CGFloat = .greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude

        // Iterate over landmarks to find bounding box
        for landmark in landmarks {
            let x = CGFloat(landmark.x)
            let y = CGFloat(landmark.y)

            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // Function to apply padding to the bounding box
    static func applyPadding(to boundingBox: CGRect, paddingPercentage: CGFloat) -> CGRect {
        let paddingX = boundingBox.width * paddingPercentage
        let paddingY = boundingBox.width * paddingPercentage
        
        return CGRect(
            x: boundingBox.origin.x - paddingX / 1.5,
            y: boundingBox.origin.y - (paddingY ),
            width: boundingBox.width + (paddingX * 1.3),
            height: boundingBox.height + (paddingY * 2)
        )
    }

    // Function to adjust bounding box to 4:3 ratio
    static func adjustToAspectRatio(boundingBox: CGRect, targetAspectRatio: CGFloat = 4/3) -> CGRect {
        let currentAspectRatio = boundingBox.width / boundingBox.height
        
        if currentAspectRatio > targetAspectRatio {
            // Adjust width to match 4:3 ratio
            let newWidth = boundingBox.height * targetAspectRatio
            let deltaX = (boundingBox.width - newWidth) / 2
            return CGRect(
                x: boundingBox.origin.x + deltaX,
                y: boundingBox.origin.y,
                width: newWidth,
                height: boundingBox.height
            )
        } else {
            // Adjust height to match 4:3 ratio
            let newHeight = boundingBox.width / targetAspectRatio
            let deltaY = (boundingBox.height - newHeight) / 2
            return CGRect(
                x: boundingBox.origin.x,
                y: boundingBox.origin.y + deltaY,
                width: boundingBox.width,
                height: newHeight
            )
        }
    }

    // Function to crop image from CMSampleBuffer
    static  func cropFaceFromSampleBuffer(sampleBuffer: CMSampleBuffer?, landmarks: [NormalizedLandmark], padding: CGFloat = 0.1) -> UIImage? {
        // Extract image from CMSampleBuffer
        guard let sampleBuffer = sampleBuffer else { return nil }

        guard let image = imageFromSampleBuffer(sampleBuffer) else { return nil }
        
        // Get bounding box from landmarks
        let boundingBox = getBoundingBox(from: landmarks)
        
        // Apply padding and adjust to 4:3 ratio
        var paddedBoundingBox = applyPadding(to: boundingBox, paddingPercentage: padding)
        
        // Ensure the bounding box is within image bounds
        let imageSize = image.size
        paddedBoundingBox.origin.x = max(paddedBoundingBox.origin.x * imageSize.width, 0)
        paddedBoundingBox.origin.y = max(paddedBoundingBox.origin.y * imageSize.height, 0)
        paddedBoundingBox.size.width = min(paddedBoundingBox.size.width * imageSize.width, imageSize.width - paddedBoundingBox.origin.x)
        paddedBoundingBox.size.height = min(paddedBoundingBox.size.height * imageSize.height, imageSize.height - paddedBoundingBox.origin.y)
        
        paddedBoundingBox = adjustToAspectRatio(boundingBox: paddedBoundingBox)

        // Crop the image
        let cgImage = image.cgImage!.cropping(to: paddedBoundingBox)
        return cgImage != nil ? UIImage(cgImage: cgImage!) : nil
    }

   

}
