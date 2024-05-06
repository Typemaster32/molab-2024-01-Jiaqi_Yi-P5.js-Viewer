# Save Animation

# --

https://nyu.zoom.us/rec/share/47wJzLhkEEUgRnhArPfoxzv4w-8fdBK0_1BcvUkNeFNt8w0H1i3JgpQ9S67QlX4J.OW8iK11M17OsJF-i

zoom recording 2024-04-03 Jiaqi Yi [jy4421@nyu.edu](mailto:jy4421@nyu.edu)

# --
1. canvas.toBlob(function(blob) {
console.log(blob);
// Example: Handle the blob here, e.g., display it, save it, or send it somewhere
}, 'image/png');
2. var reader = new FileReader();
reader.readAsDataURL(blob);
reader.onloadend = function() {
var base64data = reader.result;
console.log(base64data);
}
3.





// javascript: blob to base64 string

https://stackoverflow.com/questions/18650168/convert-blob-to-base64

var reader = new FileReader();

reader.readAsDataURL(blob);

reader.onloadend = function() {

var base64data = reader.result;

console.log(base64data);

}

# --

// Swift converting base64 string to Data

var data = Data(base64Encoded: recording_base64, options: .ignoreUnknownCharacters)

# --

// receiving a javascript post message in Swift

https://github.com/molab-itp/98-MoGallery

struct WebView : UIViewRepresentable {

func userContentController(

_ userContentController: WKUserContentController,

didReceive message: WKScriptMessage

# --

// send an javascript object to Swift code

https://github.com/molab-itp/p5videoKit

https://github.com/molab-itp/p5videoKit/blob/main/src/videoKit/p5VideoKit.js

if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.dice) {

window.webkit.messageHandlers.dice.postMessage(opt);

} else {

if (dice.warning) {

console.log('dice opt=' + JSON.stringify(opt));

}

}
