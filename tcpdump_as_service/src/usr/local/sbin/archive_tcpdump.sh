#!/bin/bash
#
# Archive tcp dumps
# 13.03.2014,  v1.0 , Kazantsev David
# 14.03.2014,  v1.1 , Kazantsev David
# 03.04.2014,  v1.2 , Kazantsev David: xranenie failov 7 dnei
# 15.10.2014,  v2.0 , Kazantsev David: configuration file and new time format
# 31.10.2014,  v2.1 , Kazantsev David: use of lsof
# 14.05.2015,  v3.0 , Kazantsev David: sctpdechunk
# 25.05.2015,  v3.1 , Kazantsev David: pereimenovaniya dumpov
# 16.09.2015,  v3.3 , Kazantsev David: izmenenie sekcii RESK
# 02.03.2016,  v3.5 , Kazantsev David: all changes beyond this version are gone to debian change log
# -----------------------------------------------------------------------------
# IMPORTANT
# -----------------------------------------------------------------------------
# Etot script doljen zapuskatsy v crontab dlya arxivirovaniya staryh dumpov
# pri zapuschennom kak service tcpdump
# -----------------------------------------------------------------------------
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
TCPDUMPSDIR=/var/tcpdump/
PACKEDDUMPSDIR=/var/tcpdumparc/
OLDERMIN='+1440'
TOARCHIVEMIN='+1'
SERVERSPEC='EDP'
NICE='nice -n 19 ionice -c2 -n7'
PIDFILE="/var/run/archive_tcpdumps.pid"
USEDSPACELIMIT=90
#check config file and read variables
CONFIGNAME=/etc/tcpdump.d/archive_tcpdump.cfg
  . $CONFIGNAME
echo "TCPDUMPSDIR: "$TCPDUMPSDIR
echo "PACKEDDUMPSDIR: "$PACKEDDUMPSDIR
echo "OLDERMIN - time to keep tcpdumps: "$OLDERMIN
echo "TOARCHVEMIN - time to wait before move to archive: "$TOARCHIVEMIN
echo "NICE: "$NICE
echo "SERVERSPEC - type of server to process dumps: "$SERVERSPEC
echo "DATE: "`date`
echo "USEDSPACELIMIT - will try to not use space more than this on partitinon with TCPDUMPSDIR: "$USEDSPACELIMIT

#check sanity of parameters
if [ "$OLDERMIN" -lt "$TOARCHIVEMIN" ]
         then
                echo "OLDERMIN less than TOARCHIVEMIN. The script will exit now"
                exit 1
fi

#check if lsof installed
command -v lsof >/dev/null 2>&1 || { echo "I require lsof but it's not installed.  Aborting." >&2; exit 1; }

#delete all files older than OLDERMIN
$NICE find $PACKEDDUMPSDIR -mmin $OLDERMIN -type f -print0 | xargs -0 rm -v
#$NICE find $TCPDUMPSDIR -mmin $OLDERMIN -type f -print0 | xargs -0 rm -v

#check if pid exists and process running
if [ -e "$PIDFILE" ]
then
read PIDFROMFILE < $PIDFILE
echo "Previous pid found "$PIDFROMFILE
if ps -p $PIDFROMFILE > /dev/null
then
   echo "process $PIDFROMFILE is running"
   exit 2
else
   echo "but its not running"
   rm -v $PIDFILE
fi
fi

#create pid
echo "$$" >"${PIDFILE}"

#remove files in $TCPDUMPSDIR older than $OLDERMIN
while IFS= read -r -d '' file; do
	if lsof -w -t -- "$file" ;
         then echo $file" is possibly open"
         else
	 rm -v "$file"
	fi
done < <(find $TCPDUMPSDIR -mmin $OLDERMIN -type f -print0)

