#!/bin/sh

echo "ddns running"
DDNS_CONF=/etc/ddns.conf
if [ -f $DDNS_CONF ] ; then
	chmod 777 $DDNS_CONF
	. $DDNS_CONF
else
	exit 0
fi
			
if [ $Active != "1" ] ; then
	exit 0
fi

WAN_NUM=`expr substr $1 4 2`
WanIP=`tcapi get DeviceInfo_PVC$WAN_NUM WanIP`
ddns_ipaddr=`tcapi get GUITemp_Entry2 ddns_ipaddr`
ddns_updated=`tcapi get GUITemp_Entry2 ddns_updated`
ddns_server_x=`tcapi get Ddns_Entry SERVERNAME`
ddns_server_x_old=`tcapi get GUITemp_Entry2 ddns_server_x_old`
ddns_hostname_x=`tcapi get Ddns_Entry MYHOST`
ddns_hostname_old=`tcapi get GUITemp_Entry2 ddns_hostname_old`
if [	"$WanIP" = "$ddns_ipaddr" -a \
	"ddns_server_x" = "ddns_server_x_old" -a \
	"ddns_hostname_x" = "ddns_hostname_old" -a \
	"$ddns_updated" -eq 1 ]; then
	tcapi set GUITemp_Entry2 ddns_return_code "no_change"
	exit 0
fi
if [	-n "$ddns_server_x_old" -a \
	"ddns_server_x" != "ddns_server_x_old" -o \
	-n "$ddns_server_x_old" -a \
	"ddns_hostname_x" != "ddns_hostname_old" ]; then
	rm -f /tmp/ddns.cache
fi

PROFILE_CFG=/userfs/profile.cfg
if [ -f $PROFILE_CFG ] ; then
  . $PROFILE_CFG
fi

WANIF=none
ACTIVE_INT=none

if [ "$TCSUPPORT_WAN_ATM" != "" -o "$TCSUPPORT_WAN_PTM" != "" -o "$TCSUPPORT_WAN_ETHER" != "" ]; then
	pvc_num="$1"
else
	pvc_num="0 1 2 3 4 5 6 7"
fi

EXTEND="0"
EXIT="0"

WANIF="$1"
if [ $WANIF = "none" ] ; then
#	echo "no active PVC"
#	exit 0
	echo "no active PVC but set WANIF as nas0 to develop"
	WANIF=nas8
fi		

IPUPDATE_PID=/var/run/ez-ipupdate.pid
IPUPDATE_CONF=/etc/ipupdate.conf

# ifconfig $WANIF | sed -ne 's/ *inet addr:\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\) *.*/\1/p' > /tmp/ip.tmp
# IP_USED=`cat /tmp/ip.tmp`
/userfs/bin/tcapi set GUITemp_Entry2 ddns_return_code ddns_query
/userfs/bin/tcapi set GUITemp_Entry2 ddns_cache ""
/userfs/bin/tcapi set GUITemp_Entry2 ddns_ipaddr ""
/userfs/bin/tcapi set GUITemp_Entry2 ddns_status ""
/userfs/bin/tcapi set GUITemp_Entry2 ddns_updated ""

if [ $SERVERNAME = "WWW.ASUS.COM" ]; then
/userfs/bin/ez-ipupdate -c $IPUPDATE_CONF -i $WANIF -F $IPUPDATE_PID -e /sbin/ddns_updated -b /tmp/ddns.cache -A 2 -s ns1.asuscomm.com
else
#/userfs/bin/ez-ipupdate -c $IPUPDATE_CONF -i $WANIF -d -F $IPUPDATE_PID -P 60 -p 1
/userfs/bin/ez-ipupdate -c $IPUPDATE_CONF -i $WANIF -F $IPUPDATE_PID -e /sbin/ddns_updated -b /tmp/ddns.cache
fi

# echo $$ >$IPUPDATE_PID

#while true
#do
#	sleep 1
#	ifconfig $WANIF | sed -ne 's/ *inet addr:\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\) *.*/\1/p' > /tmp/ip.tmp
# 	IP_NEW=`cat /tmp/ip.tmp`
# 
# 	if [ "$IP_NEW" = "$IP_USED" ] ; then
# 			sleep 10
# 	else
# 			/userfs/bin/ez-ipupdate -c $IPUPDATE_CONF -i $WANIF &
# 			echo $$ >$IPUPDATE_PID
# 			IP_USED="$IP_NEW"
# 	fi
# done


