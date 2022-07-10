# DES-VHDL-Demo  
An implementation of the Data Encryption Standard (DES) in VHDL for Altera DE2 Board.  
The Demo allows a user to set up a point to point serial messaging interface that will encrypt/decrypt all messages using DES.  

Usage: After programming the DE2 board, connect a VGA monitor, a PS/2 keyboard, and a serial cable.  
If two DE2 boards are available, use the serial cable to connect their RX and TX lines.   
If only one DE2 board is available, you can instead connect the RX and TX lines together for the demonstration.   
When running, use the keyboard to enter in the DES key and Message to send (up to 56 characters), and then press Key 0 on the dev board.  
The message will be encrypted, transmitted over the serial interface and displayed decrypted on the receiver end.  

