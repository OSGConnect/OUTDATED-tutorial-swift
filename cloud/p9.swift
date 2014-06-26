type file;

# Applications to be called by this script

file simulation_script <"simulate.sh">;
file analysis_script   <"stats.sh">;

# app() functions for application programs to be called:

app (file out) genrand (file script, int timesteps, int sim_range)
{
  local_sh @filename(script) timesteps sim_range stdout=@filename(out);
}

app (file out) simulation (file script, int timesteps, int sim_range, file bias_file, int scale, int sim_count)
{
  sh @filename(script) timesteps sim_range @filename(bias_file) scale sim_count stdout=@filename(out);
}

app (file out) analyze (file script, file s[])
{
  local_sh @script @filenames(s) stdout=@filename(out);
}

# Command line params to this script:

int  nsim  = @toInt(@arg("nsim",  "10"));  # number of simulation programs to run
int  range = @toInt(@arg("range", "100")); # range of the generated random numbers
int  count = @toInt(@arg("count", "10"));  # number of random numbers generated per simulation

# Main script and data

tracef("\n*** Script parameters: nsim=%i range=%i count=%i\n\n", nsim, range, count);

file bias<"dynamic_bias.dat">;        # Dynamically generated bias for simulation ensemble

bias = genrand(simulation_script, 1, 1000);

file sims[];                               # Array of files to hold each simulation output

foreach i in [0:nsim-1] {

  int steps = readData(genrand(simulation_script, 1, 5));
  tracef("  for simulation[%i] steps=%i\n", i, steps+1);

  file simout <single_file_mapper; file=@strcat("output/sim_",i,".out")>;
  simout = simulation(simulation_script, steps+1, range, bias, 100000, count);
  sims[i] = simout;
}

file stats<"output/stats.out">;            # Final output file: average of all "simulations"
stats = analyze(analysis_script,sims);
