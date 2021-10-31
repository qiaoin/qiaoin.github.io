---
title: 柔性数组
author: qiaoin
date: '2018-10-24'
slug: soft-array
categories:
  - 编程语言
tags:
  - C
---

印象中 `int size[0]` 这种在 C/C++ 是不允许的，但是在结构中确实可以使用的(C99 标准)。经过查看资料，知道这种可变数组被称为柔性数组。

---

{{< toc >}}

---

## 从头开始说起

在日常的编程中，有时候需要在结构体中存放一个长度动态的字符串，一般的做法，是在结构体中定义一个指针成员，这个指针成员指向该字符串所在的动态内存空间，例如：

```c
typedef struct test {  
    int a;  
    double b;  
    char *p;  
};
```

`p` 指向字符串。这种方法造成字符串与结构体是分离的，不利于操作。如果把字符串跟结构体直接连在一起，不是更好吗？于是，可以把代码修改为这样：

```c
char a[] = "hello world";
test *stpTest = (test *)malloc(sizeof(test) + strlen(a) + 1);
strcpy(stpTest + 1, a);
```

这样一来，`(char*)(stpTest + 1)` 就是字符串"hello world"的地址了。这时候 `p` 成了多余的东西，可以去掉。但是，又产生了另外一个问题：老是使用 `(char* )((stpTest + 1)` 不方便。如果能够找出一种方法，既能直接引用该字符串，又不占用结构体的空间，就完美了。符合这种条件的代码结构应该是一个非对象的符号地址，在结构体的尾部放置一个0长度的数组是一个绝妙的解决方案。不过，C/C++ 标准规定不能定义长度为 0 的数组，因此，有些编译器就把 0 长度的数组成员作为自己的非标准扩展。

在讲述柔性数组成员之前，首先要介绍一下不完整类型(incomplete type)。不完整类型是这样一种类型，它缺乏足够的信息例如长度去描述一个完整的对象，它的出现反映了 C 程序员对精炼代码的极致追求，这种代码结构产生于对动态结构体的需求。

鉴于这种代码结构所产生的重要作用，C99 甚至把它收入了标准中。C99 使用不完整类型实现柔性数组成员，在 C99 中，结构中的最后一个元素允许是未知大小的数组，这就叫做柔性数组(flexible array)成员(也叫伸缩性数组成员)。

- 结构中的柔性数组成员前面必须至少一个其他成员。
- 柔性数组成员允许结构中包含一个大小可变的数组。
- 柔性数组成员只作为一个符号地址存在，而且必须是结构体的最后一个成员，`sizeof` 返回的这种结构大小不包括柔性数组的内存。
- 柔性数组成员不仅可以用于字符数组，还可以是元素为其它类型的数组。
- 包含柔性数组成员的结构用 `malloc` 函数进行内存的动态分配，并且分配的内存应该大于结构的大小，以适应柔性数组的预期大小。

> - Flexible array members are written as contents[] without the 0.
> - Flexible array members have incomplete type, and so the sizeof operator may not be applied. As a quirk of the original implementation of zero-length arrays, sizeof evaluates to zero.
> - Flexible array members may only appear as the last member of a struct that is otherwise non-empty.
> - A structure containing a flexible array member, or a union containing such a structure (possibly recursively), may not be a member of a structure or an element of an array. (However, these uses are permitted by GCC as extensions.)

柔性数组的使用请看下面的例子：

```c
typedef struct test {
    int a;
    double b;
    char c[0];
};
```

有些编译器会报错无法编译可以改成：

```c
typedef struct test {
    int a;
    double b;
    char c[];
};
```

> 在一个结构体的最后，申明一个长度为0的数组，就可以使得这个结构体是可变长的。对于编译器来说，此时长度为0的数组并不占用空间，因为数组名本身不占空间，它只是一个偏移量，数组名这个符号本身代 表了一个不可修改的地址常量（注意：数组名永远都不会是指针！），但对于这个数组的大小，我们可以进行动态分配
> 请仔细理解后半部分，对于编译器而言，数组名仅仅是一个符号，它不会占用任何空间，它在结构体中，只是代表了一个偏移量，代表一个不可修改的地址常量！

通过如下表达式给结构体分配内存：

```c
test *stpTest = (test *)malloc(sizeof(test) + 100*sizeof(char));
```

`c` 就是一个柔性数组成员，如果把 `stpTest` 指向的动态分配内存看作一个整体，`c` 就是一个长度可以动态变化的结构体成员，柔性一词来源于此。`c` 的长度为 0，因此它不占用 `test` 的空间，同时 `stpTest->c` 就是“hello world”的首地址，不需要再使用 `(char *)(stpTest + 1)` 这么丑陋的代码了。那个 0 个元素的数组没有占用空间，而后我们可以进行变长操作了。这样我们为结构体指针 `c` 分配了一块内存。用 `stpTest->c[n]` 就能简单地访问可变长元素。

