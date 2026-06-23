# Wix-Project
#complete code for creating devops pipeline in bamboo ,and create wix installer that handle by bamboo#

A truly complete solution depends on your application, but below is a realistic end-to-end example that many teams use:

Source code in Bitbucket
Bamboo CI pipeline
.NET Framework application
WiX v3 MSI installer
Automatic versioning from Bamboo build number
Artifact publishing
Optional deployment stage
Solution Structure
MyApp
│
├── src
│   ├── MyApp.csproj
│   └── Program.cs
│
├── Installer
│   ├── Product.wxs
│   ├── AppFiles.wxs
│   ├── Harvest.cmd
│   └── Installer.wixproj
│
├── Build
│   └── build-installer.bat
│
└── MyApp.sln
1. Product.wxs

Installer\Product.wxs

<?xml version="1.0" encoding="UTF-8"?>

<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">

  <Product
      Id="*"
      Name="My Application"
      Language="1033"
      Version="$(var.ProductVersion)"
      Manufacturer="MyCompany"
      UpgradeCode="E29AAA11-1111-4444-8888-123456789999">

    <Package
        InstallerVersion="500"
        Compressed="yes"
        InstallScope="perMachine" />

    <MajorUpgrade
        DowngradeErrorMessage="A newer version is already installed."/>

    <MediaTemplate EmbedCab="yes"/>

    <Feature Id="ProductFeature"
             Title="My Application"
             Level="1">

      <ComponentGroupRef Id="AppFiles"/>

    </Feature>

  </Product>

</Wix>
2. Harvest.cmd

This automatically generates component entries for all files.

Installer\Harvest.cmd

@echo off

set WIXBIN=C:\Program Files (x86)\WiX Toolset v3.11\bin

"%WIXBIN%\heat.exe" dir "..\Publish" ^
-cg AppFiles ^
-dr INSTALLFOLDER ^
-gg ^
-g1 ^
-srd ^
-sfrag ^
-out AppFiles.wxs
3. Installer.wixproj

Installer\Installer.wixproj

<Project ToolsVersion="4.0"
 xmlns="http://schemas.microsoft.com/developer/msbuild/2003">

  <PropertyGroup>

    <OutputName>MyApplication</OutputName>

    <DefineConstants>
      ProductVersion=$(ProductVersion)
    </DefineConstants>

  </PropertyGroup>

  <ItemGroup>

    <Compile Include="Product.wxs" />
    <Compile Include="AppFiles.wxs" />

  </ItemGroup>

  <Import Project="$(WixTargetsPath)" />

</Project>
4. Build Script Used by Bamboo

Build\build-installer.bat

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
Bamboo Plan Configuration
Stage 1 — Build
Job: BuildInstaller
Task 1

Source Checkout

Bitbucket Repository
Task 2

Script Task

Build\build-installer.bat
Bamboo Variables

Plan → Variables

Name	Value
ProductVersion	1.0
Configuration	Release

Bamboo automatically exposes:

${bamboo.buildNumber}

Example:

Build #145

MSI version:

1.0.145
Bamboo Artifact

Plan → Artifacts

Artifact Definition
Name:
MSI

Location:
Installer\bin\Release

Copy Pattern:
*.msi

Shared:
Yes
Automatic Trigger

Plan → Triggers

Add:

Repository Trigger

Pipeline:

Git Push
    ↓
Bitbucket
    ↓
Bamboo Trigger
    ↓
Restore Packages
    ↓
Compile
    ↓
Harvest Files
    ↓
Build MSI
    ↓
Publish Artifact
Optional: Sign MSI

Add another Bamboo Script Task:

signtool sign ^
 /fd SHA256 ^
 /tr http://timestamp.digicert.com ^
 /td SHA256 ^
 /f company.pfx ^
 /p %CERT_PASSWORD% ^
 Installer\bin\Release\MyApplication.msi

Store CERT_PASSWORD as a Bamboo secured variable.

Optional Deployment Project

Create a Bamboo Deployment Project:

Build Plan
      ↓
DEV
      ↓
QA
      ↓
PROD

Deployment script:

msiexec /i MyApplication.msi /quiet /norestart
Recommended Production Improvements

Most enterprise teams also add:

Pull-request validation from Bitbucket
Automated version generation from Git tags
Unit test reports
Static code analysis with SonarQube
MSI signing
Release notes generation
Storage in JFrog Artifactory or similar artifact repository
Separate DEV/UAT/PROD deployment stages
Rollback deployment jobs

One issue with the simple example above is that the generated AppFiles.wxs does not define the installation directory tree (INSTALLFOLDER). In a production WiX v3 project, you would typically add a Directory structure fragment and reference it from the harvested components. If you share:

Your application type (.NET Framework WinForms/WPF/Web Service/etc.)
WiX version (3.11, 3.14, etc.)
Whether you need MSI only or Setup.exe (Burn)

I can provide a fully buildable WiX v3 project (including Directory, Feature, ComponentGroup, Product.wxs, Bundle.wxs, and Bamboo Specs YAML/Java configuration).
