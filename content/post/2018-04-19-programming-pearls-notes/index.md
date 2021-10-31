---
title: 《编程珠玑》读书笔记
author: qiaoin
date: '2018-04-19'
slug: programming-pearls-notes
categories:
  - algorithm
  - reading-notes
tags:
  - 二分查找
---

---

{{< toc >}}

---

## 前言

在本书的**前言**部分，作者写到：

> 计算机编程有很多方面。Fred Brooks 在《人月神话》一书中为我们描绘了全景，他的文章强调了管理在大型软件项目中所起的关键作用。而 Steve McConnell 在《代码大全》一书中更具体地传授了良好的编程风格。这两本书所讨论的是好软件的关键因素和专业程序员应有的特征。遗憾的是，仅仅熟练地运用这些可靠的工程原理，不见得一定能够如期完成软件并顺利运行。
>
> 本书描述了计算机编程更具魅力的一面：在可靠的工程之外，在洞察力和创造力范围内结晶而出的**编程珠玑**。
>
> 本书每一章都独立成篇，各章之间却又有着逻辑分组。第1章至第5章构成本书的第一部分，这部分回顾了编程的基本原理：问题定义，算法，数据结构以及程序验证和测试。第二部分围绕效率这个主题展开。效率问题有时本身就很重要，又永远都是进入有趣编程问题的绝佳跳板。第三部分用这些技术来解决排序，搜索和字符串等重要问题。
>
> 阅读本书的一个提示：不要读得太快。要仔细阅读，一次读一章。要尝试解答书中提出的问题——有些问题需要集中精力思考一两个小时才会想清楚。然后，要努力解答每章末尾的习题：当读者写下答案时，从本书学到的大部分知识就会跃然纸上。如有可能，要先与朋友和同事讨论一下自己的思路，再去查阅本书末尾的提示和答案。每章末尾的“深入阅读”并不算是学术意义上的参考文献表，而只是我个人推荐的一些好书，我自己就收藏了这些书。

### Part I: PRELIMINARIES 准备工作

- 开篇

  This column is the history of a single problem. A combination of careful problem definition and straightforward programming techniques led to an elegant solution. The column illustrates the central theme of this book: thinking hard about a real case study can be fun and can also lead to practical benefits.

- 啊哈！算法

  This column examines three problems, with an emphasis on how algorithmic insights can yield simple and effective code.

- 数据决定程序结构

  This column surveys the crucial role that the structure of data can play in software design.

- 编写正确的程序

  This column introduces **program verification** as a tool for writing correct code. Verification techniques are used extensively as we derive subtle (and fast) functions in Columns 9, 11 and 14.

- 编程中的次要问题

  This column shows how we implement those abstract programs in real code: we use scaffolding to probe a function, to bombard it with test cases, and to measure its performance.

### Part II: PERFORMANCE

- 程序性能分析
- 粗略估算
- 算法设计技术
- 代码调优
- 节省空间

### Part III: THE PRODUCT

- 排序
- 取样问题
- 搜索
- 堆
- 字符串

## [Summary] Column1 cracking the osster

当被问及一个问题时，“如何给磁盘上的一个文件进行排序？”，我们总是会基于先前已掌握的知识，凭着自己的定式思维，给出最为直接的反应，

“实现一个给磁盘上文件进行排序的归并排序算法就可以了啊，在一本特别经典的算法编程书籍就有给出如何实现这样的归并排序算法，用大概两百行左右的代码实现了几个功能函数，你可以找来看看，你可能需要花费一个星期左右的时间来实现并调试通过吧。”

我们会像这样夸夸其谈，但真的是这样的么？我们真的理解了提问者所提出的问题么？或者，换句话来说，提问者有清晰地表述出他想要问的问题么？这就像在面试中，面试官会有意或无意的将问题描述的很模糊，考察你是否有注意到问题的症结所在，并就这一症结提出更为细节的问题。对于“如何给磁盘上的一个文件进行排序？”，仍有很多未明了的问题。下面是提问者和作者（A 和 B）的对话。

A: 该如何对磁盘上的文件进行排序呢？

B: 需要排序的内容是什么呢？待排序的文件中有多少条记录呢？另外，每条记录的格式是怎么样的？

A: 该文件包含至多 10,000,000 条记录，每条记录都是一个 7 位整数（十进制）。

B: 如果文件这么小，为什么要使用磁盘进行排序呢？为什么不直接在主存中对其进行排序呢？ **注：** “**文件这么小**”，最多 10M 条记录，每个记录保存为一个 32-bit 的整数即可，大概需要 40MB 的内存

A: 该功能是某一大型系统的一部分，只能够提供大概 1MB 主存给此功能使用。

B: 你能将每条记录描述的更为详细一些么？

A: 每条记录是一个 7 位的十进制正整数，没有其他相关联的数据，并且每个整数至多只能出现一次。

经过一系列的问题，我们可以为一个描述模糊不清的问题给出更加清晰严谨的问题定义：

> 输入：所输入的是一个文件，至多包含 n 个正整数，每个正整数都小于 n（ n = 10^7）。如果输入文件中，某一个整数出现了两次，就会产生一个致命错误。这些整数没有其他相关联的数据。
>
> 输出：以递增的顺序输出经排序后的整数列表，保存在一磁盘文件中。
>
> 约束条件：大概仅有 1MB 的可用主存，但磁盘空间充足。运行时间不能超过几分钟。

