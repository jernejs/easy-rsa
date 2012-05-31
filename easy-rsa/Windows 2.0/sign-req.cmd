@echo off

:: Sign a certificate signing request (a .csr file)
:: with a local root certificate and key.

if not defined EASY_RSA set EASY_RSA=.
if [%1]==[] (
	echo Please specify certificate name
) else (
	call "%EASY_RSA%\pkitool.cmd" --interact --sign %*
)