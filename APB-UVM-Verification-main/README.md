# APB UVM Verification Environment

A SystemVerilog UVM-based verification environment for an **AMBA APB (Advanced Peripheral Bus)** interface, developed and simulated using **QuestaSim**.

The project demonstrates a reusable UVM verification architecture with constrained-random stimulus, protocol-aware monitoring, a reference-model-based scoreboard, functional coverage, protocol assertions, wait-state handling, and APB error-response verification.

## 1. Project Overview

The objective of this project is to verify APB read and write transactions using a class-based **UVM testbench**.

The environment uses an **APB Slave BFM (Bus Functional Model)** as the verification-side slave model.

The environment verifies:

- APB read transactions
- APB write transactions
- APB SETUP and ACCESS phases
- Variable APB wait states using `PREADY`
- APB error responses using `PSLVERR`
- Valid and invalid address accesses
- Read/write data integrity
- Scoreboard-based checking
- Constrained-random transactions
- Functional coverage
- Basic APB protocol assertions

## 2. Verification Architecture

```text
                         +----------------------+
                         |      APB UVM Test    |
                         +----------+-----------+
                                    |
                                    v
                         +----------------------+
                         |     UVM Environment  |
                         +----------+-----------+
                                    |
                 +----------------+----------------+
                 |                                 |
                 v                                 v
        +-------------------+             +-------------------+
        |    APB Agent      |             |    Scoreboard     |
        +---------+---------+             +---------+---------+
                  |                                 ^
          +-------+-------+                          |
          |       |       |                          |
          v       v       v                          |
       Sequencer Driver  Monitor -------------------+
          |       |       |
          |       |       +------------------+
          |       |                          |
          |       v                          v
          |   APB Interface          Functional Coverage
          |       |
          |       v
          |  APB Slave BFM
          |       |
          +-------+
```

### Main data flow

```text
Sequence
   |
   v
Sequencer
   |
   v
Driver
   |
   v
APB Interface
   |
   v
APB Slave BFM
   |
   v
Monitor
   |
   +--------> Scoreboard
   |
   +--------> Functional Coverage
```

## 3. UVM Components

### APB Sequence Item

`apb_rw.sv`

Defines the transaction-level representation of an APB operation.

Main transaction fields include:

- Address
- Write/read command
- Write data
- Read data
- Error response

The transaction uses constraints to generate aligned legal APB addresses and a configurable read/write distribution.

### APB Sequencer

Implemented in `apb_driver_seq_mon.sv`.

The sequencer provides directed or randomized `apb_rw` transactions to the driver.

### APB Driver

Implemented in `apb_driver_seq_mon.sv`.

The driver converts transaction-level requests into APB bus activity.

For each transaction, the driver generates:

1. IDLE
2. SETUP
3. ACCESS
4. Wait for `PREADY`
5. Capture `PRDATA` / `PSLVERR`

The driver supports both read and write operations.

### APB Monitor

Implemented in `apb_driver_seq_mon.sv`.

The monitor observes the APB interface and reconstructs completed transactions.

A transaction is sampled only when:

```text
PSEL = 1
PENABLE = 1
PREADY = 1
```

This ensures that transactions are collected after the APB transfer actually completes, including transfers containing wait states.

The monitor sends transactions through a UVM analysis port to:

- Scoreboard
- Functional coverage

### APB Agent

Implemented in `apb_agent_env_config.sv`.

The agent contains:

- Sequencer
- Driver
- Monitor

The virtual interface is passed to the driver and monitor using `uvm_config_db`.

### UVM Environment

Implemented in `apb_agent_env_config.sv`.

The environment instantiates:

- APB agent
- Scoreboard
- Coverage collector

The monitor's analysis port is connected to both the scoreboard and coverage subscriber.

## 4. APB Slave BFM

File: `apb_slave_bfm.sv`

The project uses an APB Slave BFM instead of a synthesizable APB slave RTL design.

The BFM provides:

- Register-like memory behavior
- Read/write storage
- Variable wait-state insertion
- `PREADY` generation
- `PSLVERR` generation
- Invalid-address detection

### Valid address range

The verification model treats the following addresses as valid:

```text
0x00000000 - 0x0000003C
```

with 4-byte alignment.

Therefore, the valid register locations are:

```text
0x00, 0x04, 0x08, 0x0C, ... , 0x38, 0x3C
```

Invalid addresses generate an APB error response through:

```text
PSLVERR = 1
```

## 5. APB Wait-State Verification

The slave BFM can introduce up to two wait states.

During a wait state:

```text
PSEL     = 1
PENABLE  = 1
PREADY   = 0
```

The driver waits until `PREADY` becomes high before completing the transaction.

The monitor also waits for the completed transfer before publishing the transaction.

This verifies that the environment correctly handles APB transfers requiring multiple ACCESS cycles.

## 6. Scoreboard and Reference Model

File: `apb_scoreboard.sv`

The scoreboard contains an independent reference memory model.

For write transactions:

```text
APB Write
   |
   v
Reference Memory Update
```

For read transactions:

```text
APB Read
   |
   v
Expected Data from Reference Model
   |
   v
Compare with Actual PRDATA
```

The scoreboard also checks `PSLVERR`.

For valid accesses:

```text
PSLVERR = 0
```

For invalid accesses:

```text
PSLVERR = 1
```

This provides transaction-level checking independent of the slave BFM's internal implementation.

## 7. Functional Coverage

File: `apb_coverage.sv`

The functional coverage model tracks important verification scenarios.

### Command coverage

