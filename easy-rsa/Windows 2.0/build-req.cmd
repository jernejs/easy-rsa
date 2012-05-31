@echo off

:: Build a certificate signing request and private key.  Use this
:: when your root certificate and key is not available locally.

if not defined EASY_RSA set EASY_RSA=.
if [%1]==[] (
	echo Please specify certificate name
) else (
	call "%EASY_RSA%\pkitool.cmd" --interact --csr %*
)