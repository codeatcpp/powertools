# The set of useful PowerShell scripts. #

## Project tree image generator ##

![Sample graph](sample_dep_graph.gv.png "Sample graph")

This script generates GraphViz file which is reflect the dependencies between projects in the specified Visual Studio solution file.

```
Usage: ./build_project_tree.ps1 -In test.sln -ExcludePattern "test|unit"
```
