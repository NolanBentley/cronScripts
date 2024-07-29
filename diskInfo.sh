#!/bin/bash

##Setup variables
scriptName="disk info script"
currTime=$(date "+%Y/%m/%d @ %h:%M:%S %r")
currTime2=$(date "+%Y-%m-%d_%H-%M-%S")
log1=/home/nolan/cronLog.txt
ipLogLoc=/home/SharedUser/ipLog/
percPath=/opt/MegaRAID/perccli
percProgram=$percPath/perccli64
diskInfo=$percPath/diskInfo.txt
diskHist=$percPath/diskInfoHistory.txt
diskSummary=$percPath/diskInfoSummary.txt
diskReport=$percPath/diskReport.txt
muttPath="/home/nolan/.muttrc"
emergencyEmails="nolanbentley@utexas.edu, tjuenger@austin.utexas.edu,li.zhang@austin.utexas.edu ,jebonnette@utexas.edu"
weeklyEmails="nolanbentley@utexas.edu,li.zhang@austin.utexas.edu ,jebonnette@utexas.edu"
dailyEmails="nolanbentley@utexas.edu"

##Update log
tail -n 1000 "$log1" > "$log1"_prev
cat "$log1"_prev > "$log1"
echo "" >> "$log1"
echo "cron $scriptName run at $currTime:" >> "$log1"

## Save current disk info
echo "Report on " "$currTime" > "$diskInfo"
"$percProgram" /c0 /eall /sall show all >> "$diskInfo"
echo "- Saved info" >> "$log1"

## Save current to end of history
histTxt=$(tail -100000 "$diskHist")
echo "$histTxt" > "$diskHist"
echo "##########" >> "$diskHist"
cat "$diskInfo" >> "$diskHist"
echo "" >> "$diskHist"
echo "" >> "$diskHist"
echo "- Saved history" >> "$log1"

## Save a summary 
date "+%Y/%m/%d @ %h:%M:%S %r" > $diskSummary
grep -E "S.M.A.R.T.|Error|HDD" $diskInfo > $diskSummary

# Make a report of current disk info
echo "Report on: " $currTime > $diskReport
cat $diskSummary >> $diskReport
echo "" >> $diskReport
echo "########### Full Report #############" >> $diskReport
cat $diskInfo >> $diskReport
echo "- Saved report" >> $log1

###### Check for changes to SMART! #######
## Analyze summary files and if ogLEN1!=ogLEN2+1, then email alert
ogLEN1=$(egrep "^S\.M\.A\.R\.T alert" "$diskInfoSummary" | wc -l |cut -f 1 -d " ")
ogLEN2=$(egrep "^S\.M\.A\.R\.T alert.* = No$" "$diskInfoSummary" | wc -l | cut -f 1 -d " ")
echo "- Done SMART greps" >> $log1
if [ "$ogLEN1" != "$ogLEN2" ] ; then
	message="$percPath"/smartBasedMessage_"$currTime2"
    echo "####### SMART report ########" > $message
	echo "$ogLEN1" >> $message
	echo "$ogLEN2" >> $message
	cat "$diskReport" >> $message
	cat "$message" | mutt -s "URGENT: SMART alert regarding Popgen3's RAID drives ($currTime)" -F "$muttPath" -- "$emergencyEmails"
	echo "- Sent URGENT message regarding SMART" >> $log1
fi

###### Email admins weekly and head admin daily ########
day=$(date "+%a")
dayToCheck="Fri"
message="$percPath"/dailyMessage.txt
echo "####### Diff report ########" >> $message
diff "$diskReport"_prev.txt "$diskReport" >> $message
echo "############################" >> $message
echo "####### Summary report ########" >> $message
cat "$diskSummary" >> $message
echo "############################" >> $message
echo "" >> $message
echo "####### Full report ########" >> $message
cat "$diskReport" >> $message
if [ "$day" = "$dayToCheck" ] ; then
	cat "$message" | mutt -s "Weekly report regarding Popgen3's RAID drives ($currTime)" -F "$muttPath" -- "$weeklyEmails"
	echo "- Sent weekly report" >> $log1
else
	cat "$message" | mutt -s "Daily report regarding Popgen3's RAID drives ($currTime)" -F "$muttPath" -- "$dailyEmails"
	echo "- Sent daily report" >> $log1
fi

#Check for differences in the summary text
diffOut=$(diff "$diskSummary"_prev.txt "$diskSummary")
diffWc=$(diff "$diskSummary"_prev.txt "$diskSummary" | wc -l | cut -f 1 -d " ")
echo "- Done summary diffs" >> $log1
if [ "$diffWc" != 0 ] ; then
	message=$percPath/diffMessage_$currTime2
	echo "####### Diff report ########" >> $message
	echo "$diffOut" >> $message
	echo "############################" >> $message
	echo "" >> $message
	echo "####### Full report ########" >> $message
	cat "$diskReport" >> $message
	cat "$message" | mutt -s "URGENT: Something has changed regarding popgen3's RAID drives ($currTime)" -F "$muttPath" -- "$emergencyEmails"
	echo "- Sent URGENT report regarding diffs" >> $log1
fi

#Make a copy of current disk summary the previous
cp "$diskSummary" "$diskSummary"_prev.txt
cp "$diskReport" "$diskReport"_prev.txt
echo "- Overwrote previous files" >> $log1

#exit
echo "- Done!" >> $log1
exit 0
