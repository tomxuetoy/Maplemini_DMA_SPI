// Code developed by Pol Pla i Conesa

// 1. Import "dma.h"
#include <dma.h>

// 2. Create a HardwareSPI object.
HardwareSPI spi(1);
volatile int recieveData, sentData, complete;
int outPinHigh = 20;
int inPin = 7, val;
// we create a buffer for revceiving the responses
volatile byte bytesReceived[512];
// create an array of bytes we want to sentData
volatile byte bytesToSend[512];

// this function is the one that we are going to call
// when the transmission is complete (we have to check if
// the transfer was successful or if it generated an error)
void DMAEvent(){

  //we get the DMA event

    dma_irq_cause event = dma_get_irq_cause(DMA1, DMA_CH3);

  switch(event) {
    //the event indicates that the transfer was successfully completed
  case DMA_TRANSFER_COMPLETE:
    //11. Disable DMA when we are done
    dma_disable(DMA1,DMA_CH3);
    SerialUSB.println("Done transfering");
    complete = complete + 3;
    recieveData = bytesReceived[10] + 3;
    sentData = bytesToSend[10] + 3;
    break;
    //the event indicates that there was an error transmitting
  case DMA_TRANSFER_ERROR:
    //11. Disable DMA when we are done
    dma_disable(DMA1,DMA_CH3);
    SerialUSB.println("Fail");
    break;
  case DMA_TRANSFER_HALF_COMPLETE:
    dma_disable(DMA1,DMA_CH3);
    SerialUSB.println("Half done trasnfering");
    break;
  default:
    SerialUSB.println("This is the default handler");
    break;
  }
}

void setup(){

  pinMode(inPin, INPUT);

  pinMode(outPinHigh, OUTPUT);
  digitalWrite(outPinHigh, HIGH);

  // 3. Init the HardwareSPI object.
  spi.begin(SPI_18MHZ, MSBFIRST, 0);

  // 4. Initialize DMA.
  dma_init(DMA1);

  //5. Enable DMA to use SPI communication; both TX (output) and RX (input).
  spi_tx_dma_enable(SPI1);
  spi_rx_dma_enable(SPI1);

  //fill the array with data (put your own)
  for(int i=0; i<512; i++) {
    bytesToSend[i] = 12;
    bytesReceived[i] = 34;
  }

  complete = complete+88;

  // 6. Setup a DMA transfer (for both TX and RX). If we only want
  // to read (RX) or write (TX) it is fine to just setup one. In this
  // case we want to transfer (write and get a response) so we do both.
  // Parameters:
  // - DMA
  // - DMA channel
  // - Memory register for SPI
  // - The size of the SPI memory register
  // - The buffer we want to copy things to or transmit things from
  // - The unit size of that buffer
  // - Flags (see the Maple DMA Wiki page for more info in flags)
  dma_setup_transfer(DMA1, DMA_CH2, &SPI1->regs->DR, DMA_SIZE_8BITS,
  bytesReceived, DMA_SIZE_8BITS, (DMA_MINC_MODE | DMA_TRNS_CMPLT | DMA_TRNS_ERR));  // DMA_CH2 - SPI1_RX
  dma_setup_transfer(DMA1, DMA_CH3, &SPI1->regs->DR, DMA_SIZE_8BITS,
  bytesToSend, DMA_SIZE_8BITS,(DMA_MINC_MODE | DMA_CIRC_MODE | DMA_FROM_MEM));      // DMA_CH3 - SPI1_TX

  // 7. Attach an interrupt to the transfer. Note that we need to add
  // the interrupt flag in step 6 (DMA_TRNS_CMPLT and DMA_TRNS_ERR).
  // Also, we only attach it for one of the transfers since they are
  // going to finish at the same time because they are in sync.
  dma_attach_interrupt(DMA1, DMA_CH2, DMAEvent);

  //8. Setup the priority for the DMA transfer.
  dma_set_priority(DMA1, DMA_CH2, DMA_PRIORITY_VERY_HIGH);
  dma_set_priority(DMA1, DMA_CH3, DMA_PRIORITY_VERY_HIGH);

  // 9. Setup the number of bytes that we are going to transfer.
  dma_set_num_transfers(DMA1, DMA_CH2, 512);
  dma_set_num_transfers(DMA1, DMA_CH3, 512);

  // 10. Enable DMA to start transmitting. When the transmission
  // finishes the event will be triggered and we will jump to
  // function DMAEvent.
  dma_enable(DMA1, DMA_CH2);
  dma_enable(DMA1, DMA_CH3);
}

void loop(){
  val = digitalRead(inPin);
  SerialUSB.print("inPin value = ");
  SerialUSB.println(val);
  SerialUSB.print("complete value = ");
  SerialUSB.println(complete);
  SerialUSB.print("recieveData = ");
  SerialUSB.println(recieveData);
  SerialUSB.print("sentData = ");
  SerialUSB.println(sentData);
  delay(100);
}

//Connect gnd and miso, for RX. And below is the Serial output:
//inPin value = 1
//complete value = 91
//recieveData = 3
//sentData = 15

//Connect pin20 (output HIGH) and miso, for RX. And below is the Serial output:
//inPin value = 1
//complete value = 91
//recieveData = 258
//sentData = 15
