@echo off

::
:: Build a root certificate
::

if not defined EASY_RSA set EASY_RSA=.
call "%EASY_RSA%\pkitool.cmd" --interact --initca %*
