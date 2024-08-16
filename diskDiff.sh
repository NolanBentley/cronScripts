#!/bin/bash

##Setup variables
scriptName="disk info script"
currTime=$(date "+%Y/%m/%d @ %h:%M:%S %r")
currTime2=$(date "+%Y-%m-%d_%H-%M-%S")
log1=/home/nolan/cronLog.txt
ipLogLoc=/home/SharedUser/ipLog/
percPath=/opt/MegaRAID/perccli
percProgram=$percPath/perccli64
diskInfoFull=$percPath/diskInfo_full.txt
diskInfo=$percPath/diskInfo.txt
diskInfo=$percPath/diskInfo.txt
diskPrev=$percPath/diskPrev.txt
diskDiff=$percPath/diskDiff.txt
diskSummary=$percPath/diskInfoSummary.txt
message="$percPath"/dailyMessage.txt

diskHist=$percPath/diskInfoHistory.txt
diskReport=$percPath/diskReport.txt
muttPath="/home/nolan/.mutt/muttrc"
emergencyEmails="nolanbentley@utexas.edu" #, tjuenger@austin.utexas.edu,li.zhang@austin.utexas.edu ,jebonnette@utexas.edu"
weeklyEmails="nolanbentley@utexas.edu"    #,li.zhang@austin.utexas.edu ,jebonnette@utexas.edu"
dailyEmails="nolanbentley@utexas.edu"

##Update log
tail -n 1000 "$log1" > "$log1"_prev
cat "$log1"_prev > "$log1"
echo "" >> "$log1"
echo "cron $scriptName run at $currTime:" >> "$log1"

## Save current disk info
echo "Report on " "$currTime" > "$diskInfoFull"
"$percProgram" /c0 /eall /sall show all >> "$diskInfoFull"
grep -v "Temperature" $diskInfoFull > "$diskInfo"
echo "- Saved info" >> "$log1"

## Add tail onto previous disk info (this and the timestamps should always be present in diff)
echo "#### End of previous ####" >> "$diskPrev"

## Find the difference
diff "$diskInfo" "$diskPrev" > "$diskDiff"

## Make a copy of current disk summary the previous
cat "$diskInfo" > $diskPrev
echo "- Overwrote previous files" >> $log1

#exit
echo "- Done!" >> $log1
exit 0
