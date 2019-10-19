void filterInput() {
  recorder.beginRecord();  //begin recording filtered audio
  if (recorder.isRecording() && !hasStarted) {  //check to see if recording has begun and playback file has not yet been triggered to play
    playbackFile.trigger();  //begin playback of input audio file
    int slug = 0;
    if (syncSound && !loop) {
      slug = soundAdvance;
    }
    println("project name: " + projectName);
    println();
    println("your composition is " + (slug + numFrames)/float(fps)+ "s" + " (" + (slug + numFrames) + " frames @ " + fps + "fps" + " (" + floor((slug + numFrames)/fps/60) + "m" + ((slug + numFrames)/fps)%60 + "s" + floor((((float((slug + numFrames))/fps)%60) - ((slug + numFrames)/fps)%60)*fps) + "f))");
    println();
    
    startMillis = millis();  //note time that recording has begun
    hasStarted = true;  //boolean so that file playback is only triggered once
  }
  if (recorder.isRecording() && hasStarted && !hasSaved) {  //check if phonograph option is selected, audio is being recorded, and playback has started
    lowFS.setFreq(outputSampleRate/2);  //dynamically modify freq of filter to match limitations as the spiral radius decreases
    if (int(100 * (millis() - startMillis) / inputLengthMillis) != prevPercent) {
      if (printProgress) {
        println("filtering audio: ");
        print("0%");
        printProgress = false;
      }
      int perc = int(100 * (millis() - startMillis) / inputLengthMillis);
        if (perc%2 == 0){ //only show 2% increments
        print("..." + perc + "%"); //print percentage filter/recording complete
        }
      prevPercent = int(100 * (millis() - startMillis) / inputLengthMillis); //remove redundancy in reporting filtering progress status
    }
  }
  if (millis() > startMillis + inputLengthMillis && !hasSaved) { //check if audio has played for its full duration and has not yet saved
    recorder.endRecord(); //end recording of output stream
    recorder.save();  //save recorded audio
    println();
    println();
    println("audio filtering complete, saving temporary wav file");  //alert that audio has been saved
    hasSaved = true;  //note that audio has been saved
    recordFilter = false;  //now that input audio has been saved as a temporary file, we will import that filtered file and not filter again
    setup();  //due to the fact that the audio filtering must take place in the draw loop, we now recall the setup() function to do the remaining audio manipulation and graphic export
  }
}

void downSample() {
  inputFrameArray = new float[file.frames()]; //make array to hold samples from input file
  file.read(0, inputFrameArray, 0, file.frames()); // load input file into array
  outputFrameArray = new float[int(floor((outputSampleRate/float(inputSampleRate))*file.frames()))]; // make array to hold samples for output file
  for (int i = 0; i < outputFrameArray.length; i++) {
    //downsample from input sample rate to film speed and printer limitations
    outputFrameArray[i] = inputFrameArray[round(map(i, 0, (outputFrameArray.length-1), 0, (inputFrameArray.length-1)))];
  }
}

void normalizeAudio() { //set the sample with the highest amplitude to 1 or -1 and map all smaller samples to the same scale
  for (int i = 0; i < outputFrameArray.length; i++) {
    if (abs(outputFrameArray[i]) > maxFrame) {
      maxFrame = abs(outputFrameArray[i]);
    }
  }
  for (int i = 0; i < outputFrameArray.length; i++) {
    outputFrameArray[i] = outputFrameArray[i] / abs(maxFrame);
  }
}
