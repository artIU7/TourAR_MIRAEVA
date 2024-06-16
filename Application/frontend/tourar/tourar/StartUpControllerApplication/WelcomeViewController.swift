//
//  ViewController.swift
//  tourar
//
//  Created by Артем Стратиенко on 13.06.2024.
//

import UIKit
import SnapKit
import AVFoundation
import SceneKit

class WelcomeViewController: UIViewController {

    // SceneKit scene
    var sceneView = SCNView()
    var scene: SCNScene!
    var cameraNode: SCNNode!
    var camera: SCNCamera!
    var nodePreload = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setupSceneView()
        self.configLayout()
    }
    func configLayout() {
        view.backgroundColor = #colorLiteral(red: 0.3759136491, green: 0.6231091984, blue: 0.6783652551, alpha: 1)
        // заголовок экрана приветсвия
        let titleScreenLeft = UILabel()
        titleScreenLeft.numberOfLines = 0
        titleScreenLeft.text = "tour"
        titleScreenLeft.font = UIFont(name: "Copperplate", size: 30)
        titleScreenLeft.textColor = UIColor.white
        //
        view.addSubview(titleScreenLeft)
        titleScreenLeft.snp.makeConstraints { (marker) in
            marker.centerX.equalToSuperview()
            marker.top.equalToSuperview().inset(80)
        }
        let titleScreenRight = UILabel()
        titleScreenRight.numberOfLines = 0
        titleScreenRight.text = "AR"
        titleScreenRight.font = UIFont(name: "Copperplate", size: 30)
        titleScreenRight.textColor =  #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        //
        view.addSubview(titleScreenRight)
        titleScreenRight.snp.makeConstraints { (marker) in
            marker.centerX.equalToSuperview()
            marker.top.equalTo(titleScreenLeft.snp.bottom)
        }
        //
        //

        // add scene view screen
        view.addSubview(sceneView)
        self.sceneView.snp.makeConstraints { (marker) in
            marker.top.equalTo(titleScreenLeft).inset(100)
            marker.left.right.equalTo(self.view).inset(40)
            marker.bottom.equalTo(self.view).inset(100)
        }
        // button continie
        let startTour = UIButton(type: .system)
        startTour.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        startTour.setTitle("Продолжить", for: .normal)
        startTour.setTitleColor(.white, for: .normal)
        startTour.layer.cornerRadius = 15

        view.addSubview(startTour)
        startTour.snp.makeConstraints { (marker) in
            marker.bottom.equalToSuperview().inset(20)
            marker.centerX.equalToSuperview()
            marker.width.equalTo(200)
            marker.height.equalTo(40)
        }
        startTour.addTarget(self, action: #selector(viewTours), for: .touchUpInside)

    }
}
//
extension WelcomeViewController {
    @objc func viewTours() {
        
        // добавляем озвучку перехода на главный таб бар
        let utterance = AVSpeechUtterance(string: "Открываем главный экран маршрутов")
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

        // переходим на главный таб бар
        let viewTours = MainViewController()
        //startTest.modalTransitionStyle = .flipHorizontal
        viewTours.modalPresentationStyle = .fullScreen
        viewTours.modalTransitionStyle = .crossDissolve
        show(viewTours, sender: self)
        print("Launch second controller")
    }
}

extension WelcomeViewController : SCNSceneRendererDelegate {
  
    func setupSceneView() {
          sceneView.backgroundColor = UIColor.clear
          //
          //sceneView.backgroundColor = .darkGray
          //sceneView.layer.borderWidth = 1
          //sceneView.layer.borderColor = UIColor.red.cgColor
          sceneView.isUserInteractionEnabled = false
          sceneView.layer.cornerRadius = 50
          sceneView.layer.masksToBounds = true
          sceneView.clipsToBounds = true
          sceneView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMaxYCorner]
          //
          scene = SCNScene()
          //scene.physicsWorld.gravity = SCNVector3(x: 0, y: 0, z: 0)
          sceneView.autoenablesDefaultLighting = true
          sceneView.scene = scene
          sceneView.delegate = self
          sceneView.loops = true
          sceneView.showsStatistics = false
          sceneView.isPlaying = true
          // camera
          cameraNode = SCNNode()
          camera = SCNCamera()
          cameraNode.camera = camera
          cameraNode.position = SCNVector3(x: 0, y: 10, z: 50)
          scene.rootNode.addChildNode(cameraNode)
          // player node
          nodePreload = SCNNode()
          let playerScene = SCNScene(named: "tourist_prepare.scn")!
          let playerModelNode = playerScene.rootNode.childNodes.first!
          playerModelNode.scale = SCNVector3(0.08, 0.08, 0.08)
          playerModelNode.position = SCNVector3(x: 0, y: 5, z: 0)
          nodePreload.addChildNode(playerModelNode)
          nodePreload.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
          nodePreload.physicsBody?.isAffectedByGravity = false
          scene.rootNode.addChildNode(nodePreload)
          DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            let rotateByNode = SCNAction.rotate(toAxisAngle: SCNVector4(0, 1, 0, -45), duration: 120.0)
            self.nodePreload.runAction(rotateByNode)
          }
        //let moveByNode = SCNAction.move(by: SCNVector3(x: 5, y: 0, z: 10), duration: 45)
        //nodePreload.runAction(moveByNode)
      }
}
