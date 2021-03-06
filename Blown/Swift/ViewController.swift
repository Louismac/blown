//
//  ViewController.swift
//  Blown
//
//  Created by LouisMcCallum on 16/03/2017.
//  Copyright © 2017 LouisMcCallum. All rights reserved.
//

import UIKit
import QuartzCore
import CoreImage
import PKHUD

// MARK: -  UIImage Extensions

extension UIImage {
    func crop(toRect rect: CGRect, withCIImage ciIm:CIImage, inContext ciContext:CIContext) -> UIImage? {
        
        if let cropped = ciContext.createCGImage(ciIm, from: rect) {
            return UIImage(cgImage: cropped);
        }
        return nil;
    }
    
    func pixelData(cgImage:CGImage, pixelData:inout [UInt8])
    {

        if let cgContext = CGContext(data: &pixelData,
                                     width: Int(size.width),
                                     height: Int(size.height),
                                     bitsPerComponent: 8,
                                     bytesPerRow: 4,
                                     space: CGColorSpaceCreateDeviceRGB(),
                                     bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) {
            cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
    }
    
    convenience init(view: UIView) {
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.init(cgImage:(image?.cgImage)!)
    }
}

//MARK: - Main Class

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var pinView: UIView!
    @IBOutlet weak var modeButton: RoundedGreenButton!
    @IBOutlet weak var selectPhotoButton: RoundedGreenButton!
    
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

    let blowVelocity:Float = 14;
    var firstPass = true;
    var pinsComplete = false;
    var pixelsComplete = false;
    var hasLaidOutSubViews = false;
    var pixels = false;
    let blownGreen = UIColor(red: 20/255, green: 191/255, blue: 121/255, alpha: 1.0);
    
    var audioDetector:AudioDetector?;
    var imageTools:ImageTools!;
    let imagePicker = UIImagePickerController();
    var image:UIImage? = UIImage(named: "blowninstructions");
    let queue = DispatchQueue(label: "com.blown.photoqueue");
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let link = CADisplayLink(target: self, selector: #selector(ViewController.update));
        link.add(to:.current,forMode:.defaultRunLoopMode);
        
        audioDetector = AudioDetector();
        audioDetector?.delegate=self;
        
        imagePicker.delegate = self;
        
        HUD.dimsBackground = true;
        HUD.allowsInteraction = false;
        
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews();
        
        if !hasLaidOutSubViews {
            
            //Correct for pixel alignment
            let alignedW = pinW*CGFloat(pinsX);
            var fr = pinView.frame;
            fr.size.width = alignedW;
            pinView.frame = fr;
            
            var centre = view.center;
            centre.y = pinView.center.y;
            pinView.center = centre;
            
            imageTools = ImageTools(pinW:pinW,pinH:pinH,pinFr:pinView.frame);
            
            initModel();
            
            modeButton.setEnabled(enabled: false);
            modeButton.spinner.isHidden = true;
            
            newPhotoSelected();
            
            instructionLabel.isHidden = true;
            pinView.layer.borderWidth = 0.0;
            
            hasLaidOutSubViews = true;
    
        }
    }
    
    func clear() {
        for i in 0...pinsX-1 {
            for j in 0...pinsY-1 {
                
                pins[i][j].image = UIImage();
                pins[i][j].setDefaultColors(w: withinPin, h: withinPin);
                pinViews[i][j].pixels = pixels;
                
            }
        }
    }
    
    func newPhotoSelected() {
        
        modeButton.spinner.isHidden = false;
        pixels = false;
        pixelsComplete = false;
        pinsComplete = false;
        modeButton.setEnabled(enabled: false);
        instructionLabel.isHidden = false;
        
        showProcessingSpinner();
        
        queue.async {
            
            //Place image on clear backing to remove black edges
            let backingView = UIImageView(frame: self.pinView.frame);
            backingView.backgroundColor = UIColor.clear;
            backingView.image = self.image;
            backingView.contentMode = UIViewContentMode.scaleAspectFit;
            self.image = UIImage(view:backingView);
            
            self.clear();

            self.setPins(fromImage: self.image!)
            
            DispatchQueue.main.async {
                self.refreshViews();
            }
            
            self.setPixels(fromImage: self.image!);
        }
        
    }
    
