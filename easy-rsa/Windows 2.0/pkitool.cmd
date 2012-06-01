@echo off

::  OpenVPN -- An application to securely tunnel IP networks
::             over a single TCP/UDP port, with support for SSL/TLS-based
::             session authentication and key exchange,
::             packet encryption, packet authentication, and
::             packet compression.
::
::  Copyright (C) 2002-2010 OpenVPN Technologies, Inc. <sales@openvpn.net>
::
::  Windows port by Jernej Simoncic <jernej|s-openvpn@eternallybored.org>
::
::  This program is free software; you can redistribute it and/or modify
::  it under the terms of the GNU General Public License version 2
::  as published by the Free Software Foundation.
::
::  This program is distributed in the hope that it will be useful,
::  but WITHOUT ANY WARRANTY; without even the implied warranty of
::  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
::  GNU General Public License for more details.
::
::  You should have received a copy of the GNU General Public License
::  along with this program (see the file COPYING included with this
::  distribution); if not, write to the Free Software Foundation, Inc.,
::  59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

:: pkitool is a front-end for the openssl tool.

:: Calling scripts can set the certificate organizational 
:: unit with the KEY_OU environmental variable. 

:: Calling scripts can also set the KEY_NAME environmental
:: variable to set the "name" X509 subject field.

setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

set PROGNAME=pkitool
set VERSION=2.0
set DEBUG=0

goto main

:need_vars
	echo   Please edit the vars.cmd script to reflect your configuration,
	echo   then run it
	echo   Next, to start with a fresh PKI configuration and to delete any
	echo   previous certificates and keys, run clean-all
	echo   Finally, you can run this tool (%PROGNAME%) to build certificates/keys.
goto :eof

:usage
	echo %PROGNAME% %VERSION%
	echo Usage: %PROGNAME% [options...] [common-name]
	echo Options:
	echo   --batch    : batch mode (default)
	echo   --keysize  : Set keysize
	echo       size   : size (default=1024)
	echo   --interact : interactive mode
	echo   --server   : build server cert
	echo   --initca   : build root CA
	echo   --inter    : build intermediate CA
	echo   --pass     : encrypt private key with password
	echo   --csr      : only generate a CSR, do not sign
	echo   --sign     : sign an existing CSR
	echo   --pkcs12   : generate a combined PKCS#12 file
	echo   --pkcs11   : generate certificate on PKCS#11 token
	echo       lib    : PKCS#11 library
	echo       slot   : PKCS#11 slot
	echo       id     : PKCS#11 object id (hex string)
	echo       label  : PKCS#11 object label
	echo Standalone options:
	echo   --pkcs11-slots   : list PKCS#11 slots
	echo       lib    : PKCS#11 library
	echo   --pkcs11-objects : list PKCS#11 token objects
	echo       lib    : PKCS#11 library
	echo       slot   : PKCS#11 slot
	echo   --pkcs11-init    : initialize PKCS#11 token DANGEROUS!!!
	echo       lib    : PKCS#11 library
	echo       slot   : PKCS#11 slot
	echo       label  : PKCS#11 token label
	echo Notes:
	call :need_vars
	echo   In order to use PKCS#11 interface you must have opensc-0.10.0 or higher.
	echo Generated files and corresponding OpenVPN directives:
	echo (Files will be placed in the %KEY_DIR% directory, defined in vars.cmd)
	echo   ca.crt     -^> root certificate (--ca)
	echo   ca.key     -^> root key, keep secure (not directly used by OpenVPN)
	echo   .crt files -^> client/server certificates (--cert)
	echo   .key files -^> private keys, keep secure (--key)
	echo   .csr files -^> certificate signing request (not directly used by OpenVPN)
	echo   dh1024.pem or dh2048.pem -^> Diffie Hellman parameters (--dh)
	echo Examples:
	echo   %PROGNAME% --initca          -^> Build root certificate
	echo   %PROGNAME% --initca --pass   -^> Build root certificate with password-protected key
	echo   %PROGNAME% --server server1  -^> Build "server1" certificate/key
	echo   %PROGNAME% client1           -^> Build "client1" certificate/key
	echo   %PROGNAME% --pass client2    -^> Build password-protected "client2" certificate/key
	echo   %PROGNAME% --pkcs12 client3  -^> Build "client3" certificate/key in PKCS#12 format
	echo   %PROGNAME% --csr client4     -^> Build "client4" CSR to be signed by another CA
	echo   %PROGNAME% --sign client4    -^> Sign "client4" CSR
	echo   %PROGNAME% --inter interca   -^> Build an intermediate key-signing certificate/key
	echo                                Also see ./inherit-inter script.
	echo   %PROGNAME% --pkcs11 /usr/lib/pkcs11/lib1 0 010203 "client5 id" client5
	echo                               -^> Build \"client5\" certificate/key in PKCS#11 token
	echo Typical usage for initial PKI setup.  Build myserver, client1, and client2 cert/keys.
	echo Protect client2 key with a password.  Build DH parms.  Generated files in keys.cmd :
	echo   [edit vars.cmd with your site-specific info]
	echo   vars.cmd
	echo   clean-all.cmd
	echo   build-dh.cmd     -^> takes a long time, consider backgrounding
	echo   %PROGNAME% --initca
	echo   %PROGNAME% --server myserver
	echo   %PROGNAME% client1
	echo   %PROGNAME% --pass client2
	echo Typical usage for adding client cert to existing PKI:
	echo   vars.cmd
	echo   %PROGNAME% client-new
