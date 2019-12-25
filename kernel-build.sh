#!/bin/bash

if [[ -f ${HOME}/.ragnar.rc ]]; then
	source ${HOME}/.ragnar.rc
else
	TOP=${TOP:-"${HOME}"}
fi
TOP=${TOP}/randconfig-artifacts

usage() {
	echo -e "$(basename $0)'s help text"
	echo -e "   -f file to build, if not provided we will build the Image file"
}

set_config_file() {
	cd $obj_dir
	echo ../scripts/kconfig/merge_config.sh -m ${1}
	../scripts/kconfig/merge_config.sh -m ${1}
	cd -
}

set_config_frag() {
	cd $obj_dir
	echo ../scripts/config --enable ${1}
	../scripts/config --enable ${1}
	cd -
}

find_artifact_builds() {
	pushd ${TOP}/ > /dev/null 2>&1
	tmp=$(find . -maxdepth 2 -type d|sed 's|^./||g'|awk -F/ '$2')
	echo $tmp|tr " " "\n"|sed 's|^|  |'
	popd > /dev/null 2>&1
}

while getopts "f:h" arg; do
	case $arg in
		f)
			stuff_to_build="$OPTARG"
			;;
		h|*)
			usage
			exit 0
			;;
	esac
done

if [[ -z $list_staging ]]; then
	echo "Listing staging build strings:"
	find_artifact_builds
	num_builds=$(find_artifact_builds|wc -l)
	if [[ $num_builds -eq 0 ]]; then
		exit 0
	elif [[ $num_builds -eq 1 ]]; then
		artifact_buildstr=$(find_artifact_builds | sed 's/ //g')
	else
		echo
		echo "Copy/paste what build string you want to"
		echo "deploy, followed by [ENTER]:"
		read artifact_buildstr
	fi
	fi

source ${TOP}/${artifact_buildstr}/build_configuration.conf

if [[ -z ${stuff_to_build} ]]; then
	if [[ ${ARCH} == "x86" ]]; then
		stuff_to_build=bzImage
	elif [[ ${ARCH} == "arm64" ]]; then
		stuff_to_build=Image
	fi
fi

obj_dir="obj-randconfig-${ARCH}-$(git describe|awk -F'-' '{print $1"-"$2}')"

if [[ -z ${CROSS_COMPILE} ]]; then
	cross_build=""
else
	cross_build="CROSS_COMPILE=${CROSS_COMPILE}"
fi


echo make ARCH=${ARCH} HOSTCC=${HOSTCC} -skj$(getconf _NPROCESSORS_ONLN) O=${obj_dir} ${cross_build} defconfig
make ARCH=${ARCH} HOSTCC=${HOSTCC} -skj$(getconf _NPROCESSORS_ONLN) O=${obj_dir} ${cross_build} defconfig
cp ${TOP}/${artifact_buildstr}/kernel.config ${obj_dir}/.config
echo make ARCH=${ARCH} HOSTCC=${HOSTCC} -skj$(getconf _NPROCESSORS_ONLN) O=${obj_dir} ${cross_build} olddefconfig
make ARCH=${ARCH} HOSTCC=${HOSTCC} -skj$(getconf _NPROCESSORS_ONLN) O=${obj_dir} ${cross_build} olddefconfig

echo
echo "building ${obj_dir}"
echo
echo make ARCH=${ARCH} HOSTCC=${HOSTCC} -skj$(getconf _NPROCESSORS_ONLN) O=${obj_dir} ${cross_build} INSTALL_MOD_PATH=${obj_dir}/modules_install ${stuff_to_build}
make ARCH=${ARCH} HOSTCC=${HOSTCC} -skj$(getconf _NPROCESSORS_ONLN) O=${obj_dir} ${cross_build} INSTALL_MOD_PATH=${obj_dir}/modules_install ${stuff_to_build}
