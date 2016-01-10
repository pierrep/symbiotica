

import com.heroicrobot.dropbit.registry.*;
import com.heroicrobot.dropbit.devices.pixelpusher.Pixel;
import com.heroicrobot.dropbit.devices.pixelpusher.Strip;
import com.heroicrobot.dropbit.devices.pixelpusher.PixelPusher;
import java.util.*;

import processing.core.*;
import processing.video.*;

Movie movie;
PImage image;

PVector selectedPoint = null;
ArrayList<Segment> segments;
XML xml;

DeviceRegistry registry;
PusherObserver pusherObserver;
int numGroups = 0;
boolean bDoLoad = false;
boolean bShowDebugLine = false;

float x1 = 0;
float x2 = 0;

void setup() {
  size(700, 700);

  registry = new DeviceRegistry();
  pusherObserver = new PusherObserver();
  registry.addObserver(pusherObserver);
 
  segments = new ArrayList<Segment>();

  // Load a test movie
  movie = new Movie(this, "video1.mp4");
  movie.loop();
  
  // Load a test image
  image = loadImage("nest-network-thick.jpg");
  
  ellipseMode(CENTER);
  
  bDoLoad = true;
}

class PusherObserver implements Observer {
  public boolean hasStrips = false;
  public void update(Observable reg, Object updatedDevice) {  

    if(!this.hasStrips){
      PixelPusher pusher = (PixelPusher)updatedDevice;
      if(pusher.getGroupOrdinal() == 1) {
        // group 1
         println("group 1");
        numGroups++; 
      }
      if(pusher.getGroupOrdinal() == 2) {
        // group 2
         println("group 2");
        numGroups++; 
      }
      if(pusher.getGroupOrdinal() == 3) {
        // group 3
        println("group 3"); 
        numGroups++;
        
        List<Strip> strips = pusher.getStrips();
  
        // add segments for any strips that have been discovered.
        for(int i = 0; i < strips.size(); i++){

          if(i == 0) {
//            println("added segment");
//            segments.add( new Segment(i * 30 + 10, 20, i * 30 + 10, 200, strips.get(i), 64, 0, 3, i, "name") );        
          } 
          if(i == 1) {
//            segments.add( new Segment(i * 30 + 10, 20, i * 30 + 10, 200, strips.get(i), 64, 0, 3, i) );
//            segments.add( new Segment(i * 30 + 15, 20, i * 30 + 15, 200, strips.get(i), 54, 64, 3, i) );
//            segments.add( new Segment(i * 30 + 20, 20, i * 30 + 20, 200, strips.get(i), 58, 118, 3, i) );
          }

        }
        
      }

      if(numGroups >= 1) {
        this.hasStrips = true;
      }
    }
  }
};


void keyPressed() {
    if((key == 's') || (key == 'S')) {
      saveData();
    } 
    if((key == 'l') || (key == 'L')) {
      bDoLoad = true;
    }
    if((key == 'd') || (key == 'D')) {
     bShowDebugLine = !bShowDebugLine; 
    }
}

void mousePressed() {
  PVector mouse = new PVector(mouseX, mouseY);
  selectedPoint = null;
  
  for(Segment seg : segments){
    if(seg.sampleStart.dist(mouse) < 12) {
      selectedPoint = seg.sampleStart;
      break;
    }else if(seg.sampleStop.dist(mouse) < 12) {
      selectedPoint = seg.sampleStop;
      break;
    }
  }
}

void mouseDragged(){
  if(selectedPoint != null){
    selectedPoint.x = mouseX;
    selectedPoint.y = mouseY;
  }
}

void movieEvent(Movie m) {
  m.read();
}

void draw() {

   background(0);
   
   if(!bShowDebugLine) {
     image(movie, 0, 0, width, height);
     //image(image, 0, 0, width, height);
   }
   else if
   (bShowDebugLine) {
     strokeWeight(10);
     stroke(255);
     x1 = x2 = mouseX;
     line(x1,0,x2,height);
   }   

   
   updatePixels();
   if (pusherObserver.hasStrips) {
      registry.setExtraDelay(0);
      registry.startPushing();
      
     if(bDoLoad) { //do Load 
       loadData();
       bDoLoad = false;
     }

      for(Segment seg : segments){
        seg.samplePixels();
      }

      for(Segment seg : segments){
        seg.draw();
      }      
   } 
}

