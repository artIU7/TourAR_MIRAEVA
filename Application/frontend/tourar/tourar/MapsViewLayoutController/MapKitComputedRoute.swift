//
//  MapKitComputedRoute.swift
//  tourar
//
//  Created by Артем Стратиенко on 16.06.2024.
//

import Foundation
import UIKit
import YandexMapsMobile
import CoreLocation

extension MapsLayoutUnderSceneView{
    // computed roiting - Driving Type
    func callDrivingRoutingResponse()
    {
        if ( requestPoints.isEmpty ) {
            return
        }
        let responseHandler = {(routesResponse: [YMKDrivingRoute]?, error: Error?) -> Void in
            if let routes = routesResponse {
                self.onDrivingRoutesReceived(routes)
            } else {
                self.onRoutesError(error!)
            }
        }
        //
        let drivingRouter = YMKDirections.sharedInstance().createDrivingRouter()
        drivingSession = drivingRouter.requestRoutes(
            with: requestPoints,
            drivingOptions: YMKDrivingDrivingOptions(),
            vehicleOptions: YMKDrivingVehicleOptions(),
            routeHandler: responseHandler)
    }
    // user routing method
    func onDrivingRoutesReceived(_ routes: [YMKDrivingRoute]) {
        let mapObjects = mapView.mapWindow.map.mapObjects
        //
        routePoint.removeAll()
        routeLine.removeAll()
        removePrepareNodeRoute()
        //
        let route = routes.first
        polyLineObjectDrivingRouter = mapObjects.addPolyline(with: route!.geometry)
        polyLineObjectDrivingRouter!.strokeWidth = 5
        polyLineObjectDrivingRouter!.gapLength   = 5
        var index = 0
        for point_ in route!.geometry.points {
            locationsPointAR.append(CLLocation(latitude: point_.latitude, longitude: point_.longitude))
            //addRoutePointScene(index : index, rPoint : point_)
            index += 1
        }
    }
    // computed roiting - Pedestrian Type
    func callPedestrianRoutingResponse() {
      if ( requestPoints.isEmpty ) {
          return
      }
      let pedestrianRouter = YMKTransport.sharedInstance().createPedestrianRouter()
              pedestrianSession = pedestrianRouter.requestRoutes(with: requestPoints,
                                                                 timeOptions: YMKTimeOptions(),
              routeHandler: { (routesResponse : [YMKMasstransitRoute]?, error :Error?) in
               if let routes = routesResponse {
                  self.onPedestrianRoutesReceived(routes)
               } else {
                   self.onRoutesError(error!)
              }
          })
      }
    
    func onPedestrianRoutesReceived(_ routes: [YMKMasstransitRoute]) {
        let mapObjects = mapView.mapWindow.map.mapObjects
        //
        routePoint.removeAll()
        routeLine.removeAll()
        removePrepareNodeRoute()
        //
        var route = routes.first
        polyLineObjectPedestrianRoute = mapObjects.addPolyline(with: route!.geometry)
        polyLineObjectPedestrianRoute!.strokeWidth = 5
        polyLineObjectPedestrianRoute!.gapLength   = 5
        polyLineObjectPedestrianRoute!.dashOffset  = 6
        polyLineObjectPedestrianRoute!.dashLength  = 7
        var index = 0
        for point_ in route!.geometry.points {
            locationsPointAR.append(CLLocation(latitude: point_.latitude, longitude: point_.longitude))
            //addRoutePointScene(index : index, rPoint : point_)
            index += 1
        }
    }
    // Event Error Response Build Route / ALL Type
    func onRoutesError(_ error: Error) {
        let routingError = (error as NSError).userInfo[YRTUnderlyingErrorKey] as! YRTError
        var errorMessage = "Unknown error"
        if routingError.isKind(of: YRTNetworkError.self) {
            errorMessage = "Network error"
        } else if routingError.isKind(of: YRTRemoteError.self) {
            errorMessage = "Remote server error"
        }
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
