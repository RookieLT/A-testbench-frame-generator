# A-testbench-frame-generator

perl tbmaker.pl <design_file.v> -v -p 20 +t=1ns/1ps

replace design_file with your file name
-v/-verdi: turn on fsdbdump (off by default)
-p period: specify clk period (10ns by default)
+t: specify timescale (1ns/1ns by default)
