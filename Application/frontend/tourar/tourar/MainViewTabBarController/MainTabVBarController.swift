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
        let tabOne = CodeViewController()
        let tabOneBarItem = UITabBarItem(title: "Обзор ", image: UIImage(named: "tour_guide"), selectedImage: UIImage(named: "tour_guide"))
        
        tabOne.tabBarItem = tabOneBarItem
        
        
        // Create Tab two
        let tabTwo = MapsLayoutUnderSceneView()
        let tabTwoBarItem2 = UITabBarItem(title: "Маршруты", image: UIImage(named: "tour_guide"), selectedImage: UIImage(named: "tour_guide"))
        
        tabTwo.tabBarItem = tabTwoBarItem2
        
        // Create Tab tree
        let tabTree = UIViewController()
        let tabTreeBarItem3 = UITabBarItem(title: "Профиль", image: UIImage(named: ""), selectedImage: UIImage(named: ""))
        
        tabTree.tabBarItem = tabTreeBarItem3
        
        
        self.viewControllers = [tabOne, tabTwo, tabTree]
    }
    
    // UITabBarControllerDelegate method
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0) //.red
        
        tabBar.standardAppearance = appearance
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tabBar.frame.size.height = 55
        tabBar.frame.origin.y = view.frame.height - 55
    }
}
