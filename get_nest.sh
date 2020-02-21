#!/bin/bash

# =========================================
# /home/pi/nest-api/get_nest.sh
# =========================================
# Roland@Breedveld.net
# 2020-01-16 V1.01 
# 2020-01-17 V1.02 bugfix idx hardcoded
# 2020-01-25 V1.03 bugfix and support for Away mode, 
#                  nest_auth.php renamed to nest_auth.php-example, so it won't overwrite.
#                  devices are moved from the script to nest_devices.cfg
# 2020-01-28 V1.04 add possibility formultisensor Tem+Hum
# 2020-02-07 V1.05 Heat wasn't updated fixed
# 2020-02-21 V1.06 Domoticz host and port to config file
# =========================================
#
# See README.md for info

cd /home/pi/nest-api

DOMOTICZ=$(grep "^DOMOTICZ " nest_devices.cfg|awk '{print $NF}')
if [ -z "${DOMOTICZ}" ]
then
  export DOMOTICZ="127.0.0.1:8080"
fi

TARGET_SET=0
php get_nest.php| while read LINE
do
  VALUE="$(echo ${LINE}|awk '{print $2}'|sed 's/,$//;s/\"//g')"
  if [ ! -z "$(echo ${VALUE}|grep [0-9])" ]
  then
    VALUE="$(echo ${VALUE}|awk '{print sprintf("%.1f",$1)}')"
  fi
  case "$(echo ${LINE}|awk '{print $1}')" in
    '"target":')
      TARGET_SET=1
      # 1st temp is normaltemp, the same after target is the setpoint
      ;;
    '"temperature":')
      if [ "${TARGET_SET}" == "1" ]
      then
        TYPE=SETPOINT
        IDX=$(grep "^${TYPE} " nest_devices.cfg|awk '{print $NF}')
      else
        TYPE=TEMP
        IDX=$(grep "^${TYPE} " nest_devices.cfg|awk '{print $NF}')
        TEMP=${VALUE}
      fi
      ;;
    '"humidity":')
      TYPE=HUMIDITY
      IDX=$(grep "^${TYPE} " nest_devices.cfg|awk '{print $NF}')
      # if Multi sensor is used
      TEMPHUM_VALUE="${TEMP};${VALUE};0"
      ;;
    '"away":')
      TYPE=AWAYMODE
      IDX=$(grep "^${TYPE} " nest_devices.cfg|awk '{print $NF}')
      if [ "${VALUE}" == "true" ]
      then
        VALUE="On"
      else
        VALUE="Off"
      fi
      ;;
    '"eco_mode":')
      TYPE=ECOMODE
      IDX=$(grep "^${TYPE} " nest_devices.cfg|awk '{print $NF}')
      if [ "${VALUE}" == "manual-eco" ]
      then
        VALUE="On"
      else
        VALUE="Off"
      fi
      ;;
    '"heat":')
      if [ "${VALUE}" == "true" ]
      then
        TYPE=HEAT
        IDX=$(grep "^${TYPE} " nest_devices.cfg|awk '{print $NF}')
        VALUE="On"
      fi
      if [ "${VALUE}" == "false" ]
      then
        TYPE=HEAT
        IDX=$(grep "^${TYPE} " nest_devices.cfg|awk '{print $NF}')
        VALUE="Off"
      fi
      ;;
    *)
      IDX=""
      ;;
  esac

  if [ ! -z "${IDX}" ]
  then
    if [ "${TYPE}" == "TEMP" ]
    then
      curl -X GET "http://${DOMOTICZ}/json.htm?type=command&param=udevice&idx=${IDX}&nvalue=0&svalue=${VALUE}" >/dev/null 2>&1
      echo "Update ${TYPE} to $VALUE"
    fi
    if [ "${TYPE}" == "HUMIDITY" ]
    then
      curl -X GET "http://${DOMOTICZ}/json.htm?type=command&param=udevice&idx=${IDX}&nvalue=${VALUE}&svalue=0" >/dev/null 2>&1
      echo "Update ${TYPE} to $VALUE"
    fi
    if [ "${TYPE}" == "SETPOINT" ]
    then
      CURRENT=$(curl -X GET "http://${DOMOTICZ}/json.htm?type=devices&rid=${IDX}" 2>/dev/null|grep '"SetPoint" : '|sed 's/\"//g;s/,$//'|awk '{print sprintf("%.1f",$3)}')
      if [ "${CURRENT}" != "${VALUE}" ]
      then
        curl -X GET "http://${DOMOTICZ}/json.htm?type=setused&idx=${IDX}&setpoint=${VALUE}&used=true" >/dev/null 2>&1
        echo "Update ${TYPE} to $VALUE"
      fi
    fi
    if [ "${VALUE}" == "On" ]
    then
      if curl -X GET "http://${DOMOTICZ}/json.htm?type=devices&rid=${IDX}" 2>/dev/null|grep Status|grep Off >/dev/null 2>&1
      then
        curl -X GET "http://${DOMOTICZ}/json.htm?type=command&param=switchlight&idx=${IDX}&switchcmd=${VALUE}" >/dev/null 2>&1
        echo "Update ${TYPE} state to ${VALUE}"
      fi
    fi
    if [ "${VALUE}" == "Off" ]
    then
      if curl -X GET "http://${DOMOTICZ}/json.htm?type=devices&rid=${IDX}" 2>/dev/null|grep Status|grep On >/dev/null 2>&1
      then
        curl -X GET "http://${DOMOTICZ}/json.htm?type=command&param=switchlight&idx=${IDX}&switchcmd=${VALUE}" >/dev/null 2>&1
        echo "Update ${TYPE} state to ${VALUE}"
      fi
    fi
    if [ "${IDX}" == "HEAT"  ]
    then
        curl -X GET "http://${DOMOTICZ}/json.htm?type=devices&rid=${IDX}" 2>/dev/null|grep Status|grep On >/dev/null 2>&1
    fi
    if [ ! -z "${TEMPHUM_VALUE}" ]
    then
      TYPE="TEMPHUM"
      IDX=$(grep "^${TYPE} " nest_devices.cfg|awk '{print $NF}')
      if [ ! -z "${IDX}" ]
      then
        curl -X GET "http://${DOMOTICZ}/json.htm?type=command&param=udevice&idx=${IDX}&nvalue=0&svalue=${TEMPHUM_VALUE}" >/dev/null 2>&1
        echo "Update ${TYPE} to $TEMPHUM_VALUE"
      fi
      TEMPHUM_VALUE=""
    fi
  fi
done

