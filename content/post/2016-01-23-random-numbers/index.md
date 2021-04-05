---
title: "随机数——僭越之罪"
author: "qiaoin"
date: '2016-01-23'
slug: random-numbers
categories: algorithm
tags: 随机数
---

相较于用物理方法生成随机数，冯・诺依曼承认：“当然，任何考虑用算术方法生成随机数的人都犯了僭越之罪。因为，正如已经被多次指出的，不存在一个随机数这样的东西——有的只是生成随机数的方法，而一种严格的算术方法显然不属于其中之一。”

一直都想看看计算机是如何生成随机数这种东西的，Java 中的 `random()` 方法的工作原理又是什么，前几天又看了一遍《信息简史》上第十二章对随机性的描述，遂先挖个坑，一定填好。

其实大家应该也注意到了，我们在手机上播放音乐歌单（假如此歌单有 32 首歌，歌曲名顺次索引为 0 到 31，将此顺序称为 A 序），将播放模式设置为随机，歌单是随机开始放了（假定播放顺序是 2，12，15，27，4，3，9，……，即首先播放歌单第 2 首，然后第 12 首，……，将此顺序称为 B 序），但一段时间过后就会进入循环（以 B 序进入循环播放）。A 序为顺序递增序列，非随机序列，或者说我们可以很容易的知道播放完第 15 首歌之后，下一首要播放的是第 16 首歌，这是可以预测的；B 序，称为随机序列，我们无法确定播放完此刻的这首歌之后，后一首将要播放的是哪一首歌，可以这样理解，A 序在音乐未开始播放的时候，这个序列我们就可以写出来，而 B 序，像上面的 2，12，15，27，4，3，9，……，我们只能是在音乐已经播放到这首歌时候，我们才能写下在其前面已经播放过的歌曲从而得到 B 序。更严格意义上的说，在音乐播放器中随机所产生的 B 序应称为伪随机序列，正如上面所言，在经过一段时间之后音乐的播放会以 B 序开始循环播放。

在之前，玩炉石开卡包拼人品，总是开出一蓝四白，于是开始怀疑这玩的不是同一个游戏，终于弃坑，现在想想，暴雪这个随机数生成程序的实现也许随机性不是很好。当然，这只是猜想。

## 在Java中使用随机数

在Java中使用随机数只需调用：

```java
double m = Math.random();
```

`Math.random()` 方法返回一个 [0.0, 1.0) 的 `double` 值。 `java.lang.Math.random()` 的实现如下：

```java
public static double random() {
    return RandomNumberGeneratorHolder.randomNumberGenerator.nextDouble();
}

private static final class RandomNumberGeneratorHolder {
    static final Random randomNumberGenerator = new Random();
}
```

其中 `RandomNumberGeneratorHolder` 为 `java.lang.Math` 类中的一静态内部类（这里使用内部类的好处在下面说明）。`RandomNumberGeneratorHolder` 类包含一个静态属性，其引用指向 `java.util.Random` 类的一个实例，那么设置这个静态内部类，引用 JavaAPI 文档中 `java.lang.Math.random()` 方法的说明：

> When this method is *first* called, it creates a single new pseudorandom-number generator, exactly as if by the expression. This new pseudorandom-number generator is used thereafter for *all* calls to this method and is used nowhere else.

就是说，仅会在第一次调用 `java.lang.Math.random()` 方法的时候会创建一个新的伪随机数生成器的对象实例，此后的所有对 `random()` 方法的调用都会使用这个生成器，不会重新再 =new= 一个新的对象。

可以知道， `java.lang.Math.random()` 方法实际上使用了 `java.util.Random` 这个类所实现的 `nextDouble()` 方法。这就是 Java 中常用的随机数生成类了，如下：

```java
/* 1.创建Random对象，提供两个构造方法 */
Random random = new Random();      // 默认构造方法
//Random random = new Random(1000);  // 指定种子数字
/* 2.通过Random实例获取所需要的随机数，提供多种类型的随机数类型：boolean，byte，int，long，float，double */
// 得到一个int类型随机数，如下；
int n = random.nextInt();
// 得到一个[0, 1000)int类型的随机数，如下；
int m = random.nextInt(1000);
```

## TAOCP中线性同余法摘记

最近花时间过了一下 TAOCP 第二卷的随机数一章，数学证明太多，我仅是想知道随机数的产生，也可以算是目的已经达到了，下面将书上这一章关于线性同余法的介绍摘录如下（TAOCP 第二卷，半数值算法，第三版，国防工业出版社）。

