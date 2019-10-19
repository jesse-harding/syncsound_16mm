//see userInputs tab for pertinent variables //<>//

int mouseClicks = 0;

void settings() {
  noSmooth();
  size(1025, 810); //will change with GUI
}

void setup() {
  pitch = inchPitch * outputDPI; //convert from inch measurements to pixels
  frameX = inchFrameX * outputDPI;
  frameY = inchFrameY * outputDPI;
  frameLine = pitch - frameX;

  //expand arrays for number of pages, number of rows of image per file, and number of images (if non-loop is selected)
  pg = (PGraphics[]) expand(pg, ceil(float(numFrames) / (maxGang * repeat))); //create enough PGraphics objects to hold all frames
  gangUp = expand(gangUp, pg.length);
  if (!loop) {
    images = (PImage[]) expand(images, images.length + soundAdvance);
  }

  if (recordFilter) {  //low pass filter to comply with nyquist theorem, given lower sample rate
    minim = new Minim(this);  //make new minim instance
    timeFile = new SoundFile(this, fileName);  //input file for soundlibrary (for time and samplerate etc)
    inputFrames = timeFile.frames();  //get number of samples in input file
    inputLengthMillis = int(timeFile.duration() * 1000);  //get length of input file in milliseconds
    playbackFile = new Sampler(fileName, 1, minim);  //input file for wav or aiff load/play
    out = minim.getLineOut( Minim.MONO );  // get output stream to be recorded for filtering
    recorder = minim.createRecorder(out, "data/temp.wav");  //create recorder instance which will save a temporary file for filtered audio
    TickRate rateControl = new TickRate(1.f);  //control playback rate to avoid errors
    playbackFile.patch(rateControl).patch(out); //patch filtered audio to output stream for recording
    lowFS = new LowPassFS(filterFreq, inputSampleRate);  // set cutoff frequency of lowpass filter (will remain static unless phonograph option is selected)
    out.addEffect(lowFS);  //add low pass filter to output audio stream for recording and encoding
  } else {  //if audio has already been filtered
    println();
    println("please wait while images are being processed");
    println();
    println("...");
    println();
    importDir();
    file = new SoundFile(this, "data/temp.wav"); //import filtered audio file
    downSample(); //downsample imported audio to match samplerate ... variable ... automate?
    if (normalize) {
      normalizeAudio(); //amplifies audio to full dynamic range w/o clipping
    }
    variableDensity(); //due to the size of the optical sound sensor, we can't use variable area optical sound
  }
}

void draw() {
  background(0);
  if (recordFilter) {  //checks if audio has not yet been filtered
    filterInput();  //applies a low pass filter to input audio to comply with nyquist theorem (dynamic cutoff frequency if phonograph, static for other modes
  }
  if (saved) {
    image(pg[mouseClicks%pg.length], 0, 0, width, height); //clicks cycle through your pages in the running sketch
  }
}

void mouseClicked() { //counts clicks for clicking through generated pages
  mouseClicks++;
}

void importDir() {
  // import filenames from specified folder
  java.io.File folder = new java.io.File(dataPath(frameFolder));

  // list the files in order
  filenames = folder.list();
  filenames = sort(filenames);

  //remove ".DS_Store" if working on mac (unsure about compatibility on other OS)
  while (filenames.length > numFrames) {
    filenames = reverse(filenames);
    filenames = shorten(filenames);
    filenames = sort(filenames);
  }

  //for a synchronized sound film loop, move 26 frames from end to beginning to account for sound advance
  if (syncSound && loop) {
    String tempA[] = subset(filenames, filenames.length - soundAdvance);
    String tempB[] = subset(filenames, 0, filenames.length - soundAdvance);
    for (int i = 0; i < filenames.length; i++) {
      if (i < soundAdvance) {
        filenames[i] = tempA[i];
      } else {
        filenames[i] = tempB[i - soundAdvance];
      }
    }
  }

  //for a non-looped film with synchronized sound, add 26 frames of slug to the beginning of the film
  if (syncSound && !loop) {
    println("adding 26 frames of slug to beginning of film");
    numFrames += soundAdvance;
    String slugFrames[] = new String[soundAdvance];
    for (int i = 0; i < soundAdvance; i++) {
      slugFrames[i] = "../slug.jpg";
    }
    filenames = concat(slugFrames, filenames);
  }

  // load image files into a PImage array
  for (int i = 0; i < filenames.length; i++) {
    if (i < images.length) {
      images[i] = loadImage(frameFolder + filenames[i]);
    }
  }
}


