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
import MultipeerConnectivity

class UserLocation : NSObject{
    var lat : Double
    var lon : Double
    init(lat : Double,lon : Double)
    {
        self.lat = lat
        self.lon = lon
    }
}
var isLoadAll = false
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
    
    var mapProvider: MCPeerID?

    //
    var routes = [SCNVector3]()
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
    let sharedLocation = UIButton(type: .system)

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
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }
        UIApplication.shared.isIdleTimerDisabled = true
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
    var multipeerSession: MultipeerSession!
    var labelConnected: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
        
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
        //
        // sharedLocation show
        sharedLocation.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        sharedLocation.setTitleColor(.white, for: .normal)
        sharedLocation.setTitle("Peer_to..", for: .normal)
        sharedLocation.layer.cornerRadius = 15

        view.addSubview(sharedLocation)
        sharedLocation.snp.makeConstraints { (marker) in
            marker.topMargin.equalTo(routeShow).inset(60)
            marker.rightMargin.equalToSuperview().inset(5)
            marker.width.equalTo(100)
            marker.height.equalTo(40)
        }
        sharedLocation.isHidden = true
        sharedLocation.addTarget(self, action: #selector(peerRouteButton), for: .touchUpInside)
        
        labelConnected  = UILabel()
        // status connected multi
        labelConnected.text = "Connected(share):"
        labelConnected.adjustsFontSizeToFitWidth = true
        labelConnected.adjustsFontForContentSizeCategory = true
        labelConnected.numberOfLines = 2
        labelConnected.textAlignment = .left
        labelConnected.font = UIFont.boldSystemFont(ofSize: 15)
        labelConnected.textColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        view.addSubview(labelConnected)

        labelConnected.snp.makeConstraints { (marker) in
            marker.bottomMargin.equalToSuperview().inset(20)
            marker.leftMargin.equalToSuperview().inset(10)
            marker.width.equalTo(self.view.frame.width)
            marker.height.equalTo(40)
        }
        
        self.restartSession()
        
        drawARRoute()
        //
        self.initTap()
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
    /// - Tag: ReceiveData
    func receivedData(_ data: Data, from peer: MCPeerID) {
        
        do {
            if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                // Run the session with the received world map.
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                
                // Remember who provided the map for showing UI feedback.
                mapProvider = peer
            }
            else
            if let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
                // Add anchor to the session, ARSCNView delegate adds visible content.
                sceneView.session.add(anchor: anchor)
            }
            else {
                print("unknown data recieved from \(peer)")
            }
        } catch {
            print("can't decode data recieved from \(peer)")
        }
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
            //sceneView.scene.rootNode.addChildNode(node)
            node.position = worldCoord
        }
    }
    func sharedSession()
    {
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            self.multipeerSession.sendToAllPeers(data)
        }
    }
    
    func sendLocationNode()
    {
        var routeAnchor : [ARAnchor] = []
        sceneView.scene.rootNode.childNodes.forEach { node in
            if ( node.name == "routeAR" )
            {
                let newAnchor = ARAnchor(name: "point", transform: node.simdTransform )
                routeAnchor.append(newAnchor)
            }
        }
        if ( !routeAnchor.isEmpty )
        {
            routeAnchor.forEach { anchor in
                guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true) else
                {
                    fatalError("can't encode anchor")
                }
                self.multipeerSession.sendToAllPeers(data)
            }
        }
        /*
        var senderLocation : [UserLocation] = []
        if ( !locationsPointAR.isEmpty )
        {
            locationsPointAR.forEach { location in
                senderLocation.append(UserLocation(lat: location.coordinate.latitude, lon: location.coordinate.longitude))
            }
        }
        print("Location point AR (count) : \(senderLocation.count)\nData:\(senderLocation)")
            // Send the anchor info to peers, so they can place the same content.

        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: locationsPointAR.first!, requiringSecureCoding: true) else
        {
            fatalError("can't encode anchor")
        }
        /*
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: locationsPointAR.first as Any, requiringSecureCoding: true)
                  else {  }
        */
         
        */
    }
    @objc func peerRouteButton(){
        sendLocationNode()
    }
    @objc func showRouteButton()
    {
        if ( routeShow.titleLabel?.text == "Маршрут")
        {
            sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                if ( node.name == "routeAR")
                {
                    node.isHidden = true
                }
                else if ( node.name == "direction")
                {
                    node.isHidden = false
                }
            }
            routeShow.setTitle("Указатель", for: .normal)
        }
        else
        {
            sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                if ( node.name == "routeAR")
                {
                    node.isHidden = false
                }
                else if ( node.name == "direction")
                {
                    node.isHidden = true
                }
            }
            routeShow.setTitle("Маршрут", for: .normal)
        }
        //sharedSession()
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
                isLoadAll = false
            case 1:
                isClassification = false
                isLoadAll = true
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
        routes = [SCNVector3]()
        if locationsPointAR != [] {
            for vector in locationsPointAR {
                let p1 = CLLocationCoordinate2D(latitude: startingLocation.coordinate.latitude,
                                                longitude: startingLocation.coordinate.longitude)
                let p2 = CLLocationCoordinate2D(latitude: vector.coordinate.latitude,
                                                longitude: vector.coordinate.longitude)
                let offset = offsetComplete(p1, p2)
                routes.append(SCNVector3(0 + offset[0], -1.65, 0 + offset[1] * -1))
            }
            for i in 0...routes.count - 1 {
                if i != routes.count - 1 {
                    draw3DLine(routes[i], routes[i + 1], orderIndex: 1, color: .green)
                    addLabel(routes[i], "⬆️", isCamera: true)
                } else {
                    self.arrowLoadMesh(routes[i])
                    addPlane(content: UIImage(named: "oct")!, place: SCNVector3(x: routes[i].x, y: routes[i].y + 1.2, z: routes[i].z))
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
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move around to map the environment, or wait to join a shared session."
            
        case .normal where !multipeerSession.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            message = "Connected with \(peerNames)."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            message = "Received map from \(mapProvider!.displayName)."
            
        case .limited(.relocalizing):
            message = "Resuming session — move to where you were when the session was interrupted."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        labelConnected.text = message
        labelConnected.isHidden = message.isEmpty
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
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if ( node.name == "routeAR" )
        {
            print("Anchor now :\(anchor.name) ::\(anchor.transform)" )
        }
        //if let name = anchor.name, name.hasPrefix("point") {
        //    node.addChildNode(self.createEarthShared())
        //}
    }
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // update scene Nodes
        let nodesUpdate = sceneView.scene.rootNode.childNodes
        for node in nodesUpdate {
            let distanceNode = SCNVector3(
                node.position.x - sceneView.pointOfView!.worldPosition.x,
                node.position.y - sceneView.pointOfView!.worldPosition.y,
                node.position.z - sceneView.pointOfView!.worldPosition.z)
            print("dist :: \(sceneView.pointOfView!.worldPosition)")
            print("dist :: \(distanceNode.length())")
            if ( node.name == "planeOctober" )
            {
                if distanceNode.length() > 10 {
                    print("distance more 10 m")
                    node.isHidden = true
                } else {
                    node.isHidden = false
                }
            }
        }
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

extension ARSceneViewRouteController {
    func addPlane(content : UIImage, place : SCNVector3){
               let plane = Plane(content : content, doubleSided: true, horizontal: true, plot: false)
                plane.position = place//SCNVector3(10, 0, 0)
                let yFreeConstraint = SCNBillboardConstraint()
                yFreeConstraint.freeAxes = [.Y] // optionally
                plane.constraints = [yFreeConstraint] // apply the constraint to the parent node
                plane.name = "planeOctober"
                self.sceneView.scene.rootNode.addChildNode(plane)
    }
}
//
class Plane: SCNNode{
    init(width: CGFloat = 3, height: CGFloat = 2, content: Any, doubleSided: Bool, horizontal: Bool, plot : Bool) {
        super.init()
        if plot == true {
            self.geometry = SCNPlane(width: width + 2, height: height + 1)
        } else {
            self.geometry = SCNPlane(width: width - 2, height: height - 1)
        }
        let material = SCNMaterial()
        if let colour = content as? UIColor{
            material.diffuse.contents = colour
        } else if let image = content as? UIImage{
            material.diffuse.contents = image
        }else{
            material.diffuse.contents = UIColor.cyan
        }
        if plot == true {
            self.geometry?.firstMaterial?.colorBufferWriteMask = .alpha
        } else {
            self.geometry?.firstMaterial = material
        }
        if doubleSided{
            material.isDoubleSided = true
        }
        if horizontal{
            self.transform = SCNMatrix4Mult(self.transform, SCNMatrix4MakeRotation(Float(Double.pi), 1, 0, 1))
            self.transform = SCNMatrix4Mult(self.transform, SCNMatrix4MakeRotation(-Float(Double.pi)/1.0, 1, 0, 1))
        }
    }
    required init?(coder aDecoder: NSCoder) { fatalError("Plane Node Coder Not Implemented") }
}
extension ARSceneViewRouteController {
    func initTap() {
         let tapRec = UITapGestureRecognizer(target: self,
                                             action: #selector(ARSceneViewRouteController.handleTap(rec:)))
         tapRec.numberOfTouchesRequired = 1
         self.sceneView.addGestureRecognizer(tapRec)
    }
     @objc func handleTap(rec: UITapGestureRecognizer){
        if rec.state == .ended {
            guard let hitTestResult = sceneView
                .hitTest(rec.location(in: sceneView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
                .first
                else { return }
            
            let anchor = ARAnchor(name: "point", transform: hitTestResult.worldTransform)
            sceneView.session.add(anchor: anchor)
        }
    }
}
