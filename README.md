api script to get a Nest Google account working in Domoticz

![Image 1](https://github.com/rolandbreedveld/nest-api/blob/master/Nest%20with%20Google%20account.png)

based on : https://github.com/gboudreau/nest-api

Version info:
- 2020-01-16 V1.01
- 2020-01-17 V1.02 bugfix idx hardcoded
- 2020-01-25 V1.03 bugfix and support for Away mode, \
                   nest_auth.php renamed to nest_auth.php-example, so it won't overwrite your file. \
                   devices are moved from the script to nest_devices.cfg, which is  \
                   delivered as nest_devices.cfg-example, so it won't overwrite your file.
- 2020-01-28 V1.04 add possibility formultisensor Tem+Hum
- 2020-02-07 V1.05 Heat wasn't updated fixed
- 2020-02-21 V1.06 Domoticz host and port to config file
- 2020-02-25 V1.07 change in nest.class.php not auto go to ECO on setting AWAY
- 2020-03-20 V1.07 Option: -d gives debug information
- 2020-03-20 V1.08 forced curl to use ipv4 
- 2020-03-25 V1.09 Update Setpoint if lastupdate more than 60 minutes, to avoid red-sensor. \
                   Because the setpoint triggers an event, more frequent updates are not advisable.
- 2020-04-01 V1.10 added time-stamp to the output
- 2020-05-06 V1.11 Changed dzvents-example, to avoid setpoint update after activating ECO-mode. \
                   You have to change this manually in Domoticz!!!
- 2022-07-09 V1.12 Add comments for getting token \
                   updated latest class-file from gboudreau
- 2023-02-08 V1.13 Add Alarm IDX, this wille enable ECO and AWAY mode if Alarm system is on.
- 2023-05-03 V1.14 Changed procedure to get the token and cookie




scripts are located (in my case) in /home/pi/nest-api/\
If you use a different path, you should change it a some places, also every time you pull a new version.

This script needs php, so be shure it's installed:
- sudo apt install php php-curl php-cli php-common

to install, download the zip, or better use git:
if you dan't have git, install it first:
- sudo apt install git
- cd /home/pi
- git clone https://github.com/rolandbreedveld/nest-api.git
- to update it to the latest version:
- cd /home/pi/nest-api
- git pull

copy nest.auth.php_example to nest.auth.php \
and change the issue-token and cookie in nest.auth.php   \
to get both values take these steps: 

<b>READ THESE STEPS CAREFULLY</b> ! 
- Open a Chrome browser tab in Incognito Mode (or clear your cache).
- Open Developer Tools (View/Developer/Developer Tools).
- Click on Network tab. Make sure Preserve Log is checked.

- In the Filter box, enter: issueToken
- Go to https://home.nest.com, and click Sign in with Google.
- A network call (beginning with iframerpc?action=issueToken) will appear in the Dev Tools window. Click on it.
- In the Headers tab, under <b>General</b>, copy the entire Request URL (beginning with https://accounts.google.com, ending with nest.com). This is your <b>$issue_token</b>.
- In the Headers tab, under <b>Request Headers</b> (be shure it's the request header not the other ones!!), copy the entire cookie value (include the whole string which is several lines long and has many field/value pairs - do not include the Cookie: prefix). This is your <b>$cookies</b>; make sure all of it is on one single line. 

IMPORTANT: select de values with your mouse starting at the begin of the code to the end of the code, then click richt, and select "Copy". \
DO NOT SELECT "Copy-Value", and DO NOT selecting the string bij double-click: these both won't work!!!
FINALY, Be shure the cookie and token values are placed between '  ' and the row ends with a ;

Create in Domoticz virtual Devices:

![Image 2](https://github.com/rolandbreedveld/nest-api/blob/master/Nest%20Virtual%20Devices.png)
- for Temp     : Temperature LaCross TX3
- for Hum      : Humidity LaCross TX3

or if you want the combined virtual device for Tem and Hum :
- for TempHum  : Temp+Hum THGN122/123/132
 
- for SetPoint : Thermostat SetPoint # I Named this device Nest, To acticate it easy from my iPhone with Siri
- for ECOMode  : a regular Light/Switch and change the icon tosomething nice
- for AwayMode : a regular Light/Switch and change the icon tosomething nice
- for Heat     : a regular Light/Switch and change the icon tosomething nice

- move file nest_devices.cfg-example to nest_devices.cfg
 note the idx nrs, as find in the devices tab, and change them below in the nest_devices.cfg file
- Example:   SETPOINT 492   <<< change this as example for the SETPOINT to your idx
- remove or place a # for lines you don't want to use

edit in Domoticz the ECO Mode switch:

![Image 3](https://github.com/rolandbreedveld/nest-api/blob/master/Nest%20ECO%20mode%20activation.png)
- On  Action: script:///usr/bin/php /home/pi/nest-api/set_nest_eco_mode.php
- Off Action: script:///usr/bin/php /home/pi/nest-api/unset_nest_eco_mode.php

edit in Domoticz the Away Mode switch:
- On  Action: script:///usr/bin/php /home/pi/nest-api/set_nest_away_mode.php
- Off Action: script:///usr/bin/php /home/pi/nest-api/unset_nest_away_mode.php

In the Domoticz event gui, create a new event->dzvents->device \
cut-and-paste the content of the example file dzVents_script_Nest_Setpoint.txt in it. \
My setpoint device is called "Nest", so you perhaps you need to change it. \
Better don't use spaces in the device names if you call them from dzvents event's. I had a couple of times problems with this, removing the spaces solved it. 

In the Domoticz config add 127.0.0.* and your ip (or range) to local networks.


Add the following cron-entry, to get every 5 minutes the last values from Google: (crontab -e)
- */5 * * * * /home/pi/nest-api/get_nest.sh >/dev/null 2>&1 

Or if you want a log-file:
- */5 * * * * /home/pi/nest-api/get_nest.sh >/var/log/nest-api.log 2>&1 

Of course you can do it every minute, but I don't know if Google has limitation's how much call's per hour are allowed, 5 minutes is save I think, also Domoticz stores it's data every 5 minutes, so it only effects the user interface. \
I you are using logging for a longer time you need to avoid the log-file became to big, by activate log-rotating: 
- create a file: /etc/logrotate.d/nest-api : \
 /var/log/nest-api.log { \
 	weekly \
	missingok \
	rotate 52 \
	compress \
	notifempty \
	create 640 root root \
	sharedscripts \
 } 
- If nest-api not is running as root change the create row to: \
  create 640 user-name group-name

In case you do a 2nd schedule somwhere else, like in the Nest itself, they can conflict with each other when running exactly on the same time. \
This will result as a 5 minutes toggle of values or states, you can simple solve it to add a little delay in the cron: 
- */5 * * * * sleep 60;/home/pi/nest-api/get_nest.sh >/dev/null 2>&1 


if Domoticz is running on another server or is using a different port, add this to nest_devices.cfg:
- DOMOTICZ server-ip:port
- if empty, the default will be: 127.0.0.1:8080

In Domoticz settings, be shure the api is working, example in "Local Networks (no username/password):":
- 127.0.0.1;192.168.1.*

This scipt is using cachefiles e.g. /tmp/nest_phpxxxxxx, if you test this script with the root user, and Domoticz runs as user pi, don't forget to remove them after testing. (rm -rf /tmp/nest_php*)

Some people want a different location, you can change the location of these cachefiles in the php-config:
- /etc/php5/cli/php.ini for command line interface (/etc/php5/apache2/php.ini for use from apache
- sys_temp_dir = "/tmp" <<< this is the one
- soap.wsdl_cache_dir="/tmp" <<< better change this one too




If you use Domoticz also as Alarm-System, you can add the IDX of the Alarm-Switch to the config file.
If this is present, this script will enable ECO and AWAY mode if the Alarm is on, and switch them off if the Alarm changes to off.
My alarm works automatically: if no mobile-phone is at home, the Alarm system will be activated, en the Nest goes to ECO and AWAY.
Because kids always forget to lower the thermostat when they leave. (me too)



======= Problem Solving ======

Problems to get it working? Try the debug option, you can also run the some stuff manually: 
- /home/pi/netst-api/get_nest.sh -d

Get the values from nest via the Google-api:
- php get_nest.php  

Update a value of a virtual device via the Domoticz-api, say your heat-device is 487:
- curl -X GET "http://localhost:8080/json.htm?type=command&param=switchlight&idx=487&switchcmd=On"

If you get this error: \
PHP Fatal error:  Uncaught exception 'UnexpectedValueException' with message 'Response to login request doesn't contain required access token. Response: {"error":"USER_LOGGED_OUT","detail":"No active session found."}' in /home/pi/nest-api/nest.class.php:1100

you have to regenerate the cookie and token again, see steps above, for some reason the token and cookie stopped working after running fine for over 6 months in my case. This can be caused if your api wasn't running for a while, or if Google restarts the api, the token and cookie will be timed-out.

General tip for debugging: if you get a lots of errors, always look at the first one! (The rest is in most cases caused by this, and not important)


succes, Roland@Breedveld.net

