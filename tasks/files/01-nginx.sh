#!/bin/bash

# 01-nginx.sh (Ver.20230216)

# place into:
# /etc/letsencrypt/renewal-hooks/deploy/01-nginx.sh
# more info:
# https://tcpip.wtf/en/letsencrypt-auto-nginx-reload-on-renew-hook.htm

set -e
unset TMPFILE
TMPFILE=$(mktemp "/tmp/${0##*/}.tmp.XXXXXX") || { echo "Failed to create temp file"; exit 1; }

# tmpfile処理 https://fumiyas.github.io/2013/12/06/tempfile.sh-advent-calendar.html
func_atexit() {
	[[ -n ${TMPFILE-} ]] && rm -r "${TMPFILE}"
}
trap func_atexit EXIT
trap 'rc=$?; trap - EXIT; func_atexit; exit $?' INT PIPE TERM

# TESTING Config
/usr/sbin/nginx -t 1>>${TMPFILE} 2>>${TMPFILE}
if grep -q "test is successful" ${TMPFILE}
then
		# Config OK
		echo Config OK, reloading...
		if $(pidof systemd >/dev/null)
		then
				systemctl reload nginx
		else
				/etc/init.d/nginx reload
		fi
else
		echo Config ERROR!
fi

# rm ${TMPFILE}>/dev/null 2>/dev/null
