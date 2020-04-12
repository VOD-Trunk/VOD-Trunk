






















(echo "Seconds Number-of-Requests Percentage"
cat /var/log/httpd/access_log |\
awk '{ print $6 " " $11 }' |\
grep " 200" | tail -n 5000 | sort -n | uniq -c |\
sed -e 's/ 200//g' | awk '{ t = $1; $1 = $2; $2 = t; print; }' |\
while read -r -a line
do
line[2]=`echo "scale=2; ${line[1]}*100/5000" | bc -l | sed -e 's/^\./00./g'`
echo "${line[0]} ${line[1]} ${line[2]}%"
done) | column -t | sed -e 's/\b[1-9]\b\./0&/g'

