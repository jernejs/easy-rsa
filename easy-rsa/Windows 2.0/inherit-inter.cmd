@echo off

:: Build a new PKI which is rooted on an intermediate certificate generated
:: by ./build-inter or ./pkitool --inter from a parent PKI.  The new PKI should
:: have independent vars settings, and must use a different KEY_DIR directory
:: from the parent.  This tool can be used to generate arbitrary depth
:: certificate chains.
::
:: To build an intermediate CA, follow the same steps for a regular PKI but
:: replace ./build-key or ./pkitool --initca with this script.

:: The EXPORT_CA file will contain the CA certificate chain and should be
:: referenced by the OpenVPN "ca" directive in config files.  The ca.crt file
:: will only contain the local intermediate CA -- it's needed by the easy-rsa
:: scripts but not by OpenVPN directly.
set EXPORT_CA="export-ca.crt"

set BAD_PARAM=0
if [%1]==[] set BAD_PARAM=1
if [%2]==[] set BAD_PARAM=1
if not [%3]==[] set BAD_PARAM=1
if "%BAD_PARAM%"=="1" (
	echo usage: %~nx0 ^<parent-key-dir^> ^<common-name^>
	echo parent-key-dir: the KEY_DIR directory of the parent PKI
	echo common-name: the common name of the intermediate certificate in the parent PKI
	exit /b 1
)

if defined KEY_DIR (
	copy "%1\%2.crt" "%KEY_DIR%\ca.crt"
	copy "%1\%2.key" "%KEY_DIR%\ca.key"

	if exist "%1\%EXPORT_CA%" (
		set PARENT_CA=%1\%EXPORT_CA%
	) else (
		set PARENT_CA=%1\ca.crt
	)
	copy "%PARENT_CA%" "%KEY_DIR%\%EXPORT_CA%"
	type "%KEY_DIR%\ca.crt" >> "%KEY_DIR%\%EXPORT_CA%"
) else (
    echo Please run the vars.cmd script first
    echo Make sure you have edited it to reflect your configuration.
)
