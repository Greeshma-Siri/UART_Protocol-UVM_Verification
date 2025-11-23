# UART UVM Testbench Architecture

This document describes the UVM testbench structure used to verify the **UART Core**.  
The following block diagram represents the complete UVM environment hierarchy.




---

## 📌 Overview

This UVM testbench verifies the functionality of a **UART Core** using a layered architecture with separate **TX** and **RX agents**.  
It supports constrained-random stimulus generation, transaction-level modeling, checking, coverage collection, and scoreboarding.

---

+--------------------------------------------------------------------------------+
| UVM TESTBENCH |
| |
| +-------------------+ +-----------------+ +-----------------------+ |
| | Test | --> | Environment | --> | Scoreboard | |
| | (uart_base_test) | | (uart_env) | | (uart_scoreboard) | |
| +-------------------+ +-----------------+ +-----------------------+ |
| | | | |
| +-----------+ +--------+ | |
| | | | |
| +-------v------+ +-------v------+ | |
| | Agent | | Agent | | |
| | (TX) | | (RX) | | |
| +--------------+ +--------------+ | |
| | | | | | |
| +-------v----+ +--v-------------+ +--------v----+ +-v----------------+ |
| | Sequencer | | Driver | Monitor| | Sequencer | | Driver | Monitor | |
| | (tx_seqr) | | (tx_drv) | | (rx_seqr) | | (rx_drv) | |
| +------------+ +----------------+ +------------+ +------------------+ |
| | | |
| +--------v-----------------------------v--------+ |
| | Interface | |
| | (uart_if - Virtual Interface) | |
| +----------------------------------------------+ |
| | |
+--------------------------------------------------------------------------------
|
| (Signals: clk, rst_n, tx, rx, ...)
v
+---------------------+
| DUT |
| (UART Core) |
+---------------------+

## 🧪 Test (`uart_base_test`)

- Instantiates the `uart_env`.
- Configures virtual interface, agents, and test-specific settings.
- Starts TX and RX sequences.

---

## 🌐 Environment (`uart_env`)

Responsible for:
- Creating and connecting both UART agents (TX and RX).
- Instantiating the `uart_scoreboard`.
- Providing connections between monitors and scoreboard.

---

## 🚦 Agents (TX & RX)

Each agent consists of:
### **1. Sequencer**
- Drives sequences containing UART transaction items.

### **2. Driver**
- Converts sequence items into pin-level UART activity (via virtual interface).
- TX driver drives `tx` signals.
- RX driver stimulates receive side or interacts with DUT outputs based on configuration.

### **3. Monitor**
- Observes DUT signals (tx/rx lines).
- Collects transactions and sends them to the scoreboard for checking.

TX and RX agents operate independently to mimic UART communication.

---

## 📝 Scoreboard (`uart_scoreboard`)

- Receives transactions from TX and RX monitors.
- Compares expected vs. actual UART behavior.
- Performs protocol-level and data integrity checking.

---

## 🔌 Interface (`uart_if`)

A SystemVerilog interface connecting UVM TB to the DUT.

Includes signals:
- `clk`
- `rst_n`
- `tx`
- `rx`
- and any UART configuration/control signals.

Shared through the **virtual interface** mechanism.

---

## 💾 Device Under Test (DUT)

Represents the RTL implementation of the **UART Core**.

The DUT connects to:
- TX & RX pins
- Clock and reset
- Configuration signals (baud rate, parity, etc.)

---

## ✔ Summary

This testbench:
- Follows standard UVM architecture.
- Has separate TX and RX agents for modularity.
- Uses monitors + scoreboard for automated checking.
- Uses virtual interfaces for type-safe communication with the DUT.

---

✅ Example code templates (env, agent, driver, monitor, sequencer, test, etc.)  
Just tell me!
