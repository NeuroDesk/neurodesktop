rem "Checking if Docker is installed"

if "Get-Process 'com.docker.proxy' &&  echo $? " == "False" (
 echo "--------------------------------------------------------------"
 ECHO "Please follow the instruction to download and install Docker:"
echo "---------------------------------------------------------------"
  explorer "www.hub.docker.com/editions/community/docker-ce-desktop-windows"
) else (
::"I don't like to think of PowerShell as "CMD with the stupid parts removed". I like to think of it as "Bash without any of the useful bits".
ECHO "Starting NeuroDesktop:"
ECHO "Remove old versions of NeuroDesktop - if none are available the daemon will throw an error which can be safely ignored: "
ECHO "The following container has been stopped:"
docker stop neurodesktop
ECHO "The following container has been removed:"
docker rm neurodesktop

ECHO "Running NeuroDesktop, please wait..."
##https://superuser.com/questions/768553/start-program-wait-until-it-outputs-certain-string-then-continue 
docker run --shm-size=1gb -it --privileged --name neurodesktop -v C:/neurodesktop-storage:/neurodesktop-storage -p 8080:8080 -h neurodesktop-20211028 vnmd/neurodesktop:20211028 |
(:a
if find "Guacamole proxy daemon (guacd)" || goto :next
else)
echo "waiting for neurodesk to start"
timeout /t 5 /nobreak
goto:a
:next

echo "Docker started, opening session"
explorer "http://localhost:8080/#/?username=user&password=password"


set /p=NeuroDesktop is running - press ENTER key to shutdown and quit NeuroDesktop!
ECHO "The following container has been stopped:"
docker stop neurodesktop
ECHO "The following container has been removed:"
docker rm neurodesktop
) || (
echo "-------------------------"
echo "Docker Build failed!"
echo "-------------------------"
)
)