---
title: 《TCP/IP 详解》读书笔记
author: qiaoin
date: '2019-10-29'
slug: tcp-ip-illustrated-notes
categories:
  - reading-notes
tags:
  - Socket
  - TCP/IP
---

---

{{< toc >}}

---

- [TCP/IP 详解 卷 1：协议](https://book.douban.com/subject/1088054/)：强调动手操作，使用 `tcpdump` 工具来深入理解网络协议

学习笔记整理，最后梳理的时候：

1. 对于重要知识点，可以梳理清楚，可以根据自己的理解写清楚，不要直接抄书
2. 对于阅读的知识点，条目比较多的，可以考虑画思维导图进行提示

开始阅读时间为 20191029，定一个小目标，

- 年前需要看完【过一遍】，大概还有12个星期（现在开始看的是英文版）
- 如果配合着理解加使用工具分析，可以慢一点
- 可以参考知乎上的回答
- 如何使用工具替代书中的工具？使用什么工具？怎么替代？
- [wireshark使用教程及过滤语法总结——血泪史的汇聚](https://www.zhoulujun.cn/html/theory/network/2016_1130_7908.html)
- 使用 Wireshark 抓包时可以参考书籍
  - [Wireshark网络分析就这么简单](https://book.douban.com/subject/26268767/) -- 章节：你一定会喜欢的技巧-过滤
  - [Wireshark网络分析的艺术](https://book.douban.com/subject/26710788/)
  - [Wireshark数据包分析实战](https://book.douban.com/subject/21691692/)

【20191029】- 【20191102】

Preface 前言

> This book is self-contained and assumes no specific knowledge of networking or TCP/IP. Numerous references are provided for readers interested in additional details on specific topics.

- use a popular diagnostic tool to watch the protocols in action
- Seeing how the protocols operate in varying circumstances provides a greater understanding of **how they work** and **the why certain design decisions were made**.
- **a bottom-up approach** 至底向上
- ip 协议的各个字段解释是分布在不同的章节中的
  - fragmentation --- UDP
  - time-to-live --- traceroute
- > Hands-on experimentation with the protocols will provide the greatest knowledge (and make it more fun).

Introduction 概述

- TCP/IP 协议栈的四层架构：数据链路层、网络层、传输层、应用层
  1. 包含操作系统的设备驱动、网卡等，处理物理接口细节
  2. 处理网络中的 packets
  3. 数据流，TCP 和 UDP
  4. 处理应用细节

- FTP 文件传输协议

- Telnet/SSH 登陆远程主机

- **抽象 abstraction**

- > The purpose of the network interface layer and the application layer are obvious --- the former handles the details of the communication media (Ethernet, token ring, point-to-point links, FDDI (Fiber Distributed Data Interface).) while the latter handles one specific user applicatino (FTP, Telnet, etc.),

- 网络层和数据传输层的区别在哪里呢？让人觉得二者的区别雾蒙蒙的（hazy）。为什么二者会存在不同呢？

- > To understand the reason, we have to **expand our perspective from a single network to a collection of networks**

- 路由和网关分别是什么意思？二者有什么区别和联系？

- 一个路由器具有两个或多个网络接口层，因为它连接了两个或多个网络

  - 一个多接口主机可以称为一个 Host，当它运行某一应用程序时
  - 一个多接口主机也可以称为一个 Router，需进行特殊配置，主要执行将 packages 从一个网络转发到另一个网络（forward packets from one network to another）

- 路由器 router，connect networks at the network layer

- 网桥 bridge，connect networks at the link layer

- TCP/IP 协议族倾向于使用路由器来连接网络

- 应用层和传输层使用端到端协议，网络层提供的却是逐跳协议

- IP 协议提供不可靠服务

- TCP 基于不可靠的 IP 协议，提供可靠的传输服务（超时机制 timeout、重传 retransmission，确认 sends and receives end-to-end acknowledgments，还有一些其他机制）

- IP 地址分为三类：
  1. unicast --  for a single host
  2. broadcast -- for all hosts on a given network
  3. multicast -- for a set of hosts that belong to a multicast group

- DNS（Domain Name System）映射 IP 地址和域名（IP address <--> hostname）

- > When an application sends data using TCP, the data is sent down the protocol stack, through each layer, until it is sent as a stream of bits across the network. Each layer add information to the data by prepending headers (and sometimes adding trailer information) to the data that it receives. The unit of data that TCP sends to IP is called **TCP segment**. The unit of data that IP sends to the network interface is called an **IP datagram**. The stream of bits that flows across the Ethernet is called a **frame**.

- > To be completely accurate , we should say that the unit of data passed between IP and the network interface is a **packet**. This packet can be either an IP datagram or a fragment of an IP datagram.

- IP fragmentation --- IP 分片

- 封包从上往下：

  - 应用层不同的应用使用 TCP/UDP 进行传输，TCP/UDP 在头部信息中保存了源端口号和目的端口号（16-bit，使用端口号来区分不同的应用）
  - TCP/UDP/ICMP/IGMP 向 IP 传送数据，IP 在头部信息中有 8-bit 的协议域（protocol field）【1-ICMP，2-IGMP，6-TCP，7-UDP）
  - IP/ARP/RARP 向网络接口（network interface）传输数据，在以太网帧（Ethernet frame）头部有 16-bit 的帧域（frame type field）

- 当目的主机接收到数据帧（incoming frame）之后，从网络接口开始，根据各个头部信息中的标识域（identifiers in certain header）一层层往上传，进行解包操作（demultiplexing）

- 解包从下往上：

  -  incoming frame
  -  demultiplexing based on frame type in Ethernet header
  -  demultiplexing based on protocol value in IP header
  -  demultiplexing based on destination port number in TCP or UDP header

- 客户端-服务器模式（C-S Model），server 可以分为两类：iterative 和 concurrent

- iterative server 在多个步骤上轮询，在 step 2 服务器是阻塞的，处理已到来的客户端请求时，其他的客户端就不能发送连接请求：
  1. 等待客户端连接的到来
  2. 处理客户端请求
  3. 将请求结果回包发送给客户端
  4. 跳转到 step 1

- concurrent server

  1. 等待客户端创建连接
  2. fork 一个新的 server 去处理接收到的请求
  3. 跳转到 step 1

- > As a general rule, TCP servers are concurrent, and UDP servers are iterative, but there are a few exceptions.

- > The lowercase *internet* means multiple networks connected together, using a common ptotocol suite. The uppercase *Internet* refers to the collection of hosts around the world that can communicate with each other using TCP/IP. While the *Internet* is an *internet*, the reverse is not true.

【20191103】

**Link Layer 链路层**

- TCP/IP 协议族支持很多不同的链路层，取决于机器所使用的网络硬件设备：Ethernet，token ring，FDDI（Fiber Distributed Data Interface），RS-232 serial lines，and the like。

- MTU（Maximum Transmission Unit） -- a limit on the data size of the frame

  - > If IP has a datagram to send, and the datagram is larger than the link layer's MTU, IP performs **fragmentation**, breaking the datagram up into small pieces (fragments), so that each fragment is smaller than the MTU.

  - `netstat -i`

  - 当有着不同 MTU 的两台主机发生网络通信时，关注小的 MTU，称为 Path MTU

  - > The path MTU between any two hosts need not be constand. It depends on the route being used at any time. Also, routing need not be symmetric (对称，the route from A to B may not be the reverse of the route from B to A), hence the path MTU need not be the same in the two directions.

  - "Path MTU discovery mechanism" -- a way to determine the Path MTU at any time [RFC 1191] P30 留了很多坑

- 数据包格式：

  - frame 使用的硬件地址（hardware address）是 48-bits
  - ARP 和 RARP 是在 32-bit IP 地址和 48-bit 硬件地址之间创建映射
  - type -- identifies the type of data that follows
  - data -- 最小 46 bytes for Ethernet，因此需要 Padding
  - CRC（cyclic redundancy check，循环校验码）-- detects errors in the rest of the frame

- Point-to-Point Protocol

- Loopback Interface（环回）：Most implementations supports a loopback interface that allows a client and server on the same host to communicate with each other using TCP/IP.

- > By convention, most systems assign the IP address of 127.0.0.1 to the loopback interface and assign it the name localhost.

- 在处理环回地址时，most implementations perform complete processing of the data in the transport layer and network layer, and only loop the IP datagram back to itself when the datagram leaves the bottom of the network layer.

1. Everything sent to loopback address (normally 127.0.0.1) appears as IP input.
  2. Datagrams sent to a broadcast address or a multicast address are copied to the loopback interface and sent out on the Ethernet. This is because the definition of broadcasting and multicasting includes the sending host.
  3. Anything sent to one of the host's own IP address is sent to the loopback interface.

- > While it may seem inefficient to perform all the transport layer and IP layer processing of the loopback data, it simplifies the design because **the loopback interface appears as just another link layer to the network layer**. The network layer passes a datagram to the loopback interface like any other link layer, and it happens that loopback interface then puts the datagram back onto IP's input queues.

- > One reason for the success of TCP/IP is its ability to work on top of almost any data-link technology.

【20191103】

**IP: Internet Protocol IP 协议**—— RFC 791

- > IP is the **workhorse** protocol of the TCP/IP ptotocol suite.

- 这里表达 "workhorse" 很精准，“吃苦耐劳的人；重负荷的机器”。所有 TCP、UDP、ICMP、IGMP 的数据都需要封装成 IP datagrams 进行传输

- IP 提供的是不可靠、无连接的数据报文传输服务（IP provides an **unreliable**, **connectionless** datagram delivery service）

  - 不可靠（unreliable）：不保证 IP datagram 一定能够成功传输到指定的目的地。使用 IP 进行传输，若需要保证可靠性，则需要上层协议的支持（TCP）
  - 无连接（connectionless）：IP 不保存传输成功的 datagrams 的状态信息（not maintain any state information about successive datagrams）
    - 1）每个 datagram 都是独立处理的
    - 2）datagrams 可以乱序传输，例如一台主机连续发送两个 datagrams（first A，then B）到另一台主机，每一个 datagram 都是独立路由，并且可能经由不同的路由器到达目的主机，到达顺序也不确定（可能 B 先到达）

- IP Header 大小为 20 bytes（不算 options 区域）

- 大端和小端（big endian，little endian）

**IP Header Format**

```shell-session
    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |Version|  IHL  |Type of Service|          Total Length         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |         Identification        |Flags|      Fragment Offset    |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  Time to Live |    Protocol   |         Header Checksum       |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                       Source Address                          |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                    Destination Address                        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                    Options                    |    Padding    |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

- *version* 4-bit，IP 协议版本号，IPv4

- *IHL* (Internet Header Length) 4-bit，表示 IP 协议头部大小（包含 *Options*），单位是 32-bit words。如何理解呢？意思就是 *IHL* 处的值如果为 5（*IHL* 处的最小值），对应的 IP 协议头部大小就为 20 bytes（= 5 * 32-bit = 5 * 4-byte）

- *Type of Service* 8-bit，分为三个部分，前 3-bit 现在已经 ingored 了，紧接着的 4-bit 有用，最后 1-bit unused（must be 0）。设置为 1，表示开启。当 4-bit 都为 0 时，表示普通服务（normal service）。
  1. `minimize delay`
  2. `maximize throughput`
  3. `maximize reliability`
  4. `minimize monetary cost`

    > The *Type of Servie* feature is not supported by most TCP/IP implementations today.

- *Total Length* 16-bit，IP datagram 的总包大小。使用这个域和 *IHL* 就能够知道 IP datagram 的数据部分的起始地址和数据大小。

    > This field changes when a datagram is framented.

- *Identification* 16-bit，唯一标识由主机发送的每一个 datagrams（每次递增 1）。

- *Flags* 3-bit

- *Fragment offset* 13-bit 这三个域都与 fragmentation 相关

- *Time to Live* 8-bit，在传输某一个 datagram 时，能够经由的路由器的上限值（sets an upper limit on the number of routers through which a datagram can pass），发送方进行初始化（一般是 32 或 64），在每经过一个路由器时由路由器将*TTL* 的值减少 1。当 *TTL* 为 0 时，这个 datagram 会被丢弃（be thrown away），同时会有一条 ICMP 消息通知发送方。

- *Protocol* 8-bit，由于 IP 作为 TCP/UDP/ICMP/IGMP 通信的中转方，*Protocol* 域用于标识上层协议，这样在 IP 层接收到数据包之后，可以根据 *Protocol* 域执行解包操作（demultipling incoming datagrams）。

- *Header Checksum* 16-bit，仅为计算 IP Header 的校验码。参考 [IP数据报首部checksum的计算](https://www.cnblogs.com/zafu/p/10822164.html)。在发送时：

  1. *Checksum* 域先设置为 0；
  2. 将整个 IP Header 分为多个 16-bit，执行求和；
  3. 如果和的高 16-bit 不为 0，则将和的高 16-bit 和低 16-bit 反复相加，直到和的高 16-bit 为 0，从而获得一个 16-bit 的值；
  4. 对得到的 16-bit 的值取反码，填入到 *Checksum* 中

  当接受到 IP datagram 时，

  1. 直接将接收到的整个 IP Header 分为多个 16-bit，求和；
  2. 如果和的高 16-bit 不为 0，则将和的高 16-bit 和低 16-bit 反复相加，直到和的高 16-bit 为 0，从而获得一个 16-bit 的值；
  3. 对得到的 16-bit 的值取反码，若结果为 0，则合法；否则，丢弃这个 datagram（No error message is generated. It is up to the higher layer to somehow detect the missing datagram and retransmit.）

- *Source Address* & *Destination Address* both 32-bit，源 IP 地址和目的 IP 地址

- *Options (if any)*  可变长度，对 IP datagram 的补充信息进行定义：
  - security and handling restrictions
  - record rote (have each route record its IP address)
  - timestamp (have each router record its IP address and time)
  - loose source routing (specifying a list of IP addresses that must be traversed by the datagram)
  - strict source routing (similar to loose source routing, but here only the addresses in the list can be traversed)
  > These options are rarely used and not all host and routers support all the options.

【20191104】

**IP Routing**

【20191105】

- IP datagram 的传输分为两种（简单模式）：

  1. the destination is directly connected to the host (e.g., a point-to-point link) or on a shared network (e.g., Ethernet or token ring)：IP datagram 直接传送到目的主机；
  2. otherwise：本地主机将 IP datagram 传送到一个默认路由器（default router），然后由路由器将 IP datagram 传送到目的地

- > 第九章 ：The IP layer can be configured to act as a router in addition to acting as a host. Most multiuser systems today, including almost every Unix system, can be configured to act as a router. We can then specify a single routing algorithm that both hosts and routers can use.
  >
  > - a *host* **never** forwards datagrams from one of its interface to another;
  > - a *router* forwards datagrams.
  >
  > A host that contains embedded router functionality should never forward a datagram unless it has been specifically configured to do so.

- IP 层会接收到两个部分的 datagram

  1. 本机生成的 datagrams：来自 TCP/UDP/ICMP/IGMP，需要发送出去；
  2. 非本机生成的 datagrams：来自 network interface，需要对接收到的 datagrams 进行转发（forwarding）
     - IP 检查 datagram 的目的 IP 地址是否与本机 IP 地址相同，或者为一个广播地址
     - 若是，datagram 会交由其 IP Header 中标识的协议类型（*protocol*）所对应的网络模块（protocol module）进行处理
     - 若不是，1）如果接收到 datagram 的主机配置为可以作为一个路由器，该 datagram 就会被转发出去，2）否则，就会将该 datagram 丢弃（silently discarded，不会通知源主机）

**路由表（Routing table）**【看不明白】

【20191106】

> The IP layer has a routing table in memory that it searches each time it receives a datagram to send.

- Linux 查看 `route -n`，Mac 查看 `netstat -nr`

```shell-session
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         9.134.112.1     0.0.0.0         UG    0      0        0 eth1
9.0.0.0         9.134.112.1     255.0.0.0       UG    0      0        0 eth1
9.134.112.0     0.0.0.0         255.255.240.0   U     0      0        0 eth1
10.0.0.0        9.134.112.1     255.0.0.0       UG    0      0        0 eth1
100.64.0.0      9.134.112.1     255.192.0.0     UG    0      0        0 eth1
link-local      0.0.0.0         255.255.0.0     U     1002   0        0 eth1
172.16.0.0      9.134.112.1     255.240.0.0     UG    0      0        0 eth1
192.168.0.0     9.134.112.1     255.255.0.0     UG    0      0        0 eth1
```

- 路由表中的每一项都包含有以下信息：

  - *Destination* 目的 IP 地址
    - the address of a host: host ID 不为 0，唯一标识一台主机
    - the address of a network: host ID 为 0，标识当前网络上的所有主机
  - *Gateway* 网关，下一跳路由器对应的 IP 地址，将 datagram 发送过去，然后网关执行转发
    - a next-hop router: on a directly connected network to which we can send datagrams from delivery. It takes the datagrams we send it and forwards them to the final destination.
    - a directly connected interface
  - *Flags* 标识位。
    - 其中一位标识 *Destination* 的 IP 地址对应是 a host 还是 a network
    - 其中一位标识 *Gateway* 是 next-hop router 还是 a directly connected interface
  - *Iface* 表示 datagrams 将由哪一个网卡（network interface）进行传输

- > IP routing is done on a hop-by-hop basis. All that  IP routing provides is the IP address of the next-hop router to which the datagram is sent.

- IP routing 执行以下操作：

  1. 首先在路由表中精确匹配目的 IP 地址，同时匹配上 network ID 和 host ID。若找到这样一个条目，将 datagram 发送给 *Gateway* ，就建立了一个 point-to-point 的连接

  2. 在路由表中查找目的 network ID。若找到，将数据包发送给 *Gateway*。所有在目的网络（destination network）上的主机都会 handled with this single routing table entry.

     这里跟子网掩码有关系

  3. 在路由表中查找有 “default” 标签的条目，若找到，将数据包发送给 *Gateway*

- 查找是按照顺序进行的，若三步执行下来还是未找到，这个 datagram 就是 undeliverable 的，就会给生产这个 datagram 的应用程序返回 “host unreachable” 或 “network unreachable”

- IP routing 拥有将一个路由器指定在某一网络区域（specify a route to a network）的能力，这样能够减少路由表中条目的数量

- 举例，两台主机 A 140.252.13.35 和 B 142.252.13.33，进行通信：

  1. 主机 A 的 IP 层接收到来自上层（TCP/UDP/ICMP/IGMP）的 datagrams

  2. 主机 A 查找路由表，得到 B 的 IP 地址和自己直接都是连接在一个网络上（on a directly connected network, the Ethernet 140.252.13.0）。即 A 和 B 的 network ID 相同

  3. 主机 A 将 datagrams 传输到以太网设备驱动器（the Ethernet device driver），由网卡将 datagrams 作为以太网帧（Ethernet frame）传给主机 B

     - 在 IP datagrams 中，主机 B 的 IP 地址是 32-bit 的
     - 在 Ethernet frames 中，主机 B 的 Ethernet 地址是 48-bit 的
     - IP address -- Ethernet address，使用地址解析协议（ARP）
     - 在以太网帧中会包含主机 B 的 Ethernet 地址和 IP 地址

- 举例，两台主机 A 140.252.13.35 和 C 192.48.96.9，进行通信：

  1. 主机 A 的 IP 层接收到来自上层（TCP/UDP/ICMP/IGMP）的 datagrams
  2. 主机 A 查找路由表，未找到 (networkID, hostID) 和 hostID 相同的条目（not find a matching host entry or a matching network entry）；使用有 “default” 标识的条目（*Gateway* 为主机 D），将 datagrams 发送给 next-hop router 主机 D
     - 由主机 A 发送给主机 D 的 datagrams
     - 以太网帧中，链路层头部包含的是主机 D 的 48-bit Ethernet 地址，IP 层头部包含的是目的主机 C 的 IP 地址（192.48.96.9）
  3. 主机 D 接收到来自主机 A 的 datagrams，检查 datagrams 的目的 IP 地址与自身（主机 D）的 IP 地址不相同，同时主机 D 被配置作为路由器（configured to act as a router），因此它会将 datagrams 转发出去。同样地，主机 D 查找路由表，未找到  (networkID, hostID) 和 hostID 相同的条目，因此使用 “default” 标识的条目（*Gateway* 为主机 E），将 datagrams 发送给 next-hop router 主机 E
     - 由主机 D 发送给主机 E 的 datagrams
     - 以太网帧中，链路层头部包含的是主机 E 的 48-bit Ethernet 地址，IP 层头部包含的是目的主机 C 的 IP 地址（192.48.96.9）
  4. 主机 E 接收到来自主机 D 的 datagrams，检查 datagrams 的目的 IP 地址与自身（主机 E）的 IP 地址不相同，同时主机 E 被配置作为路由器，因此它会将 datagrams 转发出去。同样地，主机 E 查找路由表，未找到  (networkID, hostID) 和 hostID 相同的条目，因此使用 “default” 标识的条目（*Gateway* 为主机 F），将 datagrams 发送给 next-hop router 主机 F
     - 由主机 E 发送给主机 F 的 datagrams
     - 以太网帧中，链路层头部包含的是主机 F 的 48-bit Ethernet 地址，IP 层头部包含的是目的主机 C 的 IP 地址（192.48.96.9）

- 上面两个例子，有以下几个要点：

  - 路由表中的 “default” 条目
  - datagrams 中的目的 IP 地址不会改变，在上述例子中一直是主机 C 的 IP 地址
  - 数据链路层的头部信息会改变，其中的 48-bit Ethernet 地址标识下一跳将要到的主机

**子网地址（Subnet addressing）**

【20191107】 RFC 950

- IP 地址由 network ID + **host ID** 组成

  - => network ID + **subnetwork ID + host ID**

- InterNIC 接收到一类 IP 地址之后，就能够确定 network ID 占了 32-bit 的多少位了，对于剩余的位数，就需要确定多少位是 subnetwork ID，多少位是 host ID 了？

- > Subnetting hides the details of internal network organization (within a company or compus) to external routers.

  - 每个子网下有多少台机器，怎么分布、怎么连接的，外界都不需要关心

- > Subnetting reduce the size of the Internet's routing tables.

  - 只需要知道 *gateway* 的 IP 地址，外界就能够与该网关下所有的机器进行通信
  - 外界 router 只需要在其路由表中保存一条记录即可，怎么找到网关  *gateway*
  - *gateway*  需要知道各个子网的编号

**子网掩码（Subnet mask）**

- 机器如何确定它的 IP 地址的？在系统启动时 bootstrap 阶段
- 子网掩码 -- 将 network ID 和 subnetwork ID 的每一位都置为 1，将 host ID 置为 0
- 给定 IP 地址和对应的子网掩码，主机就能够确定一个目的 IP datagram
  1. 为同一子网的其他主机（a host on its own subnet）
  2. 为同一网络上其他子网的主机（a host on a different subnet on its own network）
  3. 为不同网络的其他主机（a host on a different network）

-  1）知道 IP 地址属于哪一类（A/B/C/D/E），就能够确定 network ID 和 subnetwork ID 的分界线了
- 2）知道子网掩码，就能够确定 subnetwork ID 和 host ID 的分界线了

- 特殊 IP 地址：

**ifconfig Command（ifconfig 命令）**

- `ifconfig(8)` 在 bootstrap 阶段就会执行，用来设置主机的各个网卡设备

```shell-session
$ ifconfig -a
eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 9.134.112.130  netmask 255.255.240.0  broadcast 9.134.127.255
        ether 52:54:00:6a:73:2f  txqueuelen 1000  (Ethernet)
        RX packets 25698351  bytes 35151409611 (32.7 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 11706559  bytes 1585777451 (1.4 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        loop  txqueuelen 0  (Local Loopback)
        RX packets 1138942  bytes 910825599 (868.6 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1138942  bytes 910825599 (868.6 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```



**netstat Command（netstat 命令）**

```shell-session
$ netstat -in
Kernel Interface table
Iface      MTU    RX-OK RX-ERR RX-DRP RX-OVR    TX-OK TX-ERR TX-DRP TX-OVR Flg
eth1      1500 25698474      0      0 0      11706674      0      0      0 BMRU
lo       65536  1139018      0      0 0       1139018      0      0      0 LRU
```



**总结**

- >Hosts and routers have a routing table that is used for all routing decisions. There are three types of routers in the table: host specific, network specific, and optional default routes. There is a priority to the entries in a routing table. A host route will be chosen over a network router, and a default route is used only when no other route exists to the destination.

- > IP routing is done on a hop-by-hop basis. The destination IP address never changes as the datagram proceeds through all the hops, but the encapsulation and destination link-layer address can change on each hop. Most hosts and many routers use a default next-hop router for all nonlocal traffic.

- > The use of subnetting reduces the size of the Internet routing tables, since many networks can often be accessed through a single point.

**问题**

1. 本地环回地址一定要是 127.0.0.1 吗？本地回环地址指的是以127开头的地址（127.0.0.1 - 127.255.255.254），通常用127.0.0.1来表示
2. 如何判断一个网络中的主机有多个网卡？
3. RFC 1219 -- assigning subnet IDs and host IDs

【20191108】

**ARP: Address Resolution Protocol 地址解析协议**

- 当一个以太网帧（Ethernet Frame）从一台主机传输到另一台主机，48-bit 的以太网地址（Ethernet address）用来确定这个以太网帧将要发送给哪一个网络接口（interface）。设备驱动器（device driver software）不会去检查 IP datagram 中的目的 IP 地址。

- ARP 地址解析协议用来 **动态（*dynamic*）** 的做 IP 地址和以太网地址之间的映射转换

- 以 `ftp bsdi` 为例：
  1. FTP client 调用 `gethostbyname(3)` 将主机名（`bsdi`） 转化为 32-bit 的 IP 地址。`gethostbyname(3)` 调用 DNS（Domain Name System）的一个解析器（resolver），或者使用一个静态映射文件 `/etc/hosts`

  2. FTP client 请求与目的 IP 地址创建 TCP 连接

  3. TCP 发送连接请求，发送包含目的 IP 地址的 IP datagram（**更多细节**）

  4. - 目的主机在 locally attached network (e.g., Ethernet, token ring, or the other end of a point-to-point link)，则 IP datagram 能够直接传送给该目的主机；
     - 目的主机在 remote network，IP routing function 会确定一个 IP 地址（of a locally attached next-hop router），将 IP datagram 发送到路由器即可；
     - => 在这两种情况下，IP datagram 都会被发送到 locally attached nework 上的一台主机或者路由器

  5. 假设数据链路层为 Ethernet，发送端需要将其自身的 32-bit  IP 地址转换为 48-bit 的 Ethernet 地址

     > A translation is required from the *logic* Internet address to its corresponding *physical* hardware address.
     >
     > ARP is intended for broadcast networks where many hosts or routers are connected to a single network.

  6. ARP 发送一个 ARP request 的以太网帧给当前网络下的所有主机，**广播（*broadcast*）**【如何做到广播的？将 ARP Ethernet header 中的 6-byte 目的硬件地址全部置为 1】。ARP requst 中包含有目的主机的 IP 地址，请求消息体可以表述为“假如你是这个 IP 地址的 owner，请回复你的硬件地址给到我”

  7. 目的主机的 ARP 层接收到这条广播，识别出发送端请求自身的硬件地址，目的主机以 ARP reply 作为回复。ARP reply 中包含有目的 IP 地址和对应的硬件地址

     - 这里有一个问题，ARP reply 怎么知道发送端的 IP 地址和对应的硬件地址的？
     - ARP request 中包含有源硬件地址和源 IP 地址

  8. 发送端接收到 ARP reply

  9. IP datagram 发送给目的主机

- > The fundamental concept behind ARP is that the network interface has a hardware address (a 48-bit value for an Ethernet or token ring interface). Frames exchanged at the hardware level must be addressed to the correct interface. The kernel (i.e., the Ethernet driver) must know the destination's hardware address to send it data.

- 使用 `arp -a` 查看 ARP cache 中保存的近期映射：IP 地址到硬件地址，缓存过期时间默认为 20 分钟

**ARP Packet Format ARP 数据包格式** 【20191109】

- **14-bytes Ethernet header**

  - 6-byte 目的硬件地址（Ethernet destination address）：当将 48-bit 全部置为 1 时，表示广播地址
  - 6-byte 源硬件地址（Ethernet source address）
  - 2-byte 以太网帧类型（Ethernet frame type）：表示紧接着的数据域类型，对于 ARP request / ARP reply，2-bytes 类型对应的值为 0x0806

- **28 bytes ARP request/reply**

  - > The adjectives *hardware* and *protocol* are used to describle the field in the ARP packets. For example, an ARP request asks for hardware address (an Ethernet address in this case) corresponding to a protocol address (an IP address in this case).

  - 2-byte 硬件地址类型（hard type）：Ethernet 地址类型设置为 1

  - 2-byte 协议地址类型（prot type）：IP 地址类型设置为 0x0800

  - 1-byte 硬件地址长度（hard size）：单位 bytes，Ethernet 地址长度为 48-byte，对应为 6

  - 1-byte 协议地址长度（prot size）：单位 bytes，IP 地址长度为 32-byte，对应为 4

  - 1-byte op：标识当前数据包的类型，ARP request（1），ARP reply（2），RARP request（3），RARP reply（4）

  - 6-byte 发送端硬件地址（sender Ethernet address）

  - 4-byte 发送端 IP 地址（sender IP address）

  - 6-byte 目的端硬件地址（target Ethernet address）

  - 4-byte 目的端 IP 地址（target Ethernet address）

- > For an ARP request all fields are filled in except the target hardware address (这里第一个 6-byte 目的硬件地址全置为 1，发送广播). When a system receives an ARP request directed to it, it fills in its hardware address, swaps the two sender addresses with the two target addresses, set the *op* field to 2, and sends the reply.

- > Since the size of an ARP request and ARP reply is 42-bytes (28-bytes for the ARP message, 14-bytes fot the Ethernet header), each frame has been padded to the Ethernet minimum: 60 bytes.

- > Most device drivers or interface cards automatically pad an Ethernet frame to the minimum size.

- > Indeed, we'll see later that most BSD implementations set a limit of 75 seconds for a TCP connection request to complete.

- > In Chapter 18, when we see the sequence of TCP segments that is sent to establish the connection, we'll see that these ARP requests correspond one-to-one with the initial TCP SYN (synchronize) segement that TCP is tring to send.

- > Until an ARP reply comes back, the TCP segments can't be sent, since the destination hardware address isn't know.

- > If a host receives an ARP request from an IP address that is already in the receiver's cache, then that cache entry is updated with the sender's hardware address from the ARP request. This is done for any ARP request received by the host. This is because that ARP request are broadcast, so this is done by all hosts on the network each time an ARP request is sent.

- proxy ARP: when a router answers ARP requests for hosts accessible on another of the router's interface

- gratuitous ARP: sending an ARP request for your own IP address, normally when bootstrapping

**RARP: Reverse Address Resolution Protocol 反地址解析协议**

- 当一个有磁盘的机器在启动（boostrap）时，它会读取磁盘上的一个配置文件去得到其 IP 地址。但对于没有磁盘的系统（例如，an X terminal or a diskless workstation），如何去得到其 IP 地址呢？

- 互联网上的每一台主机都有唯一的硬件地址（即 MAC 地址），由生产网卡的硬件厂商指定

- RARP 的做法是：

  1. 读取本地网卡设备的 MAC 地址
  2. 发送 RARP request 广播到网络（a broadcast frame on the network），请求得到 IP 地址的回复
  3. RARP reply

- RARP 的 frame type 为 0x8035

- > As with ARP, the RARP request is **broadcast (广播)** and the RARP reply is normally **unicast (单播)**.

- 使用 RARP，网络上需要有一个 RARP server。难点在于：

  1. server 需要提供当前网络下所有 diskless 主机的硬件地址到 IP 地址之间的映射。这种映射关系写在磁盘文件 `/etc/ethers` 中。而 kernel 不会去读取和解析磁盘文件，因此 RARP server 只能实现在用户空间，不能够作为 kernel TCP/IP 实现的一部分
  2. RARP server 需要能够发送和接收 0x8035 类型的以太网帧
  3. 当一个 RARP server 宕机的时候，为了能够支持继续支持 RARP，就需要增加冗余 RARP server。然而，当引入更多的 RARP server 之后，networ traffic 就会增加（每一个 RARP server 会对 RARP request 回复一个 RARP reply），并且当多个 RARP reply 同时到达时，更会出现冲突

- > While the concept of RARP is simple, the design of an RARP server is system dependent and complex. Conversely (相反地), providing an ARP server is simple, and is normally part of the TCP/IP implementation in the kernel. Since the kernel knows its IP addresses and hardware addresses, when it receives an ARP request for one of its IP addresses, it just replies with the corresponding hardware address.

**ICMP Internet Control Message Protocol 互联网控制报文协议** —— RFC 792

【20191111】

```shell-session
    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |Version|  IHL  |Type of Service|          Total Length         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |         Identification        |Flags|      Fragment Offset    |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |  Time to Live |    Protocol   |         Header Checksum       |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                       Source Address                          |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                    Destination Address                        |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                    Options                    |    Padding    |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                        ICMP message                           |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

ICMP message 的格式如下：

```shell-session
    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   | Type          |    Code       |            Checksum           |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                       Unused (must be 0)                      |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                                                               |
   :IP header(options) + first 8 bytes of original IP datagram data:
   |                                                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

- Type 8-bytes：前 4-bytes 是相同的，后 4-bytes 表示 15 种不同类型的 ICMP message

- Code 8-bytes：*Type* 表示的 15 种类型不够用，需要使用 *Code* 来进行一些补充说明

- Checksum 16-bytes：整个 ICMP message 的校验和，和 IP header 的校验和计算方式一样，校验和为必填字段

> - We talk about ICMP messages in general and a few in detail: address mask request and reply, timestamp request and reply, and port unreachable.
> - We discuss the echo request and reply messages in detail with Ping program.
> - We discuss the ICMP message dealing with IP routing.

- ICMP message 的类型：
  1. Query messages：
  2. Error messages：特殊处理，例如，当一个 error message 的请求到来时，不会产生 error message 回复（如果对接收到的 error message 产生回复，就会产生“雪崩”）
     - 一条 ICMP error message 总是包含 IP header + IP datagram data 部分的前 8 个 bytes

     - IP header 的 *Protocol* 域会标识协议类型 TCP 或 UDP

     - IP datagram data 部分的前 8 个 bytes，即为 TCP header 或 UDP header，对应的 *port* 域会标识特定的用户应用（源端口号，目的端口号）

     - > Both TCP and UDP store the source and destination port number in the first 8 bytes of their headers.

> An ICMP error message is **never** generated in response to:
>
> 1. An ICMP error message. (An ICMP error message may, however, be generated in response to an ICMP query message.)
> 2. A datagram destined to an IP broadcast address or an IP multicast address (a class D address).
> 3. A datagram sent as a link-layer broadcast.
> 4. A fragment other than the first.
> 5. A datagram whose source address does not define a single host. This means the source address cannot be a zero address, a loopback address, a broadcast address, or a multicast address.
>
> => These rules are meant to prevent the *broadcast storms* that have occurred in the past when ICMP errors were sent in response to broadcast packets.

【20191112】

- ICMP 地址掩码请求（ICMP Address Mask Requst）是用于 diskless system 在 bootstrap 阶段去获取到子网掩码的（subnet mask）

- 广播，会同样给发送广播请求的主机发送一份 copy（through some internal loopback mechanism）。因为**广播**的定义就是在当前网络下的**所有**主机，肯定就需要包含发送主机。

- > When the Ethernet driver recognizes that the destination address is the broadcast address, the packet is sent onto the network and a copy is made and passed to the loopback interface.

- > IP datagrams sent to the host's own IP address are actually sent to the loopback interface.

- ICMP 时间戳请求（ICMP Timestamp Request）是用于一台主机去请求另一台主机的当前时间（millisecond）

- > ICMP 地址掩码请求和回复（ICMP Address Mask Requst and Replay）、ICMP 时间戳请求和回复（ICMP Timestamp Request and Reply），都是典型的 request-reply messages。
  >
  > Both have an identifier and sequence number in the ICMP message. The sending application stores a unique value in the identifier field, to distinguish between replies for itself and replies for other processes. The sequence number field lets the client match replies with request.

- Round-trip time (RTT) -- 接收到回复的时间 - 请求发送出去的时间

- Network Time Protocol (NTP) NFC 1305

- ICMP 不可达端口错误（ICMP Port Unreachable Error）

- > One rule of UDP is that if it receives a UDP datagram and the destination port does not correspond to a port that some process has in use, UDP responds with an ICMP port unreachable error.

- > Why dose the TFTP client keep retransmitting its request when the ICMP port unreachable errr messages are being returned?
  >
  > 1. BSD systems don't notify user processes using UDP of ICMP messages that are received for that socket unless the process has issued a **connect** on that socket. The standard BSD TFTP client does not issue the **connect**, so it never receives the ICMP error notification.
  > 2. The poor retransmission timeout algorithm used by this TFTP client.

**Ping** —— RFC 792

【20191113】

> The name "ping" is taken from the sonar operation to locate objects (声纳定位物体). The Ping program was written by Mike Muuss and **it tests whether another host is reachable**. The program sends an ICMP echo request message to a host, expecting an ICMP echo reply to be returned.
>
> Normally, if you can't Ping a host, you won't be able to Telnet or FTP to that host. Conversely, if you can't Telnet to a host, Ping is often the starting point to determine what the problem is. Ping also measures the round-trip time to the host, giving us some indication of how "far away" that host is.

- Ping 用来确认一台远程主机是否是 reachable 的，如果 Ping 不通，其他的上层应用如 Telnet 或 FTP 更不会通
- 将 Ping 作为一个诊断工具（判断是否可以连接上另外的一台主机），去进一步挖掘 ICMP 协议
- 同时，可以使用 Ping 去检查 IP record route 和 timestamp options

> Years ago we could make the unqualified statement that if we can't Ping a host, we can't Telnet or FTP to that host. With the increased awareness of security on the Internet, **routers that provide access control lists, and fireware gateways**, unqualified statements like this no longer true. **Reachability of a given host may depend not only on reachability at the IP layer, but also on what protocol is being used, and the port numbers involved**.

```shell-session
    0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   | Type(0 or 8)  |    Code(0)    |            Checksum           |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |         Identifier            |       sequence number         |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |                                                               |
   :                        Data(optional)                         :
   |                                                               |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

- *identifier* -- 发送 ICMP message 进程的进程号（pid），用于辨别返回给该请求进程 pid 的返回消息（responses）

- *sequence number* -- 从 0 开始，每次一个新的 echo 请求发送，sequence number 增加 1。Ping 会打印出接收到的回复对应的 sequence number，我们就能够辨识哪些包丢失了（missing）、被重定向了（reordered）、重复发送了（duplicated）

  - missing -- echo replies for sequence numbers were lost somewhere
  - reordered -- sequence number N+1 printed before sequence number N
  - deplicated -- the same sequence number printed two or more times

- LAN (Local Area Network) 局域网

- WAN (Wide Area Network) 广域网

- > Ping is able to calculate the round-trip time by storing the time at which it sends the echo request in the data portion of the ICMP message. When the reply is returned it subtracts this value from the current time.

**IP Record Route Option**

【20191117】

- 流程
  1. ping request (ICMP echo request message) 发送出去的时候设置 IP datagram 的 IP Record Route 选项
  2. ping requst 经路由器转发到达目的 IP 地址，对该 ping request 进行转发的路由器都会将自己的 IP 地址加入到 IP header 的 *Option* 域
  3. ping request 到达最终 IP 地址，ping reply (ICMP echo reply message) 中会包含 ping request 的 *Option* 域的所有 IP 地址
  4. 同时，ping reply 回包到达源 IP 地址，也会将返回路径上的所有路由器的 IP 地址加入 *Option* 域
  5. ping 会将接收到的 ping reply 中的所有 IP 地址打印出来
- 有一些限制
  - IP header 中的 *header length* 域是 4-bit，因此整个 IP header 的大小限制为 15 32-bit words（60 bytes）
  - IP header 固定的区域占 20 bytes
  - IP Record Route Option 会占用 3-bytes
  - IP address list 的大小限制为 37（60-20-3）bytes，即最多 9 个 IP 地址

**IP Timestamp Option**

【20191118】

与 IP Record Route Option 类似，二者都不够实用，类似的功能可以使用 *Traceroute* 实现

> The *Ping* program is the basic connectivity test between two systems running TCP/IP. It uses the ICMP echo request and echo reply messages and does not use a transport layer (TCP or UDP). The *Ping* server is normally part of the kernel's ICMP implementation.

**Traceroute**

【20191118】

- 为什么不直接使用 **IP Record Route Option**，而新开发一个工具 **Tracerout** 呢？有以下三个理由：

  1. 历史原因：并不是所有的路由器都支持 **IP Recode Route Option**，而 **Traceroute** 不需要路由器具备特殊的功能和能力；
  2. record route is normally a one-way option. 发送方设置了这个选项，接收方就应该返回发送方路由信息（从发送方将数据包传送给接收方的路由信息），而不需要返回从接收方将数据包 reply 到发送方的路由信息（发送方不 care 这个路由信息）。**Traceroute** requires only **a working UDP module** at the destination --- no special server application is required；
  3. 由于 IP header 的长度限制，使用 **IP Record Route Option** 最多能够记录 9 个 IP 地址信息。
- **Traceroute** 使用 ICMP message 和 IP header 的 *TTL (time-to-live)* 域

  - 8-bit *TTL* 域由发送方初始化

  - 每一个接收到 IP datagram 的路由器都需要将 *TTL* 减 1 或者减去当前路由器占用（hold）数据包的时间（秒数）。一般情况下，大多数路由器处理 IP datagram 的时间都不会超过 1 秒，因此每个路由器仅仅是将 *TTL* 减 1，这样 *TTL* 域就能够作为跳的计数器（a hop counter）

  - *TTL* 域是用来防止数据包进入死循环的。例如，当一个路由器宕机或着两个路由器之间的连接断开时，路由协议需要花费一些时间（从几秒钟到几分钟不等）才能够检测到这个问题。在这期间，IP datagram 会陷入 routing loops，*TTL* 域设置了 IP datagram 的上限（可以理解为超时时间）

  - 当一个路由器接收到的 IP datagram 的 *TTL* 域为 0 或 1 时，这个 IP datagram 就不能继续被转发（forward）出去了。这个路由器需要将这个 IP datagram 给丢弃掉，同时给发送方返回 ICMP time exceeded message。**Traceroute** 的关键点是包含这个 ICMP time exceeded message 的 IP datagram 其头部的源 IP 地址为路由器的 IP 地址

    - 目的主机接收到 IP datagram 时，*TLL* 域为 0 或 1，将该 datagram 传递给上层应用层进行处理

    - 不会有 *TTL* 域为 0 的 IP datagram 被接收到
- **Traceroute** 的操作流程：【需要根据实验纠正】
  1. 发送 *TTL* 域为 1 的 IP datagram 到目的主机，第一个接收到的路由器将 *TLL* 减 1（*TTL* 域为 0），就会将这个 IP datagram 给丢弃掉，同时向发送方返回 ICMP time exceeded message
  2. 发送方接收到 ICMP time exceeded message，就能够确定路由线路上的第一个路由器的 IP 地址了
  3. 发送 *TTL* 域为 2 的 IP datagram 到目的主机，就能够确定路由线路上的第二个路由器的 IP 地址了
  4. **Traceroute** 持续发送 *TTL* 域递增的 IP datagram，直到最终达到目的主机（目的主机接收到的 IP datagram 的 *TTL* 域为 1）
  5. 发送 UDP datagrams 到目的主机，并且选择目的端口号为 unlikely value (larger than 30,000)，确保目的主机上没有应用程序在使用该端（应用程序使用端口号进行区分）。当 UDP datagrams 到达目的主机时，*TTL* 域为 1，就会将 datagram 传递给上层应用进行处理，但这里并没有对应的应用程序在执行，因此 UDP moudle 会产生一个 ICMP port unreachable error message 返回给发送方
  6. 发送方通过区分返回的 ICMP message 的类型就能够知道是否已经到达目的主机，ICMP time exceeded message 和 ICMP port unreachable error message

**IP Source Routing Option**

【20191125】

> Normally IP routing is dynamic with each router making a decision about which next-hop router to send the datagram to. Applications have no control of this, and are normally not concerned with it.

- IP Source Routing -- 发送方指定路由（the sender specifies the route）
  1. **Strict source routing** ：发送方直接指定好到达目的主机的路径。如果在路由过程中，下一跳的路由器（在 source route 指定中）与当前转发的主机不直接连接，就会返回 ICMP source route failed error
  2. **Loose source routing** ：发送方指定一个 IP 地址列表

- 在发送 IP datagram 之前，需要填充好 IP 地址列表
  - 发送方从应用程序获得 source route list，从 list 中移除第一项作为下一跳的目的地，将 IP datagram 的目的主机的 IP 地址加入到 list 的最后
  - 接收到该 IP datagram 的路由器进行处理，检查是否与 dest 指定的 IP 地址相同，若不同，则转发出去（需要指定 loose source routing，如果没有指定，该路由器都不会接受到该 IP datagram）
  - 若相同，则1）list 现在的第一项作为下一跳的目的地；2）

```shell-session
dest = D
{#R1,R2,R3}
   |
   |
   V
-----  dest = R1  ------  dest = R2  ------  dest = R3  ------  dest = D   -----
| S | ----------> | R1 | ----------> | R2 | ----------> | R3 | ----------> | D |
----- {#R2,R3,D}  ------ {R1,#R3,D}  ------ {R1,R2,#D}  ------ {R1,R2,R3#} -----
```

**IP Routing**

- Linux 查看 `route -n`，Mac 查看 `netstat -nr` （`-r` 表示列出路由表，`-n` 表示以数字形式打印 IP 地址）

```shell-session
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         9.134.112.1     0.0.0.0         UG    0      0        0 eth1
9.0.0.0         9.134.112.1     255.0.0.0       UG    0      0        0 eth1
9.134.112.0     0.0.0.0         255.255.240.0   U     0      0        0 eth1
10.0.0.0        9.134.112.1     255.0.0.0       UG    0      0        0 eth1
100.64.0.0      9.134.112.1     255.192.0.0     UG    0      0        0 eth1
link-local      0.0.0.0         255.255.0.0     U     1002   0        0 eth1
172.16.0.0      9.134.112.1     255.240.0.0     UG    0      0        0 eth1
192.168.0.0     9.134.112.1     255.255.0.0     UG    0      0        0 eth1
```

- 路由表中的每一项都包含有以下信息：

  - *Destination* 目的 IP 地址
    - the address of a host: host ID 不为 0，唯一标识一台主机
    - the address of a network: host ID 为 0，标识当前网络上的所有主机
  - *Gateway* 网关，下一跳路由器对应的 IP 地址，将 datagram 发送过去，然后网关执行转发
    - a next-hop router: on a directly connected network to which we can send datagrams from delivery. It takes the datagrams we send it and forwards them to the final destination.
    - a directly connected interface
  - *Flags* 标识位。
    - 其中一位标识 *Destination* 的 IP 地址对应是 a host 还是 a network
    - 其中一位标识 *Gateway* 是 next-hop router 还是 a directly connected interface
  - *Iface* 表示 datagrams 将由哪一个网卡（network interface）进行传输

- 路由表中保存的信息：
  - 
- 



**ICMP redirects**


## 版权声明

本作品采用[知识共享署名 4.0 国际许可协议](http://creativecommons.org/licenses/by/4.0/)进行许可，转载时请注明原文链接。
