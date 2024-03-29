---
title: 内存管理
author: qiaoin
date: '2020-02-19'
slug: 1-memory-management
categories:
  - 操作系统
tags: []
---

> 重学操作系统系列，清华大学操作系统课程笔记

---

{{< toc >}}

---

计算机系统包括CPU、内存和 I/O 设备，使用总线进行连接。CPU 中寄存器速度最快但个数和存储容量有限，高速缓存（L1 级缓存和 L2 级缓存）由硬件存储管理单元（Memory Management Unit，MMU）控制。内存的最小访问单元是 1 字节（8 bit）。通常我们说的计算机系统是 32 位总线，就是一次读写可以从内存中读取 32 bit，也就是 4 字节（一次读写 32 位会有地址对齐的问题）。磁盘的最小访问单元是 512 字节

计算机存储体系是分层结构，各部分访问速度是有很大差距的

![computer-memory-layers](images/computer-memory-layers.png)

存储管理期望达到的效果：

![mmu](images/mmu.png)

MMU —— 将逻辑的地址空间转换为物理的地址空间

- 抽象：将线性的物理地址空间转变成抽象的逻辑地址空间
- 保护：独立的地址空间，每一个进程只能访问自己的空间
- 共享：访问相同的内存，操作系统内核代码对各个进程绝大部分都是一样的
- 虚拟化：每个进程自己看到的是区域一致的地址空间，虽然其在内存或外存上有不同的物理地址空间。逻辑地址空间 > 物理内存空间

操作系统的内存管理方式

- 重定位（relocation）：要求一个程序的所有内容连续存放
- 分段（segmentation）：将程序分成数据段、代码段以及堆栈，相对独立。要求一个段的内容连续
- 分页（paging）：实际上就是将内存分成最基本的单位，一个页的内容要求连续
- 虚拟存储（virtual memory）：目前多数系统采用按需页式虚拟存储

以上这些内存管理方式的实现都高度依赖硬件，1）与计算机存储架构紧耦合，2）MMU（内存管理单元）：处理 CPU 存储访问请求的硬件

## 地址生成

程序里用到的各种符号 -> 总线上出现的物理地址

### 地址空间的定义

在总线上看到的地址（物理地址），所有物理地址所构成的空间叫物理地址空间，由硬件支持。通常我们说计算机有多少位地址总线，指的就是物理地址总线的条数（32 位机器，32 条地址总线）

- 起始地址 0，直到 MAX(sys)，这个编号在存储单元角度来讲是唯一的，这就不适合用来写程序，早期人们编程是直接使用物理地址，不利于编程和维护

于是就有了逻辑地址，是 CPU 运行时里边的进程看到的地址空间，对应的是可执行文件中的一段区域

- 起始地址 0，直到 MAX(prog)
- 程序加载到物理内存中进行执行，就有了进程的概念

![pa-va](images/pa-va.png)

### 逻辑地址生成

![logical-address-generate](images/logical-address-generate.png)

- 编译
- 汇编
- 链接
- 加载

### 地址生成的时机和限制

1. 编译时生成
    - 假设在编译的时候就知道最后要放置的位置，那么在编译时就能够将地址写死
    - 如果起始地址发生改变，必须重新编译
2. 加载时生成
    - 如果编译时起始地址未知，编译器需生成可重定位的代码（relocatable code），可重定位表
    - 加载时，生成绝对地址
3. 执行时生成（相对地址）
    - 执行到这条指令的时候，才能够确切知道它访问的是什么地方。出现在虚拟存储系统中
    - 存在一个映射表，仅在执行到这条指令时才会去查表完成映射
    - 需要地址转换（映射）硬件支持

### 地址的生成过程

![address-generate](images/address-generate.png)

1. CPU
    - ALU：需要逻辑地址的内存内容，这里 0xfffa620e 就是对应的逻辑地址
    - MMU：进行逻辑地址和物理地址的转换（依据页表）
    - CPU 控制逻辑：给总线发送物理地址请求（物理地址和总线控制信号）
2. 内存
    - 存储芯片：识别总线上的地址和控制信号（读信号/写信号）
    - 内存存储单元：发送物理地址的内容给 CPU 或 接收 CPU 数据到物理地址
3. 操作系统
    - 建立逻辑地址 LA 和物理地址 PA 的映射
    - 实际上逻辑地址和物理地址之间的转换是由硬件 MMU 来完成的，但操作系统可以来维护这个映射转换的表（页表）

