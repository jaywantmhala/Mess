@echo off
title first_demo PHP Backend Server
color 0A
cls

echo.
echo  ================================================
echo    first_demo ^| PHP REST API Backend
echo    Database : MySQL 8.0  (visible in Workbench!)
echo    Server   : PHP Built-in Server
echo  ================================================
echo.

REM Check PHP
php --version >nul 2>&1
if errorlevel 1 (
    color 0C
    echo  [ERROR] PHP not found in PATH!
    pause & exit /b 1
)
echo  [OK] PHP:
php -r "echo '         v' . PHP_VERSION . PHP_EOL;"

REM Check pdo_mysql
php -r "exit(extension_loaded('pdo_mysql') ? 0 : 1);" >nul 2>&1
if errorlevel 1 (
    color 0C
    echo  [ERROR] pdo_mysql extension is not enabled in php.ini!
    pause & exit /b 1
)
echo  [OK] pdo_mysql extension enabled

REM Check MySQL service is running
sc query MySQL80 | findstr "RUNNING" >nul 2>&1
if errorlevel 1 (
    color 0E
    echo  [WARNING] MySQL80 service may not be running.
    echo  Starting MySQL80 service...
    net start MySQL80
)
echo  [OK] MySQL80 service is running

echo.
echo  ================================================
echo   Server running at ^> http://0.0.0.0:8000
echo   Local Address     ^> http://localhost:8000
echo.
echo   Endpoints:
echo   POST http://localhost:8000/api/auth/signup
echo   POST http://localhost:8000/api/auth/login
echo   GET  http://localhost:8000/api/auth/me
echo   POST http://localhost:8000/api/auth/logout
echo.
echo   MySQL DB : first_demo_db  (visible in Workbench)
echo   Tables   : customers, vendors, hotels
echo.
echo   Press Ctrl+C to stop the server
echo  ================================================
echo.

cd /d "%~dp0"
php -S 0.0.0.0:8000 router.php
