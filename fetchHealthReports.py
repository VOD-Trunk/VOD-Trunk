import paramiko
import os,shutil
import time
import datetime
import subprocess
import time
import csv
import sys
import json
import ast
import base64

workspace = sys.argv[1]

folders = ['Health_Reports','logs','tmp']

for folder in folders:

	path = os.path.join(workspace,folder)
	if os.path.isdir(path) != True:
		os.makedirs(path)
	else:
		directory = workspace + '/' + folder + '/'
		for the_file in os.listdir(directory):
			file_path = os.path.join(directory, the_file)
			try:
				if os.path.isfile(file_path):
					os.unlink(file_path)
			except Exception as e:
				print(e)

paramiko_log_file = workspace + '/logs/paramiko.log'

fp = open(paramiko_log_file,'w+')

error_log_file = workspace + '/logs/errors'


paramiko.util.log_to_file (paramiko_log_file)
list1 = []
list2 = []
f = open(error_log_file,'w+')

def execute_ssh_command(ip, name, port, username, serverPassword, command):
	"""
	Executes the supplied command by opening a SSH connection to the supplied host
	on the supplied port authenticating as the user with supplied username and supplied password.
	:rtype: tuple consisting of the output to standard out and the output to standard err as produced
	by the command
	"""
	ssh = None
	try:
		# Create the SSH client.
		ssh = paramiko.SSHClient()

		#don't get server not found in known_hosts
		ssh.load_system_host_keys()
		ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

		ssh.connect(ip, port, username, serverPassword,banner_timeout=500,timeout=500)
		stdin, stdout, stderr = ssh.exec_command(command)


		# Wait for the command to terminate
		while not stdout.channel.exit_status_ready() and not stdout.channel.recv_ready():
			time.sleep(1)

		stdoutstring = stdout.readlines()
		stderrstring = stderr.readlines()
		return stdoutstring, stderrstring

	except Exception as e:

		print(e)

		stdoutstring = ''
		stderrstring = 'Could not connect'
		return stdoutstring, stderrstring


	finally:
		if ssh is not None:
			# Close client connection.
			ssh.close()


def get_file_name(server):
	"""
	Generates a file name based on the server name provided by adding current timestamp.
	"""
	ts = time.gmtime()
	st = time.strftime('%Y-%m-%d-%H-%M-%S',ts)
	st = server+"_"+st
	return st

def write_to_file(data,nfname):
	"""
	Writes the supplied data to file name fname, by default file is created in current directory
	if a different path is required fname should have that.
	It is assumed that data has lines and treated accordingly.
	"""
	try:
		fname = workspace + '/Health_Reports/' + nfname
		print(fname)
		f = open(fname,'w')
		for d in data:
			#remove ^M characters
			line = d.rstrip()
			f.write(line+ '\n')
	finally:
		f.close()

print ('Starting')

jenkinsconfig_path = workspace + "/jenkinsconfig.json"

with open(jenkinsconfig_path) as file1:
	r = json.load(file1)
	ipaddr_json = ast.literal_eval(json.dumps(r))

	ip_dict = ipaddr_json["jenkins"]["environments"]["PRODUCTION"][0]

	username = "root"
	password = ipaddr_json["jenkins"]["environments"]["PRODUCTION"][1]["pwd"]
	port = 22
	command = "/root/bin/health_check.sh"

	base64_bytes = password.encode('ascii')
	message_bytes = base64.b64decode(base64_bytes)
	serverPassword = str(message_bytes.decode('ascii'))
	serverPassword = serverPassword.replace("\n", "")
	serverPassword = serverPassword.replace(" ", "")

	print(serverPassword)

	for name,ip in ip_dict.items():
		name = name.replace("'", "")
		ip = ip.replace("'", "")
		if name == "NA":
			continue
		print('Connecting to ',name,',IP -',ip)
		(stdoutstring, stderrstring) = execute_ssh_command(ip, name, port, username, serverPassword, command)

		if stdoutstring:
			fn = get_file_name(name)
			print('Writing to file ',fn)
			write_to_file(stdoutstring,fn)

		if stderrstring:
			for e in stderrstring:
				str = ""
				str = str + e
				if "health_check.sh" in str:
					print( str )
					list1.append(name)
			if "Could not connect" in stderrstring:
				print( stderrstring )
				list1.append(name)

f.write('{}'.format(list1))
f.close()
fp.close()