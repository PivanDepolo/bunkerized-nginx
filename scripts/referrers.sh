#!/bin/sh

# load some functions
. /opt/entrypoint/utils.sh

# save old conf
cp /etc/nginx/referrers.list /cache

# generate new conf
BLACKLIST="$(curl -s https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/_generator_lists/bad-referrers.list | sed 's:\.:%\.:g;s:\-:%\-:g')"
if [ "$?" -ne 0 ] ; then
	job_log "[BLACKLIST] can't update referrers list"
	echo -n "" > /tmp/referrers.list
else
	echo -e "$BLACKLIST" > /tmp/referrers.list
fi

# if we are running nginx
if [ -f /tmp/nginx.pid ] ; then
	RELOAD="/usr/sbin/nginx -s reload"
# if we are in autoconf
elif [ -S /tmp/autoconf.sock ] ; then
	RELOAD="/opt/entrypoint/reload.py"
fi

# check number of lines
lines="$(wc -l /tmp/referrers.list | cut -d ' ' -f 1)"
if [ "$lines" -gt 1 ] ; then
	mv /tmp/referrers.list /etc/nginx/referrers.list
	job_log "[BLACKLIST] referrers list updated ($lines entries)"
	if [ "$RELOAD" != "" ] ; then
		$RELOAD > /dev/null 2>&1
		if [ "$?" -eq 0 ] ; then
			cp /etc/nginx/referrers.list /cache
			job_log "[NGINX] successfull nginx reload after referrers list update"
		else
			cp /cache/referrers.list /etc/nginx
			job_log "[NGINX] failed nginx reload after referrers list update fallback to old list"
			$RELOAD > /dev/null 2>&1
		fi
	else
		cp /etc/nginx/referrers.list /cache
	fi
else
	job_log "[BLACKLIST] can't update referrers list"
fi

rm -f /tmp/referrers.list 2> /dev/null
