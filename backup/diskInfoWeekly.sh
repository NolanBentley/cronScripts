#!/bin/bash

##Customize these per server
log1=/home/nolan/Experiments/cronScripts/"$HOSTNAME"_cronLog.txt
muttPath="/home/nolan/.mutt/muttrc"
emergencyEmails="nolanbentley@utexas.edu,tjuenger@austin.utexas.edu,li.zhang@austin.utexas.edu,jebonnette@utexas.edu"
weeklyEmails="nolanbentley@utexas.edu,li.zhang@austin.utexas.edu,jebonnette@utexas.edu"
dailyEmails="nolanbentley@utexas.edu"

##Setup variables
scriptName="disk info script"
currTime=$(date "+%Y/%m/%d @ %h:%M:%S %r")
percPath=/opt/MegaRAID/perccli
percProgram=$percPath/perccli64
diskInfoFull=$percPath/diskWeeklyInfo_full.txt
diskInfo=$percPath/diskWeeklyInfo.txt
diskPrev=$percPath/diskWeeklyPrev.txt
diskDiff=$percPath/diskWeeklyDiff.txt
diskSummary=$percPath/diskWeeklyInfoSummary.txt
message=$percPath/weeklyMessage.txt

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

## Make a summary report
date "+%Y/%m/%d @ %h:%M:%S %r" > $diskSummary
grep -E "Drive .* State :|S.M.A.R.T.|Error|Predictive Failure Count|Shield Counter|^================$" $diskInfo > $diskSummary

## Make a report
day=$(date "+%a")
echo "######### Diff report #########"> $message
cat $diskDiff >> $message
echo "###############################" >> $message
echo "" >> $message
echo "####### Summary report ########" >> $message
cat "$diskSummary" >> $message
echo "###############################" >> $message
echo "" >> $message
echo "######## Full report ##########" >> $message
cat "$diskInfo" >> $message
echo "###############################" >> $message
echo "############ End ##############" >> $message
echo "- Made report" >> $log1

## Send report 
cat "$message" | mutt -s "Weekly report regarding $HOSTNAME's RAID drives ($currTime)" -F "$muttPath" -- "$weeklyEmails"
echo "- Sent weekly report" >> $log1

## Check for urgent changes
### Check the important rows that I am aware of
ogLEN1=$(egrep "^S\.M\.A\.R\.T alert|Predictive Failure Count = " "$diskSummary" | wc -l |cut -f 1 -d " ")
ogLEN2=$(egrep "^S\.M\.A\.R\.T alert.* = No$|Predictive Failure Count = 0" "$diskSummary" | wc -l | cut -f 1 -d " ")
echo "- Grepped SMART value lines: All=" "$ogLEN1" " vs. Good=" "$ogLEN2" >> $log1
ogLEN3=$(egrep "Media Error Count =" "$diskSummary" | wc -l |cut -f 1 -d " ")
ogLEN4=$(egrep "Media Error Count = 0" "$diskSummary" | wc -l | cut -f 1 -d " ")
echo "- Grepped Error count lines: All=" "$ogLEN3" " vs. Good=" "$ogLEN4" >> $log1

### Check for raw differences (excludes temperature)
diffWc=$(cat "$diskDiff" | wc -l | cut -f 1 -d " ")
echo "- Counted lines in diff (expect 6): " "$diffWc" >> $log1

## Add log to message for urgent emails
printf '%s\n%s\n' "##### Log from diskInfo.sh #####" "$(tail -8 $log1)" "####################" " " "$(cat $message)" > $message

### Send urgent message to emergency numbers if SMART errors
if [ "$ogLEN1" != "$ogLEN2" ] ; then
	cat "$message" | mutt -s "URGENT: SMART alert regarding $HOSTNAME's RAID drives ($currTime)" -F "$muttPath" -- "$emergencyEmails"
	echo "- Sent URGENT message regarding SMART!!!!" >> $log1
fi

### Send urgent message to maintainer if errors
if [ "$ogLEN3" != "$ogLEN4" ] ; then
	cat "$message" | mutt -s "URGENT: Error alert regarding $HOSTNAME's RAID drives ($currTime)" -F "$muttPath" -- "$dailyEmails"
	echo "- Sent URGENT message regarding Errors!!!!" >> $log1
fi

### Send urgent message to maintainer if changed
if [ "$diffWc" \> 6 ] ; then
	cat "$message" | mutt -s "URGENT: Something has changed regarding $HOSTNAME's RAID drives ($currTime)" -F "$muttPath" -- "$dailyEmails"
	echo "- Sent URGENT report regarding diffs!!!" >> $log1
fi

#Make a copy of current disk summary the previous
cat "$diskInfo" > $diskPrev
echo "- Overwrote previous files" >> $log1

#exit
echo "- Done!" >> $log1
exit 0
