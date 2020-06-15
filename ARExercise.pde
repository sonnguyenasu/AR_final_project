import gab.opencv.*;
import processing.video.*;
import processing.sound.*;

//===============draw function counter========//
int drawCounter = 0;

//===============Sound display variable =======//
SoundFile startGameFile;
SoundFile dieGameFile;
boolean isDeadSoundPlayed;
boolean isGameSoundPlayed;
//===============title display variable =======//
PImage titleImg;
boolean circleOver = false;
int circleSize = 120;   // Diameter of circle
int circleX, circleY;
String test = "Start";
color circleColor,circleHighlight;

PVector location;  // Location of shape
PVector velocity;  // Velocity of shape
PVector gravity;   // Gravity acts at the shape's acceleration
//===============================================//
float pipeWidth;
float pipeGap;
float pipeInterval;
ArrayList<Dokan> dokanArray;

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
int best_score = 0;
boolean new_record = false;
String best_name = "N/A";
int title = 1;


PImage playerImg;
PImage playerImg2;

// Added in Lecture 5 (20/05/27)
KeyState keyState;

void selectCamera() {
  String[] cameras = Capture.list();

  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default");
    cap = new Capture(this, 1280, 720);
  } else if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    printArray(cameras);
    if (!System.getProperty("os.name").startsWith("Windows")) {
      // For MacOS Linux
      // The camera can be initialized directly using an element
      // from the array returned by list():
      cap = new Capture(this, 1280, 720, cameras[1]);
      println("camera inited!");
    } else {
      // For Windows
      // Or, the settings can be defined based on the text in the list
      cap = new Capture(this, 1280, 720, "USB2.0 HD UVC WebCam", 30);
    }
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
    } else if (System.getProperty("os.name").startsWith("Windows")) {
      selectCamera();
      size(cap.width, cap.height);
      opencv = new OpenCV(this, cap.width, cap.height);
    } else {
      size(1280, 720);
    }
  }
}

void setupCamera() {
  if (!USE_SAMPLE_IMAGE) {
    selectCamera();
    opencv = new OpenCV(this, cap.width, cap.height);
  }
}

void setup() {
  smooth();
  markerTracker = new MarkerTracker(kMarkerSize);

  if (!USE_DIRECTSHOW) {
    if (!System.getProperty("os.name").startsWith("Windows")) {
      setupCamera();
    }
    cap.start();
  }

 // Added in Lecture 5 (20/05/27), to manage keyevents
  keyState = new KeyState();
  circleSize = width*120/1280;
  textFont(createFont("Arial", 48));
  playerImg = loadImage("data/peng.png");
  playerImg2 = loadImage("data/peng2.png");
  //playerImg.resize(120,120);
  titleImg = loadImage("data/title.jpg");
  if (System.getProperty("os.name").startsWith("Windows")) {
    // For windows
    titleImg.resize(dcap.width, dcap.height);
  } else {
    // For mac
    titleImg.resize(cap.width, cap.height);
  }
  startGameFile = new SoundFile(this, "data/background.mp3");
  dieGameFile = new SoundFile(this, "data/lose.mp3");
  isDeadSoundPlayed = false; //don't play dead game sound
  isGameSoundPlayed = true; //play the start game sound
  circleColor = color(255);
  circleHighlight = color(0,255,255);
  circleX = width/6+105*width/1280;
  circleY = height*3/4-80*height/720;
  ellipseMode(CENTER);
  location = new PVector(100,100);
  velocity = new PVector(1.5,2.1);
  gravity = new PVector(0,0.2);
  //===================Initialize dokan====================//
  initializeDokan();
  //===================Play the start game sound===========//
  startGameFile.loop();
}

