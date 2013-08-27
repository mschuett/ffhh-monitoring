#! /bin/sh

# use tmpfs for rrd files:
rrddir=/tmp
savedir=/mnt/rrd
cd $rrddir

####
# Network Interface Counters

get_interfaces() {
  cat /proc/net/dev | sed -ne 's/^ *\([^:]*\): .*$/\1/p'
}

for interface in `get_interfaces`; do 
  test -s if_$interface.rrd ||
  rrdtool create if_$interface.rrd \
  --step '60' \
  'DS:rx_bytes:COUNTER:60:0:U' \
  'DS:rx_pkts:COUNTER:60:0:U' \
  'DS:rx_err:COUNTER:60:0:U' \
  'DS:rx_drop:COUNTER:60:0:U' \
  'DS:tx_bytes:COUNTER:60:0:U' \
  'DS:tx_pkts:COUNTER:60:0:U' \
  'DS:tx_err:COUNTER:60:0:U' \
  'DS:tx_drop:COUNTER:60:0:U' \
  'RRA:AVERAGE:0.5:1:200' \
  'RRA:AVERAGE:0.5:10:300' \
  'RRA:AVERAGE:0.5:60:180' \
  'RRA:AVERAGE:0.5:200:250' \
  'RRA:AVERAGE:0.5:800:720' \
  'RRA:AVERAGE:0.5:1440:3700'
done

# field 1 interface
# 2--5 rx
# 10--13 tx
cat /proc/net/dev \
  | sed -ne 's/ *\(.*\):  *\([0-9]*\)  *\([0-9]*\)  *\([0-9]*\)  *\([0-9]*\)  *[0-9]*  *[0-9]*  *[0-9]*  *[0-9]*  *\([0-9]*\)  *\([0-9]*\)  *\([0-9]*\)  *\([0-9]*\)  *[0-9]*  *[0-9]*  *[0-9]*  *[0-9]*/rrdtool update if_\1.rrd N:\2:\3:\4:\5:\6:\7:\8:\9/p' \
  | sh

####
# Connected WLAN Devices    

test -s current_clients.rrd ||
rrdtool create current_clients.rrd \
  --step '60' \
  'DS:clients:GAUGE:60:0:U' \
  'RRA:AVERAGE:0.5:1:200' \
  'RRA:AVERAGE:0.5:10:300' \
  'RRA:AVERAGE:0.5:60:180' \
  'RRA:AVERAGE:0.5:200:250' \
  'RRA:AVERAGE:0.5:800:720' \
  'RRA:AVERAGE:0.5:1440:3700' \
  'RRA:MIN:0.5:1:200' \
  'RRA:MIN:0.5:10:300' \
  'RRA:MIN:0.5:60:180' \
  'RRA:MIN:0.5:200:250' \
  'RRA:MIN:0.5:800:720' \
  'RRA:MIN:0.5:1440:3700' \
  'RRA:MAX:0.5:1:200' \
  'RRA:MAX:0.5:10:300' \
  'RRA:MAX:0.5:60:180' \
  'RRA:MAX:0.5:200:250' \
  'RRA:MAX:0.5:800:720' \
  'RRA:MAX:0.5:1440:3700'
rrdtool update current_clients.rrd N:`iw dev wlan0 station dump | grep ^Station | wc -l`

####
# CPU Load

test -s load.rrd ||
rrdtool create load.rrd \
  --step '60' \
  'DS:load1:GAUGE:60:0:U' \
  'DS:load5:GAUGE:60:0:U' \
  'DS:load15:GAUGE:60:0:U' \
  'RRA:AVERAGE:0.5:1:200' \
  'RRA:AVERAGE:0.5:10:300' \
  'RRA:AVERAGE:0.5:60:180' \
  'RRA:AVERAGE:0.5:200:250' \
  'RRA:AVERAGE:0.5:800:720' \
  'RRA:AVERAGE:0.5:1440:3700' \
  'RRA:MIN:0.5:1:200' \
  'RRA:MIN:0.5:10:300' \
  'RRA:MIN:0.5:60:180' \
  'RRA:MIN:0.5:200:250' \
  'RRA:MIN:0.5:800:720' \
  'RRA:MIN:0.5:1440:3700' \
  'RRA:MAX:0.5:1:200' \
  'RRA:MAX:0.5:10:300' \
  'RRA:MAX:0.5:60:180' \
  'RRA:MAX:0.5:200:250' \
  'RRA:MAX:0.5:800:720' \
  'RRA:MAX:0.5:1440:3700'

rrdtool update load.rrd `cat /proc/loadavg | sed -e 's/^\([0-9\.]*\) \([0-9\.]*\) \([0-9\.]*\) .*$/N:\1:\2:\3/'`

####
# Memory Usage
test -s mem.rrd ||
rrdtool create mem.rrd \
  --step '60' \
  'DS:Active:GAUGE:60:0:U' \
  'DS:Buffers:GAUGE:60:0:U' \
  'DS:Cached:GAUGE:60:0:U' \
  'DS:Inactive:GAUGE:60:0:U' \
  'DS:MemTotal:GAUGE:60:0:U' \
  'DS:MemFree:GAUGE:60:0:U' \
  'RRA:AVERAGE:0.5:1:200' \
  'RRA:AVERAGE:0.5:10:300' \
  'RRA:AVERAGE:0.5:60:180' \
  'RRA:AVERAGE:0.5:200:250' \
  'RRA:AVERAGE:0.5:800:720' \
  'RRA:AVERAGE:0.5:1440:3700' \
  'RRA:MIN:0.5:1:200' \
  'RRA:MIN:0.5:10:300' \
  'RRA:MIN:0.5:60:180' \
  'RRA:MIN:0.5:200:250' \
  'RRA:MIN:0.5:800:720' \
  'RRA:MIN:0.5:1440:3700' \
  'RRA:MAX:0.5:1:200' \
  'RRA:MAX:0.5:10:300' \
  'RRA:MAX:0.5:60:180' \
  'RRA:MAX:0.5:200:250' \
  'RRA:MAX:0.5:800:720' \
  'RRA:MAX:0.5:1440:3700'

rrdtool update mem.rrd `cat /proc/meminfo | grep -Ee '^(MemTotal|MemFree|Buffers|Cached|Active|Inactive):' | sort | awk '{print $2}' | xargs printf "N:%d:%d:%d:%d:%d:%d\n"`

####
# every now and then copy files to USB or flash memory
d=`date +%M`
if [[ $d == "00" || $d == "30" ]]; then
  mkdir -p $savedir
  cp *.rrd $savedir
fi

