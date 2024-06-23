//
//  MapObjectPanoramaView.swift
//  tourar
//
//  Created by Артем Стратиенко on 13.06.2024.
//

import Foundation
import ScalingCarousel
import AVFoundation
import YandexMapsMobile
import SnapKit

// test voice helper function before real load data
var mocObjectTourPoint = [0:"Театр на маяковской построенный в 1954 году в Городе Ногинск",
                          1:"Площадь Славы установленная в 1945 году",
                          2:"Смотровая Площадь у Ледового дворца Спорта Кристалл - Электросталь",
                          3:"Музей Изобразительных искусств открытый в 2020 году - Художников Коняшиным Дмитрием Юрьевичем"]
var mocPositionPoint  = [0:YMKPoint(latitude: 55.73, longitude: 35.28),
                         1:YMKPoint(latitude: 54.73, longitude: 37.28),
                         2:YMKPoint(latitude: 53.73, longitude: 39.28),
                         3:YMKPoint(latitude: 56.73, longitude: 34.28)]
//
class CodeCell: ScalingCarouselCell {
    
    var labelPoint = UILabel()
    var imageSlide = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        mainView = UIView(frame: contentView.bounds)
        contentView.addSubview(mainView)
        mainView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
    }
    func setConstraintsItem()
    {
        mainView.addSubview(labelPoint)
        self.labelPoint.snp.makeConstraints { (marker) in
            marker.topMargin.equalTo(mainView).inset(10)
            marker.centerXWithinMargins.equalTo(mainView)
            marker.leftMargin.rightMargin.equalTo(mainView).inset(10)
        }
        imageSlide = UIImageView(image: UIImage(named: "n_logo"))
        mainView.addSubview(imageSlide)
        self.imageSlide.snp.makeConstraints { (marker) in
            marker.top.equalTo(labelPoint).inset(10)
            marker.centerXWithinMargins.equalTo(mainView)
            marker.leftMargin.rightMargin.equalTo(mainView).inset(10)
            marker.bottomMargin.equalTo(mainView).inset(10)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CodeViewController: UIViewController {
    // init mapView Layer
    lazy var mapView: YMKMapView = MapsViewBaseLayout().mapView
    // MARK: - Properties (Private)
    fileprivate var scalingCarousel: ScalingCarouselView!

    var tabBarTag: Bool = true

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(mapView)
        self.mapView.snp.makeConstraints { (marker) in
            marker.top.equalTo(self.view).inset(0)
            marker.left.right.equalTo(self.view).inset(0)
            marker.bottom.equalTo(self.view).inset(0)
        }
        self.title = "Обзор"
        //
        addCarousel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
         if scalingCarousel != nil {
            scalingCarousel.deviceRotated()
         }
    }
    override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
          
           if tabBarTag == true {
            self.tabBarController?.tabBar.tintColor =  #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            self.tabBarController?.tabBar.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
           } else {
               self.tabBarController?.tabBar.tintColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
           }
    }
    
    // MARK: - Configuration
    
    private func addCarousel() {
        
        let frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        scalingCarousel = ScalingCarouselView(withFrame: frame, andInset: 50)
        scalingCarousel.scrollDirection = .horizontal
        scalingCarousel.dataSource = self
        scalingCarousel.delegate = self
        scalingCarousel.translatesAutoresizingMaskIntoConstraints = false
        scalingCarousel.backgroundColor = .clear
        
        scalingCarousel.register(CodeCell.self, forCellWithReuseIdentifier: "cell")
        
        view.addSubview(scalingCarousel)
        
        // Constraints
        scalingCarousel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1).isActive = true
        scalingCarousel.heightAnchor.constraint(equalToConstant: 150).isActive = true
        scalingCarousel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scalingCarousel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
    }
}

extension CodeViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let scalingCell = cell as? CodeCell {
            // label
            scalingCell.labelPoint.text = "Test : \(mocObjectTourPoint[indexPath.item]!)"
            scalingCell.labelPoint.adjustsFontSizeToFitWidth = true
            scalingCell.labelPoint.adjustsFontForContentSizeCategory = true
            scalingCell.labelPoint.numberOfLines = 2
            scalingCell.labelPoint.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            // image
            scalingCell.imageSlide  = UIImageView(image: UIImage(named: "n_logo"))
            scalingCell.mainView.backgroundColor = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
            scalingCell.setConstraintsItem()
        }
        DispatchQueue.main.async {
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
        }

        return cell
    }
    func voiceHelperUI(textSpeech : String)
    {
        // добавляем озвучку перехода на главный таб бар
        let utterance = AVSpeechUtterance(string: "\(textSpeech)")
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
    }
}

extension CodeViewController: UICollectionViewDelegate {
    func moveCoordinatePosition(index : Int )
    {
        //
        let mapObjects = mapView.mapWindow.map.mapObjects
        let placemark = mapObjects.addPlacemark(with: mocPositionPoint[index]!)
        placemark.setIconWith(UIImage(named: "SearchResult")!)
        //
        mapView.mapWindow.map.move(
            with: YMKCameraPosition(target: mocPositionPoint[index]!, zoom: 17, azimuth: 40, tilt: 190.0),
            animationType: YMKAnimation(type: YMKAnimationType.linear, duration: 1),
            cameraCallback: nil)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("[DEBUG:scrollViewDidEndDecelerating]")
        if ( scalingCarousel.currentCenterCellIndex != nil )
        {
            voiceHelperUI(textSpeech: "Выбрали обьект :" +
                          mocObjectTourPoint[scalingCarousel.currentCenterCellIndex!.item]!)
            moveCoordinatePosition(index: scalingCarousel.currentCenterCellIndex!.item)
        }
      
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scalingCarousel.didScroll()
    }
}
