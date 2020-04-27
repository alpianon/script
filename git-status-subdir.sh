#!/bin/bash

echo "
this script is only for git directories with repositories in subdirectories
*** 2 levels down ***
(git/dir/repo/)
don't use if structure is only one level (git/repo)"

last_update=0 #initialize variable
maindir="$1"
declare -a changed_files_array=()
declare -a untracked_files_array=()
declare -a unpushed_commits_array=()
normal=$(tput sgr0)
bold=$(tput bold)


# No directory has been provided, use current
if [ -z "$maindir" ]
then
	maindir="`pwd`"
fi

# Make sure directory ends with "/"
if [[ $maindir != */ ]]
then
	dir="$maindir/*"
else
	dir="$maindir*"
fi

for f in $maindir/*

do

dir=$f

# Make sure directory ends with "/"
if [[ $maindir != */ ]]
then
	dir="$dir/*"
else
	dir="$dir*"
fi

echo "dir is $dir"

# Loop all sub-directories
for f in $dir
do
	# Only interested in directories
	[ -d "${f}" ] || continue

	echo -en "\033[0;35m"
	echo "${f}"
	echo -en "\033[0m"

	# Check if directory is a git repository
	if [ -d "$f/.git" ]
	then
		mod=0
		cd $f

		last_update=$(stat -c %Y .git/FETCH_HEAD)
		now_date=$(date +%s)

		if [ $(( now_date - last_update 	)) -gt 3600 ] ; then
			echo "fetching"
			git fetch;
		else
			echo "no need to fetch, too recently fetched, check locally"
		fi


		# Check for modified files
		if [ $(git status | grep modified -c) -ne 0 ]
		then
			mod=1
			echo -en "\033[0;31m"
			echo "Modified files"
			echo -en "\033[0m"
			changed_files_array+=("${f}")
		fi

		# Check for untracked files
		if [ $(git status | grep Untracked -c) -ne 0 ]
		then
			mod=1
			echo -en "\033[0;31m"
			echo "Untracked files"
			echo -en "\033[0m"
			untracked_files_array+=("${f}")
		fi

		# Check if everything is peachy keen
		if [ $mod -eq 0 ]
		then
			echo "Nothing to commit"
		fi


		if [ $(git status | grep "Your branch is ahead" -c) -ne 0 ]; then
			echo -en "\033[0;31m"
			echo "we have commits yet to be pushed"
			echo -en "\033[0m"
			unpushed_commits_array+=("${f}")
		fi

		cd ../

	else
		echo "Not a git repository"
	fi

	echo
done

done

printf "*------------------------------------*\\n"
printf "   ${bold}please check these directories${normal}:\\n"
printf "*------------------------------------*\\n\\n"

if [[ ! -z $changed_files_array ]]; then
printf "we have ${bold}modified${normal} files in: \\n\\n"
printf  "%s \n" "${changed_files_array[@]}"
fi

printf "\\nwe have ${bold}untracked${normal} files in: \\n\\n"
printf  "%s \n" "${untracked_files_array[@]}"

if [[ ! -z $unpushed_commits_array ]]; then
printf "\\nwe have ${bold}unpushed${normal} commits in: \\n\\n"
printf  "%s \n" "${unpushed_commits_array[@]}"
fi
printf "\\n* ------------------------------------ *\\n\\n"
