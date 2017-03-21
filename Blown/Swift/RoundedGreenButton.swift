//
//  RoundedGreenButton.swift
//  Blown
//
//  Created by LouisMcCallum on 21/03/2017.
//  Copyright © 2017 LouisMcCallum. All rights reserved.
//

import Foundation
import UIKit

class RoundedGreenButton:UIButton {

    let blownGreen = UIColor(red: 20/255, green: 191/255, blue: 121/255, alpha: 1.0);
    var spinner:UIActivityIndicatorView!;
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        backgroundColor = blownGreen;
        layer.cornerRadius = 10;
        
        spinner = UIActivityIndicatorView(frame: bounds);
        spinner.isUserInteractionEnabled = false;
        spinner.isHidden = true;
        addSubview(spinner);
        
        
    }
    
    func setEnabled(enabled:Bool) {
        
        DispatchQueue.main.async {
            
            self.isEnabled = enabled;
            self.spinner.isHidden = !enabled;
            
            if(!enabled) {
                self.spinner.startAnimating();
            } else {
                self.spinner.stopAnimating();
            }
            
            self.alpha = enabled ? 1.0:0.5;
            
        }
    }
    
}
