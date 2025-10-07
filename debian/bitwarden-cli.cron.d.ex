#
# Regular cron jobs for the bitwarden-cli package.
#
0 4	* * *	root	[ -x /usr/bin/bitwarden-cli_maintenance ] && /usr/bin/bitwarden-cli_maintenance
