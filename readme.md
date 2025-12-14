# Performance Comparison between W4A4 and W4ASpike
* Aiming to provide a comparative analysis of two different methods, W4A4 and W4ASpike (with different encoding schemes), for a specific computational workload.

## WorkLoad
*   **Vector Dot Product**: executing 128-dimensional vector dot product 1024 times

## Comparison metrics
### Vitis HLS
* Implemented each fuction unit by High Level synthesis. 
* Component part is xczu9eg-ffvb1156-2-e. Target clock is 200MHz with a clock_uncertainty of 27%. Resource usage is evaluated based on the post-synthesis results from Vitis HLS. latency, resource usage and timing are reported.

| design      | clock  | co-sim latency | post_syn timing (ns) | LUT   | FF    | DSP | BRAM | SRL  | CLB  |
|:-----------:|:------:|:--------------:|:--------------------:|:-----:|:-----:|:---:|:----:|:----:|:----:|
| naive dot-dsp  | 200MHz | 1138           | 2.299                | 6731  | 10131 | 58  | 30   | 407  | 1523 |
|naive dot-fabric|	200MHz|	1131	       |2.210	              |8050	  |8650	  |0	|30	   |287	  |1665  |
| s-bin-par      | 200MHz | 1170           | 2.430                | 16919 | 14940 | 0   | 30   | 1847 | 3380 |
| s-bin-ser      | 200MHz |	9301	       |2.353	              |7985	  |10863  | 1	| 30   |1344  |1759  |

### Vivado Design suite
* Implemented using verilog and compiled by Vivado 2024.
* Synthesized at 200MHz. Component part is xczu9eg-ffvb1156-2-e. The adder tree designs all use a seven-stage pipeline. Resource usage and timing are obtained from implementation report.
* note: before syn and im, we run `set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]` in Tcl Console to avoid IO utilization report.
* Startup latency:
	* naive_dot: 7 cycles
	* spike_add_dot: 9 cycles

| design        | clock | WNS (ns) | sim_latency | CLB LUTs | CLB Registers | CARRY8 | F7 Muxes | F8 Muxes |Startup latency|
|:-------------:|:-----:|:--------:|:-----------:|:--------:|:-------------:|:------:|:--------:|:--------:|:-------------:|
| naive_dot     | 200MHz  | 4.021    | 1034        | 4142     | 1286          | 254    | 896      | 128      |7 cycles       |
| spike_add_dot | 200MHz  | 3.738    | 1034        | 4647     | 3570          | 314    | 0        | 0        |9 cycles       |

### Design Compiler
* Implemented using verilog and compiled by DC 2022.
* All the unit is synthesized at 1GHz, and the adder tree designs all use a four-stage pipeline. The timing, area, and power results are reported below.
* Startup latency:
	* naive_dot: 4 cycles
	* spike_add_dot: 5 cycles

| design        | clock | timing (ns) | slack (ns) | Total cell area (um^2) | Dynamic Power (mW) | Static Power (uW) | Total Power (mW) |Startup latency|
|:-------------:|:-----:|:-----------:|:----------:|:----------------------:|:------------------:|:-----------------:|:----------------:|:-------------:|
| naive_dot     | 1GHz  | 0.67        | 0.21       | 13750.63               | 9.74               | 299.14            | 10.04            |4 cycles       |
| spike_add_dot | 1GHz  | 0.64        | 0.24       | 19329.24               | 19.84              | 425.31            | 20.27            |5 cycles       |
  


