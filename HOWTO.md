
# 配置 PEPB

基于 PEPB 的嵌入式项目虽然可以当做正常的 CMake 项目开发，但最好使用一个 IDE 来加强体验。文档中会介绍 VSCode 上的配置，同时项目源码中包含了 [.vscode](.vscode/)  目录方便为 VSCode 配置。

## 依赖项

你需要提前在计算机上安装：

- [ARM GCC Toolchain](https://developer.arm.com/Tools%20and%20Software/GNU%20Toolchain) （仅需要解压。如不使用 VSCode ，还需要将 bin 目录添加到系统 PATH 中）
- [Ninja build](https://github.com/ninja-build/ninja/releases) （需要处于系统 PATH 中）
- [CMake](https://cmake.org)（安装时请选择将其加入 PATH 中）
- STM32CubeMX

在 VSCode 中安装如下插件：

- clangd (by LLVM)
- CMake Tools (by Microsoft)

安装 clangd 后， VSCode 右下角会弹窗提示未找到 Clangd 可执行文件。点击蓝色按钮允许其自动下载最新版的 clangd 并配置。请耐心等待这一过程完成。

如果你先前还安装了 Microsoft 的 C/C++ 插件，clangd 会提示其与 C/C++ 插件的 Intellisense 功能冲突。请按照弹窗提示在工作区范围内关闭 Intellisense，最好将 C/C++ 插件也在工作区内关闭。

## 添加到你的新项目

建议以复制 PEPB 的源代码作为一个新项目的起点。需要复制的文件如下：

- .vscode/
- cmake/
- CMakeLists.txt
- embedded-toolchain.cmake
- .clangd

在进入 VSCode 时，使用“打开文件夹”功能，然后打开包含`CMakeLists.txt`的目录，此即为项目目录。

## 设置工具链路径

编辑`.vscode/cmake-kits.json`文件，将`"C":`和`"CXX":`后的字符串改为自己计算机上 ARM GCC 编译器的可执行文件路径。如：
```json
            "C": "D:/discretelibs/arm-gnu-toolchain-12.2/bin/arm-none-eabi-gcc.exe",
            "CXX": "D:/discretelibs/arm-gnu-toolchain-12.2/bin/arm-none-eabi-g++.exe"
```
请务必注意，建议使用正斜杠（`/`）作为路径分隔符。如果实在想用反斜杠，需要将其补全为转义序列（`\\`）。

你还可以在其他地方长期保留适用自己计算机的`cmake-kits.json`文件，并在以后创建新项目时直接覆盖复制。

然后在 VSCode 底部， CMake 插件显示“No Kit Selected”的部分点击。然后在顶端弹出的命令板中选择“ARM GCC TarsGo-PEPB”。此时 CMake 会自动开始配置，但会因为还没有配置完毕而直接失败。暂时忽略失败的配置。

## 使用 CubeMX 添加单片机项目

打开 STM32CubeMX ，按照一般的配置方法建立单片机项目、配置外设与时钟。此处不再赘述。

将 .ioc 文件保存到项目目录下的一个新文件夹中。

在生成代码前，选择上方的“Project Manager”选项卡。在左侧选择“Project”选项卡。在右侧的“Project Settings”下的“Toolchain/IDE”中，将`EWARM`改为`Makefile`。然后生成代码。

## 将 CubeMX 项目添加进 PEPB 模板中

编辑`CMakeLists.txt`，在`GENERAL CONFIGURATIONS`中修改项目名与 CubeMX 项目目录。如：
```cmake
project(BoardC_Blink LANGUAGES C CXX ASM) # 此处 BoardC_Blink 即为项目名
set(CUBEMX_PROJECT_DIR BoardC) # 此处 BoardC 即为 CubeMX 项目所处的子目录
```

然后按 Ctrl+S 保存 CMakeLists.txt。此时 VSCode 应该自动进行配置并成功生成。

**注1：如果没有自动进行配置操作，可在 VSCode 左侧点击 CMake 选项卡，并在其顶部点击第一个按钮（鼠标停留时可看到“配置所有项目”提示。），或者按 F1 打开命令面板，执行“CMake: 配置”命令。**

**注2：在每一次更改了 CubeMX 中的配置后，都应该手动重新进行项目配置。**

## 结束

此时配置已经完成。单击底部的 Build 按钮应该可以正常编译 elf 文件。你现在可以在 VSCode 中打开 CubeMX 生成的`Core/Src/main.c`文件并试试编写代码。

## 后记

默认情况下，`Core/`中的所有.c、.cpp和.h文件都将在配置时自动地、递归地被搜索并加入编译列表中。你可以将所有的项目代码堆积在这里，但更推荐使用 CMake 的其他方式，独立地管理项目中 CubeMX 以外的源码。
