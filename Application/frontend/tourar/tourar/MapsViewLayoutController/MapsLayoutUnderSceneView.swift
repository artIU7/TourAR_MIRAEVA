//
//  MapsLayoutUnderSceneView.swift
//  tourar
//
//  Created by Артем Стратиенко on 15.06.2024.
//

import UIKit
import Foundation
import CoreLocation
import SceneKit
import AVFoundation
import SnapKit
import YandexMapsMobile

var isLoadPoi = false

struct pointsSceneDynamics{
    var coordinate : CLLocationCoordinate2D
    var routeNode  : SCNNode!
    init()
    {
        // init struct
        coordinate = CLLocationCoordinate2D()
        routeNode  = nil
    }
}
struct positionNode{
    var startLine  : SCNVector3!
    var secondLine : SCNVector3!
    init()
    {
        startLine  = nil
        secondLine = nil
    }
}
struct linesSceneDynamics{
    var coordinate : positionNode
    var routeNode  : SCNNode!
    init()
    {
        // init struct
        coordinate = positionNode()
        routeNode  = nil
    }
}

class MapsLayoutUnderSceneView: UIViewController, YMKLayersGeoObjectTapListener, YMKMapInputListener,YMKUserLocationObjectListener, YMKMapCameraListener {
    // BUTTON IN
    // location zoom
    let locationButton = UIButton(type: .system)
    let arButton = UIButton(type: .system)
    //
    let socketConnection = WebSocketConnector(withSocketURL: URL(string: "ws://172.20.10.2:8080/echo")!)
    //
    // SceneKit scene
    var sceneView = SCNView()
    var scene: SCNScene!
    var cameraNode: SCNNode!
    var camera: SCNCamera!
    var playerNode: SCNNode!
    //
    var routeNode : SCNNode!
    var routePoint = [pointsSceneDynamics]()
    var routeLine =  [linesSceneDynamics]()
    var sceneRect: CGRect!
    //
    var isNavigationMode = false
    var drivingSession: YMKDrivingSession?
    var pedestrianSession : YMKMasstransitSession?
    var userLocation: YMKPoint?
    private var nativeLocationManager = CLLocationManager()
    
    var isPedestrianRoute = false

    
    let TARGET_LOCATION   = YMKPoint(latitude: 59.936760, longitude: 30.314673)
    var ROUTE_START_POINT = YMKPoint(latitude: 59.959194, longitude: 30.407094)
    var ROUTE_END_POINT   = YMKPoint(latitude: 55.733330, longitude: 37.587649)
    
    let controller = UIViewController()
    
    var tabBarTag: Bool = true
    
    lazy var mapView: YMKMapView = MapsViewBaseLayout().mapView

    override func viewDidLoad() {
        super.viewDidLoad()
        //
        self.title = "Маршруты"
        //
        view.addSubview(mapView)
        self.mapView.snp.makeConstraints { (marker) in
            marker.top.equalTo(self.view).inset(0)
            marker.left.right.equalTo(self.view).inset(0)
            marker.bottom.equalTo(self.view).inset(0)
        }
        configIULayoutUnderMap()
        // fix min and max zoom
        var map_fZoom = mapView.mapWindow.map
        map_fZoom.isZoomGesturesEnabled   = true
        map_fZoom.isTiltGesturesEnabled   = true
        map_fZoom.isRotateGesturesEnabled = true
        //
        mapView.mapWindow.map.move(
            with: YMKCameraPosition(target: TARGET_LOCATION, zoom: 15, azimuth: 0, tilt: 65),
            animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 1),
            cameraCallback: nil)
        
        // location manager
        if CLLocationManager.locationServicesEnabled() {
                   nativeLocationManager.delegate = self
                   nativeLocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                   nativeLocationManager.requestWhenInUseAuthorization()
                   nativeLocationManager.startUpdatingLocation()
               }
        self.startLocation()

        // add location service
        let scale = UIScreen.main.scale
        
