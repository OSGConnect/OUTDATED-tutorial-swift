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
                                     file bias_file, int scale, int sim_count,
                                     file seed_file)
{
  sh @prog "-t" timesteps "-r" sim_range "-B" @bias_file "-x" scale
           "-n" sim_count "-S" @seed_file stdout=@out stderr=@log;
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

file sims[];                      # Array of files to hold each simulation output

foreach i in [0:nsim-1] {
  file biasfile <single_file_mapper; file=@strcat("output/bias_",i,".dat")>;
  file simout   <single_file_mapper; file=@strcat("output/sim_",i,".out")>;
  file simlog   <single_file_mapper; file=@strcat("output/sim_",i,".log")>;
  biasfile = genbias(genbias_prog, 1000, 20);
  (simout,simlog) = simulation(simulation_prog, steps, range, biasfile, 100000, count, seedfile);
  sims[i] = simout;
}

file stats<"output/stats.out">;            # Final output file: average of all "simulations"
stats = analyze(analysis_prog,sims);
