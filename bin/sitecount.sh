grep "submitting" cps*.log | awk '{print $5}' | sed -e 's/:.*//' | sort | uniq -c
