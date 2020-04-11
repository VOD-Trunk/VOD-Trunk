#!/bin/bash
cat /root/autoring/email2.txt > mail_to_send
for i in `ls /root/autoring/Health_Reports/`
do
	cat /root/autoring/Health_Reports/$i | uuencode $i >> mail_to_send
done
sendmail -f "HealthCheck_Alerts@hsc.com" abhishek.chadha@hsc.com deepam.1920@hsc.com Tiago.Durante@hsc.com puneet.sharma@hsc.com aditya.mittal@hsc.com akhilesh.chaudhary@hsc.com debashish.sahu@hsc.com deepak.dahuja@hsc.com harold.luzardo@hsc.com  jaskiran.dhingra@hsc.com mohit.sati@hsc.com pratyush.mishra@hsc.com rupak.panta@hsc.com rupesh.singh@hsc.com sachin.garg@hsc.com sandeep.ujjwal@hsc.com shailesh.vyas@hsc.com sagar.suneja@hsc.com Deepak.Rohilla@hsc.com shashank.shukla@hsc.com < mail_to_send
rm -f /root/autoring/Health_Reports/*
rm mail_to_send
rm -f /root/autoring/email2.txt
