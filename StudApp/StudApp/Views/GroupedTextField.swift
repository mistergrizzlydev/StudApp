//
//  GroupedTextField.swift
//  StudApp
//
//  Created by Steffen Ryll on 31.10.17.
//  Copyright © 2017 Steffen Ryll. All rights reserved.
//

import UIKit

@IBDesignable
final class GroupedTextField: UITextField {
    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        initUserInterface()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initUserInterface()
    }

    // MARK: - User Interface

    private func initUserInterface() {
        borderStyle = .none
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.lightGray.cgColor
    }

    @IBInspectable
    var cornerRadius: CGFloat = UI.defaultCornerRadius {
        didSet {
            layer.cornerRadius = cornerRadius
            layoutSubviews()
        }
    }

    @IBInspectable
    var position: String = Position.middle.rawValue {
        didSet {
            switch Position(rawValue: position) {
            case .top?:
                layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            case .middle?:
                layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            case .bottom?:
                layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            case .none:
                fatalError("Cannot set position with raw value '\(position)'.")
            }
        }
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: cornerRadius, dy: cornerRadius / 2)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }

    // MARK: - Position

    enum Position: String {
        case top, middle, bottom
    }
}
