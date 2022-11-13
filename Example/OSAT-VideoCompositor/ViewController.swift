//
//  ViewController.swift
//  OSAT-VideoCompositor
//
//  Created by hdutt on 09/02/2022.
//  Copyright (c) 2022 hdutt. All rights reserved.
//

import OSAT_VideoCompositor
import UIKit

class ViewController: UIViewController {
    private var videoEditor: VideoPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = Bundle.main.url(forResource: "Demo", withExtension: "mp4")!
        videoEditor = VideoPlayer(frame: .zero, url: url)
        videoEditor!.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoEditor!)
        
        NSLayoutConstraint.activate([
            videoEditor!.heightAnchor.constraint(equalTo: view.heightAnchor),
            videoEditor!.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        videoEditor?.play()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
            coordinator.animate(alongsideTransition: { (context) in
            }) { [weak self] (context) in
                guard let self = self else { return }
                self.videoEditor?.transitionView(to: size)
            }
    }
}

