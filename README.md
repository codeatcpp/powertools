# The set of useful PowerShell scripts. #

## Project tree image generator ##

![Sample graph](sample_dep_graph.gv.png "Sample graph")

This script generates GraphViz file which is reflect the dependencies between projects in the specified Visual Studio solution file.

```
Usage: ./build_project_tree.ps1 -In test.sln -ExcludePattern "test|unit"
```
### Installation ###
Run PowerShell as administrator, then run the following command to allow to run downloaded scripts:
```
PS> Set-ExecutionPolicy -Scope Process RemoteSigned
```

More details about the implementation process you can read [here](http://www.codeatcpp.com/2015/05/blog-post.html) (in Russian).
