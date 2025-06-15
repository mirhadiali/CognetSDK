//
//  DocumentScannerViewController.swift
//  CaptureFace
//
//  Created by Hadi Ali on 23/04/2025.
//


//
//  DocumentScannerViewController.swift
//  CaptureDFH
//
//  Created by Khalil Charkas on 12/02/2025.
//


import UIKit
import AVFoundation
import Vision
import SwiftUI
import CoreImage

extension AVCaptureVideoOrientation {
    internal init(orientation: UIInterfaceOrientation) {
        switch orientation {
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeLeft
        case .landscapeRight:
            self = .landscapeRight
        default:
            self = .portrait
        }
    }
}

class DocumentScannerViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var onDocumentCaptured: ((UIImage) -> Void)?  // Callback to pass image
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let documentDetectionOverlay = CAShapeLayer()
    private var documentDetected = false
    
    private var consecutiveFrameDetectionCount = 0
    private let requiredDetectionFrames = 2  // Adjust as needed for reliable detection
    
    private var cropRect: CGRect = CGRect.zero
    private var viewWidth: CGFloat = 0
    private var viewHeight: CGFloat = 0
    
    let analyzer = DocumentQualityAnalyzer()
    
    var documentType: DocumentType = .idCard
    
    internal override var interfaceOrientation: UIInterfaceOrientation {
        return UIApplication.shared.statusBarOrientation
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds  // Adjust to fit SwiftUI frame
    }
    
    private func setupCamera() {
        self.captureSession.beginConfiguration()
        self.captureSession.sessionPreset = .hd1920x1080 // or .high / .hd1920x1080
        
        // MARK: - Input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              self.captureSession.canAddInput(input) else {
            print("Failed to set up camera input")
            return
        }
        self.captureSession.addInput(input)
        if self.captureSession.canAddOutput(self.videoOutput) {
            self.captureSession.addOutput(self.videoOutput)
        }
        
        // MARK: - Output
        self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:
                                            kCVPixelFormatType_32BGRA]
        self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "SampleBufferQueue"))
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        self.videoOutput.connection(with: .video)!.videoOrientation = AVCaptureVideoOrientation(orientation: self.interfaceOrientation)
        
        
        
        // Align orientation
        if let connection = self.videoOutput.connection(with: .video),
           connection.isVideoOrientationSupported {
            connection.videoOrientation = .landscapeRight
//            connection.isVideoMirrored = false
        }
        
        // MARK: - Auto Focus & Exposure
        configureCamera(for: camera)
        
        self.captureSession.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        previewLayer.session = captureSession
        view.layer.addSublayer(previewLayer)
        
        documentDetectionOverlay.strokeColor = UIColor.green.cgColor
        documentDetectionOverlay.lineWidth = 4
        documentDetectionOverlay.fillColor = UIColor.clear.cgColor
        view.layer.addSublayer(documentDetectionOverlay)
    }
    
    func configureCamera(for device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            
            // Lock focus
            if device.isFocusModeSupported(.locked) {
                device.focusMode = .continuousAutoFocus
            }
            
            // Lock exposure
            if device.isExposureModeSupported(.locked) {
                device.exposureMode = .locked
            }
            
            // Lock white balance
            if device.isWhiteBalanceModeSupported(.locked) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Failed to lock camera configuration: \(error)")
        }
    }
    
   
    // Process camera frames
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        detectDocument(in: pixelBuffer)
    }
    private func isRectangleCentered(_ rect: VNRectangleObservation) -> Bool {
        let xCenter = rect.boundingBox.midX
        let yCenter = rect.boundingBox.midY
        
        return (xCenter > 0.4 && xCenter < 0.6) && (yCenter > 0.3 && yCenter < 0.7)
    }
    
    func checkIfLiesInPreview(observation: VNRectangleObservation) -> Bool {
        let layerBounds = self.previewLayer.bounds

        // 1. Get all 4 corners of the normalized bounding box
        let topLeft = CGPoint(x: observation.boundingBox.minX, y: observation.boundingBox.maxY)
        let topRight = CGPoint(x: observation.boundingBox.maxX, y: observation.boundingBox.maxY)
        let bottomLeft = CGPoint(x: observation.boundingBox.minX, y: observation.boundingBox.minY)
        let bottomRight = CGPoint(x: observation.boundingBox.maxX, y: observation.boundingBox.minY)
        
        // 2. Convert all points to previewLayer coordinates
        let convertedTopLeft = self.previewLayer.layerPointConverted(fromCaptureDevicePoint: topLeft)
        let convertedTopRight = self.previewLayer.layerPointConverted(fromCaptureDevicePoint: topRight)
        let convertedBottomLeft = self.previewLayer.layerPointConverted(fromCaptureDevicePoint: bottomLeft)
        let convertedBottomRight = self.previewLayer.layerPointConverted(fromCaptureDevicePoint: bottomRight)
        
        // 3. Check if all points lie inside the previewLayer bounds
        let liesUnderPreview = layerBounds.contains(convertedTopLeft) &&
        layerBounds.contains(convertedTopRight) &&
        layerBounds.contains(convertedBottomLeft) &&
        layerBounds.contains(convertedBottomRight)
        
#if DEBUG
        if !liesUnderPreview {
            print("Detected rectangle doesn't lies under preview")
        }
#endif
        return liesUnderPreview
    }
    
  
    private func detectDocument(in pixelBuffer: CVPixelBuffer) {
        print("Consecutive Detected Frame Count: \(self.consecutiveFrameDetectionCount)")
        
        let request = VNDetectRectanglesRequest { request, error in
            guard let results = request.results as? [VNRectangleObservation], let detectedRect = results.first, self.checkIfLiesInPreview(observation: detectedRect) else {
                DispatchQueue.main.async {
                    // Clear the document detection overlay if no document is detected
                    self.documentDetectionOverlay.path = nil
                }
                // Reset consecutive frame detection count if no document detected
                self.consecutiveFrameDetectionCount = 0
                self.documentDetected = false
                return
            }
            
            
            DispatchQueue.main.async {
//#if DEBUG
                // Highlight the detected document
                self.highlightDocument(detectedRect, pixelBuffer: pixelBuffer)
                
//#endif
                
                // Increase the consecutive frame detection count
                self.consecutiveFrameDetectionCount += 1
                
                // If the document has been detected for the required number of consecutive frames, initiate capture
                if self.consecutiveFrameDetectionCount >= self.requiredDetectionFrames,
                   self.isRectangleCentered(detectedRect),
                   self.analyzer.isRectangleSkewed(detectedRect),
                   self.analyzer.isImageSharpEnough(pixelBuffer: pixelBuffer,
                                                    threshold: self.documentType.getSharpnessThreshold()),
                   self.analyzer.isImageTooBright(pixelBuffer: pixelBuffer) {
                    if !self.documentDetected {
                        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
                        let context = CIContext()
                        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                            let img = UIImage(cgImage: cgImage)
                            if let rotatedImage = self.rotateImage(image: img, by: 0){
                                if let cropedimage =  self.cropUIImage(image: rotatedImage, cropRect: detectedRect.boundingBox)  ,
                                   let finalImage = self.rotateImage(image: cropedimage, by: 90){
                                    DispatchQueue.main.async {
                                        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                                            self?.captureSession.stopRunning()
                                        }
                                        self.onDocumentCaptured?(finalImage)  // Pass captured image to SwiftUI
                                    }
                                }
                            }
                        }
                        //                        self.initiateCaptureProcess()  // Start the capture process when document is reliably detected
                        self.documentDetected = true
                    }
                } else {
                    // If the document is detected but not for enough frames yet, don't initiate capture
                    self.documentDetected = false
                }
            }
        }
        
        // Adjust detection settings to suit the document detection
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 1
        request.minimumSize = 0.4
        request.quadratureTolerance = 15
        request.minimumConfidence = 0.7
        request.maximumObservations = 1
        
        // Perform the detection request on the pixel buffer
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([request])
    }
    
    private func highlightDocument(_ detectedRect: VNRectangleObservation, pixelBuffer: CVPixelBuffer) {
        guard let previewLayer = self.previewLayer else { return }

        // Convert normalized points to the view’s coordinate space using the preview layer
        func convertToView(_ point: CGPoint) -> CGPoint {
            let imagePoint = VNImagePointForNormalizedPoint(point,
                                                            Int(CVPixelBufferGetWidth(pixelBuffer)),
                                                            Int(CVPixelBufferGetHeight(pixelBuffer)))
            let cgPoint = CGPoint(x: imagePoint.x, y: CGFloat(CVPixelBufferGetHeight(pixelBuffer)) - imagePoint.y)
            return previewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: cgPoint.x / CGFloat(CVPixelBufferGetWidth(pixelBuffer)),
                                                                                     y: cgPoint.y / CGFloat(CVPixelBufferGetHeight(pixelBuffer))))
        }

        let topLeft = convertToView(detectedRect.topLeft)
        let topRight = convertToView(detectedRect.topRight)
        let bottomRight = convertToView(detectedRect.bottomRight)
        let bottomLeft = convertToView(detectedRect.bottomLeft)

        // Draw the rectangle
        let path = UIBezierPath()
        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.close()

        DispatchQueue.main.async {
            self.documentDetectionOverlay.path = path.cgPath
            self.documentDetectionOverlay.strokeColor = UIColor.green.cgColor
            self.documentDetectionOverlay.lineWidth = 3.0
            self.documentDetectionOverlay.fillColor = UIColor.clear.cgColor

            if self.documentDetectionOverlay.superlayer == nil {
                self.view.layer.addSublayer(self.documentDetectionOverlay)
            }
        }
    }
    
    private func cropAndRotateImage(pixelBuffer: CVPixelBuffer, cropRect: CGRect, isPortrait: Bool) {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // Convert the cropRect from view coordinates to pixel buffer coordinates
        let scaleX = CGFloat(width) / self.view.frame.width
        let scaleY = CGFloat(height) / self.view.frame.height
        
        let cropRectInPixelBuffer = CGRect(
            x: cropRect.origin.x * scaleX,
            y: cropRect.origin.y * scaleY,
            width: cropRect.size.width * scaleX,
            height: cropRect.size.height * scaleY
        )
        
        // Create a CIImage from the pixel buffer to crop it
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Apply the crop to the CIImage
        let croppedImage = ciImage.cropped(to: cropRectInPixelBuffer)
        
        // Convert the CIImage to UIImage (before rotation)
        if let uiImage = convertCIImageToUIImage(ciImage: croppedImage){
            
            // Now rotate the cropped image if necessary
            if !isPortrait {
                if let rotatedImage = self.rotateImage(image: uiImage, by: 90){
                    // Use the rotated image (display, save, etc.)
                    print("Image Rotated and Cropped")
                    DispatchQueue.main.async {
                        self.onDocumentCaptured?(rotatedImage)  // Pass captured image to SwiftUI
                    }
                }
            } else {
                // Use the cropped image as is
                print("Image Cropped")
            }
        }
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
        // 1. Get the size of the image
        let imageSize = image.size
        
        // 2. Convert normalized bounding box (origin at bottom-left) to actual pixel values (UIKit origin is top-left)
        let cropX = cropRect.origin.x * imageSize.width
        let cropHeight = cropRect.size.height * imageSize.height
        let cropY = (1 - cropRect.origin.y) * imageSize.height - cropHeight
        let cropWidth = cropRect.size.width * imageSize.width

        let pixelCropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)

        // 3. Crop the image using CGImage
        guard let cgImage = image.cgImage,
              let croppedCGImage = cgImage.cropping(to: pixelCropRect) else {
            return nil
        }

        // 4. Return a UIImage from the cropped CGImage
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func initiateCaptureProcess() {
        // Start the capture process (e.g., take a photo or perform other actions)
        print("Document detected reliably. Initiating capture process...")
        // Add your capture logic here
        captureImage()
    }
    private func promptUserForAdjustment() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Adjust Document", message: "Make sure the document fits within the frame.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    private func captureImage() {
        let photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            let maxPrioritization = photoOutput.maxPhotoQualityPrioritization
            if maxPrioritization.rawValue >= AVCapturePhotoOutput.QualityPrioritization.quality.rawValue {
                settings.photoQualityPrioritization = .quality
            } else {
                settings.photoQualityPrioritization = .speed
            }
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

// Handle captured photo
extension DocumentScannerViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else { return }
        // UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil) // Save to gallery
        print("Document captured!")
        if let rotatedImage = self.rotateImage(image: image, by: 0){
            if let cropedimage =  self.cropUIImage(image: rotatedImage, cropRect: cropRect){
                DispatchQueue.main.async {
                    self.onDocumentCaptured?(cropedimage)  // Pass captured image to SwiftUI
                    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                        self?.captureSession.stopRunning()
                    }
                }
            }
        }
    }
}


struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    var documentType: DocumentType
    var onCapture: ((UIImage) -> Void)?  // Completion handler
    
    func makeUIViewController(context: Context) -> DocumentScannerViewController {
        let scannerVC = DocumentScannerViewController()
        scannerVC.documentType = documentType
        scannerVC.onDocumentCaptured = { image in
            self.capturedImage = image
            self.onCapture?(image)  // Trigger the completion handler
            
        }
        return scannerVC
    }
    
    func updateUIViewController(_ uiViewController: DocumentScannerViewController, context: Context) {
        // No updates needed
    }
}

private func convertCIImageToUIImage(ciImage: CIImage) -> UIImage? {
    let context = CIContext()  // Create a CIContext for rendering the image
    if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
        return UIImage(cgImage: cgImage)  // Convert the CGImage to a UIImage
    }
    return nil  // Return nil if conversion fails
}
