//global defaults
int numConstellations = 200;
float probabilityOfSingleStars = 0.85;
//minimum constellation size is subject to conflicts with trapped constellations by angle or overlap
int minimumConstellationSize = 4;
float minStarSize = 1;
float maxStarSize = 5;
float speed = 0.7;
float minMagnitude = 10;
float maxMagnitude = 100;
float minAngle = PI/8;
float zeroNodeProbAfterMinSizeReached = 0.5;
float initialZeroNodeProb = 0;
float initialOneNodeProb = 0.5;
float initialTwoNodeProb = 0.4;
float initialThreeNodeProb = 0.1;
int persistence = 10;
 

//vector helpers
PVector emptyVector = new PVector(0, 0);

//------TO DO-------
//MERGE AFTER SENTENCE EXPANSION (to get rid of matching commits) :P :P :P
//Reference constellation colors; too many arguments being passed on
//Reconsider singleStar catch
//Intersection check
//Closed loops


Constellation[] constellations;

void setup() {
  //generate constellations
  size(1080, 720);
  background(#1a4791);
  constellations = new Constellation[numConstellations];
  for (int i = 0; i < numConstellations; i++) {
    constellations[i] = new Constellation(-width, width, -height / 4, height);
  };
}

void draw() {
  //move all constellations
  background(#1a4791);
  for (int i = 0; i < constellations.length; i++) {
    boolean offscreen = true;
    for (int j = 0; j < constellations[i].constellationStars.size(); j++) {
      constellations[i].constellationStars.get(j).update();
      //check if entire constellation is offscreen
      if (constellations[i].constellationStars.get(j).xpos < width && constellations[i].constellationStars.get(j).ypos < height) {
        offscreen = false;
      };
    };
    //if offscreen, replace with new constellation to the left of and slightly above the screen
    if (offscreen) {
      constellations[i] = new Constellation(-width, 0, -height/4, height * 3 / 4);
    };
    for (int j = 0; j < constellations[i].constellationLines.size(); j++) {
      constellations[i].constellationLines.get(j).update();
    };
  };
};


class Constellation {
  //collection of stars and lines which connect them, or single star
  ArrayList<Star> constellationStars = new ArrayList<Star>();
  ArrayList<Line> constellationLines = new ArrayList<Line>();
  FloatDict constellationChain = new FloatDict();
  float r;
  float g;
  float b;
  Constellation (float minx, float maxx, float miny, float maxy) {
    //r = random(0, 255);
    //g = random(0, 255 - r);
    //b = random(0, 255 - g);
    r = 255;
    g = 255;
    b = 255;
    float startX = random(minx, maxx);
    float startY = random(miny, maxy);
    constellationChain.set("0", initialZeroNodeProb);
    constellationChain.set("1", initialOneNodeProb);
    constellationChain.set("2", initialTwoNodeProb);
    constellationChain.set("3", initialThreeNodeProb);
    constellationStars.add(new Star(startX, startY, random(minStarSize, maxStarSize), r, g, b));
    float singleStar = random(0, 1);
    if (singleStar > probabilityOfSingleStars) {
      workFromNode(this, constellationStars.get(0));
    };
  };
};

void workFromNode(Constellation constellation, Star node) {
  //recursively evaluates whether to grow from node, how many new vectors to draw, and where to place them
  float nextMoveProb = random(0, 1);
  int newNodes = 0;
  if (constellation.constellationStars.size() >= minimumConstellationSize && constellation.constellationChain.get("0") == 0){
    constellation.constellationChain.set("0", zeroNodeProbAfterMinSizeReached);
    constellation.constellationChain.set("1", constellation.constellationChain.get("0") - zeroNodeProbAfterMinSizeReached / 3);
    constellation.constellationChain.set("2", constellation.constellationChain.get("0") - zeroNodeProbAfterMinSizeReached / 3);
    constellation.constellationChain.set("3", constellation.constellationChain.get("0") - zeroNodeProbAfterMinSizeReached / 3);
  };
  for (int i = 0; i < constellation.constellationChain.keyArray().length; i++) {
    if (nextMoveProb <= constellation.constellationChain.get(constellation.constellationChain.keyArray()[i])) {
      newNodes = int(constellation.constellationChain.keyArray()[i]);
      break;
    } else {
      nextMoveProb -= constellation.constellationChain.get(constellation.constellationChain.keyArray()[i]);
    }
  }
  //switch(newNodes){
  //  case 0:
  //    constellation.constellationChain.set("0", constellation.constellationChain.get("0") - 0.1);
  //  case 1:
    
  //  case 2:
    
  //  case 3:
    
  //};
  for (int j = 0; j < newNodes; j++) {
    //make new node or connect to old node; lower probability of connecting to old node if selected
    //only make new vector if newVector function was able to find a nonconflicting option within 10 tries (arbitrary value)
    PVector newVector = newVector(constellation, node);
    if (newVector != emptyVector){
      float x = newVector.x + node.xpos;
      float y = newVector.y + node.ypos;
      Star newStar = new Star(x, y, random(minStarSize, maxStarSize), constellation.r, constellation.g, constellation.b);
      constellation.constellationStars.add(newStar);
      constellation.constellationLines.add(new Line(node, newStar, constellation.r, constellation.g, constellation.b));
      workFromNode(constellation, newStar);
    };
    //allow for old node to fail and reset if not possible without a collision
    //make new node and/or path, evaluate new node if applicable
  }
};

class Star {
  //set of coordinates, radius, and color
  float xpos, ypos, size, red, green, blue;
  Star (float x, float y, float s, float r, float g, float b) {
    xpos = x;
    ypos = y;
    size = s;
    red = r;
    green = g;
    blue = b;
  };
  void update() {
    noStroke();
    fill(red, green, blue);
    xpos += speed;
    ypos += speed / 4;
    ellipse(xpos, ypos, size, size);
  };
};

boolean intersection(Star star1, PVector vector1, Line existingLine){
  //find point of intersection of lines; return true if overlap
  float line1_slope, line2_slope, line1_b, line2_b, int_x, line1_x1, line1_x2, line1_y1, line1_y2, line2_x1, line2_x2, line2_y1, line2_y2;
  line1_x1 = star1.xpos;
  line1_x2 = star1.xpos + vector1.x; 
  line1_y1 = star1.ypos;
  line1_y2 = star1.ypos + vector1.y;
  line2_x1 = existingLine.lineStars[0].xpos;
  line2_x2 = existingLine.lineStars[1].xpos; 
  line2_y1 = existingLine.lineStars[0].ypos;
  line2_y2 = existingLine.lineStars[1].ypos;
  
  if (max(line1_x1, line1_x2) < min(line2_x1, line2_x2) || max(line1_y1, line1_y2) < min(line2_y1, line2_y2)){
    return false;
  }
  
  line1_slope = (line1_y2 - line1_y1) / (line1_x2 - line1_x1);
  line2_slope = (line2_y2 - line2_y1) / (line2_x2 - line2_x1);
  line1_b = line1_y1 - line1_slope * line1_x1;
  line2_b = line2_y1 - line2_slope * line2_x1;
  
  //rule out parallel lines, avoid dividing by zero later
  if (line1_slope == line2_slope){
    return false;
  };
  
  int_x = (line2_b - line1_b) / (line1_slope - line2_slope);

  //check if intersection is outside of the overlap of the line segments' domains
  if (int_x < max(min(line1_x1, line1_x2), min(line2_x1, line2_x2)) || int_x > min(max(line1_x1, line1_x2), max(line2_x1, line2_x2))){
      return false;
  }

  return true;
};

PVector newVector(Constellation constellation, Star node) {
  //creates new vector sprouting from end of old vector
  //empty vector is used as check for starting vector of constellation
  PVector vector = new PVector();
  vector = emptyVector;
  
  //evaluate for minimum angle against all vectors in constellation that contain the new vector's start point
  int counter = 0;
  boolean intersect = true;
  while (counter < persistence && vector == emptyVector){
    intersect = false;
    counter += 1;
    vector = checkForAngleConflicts(constellation, node);
    if (vector != emptyVector){
      //check for intersection with lines in this constellation
      for (int h = 0; h < constellation.constellationLines.size(); h++) {
        if (!intersect) {
          Line existingLine = constellation.constellationLines.get(h);
          intersect = intersection(node, vector, existingLine);          
        };
      };
      
      //check for intersection with lines in all other constellations
      for (int i = 0; i < constellations.length; i++) {
        if (constellations[i] != null){
          for (int j = 0; j < constellations[i].constellationLines.size(); j++) {
            if (!intersect) {
              Line existingLine = constellations[i].constellationLines.get(j);
              intersect = intersection(node, vector, existingLine);          
            };
          };
        }; 
       };
     };
     if (intersect){
       vector = emptyVector;
     };
  };
  return vector;
}

PVector checkForAngleConflicts(Constellation constellation, Star node){
  float angle = random(0, 2 * PI);
  float magnitude = random(minMagnitude, maxMagnitude);
  PVector vector = new PVector(cos(angle) * magnitude, sin(angle) * magnitude);
  PVector newUnitVector = findUnitVector(0, 0, vector.x, vector.y);
  for (int i = 0; i < constellation.constellationLines.size(); i++){
    Line existingLine = constellation.constellationLines.get(i);
    float star1x = existingLine.lineStars[0].xpos;
    float star1y = existingLine.lineStars[0].ypos;
    float star2x = existingLine.lineStars[1].xpos;
    float star2y = existingLine.lineStars[1].ypos;
    PVector existingVector = emptyVector;
    
    if (existingLine.lineStars[0] == node){
      existingVector = findUnitVector(star1x, star1y, star2x, star2y);
    } else if (existingLine.lineStars[1] == node){
      existingVector = findUnitVector(star2x, star2y, star1x, star1y);
    };
    
    if (existingVector != emptyVector){
      float proposedAngle = findAngle(newUnitVector, existingVector);
      while (proposedAngle > 2 * PI){
        proposedAngle -= 2 * PI;
      };
      while (proposedAngle < -2 * PI){
        proposedAngle += 2 * PI;
      };
      if (proposedAngle < minAngle || proposedAngle > 360 - minAngle){
        vector = emptyVector;
        break;
      };
    };
  };  
  return vector;
};

PVector findUnitVector(float x1, float y1, float x2, float y2) {
  //calculates normal vector between stars (in order), converts to unit vector
  PVector normalVector = new PVector(x2 - x1, y2 - y1);
  float d = sqrt(sq(normalVector.x) + sq(normalVector.y));
  PVector unitVector = new PVector(normalVector.x/d, normalVector.y/d);
  return unitVector;
};

float findAngle(PVector vector1, PVector vector2) {
  //finds angle between two vectors, assuming same starting point
  float angle = acos(vector1.dot(vector2));
  return angle;
};

class Line {
  //line between two stars
  Star[] lineStars;
  float red, green, blue;
  Line (Star star1, Star star2, float r, float g, float b) {
    lineStars = new Star[2];
    lineStars[0] = star1;
    lineStars[1] = star2;
    red = r;
    green = g;
    blue = b;
  };
  void update() {
    stroke(red, green, blue);
    line(lineStars[0].xpos, lineStars[0].ypos, lineStars[1].xpos, lineStars[1].ypos);
  };
};