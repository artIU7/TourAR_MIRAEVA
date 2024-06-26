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
    func callDrivingRoutingResponse(isTypeSender : Bool)
    {
        var tempRequestPoint = [YMKRequestPoint]()
        if ( !isTypeSender )
        {
            if ( requestPoints.isEmpty ) {
                return
            }
            tempRequestPoint = requestPoints
            // tempRequestPoint run algoritm
            if ( !tempRequestPoint.isEmpty )
            {
                var startWaypoint = tempRequestPoint.first
                //
                var arrayDistance : [Double] = []
                tempRequestPoint.forEach { point in
                    let distancePoi = findNearPointOnRoute(pointNear: point.point )
                    arrayDistance.append(distancePoi)
                }
                var indexMaxDistancePoi = -1
                var i = 0
                for item in arrayDistance{
                    if ( item == arrayDistance.max())
                    {
                        indexMaxDistancePoi = i
                    }
                    i+=1
                }
                var tempArray : [YMKRequestPoint] = []
                if ( indexMaxDistancePoi != -1)
                {
                    tempArray = []
                    for point_req in tempRequestPoint
                    {
                        if ( startWaypoint == point_req )
                        {
                            tempArray.append(YMKRequestPoint(point: point_req.point, type: .waypoint, pointContext: nil))
                        } else if ( tempRequestPoint[indexMaxDistancePoi] == point_req)
                        {
                            tempArray.append(YMKRequestPoint(point: point_req.point, type: .waypoint, pointContext: nil))
                        } else
                        {
                            tempArray.append(YMKRequestPoint(point: point_req.point, type: .viapoint, pointContext: nil))
                        }
                        
                    }
                }
                tempRequestPoint = tempArray
                if ( !mapsObjectNumberPoint.isEmpty )
                {
                    mapsObjectNumberPoint.forEach { object in
                        mapView.mapWindow.map.mapObjects.remove(with: object)
                    }
                    mapsObjectNumberPoint.removeAll()
                }
                var index = 0
                tempRequestPoint.forEach { point in
                    addTextPointPosition(index: index, point: point.point)
                    index+=1
                }
            }
        } else
        {
            if ( requestPointsSubRoute.isEmpty ) {
                return
            }
            tempRequestPoint = requestPointsSubRoute
        }
        //
        if ( !tempRequestPoint.isEmpty ) {
            let responseHandler = {(routesResponse: [YMKDrivingRoute]?, error: Error?) -> Void in
                if let routes = routesResponse {
                    self.onDrivingRoutesReceived(routes,isTypeSender: isTypeSender)
                } else {
                    self.onRoutesError(error!)
                }
            }
            //
            let drivingRouter = YMKDirections.sharedInstance().createDrivingRouter()
                 drivingSession = drivingRouter.requestRoutes(
                     with: tempRequestPoint,
                     drivingOptions: YMKDrivingDrivingOptions(),
                     vehicleOptions: YMKDrivingVehicleOptions(),
                     routeHandler: responseHandler)
        }
    }
    // user routing method
    func onDrivingRoutesReceived(_ routes: [YMKDrivingRoute],isTypeSender : Bool) {
        let mapObjects = mapView.mapWindow.map.mapObjects
        //
        let route = routes.first
        if ( !isTypeSender ){
            routePoint.removeAll()
            routeLine.removeAll()
            removePrepareNodeRoute()
            //
            polyLineObjectDrivingRouter = mapObjects.addPolyline(with: route!.geometry)
            polyLineObjectDrivingRouter!.strokeWidth = 5
            polyLineObjectDrivingRouter!.gapLength   = 5
            //
            var index = 0
            for point_ in route!.geometry.points {
                locationsPointAR.append(CLLocation(latitude: point_.latitude, longitude: point_.longitude))
                index += 1
                addRoutePointScene(index : index, rPoint : route!.geometry.points.last! )
                // point
                
            }
        } else
        {
            polyLineSubRouteDriving = mapObjects.addPolyline(with: route!.geometry)
            polyLineSubRouteDriving!.strokeWidth = 5
            polyLineSubRouteDriving!.gapLength   = 5
            polyLineSubRouteDriving!.setStrokeColorWith(colorSubRouteCommon)
        }
    }
    // computed roiting - Pedestrian Type
    func callPedestrianRoutingResponse(isTypeSender : Bool ) {
        var tempRequestPoint = [YMKRequestPoint]()
        if ( !isTypeSender )
        {
            if ( requestPoints.isEmpty ) {
                return
            }
            tempRequestPoint = requestPoints
            // tempRequestPoint run algoritm
            if ( !tempRequestPoint.isEmpty )
            {
                var startWaypoint = tempRequestPoint.first
                //
                var arrayDistance : [Double] = []
                tempRequestPoint.forEach { point in
                    let distancePoi = findNearPointOnRoute(pointNear: point.point )
                    arrayDistance.append(distancePoi)
                }
                var indexMaxDistancePoi = -1
                var i = 0
                for item in arrayDistance{
                    if ( item == arrayDistance.max())
                    {
                        indexMaxDistancePoi = i
                    }
                    i+=1
                }
                var tempArray : [YMKRequestPoint] = []
                if ( indexMaxDistancePoi != -1)
                {
                    tempArray = []
                    tempArray.append(YMKRequestPoint(point: startWaypoint!.point, type: .waypoint, pointContext: nil))
                    for point_req in tempRequestPoint
                    {
                        if ( startWaypoint != point_req )
                        {
                            if ( tempRequestPoint[indexMaxDistancePoi] == point_req)
                            {
                               // insert after all .viapoints
                            }
                            else
                            {
                                tempArray.append(YMKRequestPoint(point: point_req.point, type: .viapoint, pointContext: nil))
                            }
                        }
                    }
                    for point_req in tempRequestPoint
                    {
                        if ( tempRequestPoint[indexMaxDistancePoi] == point_req)
                        {
                            tempArray.append(YMKRequestPoint(point: point_req.point, type: .waypoint, pointContext: nil))
                        }
                    }
                }
                tempRequestPoint = tempArray
                
                if ( !mapsObjectNumberPoint.isEmpty )
                {
                    mapsObjectNumberPoint.forEach { object in
                        mapView.mapWindow.map.mapObjects.remove(with: object)
                    }
                    mapsObjectNumberPoint.removeAll()
                }
                var index = 0
                tempRequestPoint.forEach { point in
                    addTextPointPosition(index: index, point: point.point)
                    index+=1
                }
            }
        } else
        {
            if ( requestPointsSubRoute.isEmpty ) {
                return
            }
            tempRequestPoint = requestPointsSubRoute
        }
        if ( !tempRequestPoint.isEmpty ) {
            let pedestrianRouter = YMKTransport.sharedInstance().createPedestrianRouter()
                    pedestrianSession = pedestrianRouter.requestRoutes(with: tempRequestPoint,
                                                                       timeOptions: YMKTimeOptions(),
                    routeHandler: { (routesResponse : [YMKMasstransitRoute]?, error :Error?) in
                     if let routes = routesResponse {
                         self.onPedestrianRoutesReceived(routes,isTypeSender: isTypeSender)
                     } else {
                         self.onRoutesError(error!)
                    }
                })
        }
      }
    
    func onPedestrianRoutesReceived(_ routes: [YMKMasstransitRoute],isTypeSender : Bool) {
        let mapObjects = mapView.mapWindow.map.mapObjects
        var route = routes.first
        //
        if ( !isTypeSender ){
            routePoint.removeAll()
            routeLine.removeAll()
            removePrepareNodeRoute()
            //
            polyLineObjectPedestrianRoute = mapObjects.addPolyline(with: route!.geometry)
            polyLineObjectPedestrianRoute!.strokeWidth = 5
            polyLineObjectPedestrianRoute!.gapLength   = 5
            polyLineObjectPedestrianRoute!.dashOffset  = 6
            polyLineObjectPedestrianRoute!.dashLength  = 7
            polyLineObjectPedestrianRoute!.setStrokeColorWith(.systemCyan)
            //
            var index = 0
            for point_ in route!.geometry.points {
                locationsPointAR.append(CLLocation(latitude: point_.latitude, longitude: point_.longitude))
                index += 1
            }
            addRoutePointScene(index : index, rPoint : route!.geometry.points.last! )
        } else
        {
            polyLineSubRoutePedestrian = mapObjects.addPolyline(with: route!.geometry)
            polyLineSubRoutePedestrian!.strokeWidth = 5
            polyLineSubRoutePedestrian!.gapLength   = 5
            polyLineSubRoutePedestrian!.dashOffset  = 6
            polyLineSubRoutePedestrian!.dashLength  = 7
            polyLineSubRoutePedestrian!.setStrokeColorWith(colorSubRouteCommon)
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
