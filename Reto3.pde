import processing.video.*;
import processing.net.*;

Server servidor;
Capture video;
color colorSeguimiento;
float umbral = 25;
float posXCuadro, posYCuadro;

void setup() {
  size(800, 600);
  servidor = new Server(this, 5204); 
  String[] camaras = Capture.list();
  printArray(camaras);
  
  video = new Capture(this, camaras[0]);
  video.start();
  
  colorSeguimiento = color(255, 0, 0); 
  posXCuadro = width / 2;  
  posYCuadro = height / 2;
}

void captureEvent(Capture video) {
  video.read();
}

void draw() {
  background(255); 
  
  video.loadPixels();
  image(video, 0, 0);

  umbral = map(mouseX, 0, width, 0, 100);

  float avgX = 0;
  float avgY = 0;
  int count = 0;

  for (int x = 0; x < video.width; x++ ) {
    for (int y = 0; y < video.height; y++ ) {
      int loc = x + y * video.width;
      color currentColor = video.pixels[loc];
      float r1 = red(currentColor);
      float g1 = green(currentColor);
      float b1 = blue(currentColor);
      float r2 = red(colorSeguimiento);
      float g2 = green(colorSeguimiento);
      float b2 = blue(colorSeguimiento);

      float d = distSq(r1, g1, b1, r2, g2, b2); 

      if (d < umbral) {
        stroke(255);
        strokeWeight(1);
        point(x, y);
        avgX += x;
        avgY += y;
        count++;
      }
    }
  }

  if (count > 0) { 
    avgX = avgX / count;
    avgY = avgY / count;
    posXCuadro = lerp(posXCuadro, avgX, 0.1);
    posYCuadro = lerp(posYCuadro, avgY, 0.1);
    
    // Aplicar límites para la posición del cuadro
    posXCuadro = constrain(posXCuadro, 0, width);  // Limitar en el eje X
    posYCuadro = constrain(posYCuadro, 0, height); // Limitar en el eje Y
  }

  drawCuadro();
  servidor.write(posXCuadro + "," + posYCuadro);
}

void drawCuadro() {
  fill(0, 0, 255); 
  rectMode(CENTER); 
  rect(posXCuadro, posYCuadro, 50, 90); 
}

float distSq(float x1, float y1, float z1, float x2, float y2, float z2) {
  float d = (x2-x1)*(x2-x1) + (y2-y1)*(y2-y1) + (z2-z1)*(z2-z1);
  return d;
}

void mousePressed() {
  int loc = mouseX + mouseY * video.width;
  colorSeguimiento = video.pixels[loc];
}
