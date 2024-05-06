//
//  5-9.ViewController.swift
//  P5.js Viewer 0.13
//
//  Created by Jiaqi Yi on 4/8/24.
//

import Foundation

import WebKit

class ViewController: UIViewController, WKScriptMessageHandler {
    
    var webView: WKWebView!
    
    override func viewDidLoad() {
        print("[ViewController][ViewController]")
        super.viewDidLoad()
        
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "messageHandler")
        
        webView = WKWebView(frame: view.bounds, configuration: config)
        view.addSubview(webView)
        
        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url)
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "messageHandler", let messageBody = message.body as? String {
            print("Received base64 string from JS:", messageBody)
            // Handle the base64 string here, such as converting it to UIImage
        }
    }
}


/*
 function setup() {
 createCanvas(100, 100);
 }
 
 function draw() {
 background(220);
 //Start of inserting;
 var reader_skksn = new FileReader();
 canvas.toBlob(function (blob) {
 reader_skksn.readAsDataURL(blob);
 reader_skksn.onloadend = function () {
 var base64data_rrbss = reader_skksn.result;
 console.log(base64data_rrbss);
 window.webkit.messageHandlers.messageHandler.postMessage(base64data);
 }
 }, 'image/png');
 //End of inserting;
 }
 */
