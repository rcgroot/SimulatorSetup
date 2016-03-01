#!/bin/sh
if [[ "$1" == "read" || "$1" == "write" ]];
then
  ACTION=$1
  shift
fi

while [[ $# > 1 ]]
do
  key="$1"
  case $key in
      -g|--appgroup)
      GROUP_PACKAGE="$2"
      shift # past argument
      ;;
      *)
              # unknown option
      ;;
  esac
  shift # past argument or value
done

if [[ -z "$ACTION" || -z "$GROUP_PACKAGE" ]]
then
  echo "Usage $0 [read|write] -g <(partial) package_id>"
  exit 1
fi

for device in ~/Library/Developer/CoreSimulator/Devices/*/device.plist; do
    runtime=$(defaults read "${device}" runtime)
    devicedir="$(dirname ${device})"
    libdir="$devicedir/data/Library"
    groupsdir="$devicedir/data/Containers/Shared/AppGroup"
    if [[ $runtime = com.apple.CoreSimulator.SimRuntime.iOS* ]]
    then
      VERSION=${runtime#com.apple.CoreSimulator.SimRuntime.iOS-}
      GROUP_ARCHIVE=AppGroupCopy-${VERSION}.zip
      if [[ ! -z "$GROUP_PACKAGE" ]]
      then
        for group in ${groupsdir}/*
        do
          if grep -q $GROUP_PACKAGE "${group}/.com.apple.mobile_container_manager.metadata.plist";
          then
            echo "Found for $GROUP_PACKAGE in $group"
            if [[ "$ACTION" == "read" ]];
            then
              if [ -f ${GROUP_ARCHIVE} ]
              then
                rm -v ${GROUP_ARCHIVE}
              fi
              cd "${group}"
              zip -vr ${GROUP_ARCHIVE} .
              cd -
              mv "${group}"/${GROUP_ARCHIVE} .
            fi
            if [[ "$ACTION" == "write" ]];
            then
              if [ -f ${GROUP_ARCHIVE} ]
              then
                rm -r "${group}"/*
                unzip -o ${GROUP_ARCHIVE} -d "${group}"
              fi
            fi
          fi
        done
      fi
    fi
done