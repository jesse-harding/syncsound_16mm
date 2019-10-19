//AUDIO SECTION

//libraries needed for audio
import ddf.minim.*;
import ddf.minim.ugens.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import processing.sound.*;

Minim minim; //start minim for lowpass filtering

//for filtering
SoundFile timeFile;  //sound library class to establish input length, samplerate, etc
//SoundFile analysisFile; //import of filtered audio for editing/vectorization
Sampler playbackFile;  //for wav or aiff load/play
LowPassFS lowFS;  //declare low pass filter
AudioRecorder recorder;  // for live input
boolean recorded;  //for recording live input (needed to end recording)
boolean hasStarted = false;  //initialization for beginning save filtered playback
boolean hasSaved = false; //initialization for determining if file is ready to save
boolean hasLoaded = false; //initialization for loading soundFile for analysis
int startMillis;  // start time of filtered playback
AudioOutput out;  // for playing back
FilePlayer player;  // playback of filtered audio
int inputFrames; //number of frames in input file
int inputLengthMillis; //length of input file in milliseconds
SoundFile file; //create instance of SoundFile class to import filtered audio
int inputSampleRate = 44100; //declaring the variable for the sample rate of the file to be loaded (remove?)
float[] inputFrameArray; //array holding values for each sample of the inputted audio
float[] outputFrameArray; //array holding values for each sample of the outputted audio
float maxFrame = 0; // initializing the variable to find the most extreme part of the waveform

boolean tooLong = false; ////REMOVE?????

//IMAGE SECTION

//soon-to-be-populated pixel measurements
float frameY;
float frameX;
float pitch;
float frameLine;
int offset = 2;

//inch measurements
float inchFrameY = 0.40393701; //frameX & frameY are purposefully reversed because the filmstock is rotated on the medium (Y is horizontal and X is vertical IRL)
float inchFrameX = 0.2948819;
float inchPitch = .3;

int soundAdvance = 26; //audio is 26 frames ahead of image
float xPerf = .072007874; //inches for sprocket holes
float yPerf = .05; //inches

PGraphics pg[] = new PGraphics[1]; //declaring the PGraphics object array for outputting individual pages
int gangUp[] = new int[1]; //declaring array to hold number of rows per sheet.

int wrap = 0; //counter for how many times we have to start a new continuous print of filmstock (limited by transparency size)
int prevPercent = 0; //variable to limit progress report to not repeat information
boolean saved = false; //used draw images to to screen and cycle through PGraphics exported pages
String[] filenames; //filenames for images
boolean printProgress = true; //for console output of audio filtering progress
PFont font;
