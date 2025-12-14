# output data and remove previous designs
sh date
remove_design -designs

# set top name
set top_name spike_array

# set library path
set search_path {./library}
set target_library {tcbn28hpcplusbwp12t40p140ssg0p9v125c.db}
set link_library {tcbn28hpcplusbwp12t40p140ssg0p9v125c.db}
#set target_library {test.db}
#set link_library {test.db}

# read design file
#set design_path "./module"
#set verilog_files [glob -nocomplain -type f $design_path/*.v]
#foreach file $verilog_files {
#	read_file -format verilog $file
#}

# read all the files under design_path
set design_path "./rtl/src"
set verilog_files [glob -nocomplain -type f $design_path/*.v]
foreach file $verilog_files {
	read_file -format verilog $file
}


current_design $top_name

# reset constraints
reset_design
link
uniquify

# set design environment
# just for script functional test
#set_load 0.01 [all_output]

# set design constraints 
# timing 500MHz
#create_clock -name clk -period 2 -waveform {0 1} [get_ports clk]
# donot optimize clk
#set_dont_touch_network [get_clocks clk]

# timing delay and uncertainty
#set_input_delay -max 0.2 -clock clk [remove_from_collection [all_inputs] clk]
#set_output_delay -max 0.2 -clock clk [all_outputs]
#set_input_transition 0.03 [all_inputs]
#set_clock_uncertainty 0.1 [get_clocks clk]

# timing 1000MHz
set clk_port [get_ports clk]
#puts "clk port found: $clk_port"
set clk_period 1
create_clock -name clk -period $clk_period -waveform {0 0.5} $clk_port
set_clock_uncertainty 0.1 [get_clocks clk]


# set ports
set all_inputs_no_clk [remove_from_collection [all_inputs] $clk_port]
set ctrl_inputs [get_ports {rst start}]  
set data_inputs [get_ports {i_weights_flat i_acts_flat}]
set output_ports [get_ports {done result}]
#puts "Output ports found: $output_ports"  


# ports delay
set_input_delay -max 0.10 -clock clk $ctrl_inputs
set_input_delay -min 0.04 -clock clk $ctrl_inputs

set_input_delay -max 0.12 -clock clk $data_inputs
set_input_delay -min 0.05 -clock clk $data_inputs

set_input_transition 0.025 $ctrl_inputs
set_input_transition 0.035 $data_inputs

set_output_delay -max 0.05 -clock clk $output_ports
set_output_delay -min 0.02 -clock clk $output_ports

set_load 0.4 [get_ports done]
set_load 0.6 [get_ports result]

# async reset 
set_async_reset 1 [get_ports rst]

# area
set_max_area 0

# run compile
compile

# report generation
report_area > ./report/area.txt
report_power > ./report/power.txt
report_timing > ./report/timing.txt

report_constraint all_violators > ./report/violators.txt
report_qor > ./report/qor.txt

# save output file
write_sdc ./postsyn/spike_array.sdc
write_sdf ./postsyn/spike_array.sdf
write -f verilog -hier -output ./postsyn/netlist.v
write_file -f ddc -hierarch -output ./postsyn/spike_array.ddc


exit




