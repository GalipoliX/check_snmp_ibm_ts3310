
#!/bin/bash
#################################################################################
# Script:       check_ibm_ts3310_snmp
# Author:       Michael Geschwinder (Maerkischer-Kreis)
# Description:  Plugin for Nagios to check an IBM TS3310 Tape library
#               device with SNMP (v1).
# History:
# 20140423      Created plugin (types: power, cooling, connectivity, robotics, media, drive, operatoraction, librarystate, maindoor, iedoor, robot, cleaning, logicallibrary)
#################################################################################
# Usage:        ./check_ibm_ts3310_snmp.sh -H host [-C community] -t type [-w warning] [-c critical]
#################################################################################

help="check_ibm_ts3310_snmp (c) 2014 Michael Geschwinder published under GPL license
\nUsage: ./check_ibm_ts3310_snmp.sh -H host [-C community] -t type [-w warning] [-c critical]
\nRequirements: snmpget, awk, sed\n
\nOptions: \t-H hostname\n\t\t-c Community (to be defined in snmp settings on device, default public)\n\t\t-t Type to check, see list below
\t\t-w Warning Threshold (optional)\n\t\t-c Critical Threshold (optional)\n
\nTypes:\t\tglobalstatus -> Indicates overall Status
\t\tpower -> Indicates overall power supply status
\t\tcooling -> Indicates overall cooling fans Status
\t\tconnectivity -> Indicates overall connectivity Status
\t\trobotics -> Indicates overall robotics Status
\t\tmedia -> Indicates overall media Status
\t\tdrive -> Indicates overall drive Status
\t\toperatoraction -> if operator Action is required.
\t\tlibrarystate ->  Physical library's overall online status
\t\tmaindoor -> The status is 'open' if any door is open
\t\tiedoor -> The status is 'open' if any door is open
\t\trobot -> Robot readynes state
\t\tcleaning -> Cleaning status of the Drive.
\t\tunused -> unused"

##########################################################
# Nagios exit codes and PATH
##########################################################
STATE_OK=0              # define the exit code if status is OK
STATE_WARNING=1         # define the exit code if status is Warning
STATE_CRITICAL=2        # define the exit code if status is Critical
STATE_UNKNOWN=3         # define the exit code if status is Unknown
PATH=$PATH:/usr/local/bin:/usr/bin:/bin # Set path


##########################################################
# Debug Ausgabe aktivieren
##########################################################
DEBUG=0

##########################################################
# Debug output function
##########################################################
function debug_out {
        if [ $DEBUG -eq "1" ]
        then
                datestring=$(date +%d%m%Y-%H:%M:%S)
                echo -e $datestring DEBUG: $1
        fi
}

###########################################################
# Check if programm exist $1
###########################################################
function check_prog {
        if ! `which $1 1>/dev/null`
        then
                echo "UNKNOWN: $1 does not exist, please check if command exists and PATH is correct"
                exit ${STATE_UNKNOWN}
        else
                debug_out "OK: $1 does exist"
        fi
}

############################################################
# Check Script parameters and set dummy values if required
############################################################
function check_param {
        if [ ! $host ]
        then
                echo "No Host specified... exiting..."
                exit $STATE_UNKNOWN
        fi

        if [ ! $community ]
        then
                debug_out "Setting default community (public)"
                community="public"
        fi
        if [ ! $type ]
        then
                echo "No check type specified... exiting..."
                exit $STATE_UNKNOWN
        fi
        if [ ! $warning ]
        then
                debug_out "Setting dummy warn value "
                warning=999
        fi
        if [ ! $critical ]
        then
                debug_out "Setting dummy critical value "
                critical=999
        fi
}



############################################################
# Get SNMP Value
############################################################
function get_snmp {
        oid=$1
        snmpret=$(snmpget -v1 -c $community $host $oid) # | awk '{print $4}'
        if [ $? == 1 ]
        then
                exit $STATE_UNKNOWN
        else
                echo $snmpret | awk '{print $4}'
        fi
}

