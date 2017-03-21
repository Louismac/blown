//
//  ImageTools.swift
//  Blown
//
//  Created by LouisMcCallum on 21/03/2017.
//  Copyright © 2017 LouisMcCallum. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Types

typealias ImageProperties = (hScale:CGFloat,
    wScale:CGFloat,
    vH:CGFloat,
    vW:CGFloat,
    xOffset:CGFloat,
    yOffset:CGFloat,
    cgContext:CGContext,
    im:UIImage
);

class ImageTools:NSObject {
    
    var pinH:CGFloat = 1.0;
    var pinW:CGFloat = 1.0;
    let overlapW:CGFloat = 0.96
    let overlapH:CGFloat = 0.96
    var pinFr:CGRect = CGRect.zero;
    
    required init(pinW:CGFloat = 1.0, pinH:CGFloat = 1.0, pinFr:CGRect) {
        super.init();
        self.pinH = pinH;
        self.pinW = pinW;
        self.pinFr = pinFr;
    }
    
    func propertiesFor(image im:UIImage) -> ImageProperties? {
        
        let imW = im.size.width;
        let imH = im.size.height;
        let vH = pinFr.size.height;
        let vW = pinFr.size.width;
        
        var hScale = imH/vH;
        var wScale = imW/vW;
        if hScale < wScale {
            hScale = wScale;
        } else {
            wScale = hScale;
        }
        
        var yDelta = imH - (vH*hScale);
        if yDelta != 0 {
            yDelta-=(pinH*hScale);
        }
        
        var xDelta = imW - (vW*wScale);
        if xDelta != 0 {
            xDelta-=(pinW*wScale);
        }
        
        let size = CGSize(width:pinW, height:pinH);
        let dataSize = size.width * size.height * 4;
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize));
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        if let cgContext = CGContext(data: &pixelData,
                                     width: Int(size.width),
                                     height: Int(size.height),
                                     bitsPerComponent: 8,
                                     bytesPerRow: 4 * Int(size.width),
                                     space: colorSpace,
                                     bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) {
            
            return ImageProperties(vH:vH,
                                   vW:vW,
                                   hScale:hScale,
                                   wScale:wScale,
                                   xOffset:xDelta/2.0,
                                   yOffset:yDelta/2.0,
                                   cgContext:cgContext,
                                   im:im);
        }
        
        
        return nil;
        
    }
    
    func scaledRectFor(frame fr:CGRect, andImageProperties prop:ImageProperties) -> CGRect {
        
        let mirrorY = (prop.vH/2) - (fr.origin.y - (prop.vH/2)) - pinH;
        let scaleFr = CGRect(x:(fr.origin.x*prop.wScale)+prop.xOffset,
                             y:(mirrorY*prop.hScale)+prop.yOffset,
                             width:fr.size.width*prop.wScale,
                             height:fr.size.height*prop.hScale
        );
        
        return scaleFr;
        
    }
    
    func rectFor(pin coordinate:CGPoint) -> CGRect {
        
        let fr = CGRect(x:floor(CGFloat(coordinate.x)*pinW-((pinW*(1-overlapW))/2)),
                        y:floor(CGFloat(coordinate.y)*pinH-((pinH*(1-overlapH))/2)),
                        width:pinW*(2.0-overlapW),
                        height:pinH*(2.0-overlapH));
        
        return fr;
        
    }
    
    func anchorPointFor(pinView:PinView) -> CGPoint {
        
        let anchor = pinView.layer.anchorPoint;
        let anchorX = (anchor.x*pinView.frame.size.width)+pinView.frame.origin.x;
        let anchorY = (anchor.y*pinView.frame.size.height)+pinView.frame.origin.y;
        
        return CGPoint(x: anchorX, y: anchorY);
        
    }
    
}
