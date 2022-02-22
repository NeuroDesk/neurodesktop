:: Windows run NeuroDesktop
:: Thom Shaw 20211208
::check for docker, remove old versions of neurodesktop
:: open new version of neurodesktop
:: wait for keypress and close

SET "version=latest"

ECHO "Checking if Docker is installed" 
@echo off

docker ps 
if %ERRORLEVEL% GEQ 1 goto setupdocker 

ECHO "Starting NeuroDesktop:"
ECHO "Remove old versions of NeuroDesktop
ECHO "If none are available the daemon will throw an error which can be safely ignored:"
ECHO "Checking if the following container is available:"
docker stop neurodesktop
ECHO "Checking if the following container is available: %version%"
docker rm neurodesktop
echo "--------------------------------------------------------------"
ECHO "Starting NeuroDesktop, please wait..."
echo "--------------------------------------------------------------"
docker pull vnmd/neurodesktop:%version%
docker run --shm-size=1gb -it -d --privileged --name neurodesktop -v C:/neurodesktop-storage:/neurodesktop-storage -p 8080:8080 -h neurodesktop-%version% vnmd/neurodesktop:%version%
::poll for the guac server using curl  curl http://localhost:8080
:: possible responses while booting are curl: (52) Empty reply from server
:: if running it will say <!DOCTYPE html>
:: if not started it will say curl: (7) Failed to connect to localhost port 8080: Connection refused

SET browse=
FOR /F "tokens=* USEBACKQ" %%G IN (`reg QUERY HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice ^| findstr /r /c:"ChromeHTML" /c:"MSEdgeHTM"`) DO (SET browse=%%G)

:loop
echo "--------------------------------------------------------------"
echo "Waiting for Neurodesk, please wait and your browser will open shortly"
echo "--------------------------------------------------------------"
timeout /t 5 /nobreak
echo "If this takes longer than 10 mins please try restarting Docker or check your internet connection"
(curl http://localhost:8080 | find "<!doctype html>") >nul 2>&1

if errorlevel 1 goto loop
cls
echo "Docker started, opening session"
explorer "http://localhost:8080/#/?username=user&password=password"
echo "   _     _     _     _     _     _     _       _     _       _     _     _     _     _     _     _     _     _   " 
echo "  / \   / \   / \   / \   / \   / \   / \     / \   / \     / \   / \   / \   / \   / \   / \   / \   / \   / \  "
echo " ( W ) ( E ) ( L ) ( C ) ( O ) ( M ) ( E )   ( T ) ( O )   ( N ) ( E ) ( U ) ( R ) ( O ) ( D ) ( E ) ( S ) ( K ) "
echo "  \_/   \_/   \_/   \_/   \_/   \_/   \_/     \_/   \_/     \_/   \_/   \_/   \_/   \_/   \_/   \_/   \_/   \_/  "  
echo.
if not defined browse echo Google Chrome or Microsoft Edge Browser is recommended for use with Neurodesktop. Other browsers may work. Please try Chrome or Edge if running into issues.                                                                                   
set /p=NeuroDesktop is running - press ENTER key to shutdown and quit NeuroDesktop!
ECHO "The following container has been stopped:"
docker stop neurodesktop
ECHO "The following container has been removed:"
docker rm neurodesktop
exit 0

:setupdocker
echo "--------------------------------------------------------------"
ECHO "Please follow the instruction to download and install Docker:"
echo "---------------------------------------------------------------"
explorer "https://docs.docker.com/desktop/windows/install/"
set /p=press enter to quit, then try again once Docker is installed and running
exit 0