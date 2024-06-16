//
//  ARSceneDrawRoute+Helper.swift
//  tourar
//
//  Created by Артем Стратиенко on 16.06.2024.
//

import Foundation
import ARKit
import CoreLocation

extension ARSceneViewRouteController {
    func draw3DLine(_ nodeA : SCNVector3, _ nodeB : SCNVector3, orderIndex : Int, color : UIColor) {
            //SCNTransaction.animationDuration = 1.0
            let nodeAVector3 = GLKVector3Make(nodeA.x, nodeA.y, nodeA.z)
            let nodeBVector3 = GLKVector3Make(nodeB.x, nodeB.y, nodeB.z)
            let line = MeasuringLineNode(startingVector: nodeAVector3 , endingVector: nodeBVector3, color: color)
            line.name = "routeAR"
            line.renderingOrder = 10 //+ orderIndex//orderIndex
            //line.opacity = 0
            //line.nodeAnimation(line)
            self.sceneView.scene.rootNode.addChildNode(line)
      }
    class MeasuringLineNode: SCNNode{
        init(startingVector vectorA: GLKVector3, endingVector vectorB: GLKVector3, color : UIColor) {
        super.init()
        let height = CGFloat(GLKVector3Distance(vectorA, vectorB))
        self.position = SCNVector3(vectorA.x, vectorA.y, vectorA.z)
        let nodeVectorTwo = SCNNode()
        nodeVectorTwo.position = SCNVector3(vectorB.x, vectorB.y, vectorB.z)
        let nodeZAlign = SCNNode()
        nodeZAlign.eulerAngles.x = Float.pi/2
        let cylinder = SCNCylinder(radius: 0.5, height: height)
        let material = SCNMaterial()
        let color_route = color
        material.diffuse.contents = color_route
        let box = SCNBox(width: 0.5, height: height, length: 0.05, chamferRadius: 0)
        box.materials = [material]
        let nodeLine = SCNNode(geometry: box)
        nodeLine.position.y = Float(-height/2)
        nodeZAlign.addChildNode(nodeLine)
        nodeZAlign.name = "route AR"
        nodeZAlign.renderingOrder = 10
        self.addChildNode(nodeZAlign)
        self.constraints = [SCNLookAtConstraint(target: nodeVectorTwo)]
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
    // func computed offset for new coordinate
           func offsetComplete(_ pointStart : CLLocationCoordinate2D, _ pointEnd : CLLocationCoordinate2D) -> [Double] {
               let toRadian = Double.pi/180
               let toDegress = 180/Double.pi
               var deltaX = Double()
               var deltaZ = Double()
               var offset = [Double]()
               let defLat = (2*Double.pi * 6378.137)/360
               let defLot = (2*Double.pi*6378.137*cos(pointStart.latitude*toRadian))/360//*toDegress
                   if pointStart != nil {
                       if pointEnd != nil {
                           deltaX = (pointEnd.longitude - pointStart.longitude)*defLot*1000//*toDegress
                           deltaZ = (pointEnd.latitude - pointStart.latitude)*defLat*1000//*toDegress
                           var lon = (pointStart.longitude*defLot/*1000*/ + deltaX)/defLot/*1000*///*toDegress
                           var lat = (pointStart.latitude*defLat + deltaZ)/defLat//*toDegress
                           print("\(pointEnd.longitude - pointStart.longitude)")
                           print("\(pointEnd.latitude - pointStart.latitude)")
             }
        }
               offset.append(deltaX)
               offset.append(deltaZ)
           return offset
       }
}
