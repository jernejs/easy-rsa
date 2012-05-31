@echo off

setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set CNFDIR=%~1
if not defined CNFDIR set CNFDIR=%EASY_RSA%

set cnf=%CNFDIR%\openssl.cnf

if defined OPENSSL (
	for /f "tokens=2" %%v in ('"%OPENSSL%" version') do set OPENSSL_VER=%%v

	echo !OPENSSL_VER:~0,5!

	if "!OPENSSL_VER:~0,5!"=="0.9.6" (
		set cnf=%CNFDIR%\openssl-0.9.6.cnf
	) else if "!OPENSSL_VER:~0,5!"=="0.9.8" (
		set cnf=%CNFDIR%\openssl-0.9.8.cnf
	) else if "!OPENSSL_VER:~0,5!"=="1.0.0" (
		set cnf=%CNFDIR%\openssl-1.0.0.cnf
	) else (
		set cnf=%CNFDIR%\openssl.cnf
	)
) 2>nul

echo %cnf%

if not exist "%cnf%" (
    echo ************************************************************** >&2
    echo   No %cnf% file could be found >&2
    echo   Further invocations will fail >&2
    echo ************************************************************** >&2
)

exit /b 0