void variableDensity() { //generate optical sound from filtered and downsampled audio track 

  //best possible resolution is 8-bit due to 0-255 density

  // for a film loop with synchronized sound, move one half frame of audio from the beginning to the end of the film strip (to account for mid-frame splice)
  if (loop && syncSound) {
    float halfFrame[] = subset(outputFrameArray, 0, int(pitch / 2));
    float shiftAudio[] = subset(outputFrameArray, int(pitch / 2));
    outputFrameArray = concat(shiftAudio, halfFrame);
    if (outputFrameArray.length > numSamples) {  //account for discrepancies in downsampling to ensure audio is the same length as image
      outputFrameArray = subset(outputFrameArray, 0, numSamples);
    }
    if (outputFrameArray.length < numSamples) {  //account for discrepancies in downsampling to ensure audio is the same length as image
      float tempFrameArray[] = subset(outputFrameArray, outputFrameArray.length -(numSamples - outputFrameArray.length));
      tempFrameArray = reverse(tempFrameArray);
      outputFrameArray = concat(outputFrameArray, tempFrameArray);
    }
  }

  if (!loop) { //if not looped, add 1/2 frame of audio slug to account for mid-frame splice
    float halfFrame[] = new float[int(pitch / 2)];
    for (int i=0; i < halfFrame.length; i++) {
      halfFrame[i] = 0;
    }
    outputFrameArray = concat(halfFrame, outputFrameArray);
  }

  for (int p = 0; p < pg.length; p++) { //go through each page to be exported
    print("rendering page " + (p + 1) + "/" + pg.length);
    wrap = 0;
    if (p < pg.length -1) { //set number of rows on the current page
      gangUp[p] = maxGang;
    }
    if (p == pg.length - 1) { //set last row length to match remaining frames
      gangUp[p] = ceil((numFrames - float(fullPage) * (pg.length-1)) / float(repeat));
    }

    //create and setup the PGraphics object for each page
    pg[p] = createGraphics(int(size[0] * outputDPI), int(size[1] * outputDPI));
    pg[p].noSmooth();
    pg[p].beginDraw();
    pg[p].background(255);
    pg[p].strokeWeight(1);
    pg[p].noFill();
    pg[p].noStroke();

    ////map pcm audio data to grayscale values to generate optical soundtrack
    for (int i = int(p*fullPage*outputSampleRate/fps); i < int((p+1)*fullPage*outputSampleRate/fps); i++) {
      if (i % int(repeat*pitch) == 0) {
        wrap++;
      }
      if (i < outputFrameArray.length) {
        pg[p].stroke(map(outputFrameArray[i], -1, 1, 0, 255));
        pg[p].beginShape();
        pg[p].vertex(i%int(repeat*pitch), (wrap - 1) * (spacing + filmStock) + filmStock/2); //draw lines of a value matching pcm audio
        pg[p].vertex(i%int(repeat*pitch), (wrap * filmStock) + (wrap - 1) * spacing);
        pg[p].endShape();
      }
      pg[p].strokeWeight(1);
    }
    pg[p].stroke(0);

    for (int i = 0; i < gangUp[p]; i++) {  //generate trim marks for alignment to laser cut aligment file
      pg[p].beginShape();
      pg[p].vertex(0, (i * (filmStock + spacing)) + outputDPI*bleed/2);
      pg[p].vertex(pg[p].width, (i * (filmStock + spacing)) + outputDPI*bleed/2);
      pg[p].endShape();
    }
    wrap=0;

    for (int i = 0; i < gangUp[p]; i++) {  //add black layer behind frames to create the frameline and a border
      pg[p].pushMatrix();
      pg[p].noStroke();
      pg[p].fill(0);
      int rectWidth = int(repeat*pitch);
      if (gangUp[p] != maxGang && i == gangUp[p]-1) {
        rectWidth = int(((images.length%fullPage) % repeat)*pitch);
      }
      pg[p].rect(0, i * (spacing + filmStock) + filmStock/2 - frameY/2 - 1, rectWidth, frameY + 1);

      pg[p].popMatrix();
    }

    //rotate, invert, and place frames (note: due to mid-frame splice, each row begins and ends with an image shared with the previous and next row)
    for (int i = int(p*fullPage); i < int((p+1)*fullPage); i++) {
      if (i % int(repeat) == 0 && i < images.length) {
        wrap++;
      }
      if (i < images.length) {
        pg[p].pushMatrix();
        pg[p].rotate(3*PI/2);
        pg[p].scale(-1, 1);
        pg[p].image(images[i], (wrap - 1) * (spacing + filmStock) + filmStock/2 - frameY/2, (i%repeat-.5) * pitch + offset, frameY, frameX);
        if (i%repeat == (repeat-1) && i < images.length - 1) {
          pg[p].image(images[i+1], (wrap - 1) * (spacing + filmStock) + filmStock/2 - frameY/2, (i%repeat-.5) * pitch + pitch + offset, frameY, frameX);
        }
        if (i == images.length - 1 && loop) {
          pg[p].image(images[0], (wrap - 1) * (spacing + filmStock) + filmStock/2 - frameY/2, (i%repeat-.5) * pitch + pitch + offset, frameY, frameX);
          pg[p].pushMatrix();
          pg[p].noStroke();
          pg[p].fill(255);
          pg[p].rect((wrap - 1) * (spacing + filmStock) + filmStock/2 - frameY/2 -2, (i%repeat) * pitch + pitch, frameY+5, frameX + 5);
          pg[p].popMatrix();
        }
        pg[p].popMatrix();
      }
      pg[p].strokeWeight(1);
    }

    for (int i = 0; i < gangUp[p]; i++) { //add numbers to each section of ganged up film
      pg[p].pushMatrix();
      pg[p].fill(255, 0, 0);
      pg[p].textSize(32);
      pg[p].stroke(255, 0, 0);
      pg[p].translate(10, 90); //add slightly more than 1/2 perforation dimension for numbering
      pg[p].rectMode(CENTER);
      for (int s = 1; s <= gangUp[p]; s++) {
        pg[p].text(str(s + p*maxGang), 0, (s-1)*(filmStock + spacing));
      }
      pg[p].popMatrix();
    }
    pg[p].dispose();
    pg[p].endDraw();
    print(" ... saving");
    pg[p].save(outputFilename + (p+1) + fileType);
    println(" ... saved");
    saved = true;
  }
}
