type file;

# Application to be called by this script

file simulation_script <"simulate.sh">;

# app() functions for application programs to be called:

app (file out) simulation (file script, int timesteps, int sim_range)
{
  sh @filename(script) timesteps sim_range stdout=@filename(out);
}

# Command line params to this script:

int  nsim  = @toInt(@arg("nsim",  "10"));  # number of simulation programs to run
int  range = @toInt(@arg("range", "100")); # range of the generated random numbers

# Main script and data

int steps=3;

tracef("\n*** Script parameters: nsim=%i steps=%i range=%i \n\n", nsim, steps, range);

foreach i in [0:nsim-1] {
  file simout <single_file_mapper; file=@strcat("output/sim_",i,".out")>;
  simout = simulation(simulation_script, steps, range);
}