void draw() {
  if (title == 1) {
    titleUpdate(mouseX, mouseY);

    background(titleImg);
    fill(255);
    textSize(width*48/1280);
    textAlign(CENTER);
    text("Marker ver.", width/4, height/2+20*height/720);
    if (circleOver) {
      fill(circleHighlight);
    } else {
      fill(circleColor);
    }
    ellipse(circleX, circleY, circleSize, circleSize);
    fill(0);
    text("Start", width/5+60*width/1280, height*3/4-65*height/720);
    textSize(width*30/1280);
    text("Best score: " + best_score , width/5+60*width/1280, height*3/4+20*height/720);
    text("Player name:" + best_name , width/5+60*width/1280, height*3/4+60*height/720);
    
    // Drawing the bouncing bird
    location.add(velocity); // Add velocity to the location.
    velocity.add(gravity); // Add gravity to velocity
    // Bounce off edges
    if ((location.x > width) || (location.x < 0)) {
      velocity.x = velocity.x * -1;
    }
    if (location.y > height) {
      // We're reducing velocity ever so slightly 
      // when it hits the bottom of the window
      velocity.y = velocity.y * -0.95; 
      location.y = height;
    }
    // Display bird at location vector
    drawCounter = (drawCounter+1)%20;
    if(drawCounter >= 10)  image(playerImg, location.x, location.y, 100, 100);
    else  image(playerImg2, location.x,location.y, 100, 100);
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
    // float pipeWidth = 80;
    //float pipeGap = (pipeGap>0)?pipeGap:random(75, 150);
    // float pipeGap = 120;
    // dokan(pipeWidth, pipeGap);
    drawDokan(dokanArray, score);
    // プレイヤーのプログラム
    player(gy/4);
  }
  // if dead
  if (dead == 1) {
    fill(255, 0, 0);
    textSize(width*72/1280);
    textAlign(CENTER);
    text("GAME OVER", width/2, height/2-60);
    fill(255);
    textSize(width*48/1280);
    text("Your score: " + score, width/2, height/2);
    textSize(width*30/1280);
    text("press ENTER/RETURN for another game!", width/2, height/2+180);
    if(score > best_score){
      best_score = score;
      new_record = true;
      best_name = "";
    }
    if(new_record){
      best_score = score;
      textSize(width*48/1280);
      fill(255, 255, 0);
      text("NEW RECORD!!!!  Type your name:" + best_name, width/2, height/2+80);
    }
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
  textSize(width*48/1280);
  text(score, width/2, 100);

  System.gc();
}

void captureEvent(Capture c) {
  if (!USE_DIRECTSHOW && c.available())
      c.read();
}


//draw the pipe with gradient color
// void drawThePipe(float px,float py,float pipeWidth,float pipeHeight){
//   for(float i = px; i < px+pipeWidth; i++){
//     //idx variable to set up the color
//     int idx = (int)((i - px)*256/pipeWidth);
//     stroke(0,255-idx,255-idx>>1);
//     line(i,py,i,py+pipeHeight);
//   }
// }

void initializeDokan() {
  if (System.getProperty("os.name").startsWith("Windows")) {
    pipeWidth = dcap.width/16;
  } else {
    pipeWidth = cap.width/16;
  }
  pipeGap = 120;
  if (System.getProperty("os.name").startsWith("Windows")) {
    pipeInterval = (dcap.width+pipeWidth)/5-pipeWidth;
  } else {
    pipeInterval = (cap.width+pipeWidth)/5-pipeWidth;
  }

  dokanArray = new ArrayList<Dokan>();
  for (int i = 0; i < 5; i++) {
    dokanArray.add(i, new Dokan(pipeWidth, pipeGap, pipeInterval));
    dokanArray.get(i).setX(dx + i*(pipeWidth + pipeInterval));
    if (i == 0) dokanArray.get(i).setY(dy);
    else dokanArray.get(i).setY(random(height/2, width/2));
  } 
}

void drawDokan(ArrayList<Dokan> queue, int score) {
  for (Dokan dokan : queue) {
    dokan.draw(width, height);
  }
}

//modification in dokan
//taking 2 variables:
//pipeWidth: width of the pipe
//pipeGap: the gap between the upper and the lower pipe
// these variable can be made random later
// void dokan(float pipeWidth, float pipeGap) {
//   // draw pipe
//   dx = dx - 5;
//   //float pipeWidth = 50;
//   //float pipeGap = random(75,150);
//   if (dx + pipeWidth < 0) {
//     dx = width;
//     dy = random(height/2, width/2);
//     score = score + 1;
//     pipeGap = -1;
//   }
//   //lower pipe
//   //fill(0, 255, 0);
//   //rect(dx, dy, 50, height - dy);
//   drawThePipe(dx,dy, pipeWidth, height - dy);
//   // upper pipe
//   //fill(0,255,0);
//   //rect(dx, 0, 50, dy - 150);
//   drawThePipe(dx,0,pipeWidth, dy-pipeGap);
// }

void player(int gy) {
  if(gy != 0){
    y = gy;
  }

  for (Dokan dokan : dokanArray) {
    // collision with lower pipe
    int hit = isHit(x, y, 50, 50, dokan.getX(), dokan.getY(), pipeWidth/2 , height - dokan.getY());
    if (hit == 1) {
      fill(255, 0, 0);
      dead = 1;
      break;
    }
    // collision with upper pipe
    int hit02 = isHit(x, y, 50, 50, dokan.getX(), 0, pipeWidth/2, dokan.getY() - 150);
    if (hit02 == 1) {
      fill(255, 0, 0); 
      dead = 1;
      break;
    }
  }
  
  // out of screen
  if(y < -50 || y > height){
    dead = 1;
  }
  
  // Display bird at location vector
    drawCounter = (drawCounter+1)%20;
    if(drawCounter >=10)  image(playerImg, x, y, 100, 100);
    else  image(playerImg2, x, y, 100, 100);
}

void titleUpdate(int x, int y) {
  if ( overStart(circleX, circleY, circleSize) ) {
    circleOver = true;
  }  else {
    circleOver = false;
  }
}

void mousePressed() {
  if (circleOver) {
    //test = "great";
    title = 0;
  }
}

int isHit(float px, float py, float pw, float ph, float ex, float ey, float ew, float eh) {
  if (px < ex + ew && px + pw > ex) {
    if (py < ey + eh && py + ph > ey) {
      return 1;
    }
  }
  return 0;
}

boolean overStart(int x, int y, int diameter) {
  float disX = x - mouseX;
  float disY = y - mouseY;
  if (sqrt(sq(disX) + sq(disY)) < diameter/2 ) {
    return true;
  } else {
    return false;
  }
}

// this function is to init all variables everytime game starts
void init() {
  x = 100;
  y = 200;
  speed = 0;
  dx = 400;
  dy = 300;
  pipeWidth = (int)width/16;
  pipeGap = 120;
  pipeInterval = (width+pipeWidth)/5-pipeWidth;
  dokanArray = new ArrayList<Dokan>();
  for (int i = 0; i < 5; i++) {
    dokanArray.add(i, new Dokan(pipeWidth, pipeGap, pipeInterval));
    dokanArray.get(i).setX(dx + i*(pipeWidth + pipeInterval));
    if (i == 0) dokanArray.get(i).setY(dy);
    else dokanArray.get(i).setY(random(height/2, width/2));
  } 
  dead = 0;
  score = 0;
  title = 1;
  new_record = false;
}
