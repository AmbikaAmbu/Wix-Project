@echo off

echo ========================
echo RESTORE PACKAGES
echo ========================

nuget restore MyApp.sln

IF %ERRORLEVEL% NEQ 0 EXIT /B 1

echo ========================
echo BUILD APPLICATION
echo ========================

msbuild MyApp.sln ^
 /p:Configuration=Release

IF %ERRORLEVEL% NEQ 0 EXIT /B 1

echo ========================
echo PREPARE PUBLISH FOLDER
echo ========================

IF EXIST Publish rmdir Publish /S /Q

mkdir Publish

xcopy src\bin\Release Publish /E /Y

IF %ERRORLEVEL% NEQ 0 EXIT /B 1

echo ========================
echo GENERATE WIX FILES
echo ========================

cd Installer

call Harvest.cmd

IF %ERRORLEVEL% NEQ 0 EXIT /B 1

cd ..

echo ========================
echo BUILD MSI
echo ========================

msbuild Installer\Installer.wixproj ^
 /p:Configuration=Release ^
 /p:ProductVersion=1.0.%bamboo_buildNumber%

IF %ERRORLEVEL% NEQ 0 EXIT /B 1

echo ========================
echo DONE
echo ========================