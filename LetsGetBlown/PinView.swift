//
//  PinView.swift
//  LetsGetBlown
//
//  Created by LouisMcCallum on 16/03/2017.
//  Copyright © 2017 LouisMcCallum. All rights reserved.
//

import Foundation
import UIKit

extension Double {
    var degreesToRadians: CGFloat { return CGFloat(self) * .pi / 180 }
}
extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

class PinView:UIView {
    
    var pin:Pin=Pin();
    var imV:UIImageView = UIImageView();
    var pixels=false;
    var ciIm:CIImage=CIImage();
    var srcRect:CGRect=CGRect.zero;
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        imV = UIImageView(frame: bounds);
        addSubview(imV);
        self.layer.anchorPoint = CGPoint(x:0.5,y:0.1);
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addShadow() {
        layer.masksToBounds = false;
        layer.shadowOffset = CGSize(width:-1,height:1);
        layer.shadowRadius = 2;
        layer.shadowOpacity = 0.1;
    }
    
    override func draw(_ rect: CGRect) {
        
        let angle = pin.theta
        let rotate = CGAffineTransform (rotationAngle:CGFloat(angle));
        self.transform = rotate;
        if pixels {
            let ctx = UIGraphicsGetCurrentContext()
            let nRows = pin.colors!.count;
            let w = frame.size.width/CGFloat(nRows);
            let nColumns = pin.colors![0].count;
            let h = frame.size.height/CGFloat(nColumns);
            
            for i in 0...nRows-1 {
                for j in 0...nColumns-1 {
                    let rect = CGRect(x:CGFloat(i)*w, y:CGFloat(j)*h, width:w, height:h);
                    ctx!.setFillColor(pin.colors![i][j].cgColor);
                    ctx!.fill(rect);
                }
            }
        } 
//        let rect = CGRect(x:0, y:0, width:frame.size.width, height:frame.size.height);
//        ctx!.setStrokeColor(pin.colors![0][0].cgColor);
//        ctx!.setLineWidth(2.0);
//        ctx!.stroke(rect);
//        
    }
    
}
