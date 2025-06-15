//
//  CameraView.swift
//  CaptureDFH
//
//  Created by Khalil Charkas on 14/02/2025.
//
import AVFoundation
import Vision
import CoreImage
import SwiftUI
import CoreVideo
//import MLImage
//import MLKit

struct CameraView: View {
    @ObservedObject var cameraModel: CameraModel
    var action:(UIImage?, handSide?)->Void
    @ObservedObject var reloadManager:ReloadManager

   
    
    var body: some View {
        
        let cameraPreview = CameraPreview(cameraModel: cameraModel)
        let coordinator = cameraPreview.makeCoordinator()
        
        VStack {
            
            ZStack (alignment: .center){
                cameraPreview
                    .frame(height: cameraModel.getHeight)//width: UIScreen.main.bounds.width * 0.85
                    //.cornerRadius(captureType == .face ? 155 :  10)
                    .clipShape(RoundedRectangle(cornerRadius:cameraModel.captureType == .face ? 155 :  10)) // Clip to rectangle
                    .overlay(
                        RoundedRectangle(cornerRadius: cameraModel.captureType == .face ? 155 :  10)
                            .stroke(style: StrokeStyle(lineWidth: 3, dash: [10]))
                            .foregroundColor(.white)
                    )
            }.id(reloadManager.reload)
                .onAppear{
             
                    print(cameraModel.captureType)
                    print("cameraModel.captureType")


                }
            
//            Button(action: {
//                cameraPreview.capturePhoto(coordinator: coordinator)
//            }) {
//                Circle()
//                    .fill(Color.white)
//                    .frame(width: 50, height: 50)
//                    .overlay(Circle().stroke(Color.gray, lineWidth: 4))
//                    .shadow(radius: 10)
//            }.padding(.top)
        }
        .padding(.bottom, 10)
        .onAppear {
          //  cameraModel.setupCamera()
        }.onChange(of: cameraModel.capturedImage, perform: { newValue in
            if let imageData = newValue{
                action(imageData, cameraModel.handSide)
            }
        })
        
    }
   
}
// Camera Model
class CameraModel: NSObject, ObservableObject {
    var session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    @Published var capturedImage: UIImage?
    @Published var handSide: handSide?
    @Published var captureType: CaptureType = .document
    var latestSampleBuffer: CMSampleBuffer?  // Store the latest frame
    var analisedFace = false
    internal var faceDetectorCrop: CIDetector?
    
    private var currentDetector: Detector = .onDeviceFace
    private var isUsingFrontCamera = true
    private var lastFrame: CMSampleBuffer?

    private var faceCaptureCount:Int = 0
    private var faceCaptureinProgess:Bool = false

    init(type:CaptureType) {
        super.init()
//        analisedFace = false
        captureType = type
//        setupCamera()
//        if type == .face{
//            self.faceDetectorCrop = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
//        }

    }

    
    var getHeight:CGFloat{
        switch captureType {
        
        case .document:
            return 280
        case .face:
            return 380
        case .hand:
            return 380
        case .faceHand:
            return 380
        }
    }
}


// Camera Preview Restricted to Frame
struct CameraPreview: UIViewControllerRepresentable {
    @ObservedObject var cameraModel: CameraModel
    var cameraController: CameraViewController?
    
    class Coordinator {
        static var cameraController: CameraViewController?
        
        func capturePhoto() {
            CameraPreview.Coordinator.cameraController?.capturePhoto()
        }
        
        func restart() {
            CameraPreview.Coordinator.cameraController?.switchCamera()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.cameraModel = cameraModel
        print(cameraModel.captureType)
        // Set captured image callback
        controller.onPhotoCaptured = { image, handSide in
            DispatchQueue.main.async {
                self.cameraModel.handSide = handSide
                self.cameraModel.capturedImage = image
            }
        }
        
        // Store the reference in the coordinator
        CameraPreview.Coordinator.cameraController = controller
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
    
    func capturePhoto(coordinator: Coordinator) {
        coordinator.capturePhoto()
    }
    
    func restart(coordinator: Coordinator) {
        coordinator.restart()
    }
}



enum CaptureType:Int{
    case document = 1
    case face = 2
    case faceHand = 3
    case hand = 4
}
internal extension UIImage {
   
    func cropImage( rect: CGRect) -> UIImage? {
        var rect = rect
        rect.origin.x*=self.scale
        rect.origin.y*=self.scale
        rect.size.width*=self.scale
        rect.size.height*=self.scale
        
        if let imageRef = self.cgImage!.cropping(to: rect){
            let image = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        return image
        }else { return nil}
    }
    func scaled(with scale: CGFloat) -> UIImage? {
        // size has to be integer, otherwise it could get white lines
        let widthIntValue = Int(self.size.width * scale)
        var multiple = widthIntValue % 8
        let width = CGFloat(widthIntValue - multiple)
        var height = width / 0.75
        let heightIntValue = Int(self.size.height * scale)
        multiple = heightIntValue % 8
        height = CGFloat(heightIntValue - multiple)
        
        let size = CGSize(width: floor(width), height: floor(height))

        UIGraphicsBeginImageContext(size)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if image != nil {
            return image
        }else{
            return self
        }
    }
    func resizeImage(newWidth: CGFloat) -> UIImage? {

        let scale = newWidth / self.size.width
        let newHeight = self.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        self.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    convenience init?(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        self.init(cgImage: cgImage)
    }
}



