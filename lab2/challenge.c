/*
    Challenge:
    Modify your TekBot so it can move objects across a tabletop. Your TekBot
    needs to push objects that it touches a short distance. 

    Port Map:
    Port B, Pin 4 -> Output -> Right Motor Enable
    Port B, Pin 5 -> Output -> Right Motor Direction
    Port B, Pin 7 -> Output -> Left Motor Enable
    Port B, Pin 6 -> Output -> Left Motor Direction
    Port D, Pin 1 -> Input -> Left Whisker
    Port D, Pin 0 -> Input -> Right Whisker
*/

#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>

int main(void)
{
    // data direction register. 1 is output. 0 is input.
    DDRB =  0b11110000;    // Setup Port B for Input/Output
    DDRD =  0;             // Setup Port D for Input/Output
    PORTD = 0b11111111;    // Activate pull up resistor
    PORTB = 0b11110000;    // Turn off both motors


    PORTB = 0b01100000;    // Make TekBot move forward
    while (1) // Loop Forever
    {
        // a. TekBot hits object
        if (left_whisker_hit()) {
            // b. TekBot continues forwards for a short period of time
            _delay_ms(500);
            // c. TekBot backs up slightly
            PORTB = 0b00000000;
            // d. TekBot turns slightly towards the object
            PORTB = 0b00100000;    // Turn Left
            _delay_ms(1000);
            PORTB = 0b01100000;    // Make TekBot move forward
        } else if (right_whisker_hit()) {
            // b. TekBot continues forwards for a short period of time
            _delay_ms(500);
            // c. TekBot backs up slightly
            PORTB = 0b00000000;
            // d. TekBot turns slightly towards the object
            PORTB = 0b01000000;    // Turn Right
            _delay_ms(1000);
            PORTB = 0b01100000;    // Make TekBot move forward
        }
    }
}

int left_whisker_hit() {
    return ~PIND & 2;
}

int right_whisker_hit() {
    return ~PIND & 1;
}
