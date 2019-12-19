#!/bin/bash

if [[ -f ${HOME}/.ragnar.rc ]]; then
    source ${HOME}/.ragnar.rc
else
    TOP=${TOP:-"${HOME}/ragnar-artifacts"}
fi
mkdir -p ${TOP}/randconfig-artifacts

usage() {
	echo -e "$0's help text"
	echo -e "   -b BRANCH, branch from the kernel repository."
	echo -e "   -f FILE, yaml file to build from."
	echo -e "   -r REPOSITORY, kernel repository to build,"
}

while getopts "b:f:r:h" arg; do
	case $arg in
		b)
			BRANCH="$OPTARG"
			;;
		f)
			FILE="$OPTARG"
			;;
		r)
			REPOSITORY="$OPTARG"
			;;
		h|*)
			usage
			exit 0
			;;
	esac
done

REPOSITORY=${REPOSITORY:-"https://git.linaro.org/people/anders.roxell/linux.git"}

if [[ -z ${BRANCH} ]]; then
	echo "ERROR: forgot to set branch!"
	usage
	exit 0
fi

if [[ -z ${FILE} ]]; then
	echo "ERROR: forgot to set file!"
	usage
	exit 0
fi

OUTPUTDIR=${TOP}/$(date +"%Y%m%d-%H")
logfilename=output-${$(basename ${FILE})%.yaml}.log
tuxbuild build-set --git-repo ${REPOSITORY} --git-ref ${BRANCH} --tux-config ${FILE} --set-name basic 2>&1 | tee ${OUTPUTDIR}/${logfilename}
for build in $(cat ${logfilename}); do
	url=$(echo ${build} |grep -P '.*Pass \(\d warnings\):' |awk -F' ' '{print $NF}')
	builddir=$(echo ${build} |sed -e 's|.*tuxbuild.com/||')
	mkdir ${OUTPUTDIR}/${builddir}
	curl -sSOL ${url}/build.log
done
