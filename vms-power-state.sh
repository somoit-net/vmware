#!/bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'        # Green
YELLOW='\033[0;33m'       # Yellow

NC='\033[0m' # No Color

print_help()
{
echo "	vms-power-state.sh"
echo "		prints this help"
echo 
echo "	vms-power-state.sh list"
echo "		prints the list of VMs and powering state"
echo
echo " 	vms-power-state.sh <poweron|shutdown|poweroff> <VM_NAME>"
echo "		poweron: powers on virtual machine"
echo "		shutdown: shutdowns guest of the virtual machine"
echo "		poweroff: powers off virtual machine"
}

list_machines()
{
	VMS=$(vim-cmd vmsvc/getallvms | egrep "^[0-9]" )
	IFS=$'\r\n'
	for VM in $(echo "$VMS")
	do
		VM_NAME=$(echo "$VM" | awk '{ print $2 }')
		VM_ID=$(echo "$VM" | awk '{ print $1 }')
		VM_POWERSTATE=$(vim-cmd vmsvc/power.getstate $VM_ID | tail -1)
	
		case $VM_POWERSTATE in
			"Powered on")
				COLOR=$GREEN;;
			"Powered off")
				COLOR=$RED;;
			*)
				COLOR=$YELLOW;
		esac
		printf "%b%-15s%b%-4s%s\n" "${COLOR}" "(${VM_POWERSTATE})" "$NC" "${VM_ID}" "${VM_NAME}"
	done
}

get_machine_id()
{
	IFS=$'\r\n'
	VMS=$(vim-cmd vmsvc/getallvms | egrep "^[0-9]")
        for VM in $(echo "$VMS")
        do
		VM_ID=$(echo "$VM" | awk '{ print $1 }')
                VM_NAME=$(echo "$VM" | awk '{ print $2 }')
		[ "$VM_NAME" == "$1" ] && echo $VM_ID && return
	done
}

poweron_vm()
{
        if [ "$1" == "ALL" ]
        then
                IFS=$'\r\n'
                for VM in $(vim-cmd vmsvc/getallvms | egrep "^[0-9]" )
                do
			VM_ID=$(echo "$VM" | awk '{ print $1 }')
                        VM_NAME=$(echo "$VM" | awk '{ print $2 }')
                        VM_POWERSTATE=$(vim-cmd vmsvc/power.getstate $VM_ID | tail -1)
                        if [ "$VM_POWERSTATE" == "Powered on" ]
                        then
                                echo "[$VM_ID] $VM_NAME already powered on"
                        else
                                vim-cmd vmsvc/power.on $VM_ID
                                [ $? -eq 0 ] && echo "[$VM_ID] $VM_NAME powering on"
                        fi
		done
	else
		VM_ID=$(get_machine_id "$1")
		[ -z $VM_ID ] && echo "VM not found" && exit
		vim-cmd vmsvc/power.on $VM_ID

		[ $? -eq 0 ] && echo "Command run succesfully"
	fi
}

shutdown_vm()
{	
	if [ "$1" == "ALL" ]
	then
		IFS=$'\r\n'
	        for VM in $(vim-cmd vmsvc/getallvms | egrep "^[0-9]" )
	        do
	                VM_ID=$(echo "$VM" | awk '{ print $1 }')
	                VM_NAME=$(echo "$VM" | awk '{ print $2 }')
	                VM_POWERSTATE=$(vim-cmd vmsvc/power.getstate $VM_ID | tail -1)
			if [ "$VM_POWERSTATE" != "Powered on" ]
			then
				echo "[$VM_ID] $VM_NAME is not powered on"
			else
				vim-cmd vmsvc/power.shutdown $VM_ID
				[ $? -eq 0 ] && echo "[$VM_ID] $VM_NAME shutting down"
	                fi


	        done
	else		
		VM_ID=$(get_machine_id "$1")
		[ -z $VM_ID ] && echo "VM not found" && exit
		vim-cmd vmsvc/power.shutdown $VM_ID
		[ $? -eq 0 ] && echo "Command run succesfully"
	fi
}

poweroff_vm()
{
	VM_ID=$(get_machine_id "$1")
	[ -z $VM_ID ] && echo "VM not found" && exit
	vim-cmd vmsvc/power.off $VM_ID

	[ $? -eq 0 ] && echo "Command run succesfully"
}

[ $# -eq 1 -a "$1" == "list" ] && list_machines && exit 0
if [ $# -eq 2 ]
then
	case "$1" in
		"poweron")
                	poweron_vm $2;;
                "shutdown")
                        shutdown_vm $2;;
                "poweroff")
                        poweroff_vm $2;;
		*)
			print_help $2;;
                esac
	exit
fi
print_help

