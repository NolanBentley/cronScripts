#!/bin/bash

##Setup variables
currTime=$(date "+%Y/%m/%d @ %h:%M:%S %r")
currTime2=$(date "+%Y-%m-%d_%H-%M-%S")
log1=/home/nolan/cronLog.txt
ipLogLoc=/home/SharedUser/ipLog/

##Update log
echo "cron ip log script run at $currTime" >> $log1
log2=$(tail -n 100 $log1)
echo $log2 > $log1


## Save and trim ip logs
cd $ipLogLoc
cat ipLog.txt > ipLog_prev
tail -n 20 ipLog.txt  > ipLog_tail
cat ipLog_tail | awk '!x[$0]++' > ipLog.txt

## Add new ip's to the compiled file
cat ipList > ipList_prev
cat ipLog.txt >> ipList
cat ipList | sort | awk '!x[$0]++' > ipList_new
cat ipList_new > ipList

#Email me if there is a new login
ogLEN1=$(wc -l ipList | cut -f 1 -d " ")
ogLEN2=$(wc -l ipList_prev| cut -f 1 -d " ")
if [ "$ogLEN1" != "$ogLEN2" ] ; then
	echo "#Diff of ip lists at $currTime:" > message_$currTime2
	diff ipList ipList_prev >> message_$currTime2
	echo "" >> message_$currTime2
	echo "#Current ipList:" >> message_$currTime2
	cat ipList >> message_$currTime2
        cat message_$currTime2 | mutt -s "Low urgency: New ip address on popgen3" -F /home/nolan/.muttrc -- "nolanbentley@utexas.edu"
fi

