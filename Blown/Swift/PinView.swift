//
//  PinView.swift
//  Blown
//
//  Created by LouisMcCallum on 16/03/2017.
//  Copyright © 2017 LouisMcCallum. All rights reserved.
//

import Foundation
import UIKit

class PinView:UIView {
    
    var pin:Pin=Pin();
    var imV:UIImageView = UIImageView();
    var pixels=false;
    var ciIm:CIImage=CIImage();
    var srcRect:CGRect=CGRect.zero;
    let anchorX = 0.5;
    let anchorY = 0.1;
    
    override init(frame: CGRect) {
        
        super.init(frame: frame);
        imV = UIImageView(frame: bounds);
        imV.backgroundColor=UIColor.clear;
        addSubview(imV);
        backgroundColor=UIColor.clear;
        self.layer.anchorPoint = CGPoint(x:anchorX,y:anchorY);
        
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
        
        if let ctx = UIGraphicsGetCurrentContext() {
            
            if pixels {
                
                let nRows = pin.colors.count;
                let w = frame.size.width/CGFloat(nRows);
                let nColumns = pin.colors[0].count;
                let h = frame.size.height/CGFloat(nColumns);
                
                for i in 0...nRows-1 {
                    for j in 0...nColumns-1 {
                        
                        let rect = CGRect(x:CGFloat(i)*w, y:CGFloat(j)*h, width:w, height:h);
                        ctx.setFillColor(pin.colors[i][j].cgColor);
                        ctx.fill(rect);
                        
                    }
                }
                
            } else {
                
                let w = frame.size.width;
                let h = frame.size.height;
                let rect = CGRect(x:0, y:0, width:w, height:h);
                ctx.setFillColor(UIColor.clear.cgColor);
                ctx.fill(rect);
                
            }
        }
    }
    
}
