:: --------------------------------------------------------------
::	项目: CloudflareSpeedTest 自动更新 3Proxy
::	版本: 1.0.5
::	作者: XIU2
::	项目: https://github.com/XIU2/CloudflareSpeedTest
:: --------------------------------------------------------------
@echo off
Setlocal Enabledelayedexpansion

::判断是否已获得管理员权限

>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system" 

if '%errorlevel%' NEQ '0' (  
    goto UACPrompt  
) else ( goto gotAdmin )  

::写出 vbs 脚本以管理员身份运行本脚本（bat）

:UACPrompt  
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs" 
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs" 
    "%temp%\getadmin.vbs" 
    exit /B  

::如果临时 vbs 脚本存在，则删除
  
:gotAdmin  
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )  
    pushd "%CD%" 
    CD /D "%~dp0" 


::上面是判断是否以获得管理员权限，如果没有就去获取，下面才是本脚本主要代码



echo 开始测速...


:: 这个 RESET 是给需要 "找不到满足条件的 IP 就一直循环测速下去" 功能的人准备的
:: 如果需要这个功能就把下面 3 个 goto :STOP 改为 goto :RESET 即可
:RESET


:: 这里可以自己添加、修改 CloudflareST 的运行参数，echo.| 的作用是自动回车退出程序（不再需要加上 -p 0 参数了）
echo.|CloudflareST.exe -o "result_3proxy.txt"

:: 判断结果文件是否存在，如果不存在说明结果为 0
if not exist result_3proxy.txt (
    echo.
    echo CloudflareST 测速结果 IP 数量为 0，跳过下面步骤...
    goto :STOP
)


:: 获取第一行的最快 IP
for /f "tokens=1 delims=," %%i in (result_3proxy.txt) do (
    set /a n+=1 
    If !n!==2 (
        set bestip=%%i
        goto :END
    )
)
:END

:: 判断刚刚获取的最快 IP 是否为空
if "%bestip%"=="" (
    echo.
    echo CloudflareST 测速结果 IP 数量为 0，跳过下面步骤...
    goto :STOP



:: 下面这段代码是 "找不到满足条件的 IP 就一直循环测速下去" 才需要的代码
:: 考虑到当指定了下载速度下限，但一个满足全部条件的 IP 都没找到时，CloudflareST 就会输出所有 IP 结果
:: 因此当你指定 -sl 参数时，需要移除下面这段代码开头的这个 :: 冒号注释符，来做文件行数判断（比如下载测速数量：10 个，那么下面的值就设在为 11）
::set /a v=0
::for /f %%a in ('type result.txt') do set /a v+=1
::if %v% GTR 11 (
::    echo.
::    echo CloudflareST 测速结果没有找到一个完全满足条件的 IP，重新测速...
::    goto :RESET
::)


echo %bestip%>nowip_3proxy.txt
echo.
echo 新 IP 为 %bestip%


:: 进入3Proxy 程序所在目录
cd 3proxy
:: 请确保运行该脚本前，已经测试过 3Proxy 可以正常运行并使用！

net stop 3proxy

:: 定义文件名和目标行号
set filename=3proxy.cfg
set targetLine=5
set newContent=parent 1000 tcp %bestip% 443

:: 初始化行计数器
set lineCount=0

:: 创建一个临时文件
set tempFile=temp.txt

:: 逐行读取文件内容并修改目标行
(for /f "tokens=*" %%i in (%filename%) do (
    set /a lineCount+=1
    if !lineCount! equ %targetLine% (
        echo %newContent%
    ) else (
        echo %%i
    )
)) > %tempFile%

:: 替换原文件
move /y %tempFile% %filename%


net start 3proxy

echo 完成...
echo.
:STOP
pause 