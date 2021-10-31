---
title: 《UNIX 网络编程》读书笔记
author: qiaoin
date: '2018-12-24'
slug: unix-network-programming-notes
categories:
  - reading-notes
tags:
  - UNIX
  - Socket
---

---

{{< toc >}}

---


# UNIX 网络编程

- 阻塞式IO；
- 非阻塞式IO；
- 读写锁；
- etc...

**结合陈硕的网络编程实战视频课程进行学习，并整理笔记**

Unix 网络编程第一卷上有两点没有着重讲解：

1. 对消息格式的处理，特别是非阻塞 IO 下如何正确地处理 TCP 分包；
2. 讲授的并发模型稍显陈旧，高并发服务往往是采用事件驱动＋非阻塞 IO 的办法，这是传统的，在 UNIX 网络编程卷一中关于这方面的介绍，分量不足，只有一章介绍。高级的并发模型： Thread-per-connection, non-blocking / event-driven / epoll, thread pool, etc。专门有本书讲解这方面的知识，面向模式的软件架构第二卷，讲各种并发模型， POSA2: Patterns for Concurrent and Networked Objects, pub in 2000

程序员主要关注的网络层：

1. 以太网层，帧 Ethernet frame
2. IP 层，分组 IP packet *注意* IP 分组和 IP 分片是两个事情，一般我们不用管 IP 分片
3. 传输层，分节 TCP segment
4. 应用层，消息 Application message

网络编程存在的一些常见错误：

- 往往将网络 IO 与业务逻辑穿插在一起，应尽量分开；
- TCP 不可靠，收到的数据不完整。主要是涉及 TCP 连接断开的时机和条件，`close` 太早的话，有可能导致协议栈发送 `RST` 分节，将连接给重置，数据自然就收不完了。在阻塞编程中可以使用 `solinger` 这个选项，在非阻塞 IO 中，`linger` 选项失效，我们需要从应用层协议上入手解决这个问题，设计应用层协议的时候把 TCP 连接的断开放到协议设计的考虑中去；
- TCP 是一个字节流协议，它保证字节按顺序到达，但不保留消息的边界。因为对于 TCP 本身来说，是没有消息这个概念的；
- 直接发送 C 语言的结构体，这个需要考虑两个问题，1）对齐，就有人会直接修改全局的对齐方式，会导致第三方库 core dump，因为破坏了 ABI，二进制接口；2） 高度的不可扩展
- TCP 的自连接，客户端会自己和自己连接；
- 非阻塞 IO 网络编程的一些特点。

使用 Netcat 和 dd 测试 TCP 有效带宽及吞吐量

- 在 cn11 上 `dd if=/dev/zero bs=1MB count=1000 | nc cn13 5001`
- 在 cn13 上 `nc -l 5001 > /dev/null`

课程主要讲解哪几个例子：

## 简单的非并发例子 Basic, non-concurrent examples

- TTCP: TCP 性能测试工具
- Round-trip: 测试两台机器之间的时间差，唯一一个 UDP 编程的例子
- Netcat: 网络编程中的瑞士军刀，其与标准输入输出打交道
- Slow sink / source: 慢速收发工具，用于模拟网速比较慢的情况，从应用层模拟，故意地收到之后等一下再收下一个数据；发送也是一样。这样可以帮助找出服务端，特别是在非阻塞情况下，能不能正确应对接收速度慢的情况

## 并发网络编程 Concurrent example

- Socks 代理服务器，将两个 TCP 连接进行中继一下，阻塞、非阻塞两种情况考虑
- 数独求解，典型的请求-响应式模型，特点是连接之间是独立的，可扩展为计算量更大的情况
- 简单的 Memcached 的实现，非阻塞
- 应用层 TCP 的广播，连接之间有交互，连接的生命周期管理，某一个连接接受收据慢该如何处理？

## 多机器上的数据处理 Data processing with multiple machines

> 直接使用 Hadoop / Spark 进行求解

- 并行的 N-皇后问题求解
- 求解分布在多台机器上的数的中位数
- 查询/求解出现次数最多的项
- 分布式排序 Map -> Shuffle -> Reduce

## 高级主题 Advanced Topics

- RPC: A basic building block for various servers
- 负载均衡 load balance
- 服务系统的容量管理
- 延迟 latency 测延时的方法（百分位数的各个延迟），衡量

## 版权声明

本作品采用[知识共享署名 4.0 国际许可协议](http://creativecommons.org/licenses/by/4.0/)进行许可，转载时请注明原文链接。
