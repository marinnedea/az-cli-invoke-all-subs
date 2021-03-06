#!/bin/bash

#########################################################################################################
# Description:  Find Linux VMs in all Subscriptions and run script on them    				#
# Author: 	Marin Nedea										#
# Created: 	JunDecember 16th, 2020 									#
# Usage:  	Just run the script with sh (e.g. sh script.sh)  or chmod +x script.sh && ./script.sh   #
# Requires:	AzCli 2.0 installed on the machine you're running this script on			#
# 		https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest	#
# 		If enabled, you can run it through the bash Cloud Shell in your Azure Portal page.	#
#########################################################################################################

# Login to Az Cli
#az login

# Declare the distribution you want to match on line 19. Possible values are redhat, centos, oracle, sles, barracuda, etc.. etc..
# For other distributions (you can look for "ubuntu"), you just need to change the command sent through the 
# extension - see line 20 and make ure is working on the ditribution you are targeting.
distros="centos redhat"
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

						# Get the VM status (running or stopped/deallocated)
						vmState=$(az vm show -g ${rgName} -n ${vmName} -d --query powerState -o tsv);

						# If VM is running, check the distribution on the VM (this will fail for Windows)
						if [[ "${vmState}" == "VM running" ]]; then
							distroname=$(az vm  get-instance-view  --resource-group ${rgName} --name ${vmName} --query instanceView -o table | tail -1 | awk '{print $2}');
							
							# If the distro name is in the list we originaly defined, install our extension
							if [[ " $distros " =~ .*\ $distroname\ .* ]]; then
								echo "--- VM ${vmName} is running ${distroname} which is in the distro list: ${distros}."
								echo "--- Running the extension on this machine"
								
								# Install the command invoke extension and run the script
								az vm run-command invoke --verbose -g ${rgName} -n ${vmName} --command-id RunShellScript --scripts "${commandToSend}"
								echo "DONE"
							else
								echo "--- VM ${vmName} is running ${distroname} which is not in the distro list: ${distros}. Skipping"
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
