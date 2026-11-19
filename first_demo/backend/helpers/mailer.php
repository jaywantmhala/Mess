<?php
/**
 * SMTP Mailer Helper for Hungrily Foods
 * Uses Gmail SMTP with App Password to send emails.
 */

define('SMTP_HOST', 'ssl://smtp.gmail.com');
define('SMTP_PORT', 465);
define('SMTP_USER', 'jaywant61495@gmail.com');
define('SMTP_PASS', 'hcacpaiufimznnwi'); // App password without spaces
define('SMTP_FROM_NAME', 'Hungrily Foods');

function sendOTPEmail(string $toEmail, string $otp): array {
    $subject = "Hungrily Foods - Your Password Reset OTP";
    $htmlBody = "
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset='utf-8'>
        <style>
            body { font-family: Arial, sans-serif; background-color: #f8f9fa; margin: 0; padding: 20px; }
            .container { max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 12px; padding: 30px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); }
            .header { text-align: center; border-bottom: 2px solid #fff3ed; padding-bottom: 15px; margin-bottom: 20px; }
            .logo { font-size: 24px; font-weight: bold; color: #ff5722; text-decoration: none; }
            .title { font-size: 20px; font-weight: 700; color: #1a1a1a; margin-bottom: 10px; }
            .content { font-size: 15px; color: #555555; line-height: 1.6; text-align: center; }
            .otp-box { background: #fff3ed; border: 2px dashed #ff5722; border-radius: 8px; font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #ff5722; padding: 15px 25px; display: inline-block; margin: 20px 0; }
            .footer { margin-top: 30px; font-size: 12px; color: #999999; text-align: center; border-top: 1px solid #eeeeee; padding-top: 15px; }
        </style>
    </head>
    <body>
        <div class='container'>
            <div class='header'>
                <span class='logo'>Hungrily Foods</span>
            </div>
            <div class='content'>
                <div class='title'>Password Reset Request</div>
                <p>Hello,</p>
                <p>You requested to reset your password. Use the OTP code below to complete your password reset. This code is valid for <strong>10 minutes</strong>.</p>
                <div class='otp-box'>{$otp}</div>
                <p>If you did not request a password reset, please ignore this email.</p>
            </div>
            <div class='footer'>
                &copy; " . date('Y') . " Hungrily Foods. All rights reserved.
            </div>
        </div>
    </body>
    </html>
    ";

    return sendMailViaSocket($toEmail, $subject, $htmlBody);
}

function sendMailViaSocket(string $toEmail, string $subject, string $htmlContent): array {
    $socket = @fsockopen(SMTP_HOST, SMTP_PORT, $errno, $errstr, 15);
    if (!$socket) {
        return ['success' => false, 'error' => "Failed to connect to SMTP server: $errstr ($errno)"];
    }

    $read = function($socket) {
        $response = '';
        while ($str = fgets($socket, 515)) {
            $response .= $str;
            if (substr($str, 3, 1) === ' ') break;
        }
        return $response;
    };

    $send = function($socket, $cmd) use ($read) {
        fputs($socket, $cmd . "\r\n");
        return $read($socket);
    };

    $read($socket); // Initial banner
    $send($socket, "EHLO " . gethostname());
    
    // Auth
    $send($socket, "AUTH LOGIN");
    $send($socket, base64_encode(SMTP_USER));
    $authRes = $send($socket, base64_encode(SMTP_PASS));

    if (strpos($authRes, '235') === false) {
        fclose($socket);
        return ['success' => false, 'error' => "SMTP Authentication failed: " . trim($authRes)];
    }

    // Mail FROM & RCPT TO
    $send($socket, "MAIL FROM: <" . SMTP_USER . ">");
    $rcptRes = $send($socket, "RCPT TO: <" . $toEmail . ">");

    if (strpos($rcptRes, '250') === false && strpos($rcptRes, '251') === false) {
        fclose($socket);
        return ['success' => false, 'error' => "Recipient rejected: " . trim($rcptRes)];
    }

    // Data
    $send($socket, "DATA");

    $headers  = "MIME-Version: 1.0\r\n";
    $headers .= "Content-type: text/html; charset=utf-8\r\n";
    $headers .= "From: " . SMTP_FROM_NAME . " <" . SMTP_USER . ">\r\n";
    $headers .= "To: <" . $toEmail . ">\r\n";
    $headers .= "Subject: " . $subject . "\r\n";
    $headers .= "Date: " . date("r") . "\r\n";

    $message = $headers . "\r\n" . $htmlContent . "\r\n.";
    $dataRes = $send($socket, $message);

    $send($socket, "QUIT");
    fclose($socket);

    if (strpos($dataRes, '250') !== false) {
        return ['success' => true, 'message' => 'Email sent successfully.'];
    } else {
        return ['success' => false, 'error' => "Sending data failed: " . trim($dataRes)];
    }
}
