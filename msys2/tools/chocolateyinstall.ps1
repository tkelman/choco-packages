﻿# Chocolatey MSYS2
#
# Copyright (C) 2015 Stefan Zimmermann <zimmermann.code@gmail.com>
#
# Licensed under the Apache License, Version 2.0

$ErrorActionPreference = 'Stop';

$packageName = 'msys2'

$url = 'http://downloads.sourceforge.net/msys2/Base/i686/msys2-base-i686-20150512.tar.xz'
$checksum = '18f33537212bca9552659012a16d8c511ef5fc23'
$checksumType = 'SHA1'

$url64 = 'http://downloads.sourceforge.net/msys2/Base/x86_64/msys2-base-x86_64-20150512.tar.xz'
$checksum64 = '88fa66ac2a18715a542e0768b1af9b2f6e3680b2'
$checksumType64 = 'SHA1'

$toolsDir = Split-Path -parent $MyInvocation.MyCommand.Definition

$packageDir = Split-Path -parent $toolsDir
Write-Host "Adding '$packageDir' to PATH..."
Install-ChocolateyPath $packageDir

$osBitness = Get-ProcessorBits

$binRoot = Get-BinRoot
# MSYS2 zips contain a root dir named msys32 or msys64
$msysName = 'msys' + $osBitness
$msysRoot = Join-Path $binRoot $msysName

if (Test-Path $msysRoot) {
    Write-Host "'$msysRoot' already exists and will only be updated."
}
else {
    Write-Host "Installing to '$msysRoot'"
    Install-ChocolateyZipPackage $packageName $url $binRoot $url64 `
      -checksum $checksum -checksumType $checksumType `
      -checksum64 $checksum64 -checksumType64 $checksumType64
    # check if .tar.xz was only unzipped to tar file
    # (shall work better with newer choco versions)
    $tarFile = Join-Path $binRoot msys2Install
    if (Test-Path $tarFile) {
        Get-ChocolateyUnzip $tarFile $binRoot
        Remove-Item $tarFile
    }
}

Write-Host "Adding '$msysRoot' to PATH..."
Install-ChocolateyPath $msysRoot

# Finally initialize and upgrade MSYS2 according to https://msys2.github.io
Write-Host "Initializing MSYS2..."
$msysShell = Join-Path $msysRoot msys2_shell.bat
Start-Process -Wait $msysShell -ArgumentList '-c', exit

$command = 'pacman --noconfirm --needed -Sy bash pacman pacman-mirrors msys2-runtime'
Write-Host "Updating system packages with '$command'..."
Start-Process -Wait $msysShell -ArgumentList '-c', "'$command'"

$command = 'pacman --noconfirm -Su'
Write-Host "Upgrading full system with '$command'..."
Start-Process -Wait $msysShell -ArgumentList '-c', "'$command'"
