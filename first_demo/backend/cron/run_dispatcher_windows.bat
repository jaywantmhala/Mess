@echo off
REM =========================================================================
REM Hungrily Foods - RazorpayX Automated Vendor Payout Dispatcher (Windows)
REM =========================================================================
REM Automatically detects PHP binary from common XAMPP / Windows paths,
REM then executes payout_dispatcher.php in Asia/Kolkata (IST) context.
REM =========================================================================

set SCRIPT_DIR=%~dp0
set DISPATCHER_PHP=%SCRIPT_DIR%payout_dispatcher.php

REM 1. Detect PHP Executable
if exist "C:\xampp\php\php.exe" (
    set PHP_BIN=C:\xampp\php\php.exe
    goto RUN
)
if exist "C:\php-8.5.3\php.exe" (
    set PHP_BIN=C:\php-8.5.3\php.exe
    goto RUN
)
if exist "C:\php\php.exe" (
    set PHP_BIN=C:\php\php.exe
    goto RUN
)
if exist "C:\Program Files\PHP\php.exe" (
    set PHP_BIN=C:\Program Files\PHP\php.exe
    goto RUN
)

REM Fallback to PATH
set PHP_BIN=php

:RUN
REM Execute dispatcher (dispatcher internally appends to backend/logs/payout_cron.log)
"%PHP_BIN%" "%DISPATCHER_PHP%"
exit /b %ERRORLEVEL%
