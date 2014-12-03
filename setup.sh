
# ensure that this script is being sourced

if [ ${BASH_VERSINFO[0]} -gt 2 -a "${BASH_SOURCE[0]}" = "${0}" ] ; then
  echo ERROR: script ${BASH_SOURCE[0]} must be executed as: source ${BASH_SOURCE[0]}
  exit 1
fi

# Add swift to PATH

TUTSWIFT=/usr/local/swift/stable
PATHSWIFT=$(which swift 2>/dev/null)

if [ _$PATHSWIFT = _$TUTSWIFT/bin/swift ]; then
  echo using Swift from $TUTSWIFT,already in PATH
elif [ -x $TUTSWIFT/bin/swift ]; then
  echo Using Swift from $TUTSWIFT, and adding to PATH
  PATH=$TUTSWIFT/bin:$PATH
elif [ _$PATHSWIFT != _ ]; then
  echo Using $PATHSWIFT from PATH
else
  echo ERROR: $TUTSWIFT not found and no swift in PATH. Tutorial will not function.
  return
fi

echo Swift version is $(swift -version)
rm -f swift.log

# Setting scripts folder to the PATH env var.

TUTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ _$(which cleanup 2>/dev/null) != _$TUTDIR/bin/cleanup ]; then
  echo Adding $TUTDIR/bin:$TUTDIR/app: to front of PATH
  PATH=$TUTDIR/bin:$TUTDIR/app:$PATH
else
  echo Assuming $TUTDIR/bin:$TUTDIR/app: is already at front of PATH
fi

# Setting .swift files

if [ -e $HOME/.swift/swift.properties ]; then
  saveprop=$(mktemp $HOME/.swift/swift.properties.XXXX)
  echo Saving $HOME/.swift/swift.properties in $saveprop
  mv $HOME/.swift/swift.properties $saveprop
else
  mkdir -p $HOME/.swift
fi

cat >>$HOME/.swift/swift.properties <<END

# Properties for Swift Tutorial

sites.file=sites.xml
tc.file=apps

wrapperlog.always.transfer=true
sitedir.keep=true
file.gc.enabled=false
status.mode=provider

execution.retries=0
lazy.errors=false

use.wrapper.staging=false
use.provider.staging=true
provider.staging.pin.swiftfiles=false

END

if [ $(hostname) = login01.osgconnect.net ]; then
  CONTACTHOST=192.170.227.195
else
  printf "\n\nERROR: Hostname $(hostname) is unknown: modiy setup.sh accordingly.\n\n"
  return
fi 

cat >sites.condor <<END

<config>
  <pool handle="osg">
    <execution provider="coaster" jobmanager="local:condor"/>
    <profile namespace="karajan" key="jobThrottle">5.00</profile>
    <profile namespace="karajan" key="initialScore">10000</profile>
    <profile namespace="globus"  key="jobsPerNode">1</profile>
    <profile namespace="globus"  key="maxtime">3600</profile>
    <profile namespace="globus"  key="maxWalltime">00:01:00</profile>
    <profile namespace="globus"  key="highOverAllocation">10000</profile>
    <profile namespace="globus"  key="lowOverAllocation">10000</profile>
    <profile namespace="globus"  key="internalHostname">$CONTACTHOST</profile>
    <profile namespace="globus"  key="slots">20</profile> 
    <profile namespace="globus"  key="maxNodes">1</profile>
    <profile namespace="globus"  key="nodeGranularity">1</profile>
    <workdirectory>.</workdirectory>  <!-- Alt: /tmp/swift/OSG/{env.USER} -->
    <!-- For UC3: -->
    <profile namespace="globus"  key="condor.+AccountingGroup">"group_friends.{env.USER}"</profile>
    <profile namespace="globus"  key="jobType">nonshared</profile>

  </pool>
</config>
END

for p in 04 05 06; do
  cp sites.condor part${p}/sites.xml
done

return

# Integrate somewhere:

cat <<END
    <!-- OSG Connect Resource selector expressions:  -->
    <!-- UC3S regexp("uc3-c*", Machine)              -->
    <!-- UCIT regexp("appcloud[0-1][0-9].*", Machine)-->
    <!-- MWUC regexp("uct2-c*", Machine)             -->
    <!-- MWIU regexp("iut2-c*", Machine)             -->
    <!-- MWUI regexp("taub*", Machine)               -->
    <!-- MWT2 UidDomain == "osg-gk.mwt2.org"         -->
    <!-- OSG  isUndefined(GLIDECLIENT_Name) == FALSE -->
    <!-- MULT UidDomain == "osg-gk.mwt2.org" && (regexp("iut2-c*", Machine) || regexp("uct2-c*", Machine)) -->
    <!-- E.g. for UC3 cycle seeder: -->
    <!-- <profile namespace="globus" key="condor.Requirements">regexp("uc3-c*", Machine)</profile> -->
END