#funkcija udaleniya staryx failov v zavisimosti ot svobodnogo mesta v razdele
clear_folder(){
#$1 - directory
#$2 - initial oldermin
#$3 - desired use percentage
if [ `stat -c %D "$1"` != `stat -c %D "$1/.."` ]; then
    echo "$1 is mounted"
else
    echo "$1 is not mounted; may be we're waisting time here"
fi
local MMIN="+"$2
echo -n "MMIN "
echo $MMIN
echo -n "Directory is "
echo $1
echo -n "Desired percentage is "
echo $3

echo "Going to delete *.tbz files older than "$2" minutes in the folder "$1
find $1 -name "*.tbz" -mmin $MMIN -type f -print0 | xargs -0 rm -v
if [ $2 -le 1 ]
        then
                return 1
        else
                local v_percentage=`df -m $1 | awk 'FNR == 2 {print $5}' | tr -d %`
                echo -n "Current use percentage of "$1" is "
                echo $v_percentage
                if [ $v_percentage -lt $3 ]
                        then
                                echo "We have more space than we want"
                                return 1
                        else
                                echo "We have less space than we want"
                                clear_folder $1 $(( 2 * $2 / 3 )) $3
                        fi
        fi
}

clear_folder $PACKEDDUMPSDIR 14400 $USEDSPACELIMIT




#find files older than TOARCHIVEMIN and process them
#if server is EDP
if [ "$SERVERSPEC" = "EDP" ]
        then
        while IFS= read -r -d '' file; do
	 if lsof -w -t -- "$file" ;
         then echo $file" is possibly open"
         else
         fservanddate=$(hostname)_$(stat -c%y "$file" | tr ":.+ " _ | cut -c -19)
	 filemask=$fservanddate'_'$(basename "$file") 
	 mv "$file" "$TCPDUMPSDIR$filemask.pcap"
	 echo $filemask
	 $NICE tar --remove-files -cjvPf "$PACKEDDUMPSDIR$filemask.tbz" -C $TCPDUMPSDIR "$filemask.pcap"
	fi
         done < <(find $TCPDUMPSDIR -name 'dump*' -mmin $TOARCHIVEMIN -type f -print0)
fi

#if server is RES and original dumps should be kept after sctpdechunk
if [ "$SERVERSPEC" = "RESK" ]
        then
        command -v perl >/dev/null 2>&1 || { echo "I require perl but it's not installed.  Aborting." >&2; exit 1; }
        while IFS= read -r -d '' file; do
         if lsof -w -t -- "$file" ;
         then echo $file" is possibly open"
         else
         sctpdechunk "$file" "$file.dchnk.pcap"
         fservanddate=$(hostname)_$(stat -c%y "$file" | tr ":.+ " _ | cut -c -19)
         filemask=$fservanddate'_'$(basename "$file") 
	 mv "$file" "$TCPDUMPSDIR$filemask.pcap"
         mv "$file.dchnk.pcap" "$TCPDUMPSDIR$filemask.dchnk.pcap"
         echo $filemask
         $NICE tar --remove-files -cjvPf "$PACKEDDUMPSDIR$filemask.tbz" -C $TCPDUMPSDIR "$filemask.pcap" "$filemask.dchnk.pcap"
         fi
         done < <(find $TCPDUMPSDIR -name 'dump*' -mmin $TOARCHIVEMIN -type f -print0)
fi

#if server is RES and original dumps should be deleted after sctpdechunk
if [ "$SERVERSPEC" = "RESD" ]
        then
        command -v perl >/dev/null 2>&1 || { echo "I require perl but it's not installed.  Aborting." >&2; exit 1; }
        while IFS= read -r -d '' file; do
	if lsof -w -t -- "$file" ;
         then echo $file" is possibly open"
         else
         sctpdechunk "$file" "$file.dchnk.pcap"
         fservanddate=$(hostname)_$(stat -c%y "$file" | tr ":.+ " _ | cut -c -19)
         filemask=$fservanddate'_'$(basename "$file")
         rm "$file"
         mv "$file.dchnk.pcap" "$TCPDUMPSDIR$filemask.dchnk.pcap"
         echo $filemask
         $NICE tar --remove-files -cjvPf "$PACKEDDUMPSDIR$filemask.tbz" -C $TCPDUMPSDIR "$filemask.dchnk.pcap"
         fi
         done < <(find $TCPDUMPSDIR -name 'dump*' -mmin $TOARCHIVEMIN -type f -print0)
fi 

#rm pid file
if [ -f ${PIDFILE} ]; then
    rm ${PIDFILE}
fi
