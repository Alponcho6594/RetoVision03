import processing.net.*;

Client remoteClient;
float targetX, targetY;  // Posición del end effector
float len1 = 180;         // Longitud del primer segmento
float len2 = 80;          // Longitud del segundo segmento
int alturaCuadro = 90;    // Altura del cuadro azul
int alturaBase = 130;     // Altura de la base
int anchoHueco = 120; 
float anchoCuadro = 50;  // Width of the blue box
float altoCuadro = 90;  // Height of the blue box (same as the blue box's height)
color colorAzul = color(0, 0, 255);  
color colorAmarillo = color(255, 255, 0);  
color colorBase = colorAzul;  
float lastValidBX;
float lastValidBY;

void setup() {
  size(640, 360);
  remoteClient = new Client(this, "127.0.0.1", 5204); // Establecer la conexión con el servidor
}

void draw() {
  background(255);
  
  // Centro de la ventana
  float centerX = width / 3 - 80;
  float centerY = height / 3 - 20;
  
  // Si hay datos disponibles desde el servidor
  if (remoteClient.available() > 0) {
    String data = remoteClient.readString();
    if (data != null) {
      String[] parts = data.split(",");
      if (parts.length == 2) {
        targetX = float(parts[0]);
        targetY = float(parts[1]);
      }
    }
  }
  
  // Calcular los ángulos de las articulaciones para alcanzar el target
  float[] angles = calculateIK(targetX - centerX, targetY - centerY);
  
  // Dibujar el brazo robótico
  drawRobot(angles, centerX, centerY);
}

float[] calculateIK(float x, float y) {
  float[] angles = new float[2];  // Ángulos de las articulaciones
  
  // Distancia del target al origen
  float distance = dist(0, 0, x, y);
  
  // Límites de los ángulos para el primer segmento (base del robot)
  float minAngle1 = radians(-135);  // Ángulo mínimo permitido
  float maxAngle1 = radians(135);   // Ángulo máximo permitido
  
  // Límites de los ángulos para el segundo segmento (antebrazo)
  float minAngle2 = radians(-135);   // Ángulo mínimo permitido
  float maxAngle2 = radians(95);    // Ángulo máximo permitido
  
  // Calcular el ángulo 2 usando la ley del coseno
  float cosAngle2 = (sq(len1) + sq(len2) - sq(distance)) / (2 * len1 * len2);
  
  // Verificar si el cálculo es válido dentro del rango [-1, 1]
  cosAngle2 = constrain(cosAngle2, -1, 1);  // Ajustar cosAngle2 si está fuera de [-1, 1]
  
  // Calcular el ángulo 2 usando el ángulo en radianes
  float angle2 = acos(cosAngle2);
  
  // Calcular el ángulo 1 usando la función atan2
  float angle1 = atan2(y, x) - atan2(len2 * sin(angle2), (len1 + len2 * cos(angle2)));
  
  // Limitar los ángulos dentro de los rangos permitidos
  angle1 = constrain(angle1, minAngle1, maxAngle1);
  angle2 = constrain(angle2, minAngle2, maxAngle2);
  
  angles[0] = angle1;
  angles[1] = angle2;
  
  return angles;
}


void drawRobot(float[] angles, float centerX, float centerY) {
  float angle1 = angles[0];
  float angle2 = angles[1];

  // Calcula la posición del end effector (bx, by)
  float x1 = centerX;
  float y1 = centerY;
  float x2 = x1 + len1 * cos(angle1);
  float y2 = y1 + len1 * sin(angle1);
  float endEffectorX = x2 + len2 * cos(angle1 + angle2);
  float endEffectorY = y2 + len2 * sin(angle1 + angle2);

  // Verifica y ajusta la posición del end effector dentro de los límites
  if (endEffectorX < 0) {
    endEffectorX = 0;
  } else if (endEffectorX > width) {
    endEffectorX = width;
  }
  
  if (endEffectorY < 0) {
    endEffectorY = 0;
  } else if (endEffectorY > height) {
    endEffectorY = height;
  }

  // Calcula la posición ajustada del rectángulo azul (bx, by) en base al end effector
  float boxAngle = angle1 + angle2;
  float bx = endEffectorX + alturaCuadro * cos(boxAngle);
  float by = endEffectorY + alturaCuadro * sin(boxAngle);

  // Verifica colisiones con las áreas de interés y cambia el color si es necesario
  boolean isColliding = false;

  if (bx >= 0 && bx <= width / 2 - anchoHueco / 3 && by >= height - alturaBase && by <= height) {
    isColliding = true;
  } else if (bx >= width / 2 + anchoHueco / 3 && bx <= width && by >= height - alturaBase && by <= height) {
    isColliding = true;
  } else if (bx >= width / 2 - anchoHueco / 3 && bx <= width / 2 - anchoHueco / 3 + (width / 3 - 67) &&
             by >= height - alturaBase + 100 && by <= height) {
    isColliding = true;
  }

  // Si está en colisión, utiliza la última posición válida
  if (isColliding) {
    fill(colorAmarillo);
  } else {
    fill(colorBase);
  }

  // Dibuja las áreas
  rectMode(CORNER);
  noStroke();
  rect(0, height - alturaBase, width / 2 - anchoHueco / 3, alturaBase);
  rect(width / 2 + anchoHueco / 3, height - alturaBase, width / 2 - anchoHueco / 3, alturaBase);
  rect(width / 2 - anchoHueco / 3, height - alturaBase + 100, width / 3 - 67, alturaBase - 100);

  // Dibuja el rectángulo azul (end effector)
  fill(colorAzul);
  pushMatrix();
  translate(bx, by);
  rotate(boxAngle + HALF_PI);
  rectMode(CENTER);
  rect(0, 50, anchoCuadro, alturaCuadro);
  popMatrix();

  // Dibuja los segmentos del brazo robótico
  strokeWeight(4);
  stroke(0);
  line(centerX, centerY, x2, y2);
  line(x2, y2, endEffectorX, endEffectorY);
}
