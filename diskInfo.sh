#!/bin/bash

##Setup variables
scriptName="disk info script"
currTime=$(date "+%Y/%m/%d @ %h:%M:%S %r")
currTime2=$(date "+%Y-%m-%d_%H-%M-%S")
log1=/home/nolan/cronLog.txt
ipLogLoc=/home/SharedUser/ipLog/
diskInfo=/opt/MegaRAID/perccli/diskInfo.txt
diskHist=/opt/MegaRAID/perccli/diskInfoHistory.txt

##Update log
echo "cron $scriptName run at $currTime" >> $log1
log2=$(tail -n 100 $log1)
echo $log2 > $log1

## Save current disk info
echo "Report on " $currTime > $diskInfo
/opt/MegaRAID/perccli/perccli64 /c0 /eall /sall show all >> $diskInfo

## Save current to end of history
histTxt=$(tail -100000 $diskHist)
echo $histTxt > $diskHist
echo "##########" >> $diskHist
cat $diskInfo >> $diskHist
echo "" >> /opt/MegaRAID/perccli/diskInfoHistory.txt
echo "" >> /opt/MegaRAID/perccli/diskInfoHistory.txt

## Save a summary 
date "+%Y/%m/%d @ %h:%M:%S %r" > /opt/MegaRAID/perccli/diskInfoSummary.txt
grep -E "S.M.A.R.T.|Error|HDD" /opt/MegaRAID/perccli/diskInfo.txt > /opt/MegaRAID/perccli/diskInfoSummary.txt

# Make a report
echo "Report on: " $currTime > /opt/MegaRAID/perccli/diskReport.txt
cat /opt/MegaRAID/perccli/diskInfoSummary.txt >> /opt/MegaRAID/perccli/diskReport.txt
echo "" >> /opt/MegaRAID/perccli/diskReport.txt
echo "########### Full Report #############" >> /opt/MegaRAID/perccli/diskReport.txt
cat /opt/MegaRAID/perccli/diskInfo.txt >> /opt/MegaRAID/perccli/diskReport.txt

###### Check for changes to SMART! #######
## Analyze summary files and if ogLEN1!=ogLEN2+1, then email alert
ogLEN1=$(egrep "^S\.M\.A\.R\.T alert" /opt/MegaRAID/perccli/diskInfoSummary.txt | wc -l |cut -f 1 -d " ")
ogLEN2=$(egrep "^S\.M\.A\.R\.T alert.* = No$" /opt/MegaRAID/perccli/diskInfoSummary.txt | wc -l | cut -f 1 -d " ")
if [ "$ogLEN1" != "$ogLEN2" ] ; then
	message=/opt/MegaRAID/perccli/smartBasedMessage_$currTime2
        echo "####### SMART report ########" > $message
	echo $ogLEN1 >> $message
	echo $ogLEN2 >> $message
	cat /opt/MegaRAID/perccli/diskReport.txt >> $message
	cat $message | mutt -s "URGENT: Alert regarding Popgen3's RAID drives" -F /home/nolan/.muttrc -- "nolanbentley@utexas.edu, tjuenger@austin.utexas.edu,li.zhang@austin.utexas.edu ,jebonnette@utexas.edu"
fi

###### Email admins weekly and head admin daily ########
day=$(date "+%a")
dayToCheck="Fri"
if [ $day = $dayToCheck ] ; then
	cat /opt/MegaRAID/perccli/diskReport.txt | mutt -s "Weekly report regarding Popgen3's RAID drives" -F /home/nolan/.muttrc -- "nolanbentley@utexas.edu,li.zhang@austin.utexas.edu ,jebonnette@utexas.edu"
else
        message=/opt/MegaRAID/perccli/dailyMessage.txt
        echo "####### Diff report ########" >> $message
        diff 
        echo "############################" >> $message
        echo "" >> $message
        echo "####### Full report ########" >> $message
        cat /opt/MegaRAID/perccli/diskReport.txt >> $message
	cat /opt/MegaRAID/perccli/diskReport.txt | mutt -s "Daily report regarding Popgen3's RAID drives" nolanbentley@gmail.com -F /home/nolan/.muttrc
fi

#Check for differences in the summary text
diffOut=$(diff /opt/MegaRAID/perccli/diskInfoSummary_prev.txt /opt/MegaRAID/perccli/diskInfoSummary.txt)
diffWc=$(diff /opt/MegaRAID/perccli/diskInfoSummary_prev.txt /opt/MegaRAID/perccli/diskInfoSummary.txt | wc -l | cut -f 1 -d " ")
if [ "$diffWc" != 0 ] ; then
	message=/opt/MegaRAID/perccli/message_$currTime2
	echo "####### Diff report ########" >> $message
	echo $diffOut >> $message
	echo "############################" >> $message
	echo "" >> $message
	echo "####### Full report ########" >> $message
	cat /opt/MegaRAID/perccli/diskReport.txt >> $message
	cat $message | mutt -s "URGENT: Something has changed regarding popgen3's RAID drives " -F /home/nolan/.muttrc -- "nolanbentley@utexas.edu, tjuenger@austin.utexas.edu,li.zhang@austin.utexas.edu ,jebonnette@utexas.edu"
fi

#Make a copy of current disk summary the previous
cp /opt/MegaRAID/perccli/diskInfoSummary.txt /opt/MegaRAID/perccli/diskInfoSummary_prev.txt
cp /opt/MegaRAID/perccli/diskReport.txt /opt/MegaRAID/perccli/diskReport_prev.txt

#else exit
exit 0
