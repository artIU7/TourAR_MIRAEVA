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
import CoreLocation
import AVFoundation


var lastMLClassificationOrDetectionObject = ""
var locationsPointAR: [CLLocation] = []
var startingLocation: CLLocation!

var allowNode : SCNNode!
var buildNode : SCNNode!

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
    
    //
    let pointOnObjectDepth = 0.01 // the 'depth' of 3D text
    var latestPrediction : String = "…" // a variable containing the latest CoreML prediction

    //
    var rootLayer: CALayer! = nil
    //
    private var detectionOverlay: CALayer! = nil

    var sceneView = ARSCNView()
    let arButtonClose = UIButton(type: .system)
    let routeShow     = UIButton(type: .system)

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
    //
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)\nConfidence:  %.2f", confidence))
        let largeFont = UIFont(name: "Helvetica", size: 24.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Found Object"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
    //
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: self.view.bounds.width,
                                         height: self.view.bounds.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
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
        rootLayer = self.view.layer
        // type routing
        let itemsSegment = ["Классификация","Детектирование"]
        var typeMLModelUse = UISegmentedControl(items: itemsSegment)
        typeMLModelUse.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)], for: .selected)
        typeMLModelUse.selectedSegmentIndex = 0
        typeMLModelUse.layer.cornerRadius = 5.0
        typeMLModelUse.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        typeMLModelUse.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        typeMLModelUse.addTarget(self, action: #selector(self.changeTypeMLModelUse), for: .valueChanged)
        view.addSubview(typeMLModelUse)
        typeMLModelUse.snp.makeConstraints { (marker) in
            marker.height.equalTo(40)
            marker.width.equalTo(80)
            marker.topMargin.equalToSuperview().inset(20)
            marker.left.right.equalToSuperview().inset(40)
        }
        // ar close
        arButtonClose.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
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
        
        // route show
        routeShow.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        routeShow.setTitleColor(.white, for: .normal)
        routeShow.setTitle("Маршрут", for: .normal)
        routeShow.layer.cornerRadius = 15

        view.addSubview(routeShow)
        routeShow.snp.makeConstraints { (marker) in
            marker.topMargin.equalTo(arButtonClose).inset(60)
            marker.rightMargin.equalToSuperview().inset(5)
            marker.width.equalTo(100)
            marker.height.equalTo(40)
        }
        routeShow.addTarget(self, action: #selector(showRouteButton), for: .touchUpInside)
        
        self.restartSession()
        
        drawARRoute()
        //
        setupLayers()
        updateLayerGeometry()
        //
        /*
        // Tap Gesture Recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognize:)))
        view.addGestureRecognizer(tapGesture)
        */

    }
    // MARK: - Interaction
    
    func setAnchorObjectDetection() {
        // HIT TEST : REAL WORLD
        // Get Screen Centre
        let screenCentre : CGPoint = CGPoint(x: self.sceneView.bounds.midX, y: self.sceneView.bounds.midY)
        
        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenCentre, types: [.featurePoint]) // Alternatively, we could use '.existingPlaneUsingExtent' for more grounded hit-test-points.
        
        if let closestResult = arHitTestResults.first {
            // Get Coordinates of HitTest
            let transform : matrix_float4x4 = closestResult.worldTransform
            let worldCoord : SCNVector3 = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            
            // Create 3D Text
            let node : SCNNode = createPointOnObjectDetection(latestPrediction)
            sceneView.scene.rootNode.addChildNode(node)
            node.position = worldCoord
        }
    }
    
    @objc func showRouteButton()
    {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
        node.removeFromParentNode() }      //drawARRoute()
        
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
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
            print("Detection [object] : \(topLabelObservation.identifier) with [confidence] : \(topLabelObservation.confidence * 100)")
            if ( topLabelObservation.confidence * 100 > 80 ) {
                //if ( lastMLClassificationOrDetectionObject != topLabelObservation.identifier )
                //{
                    getTokenToGigaChat(requestString: promtGigaChatLeft + "\(topLabelObservation.identifier)" + promtGigaChatRight)
                    lastMLClassificationOrDetectionObject = topLabelObservation.identifier
                    //
                    let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(self.view.bounds.width), Int(self.view.bounds.height))
                    
                    let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
                    
                    let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                                    identifier: topLabelObservation.identifier,
                                                                    confidence: topLabelObservation.confidence)
                    shapeLayer.addSublayer(textLayer)
                    detectionOverlay.addSublayer(shapeLayer)
                    self.latestPrediction = topLabelObservation.identifier
                    setAnchorObjectDetection()
                // }
            }
        }
        updateLayerGeometry()
        CATransaction.commit()
    }
    //
    func updateLayerGeometry() {
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / self.view.bounds.height
        let yScale: CGFloat = bounds.size.height / self.view.bounds.width
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
        
    }
    private func restartSession() {
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    // draw Route
    
    // прориосвка маршрута
    func drawARRoute() {
        var routes = [SCNVector3]()
        if locationsPointAR != [] {
            for vector in locationsPointAR {
                let p1 = CLLocationCoordinate2D(latitude: startingLocation.coordinate.latitude,
                                                longitude: startingLocation.coordinate.longitude)
                let p2 = CLLocationCoordinate2D(latitude: vector.coordinate.latitude,
                                                longitude: vector.coordinate.longitude)
                let offset = offsetComplete(p1, p2)
                routes.append(SCNVector3(0 + offset[0], -1.25, 0 + offset[1] * -1))
            }
            for i in 0...routes.count - 1 {
                if i != routes.count - 1 {
                    draw3DLine(routes[i], routes[i + 1], orderIndex: 1, color: .green)
                } else {
                    self.arrowLoadMesh(routes[i])
                }
            }
        }
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