当然，上面既然用 `malloc` 函数分配了内存，肯定就需要用 `free` 函数来释放内存：

```c
free(stpTest);
```

应当尽量使用标准形式，在非 C99 的场合，可以使用指针方法。需要说明的是：C89 不支持这种东西，C99 把它作为一种特例加入了标准。但是，C99 所支持的是 incomplete type，而不是 zero array，形同 `int a[0];` 这种形式是非法的，C99 支持的形式是形同 `int a[];` 只不过有些编译器把 `int a[0];` 作为非标准扩展来支持，而且在 C99 发布之前已经有了这种非标准扩展了，C99 发布之后，有些编译器把两者合而为一了。

## 用法说明

C99 的标准形式如下：

```c
struct sample {
    int a;
    double b;
    char c[]; /* char c[0]*/
};
```

在结构体的最后，可以加入一个长度为 0 的数组 `c`，这个数组 `c` 就是所谓的柔性数组。`c` 只是一个偏移，通过动态申请 `c` 的大小可以达到动态结构的效果。

## 例子

```c++
#include<cstring>
#include<iostream>
using namespace std;

#define uint32 unsigned int


typedef struct _normal_array_t
{
    char a;
    uint32 b;
    int *c;
}__attribute ((packed)) normal_array_t;

typedef struct _dynamic_array_t
{
    char a;
    uint32 b;
    int c[]; 
}__attribute ((packed)) dynamic_array_t;

int main()
{
    normal_array_t* n1 = (normal_array_t*)malloc(sizeof(normal_array_t) );
    cout << "n1: before malloc size is " << sizeof(*n1) << endl;
    n1->c = (int*) malloc(100 * sizeof(int));
    n1->c[50] =  100;
    cout << "n1: after malloc c, n1->c[50] is " << n1->c[50] << endl;
    cout << "n1: after malloc c, size is " << sizeof(*n1) << endl;
    free(n1->c);
    free(n1);

    dynamic_array_t* d1 = (dynamic_array_t*)malloc(sizeof(dynamic_array_t) + 100 * sizeof(int) );
    cout << "d1: size is " << sizeof(*d1) << endl;
    d1->c[50] = 200;
    cout << "d1: d1->c[50] is " << d1->c[50] << endl;
    free(d1);
}
```

结果运行如下：

```shell
n1: before malloc size is 13
n1: after malloc c, n1->c[50] is 100
n1: after malloc c, size is 13
d1: size is 5
d1: d1->c[50] is 200
```

如上图，我们如果想在 `struct` 里面声明一个动态的数组，可以有 2 种方式(里面的 `__attribute ((packed))` 是禁止编译器做字节对齐，效果明显)。

第一种如下所示，这种方法可以先申请 `normal_array_t` 自身，然后在申请 `normal_array_t->c`，然后通过 `normal_array_t->c[index]` 来访问动态数组，使用之后，需要先 `free(normal_array_t->c)`，然后再 `free(normal_array_t)`;

机器是 64 位，所以指针为 8 个字节，进而 `normal_array_t` 大小为 13。

```c
typedef struct _normal_array_t
{
    char a;
    uint32 b;
    int *c;
}__attribute ((packed)) normal_array_t;
```

第二种方法如下所示，这种方法一次性申请 `normal_array_t` 加上需要动态数组的大小来申请一整块内存，然后通过 `dynamic_array_t->c[index]` 来访问动态数组，使用之后，直接 `free(dynamic_array_t)` 就可以释放整个内存。

可以看到 `dynamic_array_t->c` 仅仅是一个符号，`dynamic_array_t` 的大小为 5（char 1, uint32 4）。

```c
typedef struct _normal_array_t
{
    char a;
    uint32 b;
    int *c;
}__attribute ((packed)) normal_array_t;
```

## 小结

可以看到使用柔性数组可以大大简化内容的管理，只需要一次申请，然后通过数组的指针偏移就可以直接获得相应的数据缓冲区，非常简单，释放的时候也仅仅只需要一次释放。

## 版权声明

本作品采用[知识共享署名 4.0 国际许可协议](http://creativecommons.org/licenses/by/4.0/)进行许可，转载时请注明原文链接。

## References

- [关于柔性数组](https://my.oschina.net/jungleliu0923/blog/192956)
- [深入浅出C语言中的柔性数组](https://blog.csdn.net/ce123_zhouwei/article/details/8973073 )
- [C语言0长度数组(可变数组/柔性数组)详解](https://blog.csdn.net/gatieme/article/details/64131322) 详细解释了定长包、指针数据包、变长数据缓冲区
- [C/C++ 中的0长数组（柔性数组）](https://blog.csdn.net/yby4769250/article/details/7294696)
- [C语言柔性数组](https://www.cnblogs.com/wuyudong/p/c-flexible-array.html)
- [C语言结构体里的成员数组和指针](https://coolshell.cn/articles/11377.html)
