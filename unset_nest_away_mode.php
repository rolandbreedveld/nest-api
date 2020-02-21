<?php

require_once 'nest.class.php';
require_once 'nest.auth.php';

date_default_timezone_set('Europe/Amsterdam');

$nest = new Nest(NULL, NULL, $issue_token, $cookies);

echo "Setting away mode off...\n";
$success = $nest->setAway(AWAY_MODE_OFF); // Available: AWAY_MODE_ON, AWAY_MODE_OFF
var_dump($success);
function jlog($json) {
    echo json_encode($json, JSON_PRETTY_PRINT) . "\n";
}