在地址生成过程中，使用段的 limit 进行地址检查，然后加上段的 base。操作系统能够设置段的 limit 和 base。这样就能够从 符号 -> 逻辑地址 ->（在执行的过程中转变，并进行相应的检查机制） 物理地址

![address-check](images/address-check.png)

## 连续内存分配

给进程分配一块不小于指定指定大小的连续的物理内存区域

![continuous-memory-allocation](images/continuous-memory-allocation.png)

这样就会产生一些内存碎片，即不能被利用的空闲内存（蓝色标识部分）：

- 外部碎片：分配单元之间未被使用的内存
- 内部碎片：分配单元内部未被使用的内存（取决于分配单元大小是否需要取整）

### 动态分区分配

- 当程序被加载执行时，分配一个进程指定大小可变的分区（块、内存块）
- 分区的地址是连续的

**操作系统需要维护的数据结构**：

- 1) 所有进程的已分配分区：已分配分区的位置和大小，以及分配给了哪个进程进行执行
- 2) 空闲分区（empty block）：空闲分区的位置和大小

使用不同的算法进行寻找可用分区或者释放已用分区，对这两个数据结构的操作是不一样的，开销也不一样

动态分区分配的策略有：1. 最先匹配（First-fit），2. 最佳匹配（Best-fit），3. 最差匹配（Worst-fit）

1. **最先匹配（First Fit Allocation）策略**：分配 n 个字节，使用第一个可用的空间比 n 大的空闲块
    - 实现：空闲分区列表按地址顺序排序。分配时，搜索第一个合适的分区；释放分区时，检查是否可与临近的空闲分区合并
    - 优点：简单，在高地址空间有大块的空闲分区
    - 缺点：外部碎片（由于是从低地址向高地址按需第一个匹配就分配），在进行大块内存分配时，需要对前面的很多个小块进行检索才能找到大块，分配大块时速度较慢
2. **最佳匹配（Best Fit Allocation）策略**：分配 n 字节分区时，查找并使用不小于 n 的最小空闲分区
    - 实现：空闲分区列表按照大小进行排序。分配时，查找一个合适的分区；释放时，查找并合并临近地址的空闲分区（由于空闲分区列表是按照大小排序，现在需要查找地址临近的），并根据合并后的空闲分区大小按顺序插入到空闲分区列表里
    - 优点：大部分分配的尺度较小时，效果很好，1）可避免大的空闲分区被拆分，2）可减少外部碎片的大小，3）相对简单
    - 缺点：1）由于剩下的“边角料”较小，就越没法被利用到，容易产生很多无用的小碎片，产生外碎片多；2）释放分区较慢，因为要对地址临近的空闲分区进行合并
3. **最差匹配（Worst Fit Allocation）策略**：分配 n 字节，使用尺寸不小于 n 的最大空闲分区
    - 实现：空闲分区列表从大到小排序。分配时，选最大的分区；释放时，检查是否可与临近地址的空闲分区合并，进行可能的合并并调整空闲分区列表顺序
    - 优点：1）中等大小的分配较多，效果最好；2）避免出现太多的小碎片
    - 缺点：1）释放分区较慢；2）外部碎片；3）容易破坏大的空闲分区，因此后续难以分配大的分区

=> 对空闲分区列表的维护：按照什么排序（大小，地址）？分配时的查找开销？释放时的合并开销？将合并的空闲分区放回到空闲分区列表中时，查找合适位置的开销

### 碎片整理

通过调整进程占用的分区位置来减少或避免分区碎片

1. 碎片紧凑（compaction）：通过移动分配给进程的内存分区，以合并外部碎片

![compaction](images/compaction.png)

进行碎片紧凑的条件：所有的应用程序可动态重定位。需要解决的问题：什么时候移动（在进程等待状态去进行移动）？开销多少？

2. 分区对换（Swapping in/out）：通过抢占并回收处于等待状态进程的分区，以增大可用内存空间。通过一个图示进行说明：

![swapping-0](images/swapping-0.png)

包含 1. 内存和外存的状态；2. 进程执行过程中维护的进程的状态信息

每创建一个进程，就需要在内存中占用一块区域，创建完成之后（操作系统需要维护的进程相关的数据结构都初始化完成），并且得到 CPU 就开始运行（之前在就绪队列，现在调度开始运行）。在 P1 运行的过程中，假设有新的进程 P2 要创建，需要在内存中分配相应的存储区域，P2 到达就绪状态（放置在就绪队列中），P1 还在继续运行

![swapping-1](images/swapping-1.png)

由于某种原因，P1 处于等待状态，P2 得到 CPU 开始运行，同时新的进程 P3 创建完成，在内存中分配相应存储区域，加入就绪队列

