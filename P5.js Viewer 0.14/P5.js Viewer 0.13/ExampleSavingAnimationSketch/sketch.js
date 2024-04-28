

let num = 20; 
let screenSize = 600; 
let centralRadius = 40; 
let startSpeed = 12; 

let acceleration = 0.3; 
let accelerationFactorCap = 8;

let balls = [];

let basicSize = 25; 
let collideFactor = 1; 
function setup() {
  createCanvas(screenSize, screenSize);
  angleMode(RADIANS);
  strokeWeight(2);
  
  for (let i = 0; i < num; i++) {
    let angle = random(0, PI * 2);
    let distance = random(centralRadius, screenSize / 2.6 - basicSize * 1.5);
    balls.push(
      new Ball(
        basicSize,
        screenSize / 2 + distance * cos(angle),
        screenSize / 2 + distance * sin(angle),
        i,
        angle
      )
    );
  }
  
}

function draw() {
  background(244, 250, 255);
  for (let i = 0; i < num; i++) {
    balls[i].basicMove(); 
    balls[i].collide(balls); 
    balls[i].show(); 
  
    var reader_skksn = new FileReader();
canvas.toBlob(function (blob) {
    reader_skksn.readAsDataURL(blob);
    reader_skksn.onloadend = function () {
    var base64data_rrbss = reader_skksn.result;

    window.webkit.messageHandlers.p5js_viewer.postMessage(base64data_rrbss);
  
    var reader_skksn = new FileReader();
canvas.toBlob(function (blob) {
    reader_skksn.readAsDataURL(blob);
    reader_skksn.onloadend = function () {
    var base64data_rrbss = reader_skksn.result;

    window.webkit.messageHandlers.p5js_viewer.postMessage(base64data_rrbss);
  }
  }, 'image/png');
if (frameCount>180) noLoop()}
  }, 'image/png');
if (frameCount>180) noLoop()}
}

class Ball {
  constructor(
    r,
    x,
    y,
    n,
    theta,
    v = int(random(-startSpeed, startSpeed)),
    vx = v * sin(theta),
    vy = v * cos(theta),
    m = r * r * r,
    c = color(random(255), random(255), random(255))
  ) {
    this.r = r;
    this.x = x;
    this.y = y;
    this.n = n;
    this.m = m;
    this.vx = vx;
    this.vy = vy;
    this.c = c;
  }
  show() {
    fill(this.c);
    ellipse(this.x, this.y, this.r, this.r);
  }
  
  basicMove() {
    this.x += this.vx;
    this.y += this.vy;
    if (this.x + this.r >= width + 15 || this.x - this.r <= -15) {
      this.vx *= -1;
      this.x += this.vx;
    }
    if (this.y + this.r >= height + 15 || this.y - this.r <= -15) {
      this.vy *= -1;
      this.y += this.vy;
    }
    
  }
  

  force(ox, oy) {
    this.vy += this.m / (screenSize * 10); 
  }
  
  collide(array) {
    for (let i = 0; i < array.length; i++) {
      if (this.n != i) {
        if (
          dist(this.x, this.y, array[i].x, array[i].y) <=
          array[i].r / 2 + this.r / 2
        ) {
          let sumMass = this.m + array[i].m;
          let newvx1 =
            ((this.m - array[i].m) / sumMass) * this.vx +
            ((2 * array[i].m) / sumMass) * array[i].vx;
          let newvy1 =
            ((this.m - array[i].m) / sumMass) * this.vy +
            ((2 * array[i].m) / sumMass) * array[i].vy;
          let newvx2 =
            ((2 * this.m) / sumMass) * this.vx -
            ((array[i].m - this.m) / sumMass) * array[i].vx;
          let newvy2 =
            ((2 * this.m) / sumMass) * this.vy -
            ((array[i].m - this.m) / sumMass) * array[i].vy;
          this.vx = newvx1;
          this.vy = newvy1;
          this.x += newvx1 * collideFactor;
          this.y += newvy1 * collideFactor;
          array[i].vx = newvx2;
          array[i].vy = newvy2;
          array[i].x += newvx2;
          array[i].y += newvy2;
          this.c = color(random(255), random(255), random(255));
          array[i].c = color(random(255), random(255), random(255));
        }
      }
    }
  }
}

