#! /bin/sh
#
# create graphs from rrd files
#

####
# note on directories:
# I keep rrd files in /tmp (i.e. RAM) and persistant files on an USB stick
rrddir=/tmp
outdir=/mnt/www
cd $rrddir

width=420
height=120

# calc percentile limit for freifunk graph
percentile=98
time=1w
limit=`rrdtool graph ${outdir}/graph_freifunk_${time}.png \
--start end-${time} \
"DEF:txb_eth1=if_eth1.rrd:tx_bytes:AVERAGE" \
"DEF:rxb_eth1=if_eth1.rrd:rx_bytes:AVERAGE" \
"DEF:txb_mesh=if_mesh-vpn.rrd:tx_bytes:AVERAGE" \
"DEF:rxb_mesh=if_mesh-vpn.rrd:rx_bytes:AVERAGE" \
"DEF:txb_wlan0=if_wlan0.rrd:tx_bytes:AVERAGE" \
"DEF:rxb_wlan0=if_wlan0.rrd:rx_bytes:AVERAGE" \
CDEF:pct0=txb_eth1,rxb_eth1,MAX,txb_mesh,MAX,rxb_mesh,MAX,txb_wlan0,MAX,rxb_wlan0,MAX \
VDEF:pct=pct0,${percentile},PERCENT \
'PRINT:pct:%lf' | tail -1`

# all graphs for three time intervals:
for time in 1d 1w 1m; do

rrdtool graph ${outdir}/graph_load_${time}.png \
--title 'CPU Load' \
--width $width \
--height $height \
--start end-${time} \
-r -l 0 -u 1.1 \
--imginfo '%s %lu x %lu' \
'DEF:avg_l1=load.rrd:load1:AVERAGE' \
'DEF:min_l1=load.rrd:load1:MIN' \
'DEF:max_l1=load.rrd:load1:MAX' \
'DEF:avg_l5=load.rrd:load5:AVERAGE' \
'DEF:min_l5=load.rrd:load5:MIN' \
'DEF:max_l5=load.rrd:load5:MAX' \
'DEF:avg_l15=load.rrd:load15:AVERAGE' \
'DEF:min_l15=load.rrd:load15:MIN' \
'DEF:max_l15=load.rrd:load15:MAX' \
'AREA:min_l1' \
'AREA:max_l1#cea8ea::STACK' \
'LINE2:avg_l15#ffba00:Load 15' \
'GPRINT:avg_l15:AVERAGE:Avg. %4.1lf' \
'GPRINT:min_l15:MIN:Min. %4.1lf' \
'GPRINT:max_l15:MAX:Max. %4.1lf\l' \
'LINE2:avg_l5#78e700:Load  5' \
'GPRINT:avg_l5:AVERAGE:Avg. %4.1lf' \
'GPRINT:min_l5:MIN:Min. %4.1lf' \
'GPRINT:max_l5:MAX:Max. %4.1lf\l' \
'LINE2:avg_l1#680bab:Load  1' \
'GPRINT:avg_l1:AVERAGE:Avg. %4.1lf' \
'GPRINT:min_l1:MIN:Min. %4.1lf' \
'GPRINT:max_l1:MAX:Max. %4.1lf\l' \
"COMMENT:[$(date "+%F %T" | sed 's/:/\\:/g')]\r"


