#!/bin/bash

if [[ -f ${HOME}/.ragnar.rc ]]; then
    source ${HOME}/.ragnar.rc
else
    TOP=${TOP:-"${HOME}"}
fi
TOP=${TOP}/randconfig-artifacts
mkdir -p ${TOP}

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
mkdir -p ${OUTPUTDIR}
logfilename=$(echo $(basename ${FILE})|awk -F. '{print $1}').log
tuxbuild build-set --git-repo ${REPOSITORY} --git-ref ${BRANCH} --tux-config ${FILE} --set-name basic 2>&1 | tee ${OUTPUTDIR}/${logfilename}

for url in $(cat ${OUTPUTDIR}/${logfilename} |grep -P '.*Pass \([1-9]\d* warning(|s)\):' |awk -F' ' '{print $NF}'); do
	echo ${url}
	builddir=$(echo ${url} |sed -e 's|.*tuxbuild.com/||')
	mkdir -p ${OUTPUTDIR}/${builddir}
	cd ${OUTPUTDIR}/${builddir}
	echo curl -sSOL ${url}build.log
	curl -sSOL ${url}build.log
	echo curl -sSOL ${url}kernel.config
	curl -sSOL ${url}kernel.config
	cd -
done
