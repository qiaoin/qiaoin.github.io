---
title: 当我们谈论协程时，我们在谈论什么
author: qiaoin
date: '2021-11-04'
slug: all-you-should-know-about-coroutines
categories:
  - 操作系统
  - 编程语言
  - 源码阅读
tags:
  - Go
  - Coroutine
---

「什么是协程？」几乎是现在面试的必考题。一方面，Donald E. Knuth 说「子过程是协程的一种特殊表现形式」"Subroutines are special cases of more general program components, called coroutines"[^1]（子过程，我们可以理解为函数 functions[^2]）；另一方面，由于 coroutines 的中文翻译「协程」中包含有「程」字，因此一般会拿来与「进程」（processes）、「线程」（threads）进行比较，称为「轻量级线程」"light-weight threads"[^3]。这是我们学习新知识的常用方法，与自己熟悉的知识点进行类比。函数是写代码的封装利器，线程常用来做多任务处理，现在都用来类比协程。那协程和函数、协程和线程，有什么区别与联系呢？为什么可以进行如此类比？这是我们需要思考的问题。

这篇文章就让我们一起来看看关于协程的一些问题 —— 当我们在谈论协程时，我们在谈论什么？

我将从以下几个方面来进行介绍

【贴一张全文的思维导图，只讲什么是协程。后面可以更新为一个系列，为什么需要协程，协程目前有哪些实现】



## 协程是什么？

wikipedia 的定义如下：

> Coroutines are computer program components that **generalize subroutines** for **non-preemptive multitasking**, by allowing execution to be suspended and resumed.

这里有两个关键词：

1、**generalize subroutines** —— 泛化的 subroutines。这就说明了协程是 subroutines，但其概念比 subroutines 要更通用一些。首先我们要知道什么是 subroutines —— 即什么是函数（functions）[^2]？然后再确定协程相较于函数，在哪些方面更为泛化？

2、**non-preemptive multitasking** —— 非抢占的多任务处理。这里说明了协程的作用。我们需要知道什么是多任务处理（multitasking）？什么形式的多任务处理是抢占的（preemptive multitasking），什么形式的多任务是非抢占的（non-preemptive multitasking, cooperative multitasking 协作式多任务处理）？以及为什么会有抢占和非抢占的区分？

### 函数

函数，是计算机软件的一个核心抽象概念，将一组实现特定功能的代码段封装起来，接受一些输入参数，返回一些输出参数；可以在任何需要执行此操作的地方调用封装好的函数。

假设有两个函数 P 和 Q，函数 P 调用函数 Q，函数 Q 执行完成后返回函数 P。

```rust
fn P() -> u32 {
    // ...
    Q(1)  // -----> 调用 Q，传递一个输入参数，返回一个输出参数
    // ...
}

fn Q(i: u32) -> u32 {
   let x = 41;
   x + i
}
```

实现上述的函数调用过程，需要满足以下几个条件：

1、控制权转移（passing control）：CPU 使用程序计数器（PC）来表示当前正在执行的指令地址

- 函数 P 调用函数 Q 时，PC 指向函数 Q 的入口地址
- 函数 Q 执行完毕，返回函数 P，PC 指向函数 P 调用函数 Q 的下一行指令地址

2、数据传递（passing data）：函数 Q 能够接受函数 P 传递的输入参数，函数 P 能够获取执行完函数 Q 的返回值

3、内存的分配和释放（allocating and deallocating memory）：函数 Q 开始执行时，可能需要分配内存，在执行完毕后，需要释放内存

所有的这些，目前都依赖寄存器和调用栈进行实现。

我们首先来看一下一个程序在运行时的内存布局。一个可执行文件加载到内存进行执行，会对应操作系统中的一个进程。进程拥有独立的虚拟地址空间。图 2 表示一个典型的 Linux 进程虚拟空间的内存布局。

<img src="./images/process-virtual-space.svg" alt="concurrent-and-parallel" style="zoom: 25%;" />

主要包含有四个部分：

1、栈：用于维护函数调用的上下文

2、堆：程序执行时动态分配的内存空间，例如 C 语言中的 `malloc()` 内存分配函数

3、可执行文件映像：可执行文件在内存中的映像，包含只读的代码段和支持读写的数据段

4、保留区：是对内存中受到保护而禁止访问的内存区域的总称

我们主要关注栈。

栈是程序运行的基础。每当一个函数被调用时，一块连续的内存就会在栈顶被分配出来，这块内存被称为帧（frame）。

从图 2 的内存布局中，我们知道，**栈是自顶向下增长的**（由高地址向低地址），一个程序的调用栈最底部 —— 除去入口帧（entry frame） —— 就是 `main()` 函数对应的帧，而随着 `main()` 函数一层层调用，帧会一层层扩展；调用结束，栈又会一层层回溯，把内存释放回去。