rrdtool graph ${outdir}/graph_mem_${time}.png \
--title 'Memory' \
--width $width \
--height $height \
--start end-${time} \
-r -l 0 -u 10485760 \
--imginfo '%s %lu x %lu' \
'DEF:MemTotalK=mem.rrd:MemTotal:AVERAGE' \
'DEF:MemFreeK=mem.rrd:MemFree:AVERAGE' \
'DEF:ActiveK=mem.rrd:Active:AVERAGE' \
'DEF:InactiveK=mem.rrd:Inactive:AVERAGE' \
'DEF:BuffersK=mem.rrd:Buffers:AVERAGE' \
'DEF:CachedK=mem.rrd:Cached:AVERAGE' \
'CDEF:MemTotal=MemTotalK,1024,*' \
'CDEF:MemFree=MemFreeK,1024,*' \
'CDEF:Active=ActiveK,1024,*' \
'CDEF:Inactive=InactiveK,1024,*' \
'CDEF:Buffers=BuffersK,1024,*' \
'CDEF:Cached=CachedK,1024,*' \
'LINE3:MemTotal#FF0000:MemTotal' \
'GPRINT:MemTotal:AVERAGE:Avg. %6.1lf%s' \
'LINE3:MemFree#7FC97F:MemFree ' \
'GPRINT:MemFree:AVERAGE:Avg. %6.1lf%s\l' \
'LINE3:Active#BEAED4:Active  ' \
'GPRINT:Active:AVERAGE:Avg. %6.1lf%s' \
'LINE3:Inactive#FDC086:Inactive' \
'GPRINT:Inactive:AVERAGE:Avg. %6.1lf%s\l' \
'LINE3:Buffers#FFFF99:Buffers ' \
'GPRINT:Buffers:AVERAGE:Avg. %6.1lf%s' \
'LINE3:Cached#386CB0:Cached  ' \
'GPRINT:Cached:AVERAGE:Avg. %6.1lf%s\l' \
"COMMENT:[$(date "+%F %T" | sed 's/:/\\:/g')]\r"

rrdtool graph ${outdir}/graph_clients_${time}.png \
--title 'Clients' \
--width $width \
--height $height \
--start end-${time} \
--imginfo '%s %lu x %lu' \
'DEF:num=current_clients.rrd:clients:AVERAGE' \
'LINE2:num#FF0000:Clients' \
'GPRINT:num:AVERAGE:Avg. %4.1lf' \
'GPRINT:num:MIN:Min. %4.1lf' \
'GPRINT:num:MAX:Max. %4.1lf\l' \
"COMMENT:  Date\: $(date "+%F %T" | sed 's/:/\\:/g')\r"

scale=1024
for file in if_*.rrd; do
base=`basename $file .rrd`
rrdtool graph ${outdir}/graph_${base}_${time}.png \
--title "Network I/O ${base}" \
--vertical-label Packets/sec \
--width $width \
--height $height \
--start end-${time} \
--right-axis ${scale}:0 --right-axis-label Bytes/sec \
--imginfo '%s %lu x %lu' \
"DEF:tx_bytes=${file}:tx_bytes:AVERAGE" \
"DEF:tx_pkts=${file}:tx_pkts:AVERAGE" \
"DEF:tx_err=${file}:tx_err:AVERAGE" \
"DEF:tx_drop=${file}:tx_drop:AVERAGE" \
"DEF:rx_bytes=${file}:rx_bytes:AVERAGE" \
"DEF:rx_pkts=${file}:rx_pkts:AVERAGE" \
"DEF:rx_err=${file}:rx_err:AVERAGE" \
"DEF:rx_drop=${file}:rx_drop:AVERAGE" \
"CDEF:stx_bytes=tx_bytes,${scale},/" \
'CDEF:nrx_bytes=rx_bytes,-1,*' \
"CDEF:snrx_bytes=nrx_bytes,${scale},/" \
'CDEF:nrx_pkts=rx_pkts,-1,*' \
'CDEF:nrx_err=rx_err,-1,*' \
'CDEF:nrx_drop=rx_drop,-1,*' \
'AREA:tx_pkts#3CA0D0bb:TX Pakets' \
'GPRINT:tx_pkts:AVERAGE:Avg. %6.1lf%s' \
'AREA:nrx_pkts#3CA0D0bb:RX Pakets' \
'GPRINT:rx_pkts:AVERAGE:Avg. %6.1lf%s\l' \
'AREA:stx_bytes#70ED3Bbb:TX Bytes ' \
'GPRINT:tx_bytes:AVERAGE:Avg. %6.1lf%s' \
'AREA:snrx_bytes#70ED3Bbb:RX Bytes ' \
'GPRINT:rx_bytes:AVERAGE:Avg. %6.1lf%s\l' \
'LINE1:tx_pkts#3CA0D0' \
'LINE1:nrx_pkts#3CA0D0' \
'LINE1:stx_bytes#70ED3B' \
'LINE1:snrx_bytes#70ED3B' \
'LINE1:tx_err#F73E5F:TX Errors' \
'GPRINT:tx_err:AVERAGE:Avg. %6.1lf%s' \
'LINE1:nrx_err#F73E5F:RX Errors' \
'GPRINT:rx_err:AVERAGE:Avg. %6.1lf%s\l' \
'LINE1:tx_drop#F76F87:TX Drops ' \
'GPRINT:tx_drop:AVERAGE:Avg. %6.1lf%s' \
'LINE1:nrx_drop#F76F87:RX Drops ' \
'GPRINT:rx_drop:AVERAGE:Avg. %6.1lf%s\l' \
"COMMENT:[$(date "+%F %T" | sed 's/:/\\:/g')]\r"
done

