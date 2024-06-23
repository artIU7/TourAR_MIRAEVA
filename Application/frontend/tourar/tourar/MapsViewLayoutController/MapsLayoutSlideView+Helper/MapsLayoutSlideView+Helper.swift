//
//  MapsLayoutSlideView+Helper.swift
//  tourar
//
//  Created by Артем Стратиенко on 19.06.2024.
//

import Foundation
import ScalingCarousel
import SnapKit

class SheetControllUnderCollectionView : UIViewController {
    var collectionViewSlide: ScalingCarouselView!
    var imageSetCollection : UIImage!
    override func viewDidLoad() {
        super.viewDidLoad()
        configCollectionView()
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
         if collectionViewSlide != nil {
             collectionViewSlide.deviceRotated()
         }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    private func configCollectionView() {
        
        let frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        collectionViewSlide = ScalingCarouselView(withFrame: frame, andInset: 50)
        collectionViewSlide.scrollDirection = .horizontal
        collectionViewSlide.dataSource = self
        collectionViewSlide.delegate = self
        collectionViewSlide.translatesAutoresizingMaskIntoConstraints = false
        collectionViewSlide.backgroundColor = .clear
        
        collectionViewSlide.register(ImagesPointCell.self, forCellWithReuseIdentifier: "cell")
    }
}
class ImagesPointCell: ScalingCarouselCell {
    
    var imageSlide = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        //
        mainView = UIView(frame: contentView.bounds)
        contentView.addSubview(mainView)
        mainView.snp.makeConstraints { (marker) in
            marker.top.bottom.equalTo(contentView).inset(2)
            marker.left.right.equalTo(contentView).inset(2)
        }
        //
        mainView.addSubview(imageSlide)
        self.imageSlide.snp.makeConstraints { (marker) in
            marker.topMargin.bottomMargin.equalTo(mainView).inset(10)
            marker.leftMargin.rightMargin.equalTo(mainView).inset(10)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SheetControllUnderCollectionView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        if let scalingCell = cell as? ImagesPointCell {
            if ( imageSetCollection != nil )
            {
                scalingCell.imageSlide  = UIImageView(image:  imageSetCollection )
                scalingCell.imageSlide.layer.cornerRadius  = 25
                scalingCell.mainView.backgroundColor = .clear
            }
        }
        DispatchQueue.main.async {
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
        }

        return cell
    }
}

extension SheetControllUnderCollectionView: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        collectionViewSlide.didScroll()
    }
}
