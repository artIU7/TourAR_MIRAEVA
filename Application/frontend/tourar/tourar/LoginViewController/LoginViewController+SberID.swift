//
//  LoginViewController+SberID.swift
//  tourar
//
//  Created by Артем Стратиенко on 16.06.2024.
//

import Foundation
import UIKit
import SnapKit
import SberIdSDK
import AVFoundation


class LoginButtonObserver: SIDLoginButtonObserverProtocol {
    func loginButtonWasHidden() {
        // Здесь может быть ваш код для обработки скрытия кнопки
    }
}
/*
let sberIdButton = SIDLoginButton(type: .white,
                                  textType: .short,
                                  clientId: "clientId",
                                  desiredSize: CGSize(),
                                  observer: SIDLoginButtonObserver())

*/
class LoginViewController: UIViewController {
    
    /*
    // Создание кнопки с заданным стилем и наблюдателем
    let loginButton = SIDLoginButton(type: .green, observer: observer)

    // Создание кнопки с дополнительными настройками
    let loginButtonCustom = SIDLoginButton(type: .white,
                                           textType: .short,
                                           desiredSize: CGSize(width: 200, height: 50),
                                           observer: observer)
     */
    /*
    SIDManager.initSberID(clientId: "Ваш_clientID")
    
    let uiPreferences = SIDUIPreferences(appName: "tour.ar",
                                         themeColorLight: UIColor.white,
                                         themeColorDark: UIColor.black,
                                         semiboldFont: UIFont.systemFont(ofSize: 16, weight: .semibold),
                                         mediumFont: UIFont.systemFont(ofSize: 14, weight: .medium),
                                         isShowErrorOnMain: true)

    SIDManager.initSberID(clientId: "Ваш_clientID",
                          profileUrl: "URL для запроса данных, если необходим",
                          uiPreferences: uiPreferences)
    */

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.configLayout()
    }
    func configLayout() {
        view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        var labelImage = UIImageView(image: UIImage(named: "n_logo"))
        view.addSubview(labelImage)
        labelImage.snp.makeConstraints { (marker) in
            marker.top.equalToSuperview().inset(150)
            marker.centerX.equalToSuperview()
            marker.width.equalTo(140)
            marker.height.equalTo(100)
        }
        let uiEntryLoginLabel = UILabel()
        uiEntryLoginLabel.numberOfLines = 0
        uiEntryLoginLabel.text = "Войдите по Сбер ID"
        uiEntryLoginLabel.font = UIFont(name: "Helvetica", size: 30)
        uiEntryLoginLabel.font = UIFont.boldSystemFont(ofSize: 25)
        uiEntryLoginLabel.textColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        //
        view.addSubview(uiEntryLoginLabel)
        uiEntryLoginLabel.snp.makeConstraints { (marker) in
            marker.centerX.equalToSuperview()
            marker.top.equalTo(labelImage).inset(200)
        }
        //
        // continue
        // button continie
        let loginSberSDk = UIButton(type: .system)
        loginSberSDk.backgroundColor = #colorLiteral(red: 0.1287833452, green: 0.6253849268, blue: 0.2183291316, alpha: 1)
        loginSberSDk.setTitle("Войти по Сбер ID", for: .normal)
        loginSberSDk.setTitleColor(.white, for: .normal)
        loginSberSDk.layer.cornerRadius = 10
        loginSberSDk.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        
        view.addSubview(loginSberSDk)
        loginSberSDk.snp.makeConstraints { (marker) in
            marker.top.equalTo(uiEntryLoginLabel).inset(100)
            marker.centerX.equalToSuperview()
            marker.left.right.equalToSuperview().inset(10)
            marker.height.equalTo(50)
        }
        loginSberSDk.addTarget(self, action: #selector(loginSberID), for: .touchUpInside)
        // continue
        // button continie
        let nextController = UIButton(type: .system)
        nextController.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        nextController.setTitle("Войти без регистрации", for: .normal)
        nextController.setTitleColor(.white, for: .normal)
        nextController.layer.cornerRadius = 10
        nextController.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)

        view.addSubview(nextController)
        nextController.snp.makeConstraints { (marker) in
            marker.bottom.equalToSuperview().inset(20)
            marker.centerX.equalToSuperview()
            marker.left.right.equalToSuperview().inset(10)
            marker.height.equalTo(50)
        }
        nextController.addTarget(self, action: #selector(nextControllerView), for: .touchUpInside)
    }
}

extension LoginViewController {
    @objc func loginSberID(){
        guard let url = URL(string: "://sberbank.com") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
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
