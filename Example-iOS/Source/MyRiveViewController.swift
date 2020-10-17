//
//  MyRiveViewController.swift
//  RiveExample
//
//  Created by Matt Sullivan on 10/5/20.
//  Copyright © 2020 Rive. All rights reserved.
//

import UIKit
import RiveRuntime

class MyRiveViewController: UIViewController {

    var resourceName: String?
    var resourceExt: String?
    var artboard: RiveArtboard?
    var instance0: RiveLinearAnimationInstance?
    var instance1: RiveLinearAnimationInstance?
    var displayLink: CADisplayLink?
    var lastTime: CFTimeInterval = 0
    
    init(withResource name: String, withExtension: String) {
        resourceName = name
        resourceExt = withExtension
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        startRive()
    }
    
    override func loadView() {
        // Wire up an instance of MyRiveView to the controller
        let view = MyRiveView()
        view.backgroundColor = UIColor.blue
        self.view = view
    }
    
    func startRive() {
        guard let name = resourceName, let ext = resourceExt else {
            fatalError("No resource or extension name specified")
        }
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            fatalError("Failed to locate \(name) in bundle.")
        }
        guard var data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(url) from bundle.")
        }
        
        // Import the data into a RiveFile
        let bytes = [UInt8](data)
        
        data.withUnsafeMutableBytes{(riveBytes:UnsafeMutableRawBufferPointer) in
            guard let rawPointer = riveBytes.baseAddress else {
                fatalError("File pointer is messed up")
            }
            let pointer = rawPointer.bindMemory(to: UInt8.self, capacity: bytes.count)
            
            guard let riveFile = RiveFile(bytes:pointer, byteLength: UInt64(bytes.count)) else {
                fatalError("Failed to import \(url).")
            }
            
            let artboard = riveFile.artboard()
            
            self.artboard = artboard
            // update the artboard in the view
            (self.view as! MyRiveView).updateArtboard(artboard)
            
            if (artboard.animationCount() == 0) {
                fatalError("No animations in the file.")
            }

            // Fetch the animation and draw a first frame
//            let animation = artboard.animation(at: 0)
//            self.instance = animation.instance()
//            instance.advance(by: 0)
//            instance.apply(to: artboard)
//            artboard.advance(by: 0)
                        
            // Fetch two animations and advance the artboard
            let animation0 = artboard.animation(at: 0)
            self.instance0 = animation0.instance()
            
            let animation1 = artboard.animation(at: 1)
            self.instance1 = animation1.instance()

            artboard.advance(by: 0)
            
            // Run the looping timer
            runTimer()
        }
    }
    
    // Starts the animation timer
    func runTimer() {
        displayLink = CADisplayLink(target: self, selector: #selector(tick));
        displayLink?.add(to: .main, forMode: .default)
    }
    
    // Stops the animation timer
    func stopTimer() {
        displayLink?.remove(from: .main, forMode: .default)
    }
    
    // Animates a frame
    @objc func tick() {
        guard let displayLink = displayLink, let artboard = artboard else {
            // Something's gone wrong, clean up and bug out
            stopTimer()
            return
        }
        
        let timestamp = displayLink.timestamp
        // last time needs to be set on the first tick
        if (lastTime == 0) {
            lastTime = timestamp
        }
        // Calculate the time elapsed between ticks
        let elapsedTime = timestamp - lastTime;
        lastTime = timestamp;
        
        // Advance the animation instance and the artboard
        instance0!.advance(by: elapsedTime) // advance the animation
        instance0!.apply(to: artboard)      // apply to the artboard
        
        instance1!.advance(by: elapsedTime)
        instance1!.apply(to: artboard)
        
        artboard.advance(by: elapsedTime) // advance the artboard
        
        // Trigger a redraw
        self.view.setNeedsDisplay()
    }
}