goto :eof

:main

:: Set tool defaults
if not defined OPENSSL set OPENSSL=openssl
if not defined PKCS11TOOL set PKCS11TOOL=pkcs11-tool

:: Set defaults
set DO_REQ=1
set REQ_EXT=
set DO_CA=1
set CA_EXT=
set DO_P12=0
set DO_P11=0
set DO_ROOT=0
set NODES_REQ=-nodes
set NODES_P12=
set BATCH=-batch
set CA=ca
:: must be set or errors of openssl.cnf
set PKCS11_MODULE_PATH=dummy
set PKCS11_PIN=dummy

:: Process options
if [%1]==[] (
	call :usage
	exit /b
)
:paramloop
	set PARAMOK=0
	if "%1"=="--keysize" (
		set KEY_SIZE=%2
		shift
		set PARAMOK=1
	)
	if "%1"=="--server" (
		set REQ_EXT=%REQ_EXT% -extensions server
		set CA_EXT=%CA_EXT% -extensions server
		set PARAMOK=1
	)
	if "%1"=="--batch" (
		set BATCH=-batch
		set PARAMOK=1
	)
	if "%1"=="--interact" (
		set BATCH=
		set PARAMOK=1
	)
	if "%1"=="--inter" (
		set CA_EXT=%CA_EXT% -extensions v3_ca
		set PARAMOK=1
	)
	if "%1"=="--initca" (
		set DO_ROOT=1
		set PARAMOK=1
	)
	if "%1"=="--pass" (
		set NODES_REQ=
		set PARAMOK=1
	)
	if "%1"=="--csr" (
		set DO_CA=0
		set PARAMOK=1
	)
	if "%1"=="--sign" (
		set DO_REQ=0
		set PARAMOK=1
	)
	if "%1"=="--pkcs12" (
		set DO_P12=1
		set PARAMOK=1
	)
	if "%1"=="--pkcs11" (
		set DO_P11=1
		set PKCS11_MODULE_PATH=%2
		set PKCS11_SLOT=%3
		set PKCS11_ID=%4
		set PKCS11_LABEL=%5
		shift /4
		set PARAMOK=1
	)

	:: standalone
	if "%1"=="--pkcs11-init" (
		set PKCS11_MODULE_PATH=%2
		set PKCS11_SLOT=%3
		set PKCS11_LABEL=%4
		if "%PKCS11_LABEL%"=="" (
			echo Please specify library name, slot and label >&2
			exit /b 1
		)
		 
		"%PKCS11TOOL%" --module "%PKCS11_MODULE_PATH%" --init-token --slot "%PKCS11_SLOT%" ^
		   --label "%PKCS11_LABEL%" && ^
		"%PKCS11TOOL%" --module "%PKCS11_MODULE_PATH%" --init-pin --slot "%PKCS11_SLOT%"

		exit /b %ERRORLEVEL%
	)
	if "%1"=="--pkcs11-slots" (
		set PKCS11_MODULE_PATH=%2
		if "%PKCS11_MODULE_PATH%"=="" (
			echo Please specify library name >&2
			exit /b 1
		)

		"%PKCS11TOOL%" --module "%PKCS11_MODULE_PATH%" --list-slots
		
		exit /b 0
	)
	if "%1"=="--pkcs11-objects" (
		set PKCS11_MODULE_PATH=%2
		set PKCS11_SLOT=%3
		if "%PKCS11_SLOT%"=="" (
			echo Please specify library name and slot >&2
			exit /b 1
		)

		"%PKCS11TOOL%" --module "%PKCS11_MODULE_PATH%" --list-objects --login --slot "%PKCS11_SLOT%"
		exit /b 0
	)

	if "%1"=="--help" (
		call :usage
		exit /b
	)
	if "%1"=="--usage" (
		call :usage
		exit /b
	)	
	if "%1"=="--version" (
		echo %PROGNAME% %VERSION%
		exit /b
	)

	:: errors
	if "%PARAMOK%"=="0" (
		set P=%1
		if "%P:~0,2%"=="--" (
			echo %PROGNAME%: unknown option: %1 >&2
			exit /b 1
		) else (
			goto paramdone
		)
	)

	shift   
