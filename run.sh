#!/usr/bin/env bash

GREEN='\033[32m'
RED='\033[91m'
NC='\033[0m'

ARG=$1
PWD=`pwd`
LOGFILE='/tmp/chef_client_why_run.log'

set_ownership() {
	sudo chown -R $USER. .
}

get_os_name() {
	cat /etc/os-release|head -1|grep -o '".*"'|sed 's/"//g'
}

init() {
	printf "${GREEN}[INFO] Create a symlink to /opt/chef-solo${NC}\n"
	sudo ln -s $PWD /opt/chef-solo
#	printf "${GREEN}[INFO] Checking system type ...${NC}\n"
#	if [ $(get_os_name) == "Linux" ]; then
#		if [ `cat /etc/os-release|head -1|grep -o '".*"'|sed 's/"//g'` == "Ubuntu" ]
#			
#	elif [ $(get_os_name) == "Darwin" ]; then
#
#	fi
}

berks_vendor() {
	if [ -f Berksfile.lock ]; then
		rm Berksfile.lock
	fi
	sudo berks vendor
	set_ownership
}

why_run() {
	#berks_vendor
	sudo -H chef exec chef-solo -W -c $PWD/solo.rb -j $PWD/attributes.json|sudo tee $LOGFILE
}

chef_run() {
	#berks_vendor
	sudo chef exec chef-solo -c $PWD/solo.rb -j $PWD/attributes.json
}

exec_test() {
	chef exec inspec exec cookbooks/workstation/test/smoke/default/
	chef exec inspec exec cookbooks/sublime_text/test/smoke/default/
}

help() {
	echo "Usage: run.sh [--help] [--vendor] [--whyrun] [--test]"
	echo " "
	echo "--help 		| -h	 Print this message."
	echo "--init	| -I 	 Initialize the chef-solo setup."
	echo "--vendor 	| -V	 Vendoring dependencies."
	echo "--whyrun 	| -W	 Execute a Why Run."
	echo "--test 		| -T	 Execute test suite."
}


if [[ $ARG == '--help' || $ARG == '-h' ]]
then
	help
elif [[ $ARG == '--init' || $ARG == '-I' ]]
then
	init
elif [[ $ARG == '--vendor' || $ARG == '-V' ]]
then
	printf "${GREEN}[INFO] Cleaning berks-cookbooks folder${NC}\n"
	printf "${GREEN}[INFO] Cleaning Berksfile.lock file${NC}\n"
	rm Berksfile.lock
	rm -rf berks-cookbooks/*
	printf "${GREEN}[INFO] Vendoring cookbooks${NC}\n"
	berks_vendor
elif [[ $ARG == '--whyrun' || $ARG == '-W' ]]
then
	printf "${GREEN}[INFO] Execute only a Why Run ...${NC}\n"
	why_run
elif [[ $ARG == '--test' || $ARG == '-T' ]]
then
	printf "${GREEN}[INFO] Execute only tests ...${NC}\n"
	exec_test
else
	printf "${GREEN}[INFO] Execute a Why Run ...${NC}\n"
	why_run
	if [[ $? == 0 ]]
	then
		updated_resources=`tail -1 $LOGFILE|awk '{print $4}'|cut -d '/' -f 1`
		if [[ $updated_resources == 0 ]]
		then
			printf "\n${GREEN}[INFO] No resources to update, no need to converge.${NC}\n"
		else
			printf "\n${GREEN}[INFO] Why Run successfull, let's converge ...${NC}'\n"
			chef_run
			exec_test
		fi
	else
		printf "\n${RED}[ERROR] Why Run encountered errors !${NC}\n"
		exit 1;
	fi
fi
