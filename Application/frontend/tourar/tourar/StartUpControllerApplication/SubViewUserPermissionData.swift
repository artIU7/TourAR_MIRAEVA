//
//  SubViewUserPermissionData.swift
//  tourar
//
//  Created by Артем Стратиенко on 23.06.2024.
//

import Foundation
import SnapKit

class SubViewUserPermisionDataController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayoutView()
    }
    func setupLayoutView()
    {
        view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        //
        var labelImage = UIImageView(image: UIImage(named: "n_logo"))
        view.addSubview(labelImage)
        labelImage.snp.makeConstraints { (marker) in
            marker.top.equalToSuperview().inset(150)
            marker.centerX.equalToSuperview()
            marker.width.equalTo(140)
            marker.height.equalTo(100)
        }
        //
        var titleSubViewControll : UILabel = UILabel()
        // заголовок экрана приветсвия
        titleSubViewControll.text = "Предоставьте разрешение на получение доступа к вашей геолокации."
        titleSubViewControll.adjustsFontSizeToFitWidth = true
        titleSubViewControll.adjustsFontForContentSizeCategory = true
        titleSubViewControll.numberOfLines = 2
        titleSubViewControll.textAlignment = .center
        titleSubViewControll.font = UIFont.boldSystemFont(ofSize: 75)
        titleSubViewControll.textColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        // add title
        self.view.addSubview(titleSubViewControll)
        titleSubViewControll.snp.makeConstraints { (marker) in
            marker.top.equalTo(labelImage).inset(120)
            marker.left.right.equalToSuperview().inset(10)
            marker.centerXWithinMargins.equalToSuperview()
        }
        // add location
        var imageLocation = UIImageView(image: UIImage(named: "location_req"))
        view.addSubview(imageLocation)
        imageLocation.snp.makeConstraints { (marker) in
            marker.top.equalTo(titleSubViewControll).inset(80)
            marker.centerX.equalToSuperview()
            marker.width.equalTo(200)
            marker.height.equalTo(200)
        }
        // button continie
        let startTour = UIButton(type: .system)
        startTour.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        startTour.setTitle("Продолжить", for: .normal)
        startTour.setTitleColor(.white, for: .normal)
        startTour.layer.cornerRadius = 10
        startTour.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)

        view.addSubview(startTour)
        startTour.snp.makeConstraints { (marker) in
            marker.bottom.equalToSuperview().inset(20)
            marker.centerX.equalToSuperview()
            marker.left.right.equalToSuperview().inset(10)
            marker.height.equalTo(50)
        }
        startTour.addTarget(self, action: #selector(nextControllerView), for: .touchUpInside)

    }
    @objc func nextControllerView() {
        // переходим на главный таб бар
        let viewTours = MainViewController()
        //startTest.modalTransitionStyle = .flipHorizontal
        viewTours.modalPresentationStyle = .fullScreen
        viewTours.modalTransitionStyle = .crossDissolve
        show(viewTours, sender: self)
        print("Launch second controller")
    }
}
