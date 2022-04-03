#!/bin/bash

# Define Output Colors
Blue='\033[0;94m'
Green='\033[0;92m'
Red='\033[0;91m'
Purp='\033[0;95m'
NC='\033[0m'

# Function to print progress bar
progBar() {
	printf "${Purp}"
	i=25
	while :
	do
		# Write Symbols out
		for i in `seq 0 $i`
		do
			echo -n "#"
			sleep 0.1
		done

		# Delete Symbols back
		for i in `seq 0 $i`
		do
			echo -n " "
			echo -en "\b\b"
			sleep 0.1
		done
	done
	printf "${NC}"
}

# Make sure we have textcleaner.sh available
clear
printf "${Blue}Checking for textclean script...${NC} \n"
if [ -f textcleaner.sh ]
then
	printf "${Green}textclean.sh found! ${NC} \n"
else
	printf "${Red}textclean.sh missing, attempting to pull... ${NC} \n"
	wget https://github.com/zachcp/moses-caro/raw/master/scripts/textcleaner.sh  && \
		printf "${Green}Successfully pulled textclean.sh! ${NC} \n"
	chmod u+x textcleaner.sh
fi

# Test for zip file param, ask if not supplied:
if [ $# -eq 0 ]
then
	# Setup File Locations
	read -p 'Enter Assignmet ZIP File Location: ' assignment
	targetFiles=$(unzip $assignment)
else
	targetFiles=$( echo $1 | cut -d '.' -f 1)
fi

# Unzip archive and setup output master:
unzip $1 -d $targetFiles
outputMaster="$targetFiles/OUTPUT_MASTER.txt"

for f in $targetFiles/*.jpg;
do
	file=$(basename $targetFiles/output/$f | cut -d "." -f 1)
	
	# Generate scrubbed copy and translate
	printf "${Blue}TRANSLATING $file...${NC} \n"
	progBar &
	PROG_PID=$!
	./textcleaner.sh -g -e normalize -f 30 -o 12 -s 2 "$targetFiles/$file.jpg" "$targetFiles/$file-clean.jpg" && \
		kill -9 $PROG_PID && wait $! 2>/dev/null
	printf "${NC} \n"
	tesseract "$targetFiles/$file-clean.jpg" "$targetFiles/$file" -l eng --psm 3 && \
		printf "${Green}$file TRANSLATED ${NC} \n"

	# Clean Up Extra Files
	rm "$targetFiles/$file-clean.jpg"
	printf "${Green}$file CLEANED COPY DELETED. ${NC} \n"

	# Compile Master Output File
	printf "$file \n" >> $outputMaster
	cat "$targetFiles/$file.txt" >> $outputMaster
	printf "\n \n" >> $outputMaster
	printf "${Green}$file ADDED TO $outputMaster ${NC} \n"
	printf "${Green}$file TEXT FILE REMOVED ${NC} \n"
	rm "$targetFiles/$file.txt"

done

# Delete textcleaner.sh as final clean-up step
rm textcleaner.sh