在调用的过程中，**一个新的帧会分配足够的空间存储寄存器的上下文**。在函数里使用到的通用寄存器会在栈上保存一个副本，当这个函数调用结束，返回时，通过副本可以恢复出原来的寄存器的上下文，就好像什么都没有发生过一样。此外，函数所需要使用到的局部变量，也都会在帧分配的时候被预留出来。

整个过程可以看看图 3 辅助理解，`main()` 调用 `hello()`，`hello()` 调用 `world()`。更详细的过程可以参看《深入理解计算机系统》（第三版）3.7 Procedures 和《程序员的自我修养——链接、装载与库》10.2 栈与调用惯例。

<img src="./images/call-stack.svg" alt="concurrent-and-parallel" style="zoom: 25%;" />

前面提到的函数调用需要保证的三个条件，通过寄存器和栈进行实现：

1、控制权转移 —— PC 表示当前正在执行的指令地址，通过修改 PC 的值实现控制权转移（对应汇编指令 `call` / `ret`）。`callee` 的入口地址（相对地址）在编译期（TODO 待确认）就已经确定下来，`caller` 的返回地址保存在栈帧上

2、数据传递 —— 入参，少于 6 个入参的可以直接通过寄存器传递，多于 6 个的入参使用栈帧上的参数列表进行传递；返回值，寄存器 `eax` 保存返回值

3、内存的分配和释放 —— 通过修改栈顶指针进行内存的分配和释放：栈顶指针往下增长为分配内存，往上回溯为释放内存

### 协程 v.s. 函数

通过上一小节的介绍，函数的概念我们已经很明晰了。那函数和协程有什么关系呢？

首先来看看二者的区别：

1、对称与非对称[^1]

- 函数：调用关系是非对称的（unsymetric），例如 `main()` 调用 `hello()`，`hello()` 执行完成返回时只能回到 `main()`，称 `main()` 为 `caller`，`hello()` 为 `callee`，二者存在调用和被调用的关系；

<img src="./images/function-caller-callee.svg" alt="concurrent-and-parallel" style="zoom:50%;" />

- 协程：协程之间是完全对等的（complete symmetry），多个协程之间可以任意调用。因此，可以分为，【看一看那篇论文，补充一下内容，尽量不要提到协程的具体实现】
  - 1）**对称协程** —— 实现时不添加任何限制，多个协程之间可以任意跳转
  - 2）**非对称协程** —— 实现时人为添加限制，让协程之间存在调用和被调用的关系，如协程 A 调用/恢复协程 B，协程 B 挂起/返回时只能回到协程 A，类似函数调用（会在后面详细解释）

2、恢复执行的入口地址是否确定[^1]

- 函数：`callee` 的入口地址固定，在 `callee` 执行完成后，`caller` 从上一次终止的地方继续向下执行
- 协程：当协程恢复执行时，都是从一次终止的地方继续向下执行

函数与协程，二者也存在一些联系，**函数是一种特殊的（非对称）协程**。我们可以从另一个角度来理解函数：`main()` 和 `hello()` 作为一个 team 来完成一件事情，`main()` 开始执行，在执行过程中调用 `hello()`，此时 `main()` 挂起（需要保存 `main()` 上下文，方便后续恢复）；在 `hello()` 执行完成后，`main()` 恢复执行（根据保存的 `main()` 的上下文进行恢复，而 `hello()` 由于已经完成了使命，不存在恢复操作，它的上下文不需要保存，就直接 `pop` 出栈了） 

为什么函数调用，`callee` 返回时的上下文不用保存呢？因为在 `callee` 返回时能够保证其函数体已经执行完成（执行完了函数体的最后一行指令）。而对于协程，没有这样的保证，协程可能在执行到任何指令时主动进行挂起，控制流切换到另一个协程进行执行。为了后续能够恢复执行，因此每次挂起协程时，都需要保存好当前被挂起协程的上下文。

至此，我们就能理解文章开头 Knuth 的那句话了 —— "Subroutines are special cases of more general program components, called coroutines"[^1]。

聊完了函数与协程，我们继续来看一下协程与多任务处理的关系？

### 多任务处理

> Multitasking: the ability to execute multiple tasks concurrently

多任务是操作系统提供的特性，指能够**并发**地执行多个任务。比如现在你在阅读这篇文章的同时还打开着其他的应用程序（VSCode、iTerm2、微信等等）。即使你此时仅打开了一个浏览器的窗口，后台也会有很多任务正在运行着（管理系统状态、检查更新等等）。这样看上去好像多个任务在并行运行，实际上，一个 CPU 核心在同一时间只能执行一条指令。

那如何在单核 CPU 上执行多任务呢？这依赖于分时系统（time-sharing system），它将 CPU 时间切分成一段一段的时间片，当前时间片执行任务 1，下一个时间片执行任务 2，操作系统在多个任务之间快速切换，推进多个任务向前运行，由于时间片很短，在绝大多数情况下我们都感觉不到这些切换。这样就营造了一种**并行的错觉**。

