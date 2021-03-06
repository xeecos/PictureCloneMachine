#include <EEPROM.h>
#include <Servo.h>
#include <SoftwareSerial.h>
#include <Wire.h>
#include "MePort.h"
#include "MeDCMotor.h"
#include "MeRGBLed.h"
// data stored in eeprom
static union{
    struct{
      char name[8];
      unsigned char motoADir;
      unsigned char motoBDir;
      unsigned char motorSwitch;
      int height;
      int width;
      int speed;
      int penUpPos;
      int penDownPos;
    }data;
    char buf[64];
}roboSetup;

// arduino only handle A,B step mapping
float curSpd,tarSpd; // speed profile
float curX,curY,curZ;
float tarX,tarY,tarZ; // target xyz position
// step value
int tarA,tarB,posA,posB; // target stepper position
int8_t motorAfw,motorAbk;
int8_t motorBfw,motorBbk;

MePort stpA(PORT_1);
MePort stpB(PORT_2);
MePort ylimit(PORT_6);
MeRGBLed led(PORT_3);
int ylimit_pin1 = ylimit.pin1();
int ylimit_pin2 = 2;//ylimit.pin1();
//MePort xlimit(PORT_6);
int xlimit_pin1 = ylimit.pin2();
int xlimit_pin2 = 2;//xlimit.pin2();
MeDCMotor laser(M1);
MePort servoPort(PORT_7);
int servopin =  servoPort.pin2();
Servo servoPen;

/************** motor movements ******************/
void stepperMoveA(int dir)
{
  //Serial.print('A');Serial.println(dir);
  if(dir>0){
    stpA.dWrite1(LOW);
  }else{
    stpA.dWrite1(HIGH);
  }
  stpA.dWrite2(HIGH);
  stpA.dWrite2(LOW);
}

void stepperMoveB(int dir)
{
  //Serial.print('B');Serial.println(dir);
  if(dir>0){
    stpB.dWrite1(LOW);
  }else{
    stpB.dWrite1(HIGH);
  }
  stpB.dWrite2(HIGH);
  stpB.dWrite2(LOW);
}


/************** calculate movements ******************/
//#define STEPDELAY_MIN 200 // micro second
//#define STEPDELAY_MAX 1000
int stepAuxDelay=500;
int stepdelay_min=1;
int stepdelay_max=200;
#define ACCELERATION 2 // mm/s^2 don't get inertia exceed motor could handle
#define SEGMENT_DISTANCE 10 // 1 mm for each segment
#define SPEED_STEP 1

void doMove()
{
  int mDelay=stepdelay_min;
  int speedDiff = -SPEED_STEP;
  int dA,dB,maxD;
  float stepA,stepB,cntA=0,cntB=0;
  int d;
  dA = tarA - posA;
  dB = tarB - posB;
  maxD = max(abs(dA),abs(dB));
  stepA = (float)abs(dA)/(float)maxD;
  stepB = (float)abs(dB)/(float)maxD;
  //Serial.printf("target: %d %d\n",tarA,tarB);
  //Serial.printf("move: max:%d da:%d db:%d\n",maxD,dA,dB);
  //Serial.print(stepA);Serial.print(' ');Serial.println(stepB);
  for(int i=0;(posA!=tarA)||(posB!=tarB);i++){                         // Robbo1 2015/6/8 Changed - change loop terminate test to test for moving not finished rather than a preset amount of moves
    //Serial.printf("step %d A:%d B;%d tar:%d %d\n",i,posA,posB,tarA,tarB);
    // move A
    if(posA!=tarA){
      cntA+=stepA;
      if(cntA>=1){
        d = dA>0?motorAfw:motorAbk;
        posA+=(dA>0?1:-1);
        stepperMoveA(d);
        cntA-=1;
      }
    }
    // move B
    if(posB!=tarB){
      cntB+=stepB;
      if(cntB>=1){
        d = dB>0?motorBfw:motorBbk;
        posB+=(dB>0?1:-1);
        stepperMoveB(d);
        cntB-=1;
      }
    }
    mDelay=stepAuxDelay;//constrain(stepdelay_min+speedDiff/32,stepdelay_min,stepdelay_max)+stepAuxDelay;
    delayMicroseconds(mDelay);
    if((maxD-i)<((stepdelay_max-stepdelay_min)/SPEED_STEP)){
      speedDiff=SPEED_STEP;
    }
  }
  //Serial.printf("finally %d A:%d B;%d\n",maxD,posA,posB);
  posA = tarA;
  posB = tarB;
}

/******** mapping xy position to steps ******/
#define STEPS_PER_CIRCLE 3200.0f
#define WIDTH 80
#define HEIGHT 140
#define DIAMETER 11 // the diameter of stepper wheel
//#define STEPS_PER_MM (STEPS_PER_CIRCLE/PI/DIAMETER) 
#define STEPS_PER_MM 87.58/4 // the same as 3d printer
void prepareMove()
{
  float dx = tarX - curX;
  float dy = tarY - curY;
  float distance = sqrt(dx*dx+dy*dy);
  //Serial.print("distance=");Serial.println(distance);
  if (distance < 0.001)
    return;
  tarA = tarX*STEPS_PER_MM;
  tarB = tarY*STEPS_PER_MM;
  //Serial.print("tarL:");Serial.print(tarL);Serial.print(' ');Serial.print("tarR:");Serial.println(tarR);
  //Serial.print("curL:");Serial.print(curL);Serial.print(' ');Serial.print("curR:");Serial.println(curR);
  //Serial.printf("tar Pos %ld %ld\r\n",tarA,tarB);
  doMove();
  curX = tarX;
  curY = tarY;
}