### 3.2.1 线性同余法 P8

当今使用的最流行的随机数生成程序是 D.H.Lehmer 1949年介绍过的方案的特殊情况。我们选择 4 个魔术整数：

- m，模数，0 < m；
- a，乘数，0 <= a < m；
- c，增量，0 <= c < m；
- X(0)，开始值或种子，0 <= X(0) < m。

然后通过置

> X(n+1) = {aX(n) + c} mod m, n >= 0

而得到所求的随机数序列 {X(n)}。这个序列称做线性同余序列。对 m 求余有点像确定转动的轮盘上球的落点。

例如，当 m = 10 和 X(0) = a = c = 7 时，得到的序列是 {7, 6, 9, 0, 7, 6, 9, 0, ……} 如此例所示，对于 m，a，c 和 X(0) 的所有选择，这个序列并不总是“**随机**”的。

这个例子说明了同余序列总是进入一个循环的事实，亦即，它最终必定在 n 个数之间无休止地重复循环。这个性质对于具有一般形式 X(n+1) = f{X(n)} 的任何序列都是共同的，这里 f 把一个有限集合转换成它自身。这种重复的循环称为周期，上述例子有一个长度为 4 的周期。一个有用的序列当然应有相当长的周期。

c = 0 的特殊情况值得明确指出，因为 c = 0 时数的生成过程比 c != 0 时要稍微快些。我们后面看到，c = 0 的限制缩短了这个序列的周期长度，但是它仍有可能得到一个相当长的周期。Lehmer 原来的生成方法只有 c = 0 的情况，尽管他提出了 c != 0 的可能性。取 c != 0 来得到更长的周期的想法
是分别由 Thomson 和 Rotenberg 提出来的。许多作者用术语 **乘同余法** 和 **混合同余法** 来分别表示 c = 0 和 c != 0 的线性同余法。

### 3.2.1.2 乘数的选择 定理A P15

由 m，a，c 和 X(0) 所定义的线性同余序列有周期长度 m 当且仅当

1. c 与 m 互素；
2. 对于整除 m 的每个素数 p，a-1 是 p 的倍数；
3. 如果 m 是 4 的倍数，则 a-1 也是 4 的倍数。

### 3.6 小结 P163

在这一章中我们叙述了相当大量的课题：怎样生成随机数，怎样检验它们，怎样在应用中修正它们，以及怎样推导关于它们的理论等。也许在许多读者的心目中，主要的问题是：“什么是整个理论的结果？什么是在我的程序中可以使用的简单而良好的生成程序，以便有一个可靠的随机数的来源？”

这一章中的详细研究表明，下列过程给出了对于大多数计算机的机器语言来说是“最好”和“最简单”的随机数生成程序：

在程序的开头，把一个整型变量 X 置为某个值 X(0) 。变量 X 仅用于随机数生成的目的。每当程序要求一个新的随机数时，即置 X = (aX + c) mod m，并且使用 X 的新值作为随机值。应该适当地选择 X(0)，a，c 和 m，而且按下列原则明智地使用随机数：

1. “种子”数 X(0) 可以任意地选择。如果这个程序运行若干次，而且每次都希望有不同的随机数来源，则置 X(0) 为上次赋予运行中由 X 得到的最后值；或者（如果更方便的话）置 X(0) 为当前的日期和时间。如果这个程序以后可能要以同样的随机数重新运行（例如当调试时），而又不知道 X(0) 的值是什么，就应该打印出来看看。
2. 数 m 应是大的，比如说至少是 2^{30} 。取计算机字的大小可能是方便的，因为这会使 (aX + c) mod m 的计算十分高效。3.2.1.1 小节更详细地讨论了 m 的选择。(aX + c) mod m 的计算必须精确，不带舍去误差。
3. 如果 m 是 2 的一个乘方（即如果正使用一台二进制计算机），则可挑选 a 使得 a mod 8 = 5 。如果 m 是 10 的一个乘方（即如果正使用一台十进制计算机），则可选择 a 使得 a mod 200 = 21。a 的这一选择和以下给出的 c 的选择一起，保证了这个随机数生成程序在它开始重复以前，产生 X 的全部 m 个可能的不同值（见 3.2.1.2 小节）以及保证了高的“效能”（见 3.2.1.3 小节）。
4. 乘数 a 选择在 .01m 和 .99m 之间是可取的，而且它的二进表示或十进表示数字不应有一个简单的正规的模式。 通过选择某些像 a = 3141592621 这样的任意常数（它同时满足（3）中的两个条件），几乎总能得到相当好的乘数。如果要广泛使用这个随机数生成程序，当然应该做进一步的检验；例如，当使用欧几里得算法来求 a 和 m 的 gcd （见 3.3.3 小节）时，不应有太大的商。在乘数被认为真正合格之前它应通过谱检验（3.3.4 小节）和3.3.2 小节的若干检验。
5. 当 a 是一个好的乘数时，除了当 m 是计算机的字的大小时不能和 m 有公因子外，c 的值是无所谓的。因此我们可以选择 c = 1 或 c = a。许多人已经把 c = 0 和 m = 2^e（e 表示任意的整指数）放在一起使用，但它们牺牲两位精度和一半的种子值，却只不过节省了几纳秒的运行时间。

