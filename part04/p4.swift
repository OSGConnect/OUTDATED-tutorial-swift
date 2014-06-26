
type file;

# Application program to be called by this script:

file simulation_prog <"app/simulate.sh">;

# "app" function for the simulation application:

app (file out, file log) simulation (file prog, int timesteps, int sim_range)
{
  sh @prog "-t" timesteps "-r" sim_range stdout=@out stderr=@log;
}

# Command line parameters to this script:

int  nsim  = @toInt(@arg("nsim",  "10"));  # number of simulation programs to run
int  range = @toInt(@arg("range", "100")); # range of the generated random numbers

# Main script and data

int steps=3;

tracef("\n*** Script parameters: nsim=%i steps=%i range=%i \n\n", nsim, steps, range);

foreach i in [0:nsim-1] {
  file simout <single_file_mapper; file=@strcat("output/sim_",i,".out")>;
  file simlog <single_file_mapper; file=@strcat("output/sim_",i,".log")>;
  (simout,simlog) = simulation(simulation_prog, steps, range);
}

