# AzCli "run-command invoke" on all VMs through all subscriptions

The **script.sh** in this repo will do the following:

* iterate through all subscriptions the user running the script has access to
* will check the permissions of the user on each subscription
* if permissions allow, it will further check each resourcegroup available in the subscription for available VMs.
* if it finds any VM and the VM is in running state, it will check the Distribution name (this will be succesful only for Linux machines)
* if the distribution on each VM matches the search string configured on line 8 of the script, it will trigger the extension on that VM.
* the extension will run the command specified on line 9 in the script.

## Prerequisites

* You need to run this via AzCli, therefore make sure [AzCli is installed](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) on your machine or you can run the script from the [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/quickstart)
* The script has a commented `"az login"`  entry, if you are not logged in to you Azure account from the AzCli, make sure to uncomment that line or just run the `az login`  command before launching the script.

## Usage:

1. Download the script.sh file:
`wget https://raw.githubusercontent.com/marinnedea/az-cli-invoke-all-subs/main/script.sh`
2. Modify the script according to your needs.

**>** Line 8: `distro="centos"`

#### Available parameters are:
 * centos
 * redhat
 * ubuntu
 * sles
 * oracle

**NOTE:** Technically, you can use the short name for any Linux distrinution deployed in your Azure subscriptions, all lowercase letters.

**>** Line 9: `commandToSend="date >> /tmp/testing.log"`

Replace the command with any other command you wish, but make sure it would work on your distribution, e.g.:

`commandToSend="yum install httpd -y && systemctl enable httpd && systemctl start httpd && firewall-cmd --zone=public --permanent --add-service=http && firewall-cmd --zone=public --permanent --add-service=https && firewall-cmd --reload "`  for RedHat/CentOS/Oracle



**Step2:** Once the changes are implemented:
* make sure the script is unix compatible: `dos2unix script.sh`
* make the script executable: `sudo chmod +x script.sh`
* run the script: `./script.sh`

### Sample output:

<img src="https://github.com/marinnedea/az-cli-invoke-all-subs/blob/main/img/sample_output.png" width="320">
