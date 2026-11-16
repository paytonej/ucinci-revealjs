<?php
echo "PHP version: " . phpversion() . "<br>";
echo "PDO available: " . (class_exists('PDO') ? 'yes' : 'no') . "<br>";
echo "PDO drivers: " . implode(', ', class_exists('PDO') ? PDO::getAvailableDrivers() : array()) . "<br>";
echo "sqlite3 extension loaded: " . (extension_loaded('sqlite3') ? 'yes' : 'no') . "<br>";