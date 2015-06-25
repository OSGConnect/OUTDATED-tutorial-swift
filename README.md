[title]: - "SWIFT" 

## Introduction

This is a quick introduction to using SWIFT on OSG Connect. [SWIFT](http://swift-lang.org/main/index.php) is a parallel scripting language that lets you easily incorporate workflows using different applications and convert them into a simple script file.  The SWIFT runtime takes this script and tries to run as much of the workflow in parallel as possible. Once you finish using the exercises on this page you will be able to create workflows in SWIFT.

## Conventions

The following conventions are used throughout this document: 
  * All of the following exercises must be done using the BASH shell
  * The `setup.sh` in the tutorial directory is sourced before running any of the tutorial:
  
	$ source setup.sh

  * Each part of the exercises below is located in a separate directory (e.g. part01, part02, ...)
  * To cleanup the directory and remove all outputs, after running SWIFT, run in the exercise directory:
 
	$ ../bin/cleanup

## Introductory Exercises

### Scripts

The introductory exercises use two different mock "science applications" that act as simple stand-ins for real since applications.

##### simulate.sh

The `simulation.sh` script is a simple substitute for a scientific simulation application. It generates and prints a set of one or more random integers in the range 0-29,999 as controlled by its optional arguments.

	$ ./app/simulate.sh --help 
	./app/simulate.sh: 
	usage: 
		-b|--bias offset bias: add this integer to all results [0] 
		-B|--biasfile file of integer biases to add to results [none] 
		-l|--log generate a log in stderr if not null [y] 
		-n|--nvalues print this many values per simulation [1] 
		-r|--range range (limit) of generated results [100] 
		-s|--seed use this integer [0..32767] as a seed [none] 
		-S|--seedfile use this file (containing integer seeds [0..32767]) one per line [none] 
		-t|--timesteps number of simulated "timesteps" in seconds (determines runtime) [1] 
		-x|--scale scale the results by this integer [1] 
		-h|-?|?|--help print this help
	

A table of the arguments:

Argument       |      Description
---            |      ---
-b,--bias      |  offset bias: add this integer to all results [0]
-B,--biasfile  |  file of integer biases to add to results [none]
-l,--log       |  generate a log in stderr if not null [y]
-n,--nvalues   |  print this many values per simulation [1]
-r,--range     |  range (limit) of generated results [100]
-s,--seed      |  use this integer [0..32767] as a seed [none]
-S,--seedfile  |  use this file (containing integer seeds [0..32767]) one per line [none]
-t,--timesteps |  number of simulated "timesteps" in seconds (determines runtime) [1]
-x,--scale     |  scale the results by this integer [1]
-h,-?,?,--help |  print this help

With no arguments, `simulate.sh` prints 1 number in the range of 1-100. Otherwise it generates n numbers of the form R * scale + bias where R is a random integer. By default it logs information about its execution environment to stderr. Here are some examples of its usage:

	$ simulate.sh 2>log
	       5
	$ head -4 log
	 
	Called as: /home/wilde/swift/tut/CIC_2013-08-09/app/simulate.sh:
	Start time: Thu Aug 22 12:40:24 CDT 2013
	Running on node: login01.osgconnect.net
	 
	$ simulate.sh -n 4 -r 1000000 2>log
	  239454
	  386702
	   13849
	  873526
	 
	$ simulate.sh -n 3 -r 1000000 -x 100 2>log
	 6643700
	62182300
	 5230600
	 
	$ simulate.sh -n 2 -r 1000 -x 1000 2>log
	  565000
	  636000
	 
	$ time simulate.sh -n 2 -r 1000 -x 1000 -t 3 2>log
	  336000
	  320000
	real    0m3.012s
	user    0m0.005s
	sys     0m0.006s


##### stats.sh 

The `stats.sh` script serves as a trivial model of an "analysis" program. It reads N files each containing M integers and simply prints the average of all those numbers to stdout. Similarly to `simulate.sh`, it logs environmental information to the stderr. Here's an example of running the `stats.sh` script:

	$ ls f*
	f1  f2  f3  f4
	 
	$ cat f*
	25
	60
	40
	75
	 
	$ stats.sh f*
	50

## Part 1 - Run an application under Swift

The first swift script, `p1.swift`, runs `simulate.sh` to generate a single random number. It writes the number to a file. 

In the `p1.swift` file below, the [app](http://swift-lang.org/guides/release-0.94/userguide/userguide.html#_mapping_of_app_semantics_into_unix_process_execution_semantics) construct is used to tell SWIFT how to use the `simulate.sh` script and what the script expects for its inputs and outputs. The simulate application gets translated to `simulate.sh` using the apps file for the mapping. The [file](http://swift-lang.org/guides/release-0.94/userguide/userguide.html#_the_single_file_mapper) construct indicates the name of the file used to hold the output from the simulate script. The source for the `p1.swift` file follows:

	type file;
	app (file o) mysim ()
	{
	  simulate stdout=@filename(o);
	}
	file f <"sim.out">;
	f = mysim();

To run this script:

	$ cd part01
	$ swift p1.swift

Now, view the output:

	$ cat sim.out
	 95

## Part 2 - Running an ensemble of many apps in parallel with "foreach" loops

The `p2.swift` script introduces the [foreach](http://swift-lang.org/guides/release-0.94/userguide/userguide.html#_arrays_and_parallel_execution) loop to run multiple instances of the simulate script in parallel. Output files are named using the file mapper so each instance writes to output/sim_N.out. The source for the p2.swift script follows:

	type file;
	app (file o) mysim ()
	{
	  simulate stdout=@filename(o);
	}
	foreach i in [0:9] {
	  file f <single_file_mapper; file=@strcat("output/sim_",i,".out")>;
	  f = mysim();
	}
To run the script:
	$ cd part02
	$ swift p2.swift
Output files will be named output/sim_N.out:
	$ ls output/
	sim_0.out  sim_2.out  sim_4.out  sim_6.out  sim_8.out
	sim_1.out  sim_3.out  sim_5.out  sim_7.out  sim_9.out
 
## Part 3 - merging/reducing the results of a parallel foreach loop

The `p3.swift` script introduces a postprocessing step. After all the parallel simulations have completed, the files created by `simulation.sh` will be averaged by `stats.sh`.  The [@filenames](http://swift-lang.org/guides/release-0.94/userguide/userguide.html#_filenames) functions is used to store filenames being transfer outputs from the simulate scripts to the stats script. The source for the `p3.swift` script follows:

	type file;
	app (file o) mysim (int sim_steps, int sim_values)
	{
	  simulate "--timesteps" sim_steps "--nvalues" sim_values stdout=@filename(o);
	}
	app (file o) analyze (file s[])
	{
	  stats @filenames(s) stdout=@filename(o);
	}
	int nsim   = @toInt(@arg("nsim","10"));
	int steps  = @toInt(@arg("steps","1"));
	int values = @toInt(@arg("values","5"));
	file sims[];
	foreach i in [0:nsim-1] {
	  file simout <single_file_mapper; file=@strcat("output/sim_",i,".out")>;
	  simout = mysim(steps,values);
	  sims[i] = simout;
	}
	file stats<"output/average.out">;
	stats = analyze(sims);

To run:

	$ cd part02
	$ swift p3.swift

The output will be named `output/average.out`:

	$ cat output/average.out
	51

## Part 4 - Running a parallel ensemble on OSG Connect resources

This is the first script that will submit jobs to OSG through OSG connect. It is similar to earlier scripts, with a few minor exceptions. To generalize the script for other types of remote execution (e.g., when no shared filesystem is available to the compute nodes), the application `simulate.sh` will get transferred to the worker node by Swift, in the same manner as any other input data file. The source for the `p4.swift` script follows:

	type file;
	 
	# Application program to be called by this script:
	file simulation_prog <"app/simulate.sh">;
	 
	# "app" function for the simulation application:
	app (file out, file log) simulation (file prog, int timesteps, int sim_range)
	{
	   sh @prog "-t" timesteps "-r" sim_range stdout=@out stderr=@log;
	}
	 
	# Command line parameters to this script:
	int nsim = @toInt(@arg("nsim", "10")); # number of simulation programs to run
	int range = @toInt(@arg("range", "100")); # range of the generated random numbers
	
	# Main script and data
	int steps=3;
	
	tracef("\n*** Script parameters: nsim=%i steps=%i range=%i \n\n", nsim, steps, range);
	
	foreach i in [0:nsim-1] {
	   file simout <single_file_mapper; file=@strcat("output/sim_",i,".out")>;
	   file simlog <single_file_mapper; file=@strcat("output/sim_",i,".log")>;
	   (simout,simlog) = simulation(simulation_prog, steps, range);
	}

To run:

	$ cd part04
	$ swift p4.swift

The output will be named `output/sim_N.out`:

	$ cat output/average.out
	51
	
SWIFT uses parameters in the `sites.xml` file to determine parameters to use when submitting jobs to HTCondor.  The key value to note is the pool element which sets the name for the pool that SWIFT submits to. Additionally, the `+ProjectName` value needs to be set to the project that you're submitting as.The source for the `sites.xml` file follows:

	<config>
	  <pool handle="osg">
	    <execution provider="coaster" jobmanager="local:condor"/>
	    <profile namespace="karajan" key="jobThrottle">5.00</profile>
	    <profile namespace="karajan" key="initialScore">10000</profile>
	    <profile namespace="globus" key="jobsPerNode">1</profile>
	    <profile namespace="globus" key="maxtime">3600</profile>
	    <profile namespace="globus" key="maxWalltime">00:01:00</profile>
	    <profile namespace="globus" key="highOverAllocation">10000</profile>
	    <profile namespace="globus" key="lowOverAllocation">10000</profile>
	    <profile namespace="globus" key="internalHostname">128.135.158.173</profile>
	    <profile namespace="globus" key="slots">20</profile>
	    <profile namespace="globus" key="maxNodes">1</profile>
	    <profile namespace="globus" key="nodeGranularity">1</profile>
	    <workdirectory>.</workdirectory> <!-- Alt: /tmp/swift/OSG/{env.USER} -->
	    <!-- For UC3: -->
	    <profile namespace="globus" key="condor.+AccountingGroup">"group_friends.{env.USER}"</profile>
	    <!-- For OSGConnect -->
	    <profile namespace="globus" key="condor.+ProjectName">"con-train"</profile>
	    <profile namespace="globus" key="jobType">nonshared</profile>
	  </pool>
	</config>

The other file that SWIFT uses is the apps file.  This file lays out the mappings between applications used in the SWIFT script files and the actual binaries for each pool.  E.g.:

	osg sh /bin/bash
 
## Part 5 - Linking applications together on OSG-Connect

The `p5.swift` introduces a postprocessing step. After all the parallel simulations have completed, the files created by `simulation.sh` will be averaged by `stats.sh`. This is similar to p3, but all app invocations are done on remote nodes with Swift managing file transfers.  The source for `p5.swift` follows:
	
	type file;
	# Define external application programs to be invoked
	file simulation_prog <"app/simulate.sh">;
	file analysis_prog   <"app/stats.sh">;
	app (file out, file log) simulation
	    (file prog, int timesteps, int sim_range,
	     file bias_file, int scale, int sim_count)
	{
	  sh @prog "-t" timesteps "-r" sim_range "-B" @bias_file
	           "-x" scale "-n" sim_count
	           stdout=@out stderr=@log;
	}
	app (file out) analyze (file prog, file s[])
	{
	  sh @filename(prog) @filenames(s) stdout=@filename(out);
	}
	# Command line params to this script
	int  nsim  = @toInt(@arg("nsim",  "10"));  # number of simulation programs to run
	int  steps = @toInt(@arg("steps", "1"));   # number of "steps" each simulation (==seconds of runtime)
	int  range = @toInt(@arg("range", "100")); # range of the generated random numbers
	int  count = @toInt(@arg("count", "10"));  # number of random numbers generated per simulation
	# Perform nsim "simulations"
	tracef("\n*** Script parameters: nsim=%i steps=%i range=%i count=%i\n\n", nsim, steps, range, count);
	file sims[];                               # Array of files to hold each simulation output
	file bias<"bias.dat">;                     # Input data file to "bias" the numbers:
	                                           # 1 line: scale offset ( N = n*scale + offset)
	foreach i in [0:nsim-1] {
	  file simout <single_file_mapper; file=@strcat("output/sim_",i,".out")>;
	  file simlog <single_file_mapper; file=@strcat("output/sim_",i,".log")>;
	  (simout, simlog) = simulation(simulation_prog, steps, range, bias, 100000, count);
	  sims[i] = simout;
	}
	# Generate "analysis" file containing average of all "simulations"
	file stats<"output/stats.out">;
	stats = analyze(analysis_prog,sims);
 
To run:

	$ cd part05
	$ swift p5.swift

The output will be named output/stats.out:

	$ cat output/stats.out
	5143382

## Part 6 - Specifying more complex workflow patterns

The `p6.swift` script builds on p5.swift, but adds new apps for generating a random seed and a random bias value.  The script's source is shown below:

	type file;
	# Define external application programs to be invoked
	file simulation_prog <"app/simulate.sh">;
	file analysis_prog   <"app/stats.sh">;
	file genbias_prog = simulation_prog;
	file genseed_prog = simulation_prog;
	# app() functions for application programs to be called:
	app (file out) genseed (file prog, int nseeds)
	{
	  sh @prog "-r" 2000000 "-n" nseeds stdout=@out;
	}
	app (file out) genbias (file prog, int bias_range, int nvalues)
	{
	  sh @prog "-r" bias_range "-n" nvalues stdout=@out;
	}
	app (file out, file log) simulation (file prog, int timesteps, int sim_range,
	                                     file bias_file, int scale, int sim_count)
	{
	  sh @prog "-t" timesteps "-r" sim_range "-B" @bias_file "-x" scale
	           "-n" sim_count stdout=@out stderr=@log;
	}
	app (file out) analyze (file prog, file s[])
	{
	  sh @prog @filenames(s) stdout=@out;
	}
	# Command line arguments
	int  nsim  = @toInt(@arg("nsim",  "10"));  # number of simulation programs to run
	int  range = @toInt(@arg("range", "100")); # range of the generated random numbers
	int  count = @toInt(@arg("count", "10"));  # number of values generated per simulation
	int  steps = @toInt(@arg("steps", "1"));   # number of timesteps (seconds) per simulation
	# Main script and data
	tracef("\n*** Script parameters: nsim=%i range=%i count=%i\n\n", nsim, range, count);
	file seedfile<"output/seed.dat">;        # Dynamically generated bias for simulation ensemble
	seedfile = genseed(genseed_prog, 1);
	int seedval = readData(seedfile);
	tracef("Generated seed=%i\n", seedval);
	file sims[];                      # Array of files to hold each simulation output
	foreach i in [0:nsim-1] {
	  file biasfile <single_file_mapper; file=@strcat("output/bias_",i,".dat")>;
	  file simout   <single_file_mapper; file=@strcat("output/sim_",i,".out")>;
	  file simlog   <single_file_mapper; file=@strcat("output/sim_",i,".log")>;
	  biasfile = genbias(genbias_prog, 1000, 20);
	  (simout,simlog) = simulation(simulation_prog, steps, range, biasfile, 100000, count);
	  sims[i] = simout;
	}
	file stats<"output/stats.out">;            # Final output file: average of all "simulations"
	stats = analyze(analysis_prog,sims);

To run:

	$ cd part06
	$ swift p6.swift

The output will be named output/stats.out:

	$ cat output/stats.out
	4407482
 
## Further information and references

* [Latest version of this tutorial](http://swift-lang.org/links/cic-tutorial.html)
* [SWIFT user guide](http://swift-lang.org/guides/release-0.94/userguide/userguide.html)
* [SWIFT documentation](http://swift-lang.org/docs/index.php)

## Getting Help
For assistance or questions, please email the OSG User Support team  at [user-support@opensciencegrid.org](mailto:user-support@opensciencegrid.org)
 or visit the [help desk and community forums](http://support.opensciencegrid.org).
