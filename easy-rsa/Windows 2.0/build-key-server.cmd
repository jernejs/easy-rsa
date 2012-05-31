@echo off

:: Make a certificate/private key pair using a locally generated
:: root certificate.
::
:: Explicitly set nsCertType to server using the "server"
:: extension in the openssl.cnf file.

if not defined EASY_RSA set EASY_RSA=.
if [%1]==[] (
	echo Please specify certificate name
) else (
	call "%EASY_RSA%\pkitool.cmd" --interact --server %*
)
