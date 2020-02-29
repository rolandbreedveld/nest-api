api script to get a Nest Google account working in Domoticz

![Image 1](https://github.com/rolandbreedveld/nest-api/blob/master/Nest%20with%20Google%20account.png)

based on : https://github.com/gboudreau/nest-api

Version info:
- 2020-01-16 V1.01
- 2020-01-17 V1.02 bugfix idx hardcoded
- 2020-01-25 V1.03 bugfix and support for Away mode,
                 nest_auth.php renamed to nest_auth.php-example, so it won't overwrite your file.
                 devices are moved from the script to nest_devices.cfg, which is 
                 delivered as nest_devices.cfg-example, so it won'toverwrite your file.
- 2020-01-28 V1.04 add possibility formultisensor Tem+Hum
- 2020-02-07 V1.05 Heat wasn't updated fixed
- 2020-02-21 V1.06 Domoticz host and port to config file
- 2020-02-25 V1.07 change in nest.class.php not auto go to ECO on setting AWAY

scripts are located (in my case) in /home/pi/nest-api/

This script need php, so be shure it's installed:
- sudo apt install php php-curl php-cli php-common

to install, download the zip, or better use git:
if you dan't have git, install it first:
- sudo apt install git
- cd /home/pi
- git clone https://github.com/rolandbreedveld/nest-api.git
- to update it to the latest version:
- cd /home/pi/nest-api
- git pull

copy nest.auth.php_example to nest.auth.php
and change the issue-token and cookie in nest.auth.php  
to get both values take these steps:   (thanks FilipDem for this info)
- Open a Chrome browser tab in Incognito Mode (or clear your cache).
- Open Developer Tools (View/Developer/Developer Tools).
- Click on Network tab. Make sure Preserve Log is checked.
- In the Filter box, enter issueToken
- Go to https://home.nest.com, and click Sign in with Google. Log into your account.
- One network call (beginning with iframerpc) will appear in the Dev Tools window. Click on it.
- In the Headers tab, under General, copy the entire Request URL (beginning with https://accounts.google.com, ending with nest.com). This is your $issue_token.
- In the Filter box, enter oauth2/iframe
- Several network calls will appear in the Dev Tools window. Click on the last iframe call.
- In the Headers tab, under Request Headers, copy the entire cookie value (include the whole string which is several lines long and has many field/value pairs - do not include the Cookie: prefix). This is your $cookies; make sure all of it is on a single line.

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

if you use a different path, you should change it a some places

if Domoticz is running on another server or is using a different port, add this to nest_devices.cfg:
- DOMOTICZ server-ip:port
- if empty, the default will be: 127.0.0.1:8080

This scipt is using cachefiles e.g. /tmp/nest_phpxxxxxx, if you test this schipt with the root user, and Domotics runs as user pi, don't forget to remove them after testing. (rm -rf /tmp/nest_php*)

Some people want a different location, you can change the location of these cachefiles in the php-config:
- /etc/php5/cli/php.ini for command line interface (/etc/php5/apache2/php.ini for use from apache
- sys_temp_dir = "/tmp" <<< this is the one
- soap.wsdl_cache_dir="/tmp" <<< better change this one too

succes, Roland@Breedveld.net

