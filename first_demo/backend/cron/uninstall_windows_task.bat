@echo off
echo Removing Hungrily Automated Payout Scheduler Task...
schtasks /delete /tn "HungrilyVendorPayoutScheduler" /f
if %ERRORLEVEL% equ 0 (
    echo Successfully removed HungrilyVendorPayoutScheduler task.
) else (
    echo Task was not found or already removed.
)
pause
