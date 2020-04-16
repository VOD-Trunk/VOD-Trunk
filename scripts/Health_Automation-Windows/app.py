###############################################################################
# To DOs :                                                                    #
# 1. Add logging instead of print                                             # 
###############################################################################

import paramiko
import os,shutil
import time
import datetime
import subprocess
import time
import csv

list1 = []
list2 = []
f = open('C:\Users\E01807\Desktop\HealthCheckCode\errors','w')

def execute_ssh_command(ip, name, port, username, password, command):
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

        ssh.connect(ip, port, username, password)
        stdin, stdout, stderr = ssh.exec_command(command)


        # Wait for the command to terminate
        while not stdout.channel.exit_status_ready() and not stdout.channel.recv_ready():
            time.sleep(1)

        stdoutstring = stdout.readlines()
        stderrstring = stderr.readlines()
        return stdoutstring, stderrstring

    except:
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
        fname = 'C:\Users\E01807\Desktop\HealthCheckCode\Health_Reports/' + nfname
        print(fname)
        f = open(fname,'w')
        for d in data:
            #remove ^M characters
            line = d.rstrip()
            f.write(line+ '\n')
    finally:
        f.close()

print ('Starting')
username = "root"
password = "not4dev!"
port = 22
command = "/root/bin/health_check.sh"
#'Diamond':'172.29.204.193',

folder = 'C:\Users\E01807\Desktop\HealthCheckCode\Health_Reports/'
for the_file in os.listdir(folder):
    file_path = os.path.join(folder, the_file)
    try:
        if os.path.isfile(file_path):
           os.unlink(file_path)
        #elif os.path.isdir(file_path): shutil.rmtree(file_path)
    except Exception as e:
        print(e)

with  open("IPs.txt") as file:
	list_ip = csv.reader(file)
	ip_dict = {name:ip  for name, ip in list_ip}

	for name,ip in ip_dict.iteritems():
		print 'Connecting to ',name,',IP -',ip
		(stdoutstring, stderrstring) = execute_ssh_command(ip, name, port, username, password, command)

		if stdoutstring:
			fn = get_file_name(name)
			print 'Writing to file ',fn
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

#f.write("Could not ssh to following ships :")
f.write('{}'.format(list1))
#f.write(" and Could not fetch health reports for following ships :")
#f.write('{}'.format(list2))
f.close()

#time.sleep(5)
#subprocess.call([r'C:\Users\E01807\Desktop\HealthCheckCode\EmailGenerator.bat'])