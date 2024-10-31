#!/bin/bash
# Version: 1.1
# SPDX-License-Identifier: BSD-2-Clause
#
# Dependencies: nohup, setsid, dirname.
#
# Usage:
#   export PIDFILE=/var/run/prog.pid
#   ./sv.simple.sh start [OTHER_ARGS]
#   ./sv.simple.sh stop 

case "$1" in
start)
	(nohup setsid $0 RUN "$@" >/dev/null 2>&1 &)
	exit
	;;
stop)
	if ! [[ -f "$PIDFILE" ]]; then
		echo "Already stopped" >&2
		exit
	fi
	
	pid=`cat "$PIDFILE"`
	for p in `pgrep -x sv.simple.sh`; do
		if [[ $pid = $p ]]; then
			kill -TERM -$pid
		fi
	done
	# Comment this while if you don't want to wait the daemon completely
	# stopped.
	while [ -f "$PIDFILE" ]; do
		sleep 1s
	done
	#rm -f "$PIDFILE"
	exit
	;;
RUN)
	;;
*)
	echo "Unknown action: $1" >&2
	exit 1
	;;
esac

shift
shift

if [ "$PIDFILE" ]; then
	echo $$ > "$PIDFILE"
fi

hdl_sigterm()
{
	trap - SIGTERM
	rm -f "$PIDFILE"
	kill -TERM -$$
}

# If you want to use extended version, then just rename this to hdl_sigterm
# and hdl_sigterm above to _hdl_sigterm.
# DO NOT FORGET to change every CMD to daemon name.
hdl_sigterm_ext()
{
	local wait_sec=70

	pkill -P $$ -TERM CMD
	while pgrep -P $$ CMD >/dev/null; do
		sleep 2s
		((wait_sec-=2))
		if [[ $wait_sec -le 0 ]]; then
			pkill -P $$ -KILL CMD
			break
		fi
	done
	trap - SIGTERM
	rm -f "$PIDFILE"
	kill -TERM -$$
}

trap hdl_sigterm SIGTERM
trap hdl_sigterm SIGINT
trap hdl_sigterm SIGHUP
trap hdl_sigterm SIGQUIT

#cd `dirname $0`

while true; do
	# REPLACE THE NEXT LINE WITH YOUR COMMAND
	# KEEP & at the end
	sleep 1m &
	wait
	sleep 1s
done
