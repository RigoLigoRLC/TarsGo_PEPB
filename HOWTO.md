# 配置 PEPB 编译

基于 PEPB 的嵌入式项目虽然可以当做正常的 CMake 项目开发，但许多代码细节专为 VSCode 设计，因此仅推荐在 VSCode 中配置此框架。文档中会介绍 VSCode 上的配置，同时项目源码中包含了 [.vscode](.vscode/) 目录及配置模板方便为 VSCode 配置。

## 请注意：项目文件夹路径中不能出现**空格**，否则可能导致烧录出现异常。

## 依赖项

你需要提前在计算机上安装：

- [ARM GCC Toolchain](https://developer.arm.com/Tools%20and%20Software/GNU%20Toolchain) （仅需要解压。如不使用 VSCode ，还需要将 bin 目录添加到系统 PATH 中）
- [OpenOCD](https://github.com/xpack-dev-tools/openocd-xpack/releases) （仅需要解压。可能需要手动点击“Show all xxx assets”展开列表才能看到 Windows 版本）
- [Ninja build](https://github.com/ninja-build/ninja/releases) （需要处于系统 PATH 中）
- [CMake](https://cmake.org)（安装时请选择将其加入 PATH 中）
- STM32CubeMX

在 VSCode 中安装如下插件：

- clangd (by LLVM)
- CMake Tools (by Microsoft)
- Cortex-Debug (by marus25) （调试使用）

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

打开目录后，CMake Tools 插件可能在右下角弹出询问关于底部选项显示方式的弹窗。关于此问题，请打开 VSCode 的 CMake Tools 插件设置，搜索“cmake status bar visibility”，此时应该显示一个单选项。选择“compact”紧凑视图，然后按 F1 打开命令面板，搜索“Developer: Reload Window”，使用此命令重新加载窗口。

## 设置工具链路径

### 写在前面

PEPB 有配套 VSCode 插件，可自动为你配置路径，减少你的工作量。请于[此处](https://github.com/RigoLigoRLC/PEPBHelper/releases)下载插件。

注意插件版本号的前两段一定要与使用的 PEPB 版本号相符，或者至少要使插件版本大于 PEPB。例如，可以为 1.0.0 版本的 PEPB 使用 1.0.1 版本的 PEPB Helper，但不能为 1.1.0 版本的 PEPB 使用 1.0.1 版本的 PEPB Helper。大版本号的插件原则上兼容旧版本的 PEPB，这是一个常识。

下载插件后，在 VSCode 左侧插件面板点击右上角的“…”，选择“从 VSIX 安装”。安装插件后，按下“Ctrl+,”打开 VSCode 设置页面。搜索 PEPB Helper，然后依照提示填入对应路径。如不知道对应路径的含义，请参考本节的下文，这里讲详细介绍具体应当做的事情和使用到的软件。

使用插件配置路径时，确保 VSCode 已经打开了上文提到的项目目录，然后按 F1 打开命令面板，搜索 PEPB，执行“PEPB: 为此项目设置配置”。

### ARM GCC 路径配置

ARM GCC 即是本项目采用的编译器。

编辑`.vscode/cmake-kits.json`文件，将`"C":`和`"CXX":`后的字符串改为自己计算机上 ARM GCC 编译器的可执行文件路径。如：

```json
        "C": "D:/discretelibs/arm-gnu-toolchain-12.2/bin/arm-none-eabi-gcc.exe",
        "CXX": "D:/discretelibs/arm-gnu-toolchain-12.2/bin/arm-none-eabi-g++.exe"
```

将`"PATH:"`后面字符串中，尖括号括起的部分替换为 ARM GCC 编译器的 bin 目录路径。如果你要在 Unix 操作系统 而非 Windows 上编译，则需要把尖括号部分后面的分号改为冒号；这是由于两种操作系统使用的 PATH 分隔符不同导致的。如：

```json
        "PATH": "D:/discretelibs/arm-gnu-toolchain-12.2/bin/;${env.PATH}"
```

```json
        "PATH": "/Users/rigoligo/app/arm-gnu-toolchain-12.2.mpacbti-rel1-darwin-arm64-arm-none-eabi/bin/:${env:PATH}"
```

请务必注意，建议使用正斜杠（`/`）作为路径分隔符。如果实在想用反斜杠，需要将其补全为转义序列（`\\`）。

你还可以在其他地方长期保留适用自己计算机的`cmake-kits.json`文件，并在以后创建新项目时直接覆盖复制。

### Clangd 配置 ARM GCC 路径

Clangd 插件需要额外配置 ARM GCC 路径，以确保 Clangd 能够正确找到 GCC 的头文件。

编辑`.vscode/settings.json`文件，将`clangd.arguments`数组中的`--query-driver=`参数后的路径替换成自己计算机上 ARM GCC 编译器的 bin 目录路径。可以使用上一步的可执行文件路径并将“gcc”字眼替换成“\*”，只要`bin`后的部分和模板中相仿即可（注意在 Unix 系统中同样要符合其可执行文件名和惯例，去除`.exe`扩展名）。如：

```json
    "clangd.arguments": [
        "--query-driver=D:/discretelibs/arm-gnu-toolchain-12.2/bin/arm-none-eabi-*.exe"
    ]
```

### OpenOCD 路径配置

OpenOCD 即是本项目采用的烧录及调试程序。

编辑`.vscode/PEPBSettings.json`文件，将`OpenOcd`条目下的`Path`项设为自己计算机上 OpenOCD 解压出来后里面的 bin 目录路径。如：

```json
    "OpenOcd": {
        "Path": "X:/ABCDABCD/EFGHEFGH/xpack-openocd-0.12.0-1/bin",
        "Chip": "stm32f4x",
        "Programmer": "stlink"
    }
```

`Programmer`项中指明你使用的烧录器/调试器/仿真器类型。JSON 文件的注释中列出了几种常见的调试器。正点原子的无线调试器为 CMSIS-DAP 协议。**注：如果你今后需要更换其他调试器，修改此项后需要重新配置项目。关于项目配置，见[后文](#关于手动配置cmake-configure项目)。**

同样，此配置文件也可以长期保留以便日后使用。

配置完毕后，在 VSCode 底部， CMake 插件显示“No Kit Selected”的部分点击。然后在顶端弹出的命令板中选择“ARM GCC TarsGo-PEPB”。此时 CMake 会自动开始配置（configure）项目，但会因为我们还没有完成 PEPB 整体的设置而失败。暂时忽略失败的配置。

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

### 关于手动配置（CMake Configure）项目……

**注 1：如果没有自动进行配置操作，可在 VSCode 左侧点击 CMake 选项卡，并在其顶部点击第一个按钮（鼠标停留时可看到“配置所有项目”提示。），或者按 F1 打开命令面板，执行“CMake: 配置”命令。**

**注 2：在每一次更改了 CubeMX 中的配置后，都应该手动重新进行项目配置。**

## 结束

此时配置已经完成。单击底部的 Build 按钮应该可以正常编译 elf 文件。你现在可以在 VSCode 中打开 CubeMX 生成的`Core/Src/main.c`文件并试试编写代码。

## 添加更多的源码文件

如果你需要添加更多的源代码，那么你需要使用 CMake 的其他命令管理源码列表。推荐将这些语句放在`EXTRA SOURCES`部分，且本部分也有相应的注释加以示范。

### 源码文件

通常，我们可以使用偷懒的做法：

```cmake
file(GLOB_RECURSE MY_SOURCE src/*.c) # GLOB_RECURSE 递归地匹配文件，并将它们放入列表 MY_SOURCE 中
```

这样可以得到一个文件列表`MY_SOURCE`，内容为 src 目录下递归查找 \*.c 文件得到的文件名。如果要将它们加入到编译目标中，只需在`stm32_create_target`函数中添加`EXTRA_SOURCES`参数（CMakeLists 模板中已经有这一行，使用时也可直接取消其注释）：

```cmake
stm32_create_target(CUBEMX_DIR ${CUBEMX_PROJECT_DIR}
                    TARGET_NAME ${PROJECT_NAME}.elf
                    CPU_TYPE ${STM32_CPU_TYPE}
                    EXTRA_SOURCES ${MY_SOURCES} another/source.c
)
```

在`EXTRA_SOURCES`后添加`${MY_SOURCES}`，即意为将`MY_SOURCES`变量的值作为函数参数传递。同时，`EXTRA_SOURCES`的后面可以跟随多个源码文件路径（或者如上文中的列表变量）。可以灵活搭配。**注意：添加源码文件后，仍需重新配置项目使之生效。**

### 包含文件（头文件）

对于需要被包含的头文件，需要使用`include_directories`指令添加它们所在的目录。例如，如果想要在`main.c`中包含一个项目根目录下的`inc/something.h`文件，你需要在`CMakeLists.txt`中添加以下代码：

```cmake
include_directories(inc)
```

然后在`main.c`中如此引用：

```c
#include "something.h"
```

以上述方式指定`inc/`目录为包含目录后，如果存在子目录中的头文件（形如`inc/module/mods.h`），可以如此引用之：

```c
#include "module/mods.h"
```

# 烧录

PEPB 自带的 CMakeLists 会在添加编译目标后，再将编译目标添加到烧录目标中（见 CMakeLists 中的`pepb_add_download_target()`函数调用）。这个函数会产生一个名为`Download_Via_OpenOCD`的自定义目标，并将编译目标设为这个目标的依赖项（如此便可实现每次尝试烧录时，CMake 都保证编译出的程序是最新的，无需点击编译后再点击烧录）。

要执行烧录，可在 VSCode 下方的 Build 按钮右侧的`[all]`上单击，然后在顶部的命令面板中选择`Download_Via_OpenOCD`目标。然后，单击 Build 按钮。

_实验性：烧录仅测试了 ST-LINK V2 的兼容性。如其他烧录器使用中存在兼容性问题，请联系作者帮忙调试！_

# 调试

## 配置 Cortex-Debug

PEPB 在配置 OpenOCD 烧录时会自动在`.vscode/launch.json`中生成适用于 VSCode 的 Cortex-Debug 插件的调试描述文件。因此不需人工干预调试配置文件的生成。但是，你需要配置 Cortex-Debug 插件的 OpenOCD 路径，或者将 OpenOCD 添加进系统 PATH 。在此介绍前者的操作方式：

按 Ctrl+,（逗号）打开 VSCode 设置，搜索“Cortex-debug: Openocd Path”。由于此插件没有提供这个配置项的输入框，因此只能点击“在 settings.json 中编辑”直接修改配置文件。点击后 VSCode 会自动生成一个空的字符串，此时在里面输入 `openocd.exe` 的路径并保存。仍需要使用正斜杠。

```json
    "cortex-debug.openocdPath": "D:/discretelibs/xpack-openocd-0.12.0-1/bin/openocd.exe"
```

## 启动调试

在 VSCode 左侧的调试面板（图形为一只瓢虫趴在运行键上）中，选择“Debug (PEPB)”调试配置，点击左侧的运行键启动调试。可能需要等待片刻才能启动。这个调试目标会将代码烧录，重置单片机，然后启动调试。如果只需要将调试器附载到目标单片机上，使用“Attach (PEPB)”调试配置。

在调试面板下方，有 Cortex Live Watch 监视面板。此为实时监视面板（只能监视全局变量）。点击面板标题栏右侧的“+”号，然后在上方的命令面板中输入全局变量的名称后按回车键。可以在运行时观察变量的变化。

默认调试配置模板支持使用 SEGGER RTT 的通道 0 输入输出。由于单片机刚启动时 RTT 还未初始化就已被调试器附载，一般无法使用“Debug (PEPB)”调试目标启动 RTT 终端，所以建议使用“Attach (PEPB)”目标启动 RTT 终端。启动调试后，在 VSCode 下方“终端”面板右侧可以看到 RTT 终端。
