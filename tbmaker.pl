## Copyright (C) 2022/5/14 by Tong
#!usr/bin/perl

use warnings;
use strict;

my $timescale;
my $design_file;
my $verdi;
my $p;

my $command_argv = join " ",@ARGV;
if($command_argv =~ /-\w*(?:h|help)\w*/){
	print STDOUT "
Usage example: 
perl testbench_maker.pl <filename.v>
+t=1ns/1ps #add timescale at the beginning 
-p 5       #specify clock period 
-verdi     #enable fsdbdump\n 
";
}else{
	if($ARGV[0] =~ /\.v/){
		$design_file = $ARGV[0];
	}else{
		die("No specified design file\n");
	}

	if($command_argv =~ /\+\w*t\w*\s*=\s*(\d+\w?s\/\d+\w?s)/){
		$timescale = $1;
	}else{
		print("no timescale specified, use default timescale\n");
		$timescale = "1ns/1ns";
	}

	if($command_argv =~ /-(verdi|v)/){
		$verdi = 1;
	}else{
		$verdi = 0;
	}

	if($command_argv =~ /-p\s*(\d+)/){
		$p = $1/2;
	}else{
		$p = 10/2;
		print("no period specified, use default period\n");
	}
}

my $nosfx = $design_file =~ s/\.v//r;
my $tb_file = "tb_".$nosfx.".sv";
my $module_name;
my @port_list;
my @param_name_list;
my @param_value_list;
my $clk;
my $rst;

open DESIGN,'<',$design_file
	or die("Could not open file $design_file\n");

open TESTBENCH,'>',$tb_file
	or die("Could not open file $tb_file\n");

print TESTBENCH "`timescale $timescale\n";
while(<DESIGN>){
	chomp;
	if(/\Amodule\s*(\w+)\s*/){
		$module_name = $1;
		print TESTBENCH "module tb_$module_name;\n";
		print TESTBENCH "\n";
	}
	if(/(?<pat>parameter\s+(:?integer|\[.*\])?\s*(?<name>\w+)\s*=\s*(?<value>\d+))/ && !/;/){
		print TESTBENCH "$+{pat};\n";
		push(@param_name_list,$+{name});
		push(@param_value_list,$+{value});
	}
	if(/input\s*(?:wire)?\s*(?<port>(?:\[.*\])*\s*(?<name>\w+))\s*/){
		print TESTBENCH "bit $+{port};\n";
		push(@port_list,$+{name});
		my $name_temp = $+{name};
		if($+{name} =~ /clk/i){
			$clk = $name_temp;
		}elsif($+{name} =~ /(rst|reset)/i){
			$rst = $name_temp;
		}
	}
	if(/output\s*(?:wire|reg)?\s*(?<port>(?:\[.*\])*\s*(?<name>\w+))\s*/){
		print TESTBENCH "logic $+{port};\n";
		push(@port_list,$+{name});
	}
}

print TESTBENCH "\n";
print TESTBENCH "always #$p $clk = ~$clk;\n";

print TESTBENCH "
initial begin
\trepeat(4) @(posedge $clk);
\t$rst = 1;
//add your test case here
\n
\t\$finish();
end
";
if($verdi == 1){
	print TESTBENCH "
initial begin
\t\$fsdbDumpfile(\"$module_name.fsdb\");
\t\$fsdbDumpvars();
end
";
}

print TESTBENCH "\n";
print TESTBENCH "$module_name";
if(@param_name_list != 0){
	print TESTBENCH "#(\n";
	for(my $i = 0; $i < @param_name_list; $i++){
		if($i == $#param_name_list){
			print TESTBENCH "\t.$param_name_list[$i]($param_value_list[$i])\n\t)\n";
		}else{
			print TESTBENCH "\t.$param_name_list[$i]($param_value_list[$i]),\n";
		}
	}
}
print TESTBENCH "dut (\n";

if(@port_list != 0){
	for(my $i = 0; $i < @port_list; $i++){
		if($i == $#port_list){
			print TESTBENCH "\t.$port_list[$i]($port_list[$i])\n";
		}else{
			print TESTBENCH "\t.$port_list[$i]($port_list[$i]),\n";
		}
	}
	print TESTBENCH ");\n"
}

print TESTBENCH "endmodule";
close TESTBENCH;


