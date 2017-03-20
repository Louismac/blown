//
//  AudioDetector.swift
//  LetsGetBlown
//
//  Created by LouisMcCallum on 20/03/2017.
//  Copyright © 2017 LouisMcCallum. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CoreAudio

class AudioDetector:NSObject {
    
    var recorder: AVAudioRecorder!
    var levelTimer = Timer()
    var lowPassResults: Double = 0.0
    var delegate:ViewController?
    let kUpdateInterval = 0.3;
    
    func levelTimerCallback() {
        recorder.updateMeters()
        
        if recorder.averagePower(forChannel: 0) > -9 {
            print(recorder.averagePower(forChannel: 0))
            if let caller = delegate {
                caller.overThresholdWith(vol:recorder.averagePower(forChannel: 0));
            }
        }
    }
    
    override init() {
        
        super.init();
        
        let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        }catch {
            print("not set");
        }
        do {
            try audioSession.setActive(true)
        }catch {
            print("not set");
        }
    
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let str = documentsPath+"/record.caf";
        let url = URL(fileURLWithPath: str);
        let recordSettings: [String : AnyObject] = [
            AVFormatIDKey:kAudioFormatLinearPCM as AnyObject,
            AVSampleRateKey:44100.0 as AnyObject,
            AVNumberOfChannelsKey:2 as AnyObject,
            AVEncoderBitRateKey:12800 as AnyObject,
            AVLinearPCMBitDepthKey:16 as AnyObject,
            AVEncoderAudioQualityKey:AVAudioQuality.max.rawValue as AnyObject
        ]
        
        do {
            try recorder = AVAudioRecorder(url: url, settings: recordSettings);
        }catch {
            print("error");
        }
        recorder.prepareToRecord()
        recorder.isMeteringEnabled = true
        
        recorder.record()
        
        self.levelTimer = Timer.scheduledTimer(timeInterval: kUpdateInterval, target: self,selector:#selector(self.levelTimerCallback), userInfo: nil, repeats: true)
    }
}
