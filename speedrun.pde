import oscP5.*;
import netP5.*;

OscP5 oscP5;

long time = 0;
long startTime = 0;
boolean timerRunning = false;
int currentScene = 0;

NetAddress myRemoteLocation;                            
String serverIP = "127.0.0.1";   
PFont font;

long lastDebrisTime = 0;
boolean beaconSpotted = false;

void setup() {   
  size(800, 600, P2D);
  myRemoteLocation = new NetAddress(serverIP, 12000);
  font = loadFont("HanzelExtendedNormal-48.vlw");
  oscP5 = new OscP5(this, 12010);
}


void draw() {
  background(0, 0, 0);
  if (timerRunning) {
    time = millis() - startTime;
  }

  textFont(font, 128);
  long s = time / 1000;
  long m = s / 60;

  String st = (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
  text(st, 100, 300);


  //do events for scene
  if (currentScene == 3) {
    if (lastDebrisTime + 7000 < millis()) {
      lastDebrisTime = millis();
      OscMessage me  = new OscMessage("/scene/warzone/createBastard");
      oscP5.send(me, myRemoteLocation);
    }
  }
}

void sceneChange(int to) {
  if (to == 0) {
    //turn on training missiles
    OscMessage m  = new OscMessage("/scene/launchland/trainingMissiles");
    m.add( 1 );
    oscP5.send(m, myRemoteLocation);
  } 
  else if (to == 3) {
    //start the war as soon as scene is loaded
    OscMessage m  = new OscMessage("/scene/warzone/warzonestart");
    oscP5.send(m, myRemoteLocation);
    m  = new OscMessage("/scene/warzone/missileLauncherStatus");
    m.add(1);
    oscP5.send(m, myRemoteLocation);

    OscMessage msg = new OscMessage("/scene/warzone/missileRate");    
    msg.add(5);
    oscP5.send(msg, myRemoteLocation);
  }


  currentScene = to;
}

void begin() {
  time = 0;
  startTime = millis();
  currentScene = 0;
  timerRunning = true;
  beaconSpotted = false;
}

void end() {
  //wait for reset
  timerRunning = false;
}



void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/scene/change")) {
    int val = theOscMessage.get(0).intValue();
    sceneChange(val);
  } 
  else if (theOscMessage.checkAddrPattern("/system/misc/dockingClamp")) {
    int val = theOscMessage.get(0).intValue();
    if (val == 1) {
      begin();
    }
  } 
  else if (theOscMessage.checkAddrPattern("/scene/launchland/startDock")) {
    end();
  } 
  else if ( theOscMessage.checkAddrPattern("/game/speedrun/beaconDone")) {
    int v = theOscMessage.get(0).intValue();
    println(v);
    if (v == 5 && !beaconSpotted) {
      //spawn the gate
      
      OscMessage msg = new OscMessage("/scene/warzone/spawnGate");    

      oscP5.send(msg, myRemoteLocation);
      beaconSpotted = true;
    }
  }else if (theOscMessage.checkAddrPattern("/scene/youaredead") == true) {
    end();
  }else if (theOscMessage.checkAddrPattern("/game/reset") == true) {
    end();
  }
}

