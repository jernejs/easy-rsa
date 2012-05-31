@echo off

:: Build Diffie-Hellman parameters for the server side
:: of an SSL/TLS connection.

if exist "%KEY_DIR%\" if defined KEY_SIZE (
	"%OPENSSL%" dhparam -out "%KEY_DIR%/dh%KEY_SIZE%.pem" %KEY_SIZE%
) else (
    echo Please run the vars.cmd script first
    echo Make sure you have edited it to reflect your configuration.
)
