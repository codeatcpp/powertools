<#

Copyright (c) 2015, Kirill V. Lyadvinsky (http://www.codeatcpp.com)
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
  1. Redistributions of source code must retain the above copyright notice, this
     list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution.
  3. Neither the name of the copyright holder nor the names of its contributors
     may be used to endorse or promote products derived from this software
     without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#>

<#
.SYNOPSIS
    Visual Studio projects dependencies generator.

.DESCRIPTION
    This script generates GraphViz file which is reflect the dependencies between
    projects in the specified Visual Studio solution file.

.LINK
    http://www.codeatcpp.com

.NOTES
    Filename: build_project_tree.ps1
    Author: Kirill V. Lyadvinsky
    Requires: PowerShell 3.0

.PARAMETER In
    Specifies the path to the input file. Solution files of the Visual Studio
    2008 and higher are supported.

.PARAMETER Out
    Specifies the name and path for the GraphViz output file. By default,
    build_project_tree.ps1 generates a name from the input filename, and saves
    the output in the local directory.

.INPUTS
    None. You cannot pipe objects to build_project_tree.ps1.

.OUTPUTS
    None. build_project_tree.ps1 does not generate any output.

.EXAMPLE
    ./build_project_tree.ps1 -In test.sln -ExcludePattern "test|unit"

.EXAMPLE
    ./build_project_tree.ps1 -In test2.sln -Verbose
#>

Param(
    [Parameter(Mandatory)][System.IO.FileInfo]$In,
    [System.IO.FileInfo]$Out=$In.BaseName + "_dep_graph.gv",
    [String]$ExcludePattern
)

function Value(
    [Parameter(Mandatory)][single]$m1,
    [Parameter(Mandatory)][single]$m2,
    [Parameter(Mandatory)][single]$h)
{
    while ( $h -ge 360 ) { $h -= 360 }
    while ( $h -lt 0 ) { $h += 360 }
    if ( $h -lt 60 ) { $m1 = $m1 + ($m2 - $m1) * $h / 60 }
    else
    {
        if ( $h -lt 180 ) { $m1 = $m2 }
        else
        { 
            if ( $h -lt 240 ) { $m1 = $m1 + ($m2 - $m1) * (240 - $h ) / 60 }
        }
    }
    return ,[byte]($m1*255)
}

function HSLtoRGB(
    [Parameter(Mandatory)][single]$Hue,
    [Parameter(Mandatory)][single]$Saturation,
    [Parameter(Mandatory)][single]$Lightness)
{
    $rgb = New-Object byte[] 3

    if ( $Saturation -eq 0 ) { $rgb[0] = $rgb[1] = $rgb[2] = $Lightness * 255 }
    else 
    {
        [single]$m1 = 0
        [single]$m2 = 0
        if ( $Lightness -le 0.5 ) { $m2 = $Lightness + $Lightness * $Saturation }
        else { $m2 = $Lightness + $Saturation - $Lightness * $Saturation }
        $m1 = 2 * $Lightness - $m2
        $rgb[0] = Value $m1 $m2 ($Hue+120)
        $rgb[1] = Value $m1 $m2 $Hue
        $rgb[2] = Value $m1 $m2 ($Hue-120)
    }
    Return ,$rgb
}

#
# Find dependencies for the specified project file using specified patterns.
#
function Select-References
{
    param(
        [Parameter(Mandatory)][System.IO.FileInfo]$prjFile,
        [Parameter(Mandatory)][String]$xmlPathRef,
        [Parameter(Mandatory)][String]$xmlPathType
    )
    [single]$hue = ($global:indentity * 23.0)
    $rgb = HSLtoRGB $hue 1.0 0.45

    $projectName = $prjFile.Name
    [xml]$projectXml = Get-Content $prjFile
    [bool]$subprojects = 0
    $projectXml |
    Select-Xml -XPath $xmlPathRef |
    foreach {
        if ( $ExcludePattern.Length -eq 0 -or $_ -match $ExcludePattern -eq 0 )
        {        
            "`"" + $projectName.ToLower() + "`" -> `"" +
                [System.IO.Path]::GetFileName($_).ToLower() +"`" [color=`"#" + 
                ("{0:X2}" -f $rgb[0]) +
                ("{0:X2}" -f $rgb[1]) +
                ("{0:X2}" -f $rgb[2]) +
                "`"];"
            Write-Verbose ("--> " + $_)
            Write-Progress $projectName -Status $_
            $subprojects = 1
        }
    }
    if ( $subprojects )
    {
        $global:indentity += 1
    }

    $projectXml |
    Select-Xml -XPath $xmlPathType |
    Select-Object -First 1 | % {
        switch -Wildcard ($_)
        {
            {($_.ToString() -eq "1") -or ($_.ToString() -eq "Application") -or ($_ -match "Exe")}
            {
                "`"" + $projectName.ToLower() + "`" [color=cornflowerblue];"
                continue
            }
            {($_.ToString() -eq "4") -or ($_.ToString -eq "StaticLibrary")}
            {
                "`"" + $projectName.ToLower() + "`" [color=indigo];"
                continue
            }
            {($_.ToString() -eq "2") -or ($_ -match "Library")}
            {
                "`"" + $projectName.ToLower() + "`" [color=indigo];"
                continue
            }
            {($_.ToString() -eq "10")}
            {
                "`"" + $projectName.ToLower() +
                    "`" [color=black, style=dashed, fontcolor=black];"
                continue
            }
            default
            { 
                Write-Warning ("Unknown module type: " + $_)
            }
        }
    }
}

#
# Find dependencies for the specified VS2008 project file.
#
function Select-References-VS2008
{
    param(
        [Parameter(Mandatory)][System.IO.FileInfo]$prjFile
    )
    if ( Test-Path $prjFile )
    {
        Select-References $prjFile "VisualStudioProject[1]/References[1]/ProjectReference/@RelativePathToProject" `
            "VisualStudioProject[1]/Configurations[1]/Configuration/@ConfigurationType"
    }
    else
    {
        Write-Warning ($prjFile.FullName + " is not available")
    }
}

#
# Find dependencies for the specified VS2010 project file.
#
function Select-References-VS2010
{
    param(
        [Parameter(Mandatory)][System.IO.FileInfo]$prjFile
    )
    if ( Test-Path $prjFile )
    {
        if ( $prjFile.Extension -eq ".csproj" )
        {
            $prjTypeXPath = "//*[local-name()=`"OutputType`"]/text()"
        }
        else 
        {
            $prjTypeXPath = "//*[local-name()=`"ConfigurationType`"]/text()"
        }
        Select-References $prjFile `
            "//*[local-name()=`"ProjectReference`"]/@Include" $prjTypeXPath
    }
    else
    {
        Write-Warning ($prjFile.FullName + " is not available")
    }    
}

#
# Extract paths to the projects files from the specified solution file.
#
function Get-ProjectsPaths
{
    param(
        [Parameter(Mandatory)][System.IO.FileInfo]$slnFile
    )

    # Add graph header
    "/* Generated using build_project_tree.ps1 */"    
    "digraph " + $slnFile.BaseName + " {"
    "size=`"60,60`"; rankdir=LR; overlap=false; splines=true; dpi=300;"
    "node[color=mediumorchid3, style=filled, shape=box, fontsize=10, fontcolor=white];"
    "edge[arrowhead=vee, arrowtail=inv, arrowsize=.7, fontsize=10, fontcolor=navy];"
    "labelloc=t; label=""Solution: " + $slnFile.Name + """; fontsize=14;"

    # Parse the solution file
    $slnPath = $slnFile.Directory
    $strings = Select-String -LiteralPath $slnFile -Pattern "Project\(.*vcx?proj"
    if ( $strings.Count -gt 0 )
    {
        $vs2008prj = $strings[0] -match "vcproj"
    }
    $strings += Select-String -LiteralPath $slnFile -Pattern "Project\(.*csproj"
    # Find dependencies for each project in the solutin
    foreach ( $s in $strings )
    {
        if ( $ExcludePattern.Length -eq 0 -or $s -match $ExcludePattern -eq 0 )
        {
            $prjFile = Join-Path -Path $slnPath `
                -ChildPath ($s -split ',')[1].Trim().Replace('"','')
            Write-Verbose $prjFile
            if ( $vs2008prj )
            {
                Select-References-VS2008 $prjFile
            }
            else
            {
                Select-References-VS2010 $prjFile
            }
        }
    }

    "}"
}

#
# Main
#

$OutputEncoding = New-Object -typename System.Text.UTF8Encoding
[single]$global:indentity = 0
$pathHelper = $ExecutionContext.SessionState.Path
$slnFile = $pathHelper.GetUnresolvedProviderPathFromPSPath($In)

Get-ProjectsPaths $slnFile | Out-File -Encoding utf8 $Out
