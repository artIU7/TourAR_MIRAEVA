//
//  AppDelegate.swift
//  tourar
//
//  Created by Артем Стратиенко on 13.06.2024.
//

import UIKit
import YandexMapsMobile
import ARKit
import SberIdSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    /**
     * Replace "your_api_key" with a valid developer key.
     * You can get it at the https://developer.tech.yandex.ru/ website.
     */
    let MAPKIT_API_KEY = "2cd7ee1b-e363-4c18-8ee1-884ff30244f3"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        SIDManager.initSberID(clientId: "clientId")

        // Override point for customization after application launch.
        /**
         * Set API key before interaction with MapKit.
         */
        YMKMapKit.setApiKey(MAPKIT_API_KEY)

        /**
         * You can optionaly customize  locale.
         * Otherwise MapKit will use default location.
         */
        YMKMapKit.setLocale("ru_RU")
        
        /**
         * If you create instance of YMKMapKit not in application:didFinishLaunchingWithOptions:
         * you should also explicitly call YMKMapKit.sharedInstance().onStart()
         */
        YMKMapKit.sharedInstance()
        // preload data
        fetchAllDataPoint(cityName: "Noginsk")
        
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
                """) // For details, see https://developer.apple.com/documentation/arkit
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

