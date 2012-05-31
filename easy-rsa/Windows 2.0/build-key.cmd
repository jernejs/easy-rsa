@echo off

:: Make a certificate/private key pair using a locally generated
:: root certificate.

if not defined EASY_RSA set EASY_RSA=.
if [%1]==[] (
	echo Please specify certificate name
) else (
	call "%EASY_RSA%\pkitool.cmd" --interact %*
)