考虑一般的解法，依照能够使用的主存大小（1MB），多次（40 次）读入待排序文件，每次处理待排序文件的不同部分，使用快速排序算法进行排序，但读取磁盘上文件是非常耗时的一项操作。考虑到实际 n 的大小限制和每个整数最多只能够出现一次的限制，而所谓的排序也只是把文件中的整数按照其在 [0, n) 内出现的顺序进行输出而已，因此只要对 [0, n) 之内出现的整数做一下标记，最后按所需要的顺序输出标记过的整数就可以了。鉴于此，位向量（或称位图，bit vector or bitmap）就是比较合适的数据结构了，每个位上的0/1值就表示这个数字是否在待排序文件中出现过，实现的时间复杂度是 O(n)，空间复杂度是 O(n)，n 的最大取值为 10^7，所需要的内存空间为 10^7 / 8 / 2^10 / 2^10 = 1.25MB 左右。这里我们之所以能够使用位图这样的数据结构来进行数据表示，是基于这个问题的特殊性，1.输入数据来自于一个相对较小的范围；2.没有重复数据，数据最多出现一次；3.每条记录都没有附加数据，而这些特殊性在一般的排序中是很难满足的。基于位图数据结构的表示方法，磁盘文件的排序可以用三步来实现：

- phase 1: 初始化所有的位为 0；
- phase 2: 读取文件中的每个整数，将相对应的位置 1；如果该整数对应的位已经为 1，说明前面已经出现过这个整数，抛出异常，退出程序；
- phase 3: 检查每个位，如果某个位是 1，输出对应的整数，从而创建已排序的输出文件。

在解决这个实际问题的方案中，我们看到了不同于比较排序的一种排序方式：使用位图进行排序，从这个问题出发，引出了作者的一些思考和对我们读者的一些启示：

- **The right problem**。如何提问，如何清晰的进行问题描述，有点类似与软件工程中的需求分析，其重要性不容质疑，我们只有在清楚要解决的是什么问题，厘清该问题的各个细节之后，才能够找到问题的解法和优化解。
- **位图数据结构**。使用位图进行表示是基于一些约束的，集合是稠密的（相比于稀疏），所有的数据分布在一个有限的范围内，集合中的每一个元素都是唯一的，并且没有相关联的额外的数据。Even if these conditions aren't satisfied (when there are multiple elements or extra data, for instance), a key from a finite domain can be used as an index into a table with more complicated entries. 这句话怎么理解？
- **时间和空间是可以双赢的**。确实，在很多时候我们会在时间和空间之间做出折中（tradeoffs）的选择，但是有些时候，当我们减少一个程序所使用的空间时，执行此程序所需要的时间也会跟着就减少了，从而达到空间和时间上的双赢。像给磁盘文件进行排序这个问题，当我们使用位图来进行表示，使用的空间急剧缩减 O(n)，同时执行时间也为 O(n)。使用位图进行表示，更少的数据，对应的操作也会减少，由于占用空间少，就能将数据整个的载入到主存中，减少了对磁盘进行访问的耗费。
- **简单的设计**。“设计者确定其设计已经达到完美的标准，不是不能再增加任何东西，而是不能再减少任何东西”，在满足要求的前提下尽量让设计简洁，这样会更 reliable, secure, robust and efficient，并且有利于代码的创建和维护。“大道至简”，设计需要的也许更多的是简洁性。

未明白的问题：

> A Merge Sort program reads the file once from the input, sorts it with the aid of work files that are read and written many times, and then writes it once.

这一段的描述应该如何理解，另外这里提及的 **a general disk-based Merge Sort** 算法怎么实现？

Problems: **TODO**

1. 当内存空间充足时，如何实现一个排序算法为磁盘文件进行排序？
2. 如何基于位的逻辑操作实现位向量？
4. 如何生成 k 个小于 n 的不重复整数？
5. 题设要求的约束是“大概 1MB 左右的空闲主存空间”，但是我们基于位图的实现所需要的内存空间是 1.25MB，相差 0.25MB 的内存空间，看来还是可以接受的；但如果内存空间是一个紧缺的资源（在实现的这整个系统中），当能够提供的空闲主存空间不能够满足我们的需求时，我们应该怎么来实现呢？
6. 当每一个整数可以出现最多十次的时候，这个问题又该如何解决呢？
7. 输入假设的是每一个整数最多仅会出现一次，当出现多于一次时，会出现什么情况呢？应该做怎样的修改已实现报错呢？当输入的整数小于 0 或者大于等于 n 时，应该执行怎样的操作？当输入非整数呢？
8.

## [Summary] Column4 writing correct programs

在看4.2节前，就试着如书上所说——

> putting down this column right now and writing the code yourself. Try it!

### Implementing Binary Search with C

```c
/*
* 数组a按升序排列，即: a[0] <= a[1] <= ... <= a[n-1]
*/
int binarySearch(int a[], int left, int right, int target) {
    int mid = 0;
    while (left <= right) {
        mid = (left + right) / 2;
        if (target == a[mid]) {
            return mid;
        } else if (target < a[mid]) {
            right = mid - 1;
        } else {
            left = mid + 1;
        }
    }
    return -1;
}
```

这里仅仅是能够处理 `int` 数组的情况，离编程珠玑的要求 “the pseudocode should work equally well for integers, floats or strings” 还有很远，只是能够将自己的思路表达出来即可。其实，找着看这一节，也是在之前的[博客](http://zh.lucida.me/blog/on-learning-algorithms/#The-Science-of-Programming)上看到的，怎么评价能够这么高，都已经到达了程序正确性证明的地步了，遂决定有必要翻翻，提升技能。

## 版权声明

本作品采用[知识共享署名 4.0 国际许可协议](http://creativecommons.org/licenses/by/4.0/)进行许可，转载时请注明原文链接。