#################################################################################
# Display Help screen
#################################################################################
if [ "${1}" = "--help" -o "${#}" = "0" ];
       then
       echo -e "${help}";
       exit $STATE_UNKNOWN;
fi

################################################################################
# check if requiered programs are installed
################################################################################
for cmd in snmpget awk sed;do check_prog ${cmd};done;

################################################################################
# Get user-given variables
################################################################################
while getopts "H:C:t:w:c:o:" Input;
do
       case ${Input} in
       H)      host=${OPTARG};;
       C)      community=${OPTARG};;
       t)      type=${OPTARG};;
       w)      warning=${OPTARG};;
       c)      critical=${OPTARG};;
       o)      moid=${OPTARG};;
       *)      echo "Wrong option given. Please use options -H for host, -c for SNMP-Community, -t for type, -w for warning and -c for critical"
               exit 1
               ;;
       esac
done

debug_out "Host=$host, Community=$community, Type=$type, Warning=$warning, Critical=$critical"

check_param

S_Status[1]="good"
S_Status[2]="failed"
S_Status[3]="degraded"
S_Status[4]="warning"
S_Status[5]="informational"
S_Status[6]="unknown"
S_Status[7]="invalid"

#################################################################################
# Switch Case for different check types
#################################################################################
case ${type} in
globalstatus)
        set -e
        value=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.1.8.0)
        set +e
        perf="$type=$value;"
        case ${value} in
                1)
                        echo "OK: $type: ${S_Status[$value]} |$perf"
                        exit $STATE_OK
                ;;
                2|3)
                        echo "CRITICAL: $type ${S_Status[$value]} |$perf"
                        exit $STATE_CRITICAL
                ;;
                4|5|6|7)
                        echo "WARNING: $type ${S_Status[$value]} |$perf"
                        exit $STATE_WARNING
                ;;
                *)
                        echo "UNKNOWN: $type $value"
                        exit $STATE_UNKNOWN
                ;;
        esac
;;
power)
        set -e
        value=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.12.1.0)
        set +e
        perf="$type=$value;"
        case ${value} in
                1)
                        echo "OK: $type: ${S_Status[$value]} |$perf"
                        exit $STATE_OK
                ;;
                2|3)
                        echo "CRITICAL: $type ${S_Status[$value]} |$perf"
                        exit $STATE_CRITICAL
                ;;
                4|5|6|7)
                        echo "WARNING: $type ${S_Status[$value]} |$perf"
                        exit $STATE_WARNING
                ;;
                *)
                        echo "UNKNOWN: $type $value"
                        exit $STATE_UNKNOWN
                ;;
        esac
;;
cooling)
        set -e
        value=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.12.2.0)
        set +e
        perf="$type=$value;"
        case ${value} in
                1)
                        echo "OK: $type: ${S_Status[$value]} |$perf"
                        exit $STATE_OK
                ;;
                2|3)
                        echo "CRITICAL: $type ${S_Status[$value]} |$perf"
                        exit $STATE_CRITICAL
                ;;
                4|5|6|7)
                        echo "WARNING: $type ${S_Status[$value]} |$perf"
                        exit $STATE_WARNING
                ;;
                *)
                        echo "UNKNOWN: $type $value"
                        exit $STATE_UNKNOWN
                ;;
        esac
;;
connectivity)
        set -e
        value=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.12.4.0)
        set +e
        perf="$type=$value;"
        case ${value} in
                1)
                        echo "OK: $type: ${S_Status[$value]} |$perf"
                        exit $STATE_OK
                ;;
                2|3)
                        echo "CRITICAL: $type ${S_Status[$value]} |$perf"
                        exit $STATE_CRITICAL
                ;;
                4|5|6|7)
                        echo "WARNING: $type ${S_Status[$value]} |$perf"
                        exit $STATE_WARNING
                ;;
                *)
                        echo "UNKNOWN: $type $value"
                        exit $STATE_UNKNOWN
                ;;
        esac
