//
//  MapsLayoutTappedObject+HelperUnderViewScene.swift
//  tourar
//
//  Created by Артем Стратиенко on 19.06.2024.
//

import Foundation
import YandexMapsMobile

class MapsLayoutTappedObject : NSObject, YMKMapObjectTapListener {
    //
    var currentPointAppend : YMKPoint!
    // set controoller for request controller datat from tapped object
    private weak var controller: MapsLayoutUnderSceneView?
    let sheetController = SheetControllUnderCollectionView()

    
    init(controller: MapsLayoutUnderSceneView) {
        self.controller = controller
    }
    // req method
    func onMapObjectTap(with mapObject: YMKMapObject, point: YMKPoint) -> Bool {
        if let objectTapped = mapObject as? YMKPlacemarkMapObject {
            if let userData = objectTapped.userData as? MapObjectTappedUserData {
                let message = "Object with id \(userData.id) and description '\(userData.description)' tapped";
                selectedObjectSheetPresent(textTitleValue: userData.description, pointAdditional : point, imageValue: userData.image , controller: controller!)
            }
        }
        return true;
    }
    func selectedObjectSheetPresent(textTitleValue : String,pointAdditional : YMKPoint, imageValue : UIImage , controller: UIViewController?)
    {
        if ( currentPointAppend != pointAdditional )
        {
            currentPointAppend = pointAdditional
        }
        if #available(iOS 15.0, *) {
            if let sheetController = sheetController.sheetPresentationController {
                sheetController.detents = [.medium(),.large()]
                sheetController.prefersGrabberVisible = true
                sheetController.preferredCornerRadius = 32
            }
        } else {
            // Fallback on earlier versions
        }
        //
        sheetController.view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        let textTitle = UILabel()
        // заголовок экрана приветсвия
        textTitle.numberOfLines = 0
        textTitle.adjustsFontSizeToFitWidth = true
        textTitle.adjustsFontForContentSizeCategory = true
        textTitle.numberOfLines = 2
        textTitle.text = textTitleValue
        textTitle.font = UIFont(name: "Helvetica", size: 20)
        textTitle.font = UIFont.boldSystemFont(ofSize: 25)

        textTitle.textColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        // add title
        sheetController.view.addSubview(textTitle)
        textTitle.snp.makeConstraints { (marker) in
            marker.topMargin.equalToSuperview().inset(40)
            marker.left.right.equalToSuperview().inset(10)
            marker.centerX.equalToSuperview()
        }
        //
        var buttonOpenInfo = UIButton()
        buttonOpenInfo.setImage(imageValue, for: .normal)
        buttonOpenInfo.imageView?.layer.cornerRadius = 10
        buttonOpenInfo.layer.cornerRadius = 10
        buttonOpenInfo.layer.borderColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        buttonOpenInfo.layer.borderWidth = 3
        buttonOpenInfo.adjustsImageSizeForAccessibilityContentSizeCategory = true
        sheetController.view.addSubview(buttonOpenInfo)
        buttonOpenInfo.snp.makeConstraints { (marker) in
            marker.topMargin.equalTo(textTitle).inset(textTitle.bounds.height + 40)
            marker.bottom.equalToSuperview().inset(50 + 10 + 10 )
            marker.centerX.equalToSuperview()
            marker.left.right.equalToSuperview().inset(10)
        }
        buttonOpenInfo.addTarget(self, action: #selector(fullViewInfo), for: .touchUpInside)

        //
        /*var poiImage = UIImageView(image: imageValue)
        sheetController.view.addSubview(poiImage)
        poiImage.snp.makeConstraints { (marker) in
            marker.topMargin.equalTo(textTitle).inset(textTitle.bounds.height + 20)
            marker.bottom.equalToSuperview().inset(50 + 10 + 10 )
            marker.centerX.equalToSuperview()
            marker.left.right.equalToSuperview().inset(10)
        }
         */
        // skip collection view
        /*
        // add slideCollectionView
        sheetController.imageSetCollection = imageValue
        sheetController.view.addSubview(sheetController.collectionViewSlide)
        sheetController.collectionViewSlide.snp.makeConstraints { (marker) in
            marker.topMargin.equalTo(textTitle).inset(40)
            marker.centerX.equalToSuperview()
            marker.left.right.equalToSuperview().inset(10)
            marker.width.equalTo(200)
            marker.height.equalTo(150)
        }
        */
        // add button input point to route build
        // button continie
        let addPoint = UIButton(type: .system)
        addPoint.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        addPoint.setTitle("Добавить точку", for: .normal)
        addPoint.setTitleColor(.white, for: .normal)
        addPoint.layer.cornerRadius = 10
        addPoint.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        //
        sheetController.view.addSubview(addPoint)
        addPoint.snp.makeConstraints { (marker) in
            marker.bottomMargin.equalToSuperview().inset(20)
            marker.centerX.equalToSuperview()
            marker.left.right.equalToSuperview().inset(10)
            marker.height.equalTo(50)
        }
        addPoint.addTarget(self, action: #selector(appenPointToRoute), for: .touchUpInside)
        //
        controller!.present(sheetController, animated: true)
    }
    @objc func appenPointToRoute()
    {
        controller!.onMapAddRoutePoint(appenPoint: currentPointAppend)
    }
    @objc func fullViewInfo()
    {
        if let sheetController = sheetController.sheetPresentationController {
            sheetController.animateChanges {
                sheetController.selectedDetentIdentifier = .large
            }
            sheetPresentationControllerDidChangeSelectedDetentIdentifier(sheetController)
        }
     else {}
    }
}
// class object tapped data
 class MapObjectTappedUserData {
    let id: Int32
    let description: String
    let image : UIImage
    init(id: Int32, description: String,image : UIImage) {
        self.id = id
        self.description = description
        self.image = image
    }
}

extension MapsLayoutTappedObject: UISheetPresentationControllerDelegate {
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        print(sheetPresentationController.selectedDetentIdentifier == .large ? "large" : "medium")
    }
}
