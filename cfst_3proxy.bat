:: --------------------------------------------------------------
::	��Ŀ: CloudflareSpeedTest �Զ����� 3Proxy
::	�汾: 1.0.5
::	����: XIU2
::	��Ŀ: https://github.com/XIU2/CloudflareSpeedTest
:: --------------------------------------------------------------
@echo off
Setlocal Enabledelayedexpansion

::�ж��Ƿ��ѻ�ù���ԱȨ��

>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system" 

if '%errorlevel%' NEQ '0' (  
    goto UACPrompt  
) else ( goto gotAdmin )  

::д�� vbs �ű��Թ���Ա������б��ű���bat��

:UACPrompt  
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs" 
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs" 
    "%temp%\getadmin.vbs" 
    exit /B  

::�����ʱ vbs �ű����ڣ���ɾ��
  
:gotAdmin  
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )  
    pushd "%CD%" 
    CD /D "%~dp0" 


::�������ж��Ƿ��Ի�ù���ԱȨ�ޣ����û�о�ȥ��ȡ��������Ǳ��ű���Ҫ����



echo ��ʼ����...


:: ��� RESET �Ǹ���Ҫ "�Ҳ������������� IP ��һֱѭ��������ȥ" ���ܵ���׼����
:: �����Ҫ������ܾͰ����� 3 �� goto :STOP ��Ϊ goto :RESET ����
:RESET


:: ��������Լ���ӡ��޸� CloudflareST �����в�����echo.| ���������Զ��س��˳����򣨲�����Ҫ���� -p 0 �����ˣ�
echo.|CloudflareST.exe -o "result_3proxy.txt"

:: �жϽ���ļ��Ƿ���ڣ����������˵�����Ϊ 0
if not exist result_3proxy.txt (
    echo.
    echo CloudflareST ���ٽ�� IP ����Ϊ 0���������沽��...
    goto :STOP
)


:: ��ȡ��һ�е���� IP
for /f "tokens=1 delims=," %%i in (result_3proxy.txt) do (
    set /a n+=1 
    If !n!==2 (
        set bestip=%%i
        goto :END
    )
)
:END

:: �жϸոջ�ȡ����� IP �Ƿ�Ϊ��
if "%bestip%"=="" (
    echo.
    echo CloudflareST ���ٽ�� IP ����Ϊ 0���������沽��...
    goto :STOP



:: ������δ����� "�Ҳ������������� IP ��һֱѭ��������ȥ" ����Ҫ�Ĵ���
:: ���ǵ���ָ���������ٶ����ޣ���һ������ȫ�������� IP ��û�ҵ�ʱ��CloudflareST �ͻ�������� IP ���
:: ��˵���ָ�� -sl ����ʱ����Ҫ�Ƴ�������δ��뿪ͷ����� :: ð��ע�ͷ��������ļ������жϣ��������ز���������10 ������ô�����ֵ������Ϊ 11��
::set /a v=0
::for /f %%a in ('type result.txt') do set /a v+=1
::if %v% GTR 11 (
::    echo.
::    echo CloudflareST ���ٽ��û���ҵ�һ����ȫ���������� IP�����²���...
::    goto :RESET
::)


echo %bestip%>nowip_3proxy.txt
echo.
echo �� IP Ϊ %bestip%


:: ����3Proxy ��������Ŀ¼
cd 3proxy
:: ��ȷ�����иýű�ǰ���Ѿ����Թ� 3Proxy �����������в�ʹ�ã�

net stop 3proxy

:: �����ļ�����Ŀ���к�
set filename=3proxy.cfg
set targetLine=5
set newContent=parent 1000 tcp %bestip% 443

:: ��ʼ���м�����
set lineCount=0

:: ����һ����ʱ�ļ�
set tempFile=temp.txt

:: ���ж�ȡ�ļ����ݲ��޸�Ŀ����
(for /f "tokens=*" %%i in (%filename%) do (
    set /a lineCount+=1
    if !lineCount! equ %targetLine% (
        echo %newContent%
    ) else (
        echo %%i
    )
)) > %tempFile%

:: �滻ԭ�ļ�
move /y %tempFile% %filename%


net start 3proxy

echo ���...
echo.
:STOP
pause 