        /* Disable mapkit location service
        let mapKit = YMKMapKit.sharedInstance()
        let userLocationLayer = mapKit.createUserLocationLayer(with: mapView.mapWindow)
        userLocationLayer.setVisibleWithOn(true)
        userLocationLayer.isHeadingEnabled = true
        userLocationLayer.setAnchorWithAnchorNormal(
            CGPoint(x: 0.5 * mapView.frame.size.width * scale, y: 0.5 * mapView.frame.size.height * scale),
            anchorCourse: CGPoint(x: 0.5 * mapView.frame.size.width * scale, y: 0.83 * mapView.frame.size.height * scale))
        userLocationLayer.setObjectListenerWith(self)
        */
        // подписываемся на собятия тапа / изменения позиции камеры / экрана
        mapView.mapWindow.map.addCameraListener(with: self)
        mapView.mapWindow.map.addTapListener(with: self)
        mapView.mapWindow.map.addInputListener(with: self)
        // add subview
        sceneView.isUserInteractionEnabled = false
        sceneView.backgroundColor = UIColor.clear
        
        view.addSubview(sceneView)
        setupSceneView()
        self.sceneView.snp.makeConstraints { (marker) in
            marker.top.equalTo(self.view).inset(0)
            marker.left.right.equalTo(self.view).inset(0)
            marker.bottom.equalTo(self.view).inset(0)
        }
        //
        let checkRemoteServer : UILabel = UILabel()
        checkRemoteServer.text = "server not connected"
        checkRemoteServer.textColor = UIColor.black
        view.addSubview(checkRemoteServer)
        checkRemoteServer.snp.makeConstraints { (marker) in
            marker.left.right.equalTo(self.view).inset(20)
            marker.bottom.equalTo(self.view).inset(20)
        }
        //
        if #available(iOS 15.0, *) {
            if let sheetController = controller.sheetPresentationController {
                sheetController.detents = [.medium()]
                //
            }
        } else {
            // Fallback on earlier versions
        }
        /*
        // set view circle
        var widthScene  = mapView.layer.bounds.width
        var heightScene = mapView.layer.bounds.height

        var radiusView = widthScene/2
        var newFrameMap  =  CGRect(
            x: widthScene/2  - radiusView/2 ,
            y: heightScene/2 - radiusView/2 ,
            width:  radiusView,//mapView.layer.bounds.width/2,
            height: radiusView)//mapView.layer.bounds.width/2);
        var newFrameScene  =  CGRect(
            x: widthScene/2  - radiusView + 40/2 ,
            y: heightScene/2 - radiusView + 40/2 ,
            width:  radiusView + 40,//mapView.layer.bounds.width/2,
            height: radiusView + 40)//mapView.layer.bounds.width/2);
        mapView.frame = newFrameMap
        mapView.layer.cornerRadius = mapView.frame.width/2
        mapView.clipsToBounds = true
        // Border styling
        mapView.layer.borderColor = UIColor.darkGray.cgColor
        mapView.layer.borderWidth = 2.0
        // test
        sceneView.frame = newFrameScene
         */
        // setup connection webSocket
        setupConnection()
        fetchAllDataPoint(cityName: "Volgograd")
        if ( isConnected )
        {
            checkRemoteServer.text = "server connected"
            checkRemoteServer.textColor = UIColor.red
        } else
        {
            checkRemoteServer.text = "server not connected"
            checkRemoteServer.textColor = UIColor.black
        }
        checkServerConnection(ip_server: "http://178.167.7.139:5500/")
    }
    func configIULayoutUnderMap(){
        // type routing
        let itemsSegment = ["Пешеходный","Транспортный"]
        var typeRouting = UISegmentedControl(items: itemsSegment)
        typeRouting.selectedSegmentIndex = 0
        typeRouting.layer.cornerRadius = 5.0
        typeRouting.tintColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        typeRouting.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        typeRouting.addTarget(self, action: #selector(self.changeRoteType), for: .valueChanged)
        view.addSubview(typeRouting)
        typeRouting.snp.makeConstraints { (marker) in
            marker.height.equalTo(40)
            marker.width.equalTo(80)
            marker.topMargin.equalToSuperview().inset(20)
            marker.left.right.equalToSuperview().inset(40)
        }
        // ar helper
        arButton.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        arButton.setTitleColor(.white, for: .normal)
        arButton.setTitle("AR", for: .normal)
        arButton.layer.cornerRadius = 15

        view.addSubview(arButton)
        arButton.snp.makeConstraints { (marker) in
            marker.topMargin.equalTo(typeRouting).inset(60)
            marker.rightMargin.equalToSuperview().inset(5)
            marker.width.equalTo(100)
            marker.height.equalTo(40)
        }
        arButton.addTarget(self, action: #selector(showARViewScene), for: .touchUpInside)
        // location
        locationButton.setImage(UIImage(named: "location_nf_x"), for: .normal)
        locationButton.tintColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        locationButton.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        locationButton.layer.cornerRadius = 5
        view.addSubview(locationButton)
        locationButton.addTarget(self, action: #selector(self.locationAction(_:)), for: .touchUpInside)
        locationButton.snp.makeConstraints { (marker) in
            marker.height.equalTo(42.5)
            marker.width.equalTo(42.5)
            marker.topMargin.equalTo(arButton).inset(100)
            marker.rightMargin.equalToSuperview().inset(5)
        }
    }
    
    @objc func changeRoteType( segment : UISegmentedControl)
    {
        print("Segment current type :\(segment.selectedSegmentIndex)")
        switch segment.selectedSegmentIndex {
        case 0:
            isPedestrianRoute = true
            // check route
            // add routing service
            if ( isPedestrianRoute )
            {
                mapView.mapWindow.map.mapObjects.clear()
                computedRoute()
            } else
            {
                mapView.mapWindow.map.mapObjects.clear()
                callRoutingResponse()
            }
        case 1:
            isPedestrianRoute = false
            // add routing service
            if ( isPedestrianRoute )
            {
                mapView.mapWindow.map.mapObjects.clear()
                computedRoute()
            } else
            {
                mapView.mapWindow.map.mapObjects.clear()
                callRoutingResponse()
            }
        default:
            isPedestrianRoute = true
            // add routing service
            if ( isPedestrianRoute )
            {
                mapView.mapWindow.map.mapObjects.clear()
                computedRoute()
            } else
            {
                mapView.mapWindow.map.mapObjects.clear()
                callRoutingResponse()
            }
        }
    }
    //
    func voiceHelperUI(textSpeech : String)
    {
        // добавляем озвучку перехода на главный таб бар
        let utterance = AVSpeechUtterance(string: "\(textSpeech)")
        // Configure the utterance.
        utterance.rate = 0.57
        utterance.pitchMultiplier = 0.8
        utterance.postUtteranceDelay = 0.2
        utterance.volume = 0.55
        // Retrieve the British English voice.
        let voice = AVSpeechSynthesisVoice(language: "ru-RU")
        // Assign the voice to the utterance.
        utterance.voice = voice
        // Create a speech synthesizer.
        let synthesizer = AVSpeechSynthesizer()
        // Tell the synthesizer to speak the utterance.
        synthesizer.speak(utterance)
    }
    // method action
    // arSceneCall
    @objc func showARViewScene(_ sender:UIButton)
    {
        let ARSceneViewController = ARSceneViewRouteController()//ScannerController()
        ARSceneViewController.modalPresentationStyle = .fullScreen
        ARSceneViewController.modalTransitionStyle = .crossDissolve
        show(ARSceneViewController, sender: self)
        voiceHelperUI(textSpeech:
                        "Запускаем экран дополненной реальности ...")
    }
    // location action
    @objc func locationAction(_ sender:UIButton) {
        if ( locationButton.imageView?.image == UIImage(named: "location_nf_x"))
        {
            locationButton.setImage(UIImage(named: "location_nf_y"), for: .normal)
            self.stopLocation()
        }
        else {
            locationButton.setImage(UIImage(named: "location_nf_x"), for: .normal)
            self.startLocation()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
          
           if tabBarTag == true {
            self.tabBarController?.tabBar.tintColor =  #colorLiteral(red: 0.3759136491, green: 0.6231091984, blue: 0.6783652551, alpha: 1)
            self.tabBarController?.tabBar.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
           } else {
               self.tabBarController?.tabBar.tintColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
           }
    }
    func onCameraPositionChanged(with map: YMKMap,
                                 cameraPosition: YMKCameraPosition,
                                 cameraUpdateReason: YMKCameraUpdateReason,
                                 finished: Bool) {
        if finished {
            if ( locationButton.imageView?.image == UIImage(named: "location_nf_y"))
            {
                self.stopLocation()
            }
        }
    }
    //
    func onObjectTap(with: YMKGeoObjectTapEvent) -> Bool {
        let event = with
        let metadata = event.geoObject.metadataContainer.getItemOf(YMKGeoObjectSelectionMetadata.self)
        if let selectionMetadata = metadata as? YMKGeoObjectSelectionMetadata {
            mapView.mapWindow.map.selectGeoObject(withObjectId: selectionMetadata.id, layerId: selectionMetadata.layerId)
            
            if #available(iOS 15.0, *) {
                if let sheetController = controller.sheetPresentationController {
                    sheetController.detents = [.medium()]
                    sheetController.prefersGrabberVisible = true
                    sheetController.preferredCornerRadius = 32
                }
            } else {
                // Fallback on earlier versions
            }
            controller.view.backgroundColor = UIColor.gray
            
            present(controller, animated: true)
            
            return true
        }
        return false
    }
    
    func onMapTap(with map: YMKMap, point: YMKPoint) {
        
        mapView.mapWindow.map.deselectGeoObject()
        print("TAP NOW")
        
        if isNavigationMode == false
        {
            isNavigationMode = true
            sceneView.isHidden = true;
        }
        else
        {
            isNavigationMode = false
            sceneView.isHidden = false;
        }
        print("Nav :\(isNavigationMode)")
        if ( !isLoadPoi )
        {
            if ( !poiPointArray.isEmpty )
            {
                for point in poiPointArray
                {
                    let mapObjects = mapView.mapWindow.map.mapObjects;
                    let placemark = mapObjects.addPlacemark(with: point)
                    placemark.setIconWith(UIImage(named: "SearchResult")!)
                }
                isLoadPoi = true
            }
        }
    }
    func onMapLongTap(with map: YMKMap, point: YMKPoint) {
        print("Point Selection Coordinate:\(point)")
        mapView.mapWindow.map.mapObjects.clear()
        //
        ROUTE_END_POINT =   YMKPoint(latitude: point.latitude,
                                     longitude: point.longitude)
        // add routing service
        if ( isPedestrianRoute )
        {
            computedRoute()
        } else
        {
            callRoutingResponse()
        }
    }
    // add custom icon location user
    func createLocationCircle(centr : YMKPoint ) {
        let mapObjects = mapView.mapWindow.map.mapObjects;
        let circle = mapObjects.addCircle(
            with: YMKCircle(center: centr, radius: 1),
            stroke: UIColor.black,
            strokeWidth: 2,
            fill: UIColor.red)
        circle.zIndex = 100
    }
    // user location method
    func onObjectAdded(with view: YMKUserLocationView) {
        
        view.arrow.setIconWith(UIImage(named:"UserArrow")!)
        let pinPlacemark = view.pin.useCompositeIcon()
        
        pinPlacemark.setIconWithName(
            "pin",
            image: UIImage(named:"SearchResult")!,
            style:YMKIconStyle(
                anchor: CGPoint(x: 0.5, y: 0.5) as NSValue,
                rotationType:YMKRotationType.rotate.rawValue as NSNumber,
                zIndex: 1,
                flat: true,
                visible: true,
                scale: 1,
                tappableArea: nil))
        view.accuracyCircle.fillColor = UIColor.gray.withAlphaComponent(0.45)
         
    }
    //
    func onObjectRemoved(with view: YMKUserLocationView) {}

    func onObjectUpdated(with view: YMKUserLocationView, event: YMKObjectEvent) {
    }
    //
    func setupSceneView() {
          sceneView.backgroundColor = UIColor.clear
          scene = SCNScene()
          sceneView.autoenablesDefaultLighting = true
          sceneView.scene = scene
          sceneView.delegate = self
          sceneView.loops = true
          sceneView.showsStatistics = true
          sceneView.isPlaying = true
          sceneRect = sceneView.bounds
          // camera
          cameraNode = SCNNode()
          camera = SCNCamera()
          cameraNode.camera = camera
          scene.rootNode.addChildNode(cameraNode)
          // player node
          playerNode = SCNNode()
          let playerScene = SCNScene(named: "tourist_prepare.scn")!
          let playerModelNode = playerScene.rootNode.childNode(withName: "scene",
                                                               recursively: false)!.childNode(withName: "Tourist",
                                                                                             recursively: false)!
        
          playerModelNode.scale = SCNVector3(30.0, 30.0, 30.0)
          playerNode.addChildNode(playerModelNode)
          scene.rootNode.addChildNode(playerNode)
          let rotateByNode = SCNAction.rotate(toAxisAngle: SCNVector4(0, 1, 0, 90), duration: 60.0)
          self.playerNode.runAction(rotateByNode)
      }
    func addRoutePointScene(index : Int, rPoint : YMKPoint)
    {
        var nameNodeScenePreload = String()
        // point route node
        var pointNode  = SCNNode()
        if ( index % 2 == 0)
        {
            nameNodeScenePreload = "poi.scn"
        }
        else
        {
            nameNodeScenePreload = "poi.scn"
        }
        let pointScene = SCNScene(named: nameNodeScenePreload)!
        let pointRootNode = pointScene.rootNode.childNodes.first!
        pointRootNode.scale = SCNVector3(10.0, 10.0, 10.0)
        pointRootNode.name  = "point_\(index)"
        // set color point route
        pointNode.addChildNode(pointRootNode)
        scene.rootNode.addChildNode(pointNode)
        // add to struct
        var structPoint = pointsSceneDynamics()
        structPoint.coordinate = CLLocationCoordinate2D(latitude: rPoint.latitude, longitude: rPoint.longitude)
        structPoint.routeNode = pointNode
        print("Point append : \(structPoint.routeNode)\n\(structPoint.coordinate)")
        routePoint.append(structPoint)
    }
    // add line beetween two position point
    func lineNode(_ startPosition : SCNVector3,_ endPosition : SCNVector3,_ index_1 : Int,_ index_2 : Int) {
        let line = SCNGeometry.line(from: startPosition, to: endPosition)
        let lineNode = SCNNode(geometry: line)
        //lineNode.scale = SCNVector3(25, 25, 25)
        lineNode.name = "line_\(index_1)_\(index_2)"
        lineNode.position = SCNVector3Zero
        scene.rootNode.addChildNode(lineNode)
        // add to struct
        var structLine = linesSceneDynamics()
        structLine.coordinate = positionNode()
        structLine.coordinate.startLine  = startPosition
        structLine.coordinate.secondLine = endPosition
        structLine.routeNode = lineNode
        print("Line append : \(structLine.routeNode)\n\(structLine.coordinate)")
        routeLine.append(structLine)
    }
}
// CLLocationManagerDelegate
extension MapsLayoutUnderSceneView: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = YMKPoint(latitude: locations.last!.coordinate.latitude, longitude: locations.last!.coordinate.longitude)
        ROUTE_START_POINT = userLocation!
        let userLocationString = "USER LOCATION:\(userLocation!.latitude) \(userLocation!.longitude)"
        if isNavigationMode == true
        {
            if ( isPedestrianRoute )
            {
                computedRoute()
            } else
            {
                callRoutingResponse()
            }
        }
        // send to server location
        print("SEND TO SERVER:\(userLocationString)")
        socketConnection.send(message: userLocationString)
        
        mapView.mapWindow.map.move(
            with: YMKCameraPosition(target: ROUTE_START_POINT, zoom: 15, azimuth: 0, tilt: 65.0),
            animationType: YMKAnimation(type: YMKAnimationType.linear, duration: 2),
            cameraCallback: nil)
         
        createLocationCircle(centr: YMKPoint(latitude: userLocation!.latitude, longitude: userLocation!.longitude))
    }
    // MARK 3
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
  //      print("magneticHeading \(newHeading.magneticHeading)")
    }
    // MARK 4
    func startLocation() {
        nativeLocationManager.startUpdatingLocation()
        nativeLocationManager.startUpdatingHeading()
    }
    // MARK 5
    func stopLocation() {
        nativeLocationManager.stopUpdatingLocation()
    }
}

