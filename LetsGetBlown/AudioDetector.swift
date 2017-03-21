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
    var lowPassResults:Double = 0.0
    var delegate:ViewController?
    let kUpdateInterval = 0.3;
    let threshold:Float = -10;
    
    func levelTimerCallback() {
        
        recorder.updateMeters()
        
        if recorder.averagePower(forChannel: 0) > threshold{
                        
            if let caller = delegate {
                caller.overThresholdWith(vol:recorder.averagePower(forChannel: 0));
            }
            
        }
        
    }
    
    override init() {
        
        super.init();
        
        let audioSession:AVAudioSession = AVAudioSession.sharedInstance();
        let recordSettings: [String : Any] = [
            AVFormatIDKey:kAudioFormatLinearPCM,
            AVSampleRateKey:44100.0,
            AVNumberOfChannelsKey:2,
            AVEncoderBitRateKey:12800,
            AVLinearPCMBitDepthKey:16,
            AVEncoderAudioQualityKey:AVAudioQuality.max.rawValue
        ]
        
        do {
            
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord);
            try audioSession.setActive(true);
            try recorder = AVAudioRecorder(url: URLForAudio(), settings: recordSettings);
            recorder.prepareToRecord();
            recorder.isMeteringEnabled = true;
            recorder.record();

        } catch {
            
            print("warning: audio session failed set up \(error)");
            
        }
        
        levelTimer = Timer.scheduledTimer(timeInterval: kUpdateInterval,
                                                target: self,
                                              selector:#selector(self.levelTimerCallback),
                                              userInfo: nil,
                                               repeats: true)
    }
    
    func URLForAudio() -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
        let str = documentsPath+"/recording.caf";
        return URL(fileURLWithPath: str);
    }
}
