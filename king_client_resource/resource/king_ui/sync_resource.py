#coding:utf-8

import os
import commands

HOME = os.getenv("HOME")
SSH_PWD_FILE = HOME + "/.ssh/id_rsa"
RSYNC_SSH_CMD = "rsync -vzrtopg --recursive -e 'ssh -i %s -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null'" % SSH_PWD_FILE

def rsync_with_ssh(src, dst, ip, exclude_file="", delete=True):
	cmd = ""
	if delete:
		dst = "server@%s:%s" % (ip, dst)
		cmd = RSYNC_SSH_CMD + " --delete " + src + " " + dst
	else:
		dst = "server@%s:%s" % (ip, dst)
		cmd = RSYNC_SSH_CMD + " " + src + " " + dst

	if exclude_file:
		cmd = cmd + " --exclude-from " + exclude_file

	return cmd

if __name__ == "__main__":
	src = "./*"
	dst = "/home/server/king_client/resource/king_ui"
	ip = "120.78.13.193"
	cmd = rsync_with_ssh(src, dst, ip, "exclude.list", False)
	os.system(cmd)

	SSHCMD = "ssh -l server -i server_key -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oConnectTimeout=30 -q "
	cmd = "cd /home/server/king_client && python tools/publish_web.py mobile debug"
	remote_cmd = "%s %s -- \"%s\"" % (SSHCMD, "120.78.13.193", cmd)
	status, output = commands.getstatusoutput(remote_cmd)
	print str(status) + "  " + str(output)