rrdtool graph ${outdir}/graph_freifunk_${time}.png \
--title "Network I/O Freifunk" \
--vertical-label Bytes/sec \
--width $width \
--height $height \
--start end-${time} \
--upper-limit ${limit} --lower-limit -${limit} --rigid \
--imginfo '%s %lu x %lu' \
"DEF:txb_eth1=if_eth1.rrd:tx_bytes:AVERAGE" \
"DEF:rxb_eth1=if_eth1.rrd:rx_bytes:AVERAGE" \
"DEF:txb_mesh=if_mesh-vpn.rrd:tx_bytes:AVERAGE" \
"DEF:rxb_mesh=if_mesh-vpn.rrd:rx_bytes:AVERAGE" \
"DEF:txb_wlan0=if_wlan0.rrd:tx_bytes:AVERAGE" \
"DEF:rxb_wlan0=if_wlan0.rrd:rx_bytes:AVERAGE" \
'CDEF:nrxb_eth1=rxb_eth1,-1,*' \
'CDEF:nrxb_mesh=rxb_mesh,-1,*' \
'CDEF:nrxb_wlan0=rxb_wlan0,-1,*' \
'CDEF:ntxb_wlan0=txb_wlan0,-1,*' \
'AREA:txb_eth1#41DB00bb:TX Bytes eth1' \
'GPRINT:txb_eth1:AVERAGE:Avg. %6.1lf%s' \
'AREA:nrxb_eth1#41DB00bb:RX Bytes eth1' \
'GPRINT:rxb_eth1:AVERAGE:Avg. %6.1lf%s\l' \
'AREA:txb_mesh#086FA1bb:TX Bytes mesh' \
'GPRINT:txb_mesh:AVERAGE:Avg. %6.1lf%s' \
'AREA:nrxb_mesh#086FA1bb:RX Bytes mesh' \
'GPRINT:rxb_mesh:AVERAGE:Avg. %6.1lf%s\l' \
'AREA:rxb_wlan0#EF002Abb:RX Bytes wlan' \
'GPRINT:rxb_wlan0:AVERAGE:Avg. %6.1lf%s' \
'AREA:ntxb_wlan0#EF002Abb:TX Bytes wlan' \
'GPRINT:txb_wlan0:AVERAGE:Avg. %6.1lf%s\l' \
'LINE1:txb_eth1#41DB00' \
'LINE1:txb_mesh#086FA1' \
'LINE1:rxb_wlan0#EF002A' \
'LINE1:nrxb_eth1#41DB00' \
'LINE1:nrxb_mesh#086FA1' \
'LINE1:ntxb_wlan0#EF002A' \
"COMMENT:[$(date "+%F %T" | sed 's/:/\\:/g')]\r"

done;

####
# optional: copy files to public web server

