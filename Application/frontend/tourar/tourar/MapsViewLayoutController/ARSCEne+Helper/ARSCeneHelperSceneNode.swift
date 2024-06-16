//
//  ARSCeneHelperSceneNode.swift
//  tourar
//
//  Created by Артем Стратиенко on 16.06.2024.
//

import Foundation
import ARKit

var infoNode : SCNNode!
var circleNode : SCNNode!
var followRoot : SCNNode!
var followNode : SCNNode!

extension SCNVector3 {
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
    }
    static func + (_ a : SCNVector3,_ b : SCNVector3) -> SCNVector3 {
        let c = SCNVector3(a.x+b.x, a.y+b.y, a.z + b.z)
        return c
    }
}
extension SCNNode {
   public func nodeAnimation(_ nodeAnimation : SCNNode) {
        let animationGroup = CAAnimationGroup.init()
        animationGroup.duration = 1.0
        animationGroup.repeatCount = .infinity
    
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = NSNumber(value: 1.0)
        opacityAnimation.toValue = NSNumber(value: 0.5)
    
        let spin = CABasicAnimation.init(keyPath: "rotation")
        spin.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 25, z: 0, w: 0))
        spin.toValue = NSValue(scnVector4: SCNVector4(x:0, y: 25, z: 0, w: Float(CGFloat(2 * M_PI))))
        spin.duration = 3
        spin.repeatCount = .infinity
        animationGroup.animations = [opacityAnimation,spin]
        nodeAnimation.addAnimation(animationGroup, forKey: "animations")
    }
}

extension ARSceneViewRouteController {
    func CGPointToSCNVector3(view: SCNView, depth: Float, point: CGPoint) -> SCNVector3 {
           let projectedOrigin = view.projectPoint(SCNVector3Make(0, 0, depth))
           let locationWithz   = SCNVector3Make(Float(point.x), Float(point.y), projectedOrigin.z)
           return view.unprojectPoint(locationWithz)
       }
    func isNodeInFrontOfCamera(_ node: SCNNode, scnView: SCNView) -> Bool {
        guard let pov = scnView.pointOfView else { return false }
        guard let parent = node.parent else { return false }
        let positionInPOV = parent.convertPosition(node.position, to: pov)
        return positionInPOV.z < 0
       }
    func addLabel(_ position : SCNVector3, _ value : String, isCamera : Bool) {
             let text = SCNText(string: value, extrusionDepth: 1)
             let material = SCNMaterial()
             let pointXColor = #colorLiteral(red: 0.5725490451, green: 0, blue: 0.2313725501, alpha: 1)
             material.diffuse.contents = pointXColor
             text.materials = [material]
             let node = SCNNode()
             node.position = position//SCNVector3(0,2, 2)
             node.scale = SCNVector3(0.1, 0.1, 0.1)
             let billboardConstraint = SCNBillboardConstraint()
             billboardConstraint.freeAxes = SCNBillboardAxis.Y
             node.constraints = [billboardConstraint]
             node.geometry = text
             node.name = "labelAR"
             if isCamera == true {
                //  self.isNodeInFrontOfCamera(node, scnView: sceneView)
             }
             sceneView.scene.rootNode.addChildNode(node)
         }
    func billboardnew(_ position : SCNVector3, value : String) {
              let material = SCNMaterial()
              let textGeometry = SCNText(string: "КЦ Октябрь" + " " + value, extrusionDepth: 0.5)
              textGeometry.font = UIFont(name: "Arial", size: 2)
              textGeometry.firstMaterial!.diffuse.contents = UIColor.white
              let textNode = SCNNode(geometry: textGeometry)
              let (min, max) = textGeometry.boundingBox
              let dx = min.x + 0.5 * (max.x - min.x)
              let dy = min.y + 0.5 * (max.y - min.y)
              let dz = min.z + 0.5 * (max.z - min.z)
              textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)

              textNode.scale = SCNVector3(0.01, 0.01, 0.01)
              let billboardScene = SCNScene(named: "art.scnassets/Model/board_rZp_small_frame_test.scn")! //
              let billboardNode = billboardScene.rootNode.childNode(withName: "board",
                                                                       recursively: false)!
              let plane = billboardNode//SCNPlane(width: 0.2, height: 0.2)
              let blueMaterial = SCNMaterial()
              blueMaterial.diffuse.contents = UIColor.blue
              let parentNode = plane//SCNNode(geometry: plane) //
              let yFreeConstraint = SCNBillboardConstraint()
              yFreeConstraint.freeAxes = [.Y] // optionally
              parentNode.constraints = [yFreeConstraint] //

              parentNode.position = position//SCNVector3(0, 0, -0.5)
              parentNode.addChildNode(textNode)
              parentNode.scale = SCNVector3(3, 3, 3)
              //addChildNode(parentNode)
              sceneView.scene.rootNode.addChildNode(parentNode) //
          }
    /// MARK 0 load ring model
    func ringCheck(_ endRoute : SCNVector3,name : String) {
            let arrowScene = SCNScene(named: "art.scnassets/Model/RingCheck.scn")! //
            infoNode = arrowScene.rootNode.childNode(withName: "Meshes",
                                                       recursively: false)! // "main"
            circleNode = infoNode.childNode(withName: "RootNode",
                                               recursively: false)!.childNode(withName: "Circle",
                                                                              recursively: false)!
         
            let yFreeConstraint = SCNBillboardConstraint()
            yFreeConstraint.freeAxes = [.Y] // optionally
            circleNode.constraints = [yFreeConstraint]
            circleNode.scale = SCNVector3(0.2, 0.2, 0.2)
            circleNode.position = endRoute
            circleNode.name = name
            circleNode.nodeAnimation(circleNode)
            sceneView.scene.rootNode.addChildNode(circleNode)
            print("Init : add object - Allow") // Focusw
        }
    func arrowLoadMesh(_ endRoute : SCNVector3) {
               let arrowScene = SCNScene(named: "poi.scn")! // "Focus_mocus"
               allowNode = arrowScene.rootNode.childNode(withName: "Meshes",
                                                          recursively: false)! // "main"
        
               allowNode.scale = SCNVector3(0.8, 0.8, 0.8)
               allowNode.position = endRoute
               allowNode.name = "poi"
               sceneView.scene.rootNode.addChildNode(allowNode)
               print("Init : add object - poi") // Focusw
       }
    func loadBuilding(_ endRoute : SCNVector3) {
            let buildScene = SCNScene(named: "art.scnassets/Model/building.scn")! // "Focus_mocus"
            buildNode = buildScene.rootNode.childNode(withName: "scene",
                                                       recursively: false)! // "main"
            buildNode.scale = SCNVector3(1.2, 1.2, 1.2)
            buildNode.position = endRoute
            buildNode.name = "build"
            sceneView.scene.rootNode.addChildNode(buildNode)
            print("Init : add object - build") // Focusw
    }
    
}