;;
robotics)
        set -e
        value=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.12.5.0)
        set +e
        perf="$type=$value;"
        case ${value} in
                1)
                        echo "OK: $type: ${S_Status[$value]} |$perf"
                        exit $STATE_OK
                ;;
                2|3)
                        echo "CRITICAL: $type ${S_Status[$value]} |$perf"
                        exit $STATE_CRITICAL
                ;;
                4|5|6|7)
                        echo "WARNING: $type ${S_Status[$value]} |$perf"
                        exit $STATE_WARNING
                ;;
                *)
                        echo "UNKNOWN: $type $value"
                        exit $STATE_UNKNOWN
                ;;
        esac
;;
media)
        set -e
        value=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.12.6.0)
        set +e
        perf="$type=$value;"
        case ${value} in
                1)
                        echo "OK: $type: ${S_Status[$value]} |$perf"
                        exit $STATE_OK
                ;;
                2|3)
                        echo "CRITICAL: $type ${S_Status[$value]} |$perf"
                        exit $STATE_CRITICAL
                ;;
                4|5|6|7)
                        echo "WARNING: $type ${S_Status[$value]} |$perf"
                        exit $STATE_WARNING
                ;;
                *)
                        echo "UNKNOWN: $type $value"
                        exit $STATE_UNKNOWN
                ;;
        esac
;;
drive)
        set -e
        value=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.12.7.0)
        set +e
        perf="$type=$value;"
        case ${value} in
                1)
                        echo "OK: $type: ${S_Status[$value]} |$perf"
                        exit $STATE_OK
                ;;
                2|3)
                        echo "CRITICAL: $type ${S_Status[$value]} |$perf"
                        exit $STATE_CRITICAL
                ;;
                4|5|6|7)
                        echo "WARNING: $type ${S_Status[$value]} |$perf"
                        exit $STATE_WARNING
                ;;
                *)
                        echo "UNKNOWN: $type $value"
                        exit $STATE_UNKNOWN
                ;;
        esac
;;
operatoraction)
        set -e
        value=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.12.8.0)
        set +e
        perf="$type=$value;"
        case ${value} in
                1)
                        echo "CRITICAL: Operator Action is required! |$perf"
                        exit $STATE_CRITICAL
                ;;
                2)
                        echo "OK: No Operator Action is required. |$perf"
                        exit $STATE_OK
                ;;
                *)
                        echo "UNKNOWN: $type $value"
                        exit $STATE_UNKNOWN
                ;;
        esac
;;
librarystate)
        set -e
        value=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.14.1.0)
        set +e
        perf="$type=$value;"
        case ${value} in
                1)
                        echo "OK: Library online |$perf"
                        exit $STATE_OK
                ;;
                2)
                        echo "WARNING: Library onlinePending! |$perf"
                        exit $STATE_WARNING
                ;;
                3)
                        echo "CRITICAL: Library offline! |$perf"
                        exit $STATE_CRITICAL
                ;;
                4)
                        echo "CRITICAL: Library offlinePending! |$perf"
                        exit $STATE_CRITICAL
                ;;
                5)
                        echo "CRITICAL: Library shutdownPending! |$perf"
                        exit $STATE_CRITICAL
                ;;
                *)
                        echo "UNKNOWN: $type $value"
                        exit $STATE_UNKNOWN
                ;;
        esac
;;
maindoor)
        set -e
        value=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.14.2.0)
        set +e
        perf="$type=$value;"
        case ${value} in
                1)
                        echo "WARNING: MainDoor is open! |$perf"
                        exit $STATE_WARNING
                ;;
                2)
                        echo "OK: MainDoor is closed |$perf"
                        exit $STATE_OK
                ;;
                3)
                        echo "UNKNOWN: MainDoor Unknown! |$perf"
                        exit $STATE_UNKNOWN
                ;;
                *)
                        echo "UNKNOWN: $type $value"
                        exit $STATE_UNKNOWN
                ;;
        esac
