//
//  KeyBoardPublisher.swift
//  OSAT-VideoCompositor_Example
//
//  Created by Rohit Sharma on 19/02/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import SwiftUI
import Combine

/// Publisher to read keyboard changes.
protocol KeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> { get }
}

extension KeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: NSNotification.Name.UIKeyboardWillShow)
                .map { _ in true },
            
            NotificationCenter.default
                .publisher(for: NSNotification.Name.UIKeyboardWillHide)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }
}