void goHome()
{
  // stop on either endstop touches
  while(digitalRead(xlimit_pin2)==1 && digitalRead(xlimit_pin1)==1){
    stepperMoveB(motorBbk);
    delayMicroseconds(stepdelay_min);
  }
  while(digitalRead(ylimit_pin2)==1 && digitalRead(ylimit_pin1)==1){
    stepperMoveA(motorAbk);
    delayMicroseconds(stepdelay_min);
  }
  posA = 0;
  posB = 0;
  curX = 0;
  curY = 0;
}

void initPosition()
{
  curX=0; curY=0;
  posA = 0;posB = 0;
}

/************** calculate movements ******************/
void parseCordinate(char * cmd)
{
  char * tmp;
  char * str;
  str = strtok_r(cmd, " ", &tmp);
  tarX = curX;
  tarY = curY;
  while(str!=NULL){
    str = strtok_r(0, " ", &tmp);
    if(str[0]=='X'){
      tarX = atof(str+1);
    }else if(str[0]=='Y'){
      tarY = atof(str+1);
    }else if(str[0]=='Z'){
      tarZ = atof(str+1);
    }else if(str[0]=='F'){
      float speed = atof(str+1);
      tarSpd = speed/60; // mm/min -> mm/s
    }else if(str[0]=='A'){
      stepAuxDelay = atoi(str+1);
    }
  }
  prepareMove();
}

void echoRobotSetup()
{
  Serial.print("M10 XY ");
  Serial.print(roboSetup.data.width);Serial.print(' ');
  Serial.print(roboSetup.data.height);Serial.print(' ');
  Serial.print(curX);Serial.print(' ');
  Serial.print(curY);Serial.print(' ');
  Serial.print("A");Serial.print((int)roboSetup.data.motoADir);
  Serial.print(" B");Serial.print((int)roboSetup.data.motoBDir);
  Serial.print(" H");Serial.print((int)roboSetup.data.motorSwitch);
  Serial.print(" S");Serial.print((int)roboSetup.data.speed);
  Serial.print(" U");Serial.print((int)roboSetup.data.penUpPos);
  Serial.print(" D");Serial.println((int)roboSetup.data.penDownPos);
}

void echoEndStop()
{
  Serial.print("M11 ");
  Serial.print(digitalRead(xlimit_pin1)); Serial.print(" ");
  Serial.print(digitalRead(xlimit_pin2)); Serial.print(" ");
  Serial.print(digitalRead(ylimit_pin1)); Serial.print(" ");
  Serial.println(digitalRead(ylimit_pin2));
}

void syncRobotSetup()
{
  int i;
  for(i=0;i<64;i++){
    EEPROM.write(i,roboSetup.buf[i]);
  }
}

void parseRobotSetup(char * cmd)
{
  char * tmp;
  char * str;
  str = strtok_r(cmd, " ", &tmp);
  while(str!=NULL){
    str = strtok_r(0, " ", &tmp);
    if(str[0]=='A'){
      roboSetup.data.motoADir = atoi(str+1);
    }else if(str[0]=='B'){
      roboSetup.data.motoBDir = atoi(str+1);
    }else if(str[0]=='H'){
      roboSetup.data.height = atoi(str+1);
    }else if(str[0]=='W'){
      roboSetup.data.width = atoi(str+1);
    }else if(str[0]=='S'){
      roboSetup.data.speed = atoi(str+1);
    }
  }
  syncRobotSetup();
}

void parseAuxDelay(char * cmd)
{
  char * tmp;
  strtok_r(cmd, " ", &tmp);
  stepAuxDelay = atoi(tmp);
}

void parseLaserPower(char * cmd)
{
  char * tmp;
  char * str;
  str = strtok_r(cmd, " ", &tmp);
  while(str!=NULL){
    str = strtok_r(0, " ", &tmp);
    if(str[0]=='P'){
      int pwm = atoi(str+1);
      laser.run(pwm);
    };
  }
}
void parseLedPower(char *cmd){
  char * tmp;
  char * str;
  str = strtok_r(cmd, " ", &tmp);
  while(str!=NULL){
    str = strtok_r(0, " ", &tmp);
    if(str[0]=='P'){
      int pwm = atoi(str+1);
      led.setColor(pwm,pwm,pwm);
      led.show();
    };
  }
}
void parsePen(char * cmd)
{
  char * tmp;
  strtok_r(cmd, " ", &tmp);
  int pos = atoi(tmp);
  servoPen.write(pos);
}

