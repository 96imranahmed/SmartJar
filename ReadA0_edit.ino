const int sensorPin = A0;
const int analogOutPin = 9;
int outputValue = 0; 
float analogValueAverage = 0;
double mass = 0;
double x = 0;
double equil = 0;
double sumequil = 0;
double sendMass = 0;


int zeroHover = 0;

void setup(){
  Serial.begin(9600); //open a serial port
  for(int i = 0; i < 100; i++){
    sumequil += analogRead(sensorPin);
    delay(10);
  }
  equil = sumequil/100;
}

 
void loop(){
  double sensorVal = analogRead(sensorPin);

  double sum = 0;
  for(int i = 0; i < 100; i++){
    sum += analogRead(sensorPin);
    delay(5);
  }
  sensorVal = sum/100.0;

//  Serial.print("Sensor Value :");
//  Serial.print(sensorVal);

  x = sensorVal - equil;
  
  mass = 2.1*x;

  sendMass = mass;

  if(abs(mass) < 8){
    zeroHover++;
  }

  if(zeroHover>5){
    equil = sensorVal;
    zeroHover = 0;
  }

//  Serial.print(" Equil :");
//  Serial.print(equil);

  Serial.println(mass);

  analogWrite(analogOutPin, sendMass);

  delay(50);
  }