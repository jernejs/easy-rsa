@echo off

:: revoke a certificate, regenerate CRL,
:: and verify revocation

set CRL="crl.pem"
set RT="revoke-test.pem"

set BAD_PARAM=0
if [%1]==[] set BAD_PARAM=1
if not [%2]==[] set BAD_PARAM=1
if "%BAD_PARAM%"=="1" (
	echo usage: %~nx0 ^<cert-name-base^>
	exit 1
)

if defined KEY_DIR (
	pushd "%KEY_DIR%"
	del /q "%RT%" 2>nul

	:: set defaults
	set KEY_CN=.
	set KEY_OU=.
	set KEY_NAME=.

	:: revoke key and generate a new CRL
	"%OPENSSL%" ca -revoke "%1.crt" -config "%KEY_CONFIG%"

	:: generate a new CRL -- try to be compatible with
	:: intermediate PKIs
	"%OPENSSL%" ca -gencrl -out "%CRL%" -config "%KEY_CONFIG%"
	if exist export-ca.crt (
		type export-ca.crt "%CRL%" > "%RT%"
	) else (
		type ca.crt "%CRL%" > "%RT%"
	)
	
	:: verify the revocation
	"%OPENSSL%" verify -CAfile "%RT%" -crl_check "%1.crt"

	popd
) else (
    echo Please run the vars.cmd script first
    echo Make sure you have edited it to reflect your configuration.
)
