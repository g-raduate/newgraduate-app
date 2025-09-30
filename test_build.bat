@echo off
cd /d "E:\Programing\newgraduate"
echo Testing Flutter build...
C:\flutter\bin\flutter.bat build apk --debug --no-sound-null-safety
if %ERRORLEVEL% EQU 0 (
    echo.
    echo SUCCESS: Build completed successfully!
    echo APK file should be in: build\app\outputs\flutter-apk\
) else (
    echo.
    echo ERROR: Build failed with error code %ERRORLEVEL%
)
pause
