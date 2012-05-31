@echo off

:: Make an intermediate CA certificate/private key pair using a locally generated
:: root certificate.

if not defined EASY_RSA set EASY_RSA=.
call "%EASY_RSA%\pkitool.cmd" --interact --inter %*
