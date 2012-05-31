@echo off

:: Similar to build-key, but protect the private key
:: with a password.

if not defined EASY_RSA set EASY_RSA=.
if [%1]==[] (
	echo Please specify certificate name
) else (
	call "%EASY_RSA%\pkitool.cmd" --interact --pass %*
)