# condor_q -l $USER | grep MATCH_EXP_JOBGLIDEIN_ResourceName | cut -d '=' -f 2 | sort | uniq -c

condor_q -l $USER | grep LastRemoteHost | cut -d '=' -f 2 | sort | uniq -c
