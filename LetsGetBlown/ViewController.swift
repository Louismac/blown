//
//  ViewController.swift
//  LetsGetBlown
//
//  Created by LouisMcCallum on 16/03/2017.
//  Copyright © 2017 LouisMcCallum. All rights reserved.
//

import UIKit
import QuartzCore
import CoreImage

extension UIImage {
    func crop( rect: CGRect, ciIm:CIImage, ctx:CIContext) -> UIImage? {
        
        if let cropped = ctx.createCGImage(ciIm, from: rect) {
            return UIImage(cgImage: cropped);
        }
        return nil;
    }
    
    func pixelData(cgImage:CGImage,ctx:CGContext, pixelData:inout [UInt8]) {
        
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var pinView: UIView!
    var pins = [[Pin]]()
    var pinViews = [[PinView]]()
    var attractors = Set<Attractor>()
    let withinPin = 2;
    let pinsX = 15;
    let pinsY = 21;
    var pinW:CGFloat {
        get {
            return floor((CGFloat(self.pinView.frame.size.width)/CGFloat(pinsX)));
        }
    }
    var pinH:CGFloat {
        get {
            return floor((CGFloat(self.pinView.frame.size.height)/CGFloat(pinsY)));
        }
    }
    var pixelsX:Int {
        get {
            return pinsX*withinPin;
        }
    }
    var pixelsY:Int {
        get {
            return pinsY*withinPin;
        }
    }
    var pixelW:CGFloat {
        get {
            return floor(CGFloat(pinW/CGFloat(withinPin)))
        }
    }
    var pixelH:CGFloat {
        get {
            return floor(CGFloat(pinH/CGFloat(withinPin)))
        }
    }
    let overlapW:CGFloat = 0.96
    let overlapH:CGFloat = 0.96
    let kBlowVelocity:Float = 14;
    var firstPass = true;
    var hasLaidOutSubViews = false;
    var pixels = false;
    var audioDetector:AudioDetector?;
    
    // MARK:Setup
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        updateMode();
        let link = CADisplayLink(target: self, selector: #selector(ViewController.update));
        link.add(to:.current,forMode:.defaultRunLoopMode);
        
        audioDetector = AudioDetector();
        audioDetector?.delegate=self;
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        if !hasLaidOutSubViews {
            let alignedW = pinW*CGFloat(pinsX);
            var fr = pinView.frame;
            fr.size.width = alignedW;
            pinView.frame = fr;
            var centre = view.center;
            centre.y = pinView.center.y;
            pinView.center = centre;
            hasLaidOutSubViews = true;
        }
    }
    
    func updateMode() {
        updateModel();
        pixels ? getColors():cropImage();
    }
    
    func updateModel() {
        
        pinView.subviews.forEach({$0.removeFromSuperview()});
        pins.removeAll();
        pinViews.removeAll();
        
        for i in 0...pinsX-1 {
            var pinArr = [Pin]();
            var pinViewArr = [PinView]();
            for j in 0...pinsY-1 {
                let fr = pinRectFor(i:i,andJ:j);
                let newPin = Pin();
                newPin.setDefaultColors(w: withinPin, h: withinPin);
                let newPinView = PinView(frame:fr);
                newPinView.pin=newPin;
                newPinView.pixels = pixels;
                pinArr.append(newPin);
                pinViewArr.append(newPinView);
            }
            pins.append(pinArr);
            pinViews.append(pinViewArr);
        }
        
        //one in one out overlap
        
        for i in 0...pinsX-1 {
            for j in 0...pinsY-1 {
                if(i%2==0 && j%2==0) || (i%2==1 && j%2==1) {
                    pinView.addSubview(pinViews[i][j]);
                }
            }
        }
        for i in 0...pinsX-1 {
            for j in 0...pinsY-1 {
                if(i%2==1 && j%2==0) || (i%2==0 && j%2==1) {
                    pinView.addSubview(pinViews[i][j]);
                    //pinViews[i][j].addShadow();
                }
            }
        }
    }
    
    // MARK:Main Loop
    
    func update() {
        
        updateAttractors();
        
        for i in 0...pinsX-1 {
            for j in 0...pinsY-1 {
                
                let pin = pins[i][j];
                if pin.theta<0 || pin.theta>0 || firstPass {
                    pin.increment();
                    pinViews[i][j].setNeedsDisplay();
                }
                
            }
        }
        
        firstPass=false;
        
    }
    
    // MARK:Interaction Handlers
    
    @IBAction func modePressed(_ sender: Any) {
        pixels = !pixels;
        updateMode();
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for i in 0...pinsX-1 {
            for j in 0...pinsY-1 {
                let pinView = pinViews[i][j];
                for touch in touches {
                    let touchLocation = touch.location(in: self.pinView)
                    if pinView.frame.contains(touchLocation) {
                        let pin = pins[i][j];
                        pin.alignWithTouchFromAnchor(touch:touchLocation,anchor:anchorPointFor(pinView:pinView));
                        return;
                    }
                }
            }
        }
    }
    
    // MARK: Attractors
    
    func updatePinsFromAttractors() {
        for i in 0...pinsX-1 {
            for j in 0...pinsY-1 {
                let pinView = pinViews[i][j];
                for attractor in attractors {
                    if pinView.frame.contains(attractor.pt) {
                        let pin = pins[i][j];
                        pin.alignWithTouchFromAnchor(touch:attractor.pt,anchor:anchorPointFor(pinView:pinView));
                    }
                }
            }
        }
    }
    
    func updateAttractors() {
        var toRemove = [Attractor]();
        for attractor in attractors {
            attractor.updatePos();
            if doRemove(attractor:attractor) {
                toRemove.append(attractor);
            }
        }
        attractors = attractors.subtracting(toRemove);
        updatePinsFromAttractors();
    }
    
    func doRemove(attractor:Attractor) -> Bool {
        
        if !view.frame.contains(attractor.pt) {
            return true;
        }
        
        if attractor.hasStopped() {
            return true;
        }
        
        return false;
    }
    
    func newAttractor(vel:Double) {
        DispatchQueue.main.async {
            let a = Attractor();
            a.pt = CGPoint(x: self.pinView.frame.size.width/2, y: self.pinView.frame.size.height);
            a.vel = CGPoint(x:(self.rand()*vel*2)-vel,y:(self.rand()*vel)-(vel*2));
            self.attractors.insert(a);
        }
    }
    
    func velFrom(vol:Float) -> Double {
        return Double(vol+kBlowVelocity);
    }
    
    func overThresholdWith(vol:Float) {
        newAttractor(vel:velFrom(vol: vol));
        newAttractor(vel:velFrom(vol: vol));
    }
    
    // MARK: Image Processing
    
    func cropImage() {
        if let im = UIImage(named:"IMG_2636.JPG") {
            let imW = im.size.width;
            let imH = im.size.height;
            let vH = pinView.frame.size.height;
            let vW = pinView.frame.size.width;
            let hScale = imH/vH;
            let wScale = imW/vW;
            let size = CGSize(width:pinW, height:pinH);
            let dataSize = size.width * size.height * 4
            var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let cgContext = CGContext(data: &pixelData,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: 4 * Int(size.width),
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
            let ctx = CIContext(cgContext:cgContext!,options:nil);
            if let ciIm = CIImage(image:im) {
                for i in 0...pinsX-1 {
                    for j in 0...pinsY-1 {
                        let fr = pinRectFor(i:i,andJ:j);
                        let mirrorY = (vH/2) - (fr.origin.y - (vH/2)) - pinH;
                        let scaleFr = CGRect(x:fr.origin.x*wScale,
                                             y:(mirrorY*hScale),
                                             width:fr.size.width*wScale,
                                             height:fr.size.height*hScale
                        );
                        if let cropped = im.crop(rect:scaleFr,ciIm:ciIm,ctx:ctx) {
                            pinViews[i][j].imV.image = cropped;
                        }
                    }
                }
            }
        }
    }
    
    func getColors() {
        if let im = UIImage(named:"IMG_2636.JPG") {
            let imW = im.size.width;
            let imH = im.size.height;
            let vH = pinView.frame.size.height;
            let vW = pinView.frame.size.width;
            let hScale = imH/vH;
            let wScale = imW/vW;
            let ciIM = CIImage(image:im);
            
            let ciContext = CIContext()
            
            let size = CGSize(width:1,height:1);
            let dataSize = size.width * size.height * 4;
            var pixelData = [UInt8](repeating: 0, count: Int(dataSize));
            let colorSpace = CGColorSpaceCreateDeviceRGB();
            let cgContext = CGContext(data: &pixelData,
                                    width: Int(size.width),
                                    height: Int(size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: 4 * Int(size.width),
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue);
            
            for i in 0...pixelsX-1 {
                for j in 0...pixelsY-1 {
                    let x = floor(CGFloat(i)*pixelW);
                    let y = floor(CGFloat(j)*pixelH);
                    let fr = CGRect(x:x , y: y, width: pixelW, height: pixelH);
                    let mirrorY = (vH/2) - (fr.origin.y - (vH/2)) - pinH;
                    let scaleFr = CGRect(x:fr.origin.x*wScale,
                                         y:(mirrorY*hScale),
                                         width:fr.size.width*wScale,
                                         height:fr.size.height*hScale
                    );
                    let vec = CIVector(cgRect: scaleFr);
                    let filter = CIFilter(name: "CIAreaAverage");
                    filter!.setValue(ciIM, forKey: kCIInputImageKey);
                    filter!.setValue(vec, forKey: kCIInputExtentKey);

                    if let outputImage = filter!.value(forKey: kCIOutputImageKey) as! CIImage! {
                        let newIm = UIImage(ciImage: outputImage);
                        if let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) {
                            newIm.pixelData(cgImage:cgImage,ctx:cgContext!,pixelData:&pixelData);
                            let r = CGFloat(pixelData[0]) / CGFloat(255.0);
                            let g = CGFloat(pixelData[1]) / CGFloat(255.0);
                            let b = CGFloat(pixelData[2]) / CGFloat(255.0);
                            let a = CGFloat(pixelData[3]) / CGFloat(255.0);
                            let pinX = Int(floor(Double(i/withinPin)));
                            let pinY = Int(floor(Double(j/withinPin)));
                            let withinPinX = i%withinPin;
                            let withinPinY = j%withinPin;
                            self.pins[pinX][pinY].colors![withinPinX][withinPinY] = UIColor(red: r, green: g, blue: b, alpha: a)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Helper Methods
    
    func rand() -> Double {
        return Double(Float(arc4random()) / Float(UINT32_MAX))
    }
    
    func pinRectFor(i:Int, andJ j:Int) -> CGRect {
        let fr = CGRect(x:floor(CGFloat(i)*pinW-((pinW*(1-overlapW))/2)),
                        y:floor(CGFloat(j)*pinH-((pinH*(1-overlapH))/2)),
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

