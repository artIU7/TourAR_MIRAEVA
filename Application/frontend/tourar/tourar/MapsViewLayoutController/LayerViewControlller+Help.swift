//
//  LayerViewControlller+Help.swift
//  tourar
//
//  Created by Артем Стратиенко on 24.06.2024.
//

import Foundation
import UIKit

class LayerViewController: UIViewController {
    //
    var tableParametrs: UITableView  =   UITableView()
    //
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        view.layer.cornerRadius = 25
        self.configLayout()
        // Do any additional setup after loading the view.
    }
    func configLayout() {
        view.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        view.layer.cornerRadius = 10
        // заголовок экрана приветсвия
        let titleScreen = UILabel()
        titleScreen.font = UIFont.systemFont(ofSize: 25)
        titleScreen.numberOfLines = 0
        titleScreen.textAlignment = .center
        titleScreen.text = "Дополнительные предпочтения"
        //
        view.addSubview(titleScreen)
        titleScreen.snp.makeConstraints { (marker) in
            marker.left.right.equalToSuperview().inset(30)
            marker.centerX.equalToSuperview()
            marker.top.equalToSuperview().inset(5)
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    override func viewWillAppear(_ animated: Bool) {
          super.viewWillAppear(animated)
          
          // Get main screen bounds
          let screenSize: CGRect = UIScreen.main.bounds
          let screenWidth = screenSize.width
          let screenHeight = screenSize.height
          tableParametrs.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight);
          tableParametrs.dataSource = self
          tableParametrs.delegate = self
          tableParametrs.register(UITableViewCell.self, forCellReuseIdentifier: "myCell")
          tableParametrs.backgroundColor = .clear
          // заголовок экрана параметрв
          let titlePrepareParametr = UILabel()
          titlePrepareParametr.font = UIFont.systemFont(ofSize: 25)
          titlePrepareParametr.numberOfLines = 0
          titlePrepareParametr.text = "Параметры доступности"
          titlePrepareParametr.textAlignment = .center
          //
          view.addSubview(titlePrepareParametr)
          titlePrepareParametr.snp.makeConstraints { (marker) in
            marker.left.right.equalToSuperview().inset(30)
            marker.centerX.equalToSuperview()
            marker.top.equalToSuperview().inset(5)
        }
        //
        // button continie
        var buttonItem_1parametr =  UIButton()
        buttonItem_1parametr.setImage(UIImage(named: "groupDisableOne"), for: .normal)
        buttonItem_1parametr.imageView?.layer.cornerRadius = 10
        buttonItem_1parametr.layer.borderColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        buttonItem_1parametr.layer.borderWidth = 3
        buttonItem_1parametr.adjustsImageSizeForAccessibilityContentSizeCategory = true
        buttonItem_1parametr.layer.cornerRadius = 10
        //
        view.addSubview(buttonItem_1parametr)
        buttonItem_1parametr.snp.makeConstraints { (marker) in
            marker.bottomMargin.equalToSuperview().inset(20 + 50 + 20)
            marker.left.equalToSuperview().inset(50)
            marker.height.equalTo(50)
        }
        var buttonItem_2parametr =  UIButton()
        buttonItem_2parametr.setImage(UIImage(named: "groupDisableTwo"), for: .normal)
        buttonItem_2parametr.imageView?.layer.cornerRadius = 10
        buttonItem_2parametr.layer.borderColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        buttonItem_2parametr.layer.borderWidth = 3
        buttonItem_2parametr.adjustsImageSizeForAccessibilityContentSizeCategory = true
        buttonItem_2parametr.layer.cornerRadius = 10
        //
        view.addSubview(buttonItem_2parametr)
        buttonItem_2parametr.snp.makeConstraints { (marker) in
            marker.bottomMargin.equalToSuperview().inset(20 + 50 + 20 + 50 + 20 )
            marker.left.equalToSuperview().inset(50)
            marker.height.equalTo(50)
        }
        /*
          self.view.addSubview(tableParametrs)
          tableParametrs.snp.makeConstraints { (marker) in
            marker.left.right.equalToSuperview().inset(0)
            marker.top.equalTo(titlePrepareParametr).inset(20)
            marker.bottom.equalToSuperview().inset(10)
        }
        */
      }
}
extension LayerViewController : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath as IndexPath)
        cell.backgroundColor = .clear
        //cell.textLabel?.text = self.itemsToLoad[indexPath.row]
    return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
     {
         return 3
     }
     
    private func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
         //print("User selected table row \(indexPath.row) and item \(itemsToLoad[indexPath.row])")
    }
}
