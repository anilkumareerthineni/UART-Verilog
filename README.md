# UART Design and Verification using Verilog and SystemVerilog Assertions

## Overview

This project implements a **UART (Universal Asynchronous Receiver Transmitter)** in **Verilog HDL** and verifies it using **SystemVerilog simulation** and **SystemVerilog Assertions (SVA)**.

The project contains:

* **Baud Rate Generator**
* **UART Transmitter (TX)**
* **UART Receiver (RX)**
* **Top-level UART module**
* **SystemVerilog testbench**
* **Assertion-based verification using SVA**

The transmitter output is internally connected to the receiver input in the top module to perform **loopback verification**.

---

## Features

* Verilog implementation of UART TX and RX
* 8-bit data transmission
* 1 parity bit support
* 1 start bit and 1 stop bit
* Baud-rate based TX and RX timing
* Internal loopback verification
* SystemVerilog testbench for functional simulation
* SystemVerilog Assertions (SVA) for protocol and state checking
* Bind-based assertions for TX and RX

---

## UART Frame Format

The UART frame used in this project is:

* **1 Start bit**
* **8 Data bits**
* **1 Parity bit**
* **1 Stop bit**

So each transmitted frame contains **11 bits** in total.

---

## Project Structure

```text
UART/
├── rtl/
│   ├── baud_rate_gen.v
│   ├── tx.v
│   ├── rx.v
│   └── uart.v
│
├── sva/
│   ├── tx_internal_sva.sv
│   ├── rx_internal_sva.sv
│   ├── tx_bind.sv
│   ├── rx_bind.sv
│   └── uart_top_sva_monitor.sv
│
├── tb/
│   └── uart_tb_sva.sv
│
└── README.md
```

---

# RTL Modules

## 1. Baud Rate Generator (`baud_rate_gen.v`)

The baud rate generator generates timing enable pulses required for UART transmission and reception.

### Function

* Produces **`tx_en`** for the transmitter
* Produces **`rx_en`** for the receiver

These enable pulses are used to control the timing of the serial data transfer.

---

## 2. UART Transmitter (`tx.v`)

The transmitter converts 8-bit parallel input data into a serial UART frame.

### TX Operation

1. Waits for `write_en`
2. Loads the input byte and parity bit
3. Sends the frame in the following order:

   * start bit (`0`)
   * 8 data bits
   * parity bit
   * stop bit (`1`)
4. Asserts `done` when transmission is complete

### TX Signals

* `clk` : system clock
* `rst` : active-low reset
* `write_en` : starts transmission
* `tx_en` : baud enable pulse
* `data_in[7:0]` : parallel input data
* `tx_out` : serial UART output
* `busy` : indicates transmission is in progress
* `done` : asserted after frame transmission completes

---

## 3. UART Receiver (`rx.v`)

The receiver converts incoming serial UART data back into parallel data.

### RX Operation

1. Detects the start condition on `rx_in`
2. Samples incoming bits using `rx_en`
3. Stores:

   * 8 data bits
   * parity bit
4. Checks parity correctness
5. Generates:

   * `data_out`
   * `done`
   * `data_valid`

### RX Signals

* `clk` : system clock
* `rst` : active-low reset
* `rx_in` : serial UART input
* `rx_en` : receiver sampling enable pulse
* `clr` : clears receive completion flag
* `data_out[7:0]` : received parallel data
* `done` : receive completion pulse
* `data_valid` : asserted when parity check passes

---

## 4. Top-Level UART (`uart.v`)

The top-level UART module instantiates:

* baud rate generator
* UART transmitter
* UART receiver

For verification, the design uses **internal loopback**, where the transmitter output is connected directly to the receiver input.

```verilog
rx_in = tx_out;
```

This allows the transmitted data to be received back internally during simulation.

---

# Verification Methodology

The design is verified using:

1. **SystemVerilog Testbench**
2. **SystemVerilog Assertions (SVA)**

The verification flow checks both:

* **functional correctness** of UART transmission and reception
* **protocol/state correctness** using assertions

---

# Testbench Verification

## Testbench File

* `uart_tb_sva.sv`

The testbench performs the following:

* generates the system clock
* applies reset
* sends multiple bytes through the transmitter
* waits for TX completion
* waits for RX completion
* compares received data with transmitted data
* prints **PASS/FAIL** messages

### Testbench Flow

For each test byte:

1. Wait until UART is not busy
2. Apply `data_in`
3. Pulse `write_en`
4. Wait for `done_tx`
5. Wait for `done_rx`
6. Compare `data_out` with transmitted byte
7. Print PASS/FAIL result
8. Pulse `clr`

---

# Assertion-Based Verification

The project uses **bind-based internal assertions** for the TX and RX modules, along with a top-level UART assertion monitor.

---

## Assertion Files

### TX Assertions

* `tx_internal_sva.sv`
* `tx_bind.sv`

### RX Assertions

