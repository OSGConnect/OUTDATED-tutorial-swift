type file;

# Application programs to be called by this script

global file simulation_prog  <"app/simulate.sh">;
global file analysis_prog    <"app/stats.sh">;
global file genrand_prog     <"app/genrand.sh">;

# app() functions for application programs:

app (file out) genrand (file pgm, int timesteps, int sim_range)
{
  local_sh @filename(pgm) timesteps sim_range stdout=@filename(out);
}

app (file out) simulation (file pgm, int timesteps, int sim_range, file bias_file, int scale, int sim_count)
{
  sh @filename(pgm) timesteps sim_range @filename(bias_file) scale sim_count stdout=@filename(out);
}

app (file out) analyze (file pgm, file s[])
{
  local_sh @filename(pgm) @filenames(s) stdout=@filename(out);
}

# Higher-level functions that call app() functions

(int scale) calcScale(int maxScale)
{
  scale = readData(genrand(simulation_prog, 1, maxScale));
}

(file biasFile) calcBias (int maxBias)
{
  biasFile = genrand(simulation_prog, 1, maxBias);
}

# Command line params to this script:

int  nsim  = @toInt(@arg("nsim",  "10"));  # number of simulation programs to run
int  range = @toInt(@arg("range", "100")); # range of the generated random numbers
int  count = @toInt(@arg("count", "10"));  # number of random numbers generated per simulation
int  steps = @toInt(@arg("steps", "3"));   # number of time steps per simulation

# Main script and data

tracef("\n*** Script parameters: nsim=%i range=%i count=%i\n\n", nsim, range, count);

file bias<"dynamic_bias.dat">;    # Dynamically generated bias for simulation ensemble
bias = calcBias(1000);

file sims[];                      # Array of files to hold each simulation output

foreach i in [0:nsim-1] {
  int scale;
  scale = 1000 * calcScale(100);
  tracef("  for simulation[%i] scale=%i\n", i, scale);
  file simout <single_file_mapper; file=@strcat("output/sim_",i,".out")>;
  simout = simulation(simulation_prog, steps+1, range, bias, scale, count);
  sims[i] = simout;
}

file stats<"output/stats.out">;            # Final output file: average of all "simulations"
stats = analyze(analysis_prog,sims);