if not [%1]==[] goto paramloop

:paramdone

if not "%BATCH%"=="" (
	(
		for /f "tokens=2" %%v in ('"%OPENSSL%" version') do set OPENSSL_VER=%%v
	) 2>nul

	if "!OPENSSL_VER:~0,3!"=="0.9" if /I "!OPENSSL_VER:~4,1!" LSS 7 (
		echo Batch mode is unsupported in openssl^<0.9.7 >&2
		exit /b 1
	)
)

if "%DO_P12%"=="1" if "%DO_P11%"=="1" (
	echo PKCS#11 and PKCS#12 cannot be specified together >&2
	exit /b 1
)

if "%DO_P11%"=="1" (
	findstr "^pkcs11.*=" "%KEY_CONFIG%" >nul
	if errorlevel 1 (
		echo Please edit %KEY_CONFIG% and setup PKCS#11 engine >&2
		exit /b 1
	)
)

:: If we are generating pkcs12, only encrypt the final step
if "%DO_P12%"=="1" (
	set NODES_P12=%NODES_REQ%
	set NODES_REQ=-nodes
)

if "%DO_P11%"=="1" (
	if "%PKCS11_LABEL%"=="" (
		echo PKCS#11 arguments incomplete >&2
		exit /b 1
	)
)

:: If undefined, set default key expiration intervals
if not defined KEY_EXPIRE set KEY_EXPIRE=3650
if not defined CA_EXPIRE set CA_EXPIRE=3650

:: Set organizational unit to empty string if undefined
if not defined KEY_OU set KEY_OU=.

:: Set X509 Name string to empty string if undefined
if not defined KEY_NAME set KEY_NAME=.

:: Set KEY_CN, FN (there's no elsif in cmd, so %HOW% is used as an ugly workaround)
set HOW=0
if "%DO_ROOT%"=="1" (
	set HOW=1
) else (
	if defined BATCH if defined KEY_CN set HOW=2
)
if "%HOW%"=="1" (
	if not defined KEY_CN (
		if not [%1]==[] (
			set KEY_CN=%1
		) else if defined KEY_ORG (
			set KEY_CN=%KEY_ORG% CA
		)
	)
	if defined BATCH if defined KEY_CN echo Using CA Common Name: !KEY_CN!
	
	set FN=!KEY_CN!
)
if "%HOW%"=="2" (
	echo Using Common Name: !KEY_CN!
	set FN=!KEY_CN!
	if not [%1]==[] set FN=%1
)
if "%HOW%"=="0" (
	if [%1]==[] (
		echo Please specify certificate common name
		::call :usage
		exit /b 1
	)
	set KEY_CN=%1
	set FN=!KEY_CN!
)

:: Show parameters (debugging)
if "%DEBUG%"=="1" (
	echo DO_REQ %DO_REQ%
	echo REQ_EXT %REQ_EXT%
	echo DO_CA %DO_CA%
	echo CA_EXT %CA_EXT%
	echo NODES_REQ %NODES_REQ%
	echo NODES_P12 %NODES_P12%
	echo DO_P12 %DO_P12%
	echo KEY_CN %KEY_CN%
	echo BATCH %BATCH%
	echo DO_ROOT %DO_ROOT%
	echo KEY_EXPIRE %KEY_EXPIRE%
	echo CA_EXPIRE %CA_EXPIRE%
	echo KEY_OU %KEY_OU%
	echo KEY_NAME %KEY_NAME%
	echo DO_P11 %DO_P11%
	echo PKCS11_MODULE_PATH %PKCS11_MODULE_PATH%
	echo PKCS11_SLOT %PKCS11_SLOT%
	echo PKCS11_ID %PKCS11_ID%
	echo PKCS11_LABEL %PKCS11_LABEL%
)

:: Make sure ./vars was sourced beforehand
if not defined KEY_DIR (
	call :need_vars
	exit /b 1
)
if not exist "%KEY_DIR%\"  (
	call :need_vars
	exit /b 1
)
if not defined KEY_CONFIG (
	call :need_vars
	exit /b 1
)

