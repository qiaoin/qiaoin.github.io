---
title: 《程序设计实践》读书笔记
author: qiaoin
date: '2019-04-02'
slug: practice-of-programming-notes
categories:
  - reading-notes
  - algorithm
tags:
  - Refactor
---

很早以前就知道有这本书了，一直没有机会找来看，当然这只能说明自己比较懒，现在终于有了空闲和心情，遂找来看看，`The Practice of Programming`，中文译名为《程序设计实践》，在这里，记录下自己看这本书，以及一些心得体会。

> This book is about the practice of programming -- how to write programs for real.

---

{{< toc >}}

---

## 第一章：程序设计风格

在第一章的开始，作者就指出：

> There is more to writing a program than getting the syntax right, fixing the bugs, and making it run fast enough.

程序不仅是写给计算机读的，同时也是给人读的。一个“**well-written**”的程序相较于一个“**poorly-written**”的，更容易被理解和修改维护。

程序设计的原则就是简单清晰：

> The principles of programming style are based on common sense guided by experience, not on arbitrary rules and prescriptions. Code **should** be clear and simple -- straightforward logic, natural expression, conventional language use, meaningful names, neat formatting, helpful comments -- and it should avoid clever tricks and unusual constructions. Consistency is important because others will find it easier to read your code, and you theirs, if you all stick to the same style.

- `straightforward logic` -- 如何将自己的思想用代码有条理地表述出来，这是我们的第一步要求，这里有一个特别重要的是，一定不要在早期就陷入细节之中，不要在刚开始着手时就想着能够写出很好很优秀的代码，因为后期我们需要重新来进行修改；就如同写文字一样，初稿只要能够清晰地将自己的思想给表述出来，让我们自己能够明白接下来准备做的是什么，如何做，我们可以使用一个抽象的思想，并不是要马上就能写出一个实际可以运行的程序，而是应该能够说清楚一件事。

- `natural expression，conventional language use` -- 常用的表达式和常见用法，不使用花里胡哨的技巧，这样只是使得代码不好阅读和理解，当然这个也有“例外”，在*The C Programming Language*这本口碑很好的书里面随处可见`i++`的使用，这反而增强了程序的表达能力，减少了代码行数。(这本书，我只是粗略的翻过一些，没有很系统的学习C语言，一定得找个机会看看，之后再做评价。)

