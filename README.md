Workarround to get Nest Google account working in Domoticz

based on : https://github.com/gboudreau/nest-api

Version info:
2020-01-16 V1.01
2020-01-17 V1.02 bugfix idx hardcoded
2020-01-25 V1.03 bugfix and support for Away mode,
                 nest_auth.php renamed to nest_auth.php-example, so it won't overwrite your file.
                 devices are moved from the script to nest_devices.cfg, which is 
                 delivered as nest_devices.cfg-example, so it won'toverwrite your file.
2020-01-28 V1.04 add possibility formultisensor Tem+Hum
2020-02-07 V1.05 Heat wasn't updated fixed

scripts are located (in my case) in /home/pi/nest-api/
follow the readme in the get_nest.sh script

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
 for Temp     : Temperature LaCross TX3
 for Hum      : Humidity LaCross TX3
 or if you want a combined virtual device :
 for TempHum  : Temp+Hum THGN122/123/132
 
 for SetPoint : Thermostat SetPoint
 for ECO Mode : a regular Light/Switch and change the icon tosomething nice
 for Away Mode: a regular Light/Switch and change the icon tosomething nice
 for Heat     : a regular Light/Switch and change the icon tosomething nice

 move file nest_devices.cfg-example to nest_devices.cfg
 note the idx nrs, as find in the devices tab, and change them below in the nest_devices.cfg file
 Example:   SETPOINT 492   <<< change this as example for the SETPOINT to your idx
 remove or place a # for lines you don't want to use

edit in Domoticz the ECO Mode switch:
   On  Action: script:///usr/bin/php /home/pi/nest-api/set_nest_eco_mode.php
   Off Action: script:///usr/bin/php /home/pi/nest-api/unset_nest_eco_mode.php

edit in Domoticz the Away Mode switch:
   On  Action: script:///usr/bin/php /home/pi/nest-api/set_nest_away_mode.php
   Off Action: script:///usr/bin/php /home/pi/nest-api/unset_nest_away_mode.php

Add dzVents script, see example file : dzVents_script_Nest_Setpoint.txt
Setpoint device is called "Nest Setpoint", so you perhaps, need to change it.

Add the following cron-entry, to get every 5 minutes the last values from Google: (crontab -e)
*/5 * * * * /home/pi/nest-api/get_nest.sh >/dev/null 2>&1

if you use a different path, you should change it a some places

succes, Roland@Breedveld.net

