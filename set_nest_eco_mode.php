<?php

require_once 'nest.class.php';
require_once 'nest.auth.php';

date_default_timezone_set('Europe/Amsterdam');

$nest = new Nest(NULL, NULL, $issue_token, $cookies);

echo "Setting eco mode...\n";
$success = $nest->setEcoMode(ECO_MODE_MANUAL); // Available: ECO_MODE_MANUAL, ECO_MODE_SCHEDULE
var_dump($success);
function jlog($json) {
    echo json_encode($json, JSON_PRETTY_PRINT) . "\n";
}
