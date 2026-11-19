<?php
$content = file_get_contents(__DIR__ . '/../admin/js/app.js');
$lines = explode("\n", $content);
foreach ($lines as $num => $line) {
    if (stripos($line, 'fetchPayoutsList') !== false || stripos($line, 'payout-table-body') !== false || stripos($line, 'renderPayouts') !== false) {
        echo ($num + 1) . ": " . trim($line) . "\n";
    }
}
