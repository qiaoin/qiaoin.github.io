---
title: CMake Tutorial 翻译及整理
author: qiaoin
date: '2017-02-24'
slug: cmake-tutorial
categories: []
tags:
  - 翻译
---

本文为 CMake 官网入门教程 [CMake Tutorial](https://cmake.org/cmake-tutorial/) 的翻译，并添加了一些自己的理解，以帮助读者更好地理解文章内容。(对原文中引用过来的代码进行了一些简单的修改，如编程风格、变量命名等)

下文为一个 step-by-step 的 CMake 使用入门教程，它包含了我们使用 CMake 来构建系统所需要使用的一些常用命令。我们在这个教程中所使用到的所有文件都可以在 [Tests/Tutorial](https://gitlab.kitware.com/cmake/cmake/tree/master/Tests/Tutorial/) 文件夹下找到，对应每一步都有一个单独的文件夹。

## Step1 Hello, CMake!

我们从最为简单的一个项目开始着手，其包含一些源代码文件，用来产生最后的可执行文件。那么，在 `CMakeLists.txt` 文件中仅需包含三条语句就可以了：

```cmake
cmake_minimum_required (VERSION 2.6)
project (Tutorial)
add_executable(Tutorial tutorial.cxx)
```

**注意**：`CMakeLists.txt` 中全为小写命令，事实上，CMake 对小写命令、大写命令以及二者的混合都有提供支持。

源文件 `tutorial.cxx` 用于计算平方根，以下为初始版本：

```c
// A simple program that computes the square root of a number
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main(int argc, char *argv[]) {
  if (argc < 2) {
    fprintf(stdout, "Usage: %s number\n", argv[0]);
    return 1;
  }

  double input_value = atof(argv[1]);
  double output_value = sqrt(input_value);
  fprintf(stdout, "The square root of %g is %g\n", input_value, output_value);

  return 0;
}
```

### 添加版本号和配置文件

接下来我们为这个项目添加第一个特性——版本号。虽然我们可以直接在源文件代码中写明，但使用 CMake 来实现可以提供更大的灵活性。修改之后的 `CMakeLists.txt` 如下：

```cmake
cmake_minimum_required (VERSION 2.6)
project (Tutorial)

# The version number.
set (TUTORIAL_VERSION_MAJOR 1)
set (TUTORIAL_VERSION_MINOR 0)
 
# configure a header file to pass some of the CMake settings
# to the source code
configure_file (
  "${PROJECT_SOURCE_DIR}/TutorialConfig.h.in"
  "${PROJECT_BINARY_DIR}/TutorialConfig.h"
  )
 
# add the binary tree to the search path for include files
# so that we will find TutorialConfig.h
include_directories("${PROJECT_BINARY_DIR}")
 
# add the executable
add_executable(Tutorial tutorial.cxx)
```

“Since the configured file will be written into the binary tree we must add that directory to the list of paths to search for include files.”（这句话不知道怎么去翻译，等自己有对应的知识储备了之后再来）

接下来，我们在项目主目录下创建 `TutorialConfig.h.in` 文件：

```c
// the configured options and settings for Tutorial
#define TUTORIAL_VERSION_MAJOR @TUTORIAL_VERSION_MAJOR@
#define TUTORIAL_VERSION_MINOR @TUTORIAL_VERSION_MINOR@
```

CMake 会使用 `CMakeLists.txt` 文件中的值来取代这里的 `@TUTORIAL_VERSION_MAJOR@` 和 `@TUTORIAL_VERSION_MINOR@`。

然后，我们修改 `tutorial.cxx` 源文件并增加版本号：

```c
// A simple program that computes the square root of a number
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "TutorialConfig.h"

int main(int argc, char *argv[]) {
  if (argc < 2) {
    fprintf(stdout,"%s Version %d.%d\n", argv[0], TUTORIAL_VERSION_MAJOR, TUTORIAL_VERSION_MINOR);
    fprintf(stdout, "Usage: %s number\n", argv[0]);
    return 1;
  }

  double input_value = atof(argv[1]);
  double output_value = sqrt(input_value);
  fprintf(stdout, "The square root of %g is %g\n", input_value, output_value);

  return 0;
}
```

可以看出，我们包含了一个 `TutorialConfig.h` 的头文件，并且使用版本号来打印出更有用的帮助信息。

**提示**：我们可以使用以下命令来验证我们的配置：

```bash
cd ~/cmake-tutorial
mkdir build
cd bulid
cmake -DCMAKE_BUILD_TYPE`Debug ..
make
```

这里会使用 GNU make 来生成项目，把 Debug 改成 Release 就会生成 Release 配置的 makefile。之后就可以在当前目录（`~/cmake-tutorial/build`）下看到生成的可执行文件 `Tutorial` 了。

## Step2 添加内库

第二步，向项目中添加内库。这个内库包含我们自己实现的平方根计算函数，可以使用这个实现去替代 `#include <math.h>` 中的 `sqrt()`。在本教程中，我们在项目主目录下新建 `MathFunctions` 文件夹用来存放内库。由此，项目结构如下：

```bash
$ tree .
.
├── CMakeLists.txt
├── MathFunctions
│   ├── CMakeLists.txt
│   ├── MathFunctions.h
│   └── mysqrt.cxx
├── TutorialConfig.h.in
├── build/
└── tutorial.cxx
```

对于 `MathFunctions` 目录下的 `CMakeLists.txt` 加入下面一行：

```cmake
add_library(MathFunctions mysqrt.cxx)
```

`mysqrt.cxx` 实现平方根计算，对外提供的 API 接口在 `MathFunctions.h` 给出。

对于项目主目录下的 `CMakeLists.txt`，使用 `add_subdirectory` 命令将内库给包含进来，使用 `include_directories` 命令添加另外的 `include` 目录，这样使得在编译时能够在 `MathFunctions/MathFunctions.h` 头文件中找到对应的 `mysqrt()` 函数原型。另外，在创建可执行文件时，使用 `target_link_libraries` 命令将内库给链接进来。因此，项目主目录下的 `CMakeLists.txt` 的最后几行配置为：

```cmake
include_directories ("${PROJECT_SOURCE_DIR}/MathFunctions")
add_subdirectory (MathFunctions) 
 
# add the executable
add_executable (Tutorial tutorial.cxx)
target_link_libraries (Tutorial MathFunctions)
```

当我们在编写一个项目时，如果使用的内库较大或者使用的内库又依赖于第三方库，这时候我们就希望能够有某种方法来实现对内库的动态选择，换句话说，在平方根的例子中，我们可以选择使用自己编写的 `mysqrt()` 函数，或者使用 `math.h` 提供的 `sqrt()` 函数。

首先，我们在项目主目录下的 `CMakeLists.txt` 中添加一个 `option` 命令：

```cmake
# should we use our own math functions?
option (USE_MYMATH "Use tutorial provided math implementation" ON) 
```

这样设置之后，如果我们使用的是 `CMake GUI` 应用就会看到其默认值显示为 `ON`，当然说是默认值，就可以对其进行修改。这个配置会保存在缓存中，这样每次运行 `cmake ..` 命令时就不需要重新去设置其值了。然后，添加一个条件语句，只有在条件满足的时候才会去链接并加载 `MathFunctions` 内库：

```cmake
# add the MathFunctions library?
if (USE_MYMATH)
  include_directories ("${PROJECT_SOURCE_DIR}/MathFunctions")
  add_subdirectory (MathFunctions)
  set (EXTRA_LIBS ${EXTRA_LIBS} MathFunctions)
endif (USE_MYMATH)
 
# add the executable
add_executable (Tutorial tutorial.cxx)
target_link_libraries (Tutorial  ${EXTRA_LIBS})
```

如上，使用 `USE_MYMATH` 去确定是否使用自己实现的平方根计算函数。**注意** 这里使用 `EXTRA_LIBS` 变量去保存这些可选内库。这是一个通常的做法，这样，当构建一个大项目，并且其包含很多个可选的内库时，使用一个临时变量去保存这些可选内库，就能够很方便地对这些内库进行管理了。

下面为第二步修改之后的 `tutorial.cxx` 源文件：

```c
// A simple program that computes the square root of a number
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "TutorialConfig.h"

#ifdef USE_MYMATH
#include "MathFunctions.h"
#endif

int main(int argc, char *argv[]) {
  if (argc < 2) {
    fprintf(stdout,"%s Version %d.%d\n", argv[0], TUTORIAL_VERSION_MAJOR, TUTORIAL_VERSION_MINOR);
    fprintf(stdout, "Usage: %s number\n", argv[0]);
    return 1;
  }

  double input_value = atof(argv[1]);
  double output_value = 0;

  if (input_value >= 0) {
#ifdef USE_MYMATH
    output_value = mysqrt(input_value);
    printf("mysqrt\n");
#else
    output_value = sqrt(input_value);
    printf("math.sqrt\n");
#endif
  }

  fprintf(stdout, "The square root of %g is %g\n", input_value, output_value);

  return 0;
}
```

在这里使用 `USE_MYMATH` 来确认是否要 `#include "MathFunctions.h"` 头文件，需要在 `TutorialConfig.h.in` 配置文件中添加：

```c
#cmakedefine USE_MYMATH
```

之后由 `CMake` 解析并提供给 `tutorial.cxx` 使用。

## Step3 安装及测试

接下来，我们为项目添加安装规则以及测试。

### 安装

安装很直截了当，在 `MathFunctions` 目录下的 `CMakeLists.txt` 中添加：

```cmake
install (TARGETS MathFunctions DESTINATION bin)
install (FILES MathFunctions.h DESTINATION include)
```

同样地，在项目的主目录下的 `CMakeLists.txt` 中添加：

```cmake
# add the install targets
install (TARGETS Tutorial DESTINATION bin)
install (FILES "${PROJECT_BINARY_DIR}/TutorialConfig.h"        
         DESTINATION include)
```

这样描述可能有点抽象，接下来我们来实际操作一下，假设我们当前所在目录为 `~/cmake-tutorial/`，目录结构如下：

```bash
$ tree .
.
├── CMakeLists.txt
├── MathFunctions
│   ├── CMakeLists.txt
│   ├── MathFunctions.h
│   └── mysqrt.cxx
├── TutorialConfig.h.in
├── build/
└── tutorial.cxx
```

使用下面命令：

```bash
cmake -DCMAKE_INSTALL_PREFIX`~/cmake-tutorial/build ..
make install
```

当然，这里推荐使用绝对路径，使用相对路径也没有多大的问题。执行这两条语句之后，由于我们使用 `CMAKE_INSTALL_PREFIX` 参数指定了生成的目标文件和头文件的存储地址（`~/cmake-tutorial/build`），目录结构变为（仅列出了 `build` 目录下与当前安装有关的文件）：

```bash
$ tree .
.
├── CMakeLists.txt
├── MathFunctions
│   ├── CMakeLists.txt
│   ├── MathFunctions.h
│   └── mysqrt.cxx
├── TutorialConfig.h.in
├── build
│   ├── CMakeCache.txt
│   ├── CMakeFiles (leave out)
│   ├── Makefile
│   ├── MathFunctions
│   │   ├── CMakeFiles (leave out)
│   ├── Tutorial
│   ├── TutorialConfig.h
│   ├── bin
│   │   ├── Tutorial
│   │   └── libMathFunctions.a
│   ├── cmake_install.cmake
│   ├── include
│   │   ├── MathFunctions.h
│   │   └── TutorialConfig.h
│   └── install_manifest.txt
└── tutorial.cxx
```

可以看到，可执行文件安装在 `bin` 文件夹，头文件保存在 `include` 文件夹。

### 测试

在项目的主目录下的 `CMakeLists.txt` 中添加一些基本测试用例去验证应用是否能够正确的运行：

```cmake
include(CTest)

# does the application run
add_test (TutorialRuns Tutorial 25)

# does it sqrt of 25
add_test (TutorialComp25 Tutorial 25)
set_tests_properties (TutorialComp25 PROPERTIES PASS_REGULAR_EXPRESSION "25 is 5")

# does it handle negative numbers
add_test (TutorialNegative Tutorial -25)
set_tests_properties (TutorialNegative PROPERTIES PASS_REGULAR_EXPRESSION "-25 is 0")

# does it handle small numbers
add_test (TutorialSmall Tutorial 0.0001)
set_tests_properties (TutorialSmall PROPERTIES PASS_REGULAR_EXPRESSION "0.0001 is 0.01")

# does the usage message work?
add_test (TutorialUsage Tutorial)
set_tests_properties (TutorialUsage PROPERTIES PASS_REGULAR_EXPRESSION "Usage:.*number")
```

在 `build` 之后，可以使用 `ctest Tutorial` 来执行这些测试用例。第一个测试用例，验证应用能否正常的运行，是否会出现段错误或者由于其他的原因而宕机。这是 `CTest` 最为基本的测试形式。之后的几个测试用例都使用了 `PASS_REGULAR_EXPRESSION` 的测试特性来验证输出中是否含有特定的字符串（当平方根计算正确时，是否与给定的测试结果相同；当输入的参数出现错误时，是否打印出合适的帮助信息）。假设需要添加更多的测试用例去验证应用的正确性，我们应该考虑定义宏（`Macro`）：

```cmake
#define a macro to simplify adding tests, then use it
macro (do_test arg result)
  add_test (TutorialComp${arg} Tutorial ${arg})
  set_tests_properties (TutorialComp${arg} PROPERTIES PASS_REGULAR_EXPRESSION ${result})
endmacro (do_test)
 
# do a bunch of result based tests
do_test (25 "25 is 5")
do_test (-25 "-25 is 0")
```

## Step4 添加系统自省检查

系统自省（System Introspection），就是去检查要使用的某些特性在特定平台上是否有提供支持。在本教程中，我们要去检查目标平台上是否有提供 `log` 和 `exp` 函数支持。当然，这两个函数作为 `math.h` 中的函数，基本上所有的平台都会给出支持，这里为了举例的方便，假设大多数平台上未提供 `log` 和 `exp` 函数支持。若某一平台上有 `log` 和 `exp` 函数，就使用它们在 `mysqrt` 函数中计算平方根，否则使用迭代的方法去计算平方根。

使用 `CMake` 提供的 `CheckFunctionExists` 宏去检查其可用性，在项目主目录下的 `CMakeLists.txt` 中添加：

```cmake
# does this system provide the log and exp functions?
include (CheckFunctionExists)
check_function_exists (log HAVE_LOG)
check_function_exists (exp HAVE_EXP)
```

在 `TutorialConfig.h.in` 中定义 `HAVE_LOG` 和 `HAVE_EXP` 变量，这样当 `CMake` 发现该特定平台上有提供对 `log` 和 `exp` 的支持时，可以使用这两个变量。

```c
// does the platform provide exp and log functions?
#cmakedefine HAVE_LOG
#cmakedefine HAVE_EXP
```

“It is important that the tests for log and exp are done before the configure_file command for TutorialConfig.h. The configure_file command immediately configures the file using the current settings in CMake.”（这句话也不知道怎么去理解）

最后，在 `mysqrt.cxx` 中检查系统是否对 `log` 和 `exp` 有支持，若支持，则使用它们去实现平方根的计算；否则，使用迭代的方法去计算平方根。

```c
// if we have both log and exp then use them
#if defined (HAVE_LOG) && defined (HAVE_EXP)
  result = exp(log(x)*0.5);
#else // otherwise use an iterative approach
  ...
```

## Step5 添加生成器

接下来，我们为项目添加一个生成器（Generator）。在本教程中，我们创建一个预先计算好的平方根表格，若输入数值（待计算其平方根）包含在预处理的表格中，直接查表即可得到其平方根；若不在表格中，就调用 `mysqrt()` 进行计算，这在大型项目中可以节省很多计算开销。首先，在 `MathFunctions` 文件夹下新建 `MakeTable.cxx` 源文件来生成这个预先计算好了的平方根表格。

```c
// A simple program that builds a sqrt table
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main (int argc, char *argv[]) {
  int i;
  double result;

  // make sure we have enough arguments
  if (argc < 2) {
      return 1;
  }

  // open the output file
  FILE *fout = fopen(argv[1], "w");
  if (!fout) {
      return 1;
  }

  // create a source file with a table of square roots
  fprintf(fout, "double sqrtTable[] = {\n");
  for (i = 0; i < 10; ++i) {
      result = sqrt(static_cast<double>(i));
      fprintf(fout, "%g,\n", result);
  }

  // close the table with a zero
  fprintf(fout, "0};\n");
  fclose(fout);

  return 0;
}
```

然后，在 `MathFunctions` 目录下的 `CMakeLists.txt` 中添加合适的命令来创建 `MakeTable` 可执行文件：

```cmake
# first we add the executable that generates the table
add_executable(MakeTable MakeTable.cxx)
 
# add the command to generate the source code
add_custom_command (
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/Table.h
  COMMAND MakeTable ${CMAKE_CURRENT_BINARY_DIR}/Table.h
  DEPENDS MakeTable
  )
 
# add the binary tree directory to the search path for 
# include files
include_directories( ${CMAKE_CURRENT_BINARY_DIR} )
 
# add the main library
add_library(MathFunctions mysqrt.cxx ${CMAKE_CURRENT_BINARY_DIR}/Table.h)
```

1. `add_executable` 命令添加 `MakeTable` 可执行文件；
2. `add_custom_command` 命令说明如何由 `MakeTable` 产生 `Table.h`；
3. `add_library` 命令将生成的 `Table.h` 加入到创建 `MathFunctions` 内库的源代码列表中，以使得 `CMake` 知道 `mysqrt.cxx` 依赖于这个刚生成的 `Table.h`；
4. `include_directories` 命令将当前的二进制目录添加进 `include` 中，以使得 `mysqrt.cxx` 能够使用 `Table.h`。

当我们创建（`build`）这个项目时，首先生成 `MakeTable` 可执行文件，然后运行 `MakeTable` 生成 `Table.h` 头文件，之后编译 `#include "Table.h"` 的 `mysqrt.cxx` 源文件来创建 `MathFunctions` 内库。这样我们就能够在 `Tutorial.cxx` 中使用 `MathFunctions` 内库了。

至此，项目主目录下的的 `CMakeLists.txt` 为：

```cmake
cmake_minimum_required (VERSION 2.6)
project (Tutorial)

# The version number.
set (TUTORIAL_VERSION_MAJOR 1)
set (TUTORIAL_VERSION_MINOR 0)

# does this system provide the log and exp functions?
include (${CMAKE_ROOT}/Modules/CheckFunctionExists.cmake)
check_function_exists (log HAVE_LOG)
check_function_exists (exp HAVE_EXP)

# should we use our own math functions
option(USE_MYMATH "Use tutorial provided math implementation" ON)

# configure a header file to pass some of the CMake settings
# to the source code
configure_file (
  "${PROJECT_SOURCE_DIR}/TutorialConfig.h.in"
  "${PROJECT_BINARY_DIR}/TutorialConfig.h"
  )

# add the binary tree to the search path for include files
# so that we will find TutorialConfig.h
include_directories("${PROJECT_BINARY_DIR}")

# add the MathFunctions library?
if (USE_MYMATH)
  include_directories ("${PROJECT_SOURCE_DIR}/MathFunctions")
  add_subdirectory (MathFunctions)
  set (EXTRA_LIBS ${EXTRA_LIBS} MathFunctions)
endif ()

# add the executable
add_executable(Tutorial tutorial.cxx)
target_link_libraries (Tutorial  ${EXTRA_LIBS})

# add the install targets
install (TARGETS Tutorial DESTINATION bin)
install (FILES "${PROJECT_BINARY_DIR}/TutorialConfig.h"
  DESTINATION include)

# enable testing
enable_testing ()

# does the application run
add_test (TutorialRuns Tutorial 25)

# does the usage message work?
add_test (TutorialUsage Tutorial)
set_tests_properties (TutorialUsage
  PROPERTIES
  PASS_REGULAR_EXPRESSION "Usage:.*number"
  )

#define a macro to simplify adding tests
macro (do_test arg result)
  add_test (TutorialComp${arg} Tutorial ${arg})
  set_tests_properties (TutorialComp${arg}
    PROPERTIES PASS_REGULAR_EXPRESSION ${result}
    )
endmacro ()

# do a bunch of result based tests
do_test (4 "4 is 2")
do_test (9 "9 is 3")
do_test (5 "5 is 2.236")
do_test (7 "7 is 2.645")
do_test (25 "25 is 5")
do_test (-25 "-25 is 0")
do_test (0.0001 "0.0001 is 0.01")
```

配置文件 `TutorialConfig.h.in` 为：

```c
// the configured options and settings for Tutorial
#define TUTORIAL_VERSION_MAJOR @TUTORIAL_VERSION_MAJOR@
#define TUTORIAL_VERSION_MINOR @TUTORIAL_VERSION_MINOR@
#cmakedefine USE_MYMATH

// does the platform provide exp and log functions?
#cmakedefine HAVE_LOG
#cmakedefine HAVE_EXP
```

`MathFunctions` 目录下的 `CMakeLists.txt` 为：

```cmake
# first we add the executable that generates the table
# add the binary tree directory to the search path for include files
include_directories( ${CMAKE_CURRENT_BINARY_DIR} )

add_executable(MakeTable MakeTable.cxx )

# add the command to generate the source code
add_custom_command (
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/Table.h
  COMMAND MakeTable ${CMAKE_CURRENT_BINARY_DIR}/Table.h
  DEPENDS MakeTable
  )

# add the main library
add_library(MathFunctions mysqrt.cxx ${CMAKE_CURRENT_BINARY_DIR}/Table.h)

install (TARGETS MathFunctions DESTINATION bin)
install (FILES MathFunctions.h DESTINATION include)
```

## Step6 安装器

我们想要将项目给分发出去，为不同平台的用户提供二进制文件和源文件代码，这样用户就能够下载得到自己希望的 `distributions` 了。需要解释的是，在 [Step3] 中也执行了安装操作，将从源代码文件编译生成的可执行文件给安装到指定的 `bin` 目录下。而在本小节将要创建的项目分发不仅支持二进制安装，并且能够满足各大平台上包管理系统的特性。在这里，我们使用 `CMake` 提供的 `CPack` 工具去创建，需要在项目主目录下的 `CMakeLists.txt` 的末尾增加：

```cmake
# build a CPack driven installer package
include (InstallRequiredSystemLibraries)
set (CPACK_RESOURCE_FILE_LICENSE
  "${CMAKE_CURRENT_SOURCE_DIR}/License.txt")
set (CPACK_PACKAGE_VERSION_MAJOR "${TUTORIAL_VERSION_MAJOR}")
set (CPACK_PACKAGE_VERSION_MINOR "${TUTORIAL_VERSION_MINOR}")
include (CPack)
```

1. 包含了 `InstallRequiredSystemLibraries` 模块，其包含当前平台为运行此项目所需要的所有运行时内库；
2. 设置了三个 `CPack` 变量，证书信息和版本号信息；
3. 包含了 `CPack` 模块，以使得我们能够使用这些变量，以及一些其特有的特性。

接下来，我们只需要 `build` 这个项目，然后运行 `CPack` 就可以了：

```bash
cd build
cmake ..
cpack --config CPackConfig.cmake # To build a binary distribution you would run
cpack --config CPackSourceConfig.cmake # To create a source distribution you would type
```

## Step7

现在还没有认识到这一步的具体作用的是什么，是为了数据可视化展示呢？还是什么？之后使用到了，有了心得体会，再来补充。

## 增补

2021 年 4 月迁移博客时，发现 CMake Tutorial 已[更新](https://cmake.org/cmake/help/latest/guide/tutorial/index.html)。

## 版权声明

本作品采用[知识共享署名 4.0 国际许可协议](http://creativecommons.org/licenses/by/4.0/)进行许可，转载时请注明原文链接。
