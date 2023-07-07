//
//  ViewController.swift
//  OSAT-VideoCompositor
//
//  Created by hdutt on 09/02/2022.
//  Copyright (c) 2022 hdutt. All rights reserved.
//
import UIKit
import SwiftUI

class ViewController: UIViewController {
    var showOldUIController = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if showOldUIController {
            let oldViewController = UIKitAVPlayerViewController()
            navigationController?.addChildViewController(oldViewController)
            navigationController?.view.addSubview(oldViewController.view)
            oldViewController.view.frame = navigationController?.view.bounds ?? .zero
        } else {
            openSwiftUIScreen()
        }
    }
    
    func openSwiftUIScreen() {
        let swiftUIViewController = UIHostingController(rootView: OSATPlayerView())
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.window?.rootViewController = swiftUIViewController
        appDelegate?.window?.makeKeyAndVisible()
    }
}
