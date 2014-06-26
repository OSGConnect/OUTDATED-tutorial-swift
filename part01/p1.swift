type file;

app (file o) mysim ()
{
  simulate stdout=@filename(o);
}

file f <"sim.out">;
f = mysim();
