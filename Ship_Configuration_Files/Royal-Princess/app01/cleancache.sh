#!/bin/bash

# Find all cache files created over 24 hours ago, and not used for at least 24 hours:
cachelist=($(find /var/cache/mod_proxy -amin -1440 -mmin -1440 -type f))

# Find all cache files that are open / in use:
inuse=($(lsof |grep /var/cache/mod_proxy | awk '{ print $NF }' | sort -u))

# Compare the two lists and remove the old cache files not in use:
(printf "%s\n" ${cachelist[@]} ; printf "%s\n" ${inuse[@]}) |\
	sort |\
	uniq -u |\
	xargs rm

# So now we've probably got some empty directories left behind,
# need to remove them.  And of course they are nested 3 to 4 levels
# deep, so have to clear them all the way up to the parent.  So we
# iterate 4 times to get them all.
for i in `seq 1 4`
do
	find /var/cache/mod_proxy -type d -empty -print0 | xargs -0 rmdir -v
done