## 从 Java 源代码看线性同余法

如上所述，Java 中两种生成随机数的方法，均是在使用 `java.util.Random` 这个类所提供的方法。为了方便描述，将上面使用随机数的代码（依次编号为0，1，2，3）拷贝在下面：

```java
/* 1.创建Random对象，提供两个构造方法 */
Random random = new Random();        // 默认构造方法     *********（0）
//Random random = new Random(1000);  // 指定种子数字     *********（1）
/* 2.通过Random实例获取所需要的随机数，提供多种类型的随机数类型：boolean，byte，int，long，float，double */
// 得到一个int类型随机数，如下；
int n = random.nextInt();            //                 *********（2）
// 得到一个[0, 1000)int类型的随机数，如下；
int m = random.nextInt(1000);        //                 *********（3）
```

好了，那现在我们就来看看 Java 是如何生成随机数的。

在 eclipse 中输入 `import java.util.Random;` 导入这个 `Random` 类，按住 `command` 将光标移至 `Random`，跳转查看其源代码实现（这句话其实多余，使用过 eclipse 都知道如何查看）。

这个类的开始描述如下：

> An instance of this class is used to generate a stream of *pseudorandom* numbers. The class uses a *48-bit* seed, which is modified using a *linear congruential formula*. (See Donald Knuth, /The Art of Computer Programming, Volume 2/ , Section 3.2.1.)

就是说，这个 `java.util.Random` 类的实例用以生成一系列伪随机数，其使用 48 位种子，修改自线性同余公式，具体参考可查看第二节 **TAOCP 中线性同余法摘记**。

以下为 `java.util.Random` 类两个构造方法和几个其他的辅助方法，以获得 48 位种子，即 X(0)。

```java
public Random() {
    this(seedUniquifier() ^ System.nanoTime());
}

private static long seedUniquifier() {
    // L'Ecuyer, "Tables of Linear Congruential Generators of
    // Different Sizes and Good Lattice Structure", 1999
    for (;;) {
        long current = seedUniquifier.get();
        long next = current * 181783497276652981L;
        if (seedUniquifier.compareAndSet(current, next))
            return next;
    }
}

private static final AtomicLong seedUniquifier = new AtomicLong(8682522807148012L);

public Random(long seed) {
    if (getClass() == Random.class)
        this.seed = new AtomicLong(initialScramble(seed));
    else {
        // subclass might have overriden setSeed
        this.seed = new AtomicLong();
        setSeed(seed);
    }
}

private static long initialScramble(long seed) {
    return (seed ^ multiplier) & mask;
}
```

首先看看这个无参数的构造方法，使用 `System.nanoTime()` 方法来得到一个纳米级的时间量，参与 48 位种子的构成， `seedUniquifier()` 方法将以初始值（8682522807148012L）不断乘以某一特定值（181783497276652981L），直至某一次相乘前后结果相同，以进一步增加随机性（但随机性该如何衡量呢？如信息简史里说到的使用其所包含的信息量，亦即描述计算出这个数的算法的长度；或者如 TAOCP 里说到的 X^2 检验、谱检验等等，这些还没有很多了解）。到这里，已经至少进行了三次随机了：

1. 使用一个长整数作为“初始种子值”，系统默认为 8682522807148012L；
2. 不断与某一特定值—— 181783497276652981L ——相乘，直至某一次相乘前后结果相同；
3. 所得到的值与 `System.nanoTime()` 方法返回的值进行异或运算，得到最终的种子，即 X(0)。

