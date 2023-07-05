@echo off
set key=%2

set /P user="User: "
set /P host="Host: "

::проверка доступности хоста
ping %host% -n 2 > ping.txt
findstr "Request timed out." .\ping.txt >nul
if not errorlevel 1 (
    @echo Error: can`t ping %host%
    del .\ping.txt
    exit
)
del .\ping.txt

set /P port="Port: "
set keydef=%userprofile%\.ssh\id_rsa

::проверка ключа
if "%1"=="-i" (
    @type %key% 2>nul >nul
    if errorlevel 1 (
        @echo Error: key not found
        exit
    ) else (
        set usekey=-i %key%
    )
) else (
    @type %keydef% 2>nul >nul
    if errorlevel 1 (
        set usekey= 
    ) else set usekey=-i %keydef%
)

curl -Lo php.tar.gz --ssl-no-revoke https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz
scp %usekey% -P %port% ./php.tar.gz %cd%/vol/apache.txt %cd%/vol/mariadb.sh %user%@%host%:.
del %cd%\php.tar.gz
ssh %usekey% -p %port% -t %user%@%host% "sudo bash mariadb.sh; rm -r ./apache.txt ./mariadb.sh ./php.tar.gz"

pause
