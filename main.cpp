/* mbed Microcontroller Library
 * Copyright (c) 2006-2013 ARM Limited
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


#include "mbed.h"
#include "BLE.h"
#include "ButtonService.h"

BLE         ble;
DigitalOut  led1(LED1);

Serial pc(USBTX, USBRX);

const static char     DEVICE_NAME[] = "Button";
static const uint16_t uuid16_list[] = {ButtonService::BUTTON_SERVICE_UUID};
//bool is_pressed = false;

enum {
    PRESSED = 0,
    RELEASED,
    IDLE
};
static uint8_t buttonState = IDLE;

ButtonService *buttonServicePtr;

void buttonPressedCallback(void)
{
    /* Note that the buttonPressedCallback() executes in interrupt context, so it is safer to access
     * BLE device API from the main thread. */
    buttonState = PRESSED;
}

void buttonReleasedCallback(void)
{
    /* Note that the buttonReleasedCallback() executes in interrupt context, so it is safer to access
     * BLE device API from the main thread. */
    buttonState = RELEASED;
}

void disconnectionCallback(const Gap::DisconnectionCallbackParams_t *params)
{
    ble.gap().startAdvertising();
}

void periodicCallback(void)
{
    led1 = !led1; /* Do blinky on LED1 to indicate system aliveness. */
   // led2 = !led2;
    //float flexValue = flex.read();
    char buffer[128];
    pc.gets(buffer, 3);
    char flexValue = buffer[0];
    pc.printf("%d\r\n",flexValue);
    buttonServicePtr->updateFlexState(flexValue);
}

int main(void)
{
    led1 = 1;
    Ticker ticker;
    ticker.attach(periodicCallback, 1);
  //  button.fall(buttonPressedCallback);
   
    ble.init();
    ble.gap().onDisconnection(disconnectionCallback);
    pc.baud(9600);
    
    ButtonService buttonService(ble, false /* initial value for button pressed */, 0);
    buttonServicePtr = &buttonService;

    /* setup advertising */
    ble.gap().accumulateAdvertisingPayload(GapAdvertisingData::BREDR_NOT_SUPPORTED | GapAdvertisingData::LE_GENERAL_DISCOVERABLE);
    ble.gap().accumulateAdvertisingPayload(GapAdvertisingData::COMPLETE_LIST_16BIT_SERVICE_IDS, (uint8_t *)uuid16_list, sizeof(uuid16_list));
    ble.gap().accumulateAdvertisingPayload(GapAdvertisingData::COMPLETE_LOCAL_NAME, (uint8_t *)DEVICE_NAME, sizeof(DEVICE_NAME));
    ble.gap().setAdvertisingType(GapAdvertisingParams::ADV_CONNECTABLE_UNDIRECTED);
    ble.gap().setAdvertisingInterval(1000); /* 1000ms. */
    ble.gap().startAdvertising();

    while (true) {
       // if(!is_pressed && butto.read() > 0.9999) {
         //   buttonState = PRESSED;
          //  is_pressed = true;
       // } else if(is_pressed && butto.read() < 0.9999) {
          //  buttonState = RELEASED;
          //  is_pressed = false;
        //}
        
        if (buttonState!=IDLE) {
            buttonServicePtr->updateButtonState(buttonState);
            pc.puts("Button state is ");
            pc.putc(buttonState);
            pc.puts("\r\n");
            buttonState = IDLE;
        }
        ble.waitForEvent();
    }
}
