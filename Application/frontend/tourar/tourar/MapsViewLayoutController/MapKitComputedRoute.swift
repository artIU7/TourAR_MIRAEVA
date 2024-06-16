//
//  MapKitComputedRoute.swift
//  tourar
//
//  Created by Артем Стратиенко on 16.06.2024.
//

import Foundation
import UIKit
import YandexMapsMobile

extension MapsLayoutUnderSceneView{
    // computed roiting for car
    func callRoutingResponse()
    {
        let requestPoints : [YMKRequestPoint] = [
            YMKRequestPoint(point: ROUTE_START_POINT, type: .waypoint, pointContext: nil),
            YMKRequestPoint(point: ROUTE_END_POINT, type: .waypoint, pointContext: nil),
            ]
        
        let responseHandler = {(routesResponse: [YMKDrivingRoute]?, error: Error?) -> Void in
            if let routes = routesResponse {
                self.onRoutesReceived(routes)
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
    func onRoutesReceived(_ routes: [YMKDrivingRoute]) {
        var multiRoute = 0
        let mapObjects = mapView.mapWindow.map.mapObjects
        //mapObjects.clear()
        routePoint.removeAll()
        routeLine.removeAll()
        removePrepareNodeRoute()
        print("Count Route:\(routes.count)")
        var numberRoute : Int = 0
        switch(multiRoute) {
            case 0:
            // one route
            let polyTest = mapObjects.addPolyline(with: routes.first!.geometry)
            print("Count Points:\(routes.first?.geometry.points.count)")
            var index = 0
            var n_point = routes.first!.geometry.points.last
            //for point_ in routes.first!.geometry.points
            //{
            //    addRoutePointScene(index : index, rPoint : point_)
            //    index += 1
            //}
            addRoutePointScene(index: 1, rPoint: n_point!)
            /*
            // add line from point's
            if (self.routePoint.count != 0 )
            {
                for i in 0...self.routePoint.count - 2
                {
                    self.lineNode(self.routePoint[i+0].routeNode.position,
                                  self.routePoint[i+1].routeNode.position,
                                  i,
                                  i+1)
                }
            }
            */
            polyTest.strokeWidth = 5
            polyTest.gapLength   = 5
            polyTest.dashOffset  = 6
            polyTest.dashLength  = 7
            case 1:
            // any routes
            // get route geometry for building polyline and scene point route
            for route in routes {
                let polyTest = mapObjects.addPolyline(with: route.geometry)
                var index = 0
                print("Count Points:\(route.geometry.points.count)")
                for point_ in route.geometry.points
                {
                    addRoutePointScene(index : index, rPoint : point_)
                    index += 1
                }
                polyTest.strokeWidth = 5
                polyTest.gapLength   = 5
                polyTest.dashOffset  = 6
                polyTest.dashLength  = 7
                switch(numberRoute){
                case 0:
                    polyTest.outlineColor = UIColor.black
                    polyTest.setStrokeColorWith(UIColor.red)
                case 1:
                    polyTest.outlineColor = UIColor.black
                    polyTest.setStrokeColorWith(UIColor.green)
                case 2:
                    polyTest.outlineColor = UIColor.black
                    polyTest.setStrokeColorWith(UIColor.blue)
                case 3:
                    polyTest.outlineColor = UIColor.black
                    polyTest.setStrokeColorWith(UIColor.purple)
                default:
                    polyTest.outlineColor = UIColor.black
                    polyTest.setStrokeColorWith(UIColor.orange)
                }
                numberRoute += 1
            }
            default:
            print("not routes")
        }
        mapObjects.traverse(with: self)
    }
    
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
    // pedistrain type
    func computedRoute() {
      let requestPoints : [YMKRequestPoint] = [
          YMKRequestPoint(point: ROUTE_START_POINT, type: .waypoint, pointContext: nil),
          YMKRequestPoint(point: ROUTE_END_POINT, type: .waypoint, pointContext: nil),
          ]
      let pedestrianRouter = YMKTransport.sharedInstance().createPedestrianRouter()
              pedestrianSession = pedestrianRouter.requestRoutes(with: requestPoints,
                                                                 timeOptions: YMKTimeOptions(),
              routeHandler: { (routesResponse : [YMKMasstransitRoute]?, error :Error?) in
               if let routes = routesResponse {
                  print("route pedestrian \(routes.count)")
                  self.onRoutesPedestrian(routes)
               } else {
                  print("errr")
              }
          })
      }
    
    func onRoutesPedestrian(_ routes: [YMKMasstransitRoute]) {
        let mapObjects = mapView.mapWindow.map.mapObjects
        for route in routes {
            mapObjects.addPolyline(with: route.geometry)
        }
    }
    
}
