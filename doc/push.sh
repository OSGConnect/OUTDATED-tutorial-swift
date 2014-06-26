#! /bin/sh

scp cic-tutorial.html *png login.ci.uchicago.edu:/ci/www/projects/swift/links

exit

www=/ci/www/projects/swift/ATPESC

cp --backup=numbered tutorial.html $www
cp --backup=numbered *.png $www
chmod g+w,a+r $www/tutorial.html $www/*png
ls -l $www