![swapping-2](images/swapping-2.png)

现在，如果又有一个进程 P4 创建，内存空间就不够用了。操作系统会将处于等待状态的 P1 移动到外存中去（P1 在内存中分配的空间），空闲出来的空间就可以分配给 P4 需要的内存了。这样就能够使得更多的进程在系统里交替运行了。

![swapping-3](images/swapping-3.png)

在 Linux 或 Unix 系统里面，有一个分区就叫对换区（Swapping），在早期的时候就是一种充分利用内存的方法，实现多进程的交替运行（开销很大）。但这里需要解决的问题，交换哪个（哪些）程序？

![swapping](images/swapping.png)

### 伙伴系统（Buddy System）

**规定**：

- 整个可分配的分区大小 `$2^U$`
- 需要的分区大小为 `$2^U - 1 < S \leq 2^U$` 时，把整个块分配给该进程
  - 若 `$S \leq 2^{i-1} - 1$`，将大小为 `$2^i$` 当前空闲分区划分成两个大小为 `$2^{i-1}$` 的空闲分区
  - 重复划分过程，直到 `$2^{i-1} < S \leq 2^i$`，并把一个空闲分区分配给该进程
  - 即，将待分配空间的大小的二倍与空闲块大小进行比较

**实现**：

- 空闲块按大小和起始地址组织成二维数组
- 初始状态：只有一个大小为 `$2^U$` 的空闲块
- 分配时，由小到大在空闲块数组中找最小的可用空闲块，如果空闲块过大，对可用空闲块进行二等分，直到得到合适的可用空闲块
![buddy-system-example](images/buddy-system-example.png)
- 释放过程：把释放的块放入空闲块数组，合并满足合并条件的空闲块
- 合并的条件
  - 大小相同 `$2^i$`
  - 地址相邻
  - 起始地址较小的块，其起始地址必须是 `$2^{i+1}$` 的倍数

=> Linux 和 Unix 使用伙伴系统做内核中的存储分配

## 内存管理单元 MMU

**Q1**：操作系统怎么利用 MMU 的功能来实现内存的映射的？将虚拟的连续地址空间映射到离散的物理地址空间里去

根据段寄存器中的高 13 位作为 index 来索引全局描述符表 GDT，找到对应的项为段描述符，段描述符中包含一些信息，其中重要的是段基址和段的大小。仅开始段机制，完成虚拟地址到线性地址（物理地址）的转换

段寄存器中的信息、段描述符中的信息，都需要操作系统来填写好

![segment-method](images/segment-method.png)

GDT 放置在内存中，占用空间有点大。那如果每一次进行地址映射的时候都需要根据段选择子去内存中查找 GDT 表中的段描述符，开销太大。硬件将操作系统建立在 GDT 表中段描述符的关键信息放置在 CPU 中，我们可见的是段寄存器中存储的 16 位的值，隐藏在后端的部分是我们开不见的，由硬件直接控制，其中缓存了段基址、段的长度和访问限制等。MMU 可以直接访问，这样就能够加快段的映射过程，从而提高效率

采用段机制进行安全保护（弱化段的映射机制），同时采用页机制为主的一种页映射关系

![page-method](images/page-method.png)

注意这里是 线性地址 -> 物理地址，为什么不是虚拟地址呢？因为进入保护模式之后段机制是一定存在的（为了向后兼容），这里的段机制的映射是对等映射，因此这里的线性地址与我们认为的虚拟地址是一样的

![page-map-example](images/page-map-example.png)

![page-dir-tb](images/page-dir-tb.png)

使能页机制：为了在保护模式下使能页机制，OS 需要置 CR0 寄存器中的 bit 31 (PG) 为 1

![control-registers-2](images/control-registers-2.png)

![mmu-page-tables](images/mmu-page-tables.png)

TODO: 需要理解为什么这样做？

在页表中建立页的映射关系：给虚拟地址和物理地址，尝试分配一个对应的页表项，使得虚拟地址能够正确地映射到对应的物理地址？

![x86-seg-page](images/x86-seg-page.png)

在 x86 里面既包含了段机制，也包含了叶机制，虽然我们弱化了段机制的映射关系，但通过段机制和页机制的组合可以形成更灵活的组织方式。当然在现代操作系统中主要还是使用页机制来完成了整个的映射，段机制的作用更多的体现在安全管理层面上。其实即使在安全管理上，段机制和页机制也有一定的重复

## 非连续内存分配

在连续存储分配中，要给一个进程分配内存，必须分配一段连续的物理地址空间。那是否可以不连续的进行内存分配呢？不连续内存分配的基本块大小应该如何选择呢？基于基本块大小的不同，有三种方式：

