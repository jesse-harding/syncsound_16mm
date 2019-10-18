//347 frames (15.58 sec) if filling the page (thats 15 seconds and 14 frames)
//242X177 image frame size @ 600 dpi

boolean recordFilter = true;  //apply low pass filter to input audio file?
boolean syncSound = true;
boolean loop = true; //fix mistake at end for !loop ???

float bleed = .1; //set up a bleed of .1 inches total (.05 per side)
boolean normalize = true; // maximize audio amplitude

float outputDPI = 600; //dpi of printer

String projectName = "lobby";

String frameFolder = "frames_" + projectName + "/"; //folder holding exported png sequence
String outputFilename = projectName; //output file name (will go into processing sketch folder)
String fileName = projectName + ".wav"; //exported wav audio file (audio must be 44.1kHz sample rate)

//make dynamic???
int numFrames = 275; //add alert for too many images


int fps = 24; //framerate of 16mm film
int fpm = 36; //film speed of 16mm film at 24fps (could be found by pitch * fps * 12 / 60)

//make these dynamic???
int repeat = 34; //number of frames we can fit on one continuous piece of media
int maxGang = 11;
int fullPage = repeat * maxGang; //is this right???

//calculate how many pixels will pass by the optical sound sensor in a second using film speed (feet per minute) and printer dpi
float outputSampleRate = (outputDPI * fpm * 12) / 60;

float filterFreq = outputSampleRate/2; //the highest cutoff frequency for the lowpass filter (based on user input or size of phonograph record to be cut)


int numSamples = int(outputSampleRate * (numFrames) / fps);


//what to do here???
PImage[] images = new PImage[int(repeat*numFrames / float(repeat))];
//PImage[] images = new PImage[int(repeat*numFrames / float(repeat))];


float size[] = {repeat*inchPitch, 8 + bleed};  //width & height of output file (maximizing printable area based on printer)
//float size[] = {10.35, 8 + bleed};  //width & height of output file (maximizing printable area based on printer)

//could be made cleaner???
float spacing = (((size[1]*outputDPI) - (((bleed) + 0.629921) * outputDPI * maxGang)) / (maxGang - 1)); //calculate the space between printed filmstock
float filmStock = (((bleed) + 0.629921) * outputDPI); //0.629921 is 16mm in inches; here we are setting the width of the frame with some bleed
