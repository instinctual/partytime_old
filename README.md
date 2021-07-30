# partytime
Join in the render party.

Have machines join BackBurner Server Groups when no one is logged into the machine.  This will take advantage of idle hardware resources.

Upon GUI login to machine, PartyTime will remove machine from pre-defined BackBurner Server groups.  Upon logout,shutdown or reboot, the machine is added back to the groups.  

partytime.conf is used to define the BackBurner Manager and groups to party with.

You can test functionality via the command line.

``` partytime.sh --join/remove``` will use the groups defined in partytime.conf

You can manually specify groups by adding the --groups flag and a comma seperated list of BackBurner groups.
```
sh partyTime.sh --groups group01,group02 --join
```
