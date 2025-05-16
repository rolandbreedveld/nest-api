#!/bin/bash

# =========================================
# /home/pi/nest-api/get_nest.sh
# =========================================
# Roland@Breedveld.net
#
# See README.md for info

cd /home/pi/nest-api

DOMOTICZ=$(grep "^DOMOTICZ " nest_devices.cfg|awk '{print $NF}')
if [ -z "${DOMOTICZ}" ]
then
  export DOMOTICZ="127.0.0.1:8080"
fi

if [ "${1}" == "-d" ]
then
  export DEBUG=1
else
  export DEBUG=0
fi

function print_debug ()
{
  if [ "${DEBUG}" == "1" ]
  then
    echo "$(date "+%Y-%m-%d %H:%M") DEBUG: ${*}"
  fi
}

function print_action ()
{
  echo "$(date "+%Y-%m-%d %H:%M") ${*}"
}

IDX=$(grep "^ALARM " nest_devices.cfg|awk '{print $NF}')
if [ ! -z "${IDX}" ]
then
  print_debug "ALARM_IDX: ${IDX}"
  # if  [ "$(curl -4 -X GET "http://${DOMOTICZ}/json.htm?type=command&param=getdevices&rid=134" 2>/dev/null |jq -r '.result[].Status')" == "Off" ]
  if curl -4 -X GET "http://${DOMOTICZ}/json.htm?type=command&param=getdevices&rid=${IDX}" 2>/dev/null|grep Status|grep Off >/dev/null 2>&1
  then
    export ALARM_STATE="Off"
  else
    export ALARM_STATE="On"
  fi
fi
print_debug "ALARM_STATE: ${ALARM_STATE}"

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
      if [ "${ALARM_STATE}" == "On" ]
      then
        VALUE="On"
      fi
      if [ "${ALARM_STATE}" == "Off" ]
      then
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
      if [ "${ALARM_STATE}" == "On" ]
      then
        VALUE="On"
      fi
      if [ "${ALARM_STATE}" == "Off" ]
      then
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
  print_debug "json: $LINE"
  print_debug "vars: TYPE:$TYPE VALUE:$VALUE IDX:$IDX"
  if [ ! -z "${IDX}" ]
  then
    if [ "${TYPE}" == "TEMP" ]
    then
      print_action "Update ${TYPE} to $VALUE"
      print_debug "$(curl -4 -X GET "http://${DOMOTICZ}/json.htm?type=command&param=udevice&idx=${IDX}&nvalue=0&svalue=${VALUE}" 2>&1)"
    fi
    if [ "${TYPE}" == "HUMIDITY" ]
    then
      print_action "Update ${TYPE} to $VALUE"
      print_debug "$(curl -4 -X GET "http://${DOMOTICZ}/json.htm?type=command&param=udevice&idx=${IDX}&nvalue=${VALUE}&svalue=0" 2>&1)"
    fi
    if [ "${TYPE}" == "SETPOINT" ]
    then
      CURRENT=$(curl -4 -X GET "http://${DOMOTICZ}/json.htm?type=command&param=getdevices&rid=${IDX}" 2>/dev/null|grep '"SetPoint" : '|sed 's/\"//g;s/,$//'|awk '{print sprintf("%.1f",$3)}'|sed 's/.0$//')
      VALUE=$(echo ${VALUE}|sed 's/.0$//')
      if [ "${CURRENT}" != "${VALUE}" ]
      then
        print_action "Update ${TYPE} to $VALUE"
        print_debug "$(curl -4 -X GET "http://${DOMOTICZ}/json.htm?type=command&param=setsetpoint&idx=${IDX}&setpoint=${VALUE}"  >/dev/null 2>&1)"
      else
        # check last update, to avoid red sensor
        LASTUPDATE=$(curl -4 -X GET "http://${DOMOTICZ}/json.htm?type=command&param=getdevices&rid=${IDX}" 2>/dev/null|grep '"LastUpdate" :'|awk -F\" '{print $4}')
        print_debug "vars: LASTUPDATE SETPOINT:${LASTUPDATE}"
        if [ "$(($(date '+%s') - $(date --date="${LASTUPDATE}" +%s)))" -gt "3600" ]
        then
          print_action "Update ${TYPE} to $VALUE : LastUpdate older then 60 minutes "
          print_debug "$(curl -4 -X GET "http://${DOMOTICZ}/json.htm?type=command&param=setsetpoint&idx=${IDX}&setpoint=${VALUE}" >/dev/null 2>&1)"
        fi
      fi
    fi
    if [ "${VALUE}" == "On" ]
    then
      if curl -4 -X GET "http://${DOMOTICZ}/json.htm?type=command&param=getdevices&rid=${IDX}" 2>/dev/null|grep Status|grep Off >/dev/null 2>&1
      then
        print_action "Update ${TYPE} state to ${VALUE}"
        print_debug "$(curl -4 -X GET "http://${DOMOTICZ}/json.htm?type=command&param=switchlight&idx=${IDX}&switchcmd=${VALUE}" 2>&1)"
      fi
    fi
    if [ "${VALUE}" == "Off" ]
    then
      if curl -4 -X GET "http://${DOMOTICZ}/json.htm?type=command&param=getdevices&rid=${IDX}" 2>/dev/null|grep Status|grep On >/dev/null 2>&1
      then
        print_action "Update ${TYPE} state to ${VALUE}"
        print_debug "$(curl -4 -X GET "http://${DOMOTICZ}/json.htm?type=command&param=switchlight&idx=${IDX}&switchcmd=${VALUE}" 2>&1)"
      fi
    fi
    if [ ! -z "${TEMPHUM_VALUE}" ]
    then
      TYPE="TEMPHUM"
      IDX=$(grep "^${TYPE} " nest_devices.cfg|awk '{print $NF}')
      if [ ! -z "${IDX}" ]
      then
        print_action "Update ${TYPE} to $TEMPHUM_VALUE"
        print_debug "$(curl -4 -X GET "http://${DOMOTICZ}/json.htm?type=command&param=udevice&idx=${IDX}&nvalue=0&svalue=${TEMPHUM_VALUE}" 2>&1)"
      fi
      TEMPHUM_VALUE=""
    fi
  fi
done

#rm -f /tmp/nest_php_*

#nest_php_cache_root_
#cd /tmp
#ls -tr nest_php_cookies_root_*|tail -1
#cat $(ls -tr nest_php_cookies_root_*|tail -1)|grep Secure
