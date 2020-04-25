//
//  AttachmentView.swift
//  customviewtest
//
//  Created by Thomas Böhm on 04.12.18.
//  Copyright © 2018 Thomas Böhm. All rights reserved.
//

import UIKit

@IBDesignable
class AttachmentView: UIView {

    @IBOutlet private var contentView: UIView!
    // outlets have to be public
    // swiftlint:disable private_outlet
    @IBOutlet public weak var photoButton: UIButton!
    @IBOutlet public weak var videoButton: UIButton!
    @IBOutlet public weak var audioButton: UIButton!
    @IBOutlet public weak var documentButton: UIButton!
    // swiftlint:enable private_outlet
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSelf()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSelf()
    }
    private func initSelf() {
        let bundle = Bundle(for: type(of: self))
        bundle.loadNibNamed("AttachmentView", owner: self, options: nil)
        
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundColor = .clear
    }

    @IBInspectable private var fillColor: UIColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    
    override func draw(_ rect: CGRect) {
        let triangleWidth: CGFloat = 15
        let triangleHeight: CGFloat = 10
        fillColor.setFill()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: (bounds.width / 2) - (3 * triangleWidth), y: bounds.height))
        path.addLine(to: CGPoint(x: (bounds.width / 2) - (3 * triangleWidth) + triangleWidth / 2, y: bounds.height - triangleHeight))
        path.addLine(to: CGPoint(x: (bounds.width / 2) - (3 * triangleWidth) - triangleWidth / 2, y: bounds.height - triangleHeight))
        path.fill()
        let roundedRect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - triangleHeight)
        let path2 = UIBezierPath(roundedRect: roundedRect, cornerRadius: 10)
        path2.fill()
    }
}
