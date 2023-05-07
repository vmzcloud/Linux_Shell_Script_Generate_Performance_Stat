#if first date of month, generate the data to the last month file
csv_date=$(date +%Y%m)
if [ $(date +%d) = "01" ]
then
    csv_date=$(date +%Y%m -d yesterday)
fi

#Create Daily Stat Folder if not exist
if [ ! -d "/var/log/sa/daily_stat/$(date +%Y%m)" ]
then
        mkdir -p /var/log/sa/daily_stat/$(date +%Y%m)
fi

cpu_no_of_row=0
mem_no_of_row=0
cpu_file=/var/log/sa/cpu_avg_$(date +%Y%m -d yesterday).csv
mem_file=/var/log/sa/mem_avg_$(date +%Y%m -d yesterday).csv
if [ -f "$cpu_file" -a -f "$mem_file" ]; then
        cpu_no_of_row=$(wc -l < $cpu_file)
        mem_no_of_row=$(wc -l < $mem_file)
fi

date_of_compare=$(date +%d -d yesterday)

n="$(($date_of_compare-$cpu_no_of_row))"
for (( i=$n; i>0; --i ))
do
        file="/var/log/sa/sa$(date --date="$i day ago" +"%d")"
        sar_date=$(sar -f $file | head -n 1 | awk '{print $4}')

        cpu_avg=$(sar -u -f $file | grep all | grep -v Average | awk '{ total += $9; count++ } END { if (count > 0) printf("%.2f\n"), 100 - (total / count);}')

        #kbmemused - kbbuffers - kbcached / (kbmemfree + kbmemused)
        mem_avg=$(sar -r -f $file | grep . | grep -vi LINUX | grep -v Average | grep -v kbmemfree | awk '{ kbmemused += $4; kbbuffers += $6; kbcached += $7; kbmemfree += $3; } END { printf("%.2f\n"), (kbmemused - kbbuffers - kbcached)/(kbmemfree + kbmemused)*100}')

        echo $sar_date , $cpu_avg >> /var/log/sa/cpu_avg_$csv_date.csv
        echo $sar_date , $mem_avg >> /var/log/sa/mem_avg_$csv_date.csv

        sar -u -f $file > /var/log/sa/daily_stat/$csv_date/$(date --date="$i day ago" "+%Y%m%d")_cpu.txt
        sar -r -f $file > /var/log/sa/daily_stat/$csv_date/$(date --date="$i day ago" "+%Y%m%d")_mem.txt
done
