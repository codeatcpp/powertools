<#
.SYNOPSIS
   Visual Studio projects dependencies generator.

.DESCRIPTION
   This script generates GraphViz files which reflect dependencies between the projects in the specified Visual Studio solution file.

.LINK
   http://www.codeatcpp.com

.NOTES
   Filename: build_project_tree.ps1
   Author: Kirill V. Lyadvinsky
   Requires: PowerShell V2 CTP3

.EXAMPLE
   ./build_project_tree.ps1 -In test.sln -ExcludePattern "test|unit"

.EXAMPLE
   ./build_project_tree.ps1 -In test2.sln -Verbose
#>