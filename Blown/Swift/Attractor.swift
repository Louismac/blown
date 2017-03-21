//
//  Attractor.swift
//  Blown
//
//  Created by LouisMcCallum on 20/03/2017.
//  Copyright © 2017 LouisMcCallum. All rights reserved.
//

import Foundation
import UIKit

typealias Velocity=CGPoint;

class Attractor:NSObject {
    
    var pt = CGPoint.zero;
    var vel:Velocity = CGPoint.zero;
    var g:CGFloat = 0.1;
    
    func updatePos() {
        
        pt.x += vel.x;
        pt.y += vel.y;
        
        if(vel.x<0) {
            vel.x+=g;
            if(vel.x>0) {
                vel.x=0;
            }
        }
        
        if(vel.x>0) {
            vel.x-=g;
            if(vel.x<0) {
                vel.x=0;
            }
        }
        
        if(vel.y<0) {
            vel.y+=g;
            if(vel.y>0) {
                vel.y=0;
            }
        }
        
        if(vel.y>0) {
            vel.y-=g;
            if(vel.y<0) {
                vel.y=0;
            }
        }
        
    }
    
    func hasStopped() -> Bool {
        
        if (vel.x==0 && vel.y==0) {
            return true;
        }
        
        return false;
    
    }
    
}
