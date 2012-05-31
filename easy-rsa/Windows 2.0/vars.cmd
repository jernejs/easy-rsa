@echo off
:: easy-rsa parameter settings

:: This variable should point to
:: the top level of the easy-rsa
:: tree.
set EASY_RSA=%~dp0
set EASY_RSA=%EASY_RSA:~0,-1%

::
:: This variable should point to
:: the requested executables
::
::set OPENSSL=openssl
set OPENSSL=%PROGRAMFILES%\OpenVPN\bin\openssl.exe
:: %ProgramFiles(x86)% can't be used inside if ( ... ) block
if not exist "%OPENSSL%" set OPENSSL=%ProgramFiles(x86)%\OpenVPN\bin\openssl.exe
set PKCS11TOOL=pkcs11-tool


:: This variable should point to
:: the openssl.cnf file included
:: with easy-rsa.
::set KEY_CONFIG=path
for /F "usebackq tokens=1" %%d in (`"%EASY_RSA%\whichopensslcnf.cmd"`) do set KEY_CONFIG=%%d

:: Edit this variable to point to
:: your soon-to-be-created key
:: directory.
::
:: WARNING: clean-all will do
:: a rmdir /s /q on this directory
:: so make sure you define
:: it correctly!
set KEY_DIR=%EASY_RSA%\keys

:: Issue rm -rf warning
echo NOTE: If you run clean-all.cmd, I will be doing a rmdir /s /q on %KEY_DIR%

:: PKCS11 fixes
set PKCS11_MODULE_PATH=dummy
set PKCS11_PIN=dummy

:: Increase this to 2048 if you
:: are paranoid.  This will slow
:: down TLS negotiation performance
:: as well as the one-time DH parms
:: generation process.
set KEY_SIZE=2048

:: In how many days should the root CA key expire?
set CA_EXPIRE=3650

:: In how many days should certificates expire?
set KEY_EXPIRE=3650

:: These are the default values for fields
:: which will be placed in the certificate.
:: Don't leave any of these fields blank.
set KEY_COUNTRY=US
set KEY_PROVINCE=CA
set KEY_CITY=SanFrancisco
set KEY_ORG=Fort-Funston
set KEY_EMAIL=mail@host.domain
set KEY_CN=changeme
set KEY_NAME=changeme
set KEY_OU=changeme
set PKCS11_MODULE_PATH=changeme
set PKCS11_PIN=1234
