---
title: Rust 中的生命周期
author: qiaoin
date: '2021-12-15'
slug: rust-lifetime
categories:
  - 编程语言
  - Rust
tags:
  - 生命周期
  - Rust
  - Learning-by-doing
---

在本文中，我们将围绕着字符串分割的实例，讲解 Rust 中的生命周期。首先剖析为什么需要生命周期、什么是生命周期、以及如何标注生命周期；接下来引入多生命周期标注，阐述什么时候需要标注多个生命周期。在此基础上，向前多迈一步，自定义 trait 取代分隔符的定义，让实现更加通用。最后查看标准库字符串分割的实现，综合理解本文中的所有知识点。

---

{{< toc >}}

---

## 前置要求

至少看过 [Rust The Book](https://doc.rust-lang.org/stable/book/) 前 8 章的内容。推荐的学习资料：

- [Take your first steps with Rust](https://docs.microsoft.com/en-us/learn/paths/rust-first-steps/) 微软推出的 Rust 培训课程，可以配合视频一起使用 [Rust for Beginners](https://www.youtube.com/playlist?list=PLlrxD0HtieHjbTjrchBwOVks_sr8EVW1x)
- [Rust The Book](https://doc.rust-lang.org/stable/book/) —— 第 4 章和第 10 章的内容与本文密切相关，建议重新阅读一遍
- 极客时间专栏 [陈天 · Rust 编程第一课](https://time.geekbang.org/column/intro/100085301) —— 第 7 讲 - 第 11 讲
- [Jon Gjengset](https://www.youtube.com/channel/UC_iD0xppBwwsrM9DegC5cQQ) 的 YouTube 频道，本文就是 Crust of Rust 系列 [Lifetime Annotations](https://www.youtube.com/watch?v=rAl-9HwD858&list=PLqbS7AVVErFiWDOAVrPt7aYmnuuOLYvOa&index=1&ab_channel=JonGjengset) 的学习笔记

## 快速开始

确定目标，实现字符串分割：

> input: "a b c d e" -- &str
>
> output: "a" "b" "c" "d" "e" -- 分隔符指定为空字符串，每次 next 得到一个 &str

开始一个 Rust 项目：

```bash
cargo new --lib strsplit
```

我们也可以使用 [Rust Playground](https://play.rust-lang.org/) 进行练习，文中展示的所有代码都提供了 playground 链接，点击跳转过去，Run 起来测试一下试试。

### 搭建骨架

定义数据结构和方法，添加单元测试，搭建好骨架：

```rust
pub struct StrSplit {
    remainder: &str,
    delimiter: &str,
}

impl StrSplit {
    pub fn new(haystack: &str, delimiter: &str) -> Self {
        // ....
    }
}

impl Iterator for StrSplit {
    type Item = &str;
    
    fn next(&mut self) -> Option<Self::Item> {
        // ...
    }
}

#[test]
fn it_works() {
    let haystack = "a b c d e";
    let letters: Vec<_> = StrSplit::new(haystack, " ").collect();
    assert_eq!(letters, vec!["a", "b", "c", "d", "e"]);
}
```

实现 `Iterator` trait 后，就可以使用 `for` 循环遍历对应的 struct。

### 为什么使用 &str，而不是 String？

> 当对一个知识点不熟悉时，打开 playground，写一段代码测试一下

为了方便解释，写一段代码测试一下，[代码 0，String-str-and-&str](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=d0544480827b3d414aca177e89cfaffc)：

```rust {hl_lines=[2,12,15,17]}
fn main() {
    let noodles: &'static str = "noodles";

    // String::from(noodles) 调用链路
    //  - https://doc.rust-lang.org/src/alloc/string.rs.html#2516
    //  - https://doc.rust-lang.org/src/alloc/str.rs.html#218
    //  - https://doc.rust-lang.org/src/core/str/mod.rs.html#238
    //  - https://doc.rust-lang.org/src/alloc/slice.rs.html#841
    //  - https://doc.rust-lang.org/src/alloc/slice.rs.html#474
    //  - https://doc.rust-lang.org/src/alloc/slice.rs.html#493-495
    //  - https://doc.rust-lang.org/src/alloc/string.rs.html#771
    // let poodles: String = String::from(noodles);
    // https://doc.rust-lang.org/std/primitive.str.html#method.to_string
    // noodles.to_string() 底层调用的就是 String::from(noodles);
    let poodles: String = noodles.to_string();

    let oodles: &str = &poodles[1..];

    println!("addr of {:?}: {:p}", "noodles", &"noodles");
    println!("addr of noodles: {:p}, len: {}, size: {}", &noodles,
        noodles.len(), std::mem::size_of_val(&noodles));
    println!("addr of poodles: {:p}, len: {}, cap: {}, size: {}", &poodles,
        poodles.len(), poodles.capacity(), std::mem::size_of_val(&poodles));
    println!("addr of oodles: {:p}, len: {}, size: {}", &oodles,
        oodles.len(), std::mem::size_of_val(&oodles));
}
```

`"noodles"` 作为字符串常量（string literal），编译时存入可执行文件的 .RODATA 段，程序加载时，获得一个固定的内存地址。作为一个字符串切片赋值给栈上变量 `noodles`，拥有静态生命周期（static lifetime），在程序运行期间一直有效。

当执行 `noodles.to_string()` 时，跟踪标准库实现，最后调用 `[u8]::to_vec_in()` ，在堆上分配一块新的内存，将 `"noodles"` 逐字节拷贝过去。

当把堆上的数据赋值给 `poodles` 时，`poodles` 作为栈上的一个变量，其拥有（owns）堆上数据的所有权，使用胖指针（[fat pointer](https://stackoverflow.com/questions/57754901/what-is-a-fat-pointer)）进行[表示](https://doc.rust-lang.org/std/string/struct.String.html#representation)：`ptr` 指向字符串堆内存的首地址、`length` 表示字符串当前长度、`capacity` 表示分配的堆内存总容量。

`oodles` 为字符串切片，表示对字符串某一部分（包含全部字符串）的引用（a string slice is a reference to part of a String），包含[两部分内容](https://doc.rust-lang.org/std/primitive.str.html#representation)：`ptr` 指向字符串切片首地址（可以为堆内存和 static 静态内存）、`length` 表示切片长度。

图 1 清晰展示了三者的关系：

{{< figure src="images/noodles-poodles-and-oodles.svg" caption="图 1：noodles、poodles 和 oodles" >}}

- `str` —— `[T]`，表示为一串字符序列（a sequence of characters），编译期无法确定其长度（dynamically sized）；
- `&str` —— `&[T]`，表示为一个胖指针（fat pointer），`ptr` 指向切片首地址、`length` 表示切片长度，编译期可以确定其长度为 16 字节；
- `String` —— `Vec<T>`，表示为一个胖指针（fat pointer），`ptr` 指向字符串堆内存的首地址、`length` 表示字符串当前长度、`capacity` 表示分配的堆内存总容量。堆内存支持动态扩展和收缩。编译期可以确定其长度为 24 字节。

针对分隔符 `delimiter`，如果使用 `String` 类型会存在两个问题：

1、涉及堆内存分配，开销大；

2、需进行堆内存分配，而嵌入式系统中是没有堆内存的，存在兼容性问题。

因此分隔符 `delimiter` 使用 `&str` 类型。

### Iterator trait

查看标准文档 [Iterator trait](https://doc.rust-lang.org/std/iter/trait.Iterator.html)：

```rust {hl_lines=[12]}
pub trait Iterator {
    /// The type of the elements being iterated over.
    type Item;

    // 必须实现的关联方法，被其他关联方法的缺省实现所依赖
    /// Advances the iterator and returns the next value.
    ///
    /// Returns [`None`] when iteration is finished. Individual iterator
    /// implementations may choose to resume iteration, and so calling `next()`
    /// again may or may not eventually start returning [`Some(Item)`] again at some
    /// point.
    fn next(&mut self) -> Option<Self::Item>;

    // 其他的关联方法，依赖 next 有默认实现
    fn collect<B>(self) -> B
    where
        B: FromIterator<Self::Item>,
    { ... }
    
    // ...
}
```

- 关联类型（associated types）—— `type Item;` 为迭代遍历的类型，只有实现 `Iterator` trait 时才能确定遍历的值的类型，延迟绑定；
- 方法（methods），也称关联函数（associated functions）—— 对于 `Iterator` trait，`next()` 是必须实现的（**Request methods**），存在值时，返回 `Some(item)`；不存在值时，返回 `None`。trait 中的其他方法有缺省实现。也就是说，只要实现了 `Iterator` trait 的 `next()` 方法，trait 中的其他方法就有了默认实现，可直接使用。

### 什么时候用 Self，什么时候用 self？

- `Self` 表示当前类型，比如 `StrSplit` 类型实现 `Iterator` trait，实现时使用的 `Self` 就指代 `StrSplit` 类型；
- `self` 在用作方法的第一个参数时，实际上就是 `self: Self`（参数名: 参数类型）的简写，所以 `&self` 是 `self: &Self`，而 `&mut self` 是 `self: &mut Self`。

因此 `Iterator` trait 的 `next()` 签名展开为：

```rust {hl_lines=["4-5"]}
pub trait Iterator {
    type Item;

    // fn next(&mut self) -> Option<Self::Item>;
    fn next(self: &mut Self) -> Option<Self::Item>;
}
```

## version #1: hands on

让我们直接开始吧，[代码 1，version #1: hands-on](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=0ef8d7450128be332ef3861486f1eb0b)：

```rust {hl_lines=["19-22"]}
pub struct StrSplit {
    remainder: &str,
    delimiter: &str,
}

impl StrSplit {
    pub fn new(haystack: &str, delimiter: &str) -> Self {
        Self {
            remainder: haystack,
            delimiter,
        }
    }
}

impl Iterator for StrSplit {
    type Item = &str;

    fn next(&mut self) -> Option<Self::Item> {
        if let Some(next_delim) = self.remainder.find(self.delimiter) {
            let until_delimiter = &self.remainder[..next_delim];
            self.remainder = &self.remainder[(next_delim + self.delimiter.len())..];
            Some(until_delimiter)
        } else if self.remainder.is_empty() {
            None
        } else {
            let rest = self.remainder;
            self.remainder = "";
            Some(rest)
        }
    }
}

#[test]
fn it_works() {
    let haystack = "a b c d e";
    let letters: Vec<_> = StrSplit::new(haystack, " ").collect();
    assert_eq!(letters, vec!["a", "b", "c", "d", "e"]);
}
```

`next()` 的实现很简单：

1、在字符串中查找分隔符第一次出现的位置，如果找到返回索引值 `Some(usize)`，未找到返回 `None`；

2、根据索引值将字符串分为三个部分，第一部分为 `next()` 的返回值，第二部分为分隔符，第三部分为剩余待处理的字符串，为下一次调用 `next()` 的原始字符串。

编译，报错信息：

```bash
   Compiling playground v0.0.1 (/playground)
error[E0106]: missing lifetime specifier
 --> src/lib.rs:2:16
  |
2 |     remainder: &str,
  |                ^ expected named lifetime parameter
  |
help: consider introducing a named lifetime parameter
  |
1 ~ pub struct StrSplit<'a> {
2 ~     remainder: &'a str,
  |

error[E0106]: missing lifetime specifier
 --> src/lib.rs:3:16
  |
3 |     delimiter: &str,
  |                ^ expected named lifetime parameter
  |
help: consider introducing a named lifetime parameter
  |
1 ~ pub struct StrSplit<'a> {
2 |     remainder: &str,
3 ~     delimiter: &'a str,
  |

error[E0106]: missing lifetime specifier
  --> src/lib.rs:16:17
   |
16 |     type Item = &str;
   |                 ^ expected named lifetime parameter
   |
help: consider introducing a named lifetime parameter
   |
16 |     type Item<'a> = &'a str;
   |              ++++    ++

For more information about this error, try `rustc --explain E0106`.
```

三个错误信息都提示缺少生命周期标注（lifetime specifier），编译器建议添加生命周期参数（lifetime parameter），因此在 version #1 上添加生命周期标注。

> 错误代码 `E0106` 使用 `rustc --explain E0106` 探索更详细的信息，可以在浏览器中搜索 [Rust E0106](https://doc.rust-lang.org/error-index.html#E0106)，也可以直接在命令行中查看，使用 playground 运行可以直接点击 `[E0106]` 跳转到错误说明。
>
> E0106 错误可以分为两大类：
>
> - 数据结构缺少生命周期标注（a lifetime is missing from a type）—— 使用数据结构时，数据结构自身的生命周期，需小于等于数据结构内部所有引用类型字段的生命周期；
> - 函数签名缺少生命周期标注，即使编译器执行生命周期自动标注，也无能为力（If it is an error inside a function signature, the problem may be with failing to adhere to the lifetime elision rules）。
>
> 编译器会通过一些简单的[规则](https://doc.rust-lang.org/book/ch10-03-lifetime-syntax.html#lifetime-elision)，自动添加生命周期标注：
>
> 1. 所有引用类型参数都有独立的生命周期 `'a`、`'b`（a reference gets its own lifetime parameter）；
> 2. 如果入参只有一个引用类型，它的生命周期会赋给所有输出参数（if there is exactly one input lifetime parameter, that lifetime is assigned to all output lifetime parameters）；
> 3. 如果入参有多个引用类型参数，其中一个是 `self`（作为数据结构的方法，第一个参数是 `&self` / `&mut self`），那么 `self` 的生命周期会赋给所有输出参数（if there are multiple input lifetime parameters, but one of them is `&self` or `&mut self` because this is a method, the lifetime of `self` is assigned to all output lifetime parameters）。

## version #2: add lifetime specifier

在 playground 中多次编译，根据编译器给到的错误信息补充生命周期标注，直至编译成功，[代码 2，version #2: add-lifetime-specifier](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=d8a19f669b68a566912160e0e69ca7f4)：

```rust {hl_lines=["1-4","6-7","15-16"]}
pub struct StrSplit<'a> {
    remainder: &'a str,
    delimiter: &'a str,
}

impl<'a> StrSplit<'a> {
    pub fn new(haystack: &'a str, delimiter: &'a str) -> Self {
        Self {
            remainder: haystack,
            delimiter,
        }
    }
}

impl<'a> Iterator for StrSplit<'a> {
    type Item = &'a str;

    fn next(&mut self) -> Option<Self::Item> {
        if let Some(next_delim) = self.remainder.find(self.delimiter) {
            let until_delimiter = &self.remainder[..next_delim];
            self.remainder = &self.remainder[(next_delim + self.delimiter.len())..];
            Some(until_delimiter)
        } else if self.remainder.is_empty() {
            None
        } else {
            let rest = self.remainder;
            self.remainder = ""; // -- caution
            // &'a str  -----   &'static str
            Some(rest)
        }
    }
}

#[test]
fn it_works() {
    let haystack = "a b c d e";
    let letters: Vec<_> = StrSplit::new(haystack, " ").collect();
    assert_eq!(letters, vec!["a", "b", "c", "d", "e"]);
}
```

### 数据结构的生命周期标注

当 struct 包含引用类型参数时，需在 [定义 struct 时添加生命周期标注](https://doc.rust-lang.org/book/ch10-03-lifetime-syntax.html#lifetime-annotations-in-struct-definitions) —— 与声明泛型数据类型（generic data types）的语法一致 —— 在 struct 名称后的尖括号内声明泛型生命周期参数（generic lifetime parameter），这样在 struct 定义中就可以使用这个范型生命周期参数标注生命周期。例如 `remainder` 和 `delimiter` 是两个字符串引用，`StrSplit` 的生命周期不能大于它们，否则会访问失效的内存，因此需进行生命周期标注。

```rust {hl_lines=[1]}
pub struct StrSplit<'a> {
    remainder: &'a str,
    delimiter: &'a str,
}
```

使用数据结构时，数据结构自身的生命周期，需小于等于数据结构内部所有引用类型字段的生命周期

实现数据结构时，由于 `impl block` 和 struct 生命周期参数是分隔开的，需要为 `impl block` 添加上生命周期参数（[E0261](https://doc.rust-lang.org/stable/error-index.html#E0261)），例如：

```rust {hl_lines=[7]}
pub struct StrSplit<'a> {
    remainder: &'a str,
    delimiter: &'a str,
}

// error[E0261]: use of undeclared lifetime name `'a`
impl StrSplit<'a> {
    pub fn new(haystack: &'a str, delimiter: &'a str) -> Self {
        Self {
            remainder: haystack,
            delimiter,
        }
    }
}
```

为 `impl block` 添加上生命周期参数即可修复：

```rust {hl_lines=[7]}
pub struct StrSplit<'a> {
    remainder: &'a str,
    delimiter: &'a str,
}

// correct
impl<'a> StrSplit<'a> {
    pub fn new(haystack: &'a str, delimiter: &'a str) -> Self {
        Self {
            remainder: haystack,
            delimiter,
        }
    }
}
```

同理，也适用于 `impl<'a> Iterator for StrSplit<'a>`。

### 函数签名的生命周期标注

使用 `new()` 作为例子：

```rust {hl_lines=[8]}
pub struct StrSplit<'a> {
    remainder: &'a str,
    delimiter: &'a str,
}

impl<'a> StrSplit<'a> {
    // 去掉入参的生命周期标注
    pub fn new(haystack: &str, delimiter: &str) -> Self {
        Self {
            remainder: haystack,
            delimiter,
        }
    }
}
```

将 `Self` 简写展开：

```rust {hl_lines=[7]}
pub struct StrSplit<'a> {
    remainder: &'a str,
    delimiter: &'a str,
}

impl<'a> StrSplit<'a> {
    pub fn new(haystack: &str, delimiter: &str) -> StrSplit<'a> {
        StrSplit {
            remainder: haystack,
            delimiter,
        }
    }
}
```

函数返回值的生命周期为 `'a`，而两个入参的生命周期与 `'a` 的关系却未可知，可能在后续使用 `StrSplit struct` 时包含的两个字段 `remainder` 和 `delimiter`已经被释放，出现 use after free。因此需使用生命周期参数约束入参与入参之间、入参与返回值之间的关系。

```rust {hl_lines=[2]}
impl<'a> StrSplit<'a> {
    pub fn new(haystack: &'a str, delimiter: &'a str) -> StrSplit<'a> {
        StrSplit {
            remainder: haystack,
            delimiter,
        }
    }
}
```

### Static lifetime

`next()` 实现中的 `else block` 执行了一个赋值操作：

```rust {hl_lines=[1]}
    self.remainder = "";
```

等号左侧为 `&'a str`，等号右侧 `""` 为字符串字面量 —— 上文讲到，字符串字面量拥有静态生命周期（static lifetime），用 `&'static str` 表示。将 `&'static str` 赋值给 `&'a str`，长生命周期的值赋值给短的生命周期（subtyping system）。

### 增加一个以分隔符结尾的单元测试

增加一个单元测试，以分隔符结尾，测试报错，[代码 3，tail-test-error](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=c0d8920958af15ccb571d6d562ef59c8)。

```rust {hl_lines=[3]}
#[test]
fn tail_test() {
    let haystack = "a b c d ";
    let letters: Vec<_> = StrSplit::new(haystack, " ").collect();
    assert_eq!(letters, vec!["a", "b", "c", "d", ""]);
}
```

为什么会报错呢？

[代码 3，tail-test-error](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=c0d8920958af15ccb571d6d562ef59c8) 中，增加 3 处 print 打印，同时修改第一个测试使之报错。

```bash {hl_lines=[8,15]}
---- it_works stdout ----
1-remainder = "a b c d e f"
1-remainder = "b c d e f"
1-remainder = "c d e f"
1-remainder = "d e f"
1-remainder = "e f"
3-remainder = "f"
2-remainder = ""

---- tail_test stdout ----
1-remainder = "a b c d "
1-remainder = "b c d "
1-remainder = "c d "
1-remainder = "d "
2-remainder = ""
```

观察 print 输出的信息，两个测试用例都在 `self.remainder.is_empty()` 分支结束执行：

1. 正常测试用例 `"a b c d e f"`，在处理到 `"f"` 时，调用 `next()` 返回 `"f"`，没有剩余待处理的字符串，按照目前的实现，将剩余字符串设置为空字符串（[代码 3，tail-test-error](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=c0d8920958af15ccb571d6d562ef59c8)，line 30）；
2. 分隔符结尾的测试用例 `"a b c d "`，在处理到 `"d "` 时，调用 `next()` 返回 `"d"`，剩余待处理字符串为空字符串，需要下一次调用 `next()` 时进行处理。

测试用例 1 和测试用例 2 都进入到 `self.remainder.is_empty()` 分支，目前的实现是直接返回 `None`，满足测试用例 1，不满足测试用例 2（二者不能同时满足）。

应该如何处理空字符串呢？

- 测试用例 1，处理完 `"f"` 后，没有剩余待处理的字符串 —— 使用 `None` 表示；
- 测试用例 2，处理完 `"d"` 后，还有一个空字符串待处理 —— 使用 `Some("")` 表示。

## version #3: fix tail delimiter

将 `reminder` 定义为 `Option<&'a str>` 类型，[代码 4，define-remainder-with-Option](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=24b70fb2b35be8dc0896373dd70983d1)：

- `Some("xxx")` —— 仍有待处理的字符串，包括空字符串；
- `None` —— 没有剩余待处理的字符串。

```rust {hl_lines=[2,"21-27",32,35]}
pub struct StrSplit<'a> {
    remainder: Option<&'a str>,
    delimiter: &'a str,
}

impl<'a> StrSplit<'a> {
    pub fn new(haystack: &'a str, delimiter: &'a str) -> Self {
        Self {
            remainder: Some(haystack),
            delimiter,
        }
    }
}

impl<'a> Iterator for StrSplit<'a> {
    type Item = &'a str;

    fn next(&mut self) -> Option<Self::Item> {
        // &mut &'a str ----------- Option<&'a str>
        // 匹配 self.remainder == Some("xxx")，同时获取 val 的可变借用
        if let Some(ref mut remainder) = self.remainder {
            if let Some(next_delim) = remainder.find(self.delimiter) {
                let until_delimiter = &remainder[..next_delim];
                // left without *  - &mut &'a str
                // right - &'a str
                *remainder = &remainder[(next_delim + self.delimiter.len())..];
                Some(until_delimiter)
            } else {
                // https://doc.rust-lang.org/std/option/enum.Option.html#method.take
                // impl<T> Option<T> { fn take(&mut self) -> Option<T> }
                // Takes the value out of the option, leaving a None in its place.
                self.remainder.take()
            }
        } else {
            None
        }
    }
}

#[test]
fn it_works() {
    let haystack = "a b c d e";
    let letters: Vec<_> = StrSplit::new(haystack, " ").collect();
    assert_eq!(letters, vec!["a", "b", "c", "d", "e"]);
}

#[test]
fn tail_test() {
    let haystack = "a b c d ";
    let letters: Vec<_> = StrSplit::new(haystack, " ").collect();
    assert_eq!(letters, vec!["a", "b", "c", "d", ""]);
}
```

修改后的 `next()` 实现逻辑如下：

1、首先执行模式匹配，如果仍有待处理的字符串，即 `Some("xxx")`，匹配待处理的字符串，记为 `remainder`；

2、在待处理的字符串中查找分隔符，

- 存在分隔符，获取分隔符第一次出现的索引，按照索引将字符串分为三个部分，第一部分为此次 `next()` 调用的返回值，第二部分为分隔符，第三部分为下一次调用 `next()` 时待处理的字符串（即此次调用需要更新待处理的字符串）；
- 不存在分隔符，直接返回待处理的字符串；并设置剩余待处理字符串为 `None`（表示没有剩余待处理的字符串），下一次调用 `next()` 时直接返回 `None`；

3、如果没有待处理的字符串，直接返回 `None`。

### ref mut

`ref` 和 `mut` 为 [Identifier patterns](https://doc.rust-lang.org/reference/patterns.html#identifier-patterns) 的关键字：

```rust
IdentifierPattern :
      ref? mut? IDENTIFIER (@ Pattern ) ?
```

写一段代码测试一下 `ref mut` 的使用，[代码 5，ref-mut](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=acefdddc07fe240e215816c10ab7c797)：

```rust
fn main() {
    let name = String::from("qiaoin");
    let gender = String::from("Male");
    let mut age = 27;
    
    age = 28;
    println!("name = {:?}, gender = {:?}, age = {:?}", name, gender, age);
    
    // String doesn't impl Copy trait, ownship moved here
    let mut own_name = name;
    println!("own_name = {:?}, gender = {:?}, age = {:?}", own_name, gender, age);
    // 可以将注释删除，编译看一下具体的错误信息
    // error, borrowed after move
    // println!("name = {:?}, gender = {:?}, age = {:?}", name, gender, age);
    
    // A `ref` borrow on the left side of an assignment is equivalent to
    // an `&` borrow on the right side.
    let ref ref_g1 = gender;
    let ref_g2 = &gender;
    println!("own_name = {:?}, ref_g1 = {:?}, age = {:?}", own_name, ref_g1, age);
    println!("own_name = {:?}, ref_g2 = {:?}, age = {:?}", own_name, ref_g2, age);
    println!("ref_g1 equal ref_g2 = {}", *ref_g1 == *ref_g2);
    println!("own_name = {:?}, gender = {:?}, age = {:?}", own_name, gender, age);
    
    // borrowed as mutable
    let ref mut mut_ref_n = own_name;
    println!("own_name = {:?}, gender = {:?}, age = {:?}", mut_ref_n, gender, age);
    *mut_ref_n = String::from("桥");
    println!("own_name = {:?}, gender = {:?}, age = {:?}", mut_ref_n, gender, age);
    // 其后，mut_ref_n 就不是活跃的 mutable borrowed
    
    // 因此可以在这里访问 immutable borrowed
    println!("own_name = {:?}, gender = {:?}, age = {:?}", own_name, gender, age);

    // borrowed as mutable
    let mut_ref_n2 = &mut own_name;
    *mut_ref_n2 = String::from("qiaoin");
    println!("own_name = {:?}, gender = {:?}, age = {:?}", mut_ref_n2, gender, age);
}
```

- 在等号左侧使用 `ref` 不可变借用 === 在等号右侧使用 `&` 不可变借用
- 在等号左侧使用 `ref mut` 可变借用 === 在等号右侧使用 `&mut` 可变借用

既然两者直接等价，为什么还需要 `ref` 关键字呢？

`ref` 主要使用在模式匹配（pattern matching）中（`let` / `match`），对匹配到的值执行借用（borrow），而不是 `copy` 或者 `move` 匹配到的值（根据匹配值的类型是否实现了 `Copy` trait）。

应用于模式匹配语句时，`ref`  与 `&` 的比较如下（[ref keyword](https://doc.rust-lang.org/std/keyword.ref.html)）：

- `ref` 不作为模式的一部分，不影响值是否匹配，只影响匹配到的值作为借用在 scope 中使用，因此 `Foo(ref foo)` 和 `Foo(foo)` 两个模式匹配相同的对象；
- `&` 作为模式的一部分，表示待匹配的模式要求为一个对象的引用，因此 `&Foo` 和 `Foo` 两个模式匹配不同的对象。

假设去掉 `ref mut`，则后续不能修改。

```rust
if let Some(remainder) = self.remainder {
    // can't mutable ... 
}
```

假设使用 `&mut` 进行模式匹配，则右侧类型需要为 `Option<&mut T>`，匹配后 `remainder` 的类型为 `T`，依然不能修改。

```rust
if let Some(&mut remainder) = self.remainder {
    // can't mutable ...
}
```

### version #3.1 use ? operator

`next()` 实现中有以下的一段代码：

```rust {hl_lines=["5-9"]}
impl<'a> Iterator for StrSplit<'a> {
    type Item = &'a str;

    fn next(&mut self) -> Option<Self::Item> {
        if let Some(ref mut remainder) = self.remainder {
            // do something
        } else {
            None
        }
    }
}
```

- `self.remainder` 为 `Some(val)` 时，匹配 `val`，得到其可变引用，继续后续操作；
- `self.remainder` 为 `None` 时，直接返回 `None`。

可以使用 `?` 操作符实现相同逻辑。写一段代码测试 `?` 操作符，[代码 6，?-operator](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=9cab033571d766a16164c7b27d7d5c4c)：

```rust {hl_lines=[10,19]}
fn main() {
    if complex_function().is_none() {
        println!("X not exists!");
    }
}

fn complex_function() -> Option<&'static str> {
    // 末尾使用 ? operator
    // 如果是 None, 直接返回；如果是 Some("abc"), set x to "abc"
    let x = get_an_optional_value()?;

    println!("{}", x); // "abc" ; if you change line 19 `false` to `true`

    Some("")
}

fn get_an_optional_value() -> Option<&'static str> {
    // if the optional value is not empty
    if false {
        return Some("abc");
    }

    // else
    None
}
```

如何替换 `ref mut` 的模式匹配呢？本质问题为如何做类型的转换，将类型 `&mut Option<&'a str>` 转换为类型 `Option<&mut &'a str>` —— `Option::as_mut()` 可以完成这个类型转换。因此，修改后得到如下实现，[代码 7，version #3.1 use-?-operator](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=083328cfac596d53749413246fa3db2b)：

```rust {hl_lines=[10]}
impl<'a> Iterator for StrSplit<'a> {
    type Item = &'a str;

    fn next(&mut self) -> Option<Self::Item> {
        // https://doc.rust-lang.org/std/option/enum.Option.html#method.as_mut
        // impl<T> Option<T> { fn as_mut(&mut self) -> Option<&mut T> }
        // self.remainder --- &mut Option<&'a str>
        // self.remainder.as_mut() --- Option<&mut &'a str>
        // self.remainder.as_mut()? --- if Some("xxx"), type is &mut &'a str
        let remainder = self.remainder.as_mut()?;
        if let Some(next_delim) = remainder.find(self.delimiter) {
            let until_delimiter = &remainder[..next_delim];
            // left without *  - &mut &'a str
            // right - &'a str
            *remainder = &remainder[(next_delim + self.delimiter.len())..];
            Some(until_delimiter)
        } else {
            // https://doc.rust-lang.org/std/option/enum.Option.html#method.take
            // impl<T> Option<T> { fn take(&mut self) -> Option<T> }
            self.remainder.take()
        }
    }
}
```

## version #4: multiple lifetimes

### already done？

思考一个问题，`remainder` 和 `delimiter` 需要为相同的生命周期吗？

看下面一个例子，现在有一个函数使用 `StrSplit` 提供的字符串分割能力，其对外 API 使用 `char` 作为分隔符，因此在调用 `StrSplit` 前需转换 `char` 类型到 `&str` 类型，[代码 8，char-delimiter-test-error](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=5b529c238e753c03465a6ef7982068ed)）：

```rust {hl_lines=["2-3"]}
pub fn until_char(s: &str, c: char) -> &str {
    let delim = format!("{}", c);
    StrSplit::new(s, &delim)
        .next()
        .expect("StrSplit should have at least one result")
}

#[test]
fn test_until_char() {
    assert_eq!(until_char("hello, world", 'r'), "hello, wo");
}
```

编译，报错信息：

```bash
   Compiling playground v0.0.1 (/playground)
error[E0515]: cannot return value referencing local variable `delim`
  --> src/lib.rs:41:5
   |
41 |       StrSplit::new(s, &delim)
   |       ^                ------ `delim` is borrowed here
   |  _____|
   | |
42 | |         .next()
43 | |         .expect("StrSplit should have at least one result")
   | |___________________________________________________________^ returns 
      a value referencing data owned by the current function

For more information about this error, try `rustc --explain E0515`.
```

同样，查看 [E0515](https://doc.rust-lang.org/stable/error-index.html#E0515) 获取更多信息，但这里的解决方案需要从根本上去分析。

回到本小节开头的问题 —— `remainder` 和 `delimiter` 需要为相同的生命周期吗？`StrSplit` 执行字符串分割得到的返回值应该与待处理字符串 `remainder` 的生命周期保持一致，与分隔符 `delimiter` 的生命周期没有直接关系。

在目前的实现中，`struct StrSplit` 仅声明了一个生命周期参数 `'a`，`remainder` 和 `delimiter` 拥有相同的生命周期约束。同时，在实现 `Iterator` trait 时，返回值的生命周期与 `remainder` 的生命周期保持一致，也是 `'a`。

`until_char()` 中，传递给 `StrSplit::new(s, &delim)` 的两个参数拥有不同的生命周期：

- `delim` 的生命周期为当前函数体；执行完函数后，会 Drop 掉；
- `s` 的生命周期 >= `delim` 的生命周期。

由于 `struct StrSplit` 定义时将两个成员标注为相同的生命周期，此时，编译器认为 `s` 和临时变量 `delim` 应该拥有相同的生命周期，会将长的生命周期（longer lifetime）转化为短的生命周期（shorter lifetime）。在 `until_char()` 返回时，返回的引用的生命周期与 `delim` 临时变量的生命周期相绑定（也即与函数 `until_char()` 的生命周期相绑定），而临时变量的生命周期会在函数执行完后被 Drop 掉，因此编译器给到报错。

基于以上分析，`until_char()` 函数返回的引用的生命周期应该与待处理的字符串引用的生命周期相绑定，期望的签名如下：

```rust
fn until_char<'s>(s: &'s str, c: char) -> &'s str {}
//                     ^                    ^
//                     |                    |
//          待处理的字符串引用的生命周期    返回的引用的生命周期
```

### add multiple lifetime

`struct StrSplit` 定义的两个成员，使用不同的生命周期参数进行标注，[代码 9，add-multiple-lifetime](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=646edaa857f6298a7c4b38dc507a5be3)：

```rust {hl_lines=["1-4","6-7","15-16"]}
pub struct StrSplit<'haystack, 'delimiter> {
    remainder: Option<&'haystack str>,
    delimiter: &'delimiter str,
}

impl<'haystack, 'delimiter> StrSplit<'haystack, 'delimiter> {
    pub fn new(haystack: &'haystack str, delimiter: &'delimiter str) -> Self {
        Self {
            remainder: Some(haystack),
            delimiter,
        }
    }
}

impl<'haystack, 'delimiter> Iterator for StrSplit<'haystack, 'delimiter> {
    type Item = &'haystack str;

    fn next(&mut self) -> Option<Self::Item> {
        let remainder = self.remainder.as_mut()?;
        if let Some(next_delim) = remainder.find(self.delimiter) {
            let until_delimiter = &remainder[..next_delim];
            *remainder = &remainder[(next_delim + self.delimiter.len())..];
            Some(until_delimiter)
        } else {
            self.remainder.take()
        }
    }
}

fn until_char(s: &str, c: char) -> &str {
    let delim = format!("{}", c);  // 每次构造 delimiter 都需要进行一次堆上的内存分配
    StrSplit::new(s, &delim)
        .next()
        .expect("StrSplit should have at least one result")
}

#[test]
fn test_until_char() {
    assert_eq!(until_char("hello, world", 'r'), "hello, wo");
}
```

至此，我们就正确实现了字符串分割的功能。目前的实现中，`delimiter` 是一个 `&str` 类型的分隔符；我们希望更通用一些（anything can find itself in a str）。

## version #5: generic delimiter

明确目标：按照分隔符对目标字符串进行分割

- 操作的对象 —— 字符串；
- 分割字符串 —— 根据分隔符将目标字符串分割为三个部分；

```bash
     xxxxxxxxxxxxxxx1xxxxxxx3xxx4xxxxx6xxxx8x
     first part     ^     third part
                    |
                second part
```

- 索引值 —— 至少需要两个索引值将目标字符串分割为三个部分，1）分隔符的开始索引，2）分隔符的结束索引+1（为了方便处理，类似编程语言中的 `end()` 指向最后一个元素的下一个位置）；如果分隔符长度固定，可以只需要一个索引值，但考虑分隔符可能为正则表达式，可以匹配不同长度的分隔符，因此确定为两个索引值。

### 使用 trait 定义分隔符

> how to use *traits* to define behavior in a generic way

```rust {hl_lines=[5]}
pub trait Delimiter {
    // 在字符串中查找分隔符 self
    // 1）找到，返回 (分隔符的开始索引, 分隔符的结束索引+1)
    // 2）未找到，返回 None
    fn find_next(&self, s: &str) -> Option<(usize, usize)>;
}
```

`StrSplit` 的 `delimiter` 成员，实现 `Delimiter` trait：

```rust {hl_lines=[3]}
pub struct StrSplit<'haystack, D> {
    remainder: Option<&'haystack str>,
    delimiter: D,
}

impl<'haystack, D> StrSplit<'haystack, D> {
    pub fn new(haystack: &'haystack str, delimiter: D) -> Self {
        Self {
            remainder: Some(haystack),
            delimiter,
        }
    }
}
```

### 为不同的分隔符类型实现 Delimiter trait

- `&str` 实现 `Delimiter` trait

```rust {hl_lines=[2]}
impl Delimiter for &str {
    // self: &Self 
    // self: &&str
    fn find_next(&self, s: &str) -> Option<(usize, usize)> {
        s.find(self).map(|start| (start, start + self.len()))
    }
    // &str.find(&&str)
}
```

- `char` 实现 `Delimiter` trait

```rust {hl_lines=[2]}
impl Delimiter for char {
    fn find_next(&self, s: &str) -> Option<(usize, usize)> {
        s.char_indices()
            .find(|(_, c)| c == self)
            .map(|(start, _)| (start, start + self.len_utf8()))
    }
}
```

更多其他类型均可以按需实现。

### str::find & Option::map

`&str` 实现 `Delimiter` trait 时，`s.find(self)` 传入的是一个字符串；而 `char` 实现 `Delimiter` trait 时，`s.char_indices().find(|(_, c)| c == self)` 传入的是一个闭包（closure）。看一下 `str::find()` 的函数签名：

```rust
pub fn find<'a, P>(&'a self, pat: P) -> Option<usize>
where
    P: Pattern<'a>, 
```

实现功能为：在字符串中搜索匹配的 `Pattern`，返回匹配到的字符串的开始索引 `Some(usize)`；未找到，返回 `None`。`Pattern` trait 的讨论在本文的最后一节。

结合 `Option::map` 对匹配的结果进行转换：

- `Some(usize)` —— 匹配分隔符的开始索引，apply 闭包，得到 `Some(分隔符开始索引, 分隔符结束索引+1)`；
- `None` —— 返回 `None`。

### 最终代码实现

完整的代码如下，[代码 10，StrSplit-final-implementation](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=6dbcb7c0a283387d922d189b683b4a1d)：

```rust
pub struct StrSplit<'haystack, D> {
    remainder: Option<&'haystack str>,
    delimiter: D,
}

impl<'haystack, D> StrSplit<'haystack, D> {
    pub fn new(haystack: &'haystack str, delimiter: D) -> Self {
        Self {
            remainder: Some(haystack),
            delimiter,
        }
    }
}

pub trait Delimiter {
    // 在字符串中查找分隔符 self
    // 1）找到，返回 (分隔符的开始索引, 分隔符的结束索引+1)
    // 2）未找到，返回 None
    fn find_next(&self, s: &str) -> Option<(usize, usize)>;
}

impl Delimiter for &str {
    fn find_next(&self, s: &str) -> Option<(usize, usize)> {
        s.find(self).map(|start| (start, start + self.len()))
    }
}

impl Delimiter for char {
    fn find_next(&self, s: &str) -> Option<(usize, usize)> {
        s.char_indices()
            .find(|(_, c)| c == self)
            .map(|(start, _)| (start, start + self.len_utf8()))
    }
}

impl<'haystack, D> Iterator for StrSplit<'haystack, D>
where
    D: Delimiter,
{
    type Item = &'haystack str;

    fn next(&mut self) -> Option<Self::Item> {
        // https://doc.rust-lang.org/std/option/enum.Option.html#method.as_mut
        // impl<T> Option<T> { fn as_mut(&mut self) -> Option<&mut T> }
        // self.remainder --- &mut Option<&'a str>
        // self.remainder.as_mut() --- Option<&mut &'a str>
        // self.remainder.as_mut()? --- if Some("xxx"), type is &mut &'a str
        let remainder = self.remainder.as_mut()?;
        if let Some((delim_start,delim_end)) = self.delimiter.find_next(remainder){
            let until_delimiter = &remainder[..delim_start];
            // left without *  - &mut &'a str
            // right - &'a str
            *remainder = &remainder[delim_end..];
            Some(until_delimiter)
        } else {
            // https://doc.rust-lang.org/std/option/enum.Option.html#method.take
            // impl<T> Option<T> { fn take(&mut self) -> Option<T> }
            self.remainder.take()
        }
    }
}

fn until_char(s: &str, c: char) -> &str {
    StrSplit::new(s, c)
        .next()
        .expect("StrSplit should have at least one result")
}

#[test]
fn test_until_char() {
    assert_eq!(until_char("hello, world", 'r'), "hello, wo");
}

#[test]
fn it_works() {
    let haystack = "a b c d e";
    let letters: Vec<_> = StrSplit::new(haystack, " ").collect();
    assert_eq!(letters, vec!["a", "b", "c", "d", "e"]);
}

#[test]
fn tail_test() {
    let haystack = "a b c d ";
    let letters: Vec<_> = StrSplit::new(haystack, " ").collect();
    assert_eq!(letters, vec!["a", "b", "c", "d", ""]);
}
```

至此，我们实现了 `StrSplit`，支持自定义 `Delimiter`（为分隔符类型实现 `Delimiter` trait）🎉🎉🎉。

## 标准库 str::split

标准库 `str::split` 实现，[str - split](https://doc.rust-lang.org/std/primitive.str.html#method.split)

```rust
pub fn split<'a, P>(&'a self, pat: P) -> Split<'a, P>
where
    P: Pattern<'a>, 
```

### pat 为 &str 类型时，split() 完整的调用链路

测试代码：

```rust
fn main() {
    let mut a = "hello world".split(" ");
    let b = a.next();
    println!("{:?}", b);  // Some("hello")
}
```

1、`"hello world".split(" ")` 调用 `str::split()` 返回 `Split struct`

```rust {hl_lines=[3]}
// https://doc.rust-lang.org/src/core/str/mod.rs.html#1217
pub fn split<'a, P: Pattern<'a>>(&'a self, pat: P) -> Split<'a, P> {
    Split(SplitInternal {
        start: 0,
        end: self.len(),
        matcher: pat.into_searcher(self),  // StrSearcher
        allow_trailing_empty: true,
        finished: false,
    })
}
```

2、`a.next()` 返回匹配的字符串，查看 `impl<'a, P> Iterator for Split<'a, P>` 的 `next()` 实现

```rust {hl_lines=["9-12"]}
// 宏定义 https://doc.rust-lang.org/src/core/str/iter.rs.html#450
// Split struct 定义 https://doc.rust-lang.org/src/core/str/iter.rs.html#733
impl<'a, P> Iterator for Split<'a, P>
where
    P: Pattern<'a>,
{
    type Item = &'a str;

    pub fn next(&mut self) -> Option<&'a str> {
        // self.0 ---- core::str::iter::SplitInternal<'_, &str>
        self.0.next()
    }
}
```

3、调用 `SplitInternal::next()`

```rust {hl_lines=[3]}
// https://doc.rust-lang.org/src/core/str/iter.rs.html#599
impl<'a, P: Pattern<'a>> SplitInternal<'a, P> {
    fn next(&mut self) -> Option<&'a str> {
        if self.finished {
            return None;
        }

        let haystack = self.matcher.haystack();
        match self.matcher.next_match() {
            // SAFETY: `Searcher` guarantees that `a` and `b` lie on unicode
            // boundaries.
            Some((a, b)) => unsafe {
                let elt = haystack.get_unchecked(self.start..a);
                self.start = b;
                Some(elt)
            },
            None => self.get_end(),  // 将 self.finished 设置为 true，下一次调用返回 None
        }
    }
}
```

- 测试代码 `"hello world".split(" ")` 返回 `Split struct`，其中 `matcher: pat.into_searcher(self)`，通过 `Pattern::into_searcher` 作为构造器去构造出一个 `StrSearcher`

```rust {hl_lines=[4,"11-13"]}
// https://doc.rust-lang.org/src/core/str/pattern.rs.html#91-155
pub trait Pattern<'a> {
    type Searcher: Searcher<'a>;
    fn into_searcher(self, haystack: &'a str) -> Self::Searcher;
}

// https://doc.rust-lang.org/src/core/str/pattern.rs.html#862-904
impl<'a, 'b> Pattern<'a> for &'b str {
    type Searcher = StrSearcher<'a, 'b>;

    fn into_searcher(self, haystack: &'a str) -> StrSearcher<'a, 'b> {
        StrSearcher::new(haystack, self)  // haystack --- "hello world"; self -- " "
    }
}
```

- `self.matcher.haystack()` 获取待处理的字符串；
- `self.matcher.next_match()` 获取匹配到 `""`  的起始索引 `(start_match, end_match)` ——（详细实现就不贴了，有兴趣的同学可以查看 [Search trait 的文档说明](https://doc.rust-lang.org/std/str/pattern/trait.Searcher.html#method.next_match)）—— 其中 `start_match` 表示 Pattern 的开始索引，`end_match` 表示 Pattern 的结束索引+1；
- `Some((a, b))` 匹配后，将匹配到的字符串返回，同时修改待处理字符串的 `start` 索引；

```rust
pub unsafe trait Searcher<'a> {
    // Required methods
    fn haystack(&self) -> &'a str;
    fn next(&mut self) -> SearchStep;

    // Provided methods
    fn next_match(&mut self) -> Option<(usize, usize)> { ... }
    fn next_reject(&mut self) -> Option<(usize, usize)> { ... }
}

// https://doc.rust-lang.org/src/core/str/pattern.rs.html#962-1050
unsafe impl<'a, 'b> Searcher<'a> for StrSearcher<'a, 'b> {
    fn haystack(&self) -> &'a str {
        self.haystack  // first call, return "hello world"
    }
    
    fn next(&mut self) -> SearchStep { ... }

    fn next_match(&mut self) -> Option<(usize, usize)> { ... }
}
```

实现逻辑都是围绕一个 struct（`Split struct`）和两个 traits（`Pattern` trait 和 `Search` trait）。

### Split struct

`Split struct` 使用 [宏进行实现](https://doc.rust-lang.org/src/core/str/iter.rs.html#728-744)，[宏定义](https://doc.rust-lang.org/src/core/str/iter.rs.html#450) 中实现了 `Iterator` trait（还实现了 `DoubleEndedIterator` trait 和 `FusedIterator` trait，暂不讨论），因此测试代码中可以 `a.next()` 进行调用。

```rust
pub struct Split<'a, P>(_)
 where
    P: Pattern<'a>;

impl<'a, P: Pattern<'a>> Split<'a, P> {
    /// Returns remainder of the splitted string 返回剩余待处理的字符串
    pub fn as_str(&self) -> &'a str {
        self.0.as_str()
    }
}

impl<'a, P> Iterator for Split<'a, P>
where
    P: Pattern<'a>,
{
    type Item = &'a str;
    
    pub fn next(&mut self) -> Option<&'a str> {
        self.0.next()
    }
}
```

### Pattern trait

[Pattern trait](https://doc.rust-lang.org/std/str/pattern/trait.Pattern.html)（类似我们定义的 `Delimiter` trait，但 `Pattern` trait 实现更复杂一些）包含一个关联类型 `type Searcher`，`into_searcher` 作为构造器去构造出特定类型的 `Searcher`（作为真实的执行者，进行字符串匹配操作）。

实现了 `Pattern` trait 的六种类型都可以作为 `split()` 的入参，在 `haystack: &'a str` 中搜索匹配的字符串，[表格 1](https://doc.rust-lang.org/std/str/pattern/trait.Pattern.html) 展示了对应的类型和搜索匹配之间的关系。

| Pattern type             | Match condition                          |
| :----------------------- | :--------------------------------------- |
| `&str`                   | is substring                             |
| `char`                   | is contained in string                   |
| `&[char]`                | any char in slice is contained in string |
| `F: FnMut(char) -> bool` | `F` returns `true` for a char in string  |
| `&&str`                  | is substring                             |
| `&String`                | is substring                             |

表格 1：实现 `Pattern` trait 的六种类型与搜索匹配的对应关系

```rust
pub trait Pattern<'a> {
    type Searcher: Searcher<'a>;
    fn into_searcher(self, haystack: &'a str) -> Self::Searcher;
}

// 以下六个 structs 实现了 Pattern trait
impl<'a> Pattern<'a> for char { ... }

impl<'a, 'b> Pattern<'a> for &'b str {
    type Searcher = StrSearcher<'a, 'b>;
}

impl<'a, 'b> Pattern<'a> for &'b String { ... }

impl<'a, 'b> Pattern<'a> for &'b [char] { ... }

impl<'a, 'b, 'c> Pattern<'a> for &'c &'b str { ... }

impl<'a, F> Pattern<'a> for F
where
    F: FnMut(char) -> bool, 
{ ... }
```

### Search trait

真实地进行字符串匹配的执行者，从给定字符串的起点位置（字符串最左侧）开始匹配对应的 Pattern。需要注意的是，`Search` trait 被标记为 `unsafe`，原因是 `next()` 返回的索引值需要保证正好落在有效的 UTF-8 边界上（lie on valid utf8 boundaries in the haystack），详细说明可以查看[文档](https://doc.rust-lang.org/std/str/pattern/trait.Searcher.html)。

```rust
pub unsafe trait Searcher<'a> {
    // Required methods
    fn haystack(&self) -> &'a str;
    fn next(&mut self) -> SearchStep;

    // Provided methods
    fn next_match(&mut self) -> Option<(usize, usize)> { ... }
    fn next_reject(&mut self) -> Option<(usize, usize)> { ... }
}

// 以下四个 structs 实现了 Search trait
unsafe impl<'a> Searcher<'a> for CharSearcher<'a> { ... }

unsafe impl<'a, 'b> Searcher<'a> for CharSliceSearcher<'a, 'b> { ... }

unsafe impl<'a, 'b> Searcher<'a> for StrSearcher<'a, 'b> { ... }

unsafe impl<'a, F> Searcher<'a> for CharPredicateSearcher<'a, F>
where
    F: FnMut(char) -> bool,
{ ... }
```

## 总结

在本文中，我们围绕着字符串分割的实例，详细讲解了 Rust 中的生命周期，包括为什么需要生命周期、什么是生命周期、以及如何标注生命周期。同时，由于字符串分割仅与待处理字符串的生命周期相关联，引入多生命周期标注。最后，使用 trait 来定义分割行为，让实现更加通用。

通过 5 个版本的修改，一步步完成我们自己的 `StrSplit`，最后查看标准库的字符串分割实现，加深理解。

除了对生命周期相关概念的讲解外，本文还对实现中的一些细节做了讲解：

- `&str` 与 `String` 的区别与联系
- `Iterator trait`
- `Self` 和 `self`
- `ref mut` 进行模式匹配
- `?` operator
- etc ...

本文为作者学习 Rust 的一篇学习笔记，肯定存在遗漏或错误，欢迎大家在评论区讨论指出。

【系列文章】：

1、[Rust 中的生命周期](https://qiaoin.github.io/2021/12/15/rust-lifetime/)

2、[Rust 中的迭代器](https://qiaoin.github.io/2022/01/17/rust-iterator/)

3、更多 Rust 相关的文章，敬请期待

## 版权声明

本作品采用[知识共享署名 4.0 国际许可协议](http://creativecommons.org/licenses/by/4.0/)进行许可，转载时请注明原文链接。

## References

- Crust of Rust 系列 [Lifetime Annotations](https://www.youtube.com/watch?v=rAl-9HwD858&list=PLqbS7AVVErFiWDOAVrPt7aYmnuuOLYvOa&index=1&ab_channel=JonGjengset) 本文为学习此视频后的笔记
- [Rust The Book](https://doc.rust-lang.org/stable/book/) 第 4 章和第 10 章
- 极客时间专栏 [陈天 · Rust 编程第一课](https://time.geekbang.org/column/intro/100085301)，第 7 讲 - 第 11 讲
- [Rust 标准库文档](https://doc.rust-lang.org/stable/std/)，对于 Rust 的源码直接从 docs.rs 点击过去看一下
- [Rust 语言的备忘清单](https://cheats.rs/)
- [rust - What is a "fat pointer"? - Stack Overflow](https://stackoverflow.com/questions/57754901/what-is-a-fat-pointer)
- [Authors of "Programming Rust 2nd Edition" have a sense of humor : rust](https://www.reddit.com/r/rust/comments/kcou9c/authors_of_programming_rust_2nd_edition_have_a/) 文中 `noodles` 的代码示例和图示受这个帖子启发，有删改
- [Rust Playground](https://play.rust-lang.org/) 文中的代码示例都给到了 playground 的链接，在阅读的时候可以点击跳转过去 Run 起来看一下运行结果或错误提示
- [Rust Compiler Error Index](https://doc.rust-lang.org/stable/error-index.html) Rust 错误列表，在 playground 中运行报错时可以直接点击跳转过来查看，作为字典查询即可
- 文中的所有图片均使用 [excalidraw](https://excalidraw.com/) 绘制
