## designed for powershell v1 because the servers the run this mess are... aNcIeNt

$ErrorActionPreference  = "Stop"

## inputs
$rvMajor                = $ENV:RV_MAJOR
$rvMinor                = $ENV:RV_MINOR
$rvPatch                = $ENV:RV_PATCH
$packages               = $ENV:PACKAGES
$packageDir             = $ENV:PACKAGE_DIR
$buildId                = $ENV:BUILD_NUMBER
$releaseNotesFilePath   = $ENV:RELEASE_NOTES_FILE_PATH

$nugetPackageRepo       = $ENV:NUGET_PACKAGE_URI
$nugetPackageUsername   = $ENV:NUGET_PACKAGE_USERNAME
$nugetPackagePAT        = $ENV:NUGET_PACKAGE_PAT

$_nugetExeLocation      = "${PSScriptRoot}/tools/nuget.exe"

 ## ConvertFrom-Json is not available in powershell (whatever version we have)
add-type -assembly system.web.extensions
$ps_js = new-object system.web.script.serialization.javascriptSerializer

$pkgs =  $ps_js.DeserializeObject($packages)
$curDir = ${PWD} ## current working dir

$pkgs | `
ForEach-Object {
    $pkgId      = $_.name
    $pkgVersion = "${rvMajor}.${rvMinor}.${rvPatch}-beta-${buildId}"
    $pkgName    = "${pkgId}.${pkgVersion}.nupkg"
    $pkgPath    = "$($_.path)"
    $nuspecPath = [System.IO.Path]::Combine($pkgPath, "package.nuspec")

    Write-Host "Package Name: ${pkgName}"
    Write-Host "Package Path: ${pkgPath}"

    Write-Host "Creating NuSpec File"
    $xmlWriter  = New-Object System.XMl.XmlTextWriter($nuspecPath, $Null)
    $xmlWriter.Formatting = 'Indented'
    $xmlWriter.Indentation = 1
    $xmlWriter.IndentChar = "`t"
    $xmlWriter.WriteStartDocument()

    $xmlWriter.WriteStartElement("package")
    $xmlWriter.WriteStartElement("metadata")

    #id
    $xmlWriter.WriteElementString("id", $pkgId)

    #description
    $xmlWriter.WriteElementString("description", $pkgId)

    #version
    $xmlWriter.WriteElementString("version", $pkgVersion)

    #authors
    $xmlWriter.WriteElementString("authors", $nugetPackageUsername)

    #owners
    $xmlWriter.WriteElementString("owners", $nugetPackageUsername)

    ##release notes
    $xmlWriter.WriteElementString("releaseNotes", $(Get-Content -Path $releaseNotesFilePath))

    $xmlWriter.WriteEndElement() ##metadata
    $xmlWriter.WriteEndElement() ##package
    $xmlWriter.WriteEndDocument()
    $xmlWriter.Flush()
    $xmlWriter.Close()

    Write-Host "Nuspec file created"

    Write-Host "Packing file"

    $PSScriptRoot/tools/nuget.exe pack $nuspecPath -OutputDirectory "${packageDir}"

    Write-Host "Pack Complete"
}

## setting tls to 1.2 the hard way because old powershell
$p = [Enum]::ToObject([System.Net.SecurityProtocolType], 3072);
[System.Net.ServicePointManager]::SecurityProtocol = $p;

Write-Host "Pushing Nuget files to Nuget Package Repo"

## create a nuget source for this configuration
$exitCode = 0

Get-ChildItem -Path "${packageDir}\*" -Include *.nupkg | `
    ForEach-Object {
    $pkg = $_.FullName
    $srcName = "For_${pkg}"

    & $_nugetExeLocation sources add -name "${srcName}" -Source $nugetPackageRepo -Username $nugetPackageUsername -Password $nugetPackagePAT
    & $_nugetExeLocation push $pkg -NonInteractive -Source "${srcName}" -ApiKey $nugetPackagePAT

    Write-Host "Push Exit Code: $LASTEXITCODE"

    $exitCode = $exitCode + $LASTEXITCODE
    
    & $_nugetExeLocation sources remove -name "${srcName}"
    }

Write-Host "Exiting with Code: ${exitCode}"

exit $exitCode