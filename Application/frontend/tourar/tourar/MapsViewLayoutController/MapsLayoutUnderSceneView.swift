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

struct RecomendedPoint{
    var name : String
    var desc : String
}
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
var isLoadPreloadSceneOnly : Bool = true

var mapsObjectPlaceMark : [YMKPlacemarkMapObject] = []


class MapsLayoutUnderSceneView: UIViewController, YMKLayersGeoObjectTapListener, YMKMapInputListener,YMKUserLocationObjectListener, YMKMapCameraListener {
    // var
    //
    let synthesizer = AVSpeechSynthesizer()
    // network manager
    var networkManager = NetworkManager()
    var isPreviusPointNotAccept : Bool = true
    var recomendedPoint : YMKPoint!
    var currentPlaceMarkFind : YMKPlacemarkMapObject!
    var viewRouteCreate : UIView!
    var viewNavigationStart : UIView!
    var buttonAcceptPoint   : UIButton!
    var buttonCanceledPoint : UIButton!
    var viewSubPoints : UIView!
    var buttonCreateRoute : UIButton!
    var buttonNavigationStart : UIButton!
    //
    // sceneKit preload data
    var sceneViewPreload = SCNView()
    var scenePreload: SCNScene!
    var cameraPreload: SCNCamera!
    var cameraNodePreload: SCNNode!
    var nodePreload = SCNNode()
    //
    var blurView = UIView()
    // global var polyline DrivingRouter
    var polyLineObjectDrivingRouter   : YMKPolylineMapObject? = nil
    // global var polyline PedestrianRoute
    var polyLineObjectPedestrianRoute : YMKPolylineMapObject? = nil
    // points selected to build ropute custom
    var requestPoints : [YMKRequestPoint] = []
    // color custom route
    var colorMainRouteDriving : UIColor!
    var colorMainRoutePedestrian : UIColor!
    var colorSubRouteCommon : UIColor = .white
    // polyline subRoute
    var polyLineSubRouteDriving    : YMKPolylineMapObject? = nil
    var polyLineSubRoutePedestrian : YMKPolylineMapObject? = nil
    // point for sub routing
    var requestPointsSubRoute      :  [YMKRequestPoint] = []
    // add objectListernerTapped Custom Marker
    var mapObjectTapListener: YMKMapObjectTapListener!
    var mapsObjectTapListener = [YMKMapObjectTapListener]()
    var mapsObjectRecomendedMark : [YMKPlacemarkMapObject] = []
    var mapsObjectRecomendedAccept : [YMKPlacemarkMapObject] = []
    var mapsObjectNumberPoint : [YMKPlacemarkMapObject] = []


    // BUTTON IN
    // location zoom
    let layerButton         = UIButton(type: .system)
    let plusZoomButton      = UIButton(type: .system)
    let minusZoomButton     = UIButton(type: .system)
    let locationButton      = UIButton(type: .system)
    
    let showPoiButton       = UIButton(type: .system)
    let drawRouteButton     = UIButton(type: .system)
    let resetPointsButton   = UIButton(type: .system)

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
    //
    var isPedestrianRoute = true
    //
    var ROUTE_START_POINT = YMKPoint(latitude: 59.959194, longitude: 30.407094)
    var ROUTE_END_POINT   = YMKPoint(latitude: 55.733330, longitude: 37.587649)
    //
    let controller = UIViewController()
    var tabBarTag: Bool = true
    
    lazy var mapView: YMKMapView = MapsViewBaseLayout().mapView
    var searchManager: YMKSearchManager?
    var searchSession: YMKSearchSession?
    
    //
    var currentMagneticHeading = CLHeading()