```text
READ
WRITE
```

### Address coverage

The defined valid register addresses are covered individually, along with an invalid-address category.

### Error coverage

```text
NO_ERROR
ERROR
```

### Cross coverage

The project also crosses:

```text
Command × Error
```

The regression achieved:

```text
100% of the defined functional coverage model
```

This represents coverage of the bins defined in this project's coverage model; it does not mean that every possible APB behavior has been exhaustively verified.

## 8. Protocol Assertions

File: `apb_if.sv`

The APB interface contains assertions for basic protocol behavior.

### PENABLE requires PSEL

```text
PENABLE -> PSEL
```

This checks that `PENABLE` is not asserted without an active APB select.

### SETUP to ACCESS transition

A SETUP cycle:

```text
PSEL = 1
PENABLE = 0
```

must be followed by an ACCESS cycle:

```text
PSEL = 1
PENABLE = 1
```

### Control stability during wait states

When an APB transfer is waiting for `PREADY`, important control information such as address, read/write direction, and write data must remain stable.

## 9. Verification Sequences

File: `apb_sequences.sv`

The project includes multiple verification scenarios.

### Smoke Sequence

`apb_smoke_seq`

Performs directed write/readback operations using several valid addresses.

Example:

```text
WRITE 0x00 -> AAAA1111
READ  0x00 -> AAAA1111

WRITE 0x04 -> BBBB2222
READ  0x04 -> BBBB2222
```

### Constrained-Random Sequence

`apb_random_seq`

Generates 50 randomized APB transactions.

The sequence exercises:

- Random addresses within the legal range
- Aligned addresses
- Random read/write operations
- Different data values

### Error Sequence

`apb_error_seq`

Explicitly accesses invalid addresses to verify error handling.

Example:

```text
WRITE 0x100
READ  0x104
```

Expected behavior:

```text
PSLVERR = 1
```

## 10. Testbench Files

| File | Description |
|---|---|
| `testbench.sv` | Top-level simulation module |
| `apb_if.sv` | APB interface, clocking blocks and assertions |
| `apb_rw.sv` | APB UVM sequence item |
| `apb_driver_seq_mon.sv` | Driver, sequencer and monitor |
| `apb_agent_env_config.sv` | Configuration, agent and environment |
| `apb_scoreboard.sv` | Reference model and transaction checking |
| `apb_coverage.sv` | Functional coverage |
| `apb_sequences.sv` | Directed and constrained-random sequences |
| `apb_test.sv` | UVM test |
| `apb_slave_bfm.sv` | APB slave bus functional model |
| `run.do` | QuestaSim compilation and simulation script |

## 11. Simulation Flow

The complete testbench can be compiled and simulated using the provided QuestaSim script.

Run from QuestaSim:

```tcl
do run.do
```

The script:

1. Cleans the previous `work` library
2. Creates a new `work` library
3. Compiles the SystemVerilog testbench
4. Starts the UVM test
5. Adds APB signals to the waveform
6. Runs the simulation to completion

## 12. Regression Results

The final known-good regression exercised:

```text
Smoke transactions          : 10
Constrained-random          : 50
Error transactions          : Included
--------------------------------
Total monitored             : 60
Scoreboard PASS             : 60
Scoreboard FAIL             : 0
Functional coverage         : 100%
UVM errors                  : 0
UVM fatals                  : 0
```

Wait states were exercised during the simulation, and invalid accesses generated the expected `PSLVERR` response.

The single UVM warning observed in the regression corresponds to the intentionally generated APB error response for an invalid transaction and is not a scoreboard failure.

## 13. Tools and Technologies

- **SystemVerilog**
- **UVM**
- **QuestaSim / ModelSim**
- **Constrained-Random Verification**
- **Functional Coverage**
- **SystemVerilog Assertions**
- **Reference Model / Scoreboard**
- **APB Protocol**

## 14. Verification Concepts Demonstrated

This project demonstrates practical knowledge of:

- UVM testbench architecture
- Sequence items
- Sequences
- Sequencers
- Drivers
- Monitors
- Agents
- Environments
- Virtual interfaces
- `uvm_config_db`
- UVM factory mechanism
- Analysis ports
- Scoreboards
- Reference models
- Constrained randomization
- Functional coverage
- Cross coverage
- SystemVerilog assertions
- APB protocol phases
- Wait-state handling
- Error-response verification
- QuestaSim simulation and debugging

## 15. Project Limitation

This implementation uses an **APB Slave BFM** as the device-side model rather than a synthesizable APB slave RTL DUT.

Therefore, the project primarily demonstrates the construction and operation of an APB UVM verification environment.

For a production-level DUT verification project, the next step would be to replace the BFM with an actual APB slave RTL design and verify its implementation against the APB protocol and functional requirements.

## 16. Future Enhancements

Potential extensions include:

- Replace the slave BFM with an actual APB RTL DUT
- Add reset verification
- Add dedicated smoke, random, error and wait-state tests
- Add back-to-back APB transfer testing
- Add boundary-address testing
- Add additional protocol assertions
- Add coverage-driven test refinement
- Add multiple APB slave/register regions
- Add UVM configuration objects for BFM parameters
- Add regression automation
- Integrate the project with CI where simulator licensing permits

## 17. Repository Purpose

This repository is intended as a **Design Verification portfolio project** demonstrating the development of a structured SystemVerilog/UVM environment for a standard on-chip bus protocol.

The focus is on showing how stimulus generation, protocol driving, monitoring, checking, coverage, and assertions work together to verify a hardware interface.
