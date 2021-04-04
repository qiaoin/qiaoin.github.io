---
title: RSA 算法
author: qiaoin
date: '2020-06-09'
slug: rsa
categories:
  - algorithm
tags:
  - RSA
---

参考资料：

- [RSA 算法涉及的数学知识](http://www.ruanyifeng.com/blog/2013/06/rsa_algorithm_part_one.html) 介绍了 RSA 算法中涉及到的四个数学概念，1）互质关系，2）欧拉函数，3）欧拉定理，4）模反元素
- [RSA算法原理](http://www.ruanyifeng.com/blog/2013/07/rsa_algorithm_part_two.html) 通过例子进行讲解，同时给出 RSA 算法证明
- [Matrix67：跨越千年的RSA算法](http://www.matrix67.com/blog/archives/5100)
- Fermat 素性测试——在 SICP 第一章也有提及
- [为什么 RSA 公钥每次加密得到的结果都不一样？](https://blog.csdn.net/guyongqiangx/article/details/74930951)

## RSA 算法

1. 随机选择两个不相等的质数 p 和 q（实际应用中，这两个质数越大，就越难破解）；
2. 计算 p 和 q 的乘积 n；
3. 计算 n 的欧拉函数 `$\varphi(n)$`；
4. 随机选择一个整数 e，条件是 1< e < `$\varphi(n)$`，且 e 与 `$\varphi(n)$` 互质；
5. 计算 e 对于 `$\varphi(n)$` 的模反元素 d，即 `$e \times d \equiv 1 \ (\mathbf{mod} \ \varphi(n))$`（实际应用中，常常选择 65537）；
6. 将 (n, e) 封装成公钥，(n, d) 封装成私钥。

> 证明时需要用到的定理推论：
>
> 对于自然数 a, b, e, k，如果 a % e = b, 则 a^k % e = b^k % e

## RSA 加密填充规范

使用公钥进行加密，同一个明文内容，多次加密返回的内容不一样；使用私钥进行签名，同一个明文内容，多次加密返回的内容一样。

> - PKCS #1 v1.5：比较简单的填充方式，也是目前最常见的填充方式
> - PKCS #1 v2.0：指定了针对加密使用的 OAEP 填充方式
> - PKCS #1 v2.1：又进一步指定了针对签名使用的 PSS 填充方式

不管是使用 RSA 私钥进行签名还是公钥进行加密，操作中都需要对待处理的数据先进行填充，然后再对填充后的数据进行加密处理。[PKCS #1 v1.5](https://tools.ietf.org/html/rfc2313)规定的填充格式为：

```bash
EB = 00 || BT || PS || 00 || D
```

表示为：

- `D`: data（指待处理数据，即填充前的原始数据）
- `PS`: padding string（填充字符串）
- `BT`: block type（数据块类型）
- `EB`: encryption block（待加密的数据块，经过填充后结果）
- `||`: 表示连接操作（`X||Y` 表示将 `X` 和 `Y` 的内容连接到一起）

“填充块类型” `BT` 决定了紧挨着的“填充字符串” `PS` 的内容，`BT` 的可能取值包括 `00`, `01` 和 `02`

- 针对**私钥**处理的数据，`BT` 取值为 `00` 或 `01`;
  1. `BT` 取值为 `00` 时，`PS` 为全 `00` 的字符串
  2. `BT` 取值为 `01` 时，`PS` 为全 `FF` 的字符串，通过填充得到的整数会足够大，可以阻止某些攻击，因此也是推荐的填充方式
- 针对**公钥**处理的数据，`BT` 取值为 `02`，使用伪随机的 16 进制字符串填充 `PS`，而且每次操作进行填充的伪随机数都是不同的，因此使用公钥加密数据每次得到的密文都是不一样的

Q1：如果填充字符串 `PS` 中存在 `00`，那如何确定 `PS` 和 `D` 的间隔呢？

[RFC 2313](https://tools.ietf.org/html/rfc2313) 中的 Notes 对此是有解释的：

> For block type 00, the data D must begin with a nonzero octet or have known length so that the encryption block can be parsed unambiguously. For block types 01 and 02, the encryption block can be parsed unambiguously since **the padding string PS contains no octets with value 00** and the padding string is separated from the data D by an octet with value 00.
