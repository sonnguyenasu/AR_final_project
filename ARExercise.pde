import gab.opencv.*;
import processing.video.*;
import processing.sound.*;

//===============Sound display variable =======//
SoundFile startGameFile;
SoundFile dieGameFile;
boolean isDeadSoundPlayed;
boolean isGameSoundPlayed;
//===============================================//

final boolean MARKER_TRACKER_DEBUG = false;

final boolean USE_SAMPLE_IMAGE = false;

// We've found that some Windows build-in cameras (e.g. Microsoft Surface)
// cannot work with processing.video.Capture.*.
// Instead we use DirectShow Library to launch these cameras.
final boolean USE_DIRECTSHOW = true;

final double kMarkerSize = 0.03; // [m]

Capture cap;
DCapture dcap;
OpenCV opencv;

ArrayList<Marker> markers;
MarkerTracker markerTracker;

PImage img;

float x = 100;
float y = 200;
float speed = 0;
float dx = 400;
float dy = 300;
int dead = 0;
int score = 0;
int title = 1;

PImage playerImg;

// Added in Lecture 5 (20/05/27)
KeyState keyState;

void selectCamera() {
  String[] cameras = Capture.list();

  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default");
    cap = new Capture(this, 640, 480);
  } else if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    printArray(cameras);

    // The camera can be initialized directly using an element
    // from the array returned by list():
    //cap = new Capture(this, cameras[5]);

    // Or, the settings can be defined based on the text in the list
    cap = new Capture(this, 1280, 720, "USB2.0 HD UVC WebCam", 30);
  }
}


void settings() {
  if (USE_SAMPLE_IMAGE) {
    size(1000, 730);
    opencv = new OpenCV(this, "./marker_test.jpg");
  } else {
    if (USE_DIRECTSHOW) {
      dcap = new DCapture();
      size(dcap.width, dcap.height);
      opencv = new OpenCV(this, dcap.width, dcap.height);
    } else {
      selectCamera();
      size(cap.width, cap.height);
      opencv = new OpenCV(this, cap.width, cap.height);
    }
  }
}

void setup() {
  smooth();
  markerTracker = new MarkerTracker(kMarkerSize);

  if (!USE_DIRECTSHOW) {
    cap.start();
  }

 // Added in Lecture 5 (20/05/27), to manage keyevents
  keyState = new KeyState();

  textFont(createFont("Arial", 48));
  playerImg = loadImage("data/bird.png");
  startGameFile = new SoundFile(this, "data/background.mp3");
  dieGameFile = new SoundFile(this, "data/lose.mp3");
  isDeadSoundPlayed = false; //don't play dead game sound
  isGameSoundPlayed = true; //play the start game sound
  //===================Play the start game sound===========//
  startGameFile.loop();
}

void draw() {
  if (title == 1) {
    background(0);
    fill(255);
    textSize(48);
    textAlign(CENTER);
    text("Marker Bird", width/2, height/2);
    return;
  }
  ArrayList<Marker> markers = new ArrayList<Marker>();

  if (!USE_SAMPLE_IMAGE) {
    if (USE_DIRECTSHOW) {
      img = dcap.updateImage();
      opencv.loadImage(img);
    } else {
      if (cap.width <= 0 || cap.height <= 0) {
        println("Incorrect capture data. continue");
        return;
      }
      opencv.loadImage(cap);
    }
  }

  markerTracker.findMarker(markers);

  int gy = 0; //player y-coordinate
  for (int i = 0; i < markers.size(); i++) {
    Marker m = markers.get(i);
    Point[] corners = m.corners;
    for(int j = 0; j < 4; j++){
      gy += corners[j].y;
    }
  }
  println(gy/4);

  // if not dead
  if (dead == 0) {
    //Because the player lose, we play the losing sound for once
    //and stop the playing sound. Boolean is to keep track of the sound if it is played
    if(isDeadSoundPlayed)
      isDeadSoundPlayed = false;
    if(!isGameSoundPlayed){
      startGameFile.loop();
      isGameSoundPlayed=true;
    }
    // 土管のプログラム
    float pipeWidth = 80;
    //float pipeGap = (pipeGap>0)?pipeGap:random(75, 150);
    float pipeGap = 120;
    dokan(pipeWidth, pipeGap);
    // プレイヤーのプログラム
    player(gy/4);
  }
  // if dead
  if (dead == 1) {
    fill(255, 0, 0);
    textAlign(CENTER);
    text("GAME OVER", width/2, height/2);
    if(isGameSoundPlayed){  
      startGameFile.stop();
      isGameSoundPlayed = false;
    }
    if(!isDeadSoundPlayed){
      isDeadSoundPlayed = true;
      dieGameFile.play();
    }
  }
  fill(255);
  textAlign(CENTER);
  textSize(48);
  text(score, width/2, 100);

  System.gc();
}

void captureEvent(Capture c) {
  if (!USE_DIRECTSHOW && c.available())
      c.read();
}

//draw the pipe with gradient color
void drawThePipe(float px,float py,float pipeWidth,float pipeHeight){
  for(float i = px; i < px+pipeWidth; i++){
    //idx variable to set up the color
    int idx = (int)((i - px)*256/pipeWidth);
    stroke(0,255-idx,255-idx>>1);
    line(i,py,i,py+pipeHeight);
  }
}
//modification in dokan
//taking 2 variables:
//pipeWidth: width of the pipe
//pipeGap: the gap between the upper and the lower pipe
// these variable can be made random later
void dokan(float pipeWidth, float pipeGap) {
  // draw pipe
  dx = dx - 5;
  //float pipeWidth = 50;
  //float pipeGap = random(75,150);
  if (dx + pipeWidth < 0) {
    dx = width;
    dy = random(height/2, width/2);
    score = score + 1;
    pipeGap = -1;
  }
  //lower pipe
  //fill(0, 255, 0);
  //rect(dx, dy, 50, height - dy);
  drawThePipe(dx,dy, pipeWidth, height - dy);
  // upper pipe
  //fill(0,255,0);
  //rect(dx, 0, 50, dy - 150);
  drawThePipe(dx,0,pipeWidth, dy-pipeGap);
}

void player(int gy) {
  if(gy != 0){
    y = gy;
  }

  // collision with lower pipe
  int hit = isHit(x, y, 50, 50, dx, dy, 50, height - dy);
  if (hit == 1) {
    fill(255, 0, 0);
    dead = 1;
  }
  // collision with upper pipe
  int hit02 = isHit(x, y, 50, 50, dx, 0, 50, dy - 150);
  if (hit02 == 1) {
    fill(255, 0, 0); 
    dead = 1;
  }
  
  // out of screen
  if(y < -50 || y > height){
    dead = 1;
  }
  
  image(playerImg, x, y, 100, 100);
}

int isHit(float px, float py, float pw, float ph, float ex, float ey, float ew, float eh) {
  if (px < ex + ew && px + pw > ex) {
    if (py < ey + eh && py + ph > ey) {
      return 1;
    }
  }
  return 0;
}

void init() {
  x = 100;
  y = 200;
  speed = 0;
  dx = 400;
  dy = 300;
  dead = 0;
  score = 0;
  title = 1;
}
