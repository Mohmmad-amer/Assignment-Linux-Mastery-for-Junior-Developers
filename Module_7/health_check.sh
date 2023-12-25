#!/bin/bash

#function to check server status
check_service(){
	service_name=$1
	timestamp=$(date "+%Y-%m-%d %H:%M:%S")
	status=$(systemctl is-active $service_name 2>/dev/null)
	if [ "$status" == "active" ]; then
		
		echo "$service_name is running."
		echo "$timestamp - $service_name is running." >> health.log
	else
		echo "$service_name is down."
		echo "$timestamp - $service_name is down." >> health.log
	fi
}
check_service_h(){
	check_service ssh
	check_service http
	check_service https
	check_service mysql
	echo "______________________________________________" >> health.log
}

check_threshold(){
	Threshold=33
	parti=$(df -h  | tail -n +2 | awk -v threshold=$Threshold '$5 > threshold {print $1}')
	timestamp=$(date "+%Y-%m-%d %H:%M:%S")
	echo "Disk usage check at $timestamp:" >> health.log
	if [ -n "$parti" ] ; then
		echo "this filesystem above the $Threshold% use "  >> health.log
		echo "$parti"  >> health.log
	else
		echo "all Diske usage below Threshold: $Threshold% " >> health.log
	fi
	echo "done you can see the result at health.log"
	echo "______________________________________________" >> health.log
}

check_read_only_files(){
	#read only files name
	timestamp=$(date "+%Y-%m-%d %H:%M:%S")
	read_only=$(mount -v | awk '$4 !/ro/ {print $3}')
	echo "check for read_only files at $timestamp" >> health.log
	if [ -z "$read_only" ] ; then
		echo "no read_only files system found." >> health.log
	else 
		echo "read_only file system found." >> health.log
		echo "$read_only" >> health.log
	fi
	echo "______________________________________________" >> health.log
}

check_process(){
	cpu=1
	memory_max=2000000
	process_info=$(ps axo pid,comm,%cpu,%mem --sort=%cpu)
	timestamp=$(date "+%Y-%m-%d %H:%M:%S")	
	echo "checking cpu and memo use" >> health.log
	echo "$process_info" | tail -n +2 |while read -r line; do
		timestamp=$(date "+%Y-%m-%d %H:%M:%S")
		pid=$(echo "$line" | awk ' { print $1}')
		command=$(echo "$line" | awk ' { print $2}')
		cpu_usage=$(echo "$line" | awk ' { print $3}')
		memory_usage=$(echo "$line" | awk ' { print $4}')
		
		if (( $(echo "$cpu_usage > $cpu" | bc -l) )); then
		echo "$timestamp Hight cpu usage in pid = $pid,COMMAND $command,cpu=%$cpu_usage" >> health.log
		fi
		if (( $(echo "$memory_usage > $memory_max " | bc -l) )) ; then
			echo "$timestamp hight memorey usege found in pid=$pid,COMMAND $command,memory=$memory_usage" >> health.log
		fi
	done
		echo "finshed check process" >> health.log
		echo "______________________________________________" >> health.log
	}

check_error_warnning(){

	find "/var/log/" -type f -print0 | while IFS= read -r -d '' log_file ; do 
		echo "anlayzig $log_file for error or warrnings"
		error=$(grep -iE 'error|warning' "$log_file")
		if [ -n "$error" ] ; then 
			timestamp=$(date "+%Y-%m-%d %H:%M:%S")
			echo "$timestamp: error message for file $log_file" >> health.log
			echo "$error" >> health.log
			echo "***********" >> health.log
		fi
	done
	echo "______________________________________________" >> health.log
}


#secrity check
failed_login(){

	failed_attempts=$(cat /var/log/auth.log | grep -a 'Failed password')
	timestamp=$(date "+%Y-%m-%d %H:%M:%S")
	echo "unauthorized ssh login Attempts log in check at $timestamp" >> health.log
	echo "$failed_attempts" | awk ' ' '{print "Username: "$9" ,Date: $1 $2 ,Time : $3 $4}' >> health.log
	echo -e "\nAdditional Information" >> health.log
	echo "total failed attempts : $(echo "$failed_attempts" | wc -l)" >> health.log
	echo "users with failed attempts : $(echo "$failed_attempts"| awk -F ' ' '{print$9}' | sort |  uniq)" >> health.log
	echo "done you can see result at health.log"
	
 }
 
port_check(){
	# Set the target host and port range
	target_host="10.0.2.15"
	port_range="1-1000"  # Modify the port range as needed
	timestamp=$(date "+%Y-%m-%d %H:%M:%S")

	# Set the list of expected open ports (space-separated)
	expected_ports="22 80 443"

	# Perform the port scan
	open_ports=$(nmap -p- --open --min-rate=1000 $target_host | grep -E '^ *[0-9]' | awk '{print $1}')

	# Check for unexpected open ports
	unexpected_ports=""
	for port in $open_ports; do
	    if ! echo "$expected_ports" | grep -q "$port"; then
		unexpected_ports+="$port"
	    fi
	done

	# Report the results
	echo "$timestamp open port check" >> health.log
	echo "Open ports on $target_host: $open_ports" >> health.log
	if [ -n "$unexpected_ports" ]; then
	    echo "Unexpected open ports: $unexpected_ports" >> health.log
	else
	    echo "No unexpected open ports found." >> health.log
	fi
	echo "_________________" >> health.log
}



while true;do
	echo "health check menu"
	echo "1 to preform check_service_h"
	echo "2 to preform check_threshold"
	echo "3 to preform check_read_only_files"
	echo "4 to preform check_process"
	echo "5 to preform check_error_warnning"
	echo "6 for failed log in"
	echo "7 for port_check"
	echo "8 to exit"
	read -p "enter your choice 1 - 8: " choice
	case $choice in
		1)check_service_h ;;
		2)check_threshold ;;
		3)check_read_only_files ;;
		4)check_process ;;
		5)check_error_warnning ;; 
		6)failed_login ;; 
		7)port_check ;;
		8) echo "exiting the script"; exit ;;
	esac
done


		
		
		





