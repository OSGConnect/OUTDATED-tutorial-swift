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
