var canvas = document.getElementById('canvas');
var ctx = canvas.getContext('2d');
var capturer = new CCapture({ format: 'webm' });

function animate() {
    // Example animation code
    ctx.fillStyle = 'rgba(255, 0, 0, 0.5)';
    ctx.fillRect(0, 0, 100, 100);
    requestAnimationFrame(animate);
}

function startCapture() {
    capturer.start();
    animate();
}

function stopCapture() {
    capturer.stop();
    capturer.save();
}