另外一个构造方法是直接提供了 X(0) 的值。

接下来，我们来看看（2）对应的 `nextInt()` 方法，实现如下：

```java
public int nextInt() {
    return next(32);
}
```

代码很简洁，直接调用 `next(int bits)` 方法， `next(int bits)` 方法实现如下：

```java
protected int next(int bits) {
    long oldseed, nextseed;
    AtomicLong seed = this.seed;
    do {
        oldseed = seed.get();
        nextseed = (oldseed * multiplier + addend) & mask;
    } while (!seed.compareAndSet(oldseed, nextseed));
    return (int)(nextseed >>> (48 - bits));
}

nextseed = (oldseed * multiplier + addend) & mask;
```

与 X(n+1) = {aX(n) + c} mod m, n >= 0 形式几乎类似。其实，这就是线性同余法，如文档所说只是稍微 *modified* 了一下。

不急，我们先来看看这几个参数的声明：

```java
private final AtomicLong seed;
private static final long multiplier = 0x5DEECE66DL;
private static final long addend = 0xBL;
private static final long mask = (1L << 48) - 1;
```

`seed` 就是初始种子，这个已经计算出来了（无参数或有参数的构造方法），对应公式中的 X(0)，`multiplier` 也就是乘数，对应公式中的 a，`addend` 对应公式中的 c，`mask` 是什么呢，怎么与 `mod` 对应上呢？其实 b  mod 2^{48} 与 `b & (1L << 48) - 1` 是等价的。这两个式子都是为了达到同一个目的（二进制表示）：

1. 将第 48 位及比 48 位高的各位数值置为 0；
2. 低 47 位保持原值不变。

**注**：mod 取余，a mod b，假设 a = n * b + c，则 a mod b = c；& 异或运算，a & 0 = a，a & 1 = 0。

（3）对应的 `nextInt(int bound)` 是一个更常用的方法，实现如下：

```java
public int nextInt(int bound) {
    if (bound <= 0)
        throw new IllegalArgumentException(BadBound);
    int r = next(31);
    int m = bound - 1;
    if ((bound & m) == 0)  // i.e., bound is a power of 2
        r = (int)((bound * (long)r) >> 31);
    else {
        for (int u = r;
             u - (r = u % bound) + m < 0;
             u = next(31))
             ;
    }
    return r;
}
```

该函数进行的工作是把 31 位的原始随机范围 `next(31)` 的结果 [0, 2^{31}) 映射到 [0, bound) 范围之内。但是，如果不经过特殊处理会出现概率不均匀。考虑下面这个例子，设已有一组均匀的随机整数，范围为 [0, 100)，现在想由这一组均匀随机数得到另一组范围为 [0, 25) 的随机数。由于 100 是 25 的倍数，可以很简单的将之前那组均匀随机数划分为 [0, 25)、[26, 50)、[51, 75)、[75, 100)，这四组随机数也是均匀的，或者将之前的每个随机数除以 4 得到一组新的随机数，仍旧是均匀的。但如果要得到一组范围为 [0, 30) 的随机数，就会出现问题了，因为 30 不能被 100 整除，所以余下的第四组是不均匀的：[0, 30)、[31, 60)、[61, 90)、[91, 100)，所以在实际产生的结果中，产生 [0, 10) 范围内的随机数的概率要比 [21, 30) 高出一些。JavaJDK 的做法就是，如果将 31 位随机结果映射到 [0, bound) 范围内时，若 `next(31)` 产生的数字是最后面不均匀的那一部分，就直接舍弃，重新生成随机数。所以以上代码中的 `for` 循环部分就是来处理这个问题的。

1. 当 `bound` 是 2 的整次幂（bound is a power of 2）时，很显然，`bound` 能够被 2^{31} 整除，就能够直接映射；
2. 当 `bound` 不是 2 的整次幂（else）时，就会出现上面例子中出现的不均匀问题，因此要进行特殊处理，以获得不为 0 的返回值。

是如何的特殊处理呢？其实就是以下这个 `for` 循环：

```java
for (int u = next(31); u - r + (bound - 1) < 0; u = next(31))
    r = u % bound;
```

## 版权声明

本作品采用[知识共享署名 4.0 国际许可协议](http://creativecommons.org/licenses/by/4.0/)进行许可，转载时请注明原文链接。