- `meaningful names` -- 有一个好的名字很重要，这需要有很强的功力，[这篇微信推送](http://mp.weixin.qq.com/s?__biz=MzA3NDM0ODQwMw==&mid=2649827483&idx=1&sn=228be8c6c3448a56f7ecd00e20e3ae1d&chksm=8704aa87b0732391ceca19893103f58f7aa360c815faec08a334daddbff74a62b4db724125b7&mpshare=1&scene=1&srcid=1013FED3GLSb5JApWgUpkeC2#rd)给出来很好的解释。

- `neat formatting` -- 格式要清晰，不能让自己在编写完之后都不想第二次打开，自己要有一个特有的风格，但在团队合作时，要有一致的规范。

- `helpful comments` -- 注释不仅是给自己看的，更是方便别人来阅读你的代码，所以要遵循一定的社区规范，要写一些有意义的注释。

### 命名 Names

"What's in a name?" 一个变量的名称标识着一个对象，一个函数的名称是对其所能执行操作的一个表示，因此，命名应该富含信息、表述清晰、容易记忆，可能的话，应该能够发出音来。

1. 全局变量采用描述性的名字，局部变量采用短名字（ **Use descriptive names for globals, short names for locals** ）

   全局变量可能出现在程序的任何地方，因而它应是足够长并且有一定的描述性以让读代码的人能够清楚地知道它的意思。推荐在声明每一个全局变量时，添加上简短的注释。

   局部变量应该使用简短的命名，我们习惯使用`i`和`j`表示循环的次数，使用`p`和`q`表示指针，使用`s`和`t`表示字符串。

   **naming conventions and local customs**

   - using names that begin or end with `p` for *pointers*;
   - initial **captital** letters for *Globals*;
   - **all** captital for *CONSTANTS*.

   > Programmers are often encouraged to use long variable names regardless of context. That is a mistake: **clarity(清晰) is often achieved through brevity(简洁)**.

2. 保持一致性（ **Be consistent** ）

   > Give related things related names that show their relationship and highlight their difference.

   ```java
   class UserQueue {
       int noOfItemsInQ, frontOfTheQueue, queueCapacity;
       public int noOfUsersInQueue() {...}
   }
   ```

   上面这段简单的代码，对`queue`进行了三种不同的表述——`Q`、`Queue`、`queue`，这个是没必要的。另一个问题是，这个`UserQueue`类中的属性和方法仅可以被这个类的实例所访问，因此这些属性和方法的命名中可以省略`queue`的表示。更加清晰简单的表示如下：

   ```java
   class UserQueue {
       int nitems, front, capacity;
       public int nusers() {...}
   }
   ```

   由于`users`和`items`是表示同样的事物，因此可以仅使用一种表示。

3. 函数名采用动作性的名字（ **Use active names for functions** ）

   这个就很容易理解了，我们在写Java类的时候，一个`private`的属性值`X`，如何进行访问呢，一般的做法就是`setX(someValue)`和`getX()`。还有，在`SICP`中可以看到的，当我们需要使用一个谓词时，一般使用于条件判断处，`Scheme`的做法是在动词后面加上问号，例如：`improved?`/`good-enough?`，相应地在C语言中，判断一个`char`是否为数字时，使用`isDigit()`，就是“动词+名词”形式，这样我们可以很清楚地知道当`char`为数字时返回`true`，否则为`false`。

4. 保持准确（ **Be accurate** ）

### 表达式和语句 Expressions and Statements

1. 缩进显示（**Indent to show structure**）

   缩进显示能够让代码更容易阅读，当然，对于`Python`，缩进就是它的全部了。

2. 采用表达式的正常写法（**Use the natural form for expressions**）

   例如，条件表达式包含“取非”操作是难让人理解的。

   ```java
   if (!(block_id < actblks) || !(block_id >= unblocks)) {...}
   ```

   更加符合我们阅读习惯的是，

   ```java
   if ((block_id >= actblks) || (block_id < unblocks)) {...}
   ```

3. 采用括号排除二义性（**Parenthesize to resolve ambiguity**）

   > Parenthesizes specify grouping and can be used to make the intent clear even when they are not required.

4. 拆分复杂的表达式（**Break up complex expressions**）

5. 要清晰明了（**Be clear**）

   这段代码的作用是什么？

   ```c
   subkey = subkey >> (bitoff - ((bitoff >> 3) << 3));
   ```

   取`bitoff`二进制表示的最低三位，可以重写为：

   ```java
   subkey >>= bitoff & 0x7;
   ```

6. 当心副作用（**Be careful with side effects**）

   > Operators like ++ have ***side effects***: besides returning a value, they also modify an underlying variable. Side effects can be extremely convenient, but they can also cause trouble because the actions of retrieving the value and updating the variable might not happen at the same time. **In C and C++, the order of execution of side effects is undefined**, so this multiple assignment is likely to produce the wrong answer.

   当在一个表达式中要同时要访问某一个变量和给这个变量进行赋值时，就会出现这样的问题：

   ```c
   array[i++] = i;
   ```

   `i`的初始值为3，这个数组的索引为3的位置的值可能会被设置为3或者4。

   实际写代码编译的情况是：

   ```c
   #include <stdio.h>
   
   int main() {
       int array[10];
       int i;
       for (i = 0; i < 10; i++) {
           array[i] = 0;
       }
       for (i = 0; i < 10; ) {
           array[i++] = i;
       }
       for (i = 0; i < 10; i++) {
           printf("%d\t", array[i]);
       }
   
       return 0;
   }
   ```

   我的配置是：

   > 系统：OS X EI Capitan，版本 10.11.6
   >
   > gcc --version: Apple LLVM version 7.3.0 (clang-703.0.31)

   使用`gcc hello.c -o hello`编译的结果是给了一个`warning: unsequenced modification and access to 'i'`，运行结果如下：`0    1    2   3   4   5   6   7   8   9`，运行结果正确。因此推断`array[i++] = i;`的处理是`array[i] = i; i++;`。

   > It's not just increments and decrements that have side effects; I/O is another source of behind-the-scenes action.

   ```c
   scanf("%d %d", &yr, &profit[yr]);
   ```

   以上代码段，前一部分是接受标准输入给`yr`赋值，后一部分是使用这个得到的值访问数组，给数组的某个元素赋值。“*all the arguments to scanf are evaluated before the routine is called, so `&profit[yr]` will always be evaluated using the old value of yr.*”因此我们将这个语句拆分开：

   ```c
   scanf("%d", &yr);
   scanf("%d", &profit[yr]);
   ```

### 一致性和惯用写法 **Consistency and Idioms**

## 版权声明

本作品采用[知识共享署名 4.0 国际许可协议](http://creativecommons.org/licenses/by/4.0/)进行许可，转载时请注明原文链接。
