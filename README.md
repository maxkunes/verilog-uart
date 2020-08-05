# verilog-uart
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## A relatively simple uart transmitter and receiver written in Verilog!

### Files
- `top.sv`    : UART echo module that runs at 921600 baud.
- `uart.sv`   : UART transmitter and receiver. See `top.sv` for an example on how to use `uart.sv`

This is my first attempt at learning HDL and working with FPGAs so please excuse the crudity of this model. I didn't have time to build it to scale or paint it!
 
Both files should work out of the box with Vivado and this project was tested on the ARTY Development board. `clock_counter_width` in `uart.sv` uses `clog2` which may not be supported by your ide. Feel free to hardcode that value to something like 16 or less if you know what you are doing!