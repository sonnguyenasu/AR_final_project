// sample code for keyEvents

// Generally, keyPressed() is used for key events in processing.
// However, using keyPressed() directly is not suitable for our app,
// because the intarval at which keyPressed() is called and the camera capture is not synchronized.

// Instead, we implement KeyState class to manage the input state.
// This instance is called every frame in draw() and synchronized with the capture

class KeyState {
  HashMap<Integer, Boolean> key;

  KeyState() {
    key = new HashMap<Integer, Boolean>();

    key.put(RIGHT, false);
    key.put(LEFT,  false);
    key.put(UP,    false);
    key.put(DOWN,  false);
  }

  void putState(int code, boolean state) {
    key.put(code, state);
  }

  boolean getState(int code) {
    return key.get(code);
  }

  // currently we just manipulate binary thresholds of the marker tracker
  void getKeyEvent() {
    if (getState(LEFT)) {
      markerTracker.thresh -= 1;
    }

    if (getState(RIGHT)) {
      markerTracker.thresh += 1;
    }

    if (getState(UP)) {
      markerTracker.bw_thresh += 1;
    }

    if (getState(DOWN)) {
      markerTracker.bw_thresh -= 1;
    }
  }
}

void keyPressed() {
  if (key == ' ') {
    if (title == 1) {
      title = 0;
    }
    if (dead == 1) {
      init();
    }
  }
  keyState.putState(keyCode, true);
}

void keyReleased() {
  keyState.putState(keyCode, false);
}