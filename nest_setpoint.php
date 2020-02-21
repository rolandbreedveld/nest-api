<?php

require_once 'nest.class.php';
require_once 'nest.auth.php';

date_default_timezone_set('Europe/Amsterdam');

$nest = new Nest(NULL, NULL, $issue_token, $cookies);


// Note: setting temperatures will use the units you set on the device. I'm using celsius on my device, so I'm using celsius here.
if (isset($argv)) {
  echo "Setting target temperature to $argv[1] ...\n";
  $success = $nest->setTargetTemperature((float)$argv[1]);
  var_dump($success);
}
function jlog($json) {
    echo json_encode($json, JSON_PRETTY_PRINT) . "\n";
}
