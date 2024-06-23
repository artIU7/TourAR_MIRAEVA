//
//  MainTabVBarController.swift
//  tourar
//
//  Created by Артем Стратиенко on 13.06.2024.
//

import Foundation
import UIKit

class MainViewController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Assign self for delegate for that ViewController can respond to UITabBarControllerDelegate methods
        self.delegate = self
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create Tab one
        let tabOne = MapsLayoutUnderSceneView()
        let tabOneBarItem = UITabBarItem(title: "Маршруты", image: UIImage(named: "tabBar_Routing"), selectedImage: UIImage(named: "tabBar_Routing"))
        
        tabOne.tabBarItem = tabOneBarItem
        // Create Tab two
        let tabTwo = CodeViewController()
        let tabTwoBarItem2 = UITabBarItem(title: "Обзор", image: UIImage(named: "tabBar_Overview"), selectedImage: UIImage(named: "tabBar_Overview"))
        
        tabTwo.tabBarItem = tabTwoBarItem2
        
        // Create Tab tree
        let tabTree = UIViewController()
        let tabTreeBarItem3 = UITabBarItem(title: "Настройки", image: UIImage(named: "tabBar_Settings"), selectedImage: UIImage(named: "tabBar_Settings"))
        
        tabTree.tabBarItem = tabTreeBarItem3
        
        
        self.viewControllers = [tabOne, tabTwo, tabTree]
    }
    
    //
    override var selectedIndex: Int {
        didSet {
            guard let selectedViewController = viewControllers?[selectedIndex] else {
                return
            }
            selectedViewController.tabBarItem.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 13)], for: .normal)
        }
    }
    //
    override var selectedViewController: UIViewController? {
        didSet {

            guard let viewControllers = viewControllers else {
                return
            }

            for viewController in viewControllers {
                if viewController == selectedViewController {
                    viewController.tabBarItem.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 13)], for: .normal)
                } else {
                    viewController.tabBarItem.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 11)], for: .normal)
                }
            }
        }
    }
    
    // UITabBarControllerDelegate method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
        //let appearance = UITabBarAppearance()
        //appearance.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0) //.red
        
        //tabBar.standardAppearance = appearance
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tabBar.frame.size.height = 55
        tabBar.frame.origin.y = view.frame.height - 55
    }
}