那**真实的并行**是怎么样的呢？需要有多个 CPU 核心，每一个核心负责处理一个任务，这样在同一个时间片下就会同时有多条指令在并行运行着（每个核心对应一条指令），不需要进行任务的切换。图 4 很好地阐释了并发与并行的区别（一个矩形框表示一个 CPU 核心）。

<img src="./images/concurrent-and-parallel.svg" alt="concurrent-and-parallel" style="zoom:50%;" />

因此，我们说**并发（concurrency）是一种能力，并行（parallelism）是一种手段**。当我们的系统拥有并发的能力后，代码如果跑在多个 CPU 核上，就可以并行运行。

现在我们主要讨论的是单核 CPU 上的多任务处理，涉及到以下几个问题：

1、任务是什么，我们如何抽象任务这一概念？

2、多个任务之间需要进行切换，把当前任务的上下文先保存起来，把另一个任务的上下文恢复，那么任务的上下文都包含哪些东西呢？怎么保存和恢复？

3、什么情况下进行任务切换？

从目前的现实来看，任务的抽象并不唯一。我们熟悉的进程和线程，以及本文讨论的协程，都可以作为这里任务的抽象。这三类对象都可被 CPU 核心赋予执行权，它至少需要包含下一条将要执行的指令地址，以及运行时的上下文。

从任务的抽象层级来看：对于进程，其上下文保存在进程控制块中；对于线程，其上下文保存在线程控制块中；而对于协程，上下文信息由程序员自己进行维护（使用内库或者编程语言层面的支持）。

| 任务抽象 |            上下文            |
| :------: | :--------------------------: |
|   进程   |        进程控制块 PCB        |
|   线程   |        线程控制块 TCB        |
|   协程   | 用户程序自己维护 use-defined |

但如果我们换一个角度，从 CPU 的角度来看，这里所说的任务的上下文表示什么呢？我们都知道，冯诺依曼体系结构计算机，执行程序主要依赖的是内置存储：寄存器和内存，这就构成了程序运行的上下文（context）。

先看寄存器。寄存器的数量很少且可以枚举，我们直接通过寄存器名进行数据的存取。在将 CPU 的执行权从任务 1 切换到任务 2 时，要把任务 1 所使用到的寄存器都保存起来（以便后续轮到任务 1 继续执行时进行恢复），并且寄存器的值恢复到任务 2 上一次执行时的值，然后才将执行权交给任务 2。

再看内存。不同的任务可以有不同的地址空间，通过不同的地址映射表来体现。如何切换地址映射表，也是修改寄存器。

所以，任务的上下文就是一堆寄存器的值。要切换任务，只需要保存和恢复一堆寄存器的值就可以了。**无论是进程、线程还是协程，都是如此。**

至此，我们就回答了前两个问题，什么是任务以及任务的上下文是什么，如何进行保存和恢复。

接下来我们来看第三个问题，任务在什么时候进行切换？一个任务占用着 CPU 核心在运行着，有两种方式让它放弃对 CPU 的控制，一个是主动，一个是被动。主动和被动，在计算机中有它的专有用词，抢占式和协作式。

抢占式是被动的，由操作系统来控制切换任务的时机；协作式，也称为非抢占式，是主动的，是任务主动放弃对 CPU 的控制。

#### 抢占式多任务







#### 协作式多任务









### 协程 v.s. 线程





### 小结





















## 画图工具

文中的图片使用 [excalidraw](https://excalidraw.com/) 绘制

## 版权声明

本作品采用[知识共享署名 4.0 国际许可协议](http://creativecommons.org/licenses/by/4.0/)进行许可，转载时请注明原文链接。

## References

[^1]: 《计算机程序设计艺术 第一卷 基本算法》1.4.2 Coroutines

> Subroutines are special cases of more general program components, called *coroutines*. In contrast to the unsymmetric relationship between a main routine and a subroutine, there is complete symmetry between coroutines, which *call on each other*.
>
> To understand the coroutine concept, let us consider another way of thinking about subroutines. The viewpoint adopted in the previous section was that a subroutine merely was an extension of the computer hardware, introduced to save lines of coding. This may be true, but another point of view is possible: We may consider the main program and the subroutine as a *team* of programs, each member of the team having a certain job to do. The main program, in the course of doing its job, will activate the subprogram; the subprogram will perform its own function and then activate the main program. We might stretch our imagination to believe that, from the subroutine's point of view, when it exits *it* is calling the *main* routine; the main routine continues to perform its duty, then "exits" to the subroutine. The subroutine acts, then calls the main routine again.
>
> The essential difference between routine-subroutine and coroutine-coroutine linkage is that a subroutine is always initiated *at its beginning*, which is usually a fixed place; the main routine or a coroutine is always initiated *at the place following* where it last terminated.

[^2]: 《深入理解计算机系统》（第三版）3.7 Procedures

> Procedures come in many guises in different programming languages -- functions, methods, subroutines, handlers, and so on -- but they all share a general set of features.

[^3]: [Concurrency and coroutines | Kotlin (kotlinlang.org)](https://kotlinlang.org/docs/kmm-concurrency-and-coroutines.html) 明确写到





