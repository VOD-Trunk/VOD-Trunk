import paramiko
from scp import SCPClient
import os,shutil
import time
import datetime
import csv
import xml.etree.ElementTree as ET

def copy_lgservicexml(ip, name, port, username, password):

    try:
	ssh = None
	# Create the SSH client.
	ssh = paramiko.SSHClient()
	#don't get server not found in known_hosts
	ssh.load_system_host_keys()
	ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
	ssh.connect(ip, port, username, password,banner_timeout=200,timeout=200,auth_timeout=200,allow_agent=False)

	scp = SCPClient(ssh.get_transport())
	dest_path = '/home/vod/LGServiceXML/' + name
	src_path = '/nfs/m1/procentric/procentric/system/LGService.xml'
	print("Copying files from server to local")
	scp.get(src_path, dest_path)
        if ssh is not None:
            ssh.close()
            time.sleep(5)
        return 'Success'
    except Exception as e:
        return e

def prepare_LGModelDetails(fileName,name):

    try:
	strLine=""
	tree = ET.parse(fileName)
	root = tree.getroot()
	
	for child in root:
		strLine+=name +","
		for innerChild in child:
			if innerChild.tag == "modelName":
				print(innerChild.tag,innerChild.text)
				strLine+=innerChild.text + ","

			elif innerChild.tag == "content":
				if innerChild.find('type').text == "EPK_FIRMWARE":
					print(innerChild.find('type').text)
					strLine+=innerChild.find('data').text + "; "
					print(innerChild.find('data').text)
				elif innerChild.find('type').text == "PTC_FIRMWARE":
					print(innerChild.find('type').text)
					strLine+="," + innerChild.find('data').text
					print(innerChild.find('data').text)

		strLine+="\n"
		fileDesc= open("/home/vod/LGServiceXML/LGModelDetails.csv","a")
		fileDesc.write(strLine)
		fileDesc.close()
		strLine=""

        stderr = 'Successfull'
        return stderr
    except Exception as e:
        return e


print ('Starting')
username = "root"
password = "not4dev!"
port = 22

fileDesc= open("/home/vod/LGServiceXML/LGModelDetails.csv","w")
fileDesc.write("Ship Name,Model Name,EPK Name,PTC_FIRMWARE\n")
fileDesc.close()

with open("/home/vod/properties/ip.txt") as file:
	list_ip = csv.reader(file)
	ip_dict = {name:ip  for name, ip in list_ip}
	print(ip_dict)
	for name,ip in ip_dict.iteritems():
		print 'Connecting to ',name,',IP -',ip
		stderrstring = copy_lgservicexml(ip, name, port, username, password)
                print(stderrstring)
		fileName='/home/vod/LGServiceXML/' + name + '/LGService.xml'
                stderr = prepare_LGModelDetails(fileName,name)
                print(stderr)