cd /D "%KEY_DIR%"

:: Make sure $KEY_CONFIG points to the correct version
:: of openssl.cnf
findstr /r /c:"easy-rsa version 2\.[0-9]" "%KEY_CONFIG%" > nul
if errorlevel 1 (
	echo %PROGNAME%: KEY_CONFIG (set by the vars.cmd script^) is pointing to the wrong
	echo version of openssl.cnf: %KEY_CONFIG%
	echo The correct version should have a comment that says: easy-rsa version 2.x
	exit /b 1
)

:: Build root CA
if "%DO_ROOT%"=="1" (
		
	"%OPENSSL%" req %BATCH% -days %CA_EXPIRE% %NODES_REQ% -new -newkey rsa:%KEY_SIZE% -sha1 ^
	   -x509 -keyout "%CA%.key" -out "%CA%.crt" -config "%KEY_CONFIG%"
		
) else (
	:: Make sure CA key/cert is available
	set ISCA=0
	if "%DO_CA%"=="1" set ISCA=1
	if "%DO_P12%"=="1" set ISCA=1
	if "!ISCA!"=="1" (
		set ISCERT=0
		if not exist "%CA%.crt" set ISCERT=1
		if not exist "%CA%.key" set ISCERT=1
		if "!ISCERT!"=="1" (		
			echo %PROGNAME%: Need a readable %CA%.crt and %CA%.key in %KEY_DIR%
			echo Try %PROGNAME% --initca to build a root certificate/key.
			exit /b 1
		)
	)

	:: Generate key for PKCS#11 token
	set PKCS11_ARGS=
	if "%DO_P11%"=="1" (
		::TODO: find out how to not echo pin
		set /p PKCS11_PIN=User pin: 

		echo Generating key pair on PKCS#11 token...
		"%PKCS11TOOL%" --module "%PKCS11_MODULE_PATH%" --keypairgen ^
		   --login --pin "!PKCS11_PIN!" ^
		   --key-type rsa:1024 ^
		   --slot "%PKCS11_SLOT%" --id "%PKCS11_ID%" --label "%PKCS11_LABEL%" || exit /b 1
		set PKCS11_ARGS=-engine pkcs11 -keyform engine -key %PKCS11_SLOT%:%PKCS11_ID%
	)

	:: Build cert/key
	if not "%DO_REQ%"=="0" (
		"%OPENSSL%" req %BATCH% -days "%KEY_EXPIRE%" %NODES_REQ% -new -newkey rsa:%KEY_SIZE% ^
		   -keyout "%FN%.key" -out "%FN%.csr" %REQ_EXT% -config "%KEY_CONFIG%" !PKCS11_ARGS!
	)
	if not errorlevel 1 if not "%DO_CA%"=="0" (
		"%OPENSSL%" ca %BATCH% -days "%KEY_EXPIRE%" -out "%FN%.crt" ^
		   -in "%FN%.csr" %CA_EXT% -md sha1 -config "%KEY_CONFIG%"
	)
	if not errorlevel 1 if not "%DO_P12%"=="0" (
		"%OPENSSL%" pkcs12 -export -inkey "%FN%.key" \
		   -in "%FN%.crt" -certfile "%CA%.crt" -out "%FN%.p12" %NODES_P12%
	)

	:: Load certificate into PKCS#11 token
	if "%DO_P11%"=="1" (
		"%OPENSSL%" x509 -in "%FN%.crt" -inform PEM -out "%FN%.crt.der" -outform DER && ^
		  "%PKCS11TOOL%" --module "%PKCS11_MODULE_PATH%" --write-object "%FN%.crt.der" --type cert ^
			--login --pin "!PKCS11_PIN!" \
			--slot "%PKCS11_SLOT%" --id "%PKCS11_ID%" --label "%PKCS11_LABEL%"
		
		if exist "%FN%.crt.der" del "%FN%.crt.der"
	)
)
