
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

