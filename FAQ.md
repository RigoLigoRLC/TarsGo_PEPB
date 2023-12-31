
# 部署时常见问题

## 怎么将一个“东西”添加到系统 PATH 里？

在 Windows 10/11计算机上：右键单击“计算机”/“此电脑”，选择“属性”。在弹出的窗口中，找到“高级系统设置”并进入。然后单击“环境变量”。

在“系统变量” 一栏中，滚动列表找到`PATH`环境变量，双击进入编辑界面。在右侧单击“新建”按钮，然后将要加入`PATH`的目录路径输入在里面，然后逐步保存。在保存后，最好重启 VSCode / explorer.exe 或者电脑，来保证环境变量已经被重新载入。

通常在说“把某个 exe 文件加入到`PATH`中”时，是指将它的父目录的路径放入`PATH`中。系统执行一个没有指定 exe 路径的命令时，会首先查找`PATH`内保存的所有目录，这样系统在不指定路径的情况下就可以成功运行之。而对于多文件的软件，一般要将其`bin`目录加入`PATH`中。

## 系统中存在多个安装的 CMake 导致版本混乱，进而配置失败，如何解决？

如果此前有安装 Visual Studio 2019 之类的 IDE ，或者使用了其他方式安装了 CMake ，则可能 VSCode 自动取用旧版本的 CMake ，导致编译失败。

提示：`cmake_minimum_required` 语句一般不是对最低版本要求的硬性限制，因为在开发基于 CMake 的构建系统时， CMake 本身并不能提供一套程序化的方法“检测”最低支持的 CMake 版本，所以一般这个版本号都是由开发人员填写上自己在开发时使用的 CMake 版本。当然，我仍然推荐你在新安装 CMake 时只选择安装最新版本。

可以通过以下方法手动指定使用的 CMake ：按 Ctrl+,（逗号）打开 VSCode 设置，在其中搜索“Cmake: Cmake Path”，然后在这里指定你强制 VSCode 使用的`cmake.exe`的路径。指定后手动触发重新配置。

## 在 CubeMX 中已经启用了 DSP 库，那么 DSP 库怎么配置？

`cmake/CubeMx.cmake` 中的 `stm32_fixup_target` 函数中已经包含了自动检测是否选中 DSP 库、并自动链接、添加定义的操作，无需用户干预。如出现编译问题等，请及时联系作者沟通解决。