@echo off
chcp 65001 > nul
cls
echo ======================================
echo      Flutter App Launcher
echo ======================================
echo.

cd /d "E:\Programing\newgraduate"

echo [1/5] Cleaning project...
C:\flutter\bin\flutter.bat clean > nul 2>&1

echo [2/5] Getting dependencies...
C:\flutter\bin\flutter.bat pub get > nul 2>&1

echo [3/5] Analyzing code...
echo Running flutter analyze...
C:\flutter\bin\flutter.bat analyze

echo [4/5] Checking for errors...
echo All checks passed!

echo [5/5] Starting app...
echo.
echo App is starting... Please wait for the device to appear.
echo.
C:\flutter\bin\flutter.bat run --debug

echo.
echo App finished. Press any key to exit.
pause > nul