    func updateMode() {
        
        if pixels,!pixelsComplete {
            
            showProcessingSpinner();
            
            queue.async {
                self.setPixels(fromImage: self.image!);
                DispatchQueue.main.async {
                    self.refreshViews();
                }
                
            }
            
        } else if !pixels,!pinsComplete {
            
            showProcessingSpinner();
            
            queue.async {
                
                self.setPins(fromImage: self.image!);
                DispatchQueue.main.async {
                    self.refreshViews();
                }
                
            }
            
        } else {
            
            refreshViews();
        
        }
    
    }
    
    func refreshViews() {
        
        HUD.hide();
        modeButton.setTitle((pixels ? "Photo":"Pixels"), for: UIControlState.normal);
        for i in 0...pinsX-1 {
            for j in 0...pinsY-1 {
                
                let pv = pinViews[i][j];
                pv.imV.isHidden = pixels;
                pv.pixels = pixels;
                
                if(!pixels) {
                    pv.imV.image = pins[i][j].image;
                }
                pv.setNeedsDisplay();
            }
        }
    }
    
    func initModel() {
        
        //Clear old views
        pinView.subviews.forEach({$0.removeFromSuperview()});
        pins.removeAll();
        pinViews.removeAll();
        
        for i in 0...pinsX-1 {
            
            var pinArray = [Pin]();
            var pinViewArray = [PinView]();
            
            for j in 0...pinsY-1 {
                
                let newPin = Pin();
                pinArray.append(newPin);
                newPin.setDefaultColors(w: withinPin, h: withinPin);

                let fr = imageTools.rectFor(pin:CGPoint(x:i,y:j));
                let newPinView = PinView(frame:fr);
                newPinView.pin = newPin;
                newPinView.pixels = pixels;
                pinViewArray.append(newPinView);
                
            }
            
            pins.append(pinArray);
            pinViews.append(pinViewArray);
            
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
                }
            }
        }
        
    }
    
    // MARK: - Main Loop
    
    func update() {
        
        updateAttractors();
        
        for i in 0...pinsX-1 {
            for j in 0...pinsY-1 {
                
                let pin = pins[i][j];
                
                //Only update if not still
                if pin.theta<0 || pin.theta>0 || firstPass {
                    
                    pin.increment();
                    pinViews[i][j].setNeedsDisplay();
                
                }
            }
        }
        
        firstPass=false;
        
    }
    
    // MARK: - Interaction Handlers
    
    @IBAction func loadImageButtonPressed(sender: UIButton) {
        
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func modeButtonPressed(_ sender: UIButton) {
        
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
                        pin.alignWith(touch:touchLocation,fromAnchor:imageTools.anchorPointFor(pinView:pinView));
                        
                        // Early exit
                        
                        return;
                    }
                }
            }
        }
        
    }
    
    // MARK: - Attractors
    
    func updatePinsFromAttractors() {
        
        for i in 0...pinsX-1 {
            
            for j in 0...pinsY-1 {
                
                let pinView = pinViews[i][j];
                
                for attractor in attractors {
                    
                    if pinView.frame.contains(attractor.pt) {
                        
                        let pin = pins[i][j];
                        pin.alignWith(touch:attractor.pt,fromAnchor:imageTools.anchorPointFor(pinView:pinView));
                    
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
    
    func overThresholdWith(vol:Float) {
        
        newAttractor(vel:velFrom(vol: vol));
        newAttractor(vel:velFrom(vol: vol));
        
    }
    
    // MARK: - UIImagePickerControllerDelegate Methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if var pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            if pickedImage.imageOrientation==UIImageOrientation.left ||
                pickedImage.imageOrientation==UIImageOrientation.right ||
                pickedImage.imageOrientation==UIImageOrientation.down {
                    UIGraphicsBeginImageContext(pickedImage.size);
                    pickedImage.draw(at: CGPoint(x:0,y:0));
                    pickedImage=UIGraphicsGetImageFromCurrentImageContext()!;
                    UIGraphicsEndImageContext();
            }
            image = pickedImage;
            newPhotoSelected()
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel() {
        
        dismiss(animated: true, completion: nil)
        
    }
    
    // MARK: - Image Processing
    
    func setPins(fromImage image:UIImage) {
        
        if let imageProperties = imageTools.propertiesFor(image:image) {
            
            let ciContext = CIContext(cgContext:imageProperties.cgContext,options:nil);
            
            if let ciIm = CIImage(image:imageProperties.im) {
                
                for i in 0...pinsX-1 {
                    for j in 0...pinsY-1 {
                        
                        let fr = imageTools.rectFor(pin:CGPoint(x:i,y:j));
                        let scaleFr = imageTools.scaledRectFor(frame:fr, andImageProperties:imageProperties);
                        
                        if let cropped = imageProperties.im.crop(toRect:scaleFr,
                                                                 withCIImage:ciIm,
                                                                 inContext:ciContext) {
                            
                            pins[i][j].image = cropped;
                        
                        }
                    }
                }
            }
        }
        pinsComplete = true;
    }
    
    func setPixels(fromImage image:UIImage) {
        
        if let imageProperties = imageTools.propertiesFor(image:image) {
            
            let ciIM = CIImage(image:imageProperties.im);
            let ciContext = CIContext()
            
            for i in 0...pixelsX-1 {
                for j in 0...pixelsY-1 {
                    
                    let x = floor(CGFloat(i)*pixelW);
                    let y = floor(CGFloat(j)*pixelH);
                    let fr = CGRect(x:x , y: y, width: pixelW, height: pixelH);
                    let scaleFr = imageTools.scaledRectFor(frame:fr, andImageProperties:imageProperties);
                    
                    let vec = CIVector(cgRect: scaleFr);
                    let filter = CIFilter(name: "CIAreaAverage");
                    filter!.setValue(ciIM, forKey: kCIInputImageKey);
                    filter!.setValue(vec, forKey: kCIInputExtentKey);

                    if let outputImage = filter!.value(forKey: kCIOutputImageKey) as! CIImage! {
                        
                        let newIm = UIImage(ciImage: outputImage);
                        
                        if let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) {
                            
                            var pixelData = [UInt8](repeating: 0, count: 4);
                            newIm.pixelData(cgImage: cgImage,pixelData: &pixelData);
                            setColorOf(pixel: CGPoint(x:i,y:j), withColor: pixelData);
                            
                        }
                    }
                }
            }
        }
        
        modeButton.setEnabled(enabled: true);
        pixelsComplete = true;
    
    }
    
    func setColorOf(pixel coordinate:CGPoint, withColor pixelData:[UInt8]) {
        
        let r = CGFloat(pixelData[0]) / CGFloat(255.0);
        let g = CGFloat(pixelData[1]) / CGFloat(255.0);
        let b = CGFloat(pixelData[2]) / CGFloat(255.0);
        var a = CGFloat(pixelData[3]) / CGFloat(255.0);
        
        if r==0 && g==0 && b==0 {
            a = 0;
        }
        
        let pinX = Int(floor(Double(coordinate.x/CGFloat(withinPin))));
        let pinY = Int(floor(Double(coordinate.y/CGFloat(withinPin))));
        
        let withinPinX = Int(coordinate.x)%withinPin;
        let withinPinY = Int(coordinate.y)%withinPin;
        
        pins[pinX][pinY].colors[withinPinX][withinPinY] = UIColor(red: r, green: g, blue: b, alpha: a);
        
    }
    
    // MARK: - Helper Methods
    
    func velFrom(vol:Float) -> Double {
        
        return Double(vol+blowVelocity);
        
    }
    
    func rand() -> Double {
        
        return Double(Float(arc4random()) / Float(UINT32_MAX));
        
    }
    
    func showProcessingSpinner() {
        
        DispatchQueue.main.async {
            HUD.show(.labeledProgress(title: "Please wait", subtitle: "Processing"), onView: self.view);
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

