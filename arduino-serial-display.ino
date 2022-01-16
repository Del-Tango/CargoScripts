#include <LiquidCrystal.h>

LiquidCrystal lcd = LiquidCrystal(2, 3, 4, 5, 6, 7);

void setup() {
    lcd.begin(16, 2);
    Serial.begin(9600);
    lcd.setCursor(1,0);
    lcd.print("No Data");
}

void loop() {
    delay(500);
    lcd.setCursor(1, 0);
    if (Serial.available() > 0) {
        lcd.print(Serial.readString());
    }
}