- 段式
- 页式
- 段页式

**连续分配的缺点**：

- 分配给程序的物理内存必须连续
- 存在外碎片和内碎片
- 内存分配的动态修改困难
- 内存利用率较低

**非连续分配的设计目标**：提高内存利用效率和管理灵活性

- 允许一个程序使用非连续的物理地址空间
- 允许共享代码与数据，减少内存的使用量，例如两个应用进程使用同一个函数库
- 支持动态加载和动态链接

**非连续分配需要解决的问题**：

- 如何实现虚拟地址和物理地址的转换？
- 软件实现（灵活，开销大）
- 硬件实现（够用，开销小）

**连续分配的硬件辅助机制**：

- 如何选择非连续分配中的内存分块大小？
- 段式存储管理（segmentation）：以一个段作为一个基本单位，在分配的时候一个段的内容在物理内存中是连续的，不同段之间是可以放到不同地方的
- 页式存储管理（paging）：以页为单位进行分配（页——大小相比于段更小的内存块），页与页之间可以不连续

### 段式存储管理

**段地址空间**：

将进程的地址空间看成由若干个段组成的，例如代码段、数据段、堆栈等等，每个段物理地址空间是连续的，使用段基址+偏移进行访问，各个段之间很少有跨越（以一个段的基址去访问另一个段），各个段之间可以不连续

![segment](images/segment.png)

段表示属性相同（包括访问方式、存储数据等）的一段地址空间，对应到一块连续的内存“块”，若干个段组成了进程逻辑地址空间

逻辑地址由两元组表示 (段号 s, 段内偏移 o)

**段访问的硬件实现**：

![segment-offset](images/segment-offset.png)

### 页式存储管理

- **页帧（帧、物理页面，Frame，Page Frame）**

把物理地址空间划分为大小相同的基本分配单元，大小为 2 的 n 次方（如 512，4K 4096 常见页帧的大小，8192）。帧的物理内存地址表示为二元组 (f, o)，f 表示帧号（F 位，表示共有 `$2^F$` 个帧），o 表示帧内偏移（S 位，表示每帧有 `$2^S$` 字节），则当前帧所在的物理地址为 `$f * 2^S + o$`

![frame-offset](images/frame-offset.png)

- **页面（页、逻辑页面，Page）**

把逻辑地址空间也划分为相同大小的基本分配单位。帧和页的大小必须是相同的，页内偏移 = 帧内偏移，通常 页号 ≠ 帧号（逻辑地址空间是连续的，对应的页号也是连续的，而帧号就不一定是相邻的了）。进程的逻辑地址表示为二元组 (p, o)，p 表示页号（P 位，表示共有 `$2^P$` 个页），o 表示页内偏移（S 位，表示每页有 `$2^S$` 字节），则当前页所在的虚拟地址为 `$p * 2^S + o$`

![page-offset](images/page-offset.png)

- **页到帧的映射**（逻辑地址中的页号是连续的，物理地址中的帧号是不连续的，不是所有的页都有对应的帧）
  - 逻辑地址到物理地址的转换
  - 页表：保存逻辑地址到物理地址的映射关系
  - 存储管理单元 MMU/快表 TLB：让转化更为高效的进行

![va-pa](images/va-pa.png)

### 页表

页表负责从逻辑页号到物理帧号之间的转换，那这个转换是如何进行的呢？

*页表项：*

每个进程都有一个页表，进程的每一个逻辑页面在页表中都对应一条页表项，这个页表项完成这个逻辑页号到物理帧号之间的转换。需要注意的是，页表里面的内容会随着程序的运行而动态变化，正是这种变化使得我们有可能动态地去调整分配给一个进程的内存空间的大小，在程序运行的过程当中，来给其分配新的物理帧放到进程的地址空间里去。页表的起始地址存放在页表基址寄存器（Page Table Base Register，PTBR）中

![page-table](images/page-table.png)

页表项中包含的内容：

1. 物理帧号 f
2. 页表项标志位（常用）
    - 存在位（resident bit）：一个逻辑页号是否有一个物理帧号有它对应
    - 修改位（dirty bit）：对应页面的内容是否发生了修改
    - 引用位（clock/reference bit）：对应页面在过去的一段时间里是否存在对它的引用，即是否访问过该页面里的某一存储单元

**页式存储管理机制的性能问题**：

1. 内存访问的性能问题
    - 访问一个内存单元需要 2 次内存访问，第一次访问页表项，第二次访问数据，这样读写性能就回大幅度下降
