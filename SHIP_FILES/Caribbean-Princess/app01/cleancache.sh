


cachelist=($(find /var/cache/mod_proxy -amin -1440 -mmin -1440 -type f))


inuse=($(lsof |grep /var/cache/mod_proxy | awk '{ print $NF }' | sort -u))


(printf "%s\n" ${cachelist[@]} ; printf "%s\n" ${inuse[@]}) |\
sort |\
uniq -u |\
xargs rm





for i in `seq 1 4`
do
find /var/cache/mod_proxy -type d -empty -print0 | xargs -0 rmdir -v
done
