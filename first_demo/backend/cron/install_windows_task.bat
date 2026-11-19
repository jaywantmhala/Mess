@echo off
REM =========================================================================
REM Hungrily Foods - Install Windows Task Scheduler Job
REM =========================================================================
REM Schedules HungrilyVendorPayoutScheduler to run every minute indefinitely.
REM The script runs silently in the background and logs to backend/logs/payout_cron.log.
REM =========================================================================

set SCRIPT_DIR=%~dp0
set VBS_RUNNER=%SCRIPT_DIR%run_dispatcher_silent.vbs

echo Installing Hungrily Automated Payout Scheduler (Runs every 1 minute)...
echo Runner: %VBS_RUNNER%

schtasks /create /tn "HungrilyVendorPayoutScheduler" /tr "wscript.exe \"%VBS_RUNNER%\"" /sc minute /mo 1 /f

if %ERRORLEVEL% equ 0 (
    echo.
    echo ================================================================
    echo SUCCESS: Task "HungrilyVendorPayoutScheduler" created successfully!
    echo It will execute silently in background every minute.
    echo Logs: %SCRIPT_DIR%..\logs\payout_cron.log
    echo ================================================================
) else (
    echo.
    echo FAILED: Please right-click this script and select 'Run as Administrator'.
)
pause
