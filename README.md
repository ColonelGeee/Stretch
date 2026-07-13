# Stretch
This repository contains all files in order to perform my piece stretch



## MOTIVATION


The motivation to write this piece, comes from experiments with alternative ways of interacting with software. In this case, I wanted to work with resistance between the performer and an object. The focus is on the physical work the performer must put into to deform the controller and to create the sound. 
Since the controller is quite chaotic, the score must be seen more of an improvisational advice or roadmap, than an absolute path to follow. 



## CONTROLLER


The building of the controller is not that demanding, but notice, that it takes some time. For this piece, you must build two of them. To build them, you need the following materials:

1.	Balloons (latex based ideally)
2.	Conductive rubber sheet (Adafruit; product ID: 5464)
3.	Cornstarch
4.	Water
5.	Paperclips
6.	Cables
7.	Soldering Iron + Solder
8.	Duct Tape

First, you mix two parts cornstarch with one part water. After mixing it together, you should get a white liquid, that starts to become hard when it is put under stress. You can check this step by trying to mix it quickly, if it forms to a lump, you have the right ratio. By letting it rest, it should flow back into a liquid form. 
In the next step you fill the liquid in the balloon with a funnel. Be careful, it will take some time, since the liquid is not that fast and make sure to only add small amounts of liquid, otherwise the funnel could become blocked. Fill the balloon up to it extend and close it with a knot.
Now you must cut the conductive rubber sheet into 4 pieces, I used 2 x 20 cm. After cutting, you need to wrap the ends of the rubber pieces over the paperclips, in a way, that the rubber stays inside of the paper clip. Now you have on each end one paperclip, onto which you can now solder the cables. As a last step, cover the paperclips and any open contacts with duct tape to prevent shortcuts. 
Apply for each controller one strip horizontally, and one strip vertically. To stick the rubber strips on the balloon, I used some duct tape. Make sure, that you also apply duct tape or any other non-conducting material between the rubber sheets, otherwise, they will not work properly. 
Now you should have two controllers with each two rubber sensors connected to it.



## CIRCUIT + CODE


For the circuit, you need the following materials:

1.	Arduino UNO
2.	Breadboard
3.	4 x 20kΩ Resistors
4.	Jumper Wirers

Connect the +5V of the Arduino to the 20kΩ Resistor. Connect the resistor with one side of the rubber strip and the input of A0 on the Arduino. Connect the remaining side of the rubber strip with the ground of the Arduino. Repeat these steps for every rubber strip but connect them along the different inputs (A0 – A3). 
After wiring everything, upload the code onto the Arduino.
```cpp
const int SIG_pins[4] = {A0, A1, A2, A3};

void setup() {
  Serial.begin(115200);
}

void loop() {
  for (int chan = 0; chan < 4; chan++) {
    int value = analogRead(SIG_pins[chan]);
    Serial.print(value);

    if (chan == 3) {
      Serial.print('e');   
    } else {
      Serial.print(',');  
    }
  }
  Serial.println();        
  delay(100);
}



```

## MAKING A CONNECTION


The first step to rehearse the piece is to make a connection from the Arduino to SuperCollider. Both are communicating via serial port data, and you must set up the connection. With the command 
```supercollider	
SerialPort.listDevices;
```		
you can check for all devices, that are connected to the computer, and it can look like this:
```supercollider
"/dev/cu.usbmodem11201"
```
Troubleshooting: If the device doesn’t show up, make sure, that no other program is connected to the Arduino. If you still have the Arduino IDE open, close the program, unplug the Arduino, and connect it again. Now, SuperCollider should be able to find the Arduino with the previous command. This should work on MacOS and Windows. If you are using a linux device, you first must allow the connection to the Arduino via the Terminal. This is a safety mechanism on Linux devices, you find many helpfiles for this online.
To connect to the Arduino, enter its name under YOUR_ARDUINO. 

```supercollider
(
SerialPort.closeAll;
~port = SerialPort.new("YOUR_ARDUINO", 115200); //change the name according to your arduino
~arduinoData = [];
~values = [];
CmdPeriod.doOnce({Tdef(\getData).stop;SerialPort.closeAll;});
);
```
