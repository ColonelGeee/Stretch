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