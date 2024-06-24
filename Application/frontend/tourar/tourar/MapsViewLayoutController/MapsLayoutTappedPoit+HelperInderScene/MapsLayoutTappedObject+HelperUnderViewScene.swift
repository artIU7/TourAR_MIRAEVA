//
//  MapsLayoutTappedObject+HelperUnderViewScene.swift
//  tourar
//
//  Created by Артем Стратиенко on 19.06.2024.
//

import Foundation
import YandexMapsMobile
import AVFoundation


class MapsLayoutTappedObject : NSObject, YMKMapObjectTapListener {
    //
    var buttonPlayAudio =  UIButton()
    var buttonItem_1parametr =  UIButton()
    var buttonItem_2parametr =  UIButton()
    var buttonItem_3parametr =  UIButton()
    //
    var currentPlacemarkSelected : YMKPlacemarkMapObject!

    //
    var currentPointAppend : YMKPoint!
    // set controoller for request controller datat from tapped object
    private weak var controller: MapsLayoutUnderSceneView?
    let sheetController = SheetControllUnderCollectionView()
    
    var textHeader : UITextField!
    
    init(controller: MapsLayoutUnderSceneView) {
        self.controller = controller
    }
    // req method
    func onMapObjectTap(with mapObject: YMKMapObject, point: YMKPoint) -> Bool {
        if let objectTapped = mapObject as? YMKPlacemarkMapObject {
            currentPlacemarkSelected = objectTapped
            if let userData = objectTapped.userData as? MapObjectTappedUserData {
                selectedObjectSheetPresent(textTitleValue: userData.title,descriptionValue: userData.description, pointAdditional : userData.point, imageValue: userData.image ,audioValue: userData.audio,group_1: userData.group_1,group_2: userData.group_2,group_3: userData.group_3, controller: controller!)
            }
        }
        return true;
    }
    func selectedObjectSheetPresent(textTitleValue : String,descriptionValue : String ,pointAdditional : YMKPoint, imageValue : UIImage ,audioValue : URL, group_1 : Bool,group_2:Bool,group_3: Bool, controller: UIViewController?)
    {
        if ( currentPointAppend != pointAdditional )
        {
            currentPointAppend = pointAdditional
        }
        if #available(iOS 15.0, *) {
            if let sheetController = sheetController.sheetPresentationController {
                sheetController.detents = [.medium()]
                sheetController.prefersGrabberVisible = true
                sheetController.preferredCornerRadius = 32
            }
        } else {
            // Fallback on earlier versions
        }
        //
        sheetController.view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        // text title
        let textTitle = UILabel()
        // заголовок экрана приветсвия
        textTitle.text = textTitleValue
        textTitle.adjustsFontSizeToFitWidth = true
        textTitle.adjustsFontForContentSizeCategory = true
        textTitle.numberOfLines = 2
        textTitle.font = UIFont.boldSystemFont(ofSize: 20)
        textTitle.textColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        textTitle.textAlignment = .center
        // add title
        sheetController.view.addSubview(textTitle)
        textTitle.snp.makeConstraints { (marker) in
            marker.top.equalToSuperview().inset(10)
            marker.left.right.equalToSuperview().inset(10)
            marker.centerXWithinMargins.equalToSuperview()
        }
        /*
        //
        textHeader = UITextField()
        textHeader.text = descriptionValue
        textHeader.adjustsFontSizeToFitWidth = true
        textHeader.adjustsFontForContentSizeCategory = true
        textHeader.font = UIFont(name: "Helvetica", size: 20)
        textHeader.font = UIFont.boldSystemFont(ofSize: 25)
        textHeader.textColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        
        sheetController.view.addSubview(textHeader)
        textHeader.snp.makeConstraints { (marker) in
            marker.top.equalTo(textTitle).inset(40)
            marker.left.right.equalToSuperview().inset(10)
            marker.centerX.equalToSuperview()
        }
        textHeader.isHidden = false
        //
         */
        let buttonOpenInfo = UIButton()
        buttonOpenInfo.setImage(imageValue, for: .normal)
        buttonOpenInfo.imageView?.layer.cornerRadius = 10
        buttonOpenInfo.layer.cornerRadius = 10
        buttonOpenInfo.layer.borderColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        buttonOpenInfo.layer.borderWidth = 3
        buttonOpenInfo.adjustsImageSizeForAccessibilityContentSizeCategory = true
        sheetController.view.addSubview(buttonOpenInfo)
        buttonOpenInfo.snp.makeConstraints { (marker) in
            marker.topMargin.equalTo(textTitle).inset(20 + 5)
            marker.centerX.equalToSuperview()
            marker.left.right.equalToSuperview().inset(20)
            marker.bottomMargin.equalToSuperview().inset(50 + 20 + 20 + 35 + 20 )
        }
        buttonOpenInfo.addTarget(self, action: #selector(fullViewInfo), for: .touchUpInside)
        // add button input point to route build
        // button continie
        buttonItem_1parametr =  UIButton()
        buttonItem_1parametr.setImage(UIImage(named: "groupDisableOne"), for: .normal)
        buttonItem_1parametr.imageView?.layer.cornerRadius = 10
        buttonItem_1parametr.layer.borderColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        buttonItem_1parametr.layer.borderWidth = 3
        buttonItem_1parametr.adjustsImageSizeForAccessibilityContentSizeCategory = true
        buttonItem_1parametr.layer.cornerRadius = 10
        //
        sheetController.view.addSubview(buttonItem_1parametr)
        buttonItem_1parametr.snp.makeConstraints { (marker) in
            marker.bottomMargin.equalToSuperview().inset(20 + 50 + 20)
            marker.left.equalToSuperview().inset(20)
            marker.height.equalTo(50)
            marker.width.equalTo( (sheetController.view.layer.frame.width - 10 * 5)/4)
        }
        buttonItem_2parametr =  UIButton()
        buttonItem_2parametr.setImage(UIImage(named: "groupDisableTwo"), for: .normal)
        buttonItem_2parametr.imageView?.layer.cornerRadius = 10
        buttonItem_2parametr.layer.borderColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        buttonItem_2parametr.layer.borderWidth = 3
        buttonItem_2parametr.adjustsImageSizeForAccessibilityContentSizeCategory = true
        buttonItem_2parametr.layer.cornerRadius = 10
        //
        sheetController.view.addSubview(buttonItem_2parametr)
        buttonItem_2parametr.snp.makeConstraints { (marker) in
            marker.bottomMargin.equalToSuperview().inset(20 + 50 + 20)
            marker.left.equalTo(buttonItem_1parametr).inset(10 + (sheetController.view.layer.frame.width - 10 * 5)/4 )
            marker.height.equalTo(50)
            marker.width.equalTo( (sheetController.view.layer.frame.width - 10 * 5)/4)
        }
        
        buttonItem_3parametr =  UIButton()
        buttonItem_3parametr.setImage(UIImage(named: "groupDisableTree"), for: .normal)
        buttonItem_3parametr.imageView?.layer.cornerRadius = 10
        buttonItem_3parametr.layer.borderColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        buttonItem_3parametr.layer.borderWidth = 3
        buttonItem_3parametr.adjustsImageSizeForAccessibilityContentSizeCategory = true
        buttonItem_3parametr.layer.cornerRadius = 10
        //
        sheetController.view.addSubview(buttonItem_3parametr)
        buttonItem_3parametr.snp.makeConstraints { (marker) in
            marker.bottomMargin.equalToSuperview().inset(20 + 50 + 20)
            marker.left.equalTo(buttonItem_2parametr).inset(10 + (sheetController.view.layer.frame.width - 10 * 5)/4)
            marker.height.equalTo(50)
            marker.width.equalTo( (sheetController.view.layer.frame.width - 10 * 5)/4)
        }
        if (sheetController.player != nil )
        {
            // прерываем аудио
            sheetController.playerItem = nil
            sheetController.player = nil
            sheetController.playerLayer = nil
        }
        let audioPoi = AVAsset(url: audioValue)
        sheetController.playerItem = AVPlayerItem(asset: audioPoi)
        sheetController.player = AVPlayer(playerItem: sheetController.playerItem)
        sheetController.playerLayer = AVPlayerLayer(player: sheetController.player!)
        sheetController.view.layer.addSublayer(sheetController.playerLayer!)
        
        buttonPlayAudio =  UIButton()
        buttonPlayAudio.setImage(UIImage(named: "playAudioFile"), for: .normal)
        buttonPlayAudio.imageView?.layer.cornerRadius = 10
        buttonPlayAudio.layer.borderColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        buttonPlayAudio.layer.borderWidth = 3
        buttonPlayAudio.adjustsImageSizeForAccessibilityContentSizeCategory = true
        buttonPlayAudio.layer.cornerRadius = 10
        //
        sheetController.view.addSubview(buttonPlayAudio)
        buttonPlayAudio.snp.makeConstraints { (marker) in
            marker.bottomMargin.equalToSuperview().inset(20 + 50 + 20)
            marker.left.equalTo(buttonItem_3parametr).inset(10 + (sheetController.view.layer.frame.width - 10 * 5)/4)
            marker.right.equalToSuperview().inset(20)
            marker.height.equalTo(50)
            marker.width.equalTo( (sheetController.view.layer.frame.width - 10 * 5)/4)
            //marker.width.equalTo(40)
        }
        buttonPlayAudio.addTarget(self, action: #selector(self.playButtonTapped(_:)), for: .touchUpInside)

        let addPoint = UIButton(type: .system)
        if ( !self.controller!.onMapCurrentPointIsAppend(currentPoint : currentPointAppend))
        {
            // add button
            addPoint.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
            addPoint.setTitle("Добавить точку", for: .normal)
            addPoint.setTitleColor(.white, for: .normal)
            addPoint.layer.cornerRadius = 10
            addPoint.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        }
        else
        {
            // add button
            addPoint.backgroundColor = #colorLiteral(red: 0.8665164076, green: 0.2626616855, blue: 0.1656771706, alpha: 1)
            addPoint.setTitle("Убрать точку", for: .normal)
            addPoint.setTitleColor(.white, for: .normal)
            addPoint.layer.cornerRadius = 10
            addPoint.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        }
        //
        sheetController.view.addSubview(addPoint)
        addPoint.snp.makeConstraints { (marker) in
            marker.bottomMargin.equalToSuperview().inset(20)
            marker.centerX.equalToSuperview()
            marker.left.right.equalToSuperview().inset(10)
            marker.height.equalTo(50)
        }
        addPoint.addTarget(self, action: #selector(self.appenPointToRoute(_:)), for: .touchUpInside)
        //
        controller!.present(sheetController, animated: true)
    }
    @objc func playButtonTapped(_ sender:UIButton){
        if sheetController.player?.rate == 0
        {
            sheetController.player!.play()
            buttonPlayAudio.setImage(UIImage(named: "stopAudioFile"), for: .normal)
            //playButton!.setTitle("Pause", for: UIControl.State.normal)

        } else {
            sheetController.player!.pause()
            buttonPlayAudio.setImage(UIImage(named: "playAudioFile"), for: .normal)
            //playButton!.setTitle("Play", for: UIControl.State.normal)
        }
    }
    @objc func appenPointToRoute( _ sender:UIButton)
    {
        if ( sender.titleLabel?.text == "Добавить точку")
        {
            sender.backgroundColor = #colorLiteral(red: 0.8665164076, green: 0.2626616855, blue: 0.1656771706, alpha: 1)
            sender.setTitle("Убрать точку", for: .normal)
            sender.setTitleColor(.white, for: .normal)
            sender.layer.cornerRadius = 10
            sender.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
            //
            controller!.onMapAddRoutePoint(appenPoint: currentPointAppend)
            currentPlacemarkSelected.setIconWith(UIImage(named: "custom_point_selected")!)

        }
        else
        {
            sender.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
            sender.setTitle("Добавить точку", for: .normal)
            sender.setTitleColor(.white, for: .normal)
            sender.layer.cornerRadius = 10
            sender.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
            //
            controller!.onMapRemovePoint(deletePoint: currentPointAppend)
            currentPlacemarkSelected.setIconWith(UIImage(named: "custom_point")!)
        }
        
    }
    @objc func fullViewInfo()
    {
        return
        if let sheetController = sheetController.sheetPresentationController {
            sheetController.animateChanges {
                if ( sheetPresentationControllerDidChangeSelectedDetentIdentifier(sheetController) == .medium )
                {
                    sheetController.selectedDetentIdentifier = .large
                    buttonItem_1parametr.isHidden = false
                    buttonItem_2parametr.isHidden = false
                    buttonItem_3parametr.isHidden = false
                    buttonPlayAudio.isHidden      = false
                }
                else
                {
                    sheetController.selectedDetentIdentifier = .medium
                    buttonItem_1parametr.isHidden = true
                    buttonItem_2parametr.isHidden = true
                    buttonItem_3parametr.isHidden = true
                    buttonPlayAudio.isHidden      = true
                }
            }
        }
     else {}
    }
}
// class object tapped data
 class MapObjectTappedUserData {
    let id: Int32
    let title : String
    let description: String
    let point : YMKPoint
    let image : UIImage
    let audio : URL
    let group_1 : Bool
    let group_2 : Bool
    let group_3 : Bool
     init(id: Int32,title : String, description: String,point : YMKPoint,image : UIImage,audio : URL, group_1 : Bool, group_2 : Bool , group_3 : Bool) {
        self.id = id
        self.title = title
        self.description = description
        self.point = point
        self.image = image
        self.audio = audio
        self.group_1 = group_1
        self.group_2 = group_2
        self.group_3 = group_3
    }
}

extension MapsLayoutTappedObject: UISheetPresentationControllerDelegate {
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) -> UISheetPresentationController.Detent.Identifier?{
        return sheetPresentationController.selectedDetentIdentifier
    }
}
