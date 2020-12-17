#!/bin/bash

# Login to Az Cli
#az login

# Declare the distribution you want to match. Possible values are "redhat", "centos"
# For other distributions (you can look for "ubuntu"), you also need to change the command sent through the extension - see line 9
distro="centos"
commandToSend="date >> /tmp/testing.log"

# Find all subscriptions:
for subs in $(az account list -o tsv | awk '{print $3}'); do
	# Find current logged in username 
	username=$(az account show --query user.name --output tsv)
	
	# Select subsctiption 1 by 1
	az account set --subscription ${subs}		
	echo "Cheching subscription ${subs} :"
	
	# Check running account read permissions over the selected subscription and send output to /dev/null to avoid screen clogging with unnecessary data.
	# Info: https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-list-cli#list-role-assignments-for-a-user
	# If user has permissions, the script will continue, else will skip this subscription and show a message on the screen.
	if az role assignment list --all --assignee ${username} --query [].roleDefinitionName  > /dev/null 2>&1; then 	
		# List all resource groups in selected subscription
		rgarray="$(az group list  --query '[].name' -o tsv)"		
		#check if array is empty
		if [ ! -z "${rgarray}" ]; then
			for rgName in ${rgarray}; do				
			echo "- Checking Resource Group: ${rgName}"			
			# List all VMs for RG $rgName
			vmarray="$(az vm list -g ${rgName} --query '[].name' -o tsv)"			
			# check if VM array is empty
			if [ ! -z "${vmarray}" ]; then											
				for vmName in ${vmarray}; do	
					echo "-- Found VM ${vmName}.Checking it..."									
					vmState=$(az vm show -g ${rgName} -n ${vmName} -d --query powerState -o tsv);
					if [[ "${vmState}" == "VM running" ]]; then
						distroname=$(az vm  get-instance-view  --resource-group ${rgName} --name ${vmName} --query instanceView -o table | tail -1 | awk '{print $2}');
						echo "--- VM ${vmName} is running ${distro}"
						if [[ "${distroname}" == "${distro}"  ]]; then															
							echo "--- Running the extension on this machine"
							# Install the command invoke extension and run the script to downgrade the needed package
							az vm run-command invoke --verbose -g ${rgName} -n ${vmName} --command-id RunShellScript --scripts "${commandToSend}"				
						else
							echo "--- VM ${vmName} is not a ${distro} one. Skipping"
						fi
					else
						echo "--- The VM ${vmName} in ${rgName} is ${vmState} state"
						echo "--- Cannot check OS type. Skipping."
					fi
				done
			else
				echo "-- Found no VMs in this Resource Group"
				echo ""
				echo ""	
			fi
			done
		else 
		 echo "-- Found no Resource Group in this Subscription"
		 echo ""
		 echo ""	
		fi
	else
		echo "- You do not have the necessary permissions on subscription ${subs}.
		More information is available on https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-list-cli#list-role-assignments-for-a-user"
		echo ""
		echo ""		
	fi
done	
exit 0