void saveData()
{
  XML xml = new XML("symbiotica");

  for(Segment seg : segments){
    XML newChild = xml.addChild("strip");
    newChild.setString("name",seg.name);
    newChild.setFloat("x1",seg.sampleStart.x);
    newChild.setFloat("y1",seg.sampleStart.y);
    newChild.setFloat("x2",seg.sampleStop.x);
    newChild.setFloat("y2",seg.sampleStop.y);
    newChild.setInt("offset",seg.pixelOffset);
    newChild.setInt("pixels",seg.pixelCount);
    newChild.setInt("group",seg.group);
    newChild.setInt("id",seg.id);
  }
  
  saveXML(xml,"data/data.xml");
  println("saved XML");

}

void loadData() {
  List<Strip> strips;
  println("load data");
  xml = loadXML("data/data.xml");
  segments.clear();
  
  XML[] children = xml.getChildren("strip");

  for(int i = 0; i < children.length; i++)
  {
    int group = children[i].getInt("group");
    int id = children[i].getInt("id");
    println("id="+id+" group="+group);
    
    strips = registry.getStrips(group);
    if(!strips.isEmpty()) {
      Strip s = strips.get(id);
      
      float x1 = children[i].getFloat("x1");
      float y1 = children[i].getFloat("y1");
      float x2 = children[i].getFloat("x2");
      float y2 = children[i].getFloat("y2");
      int pixoffset = children[i].getInt("offset");
      int numpix = children[i].getInt("pixels");
      String name = children[i].getString("name");
      
      segments.add( new Segment(x1, y1, x2, y2, s, numpix, pixoffset, group, id, name) );
      println("segment added = "+x1+" "+y1+" "+x2+" "+y2);
    }

  } 
  println("Loaded XML");
}

class Segment{
  
  PVector sampleStart;
  PVector sampleStop;
  Strip strip;
  int pixelOffset = 0;
  int pixelCount = 0;
  int group;
  int id;
  String name;
  
  Segment(float startX, float startY, float stopX, float stopY, Strip strip, int pixelCount, int pixelOffset, int _group, int _id, String _name ){
    this( startX, startY, stopX, stopY, strip );
    this.pixelCount = pixelCount;
    this.pixelOffset = pixelOffset;
    this.group = _group;
    this.id = _id;
    this.name = _name;
    //println("Pixels!!! : " + this.pixelCount);
  }
  
  Segment(float startX, float startY, float stopX, float stopY, Strip strip ){
    this.sampleStart = new PVector(startX, startY);
    this.sampleStop = new PVector(stopX, stopY);
    this.strip = strip;
    this.pixelCount = strip.getLength();
    //println("Pixels!!! : " + this.pixelCount);
  }
  
  // draw end points and sample points.
  public void draw() {
    stroke(255,0,0);
    noFill();
    
    // draw circles at the end points.
    ellipse(this.sampleStart.x, this.sampleStart.y, 8,8);
    stroke(0,0,255);
    ellipse(this.sampleStop.x, this.sampleStop.y, 8,8);
    
    
    PVector step = PVector.sub(this.sampleStop, this.sampleStart);
    step.div( this.pixelCount ); 
    fill(0,255,0);
    textSize(20);
    text(this.name,this.sampleStart.x + step.x*pixelCount/2,this.sampleStart.y + step.y*pixelCount/2);
   
    PVector samplePos = new PVector();
    samplePos.set(this.sampleStart);

    noStroke();
    for(int i = 0; i < pixelCount; i++){
      fill(255, 0,0);
      ellipse(samplePos.x, samplePos.y, 3.5, 3.5);
      samplePos.add( step );
    }
  } 
  
  // sample pixels and push them to a strip.
  public void samplePixels() 
  {
    PVector step = PVector.sub(this.sampleStop, this.sampleStart);
    step.div( this.pixelCount ); 
     
    PVector samplePos = new PVector();
    samplePos.set(this.sampleStart);
     
    for(int i = 0; i < this.pixelCount; i++) {
      color p = get((int)samplePos.x, (int)samplePos.y);
      
      //println("pixel offset =" + (i + this.pixelOffset) + " x=" + (int)samplePos.x + " y=" + (int)samplePos.y + " colour = "+red(p) + " " + green(p) + " " + blue(p));
      this.strip.setPixel(get((int)samplePos.x, (int)samplePos.y), i + this.pixelOffset);
      samplePos.add(step);
    }
  }
}
