//
//  ARSceneViewRouteController.swift
//  tourar
//
//  Created by Артем Стратиенко on 16.06.2024.
//

import Foundation
import ARKit
import Vision
import SceneKit

var lastMLClassificationOrDetectionObject = ""

let synthesizer = AVSpeechSynthesizer()
let promtGigaChatLeft  = "Для обнаруженного обьекта камерой : ["
let promtGigaChatRight = "] напиши предупреждение для безопасного движения по дорогам для туристов. Предупреждение должно использовать русский перевод обнаруженного обьекта.  Туристы могут быть с ограниченными возможностями. Предупреждение должно быть коротким и понятным и не использовать слова из запроса"

public func voiceHelperUI(textSpeech : String)
{
    // добавляем озвучку перехода на главный таб бар
    let utterance = AVSpeechUtterance(string: "\(textSpeech)")
    // Configure the utterance.
    utterance.rate = 0.45
    utterance.pitchMultiplier = 0.8
    utterance.postUtteranceDelay = 0.2
    utterance.volume = 0.45
    // Retrieve the British English voice.
    let voice = AVSpeechSynthesisVoice(language: "ru-RU")
    // Assign the voice to the utterance.
    utterance.voice = voice
    // Tell the synthesizer to speak the utterance.
    if ( synthesizer.isSpeaking )
    {
    } else
    {
        synthesizer.speak(utterance)
    }
}

class ARSceneViewRouteController: UIViewController, UIGestureRecognizerDelegate, ARSessionDelegate {
    
    var sceneView = ARSCNView()
    let arButtonClose = UIButton(type: .system)
    // bool use type MLModel
    var isClassification = true
   /// The ML model to be used for recognition of arbitrary objects. - Classification
   private var _inceptionv3Model: Inceptionv3!
   private var inceptionv3Model: Inceptionv3! {
       get {
           if let model = _inceptionv3Model { return model }
           _inceptionv3Model = {
               do {
                   let configuration = MLModelConfiguration()
                   return try Inceptionv3(configuration: configuration)
               } catch {
                   fatalError("Couldn't create Inceptionv3 due to: \(error)")
               }
           }()
           return _inceptionv3Model
       }
   }
    /// The ML model to be used for recognition of arbitrary objects. - Detection
    private var _yolo3Model: YOLOv3Tiny!
    private var yolo3Model: YOLOv3Tiny! {
        get {
            if let model = _yolo3Model { return model }
            _yolo3Model = {
                do {
                    let configuration = MLModelConfiguration()
                    return try YOLOv3Tiny(configuration: configuration)
                } catch {
                    fatalError("Couldn't create Inceptionv3 due to: \(error)")
                }
            }()
            return _yolo3Model
        }
    }
    // MARK: - View controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        let scene = SCNScene()
        sceneView.scene = scene
        self.view.addSubview(sceneView)
        sceneView.snp.makeConstraints { (marker) in
            marker.top.bottom.equalToSuperview().inset(0)
            marker.left.right.equalToSuperview().inset(0)
        }
        // type routing
        let itemsSegment = ["Классификация","Детектирование"]
        var typeMLModelUse = UISegmentedControl(items: itemsSegment)
        typeMLModelUse.selectedSegmentIndex = 0
        typeMLModelUse.layer.cornerRadius = 5.0
        typeMLModelUse.tintColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        typeMLModelUse.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        typeMLModelUse.addTarget(self, action: #selector(self.changeTypeMLModelUse), for: .valueChanged)
        view.addSubview(typeMLModelUse)
        typeMLModelUse.snp.makeConstraints { (marker) in
            marker.height.equalTo(40)
            marker.width.equalTo(80)
            marker.topMargin.equalToSuperview().inset(20)
            marker.left.right.equalToSuperview().inset(40)
        }
        // ar close
        arButtonClose.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        arButtonClose.setTitleColor(.white, for: .normal)
        arButtonClose.setTitle("X", for: .normal)
        arButtonClose.layer.cornerRadius = 15

        view.addSubview(arButtonClose)
        arButtonClose.snp.makeConstraints { (marker) in
            marker.topMargin.equalTo(typeMLModelUse).inset(60)
            marker.rightMargin.equalToSuperview().inset(5)
            marker.width.equalTo(100)
            marker.height.equalTo(40)
        }
        arButtonClose.addTarget(self, action: #selector(closeARViewScene), for: .touchUpInside)
        
        self.restartSession()
        
    }
    @objc func closeARViewScene()
    {
        dismiss(animated: true)
    }
    @objc func changeTypeMLModelUse( segment : UISegmentedControl )
    {
            switch segment.selectedSegmentIndex {
            case 0:
                isClassification = true
            case 1:
                isClassification = false
            default:
                isClassification = true
            }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    //
    // MARK: - Vision classification
    
    // Vision classification request and model
    /// - Tag: ClassificationRequest
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            // Instantiate the model from its generated Swift class.
            let model = try VNCoreMLModel(for: inceptionv3Model.model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            
            // Crop input images to square area at center, matching the way the ML model was trained.
            request.imageCropAndScaleOption = .centerCrop
            
            // Use CPU for Vision processing to ensure that there are adequate GPU resources for rendering.
            request.usesCPUOnly = true
            
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    private lazy var detectionRequest: VNCoreMLRequest = {
        do{
            let model = try VNCoreMLModel(for: yolo3Model.model)
            let objectRecognition = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                        self.showDetectionResult(results)
                    }
                })
            })
            
