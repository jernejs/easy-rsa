@echo off

:: Initialize the %KEY_DIR% directory.
:: Note that this script does a
:: rmdir /s /q on %KEY_DIR% so be careful!

if defined KEY_DIR (
    rd /s /q "%KEY_DIR%"
    md "%KEY_DIR%"
	set /p =<nul> "%KEY_DIR%\index.txt"
	echo 01>"%KEY_DIR%\serial"
) else (
    echo Please run the vars.cmd script first
    echo Make sure you have edited it to reflect your configuration.
)
