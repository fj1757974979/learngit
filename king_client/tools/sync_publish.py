#coding:utf-8

import os

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
        version = "0.0.1"
	src = "./bin-release/web/" + version + "/*"
	dst = "/var/www/html/" + version
	ip = "120.78.13.193"
	cmd = rsync_with_ssh(src, dst, ip, "", False)
	os.system(cmd)