            // Crop input images to square area at center, matching the way the ML model was trained.
            objectRecognition.imageCropAndScaleOption = .centerCrop
            
            // Use CPU for Vision processing to ensure that there are adequate GPU resources for rendering.
            objectRecognition.usesCPUOnly = true
            
            return objectRecognition
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    // The pixel buffer being held for analysis; used to serialize Vision requests.
    private var currentBuffer: CVPixelBuffer?
    
    // Queue for dispatching vision classification requests
    private let visionQueue = DispatchQueue(label: "com.example.apple-samplecode.ARKitVision.serialVisionQueue")
        
    // Classification results
    private var identifierString = ""
    private var confidence: VNConfidence = 0.0
    //
    func showDetectionResult(_ results: [Any])
    {
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
            print("Detection [object] : \(topLabelObservation.identifier) with [confidence] : \(topLabelObservation.confidence * 100)")
            if ( topLabelObservation.confidence * 100 > 90 ) {
                if ( lastMLClassificationOrDetectionObject != topLabelObservation.identifier )
                {
                    getTokenToGigaChat(requestString: promtGigaChatLeft + "\(topLabelObservation.identifier)" + promtGigaChatRight)
                    lastMLClassificationOrDetectionObject = topLabelObservation.identifier
                }
            }
        }
    }
    //
    private func restartSession() {
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}

extension ARSceneViewRouteController : ARSCNViewDelegate{
    // MARK: - ARSessionDelegate
    
    // Pass camera frames received from ARKit to Vision (when not already processing one)
    /// - Tag: ConsumeARFrames
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do not enqueue other buffers for processing while another Vision task is still running.
        // The camera stream has only a finite amount of buffers available; holding too many buffers for analysis would starve the camera.
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        
        // Retain the image buffer for Vision processing.
        self.currentBuffer = frame.capturedImage
        if ( isClassification )
        {
            classifyCurrentImage()

        }
        else
        {
            detectionCurrentImage()
        }
    }
    /// - Tag: ClassifyCurrentImage
    private func classifyCurrentImage() {
        // Most computer vision tasks are not rotation agnostic so it is important to pass in the orientation of the image with respect to device.
        let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)

        let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentBuffer!, orientation: orientation)
        visionQueue.async {
            do {
                // Release the pixel buffer when done, allowing the next buffer to be processed.
                defer { self.currentBuffer = nil }
                try requestHandler.perform([self.classificationRequest])
            } catch {
                print("Error: Vision request failed with error \"\(error)\"")
            }
        }
    }
    
    /// - Tag: DetectionCurrentImage
    private func detectionCurrentImage() {
        // Most computer vision tasks are not rotation agnostic so it is important to pass in the orientation of the image with respect to device.
        let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)

        let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentBuffer!, orientation: orientation)
        visionQueue.async {
            do {
                // Release the pixel buffer when done, allowing the next buffer to be processed.
                defer { self.currentBuffer = nil }
                try requestHandler.perform([self.detectionRequest])
            } catch {
                print("Error: Vision request failed with error \"\(error)\"")
            }
        }
    }

    // Handle completion of the Vision request and choose results to display.
    /// - Tag: ProcessClassifications
    func processClassifications(for request: VNRequest, error: Error?) {
        guard let results = request.results else {
            print("Unable to classify image.\n\(error!.localizedDescription)")
            return
        }
        // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
        let classifications = results as! [VNClassificationObservation]
        
        // Show a label for the highest-confidence result (but only above a minimum confidence threshold).
        if let bestResult = classifications.first(where: { result in result.confidence > 0.5 }),
            let label = bestResult.identifier.split(separator: ",").first {
            identifierString = String(label)
            confidence = bestResult.confidence
        } else {
            identifierString = ""
            confidence = 0
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.displayClassifierResults()
        }
    }
    
    // Show the classification results in the UI.
    private func displayClassifierResults() {
        guard !self.identifierString.isEmpty else {
            return // No object was classified.
        }
        print("Classifed [object] : \(self.identifierString) with [confidence] : \(self.confidence * 100)")
        if ( self.confidence * 100 > 90 ) {
            
            if ( lastMLClassificationOrDetectionObject != self.identifierString )
            {
                getTokenToGigaChat(requestString: promtGigaChatLeft + "\(self.identifierString)" + promtGigaChatRight)
                lastMLClassificationOrDetectionObject = self.identifierString
            }
            
        }
    }
    
    // MARK: - AR Session Handling
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
        switch camera.trackingState {
        case .notAvailable, .limited:
            print("NOT NORMAL SESSION")
        case .normal:
            print("NORMAL SESSION")
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Filter out optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            print("The AR session failed.")
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        /*
         Allow the session to attempt to resume after an interruption.
         This process may not succeed, so the app must be prepared
         to reset the session if the relocalizing status continues
         for a long time -- see `escalateFeedback` in `StatusViewController`.
         */
        return true
    }
}

// Convert device orientation to image orientation for use by Vision analysis.
extension CGImagePropertyOrientation {
    init(_ deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portraitUpsideDown: self = .left
        case .landscapeLeft: self = .up
        case .landscapeRight: self = .down
        default: self = .right
        }
    }
}