    override func viewDidLoad() {
        super.viewDidLoad()
        //
        self.title = "Маршруты"
        ///
        // preload data
        let manager = NetworkManager()
        manager.fetchAllDataPoint(cityName: "Moscow")
        //
        view.addSubview(mapView)
        self.mapView.snp.makeConstraints { (marker) in
            marker.top.equalTo(self.view).inset(0)
            marker.left.right.equalTo(self.view).inset(0)
            marker.bottom.equalTo(self.view).inset(0)
        }
        //
        configIULayoutUnderMap()
        setupPreloadScene()
        setupSceneView()
        // main scenView
        sceneView.isUserInteractionEnabled = false
        sceneView.backgroundColor = UIColor.clear
        view.addSubview(sceneView)
        self.sceneView.snp.makeConstraints { (marker) in
            marker.top.equalTo(self.view).inset(0)
            marker.left.right.equalTo(self.view).inset(0)
            marker.bottom.equalTo(self.view).inset(0)
        }
        //
        // add blur view
        let blurEffect = UIBlurEffect(style: .dark)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        blurView.snp.makeConstraints { (marker) in
        marker.top.equalTo(self.view).inset(0)
        marker.left.right.equalTo(self.view).inset(0)
        marker.bottom.equalTo(self.view).inset(0)
        }
        //
        // preload sceneView=====================================//
        sceneViewPreload.backgroundColor = .clear
        sceneViewPreload.isUserInteractionEnabled = false
        view.addSubview(sceneViewPreload)
        self.sceneViewPreload.snp.makeConstraints { (marker) in
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
        // fix min and max zoom
        var map_fZoom = mapView.mapWindow.map
        map_fZoom.isZoomGesturesEnabled   = true
        map_fZoom.isTiltGesturesEnabled   = true
        map_fZoom.isRotateGesturesEnabled = true
        // location manager
        if CLLocationManager.locationServicesEnabled() {
                   nativeLocationManager.delegate = self
                   nativeLocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                   nativeLocationManager.requestWhenInUseAuthorization()
                   nativeLocationManager.startUpdatingLocation()
                   nativeLocationManager.startUpdatingHeading()

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
        searchManager = YMKSearch.sharedInstance().createSearchManager(with: .combined)
        // setup connection webSocket
        setupConnection()
        if ( isConnected )
        {
            checkRemoteServer.text = "server connected"
            checkRemoteServer.textColor = UIColor.red
        } else
        {
            checkRemoteServer.text = "server not connected"
            checkRemoteServer.textColor = UIColor.black
        }
        //networkManager.checkServerConnection(ip_server: "http://178.167.7.139:5500/")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(15)) { [self] in
            sceneViewPreload.isHidden = true
            blurView.isHidden         = true
        }
    }
    func setupPreloadScene(){
        isLoadPreloadSceneOnly = true
        sceneViewPreload.backgroundColor = UIColor.clear
        //
        scenePreload = SCNScene()
        //scene.physicsWorld.gravity = SCNVector3(x: 0, y: 0, z: 0)
        sceneViewPreload.autoenablesDefaultLighting = true
        sceneViewPreload.scene = scenePreload
        sceneViewPreload.delegate = self
        sceneViewPreload.loops = true
        sceneViewPreload.showsStatistics = false
        sceneViewPreload.isPlaying = true
        // camera
        cameraNodePreload = SCNNode()
        cameraPreload = SCNCamera()
        cameraNodePreload.camera = cameraPreload
        cameraNodePreload.position = SCNVector3(x: 0, y: 5, z: 45)
        scenePreload.rootNode.addChildNode(cameraNodePreload)
        // player node
        nodePreload = SCNNode()
        let playerScene = SCNScene(named: "earth.scn")!
        let playerModelNode = playerScene.rootNode.childNodes.first!
        playerModelNode.scale = SCNVector3(0.55, 0.55, 0.55)
        playerModelNode.position = SCNVector3(x: 0, y: 5, z: 0)
        nodePreload.addChildNode(playerModelNode)
        nodePreload.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        nodePreload.physicsBody?.isAffectedByGravity = false
        scenePreload.rootNode.addChildNode(nodePreload)
        let rotateBy_s1 = SCNAction.rotate(toAxisAngle: SCNVector4(0, 1, 0, 90), duration: 60)
        /// use only this method for rotate around axis ||
        nodePreload.runAction(rotateBy_s1)
    }
    func configIULayoutUnderMap(){
        // type routing
        let itemsSegment = ["Пешеходный","Транспортный"]
        var typeRouting = UISegmentedControl(items: itemsSegment)
        typeRouting.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)], for: .selected)
        typeRouting.selectedSegmentIndex = 0
        typeRouting.layer.cornerRadius = 5.0
        typeRouting.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        typeRouting.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        
        typeRouting.addTarget(self, action: #selector(self.changeRoteType), for: .valueChanged)
        view.addSubview(typeRouting)
        typeRouting.snp.makeConstraints { (marker) in
            marker.height.equalTo(40)
            marker.width.equalTo(80)
            marker.topMargin.equalToSuperview().inset(20)
            marker.left.right.equalToSuperview().inset(40)
        }
        // viewNavigationMode
        viewNavigationStart = UIView(frame: CGRect(x: 0, y: self.view.frame.height/4, width: self.view.frame.width - 40, height: 100))
        viewNavigationStart.layer.backgroundColor  =  #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        viewNavigationStart.layer.cornerRadius = 10
        viewNavigationStart.layer.shadowColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        viewNavigationStart.layer.shadowRadius = 4
        view.addSubview(viewNavigationStart)
        viewNavigationStart.snp.makeConstraints { (marker) in
            marker.height.equalTo(60)
            marker.width.equalTo(self.view.frame.width - 40)
            marker.topMargin.equalTo(typeRouting).inset(60)
            marker.leftMargin.rightMargin.equalToSuperview().inset(10)
        }
        viewNavigationStart.isHidden = true
        //
        buttonNavigationStart = UIButton()
        // button continie
        buttonNavigationStart.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        buttonNavigationStart.setTitle("Начать", for: .normal)
        buttonNavigationStart.setTitleColor(#colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1), for: .normal)
        buttonNavigationStart.layer.cornerRadius = 10
        buttonNavigationStart.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        buttonNavigationStart.addTarget(self, action: #selector(self.navigationStart(_:)), for: .touchUpInside)
        viewNavigationStart.addSubview(buttonNavigationStart)
        buttonNavigationStart.snp.makeConstraints { (marker) in
            marker.bottom.top.equalToSuperview().inset(10)
            marker.left.equalToSuperview().inset(10)
            marker.height.equalTo(40)
            marker.width.equalTo(120)
        }
        // ar helper
        arButton.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        arButton.setTitleColor(#colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1), for: .normal)
        arButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        arButton.setTitle("AR", for: .normal)
        arButton.layer.cornerRadius = 5

        viewNavigationStart.addSubview(arButton)
        arButton.snp.makeConstraints { (marker) in
            marker.bottom.top.equalToSuperview().inset(10)
            marker.rightMargin.equalToSuperview().inset(10)
            marker.height.equalTo(40)
            marker.width.equalTo(80)
        }
        arButton.addTarget(self, action: #selector(showARViewScene), for: .touchUpInside)
        // layer button
        layerButton.setImage(UIImage(named: "layer_bt"), for: .normal)
        layerButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        layerButton.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        layerButton.layer.cornerRadius = 5
        view.addSubview(layerButton)
        layerButton.addTarget(self, action: #selector(self.layerAction(_:)), for: .touchUpInside)
        layerButton.snp.makeConstraints { (marker) in
            marker.height.equalTo(42.5)
            marker.width.equalTo(42.5)
            marker.topMargin.equalTo(arButton).inset(60)
            marker.rightMargin.equalToSuperview().inset(5)
        }
        // plusZoom button
        plusZoomButton.setImage(UIImage(named: "zoomPlus_bt"), for: .normal)
        plusZoomButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        plusZoomButton.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        plusZoomButton.layer.cornerRadius = 5
        view.addSubview(plusZoomButton)
        plusZoomButton.addTarget(self, action: #selector(self.zoomPlusAction(_:)), for: .touchUpInside)
        plusZoomButton.snp.makeConstraints { (marker) in
            marker.height.equalTo(42.5)
            marker.width.equalTo(42.5)
            marker.topMargin.equalTo(layerButton).inset(100)
            marker.rightMargin.equalToSuperview().inset(5)
        }
        // minusZoom button
        minusZoomButton.setImage(UIImage(named: "zoomMinus_bt"), for: .normal)
        minusZoomButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        minusZoomButton.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        minusZoomButton.layer.cornerRadius = 5
        view.addSubview(minusZoomButton)
        minusZoomButton.addTarget(self, action: #selector(self.zoomMinusAction(_:)), for: .touchUpInside)
        minusZoomButton.snp.makeConstraints { (marker) in
            marker.height.equalTo(42.5)
            marker.width.equalTo(42.5)
            marker.topMargin.equalTo(plusZoomButton).inset(40)
            marker.rightMargin.equalToSuperview().inset(5)
        }
        //
        // location
        locationButton.setImage(UIImage(named: "location_on"), for: .normal)
        locationButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        locationButton.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        locationButton.layer.cornerRadius = 5
        view.addSubview(locationButton)
        locationButton.addTarget(self, action: #selector(self.locationAction(_:)), for: .touchUpInside)
        locationButton.snp.makeConstraints { (marker) in
            marker.height.equalTo(42.5)
            marker.width.equalTo(42.5)
            marker.topMargin.equalTo(minusZoomButton).inset(60)
            marker.rightMargin.equalToSuperview().inset(5)
        }
        // showPoint
        showPoiButton.setImage(UIImage(named: "poi_show_on"), for: .normal)
        showPoiButton.isEnabled = false
        showPoiButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        showPoiButton.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        showPoiButton.layer.cornerRadius = 5
        view.addSubview(showPoiButton)
        showPoiButton.addTarget(self, action: #selector(self.showPoiAction(_:)), for: .touchUpInside)
        showPoiButton.snp.makeConstraints { (marker) in
            marker.height.equalTo(42.5)
            marker.width.equalTo(42.5)
            marker.topMargin.equalTo(locationButton).inset(100)
            marker.rightMargin.equalToSuperview().inset(5)
        }
        // drawRouteButton
        drawRouteButton.setImage(UIImage(named: "route_show_on"), for: .normal)
        drawRouteButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        drawRouteButton.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        drawRouteButton.layer.cornerRadius = 5
        view.addSubview(drawRouteButton)
        drawRouteButton.addTarget(self, action: #selector(self.drawRouteAction(_:)), for: .touchUpInside)
        drawRouteButton.snp.makeConstraints { (marker) in
            marker.height.equalTo(42.5)
            marker.width.equalTo(42.5)
            marker.topMargin.equalTo(showPoiButton).inset(100)
            marker.rightMargin.equalToSuperview().inset(5)
        }
        drawRouteButton.isHidden = true
        viewRouteCreate = UIView(frame: CGRect(x: 0, y: self.view.frame.height/4, width: self.view.frame.width - 40, height: 100))
        viewRouteCreate.layer.backgroundColor  =  #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        viewRouteCreate.layer.cornerRadius = 10
        viewRouteCreate.layer.shadowColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        viewRouteCreate.layer.shadowRadius = 4
        view.addSubview(viewRouteCreate)
        viewRouteCreate.snp.makeConstraints { (marker) in
            marker.height.equalTo(100)
            marker.width.equalTo(self.view.frame.width - 40)
            marker.bottomMargin.equalToSuperview().inset(10)
            marker.rightMargin.leftMargin.equalToSuperview().inset(0)
            marker.centerX.equalToSuperview()
        }
        viewRouteCreate.isHidden = true
        //
        buttonCreateRoute = UIButton()
        // button continie
        buttonCreateRoute.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        buttonCreateRoute.setTitle("Построить маршрут", for: .normal)
        buttonCreateRoute.setTitleColor(#colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1), for: .normal)
        buttonCreateRoute.layer.cornerRadius = 10
        buttonCreateRoute.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        buttonCreateRoute.addTarget(self, action: #selector(self.routeDrawAction(_:)), for: .touchUpInside)
        viewRouteCreate.addSubview(buttonCreateRoute)
        buttonCreateRoute.snp.makeConstraints { (marker) in
            marker.bottom.equalToSuperview().inset(20)
            marker.centerX.equalToSuperview()
            marker.left.right.equalToSuperview().inset(30)
            marker.height.equalTo(50)
        }
        // add sub panel point
        // viewSubPoints
        viewSubPoints = UIView(frame: CGRect(x: 0, y: self.view.frame.height/4, width: self.view.frame.width - 40, height: 100))
        viewSubPoints.layer.backgroundColor  =  #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        viewSubPoints.layer.cornerRadius = 10
        viewSubPoints.layer.shadowColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        viewSubPoints.layer.shadowRadius = 4
        view.addSubview(viewSubPoints)
        viewSubPoints.snp.makeConstraints { (marker) in
            marker.height.equalTo(60)
            marker.width.equalTo(self.view.frame.width - 40)
            marker.bottomMargin.equalToSuperview().inset(60)
            marker.leftMargin.equalToSuperview().inset(10)
        }
        viewSubPoints.isHidden = true
        //
        buttonAcceptPoint = UIButton()
        // button continie
        buttonAcceptPoint.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        buttonAcceptPoint.setTitle("Принять", for: .normal)
        buttonAcceptPoint.setTitleColor(#colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1), for: .normal)
        buttonAcceptPoint.layer.cornerRadius = 10
        buttonAcceptPoint.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        buttonAcceptPoint.addTarget(self, action: #selector(self.buttonAcceptAction(_:)), for: .touchUpInside)
        viewSubPoints.addSubview(buttonAcceptPoint)
        buttonAcceptPoint.snp.makeConstraints { (marker) in
            marker.bottom.top.equalToSuperview().inset(10)
            marker.left.equalToSuperview().inset(20)
            marker.height.equalTo(40)
            marker.width.equalTo(120)
        }
        //
        buttonCanceledPoint = UIButton()
        // button continie
        buttonCanceledPoint.backgroundColor = #colorLiteral(red: 0.8665164076, green: 0.2626616855, blue: 0.1656771706, alpha: 1)
        buttonCanceledPoint.setTitle("Отменить", for: .normal)
        buttonCanceledPoint.setTitleColor(#colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1), for: .normal)
        buttonCanceledPoint.layer.cornerRadius = 10
        buttonCanceledPoint.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        buttonCanceledPoint.addTarget(self, action: #selector(self.buttonCanceledAction(_:)), for: .touchUpInside)
        viewSubPoints.addSubview(buttonCanceledPoint)
        buttonCanceledPoint.snp.makeConstraints { (marker) in
            marker.bottom.top.equalToSuperview().inset(10)
            marker.rightMargin.equalToSuperview().inset(20)
            marker.height.equalTo(40)
            marker.width.equalTo(120)
        }
    }
    @objc func buttonAcceptAction( _ sender:UIButton )
    {
        isPreviusPointNotAccept = true
        viewSubPoints.isHidden = true
        clearMapObjectSubRouting()
        requestPointsSubRoute.removeAll()
        // add to main instance polyline
        requestPoints.insert(YMKRequestPoint(point: recomendedPoint, type: .viapoint, pointContext: nil), at: 1)
        //
        // grebuild new route
        clearMapObjectRoutingType()
        locationsPointAR.removeAll()
        removePrepareNodeRoute()
        if ( isPedestrianRoute )
        {
            callPedestrianRoutingResponse(isTypeSender: false)
        } else
        {
            callDrivingRoutingResponse(isTypeSender: false)
        }
        mapsObjectRecomendedAccept.append(currentPlaceMarkFind)
    }
    @objc func buttonCanceledAction( _ sender:UIButton )
    {
        isPreviusPointNotAccept = true
        viewSubPoints.isHidden = true
        clearMapObjectSubRouting()
        requestPointsSubRoute.removeAll()
        //
        var idx = 0
        var delIndex = -1
        for place in mapsObjectRecomendedMark
        {
            let dataRec = currentPlaceMarkFind.userData as? RecomendedPoint
            let dataObj = place.userData as? RecomendedPoint
            if ( dataRec != nil && dataObj != nil )
            {
                if (dataRec?.name == dataObj?.name )
                {
                    delIndex = idx
                }
                idx+=1
            }
        }
        if ( delIndex != -1)
        {
            mapsObjectRecomendedMark[delIndex].isVisible = false
        }
        mapsObjectRecomendedAccept.append(currentPlaceMarkFind)
    }
    // method Draw PlaceMark Poi Point
    func drawFromFetchDataPoint()
    {
        var isFinishRequedt = true
        if ( isFinishRequedt )
        //if ( networkManager.stateSessionComplete() )
        {
            if ( !fetchDataLocationPoi.isEmpty )
            {
                // temp test poi
                fetchDataLocationPoi["test::uuid"] = YMKPoint(latitude: 55.789969, longitude: 38.442341)
                fetchDataDescriptionPoi["test::uuid"] = "КЦ Октябрь в городе Электросталь"
                fetchDataImagesPoi["test::uuid"]      = fetchDataImagesPoi.first?.value
                fetchDataTitlePoi["test::uuid"]       = "КЦ Октябрь"
                fetchDataAudioPoi["test::uuid"]       = fetchDataAudioPoi.first?.value
                // 55.783287, 38.445399
                fetchDataLocationPoi["test::1"] = YMKPoint(latitude: 55.783287, longitude: 38.445399)
                fetchDataDescriptionPoi["test::1"] = "ДС Кристалл в городе Электросталь"
                fetchDataImagesPoi["test::1"]      = fetchDataImagesPoi.first?.value
                fetchDataTitlePoi["test::1"]       = "ДС Кристалл"
                fetchDataAudioPoi["test::1"]       = fetchDataAudioPoi.first?.value
                // 55.783615, 38.438821
                fetchDataLocationPoi["test::2"] = YMKPoint(latitude: 55.783615, longitude: 38.438821)
                fetchDataDescriptionPoi["test::2"] = "Историко-художественный музей в городе Электросталь"
                fetchDataImagesPoi["test::2"]      = fetchDataImagesPoi.first?.value
                fetchDataTitlePoi["test::2"]       = "Историко-художественный музей"
                fetchDataAudioPoi["test::2"]       = fetchDataAudioPoi.first?.value
                // 55.789083, 38.426169
                fetchDataLocationPoi["test::3"] = YMKPoint(latitude: 55.789083, longitude: 38.426169)
                fetchDataDescriptionPoi["test::3"] = "Парк Авангад в городе Электросталь"
                fetchDataImagesPoi["test::3"]      = fetchDataImagesPoi.first?.value
                fetchDataTitlePoi["test::3"]       = "Парк Авангард"
                fetchDataAudioPoi["test::3"]       = fetchDataAudioPoi.first?.value
                // школа исскуств 55.790842, 38.433057
                fetchDataLocationPoi["test::4"] = YMKPoint(latitude: 55.790842, longitude: 38.433057)
                fetchDataDescriptionPoi["test::4"] = "Школа Искусств в городе Электросталь"
                fetchDataImagesPoi["test::4"]      = fetchDataImagesPoi.first?.value
                fetchDataTitlePoi["test::4"]       = "Школа Искусств"
                fetchDataAudioPoi["test::4"]       = fetchDataAudioPoi.first?.value
                // школа исскуств 55.790498, 38.432228
                fetchDataLocationPoi["test::5"] = YMKPoint(latitude: 55.790498, longitude: 38.432228)
                fetchDataDescriptionPoi["test::5"] = "Дом Дарьи Макаровой в городе Электросталь"
                fetchDataImagesPoi["test::5"]      = fetchDataImagesPoi.first?.value
                fetchDataTitlePoi["test::5"]       = "Дом Дарьи Макаровой"
                fetchDataAudioPoi["test::5"]       = fetchDataAudioPoi.first?.value
                // 55.790922, 38.430841
                fetchDataLocationPoi["test::5"] = YMKPoint(latitude: 55.790922, longitude: 38.430841)
                fetchDataDescriptionPoi["test::6"] = "Угол на Советской в городе Электросталь"
                fetchDataImagesPoi["test::6"]      = fetchDataImagesPoi.first?.value
                fetchDataTitlePoi["test::6"]       = "Угол на Советской"
                fetchDataAudioPoi["test::6"]       = fetchDataAudioPoi.first?.value
                for point in fetchDataLocationPoi
                {
                    if ( !fetchDataDescriptionPoi.isEmpty && !fetchDataImagesPoi.isEmpty &&  !fetchDataTitlePoi.isEmpty && !fetchDataAudioPoi.isEmpty )
                    {
                         
                         if ( fetchDataDescriptionPoi[point.key] != nil &&
                              fetchDataImagesPoi[point.key] != nil &&
                              fetchDataTitlePoi[point.key] != nil &&
                              fetchDataAudioPoi[point.key] != nil
                            )
                            {
                                let mapObjects = mapView.mapWindow.map.mapObjects;
                                let placemark = mapObjects.addPlacemark(with: point.value)
                                placemark.setIconWith(UIImage(named: "custom_point")!)
                                // input placeMark
                                placemark.userData = MapObjectTappedUserData(id: Int32.random(in: 0...10000) ,
                                                                             title:  fetchDataTitlePoi[point.key]!,
                                                                             description: fetchDataDescriptionPoi[point.key]!,
                                                                             point: point.value,
                                                                             image: fetchDataImagesPoi[point.key]!,
                                                                             audio: fetchDataAudioPoi[point.key]! ,
                                                                             group_1: true,
                                                                             group_2: true,
                                                                             group_3: false)
                                // Client code must retain strong reference to the listener.
                                mapObjectTapListener = MapsLayoutTappedObject(controller: self)
                                mapsObjectTapListener.append(mapObjectTapListener)
                                placemark.addTapListener(with: mapsObjectTapListener.last!)
                                mapsObjectPlaceMark.append(placemark)
                         }
                    }
                }
            }
        }
    }
    // helper method + clear subrouting
    func clearMapObjectSubRouting(){
        if ( polyLineSubRouteDriving != nil )
        {
            mapView.mapWindow.map.mapObjects.remove(with: polyLineSubRouteDriving!)
            polyLineSubRouteDriving = nil
        }
        if ( polyLineSubRoutePedestrian != nil )
        {
            mapView.mapWindow.map.mapObjects.remove(with: polyLineSubRoutePedestrian!)
            polyLineSubRoutePedestrian = nil
        }
    }
    // method Helper + Clear Map Routing
    func clearMapObjectRoutingType()
    {
            if ( polyLineObjectDrivingRouter != nil )
            {
                mapView.mapWindow.map.mapObjects.remove(with: polyLineObjectDrivingRouter!)
                polyLineObjectDrivingRouter = nil
            }

            if ( polyLineObjectPedestrianRoute != nil )
            {
                mapView.mapWindow.map.mapObjects.remove(with: polyLineObjectPedestrianRoute!)
                polyLineObjectPedestrianRoute = nil
            }
    }
    @objc func navigationStart(_ sender : UIButton )
    {
        if ( sender.titleLabel?.text == "Начать")
        {
            isNavigationMode = true
            buttonNavigationStart.setTitle("Завершить", for: .normal)
            viewRouteCreate.isHidden = true
        }
        else
        {
            isNavigationMode = false
            buttonNavigationStart.setTitle("Начать", for: .normal)
            viewRouteCreate.isHidden = false
        }
    }
    @objc func layerAction(_ sender:UIButton)
    {
        let layerController = LayerViewController()
        layerController.modalPresentationStyle = .formSheet
        //layerController.modalTransitionStyle = .crossDissolve
        show(layerController, sender: self)
        //present(layerController, animated: true, completion: nil)
    }
    @objc func zoomPlusAction(_ sender:UIButton)
    {
        var maps = mapView.mapWindow.map
        let zoom = maps.cameraPosition.zoom + 0.2
        maps.move(with: YMKCameraPosition(target: maps.cameraPosition.target, zoom: zoom, azimuth: maps.cameraPosition.azimuth, tilt: maps.cameraPosition.tilt))
    }
    @objc func zoomMinusAction(_ sender:UIButton)
    {
        var maps = mapView.mapWindow.map
        let zoom = maps.cameraPosition.zoom - 0.2
        maps.move(with: YMKCameraPosition(target: maps.cameraPosition.target, zoom: zoom, azimuth: maps.cameraPosition.azimuth, tilt: maps.cameraPosition.tilt))    }
    @objc func showPoiAction(_ sender:UIButton)
    {
        if ( sender.imageView?.image == UIImage(named: "poi_show_on"))
        {
            sender.setImage(UIImage(named: "poi_show_off"), for: .normal)
            // check append before already append
                if ( mapsObjectPlaceMark.isEmpty )
                {
                    self.drawFromFetchDataPoint()
                }
        }
        else {
            sender.setImage(UIImage(named: "poi_show_on"), for: .normal)
            mapsObjectPlaceMark.forEach { object in
                mapView.mapWindow.map.mapObjects.remove(with: object)
            }
            mapsObjectPlaceMark.removeAll()
        }
    }
    func clearSelectedPointOnMap(){
        for pp in requestPoints {
            for plm in mapsObjectPlaceMark
            {
                var llm = plm.userData as? MapObjectTappedUserData
                
                if (pp.point == llm?.point )
                {
                    plm.setIconWith(UIImage(named: "custom_point")!)
                }
            }
        }
    }
    @objc func routeDrawAction(_ sender : UIButton )
    {
        if ( requestPoints.isEmpty ) {
            return
        }
        //
        if ( sender.titleLabel?.text == "Построить маршрут")
        {
            sender.setTitle("Сбросить маршрут", for: .normal)
            sender.backgroundColor = #colorLiteral(red: 0.8665164076, green: 0.2626616855, blue: 0.1656771706, alpha: 1)
            //
            clearMapObjectRoutingType()
            locationsPointAR.removeAll()
            removePrepareNodeRoute()
            if ( isPedestrianRoute )
            {
                callPedestrianRoutingResponse(isTypeSender: false)
            } else
            {
                callDrivingRoutingResponse(isTypeSender : false)
            }
            viewNavigationStart.isHidden = false
        }
        else {
            sender.setTitle("Построить маршрут", for: .normal)
            sender.backgroundColor = .white
            //
            clearSelectedPointOnMap()
            clearMapObjectRoutingType()
            requestPoints.removeAll()
            locationsPointAR.removeAll()
            removePrepareNodeRoute()
            viewRouteCreate.isHidden = true
            viewNavigationStart.isHidden = true
            // sub point
            mapsObjectRecomendedMark.removeAll()
            clearMapObjectSubRouting()
            mapsObjectRecomendedAccept.removeAll()
            //
            if ( currentPlaceMarkFind != nil )
            {
                currentPlaceMarkFind.isVisible = false
                currentPlaceMarkFind = nil
            }
            if ( !mapsObjectNumberPoint.isEmpty )
            {
                mapsObjectNumberPoint.forEach { object in
                    mapView.mapWindow.map.mapObjects.remove(with: object)
                }
                mapsObjectNumberPoint.removeAll()
            }
        }
    }
    @objc func drawRouteAction(_ sender:UIButton)
    {
        if ( requestPoints.isEmpty ) {
            return
        }
        if ( sender.imageView?.image == UIImage(named: "route_show_on"))
        {
            sender.setImage(UIImage(named: "route_show_off"), for: .normal)
            sender.tintColor = #colorLiteral(red: 0.4392156899, green: 0.01176470611, blue: 0.1921568662, alpha: 1)
            sender.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
            //
            clearMapObjectRoutingType()
            locationsPointAR.removeAll()
            removePrepareNodeRoute()
            if ( isPedestrianRoute )
            {
                callPedestrianRoutingResponse(isTypeSender: false)
            } else
            {
                callDrivingRoutingResponse(isTypeSender: false)
            }
        }
        else {
            sender.setImage(UIImage(named: "route_show_on"), for: .normal)
            sender.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            sender.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
            //
            clearMapObjectRoutingType()
            requestPoints.removeAll()
            removePrepareNodeRoute()
        }
    }
    @objc func changeRoteType( segment : UISegmentedControl)
    {
        print("Segment current type :\(segment.selectedSegmentIndex)")
        switch segment.selectedSegmentIndex {
        case 0:
            // set Pedestrian Type
            isPedestrianRoute = true
            clearMapObjectRoutingType()
            locationsPointAR.removeAll()
            removePrepareNodeRoute()
            callPedestrianRoutingResponse(isTypeSender: false)
        case 1:
            // set Driving Type
            isPedestrianRoute = false
            clearMapObjectRoutingType()
            locationsPointAR.removeAll()
            callDrivingRoutingResponse(isTypeSender: false)
        default:
            // set Pedestrian Type
            isPedestrianRoute = true
            clearMapObjectRoutingType()
            locationsPointAR.removeAll()
            removePrepareNodeRoute()
            callPedestrianRoutingResponse(isTypeSender: false)
        }
    }
    //
    func voiceHelperUI(textSpeech : String)
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
        // Create a speech synthesizer.
        // Tell the synthesizer to speak the utterance.
        if ( synthesizer.isSpeaking )
        {
        } else
        {
            synthesizer.speak(utterance)
        }
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
        if ( locationButton.imageView?.image == UIImage(named: "location_on"))
        {
            locationButton.setImage(UIImage(named: "location_off"), for: .normal)
            self.stopLocation()
        }
        else {
            locationButton.setImage(UIImage(named: "location_on"), for: .normal)
            self.startLocation()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
          
           if tabBarTag == true {
            self.tabBarController?.tabBar.tintColor =  #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            self.tabBarController?.tabBar.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
           } else
                {
                    self.tabBarController?.tabBar.tintColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
                }
    }
    func onCameraPositionChanged(with map: YMKMap,
                                 cameraPosition: YMKCameraPosition,
                                 cameraUpdateReason: YMKCameraUpdateReason,
                                 finished: Bool) {
        if finished {
            if ( !isNavigationMode )
            {
                //if ( locationButton.imageView?.image == UIImage(named: "location_on"))
                //{
                //    self.stopLocation()
                //    locationButton.setImage(UIImage(named: "location_off"), for: .normal)
                //}
            }
            
            if ( isNavigationMode )
            {
                // search near my location point poi
                let responseHandler = {(searchResponse: YMKSearchResponse?, error: Error?) -> Void in
                    if let response = searchResponse {
                        self.onSearchResponse(response)
                    } else {
                        self.onSearchError(error!)
                    }
                }
               
                    searchSession = searchManager!.submit(
                        withText: "cafe",
                        geometry: YMKVisibleRegionUtils.toPolygon(with: map.visibleRegion),
                        searchOptions: YMKSearchOptions(),
                        responseHandler: responseHandler)
            }
        }
    }
    //
    func findNearPointOnRoute(pointNear : YMKPoint)->Double{
        
        
        let distanceFromLocation = distanceGeo(pointA: CLLocationCoordinate2D(latitude: (requestPoints.first?.point.latitude)! ,longitude: (requestPoints.first?.point.longitude)!),
                                               pointB: CLLocationCoordinate2D(latitude: pointNear.latitude, longitude: pointNear.longitude))
        return distanceFromLocation
    }
    //
    func onSearchResponse(_ response: YMKSearchResponse) {
        
        let mapObjects = mapView.mapWindow.map.mapObjects
        func searchPlacemarkTemp(name : String ) -> Bool
        {
            var isFind = false
            if ( !mapsObjectRecomendedMark.isEmpty )
            {
                mapsObjectRecomendedMark.forEach { mark in
                    var useData = mark.userData as? RecomendedPoint
                    if ( useData != nil )
                    {
                        if ( useData!.name == name )
                        {
                            isFind = true
                        }
                    }
                }
            }
            return isFind
        }
        for searchResult in response.collection.children {
            if let point = searchResult.obj?.geometry.first?.point
            {
                if ( !searchPlacemarkTemp(name: (searchResult.obj?.name)!))
                {
                    let placemark = mapObjects.addPlacemark(with: point)
                    placemark.setIconWith(UIImage(named: "SearchResult")!)
                    placemark.isVisible = false
                    placemark.userData = RecomendedPoint(name:                     (searchResult.obj?.name)!, desc:                     searchResult.obj!.description)
                    mapsObjectRecomendedMark.append(placemark)
                }
            }
        }
        func isPointRecomendedAlready(recomendedPoint : YMKPlacemarkMapObject)->Bool
        {
            var isRecomende = false
            if ( !mapsObjectRecomendedAccept.isEmpty)
            {
                mapsObjectRecomendedAccept.forEach { recomende in
                    let dataRec = recomende.userData as? RecomendedPoint
                    let dataObj = recomendedPoint.userData as? RecomendedPoint
                    if ( dataRec != nil && dataObj != nil )
                    {
                        if (dataRec?.name == dataObj?.name )
                        {
                            isRecomende = true
                        }
                    }
                }
            }
            return isRecomende
        }
        if ( isPreviusPointNotAccept )
        {
            isPreviusPointNotAccept = false
            var arrayDistance : [Double] = []
            mapsObjectRecomendedMark.forEach { mark in
                let distancePoi = findNearPointOnRoute(pointNear: mark.geometry )
                arrayDistance.append(distancePoi)
            }
                var indexMinNearPoi = -1
                var i = 0
                for item in arrayDistance{
                    if ( item == arrayDistance.min())
                    {
                        indexMinNearPoi = i
                    }
                    i+=1
                }
                if ( indexMinNearPoi != -1)
                {
                    if ( requestPoints.count >= 2 )
                    {
                        if ( !isPointRecomendedAlready(recomendedPoint: mapsObjectRecomendedMark[indexMinNearPoi]))
                        {
                            mapsObjectRecomendedMark[indexMinNearPoi].isVisible = true
                            recomendedPoint = mapsObjectRecomendedMark[indexMinNearPoi].geometry
                            currentPlaceMarkFind = mapsObjectRecomendedMark[indexMinNearPoi]
                            /*
                            let alert = UIAlertController(title: "Внимание! Найдено кафе поблизости", message: "Добавляем точку к маршруту ?\nРасстояние \(arrayDistance.min()) метров", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            present(alert, animated: true, completion: nil)
                            */
                            let dataPoi = currentPlaceMarkFind.userData as? RecomendedPoint
                            if ( dataPoi != nil )
                            {
                                voiceHelperUI(textSpeech: "Внимание!!! На маршруте обнаружена точка - Кафе\(dataPoi!.name).")
                            }
                            //
                            requestPointsSubRoute.append(requestPoints[0])
                            requestPointsSubRoute.append(YMKRequestPoint(point:   mapsObjectRecomendedMark[indexMinNearPoi].geometry, type: .viapoint, pointContext: nil))
                            requestPointsSubRoute.append(requestPoints[1])
                            //
                            // grebuild new route
                            clearMapObjectSubRouting()
                            
                            if ( isPedestrianRoute )
                            {
                                callPedestrianRoutingResponse(isTypeSender: true)
                            } else
                            {
                                callDrivingRoutingResponse(isTypeSender: true)
                            }
                            viewSubPoints.isHidden = false
                        }
                        else
                        {
                            isPreviusPointNotAccept = true
                        }
                    }
                }
            }
        }
    
    func onSearchError(_ error: Error) {
        let searchError = (error as NSError).userInfo[YRTUnderlyingErrorKey] as! YRTError
        var errorMessage = "Unknown error"
        if searchError.isKind(of: YRTNetworkError.self) {
            errorMessage = "Network error"
        } else if searchError.isKind(of: YRTRemoteError.self) {
            errorMessage = "Remote server error"
        }
        
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    //
    func onObjectTap(with: YMKGeoObjectTapEvent) -> Bool {
        /*
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
         */
        return true // false after uncomment
    }
    
    func onMapTap(with map: YMKMap, point: YMKPoint) {
        mapView.mapWindow.map.deselectGeoObject()
        /*
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
         */
    }
    
    func onMapAddRoutePoint( appenPoint : YMKPoint)
    {
        if ( requestPoints.isEmpty )
        {
            if ( userLocation != nil )
            {
                requestPoints.append(YMKRequestPoint(point: userLocation!, type: .viapoint, pointContext: nil))
                requestPoints.append(YMKRequestPoint(point: appenPoint, type: .viapoint, pointContext: nil))
            }
        }else
        {
            requestPoints.append(YMKRequestPoint(point: appenPoint, type: .viapoint, pointContext: nil))
        }
        if ( requestPoints.count > 1 )
        {
            if ( viewRouteCreate.isHidden == true )
            {
                viewRouteCreate.isHidden = false
            }
            if ( buttonCreateRoute.titleLabel?.text != "Построить маршрут" )
            {
                // grebuild new route
                clearMapObjectRoutingType()
                locationsPointAR.removeAll()
                removePrepareNodeRoute()
                if ( isPedestrianRoute )
                {
                    callPedestrianRoutingResponse(isTypeSender: false)
                } else
                {
                    callDrivingRoutingResponse(isTypeSender: false)
                }
            }
        }
    }
    func onMapRemovePoint( deletePoint : YMKPoint )
    {
        if ( !requestPoints.isEmpty )
        {
            var del_index : Int = 0
            var index_del : Int = 0
            for pp in requestPoints {
                if (pp.point == deletePoint)
                {
                    del_index = index_del
                }
                index_del+=1
            }
            requestPoints.remove(at: del_index )
            //
            if ( buttonCreateRoute.titleLabel?.text != "Построить маршрут" )
            {
                // grebuild new route
                clearMapObjectRoutingType()
                locationsPointAR.removeAll()
                removePrepareNodeRoute()
                if ( isPedestrianRoute )
                {
                    callPedestrianRoutingResponse(isTypeSender: false)
                } else
                {
                    callDrivingRoutingResponse(isTypeSender: false)
                }
            }
        }
    }
    func onMapCurrentPointIsAppend( currentPoint : YMKPoint ) -> Bool
    {
        if ( !requestPoints.isEmpty )
        {
            for pp in requestPoints {
                if (pp.point == currentPoint)
                {
                    return true
                }
            }
            return false
        }
        return false
    }
    func onMapLongTap(with map: YMKMap, point: YMKPoint) {
        print("Point Selection Coordinate:\(point)")
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
          sceneView.showsStatistics = false
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
          let rotateByNode = SCNAction.rotate(toAxisAngle: SCNVector4(0, 1, 0, 15), duration: 0.5)
          self.playerNode.runAction(rotateByNode)
      }
    func addTextPointPosition(index : Int , point : YMKPoint )
    {
        let mapObjects = mapView.mapWindow.map.mapObjects;
        let placemark = mapObjects.addPlacemark(with: point)
        placemark.setTextWithText(
            "[ \(index) ]",
            style: {
                let textStyle = YMKTextStyle()
                textStyle.size = 15.0
                textStyle.placement = .right
                textStyle.offset = 5.0
                return textStyle
            }()
        )
        mapsObjectNumberPoint.append(placemark)
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
        
        startingLocation = locations.last
        let userLocationString = "USER LOCATION:\(userLocation!.latitude) \(userLocation!.longitude)"
        // comment naviation mode
        if ( requestPoints.isEmpty )
        {
            requestPoints.insert(YMKRequestPoint(point: userLocation!, type: .viapoint, pointContext: nil), at: 0)
        }
        else
        {   // update location user at array requestPoint
            if ( requestPoints.first?.point.latitude != userLocation?.latitude && requestPoints.first?.point.longitude != userLocation?.longitude )
            {
                requestPoints[0] = YMKRequestPoint(point: userLocation!, type: .viapoint, pointContext: nil)
            }
        }
        if isNavigationMode == true
        {
            // grebuild new route
            clearMapObjectRoutingType()
            locationsPointAR.removeAll()
            if ( isPedestrianRoute )
            {
                callPedestrianRoutingResponse(isTypeSender: false)
            } else
            {
                callDrivingRoutingResponse(isTypeSender: false)
            }
        }
        // send to server location
        print("SEND TO SERVER:\(userLocationString)")
        socketConnection.send(message: userLocationString)
        let maps_t =  self.mapView.mapWindow.map
        mapView.mapWindow.map.move(
            with: YMKCameraPosition(target: ROUTE_START_POINT, zoom: 15, azimuth:                 Float(startingLocation.course), tilt: 0),
            animationType: YMKAnimation(type: YMKAnimationType.linear, duration: 2),
            cameraCallback: nil)
        createLocationCircle(centr: YMKPoint(latitude: userLocation!.latitude, longitude: userLocation!.longitude))
        // checj preload data finish
        if ( networkManager.stateSessionComplete() )
        {
            showPoiButton.isEnabled = false
        }
    }
    // MARK 3
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading){
        currentMagneticHeading = newHeading
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
    func onPolylineVisited(withPolyline polyline: YMKPolylineMapObject) {}
    func onPolygonVisited(withPolygon polygon: YMKPolygonMapObject) {}
    func onCircleVisited(withCircle circle: YMKCircleMapObject) {}
    func onCollectionVisitStart(with collection: YMKMapObjectCollection) -> Bool {
    return true
    }
    func onCollectionVisitEnd(with collection: YMKMapObjectCollection) {}
    func onClusterizedCollectionVisitStart(with collection: YMKClusterizedPlacemarkCollection) -> Bool {
    return false
    }
    func onClusterizedCollectionVisitEnd(with collection: YMKClusterizedPlacemarkCollection) {}
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
