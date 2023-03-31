#!/bin/bash

#set -euo pipefail
# to check if variable exists with -u turn on, use [ -v VAR_NAME ] or [ $# -gt 0 ] if arguments
#shopt -s failglob lastpipe

# Assumes version 1.1 of fix_bash.sh
full_path="$(realpath -e $0)"
script_dir="$(dirname "$full_path")"
source "$script_dir/fix_bash.sh"

no_test=0
passed_test=0
failed_test=0
# set input to newline, as required by mfcsc
INPUT='
'
OUTPUT_DIR=./test_containers_output
LOGFILE=app_test_stdout.log
ERRLOGFILE=app_test_stderr.log

#set -e

logfile=test_containers.log

if [ -d "$OUTPUT_DIR" ]
then
	echo "$OUTPUT_DIR"' folder already exists. Exiting'
	exit 1
else
	mkdir "$OUTPUT_DIR"
	cd "$OUTPUT_DIR"
fi

( (cd /neurocommand; ./containers.sh) | while IFS=$' \t' read -r col1 PACKAGE VERSION BUILDDATE col5 col6
do
    if echo "$col1" | grep -q fetch_containers.sh
	then
		echo
		echo ================================================
	    echo 'Package: '"$PACKAGE"
    	echo 'Version: '"$VERSION"
    	echo 'Build date: '"$BUILDDATE"
		
		# create and change to package subdir
		subdir="$PACKAGE"_"$VERSION"_"$BUILDDATE"
		
		if ! [ -d "$subdir" ]
		then
			mkdir "$subdir"
			cd "$subdir"

			#if [ -f /tmp/error_message ]
			#then
			#	rm /tmp/error_message
			#fi
			test_cmd='singularity --silent exec --pwd '"$PWD"' /cvmfs/neurodesk.ardc.edu.au/containers/'"$PACKAGE"'_'"$VERSION"'_'"$BUILDDATE"'/'"$PACKAGE"'_'"$VERSION"'_'"$BUILDDATE"'.simg /bin/bash -e /neurodesk/app_test.sh'
			export PWD=`pwd -P`
			
			echo 'running test script (only showing stderr; to track stdout, run "tail -f '"$PWD"'/'"$LOGFILE"'"):'
			echo "$test_cmd"
			
			# execute test script inside $subdir, sending stdout to a file, and stderr to a file and terminal
			# providing $INPUT as input, in case a new line or other input is required
			if echo "$INPUT" | ${test_cmd} 2>&1 1>"$LOGFILE" | tee "$ERRLOGFILE"
			then
				# exit code was 0
				echo 'package passed test'
				passed_test=$((passed_test+1))
				echo 'last two lines of stdout are:'
				tail -2 "$LOGFILE"
				echo 'Passed test so far: '"$passed_test"
			else
				exit_code=$? # save non-zero exit code
				error_message=$(cat "$ERRLOGFILE")
				if [ "$exit_code" -eq 1 ] && [ "$error_message" = '/bin/bash: /neurodesk/app_test.sh: No such file or directory' ]
				then
					echo 'Package has no test script'
					no_test=$((no_test+1))
					echo 'No test so far: '"$no_test"
				elif [ "$exit_code" -eq 1 ] && [ "$error_message" = 'N/A' ]
				then
					echo 'Package is using the template stub test script'
					no_test=$((no_test+1))
					echo 'No test so far: '"$no_test"
				else
					echo '==> test_containers: FAIL'
					echo 'Package failed test with error code: '"$exit_code"
					echo 'See above for stderr'
					failed_test=$((failed_test+1))
					echo 'Failed test so far: '"$failed_test"
				fi
			fi
			# go back to top folder
			cd ..
		else
			echo 'Skips, as package has already been tested earlier (package is probably listed once with GUI and once without)'
		fi
	fi
done

echo
echo ================================================
echo
echo 'SUMMARY OF CONTAINER TESTS'
echo 'No test: '"$no_test"' packages'
echo 'Passed test: '"$passed_test"' packages'
echo 'Failed test: '"$failed_test"' packages (search for "==> test_containers: FAIL" in log)'
echo 'Notice: the containers tested are those returned by running ./containers.sh in /neurocommand'
echo
echo 'NEURODESKTOP TESTS'
echo 'Testing the existance of /neurodesktop-storage ...'
if [ -d /neurodesktop-storage ]
then
	echo 'Test passed'
else
	echo 'Test failed'
fi
echo
echo ) |& log "$logfile"
exit_code=$?
if [ "$exit_code" = 0 ]
then
	echo 'Log is at '"$OUTPUT_DIR"'/'"$logfile"
fi
exit "$exit_code"
