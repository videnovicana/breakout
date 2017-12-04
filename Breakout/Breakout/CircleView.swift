//
//  CircleView.swift
//  Breakout
//
//  Created by ana videnovic on 12/4/17.
//  Copyright © 2017 ana videnovic. All rights reserved.
//

import UIKit

class CircleView: UIView {

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(self.bounds.size.width, self.bounds.size.height) / 2
    }
}
