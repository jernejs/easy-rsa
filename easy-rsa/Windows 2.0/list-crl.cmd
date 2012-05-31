@echo off

:: list revoked certificates

if [%1]==[] (
	set CRL=crl.pem
) else (
	set CRL=%1
)

if defined KEY_DIR (
    cd /d "%KEY_DIR%" && ^
	"%OPENSSL%" crl -text -noout -in "%CRL%"
) else (
    echo Please run the vars.cmd script first
    echo Make sure you have edited it to reflect your configuration.
)
