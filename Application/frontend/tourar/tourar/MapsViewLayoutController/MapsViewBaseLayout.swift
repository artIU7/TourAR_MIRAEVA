//
//  MapsViewBaseLayout.swift
//  tourar
//
//  Created by Артем Стратиенко on 15.06.2024.
//

import Foundation
import UIKit
import YandexMapsMobile


class MapsViewBaseLayout: UIView {

    @objc public var mapView: YMKMapView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    private func setup() {
        mapView = YMKMapView(frame: bounds)
        mapView.mapWindow.map.mapType = .vectorMap
        //        mapView = YMKMapView(frame: bounds, vulkanPreferred: BaseMapView.isM1Simulator())

    }
}
