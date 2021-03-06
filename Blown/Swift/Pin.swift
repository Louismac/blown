//
//  Pin.swift
//  Blown
//
//  Created by LouisMcCallum on 16/03/2017.
//  Copyright © 2017 LouisMcCallum. All rights reserved.
//

import Foundation
import UIKit

class Pin {
    
    let g:Double = 90
    let L = 1.0
    let d = 0.02
    let dt = 0.01
    let damp = 1.4;
    var theta:Double = 0.0
    var thetaDot:Double = 0.0
    var colors:[[UIColor]] = [[UIColor]]();
    var update:Bool = true;
    var image:UIImage!;
    
    func setDefaultColors(w:Int,h:Int) {
        
        colors.removeAll();
        
        for _ in 0...w-1 {
            
            var arr = [UIColor]();
            
            for _ in 0...h-1 {
                
                arr.append(UIColor.clear);
                
            }
            
            colors.append(arr);
            
        }
    }
    
    func increment() {
        
        if(update) {
            
            let thetaDotDot = (-damp*thetaDot) + (-(g/L) * sin(theta))
            thetaDot += thetaDotDot * dt
            theta += thetaDot * dt
            
        } else {
            
            update = true;
            
        }
        
    }
    
    func alignWith(touch pt1:CGPoint, fromAnchor pt2:CGPoint) {
        
        let o = abs(pt1.x-pt2.x);
        let a = abs(pt1.y-pt2.y);
        let h = sqrt(pow(o, 2)+pow(a,2));
        let newTheta = Double((CGFloat.pi/2) - cosh(a/h));
        let leftSide = pt1.x<pt2.x;
        
        theta += (leftSide ? newTheta:-newTheta);
        update=false;
        
    }
    
}