* `rx_internal_sva.sv`
* `rx_bind.sv`

### Top-Level Assertions

* `uart_top_sva_monitor.sv`

---

# Why `bind` is used

Instead of modifying the RTL directly, assertions are attached externally using `bind`.

This allows:

* keeping RTL clean
* separating design and verification code
* accessing internal state signals for stronger assertion checking
* easier maintenance and readability

---

# TX Assertions (`tx_internal_sva.sv`)

The transmitter assertions verify:

* TX output remains high in **IDLE**
* `write_en` in IDLE moves TX to **START**
* START state correctly drives the start bit
* DATA state remains active until all bits are transmitted
* DATA transitions to STOP at the correct time
* `busy` remains asserted while TX is active
* STOP state correctly completes the frame and returns to IDLE
* `done` behaves as a one-cycle pulse
* stop bit is high when transmission completes

These assertions use internal TX signals such as:

* `state`
* `bit_count`

---

# RX Assertions (`rx_internal_sva.sv`)

The receiver assertions verify:

* START transitions to RECEIVE correctly
* RECEIVE transitions to STOP correctly
* STOP transitions back to START correctly
* `done` is asserted at receive completion
* `data_valid` only occurs with `done`
* `data_valid` behaves as a one-cycle pulse
* `clr` clears `done`
* parity must match when `data_valid` is asserted
* `data_out` must not be unknown when receive completes

These assertions use internal RX signals such as:

* `state`
* `sample`
* `index`
* `temp`

---

# Top-Level UART Assertions (`uart_top_sva_monitor.sv`)

The top-level assertions verify the end-to-end UART loopback behavior.

These checks include:

* no new write request while UART is busy
* accepted write request eventually produces `done_tx`
* `done_tx` eventually leads to `done_rx`
* received valid data matches the transmitted byte

---

# Test Cases Used

The UART was tested with the following input bytes:

* `8'h55`
* `8'hA3`
* `8'h00`
* `8'hFF`

These values help verify correct UART transmission and reception for different bit patterns.

---

# Sample Simulation Output

```text
[65000] SENT = 55
[572925000] TX DONE for 55
[624045000] RX DONE, data_out = 55, data_valid = 1
PASS: expected=55 received=55

[624075000] SENT = A3
[1145805000] TX DONE for A3
[1196045000] RX DONE, data_out = A3, data_valid = 1
PASS: expected=A3 received=A3

[1196075000] SENT = 00
[1718685000] TX DONE for 00
[1768045000] RX DONE, data_out = 00, data_valid = 1
PASS: expected=00 received=00

[1768075000] SENT = FF
[2291565000] TX DONE for FF
[2340045000] RX DONE, data_out = FF, data_valid = 1
PASS: expected=FF received=FF
```

This confirms correct loopback transmission and reception for all tested bytes.

---

# Tools Used

* **Verilog HDL** for RTL design
* **SystemVerilog** for testbench and assertions
* **Xilinx Vivado** for simulation and verification

---

# How to Run in Vivado

## Add these as Design Sources

* `baud_rate_gen.v`
* `tx.v`
* `rx.v`
* `uart.v`

## Add these as Simulation Sources

* `uart_tb_sva.sv`
* `tx_internal_sva.sv`
* `rx_internal_sva.sv`
* `tx_bind.sv`
* `rx_bind.sv`
* `uart_top_sva_monitor.sv`

## Set Simulation Top

```text
uart_tb_sva
```

## Run Procedure

1. Create a new Vivado project
2. Add RTL files as **Design Sources**
3. Add testbench and SVA files as **Simulation Sources**
4. Set simulation top module as `uart_tb_sva`
5. Run behavioral simulation
6. Observe:

   * PASS/FAIL messages in the simulation console
   * assertion failures, if any
   * UART waveforms in the waveform viewer

---

# Key Learnings

This project helped in understanding:

* UART serial communication protocol
* start bit / data bits / parity / stop bit framing
* baud-rate controlled TX and RX timing
* parity generation and checking
* receiver sampling logic
* loopback-based functional verification
* SystemVerilog testbench development
* assertion-based verification using SVA
* use of `bind` for clean verification flow

---

# Future Improvements

Possible extensions to this project include:

* configurable baud rate
* selectable parity mode (odd/even/none)
* configurable stop bits
* separate external RX input instead of loopback-only mode
* FIFO buffering for TX/RX
* formal verification of UART properties
* constrained-random verification environment

---

# Conclusion

This project demonstrates the design and verification of a UART using **Verilog HDL** and **SystemVerilog Assertions**.

It includes:

* RTL implementation of UART transmitter, receiver, baud generator, and top module
* simulation-based verification using a SystemVerilog testbench
* bind-based internal assertion checking for TX and RX
* top-level loopback verification for end-to-end data correctness

Overall, this project combines **digital design**, **simulation**, and **assertion-based verification** in a compact UART implementation.