void parsePenM3(char * cmd)
{
  char * tmp;
  char * str;
  str = strtok_r(cmd, " ", &tmp);
  while(str!=NULL){
    str = strtok_r(0, " ", &tmp);
    if(str[0]=='P'){
      servoPen.write(atoi(str+1));
    };
  }
}

void parsePenPosSetup(char * cmd)
{
  char * tmp;
  char * str;
  str = strtok_r(cmd, " ", &tmp);
  while(str!=NULL){
    str = strtok_r(0, " ", &tmp);
    if(str[0]=='U'){
      roboSetup.data.penUpPos = atoi(str+1);
    }else if(str[0]=='D'){
      roboSetup.data.penDownPos = atoi(str+1);    
    }
  }
  //Serial.printf("M2 U:%d D:%d\r\n",roboSetup.data.penUpPos,roboSetup.data.penDownPos);
  syncRobotSetup();
}

void parseMcode(char * cmd)
{
  int code;
  code = atoi(cmd);
  switch(code){
    case 1:
      parsePen(cmd);
      break;
    case 2: // set pen position
      parsePenPosSetup(cmd);
      break;
    case 3:
      parseLaserPower(cmd);
      //parsePenM3(cmd);
      //parseAuxDelay(cmd);
      break;
    case 4:
      parseLaserPower(cmd);
      break;
    case 5:
      parseRobotSetup(cmd);
      break;  
    case 6:
      parseLedPower(cmd);
      //parsePenM3(cmd);
      //parseAuxDelay(cmd);
      break;    
    case 10:
      echoRobotSetup();
      break;
    case 11:
      echoEndStop();
      break;
  }
}

void parseGcode(char * cmd)
{
  int code;
  code = atoi(cmd);
  switch(code){
    case 0:
    case 1: // xyz move
      parseCordinate(cmd);
      break;
    case 28: // home
      tarX=0; tarY=0;
      goHome();
      break; 
  }
}

void parseCmd(char * cmd)
{
  if(cmd[0]=='G'){ // gcode
    parseGcode(cmd+1);  
  }else if(cmd[0]=='M'){ // mcode
    parseMcode(cmd+1);
  }else if(cmd[0]=='P'){
    Serial.print("POS X");Serial.print(curX);Serial.print(" Y");Serial.println(curY);
  }
  Serial.println("OK");
}

// local data
void initRobotSetup()
{
  int i;
  //Serial.println("read eeprom");
  for(i=0;i<64;i++){
    roboSetup.buf[i] = EEPROM.read(i);
    //Serial.print(roboSetup.buf[i],16);Serial.print(' ');
  }
  //Serial.println();
  if(strncmp(roboSetup.data.name,"XY4",3)!=0){
    Serial.println("set to default setup");
    // set to default setup
    memset(roboSetup.buf,0,64);
    memcpy(roboSetup.data.name,"XY4",3);
    // default connection move inversely
    roboSetup.data.motoADir = 0;
    roboSetup.data.motoBDir = 0;
    roboSetup.data.width = WIDTH;
    roboSetup.data.height = HEIGHT;
    roboSetup.data.motorSwitch = 0;
    roboSetup.data.speed = 1;
    roboSetup.data.penUpPos = 160;
    roboSetup.data.penDownPos = 90;
    syncRobotSetup();
  }
  // init motor direction
  // yzj, match to standard connection of xy
  // A = x, B = y
  if(roboSetup.data.motoADir==0){
    motorAfw=-1;motorAbk=1;
  }else{
    motorAfw=1;motorAbk=-1;
  }
  if(roboSetup.data.motoBDir==0){
    motorBfw=-1;motorBbk=1;
  }else{
    motorBfw=1;motorBbk=-1;
  }
  int spd = 200 - roboSetup.data.speed;
  stepdelay_min = spd*10;
  stepdelay_max = spd*100;
}


/************** arduino ******************/
void setup() {
  pinMode(ylimit_pin1,INPUT_PULLUP);
  pinMode(ylimit_pin2,INPUT_PULLUP);
  pinMode(xlimit_pin1,INPUT_PULLUP);
  pinMode(xlimit_pin2,INPUT_PULLUP);
  Serial.begin(115200);
  initRobotSetup();
  initPosition();
  servoPen.attach(servopin);
  delay(100);
  servoPen.write(roboSetup.data.penUpPos);
  laser.run(0);
  led.setNumber(4);
  led.setColor(0,0,0);
  led.show();
}

char buf[64];
int8_t bufindex;

void loop() {
  if(Serial.available()){
    char c = Serial.read();
    buf[bufindex++]=c; 
    if(c=='\n'){
      buf[bufindex]='\0';              // Robbo1 2015/6/8 Add     - Null terminate the string - Essential for first use of 'buf' and good programming practice
      parseCmd(buf);
      memset(buf,0,64);
      bufindex = 0;
    }
    if(bufindex>=64){
      bufindex=0;
    }
  }
  /*
  Serial.print(digitalRead(xlimit_pin1));Serial.print(' ');
  Serial.print(digitalRead(xlimit_pin2));Serial.print(' ');
  Serial.print(digitalRead(ylimit_pin1));Serial.print(' ');
  Serial.print(digitalRead(ylimit_pin2));Serial.println();  
  */
}