extension MapsLayoutUnderSceneView : YMKMapObjectVisitor {
    
    func onPlacemarkVisited(withPlacemark placemark: YMKPlacemarkMapObject) {}
    
    func onPolylineVisited(withPolyline polyline: YMKPolylineMapObject) {
        print("POLYLINE TRAVERSE")
    }
    
    func onPolygonVisited(withPolygon polygon: YMKPolygonMapObject) {}
    
    func onCircleVisited(withCircle circle: YMKCircleMapObject) {}
    
    func onCollectionVisitStart(with collection: YMKMapObjectCollection) -> Bool {
        //
        print("START TRAVERSE")
        return true
    }
    
    func onCollectionVisitEnd(with collection: YMKMapObjectCollection) {
        //
        print("END TRAVERSE")
    }
    
    func onClusterizedCollectionVisitStart(with collection: YMKClusterizedPlacemarkCollection) -> Bool {
        //
        return false
    }
    
    func onClusterizedCollectionVisitEnd(with collection: YMKClusterizedPlacemarkCollection) {
        //
    }
}

extension MapsLayoutUnderSceneView : SCNSceneRendererDelegate {
    //
    func removePrepareNodeRoute()
    {
        scene!.rootNode.enumerateChildNodes { (node, stop) in
            if (node.name != nil)
            {
                if (node.name!.contains("point_")) || ( node.name!.contains("line_"))   {
                    node.removeFromParentNode()
                }
            }
        }
    }
    //
    func coordinateToOverlayPosition(coordinate: CLLocationCoordinate2D) -> SCNVector3 {
        //  update sceneRect Size
        sceneRect = sceneView.bounds

        var pointYKCoordinate : YMKScreenPoint? = nil
        var p: CGPoint = CGPoint()
        pointYKCoordinate = mapView.mapWindow.worldToScreen(withWorldPoint:
                                                                    YMKPoint(latitude : coordinate.latitude,
                                                                             longitude: coordinate.longitude))
        if pointYKCoordinate == nil {
            return SCNVector3()
        }
        p = CGPoint(x:  CGFloat(pointYKCoordinate!.x), y: CGFloat(pointYKCoordinate!.y))
        print("New Point:\(p)")
        print("scene rect size:\(sceneRect.size.height)")
        return SCNVector3Make(Float(p.x/2),  Float(sceneRect.size.height) - Float(p.y/2), 0)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
   
          // get pitch of map
        var map_ : YMKMap? = nil
        var mapPitchRads : Float = 0
        //  update sceneRect Size
        DispatchQueue.main.async {
            map_ =  self.mapView.mapWindow.map
            
            let zoom = map_!.cameraPosition.zoom
            if ( zoom > 10 )
            {
                //return
            }
            mapPitchRads = Float(map_!.cameraPosition.tilt) * (Float.pi / 180.0)
            print("current tilt :\(map_!.cameraPosition.tilt)")
            print("mapPitch :\(mapPitchRads)")
            // test coordinate
            //"55.89220431"
            //"37.54290942"
            // update player
            
            let playerPoint = self.coordinateToOverlayPosition(coordinate:
                                                            CLLocationCoordinate2D(
                                                            latitude:  self.ROUTE_START_POINT.latitude,
                                                            longitude: self.ROUTE_START_POINT.longitude))
             
            //let playerPoint = self.coordinateToOverlayPosition(coordinate:
            //                                                CLLocationCoordinate2D(
            //                                                latitude:  55.89220431,
            //                                                longitude: 37.54290942))
            print("Screen point:\(playerPoint)")
            let scaleMat = SCNMatrix4MakeScale(2.0, 2.0, 2.0)
            //
            let scaleMatLink = SCNMatrix4MakeScale(4.0, 4.0, 4.0)
            // update camera
            var metersPerPointFirst = 0.3348600676537076//viewMap.geoCenter.distance(to: viewMap.geoCenter)///metersPerPoint(atZoomLevel: Float(viewMap.zoomLevel))
            print("scene rect size(render proc):\(self.sceneRect.size.height)")
            self.playerNode.transform = SCNMatrix4Mult(scaleMat,
                                        SCNMatrix4Mult(SCNMatrix4MakeRotation(    -mapPitchRads, 0, 1, 0),
                                                       SCNMatrix4MakeTranslation( playerPoint.x, playerPoint.y, 0 )))
            // change position route node
            for point_s in self.routePoint
            {
                let routePoint = self.coordinateToOverlayPosition(coordinate:
                                                                CLLocationCoordinate2D(
                                                                    latitude:  point_s.coordinate.latitude,
                                                                    longitude: point_s.coordinate.longitude))
                print("Screen point:\(routePoint)")
                let scaleMat = SCNMatrix4MakeScale(2.0, 2.0, 2.0)
                //
                let scaleMatLink = SCNMatrix4MakeScale(4.0, 4.0, 4.0)
                // update camera
                //let metersPerPointFirst = //0.3348600676537076//viewMap.geoCenter.distance(to: viewMap.geoCenter)///metersPerPoint(atZoomLevel: Float(viewMap.zoomLevel))
                print("scene rect size(render proc):\(self.sceneRect.size.height)")
                point_s.routeNode.transform = SCNMatrix4Mult(scaleMat,
                                            SCNMatrix4Mult(SCNMatrix4MakeRotation(    -mapPitchRads, 1, 0, 0),
                                                           SCNMatrix4MakeTranslation( routePoint.x,
                                                                                      routePoint.y,
                                                                                      0 )))
            }
            
            //
            //for line_s in self.routeLine
            //{
            //}
            //
            
            print("meters point\(metersPerPointFirst)")
            let maps_t =  self.mapView.mapWindow.map
            print("All MAPS CHARACTERISTICS :\(maps_t)")
            print("Projection : \(maps_t.projection())")
            print("Camera pos - zoom : \(maps_t.cameraPosition.zoom)")
            print("Camera pos - azimuth : \(maps_t.cameraPosition.azimuth)")
            print("Camera pos - target : \(maps_t.cameraPosition.target.latitude)\n\(maps_t.cameraPosition.target.longitude)")
            print("Camera pos - scale factor : \( self.mapView.mapWindow.scaleFactor)")
            print("Camera pos - point of view : \( self.mapView.mapWindow.focusPoint)")

            let xxxx = maps_t.visibleRegion
            var xx1  = xxxx.topLeft
            var xx2  = xxxx.topRight
            var xx3  = xxxx.bottomLeft
            let dd1 = self.distanceGeo(pointA: CLLocationCoordinate2D(latitude: xx1.latitude, longitude: xx1.longitude), pointB: CLLocationCoordinate2D(latitude: xx2.latitude, longitude: xx2.longitude))
            let dd2 = self.distanceGeo(pointA: CLLocationCoordinate2D(latitude: xx1.latitude, longitude: xx1.longitude), pointB: CLLocationCoordinate2D(latitude: xx3.latitude, longitude: xx3.longitude))
            let Sm = dd1 * dd2
            let Spx = self.mapView.frame.height*self.mapView.frame.width
            metersPerPointFirst = sqrt(Sm)/sqrt(Spx)
            print("Camera pos - metersPerPointFirst calc : \(metersPerPointFirst)")
            let poinOfView =  self.mapView.mapWindow
            maps_t.isNightModeEnabled = true
            maps_t.cameraPosition
            poinOfView?.focusPoint
            var target = maps_t
            
            var pointYKCoordinate : YMKScreenPoint? = nil
            var p: CGPoint = CGPoint()
           // pointYKCoordinate = self.mapView.mapWindow.screenToWorld(with:  YMKPoint(latitude: //Double(self.mapView.mapWindow.focusPoint!.x), longitude: //Double(self.mapView.mapWindow.focusPoint!.y)))
            var point = self.mapView.mapWindow.map
            var altitude = poinOfView?.map.projection().worldToXY(withGeoPoint: maps_t.cameraPosition.target, zoom: Int(maps_t.cameraPosition.zoom))
            print("Projection points:\(altitude?.x)\n\(altitude?.y)")
            //getMap().getCameraPosition().getTarget();
            print("Camera pos - point of target : \( point)")

            let altitudePoints = 853.7030/metersPerPointFirst
            //distanceGeo(pointA: CLLocationCoordinate2D(latitude: maps_t.cameraPosition.target.latitude, longitude: maps_t.cameraPosition.target.longitude), pointB:  )//853.7030/metersPerPointFirst
            ///maps_t.cameraPosition.zoom*maps_t.cameraPosition.tilt//maps_t.cameraPosition.azimuth/maps_t.cameraPosition.target.latitude
            //altitude//853.7030533228752///*viewMap.geoCenter.altitude*/ viewMap.geoCenter.altitude / Float(metersPerPointFirst) as Float
            let projMat = GLKMatrix4MakeOrtho(0, Float(self.sceneRect.size.width),  // left, right
                                              0, Float(self.sceneRect.size.height), // bottom, top
                                              1, Float(altitudePoints + 100))         // zNear, zFar
            self.cameraNode.position = SCNVector3Make(0, 0, Float(altitudePoints))
            self.cameraNode.camera!.projectionTransform = SCNMatrix4FromGLKMatrix4(projMat)
            // print view info
            print("mapView.frame:\(self.mapView.frame)")
            print("mapView.bounds:\(self.mapView.bounds)")
        }
      }
    // Расчет расстояния между двумя точка геодезическими
    public func distanceGeo(pointA : CLLocationCoordinate2D,pointB : CLLocationCoordinate2D) -> Double {
        let toRad = Double.pi/180
        let radial = acos(sin(pointA.latitude*toRad)*sin(pointB.latitude*toRad) + cos(pointA.latitude*toRad)*cos(pointB.latitude*toRad)*cos((pointA.longitude - pointB.longitude)*toRad))
        let R = 6378.137//6371.11
        let D = (radial*R)*1000
        return D
    }
}
extension SCNGeometry {
    class func line(from vector1: SCNVector3, to vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
}

// conform websockets
extension MapsLayoutUnderSceneView {
    
    private func setupConnection(){
        
        socketConnection.establishConnection()
        
        /*
        socketConnection.didReceiveMessage = {[weak self] message in
            DispatchQueue.main.async {[weak self] in
                self?.messageLabel.text = message
            }
        }
        */
        
        socketConnection.didReceiveError = { error in
            //Handle error here
        }
        
        socketConnection.didOpenConnection = {
            //Connection opened
        }
        
        socketConnection.didCloseConnection = {
            // Connection closed
        }
        
        socketConnection.didReceiveData = { data in
            // Get your data here
        }
    }
}