2. 页表大小的问题：页表可能非常大
    - 缓存（Caching）——程序的局部性，将页表项缓存起来，在接下来的执行中，极大的可能性会使用到该页表项，就能够直接得到物理帧号，进而减少第一次访问页表的过程
    - 间接（Indirection）访问——多级页表，先找在哪个子表中，再从找到的子表中接着找期待的目标项

**快表（Translation Look-aside Buffer，TLB）**：

将近期访问过的页表项缓存在 CPU 里，利用缓存的机制减少对内存的访问。TLB 使用关联存储器（associative memory，根据 key 并行地同时查找所有的表项，在 CPU 里面，因此速度快，对应的成本高、功耗大）实现，具备快速访问性能。如果在 TLB 中命中，物理帧号可以很快被获取，就不需要访问内存中的页表查找对应逻辑页号的物理帧号了（只需要一次内存访问）；如果 TLB 未命中，还是需要到内存中的页表进行查找页表项，并将对应的页表项更新到 TLB 中（需要两次内存访问）

![TLB](images/TLB.png)

**多级页表**：【待学习，为什么能够减少页表的存储空间】

通过间接引用将页号分成若 K 级（三级页表，则逻辑地址由四元组构成，P1、P2、P3、o），需要建立页表“树”，来减少每一级页表的长度，对应的访问内存的次数为 K+1

![multi-layered-pt](images/multi-layered-pt.png)

**反置页表**：【没有明白】

多机页表访问内存的次数较多，对于大地址空间（64 bit）系统，多级页表变得繁琐。多级页表将逻辑地址空间与页表进行了对应

为了减少页表占用存储空间

页寄存器和反置页表的思路：不让页表与逻辑地址空间的大小相对应，让页表与物理地址空间的大小相对应。这样虚拟地址的增加和进程数目的增多都对页表占用的空间大小没有影响

页寄存器（Page Registers）

每个物理帧与一个页寄存器（Page Register）关联，寄存器内容包括：

- 使用位（Resident bit）：此帧是否被进程占用
- 占用页号（Occupier）：对应的逻辑页号 p，就能够直到这个物理帧分配给了哪一个进程
- 保护位（Protection bits）：该帧访问方式，可读/可写

优点：页表大小相对于物理内存而言很小，页表大小与逻辑地址空间大小无关

缺点：页表信息对调后，需要依据物理帧号找逻辑页号，在页寄存器中搜索逻辑地址中的页号

页寄存器的地址转换

CPU 生成的逻辑地址，在页寄存器机制下对应的物理地址是多少呢？对逻辑地址进行 Hash，减少搜索范围，但需要解决可能的冲突。并且可以使用快表缓存页表项后的搜索步骤：1）对逻辑地址进行 Hash，2）在快表中查找对应页表项，3）有冲突时遍历冲突项链表，4）查找失败时产生异常

反置页表和页寄存器的区别是其将进程 ID 考虑进来了。使用逻辑页号和进程 ID 一起进行 Hash 映射查找对应的页表项中的物理帧号，Hash 值可能有冲突。以 Hash 值进行排序，需要去核对页表项中的 PID 和逻辑页号是否相同，若一致就得到了相应的物理页号了

![reversed-pg](images/reversed-pg.png)

### 段页式存储管理

段式存储在内存保护方面有优势，页式存储在内存利用和优化转移到后备存储有优势。段式和页式能否结合呢？

在段式存储管理的基础上，给每个段加一级页表，逻辑地址表示为三元组 (段号，页号，页内偏移)

![segment-page-offset](images/segment-page-offset.png)

- 1) 根据进程的段基址，找到相应的段表基址，由段号 s 找到相应的段表项。段表项中有相应段的段长度和段基址
- 2) 相应段的页表基址+逻辑页号 p 就可以得到相应的页表项。页表项中有对应物理帧的帧号
- 3) 帧号+页内偏移 o，就能够访问到实际的物理存储单元了

**段页式存储管理中的内存共享**：

通过指向相同的页表基址，实现进程间的段共享

![shared-segment](images/shared-segment.png)

综述，上面讲解了非连续内存分配的几种做法，段式、页式和段页式。它们共同点是分配给一个进程的内存区域可以是不连续的，区别在于分配的基本块的大小（段式分配的块很大，页式分配的块很小，段页式将二者结合起来）。在非连续内存分配中，会出现段表和页表

## 版权声明

本作品采用[知识共享署名 4.0 国际许可协议](http://creativecommons.org/licenses/by/4.0/)进行许可，转载时请注明原文链接。