;;
iedoor)
        set -e
        value=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.14.3.0)
        set +e
        perf="$type=$value;"
        case ${value} in
                1)
                        echo "CRITICAL: IEDoor is open! |$perf"
                        exit $STATE_CRITICAL
                ;;
                2)
                        echo "OK: IEDoor is closed and locked |$perf"
                        exit $STATE_OK
                ;;
                3)
                        echo "WARN: IEDoor not locked! |$perf"
                        exit $STATE_WARNING
                ;;
                *)
                        echo "UNKNOWN: $type $value"
                        exit $STATE_UNKNOWN
                ;;
        esac
;;
robot)
        set -e
        value=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.14.30.2.0)
        set +e
        case ${value} in
                1)
                        echo "OK: Robot ready |$perf"
                        exit $STATE_OK
                ;;
                2)
                        echo "Critical: Robot not ready! |$perf"
                        exit $STATE_CRITICAL
                ;;
                *)
                        echo "UNKNOWN: $type $value"
                        exit $STATE_UNKNOWN
                ;;
        esac
;;
cleaning)
        set -e
        numdrives=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.14.6.0)
        set +e
        base=".1.3.6.1.4.1.3764.1.10.10.11.3.1.12"
        warn=0
        crit=0
        text=""
        perf=""
        for ((i=1;i<=$numdrives;i++));
        do
                set -e
                value=$(get_snmp $base.$i)
                location=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.11.3.1.6.$i)
                serial=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.11.3.1.2.$i)
                set +e
                perf="$perf cleaning_Drive_$i=$value;"
                case ${value} in
                        1)
                                text="$text \nDrive $i (location: $location, serial:$serial) needs cleaning!"
                                warn=1
                        ;;
                        2)
                                text="$text \nDrive $i (location: $location, serial:$serial) needs no cleaning"
                        ;;
                        3)
                                text="$text \nDrive $i (location: $location, serial:$serial) needs cleaning immediately"
                                crit=1
                        ;;
                        *)
                                echo "UNKNOWN: $type $value"
                                exit $STATE_UNKNOWN
                        ;;
                esac


        done
        if [ $crit == 1 ]
        then
                echo -e "CRITICAL: one or more drive needs cleaning immediately! $text |$perf"
                exit $STATE_CRITICAL
        elif [ $warn == 1 ]
        then
                echo -e "WARNING: one or more drive needs cleaning! $text |$perf"
                exit $STATE_WARNING
        else
                echo -e "OK: no drive needs cleaning $text |$perf"
                exit $STATE_OK
        fi
;;
logicallibrary)
        set -e
        numlog=$(get_snmp .1.3.6.1.4.1.3764.1.10.10.13.1.0)
        set +e
        base=".1.3.6.1.4.1.3764.1.10.10.13.2.1"
        warn=0
       4crit=0
        text=""
        perf=""
        for ((i=1;i<=$numlog;i++));
        do
                set -e
                value=$(get_snmp $base.8.$i)
                name=$(get_snmp $base.2.$i)
                set +e
                perf="$perf logical_library_$i=$value;"
                case ${value} in
                        1)
                                text="$text \n Logical Library$i (name:$name) is online"
                        ;;
                        2)
                                text="$text \n Logical Library$i (name:$name) is onlinePending!"
                                warn=1
                        ;;
                        3)
                                text="$text \n Logical Library$i (name:$name) is offline!"
                                crit=1
                        ;;
                        4)
                                text="$text \n Logical Library$i (name:$name) is offlinePending!"
                                crit=1
                        ;;
                        5)
                                text="$text \n Logical Library$i (name:$name) shutdownPending!"
                                crit=1
                        ;;
                        *)
                                echo "UNKNOWN: $type $value"
                                exit $STATE_UNKNOWN
                        ;;
                esac


        done
        if [ $crit == 1 ]
        then
                echo -e "CRITICAL: one or more Logical Library in Error state! $text |$perf"
                exit $STATE_CRITICAL
        elif [ $warn == 1 ]
        then
                echo -e "WARNING: one or more Logical Library in Warning state! $text |$perf"
                exit $SATE_WARNING
        else
                echo -e "OK: all Logical Librarys ok $text |$perf"
                exit $STATE_OK
        fi
;;




manual)
        result=$(get_snmp $moid)
        echo $result
esac
