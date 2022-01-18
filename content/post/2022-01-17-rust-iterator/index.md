---
title: Rust 中的迭代器
author: qiaoin
date: '2022-01-17'
slug: rust-iterator
categories:
  - 编程语言
  - Rust
tags:
  - Rust
  - 迭代器
  - Learning-by-doing
---

迭代器作为 GoF 23 种设计模式之一，在编程语言中广泛使用。本文，我们一起来探索 Rust 对迭代器的支持。首先明确 Rust 中的迭代器类型，接下来讲解从集合获取迭代器的三种方式，然后实现一个我们自己的迭代器（以实现 `our_flatten()` 为例）。在此基础上，为 `Iterator` trait 引入 extension traits，让所有迭代器都可以直接使用 `our_flatten()`，方便扩展。

---

{{< toc >}}

---

## The basis of Iterator

Rust 标准库实现的迭代器依托于 `Iterator` trait，它定义了一组抽象接口（abstraction），让使用者无需关心集合的底层实现细节，直接调用 `next()` 将集合作为迭代器进行访问，每次访问一个元素。

> Provide a way to access the elements of an aggregate object sequentially without exposing its underlying representation.
>
> 提供一种方法，使之能够依序访问某个聚合物（集合）所含的各个元素，而又无需暴露该聚合物的内部实现细节。
>
> —— Design Pattern, GoF, Chapter 5.4 Iterator, Page 257

### external iteration

查看 iter module 的[文档介绍](https://doc.rust-lang.org/std/iter/index.html)，第一句为：

> Composable external iteration.

`external`，外部迭代器，同样 GoF 给到介绍：

> *Who controls the iteration?* A fundamental issue is deciding which party controls the iteration, the iterator or the client that uses the iterator. When the client controls the iteration, the iterator is called an **external iterator** (C++ and Java), and when the iterator controls it, the iterator is an **internal iterator** (Lisp and functional languages). Clients that use an external iterator must advance the traversal and request the next element explicitly from the iterator. In contrast, the client hands an internal iterator an operation to perform, and the iterator applies that operation to every element in the aggregate.
>
> External iterators are more flexible than internal iterators. It's easy to compare two collections for equality with an external iterator, for example, but it's practically impossible with internal iterators. Internal iterators are especially weak in a language like C++ that does not provide anonymous functions, closures, or continuations like Smalltalk and CLOS. But on the other hand, internal iterators are easier to use, because they define the iteration logic for you.
>
> —— Design Pattern, GoF, Chapter 5.4 Iterator, Page 260

- 外部迭代器（external iterators），使用 `struct` 保存当前迭代的状态信息，由调用方来控制迭代行为（调用 `next()` 从迭代器中获取元素）。例如 `for-in-loops`，语法糖在后面会详细讲解；
- 内部迭代器（internal iterators），传递一个闭包（closures）给迭代器，迭代器在每个元素上调用这个闭包操作，无需保存当前迭代的状态信息，完全由迭代器来控制迭代行为。例如 `Iterator::for_each(self, f: F) where F: FnMut(Self::Item)`。

Rust 同时提供了内部迭代器和外部迭代器的语义，本文主要聚焦外部迭代器。

对于 Rust 中的内部迭代器，会与 `composable` 一起，搭配闭包（closures）和适配器（adapters）在下一篇文章中进行介绍。

### Iterator trait

所有迭代器（Iterator）都实现了 `Iterator` trait（查看目前标准库中实现了 `Iterator` trait 的 [Implementors](https://doc.rust-lang.org/std/iter/trait.Iterator.html#implementors)），定义如下：

```rust {hl_lines=[3,5]}
// https://doc.rust-lang.org/src/core/iter/traits/iterator.rs.html#55
pub trait Iterator {
    type Item;

    fn next(&mut self) -> Option<Self::Item>;

    // 在实现了 next() 后，其他的方法都有缺省实现，这里直接省略    
}
```

包含两个部分：

- 关联类型（associated types）。`Item` 定义了迭代器每次返回的数据类型；
- 方法（methods），也称关联函数（associated functions）。实现 `Iterator` trait 必须实现 `next()`，定义了从迭代器中取下一个值的方法。当一个迭代器的 `next()` 方法返回 `None` 时，表明迭代器中已经没有值了。实现 `next()` 后，`Iterator` trait 中的其他方法就都有了缺省实现（其他方法的缺省实现使用了 `next()`，性能可能比较差；可以提供自定义实现）。

## Three forms of iteration

从一个集合得到迭代器（create iterators from a collection），有三种方式：

- `iter()`, which iterates over `&T`.
- `iter_mut()`, which iterates over `&mut T`.
- `into_iter()`, which iterates over `T`.

注意，这里只是一个笼统的描述，实际情况需要根据标准库中具体类型来确认。例如，[HashSet](https://doc.rust-lang.org/std/collections/struct.HashSet.html) / [HashMap](https://doc.rust-lang.org/std/collections/struct.HashMap.html) 就不提供 `iter_mut()` 方法；`&str` 则根据返回的迭代器类型，提供 [chars()](https://doc.rust-lang.org/std/primitive.str.html#method.chars) 和 [bytes()](https://doc.rust-lang.org/std/primitive.str.html#method.bytes) 方法。

以 `Vec<T>` 类型为例，写一段代码进行理解，[代码 1，three-forms-of-iteration](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=83404e09bc12f1d203e43c20ca6bcfb3)：

```rust {hl_lines=[5,19,28]}
fn main() {
    let v1 = vec![1, 2, 3];
    // 由于 next(&mut self)，因此 v1_iter 需要使用 mut 修饰
    // calling next() changes the state of iter, it must be mutable.
    let mut v1_iter = v1.iter();  // std::slice::Iter<'_, {integer}>
    // iter() -- borrow as immutable, 不能进行修改
    // if let Some(first) = v1_iter.next() {
    //     *first += 4;
    // }
    assert_eq!(v1_iter.next(), Some(&1));
    assert_eq!(v1_iter.next(), Some(&2));
    assert_eq!(v1_iter.next(), Some(&3));
    assert_eq!(v1_iter.next(), None);
    assert_eq!(v1, vec![1, 2, 3]);  // v1_iter borrows, so v1 can still access
    println!("v1 = {:?}", v1);
    
    // iter_mut() -- borrow as mutable，可以进行修改
    let mut v2 = vec![1, 2, 3];
    let mut v2_iter = v2.iter_mut();  // std::slice::IterMut<'_, {integer}>
    // v2_iter.next() --- Option<&mut {integer}>
    if let Some(first) = v2_iter.next() {
        *first += 4;
    }
    assert_eq!(v2, vec![5, 2, 3]);  // v2_iter borrows, so v2 can still access
    println!("v2 = {:?}", v2);
    
    let v3 = vec![1, 2, 3];
    let mut v3_iter = v3.into_iter();  // std::vec::IntoIter<{integer}>
    //                   ----------- `v3` moved due to this method call
    assert_eq!(Some(1), v3_iter.next());
    assert_eq!(Some(2), v3_iter.next());
    assert_eq!(Some(3), v3_iter.next());
    assert_eq!(None, v3_iter.next());
    // println!("v3 = {:?}", v3);  // error[E0382]: borrow of moved value: `v3`
    //                       ^^ value borrowed here after move
}
```

### iter() / iter_mut()

1、`v.iter()` 返回切片类型的不可变迭代器，[slice-method-iter](https://doc.rust-lang.org/std/primitive.slice.html#method.iter)

```rust
// https://doc.rust-lang.org/src/core/slice/mod.rs.html#736
pub fn iter(&self) -> Iter<'_, T> {}
```

2、`v.iter_mut()` 返回切片类型的可变迭代器，[slice-method-iter_mut](https://doc.rust-lang.org/std/primitive.slice.html#method.iter_mut)

```rust
// https://doc.rust-lang.org/src/core/slice/mod.rs.html#753
pub fn iter_mut(&mut self) -> IterMut<'_, T> {}
```

`iter()` 和 `iter_mut()` 均为切片类型提供的方法，返回切片的迭代器（`std::slice::Iter struct` 和 `std::slice::IterMut struct`）。

### Deref / DerefMut trait

`v` 的类型为 `Vec<T>`，为什么 `v.iter()` / `v.iter_mut()` 可以调用切片类型的方法呢？是由于 [Deref](https://doc.rust-lang.org/std/ops/trait.Deref.html) / [DerefMut](https://doc.rust-lang.org/std/ops/trait.DerefMut.html) trait —— 为一个类型（Type）实现 `Deref` / `DerefMut` trait，就可以像使用引用一样进行解引用（dereferencing）。

`Deref` 和 `DerefMut` trait 定义：

```rust {hl_lines=[7,13]}
// https://doc.rust-lang.org/src/core/ops/deref.rs.html#64-76
pub trait Deref {
    /// The resulting type after dereferencing.
    type Target: ?Sized;

    /// Dereferences the value.
    fn deref(&self) -> &Self::Target;
}

// https://doc.rust-lang.org/src/core/ops/deref.rs.html#172-176
pub trait DerefMut: Deref {
    /// Mutably dereferences the value.
    fn deref_mut(&mut self) -> &mut Self::Target;
}
```

默认情况下（without  `Deref` / `DerefMut` trait），编译器只能对 `&` 执行解引用。有了  `Deref` / `DerefMut` trait ，`deref()` / `deref_mut()` 返回引用类型，此时编译器就能够知道如何在一个类型（Type）上执行解引用（调用 `deref()` / `deref_mut()`  得到引用，再执行解引用得到对应的 `Self::Target` / `mut Self::Target` 类型）。

`Vec<T>` 实现了这两个 trait，[Vec-impl-Deref-trait](https://doc.rust-lang.org/std/vec/struct.Vec.html#impl-Deref)：

```rust {hl_lines=[5,12]}
// https://doc.rust-lang.org/src/alloc/vec/mod.rs.html#2398-2404
impl<T, A: Allocator> ops::Deref for Vec<T, A> {
    type Target = [T];

    fn deref(&self) -> &[T] {
        unsafe { slice::from_raw_parts(self.as_ptr(), self.len) }
    }
}

// https://doc.rust-lang.org/src/alloc/vec/mod.rs.html#2407-2411
impl<T, A: Allocator> ops::DerefMut for Vec<T, A> {
    fn deref_mut(&mut self) -> &mut [T] {
        unsafe { slice::from_raw_parts_mut(self.as_mut_ptr(), self.len) }
    }
}
```

因此，`Vec<T>` 执行解引用得到切片，对应 `v.iter()` / `v.iter_mut()` 详细解释为：

- `v.iter()` —— 对 `v` 执行 `deref(&v)` 得到 `&[T]`，然后 `*` 解引用得到 `[T]`；再调用切片类型的 `iter(&[T])` 方法，返回迭代器 `std::slice::Iter<'a, T>`，其实现了 `Iterator` trait（关联类型为 `type Item = &'a T`），因此 `v1_iter` 可以调用 `next()` 访问存储的数据（`next()` 返回类型为 `Option<&'a T>`），不可变借用；
- `v.iter_mut()` —— 对 `v` 执行 `deref_mut(&mut v)` 得到 `&mut [T]`，然后 `*` 解引用得到 `mut [T]`；再调用切片类型的 `iter_mut(&mut [T])` 方法，返回迭代器 `std::slice::IterMut<'a, T>`，其实现了 `Iterator` trait（关联类型为 `type Item = &'a mut T`），因此 `v2_iter` 可以调用 `next()` 访问存储的数据（`next()` 返回类型为 `Option<&'a mut T>`），可变借用。

`std::slice::Iter<'a, T>` 和 `std::slice::IterMut<'a, T>` 实现 `Iterator` trait，均使用宏进行定义（[impl-Iterator-for-Iter](https://doc.rust-lang.org/src/core/slice/iter.rs.html#134-144)、[impl-Iterator-for-IterMut](https://doc.rust-lang.org/src/core/slice/iter.rs.html#316)），关于 Rust 中的宏（macros），本系列会有单独一篇文章进行讲解。

对于 `Vec<T>`、slice 和 `Iterator` trait 之间的转换，借助图 1 进行理解。更深入的 slice 介绍，可以查看 [陈天 · Rust 编程第一课 - 第 16 讲](https://time.geekbang.org/column/article/422975)。

{{< figure src="images/vec-deref-slice-impl-iterator.png" caption="图 1：`Vec<T>`、slice 和 `Iterator` trait 之间的转换" >}}

### Deref coercion

一个类型（Type）实现 `Deref` / `DerefMut` trait，编译器会在三种情况下执行解引用：

1、`*x` —— **显式**解引用，根据 `x` 所在的上下文（[mutable contexts](https://doc.rust-lang.org/reference/expressions.html#mutability) / immutable contexts），等价于执行 `*(std::ops::Deref::deref(&x))` / `*(std::ops::DerefMut::deref_mut(&mut x))`，[* 解引用操作符](https://doc.rust-lang.org/reference/expressions/operator-expr.html#the-dereference-operator)；

2、`x.method(call-params)` —— [方法调用](https://doc.rust-lang.org/reference/expressions/method-call-expr.html)时执行**隐式**解引用，可能调用的候选方法包括：

- associated [methods](https://doc.rust-lang.org/reference/items/associated-items.html#methods) on specific traits
- statically dispatching to a method if the exact `self`-type of the left-hand-side is known
- dynamically dispatching if the left-hand-side expression is an indirect [trait object](https://doc.rust-lang.org/reference/types/trait-object.html)

因此，查找方法名时需获取得到所有的候选类型（a list of candidate receiver types） —— 通过对 `x` 执行多次解引用获取得到所有的候选类型。

3、类型转换（Type coercions），一个简单的例子，[代码 2，type-coercions](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=89ad52d4371f3d88ccac1994936713e0)，列举了两个场景下的类型转换，更多场景可以查看文档，[Type coercions](https://doc.rust-lang.org/reference/type-coercions.html)。

```rust {hl_lines=[1,7,11]}
fn hello(name: &str) {
    println!("Hello, {}!", name);
}

fn main() {
    let m = String::from("Rust");  // String
    hello(&m);  // 场景 1：函数参数，&m type is &String -- auto dereferenece --> &str

    hello(&m[..]);  // 如果不支持 Deref coercion, 就需要显式传递 &str

    let n: &str = &m;  // 场景 2：let 左侧显式指定了类型，auto dereferenece
    hello(n);
}
```

[标准库为 `String` 类型实现了 `Deref` trait](https://doc.rust-lang.org/std/string/struct.String.html#impl-Deref)，返回一个字符串切片（`&str`）。在进行函数调用（场景 1）时，编译器自动进行了类型转换（调用 `String` 实现的 `deref(&String)`，返回 `&str`）。场景 2 同理。

除了使用 `*` 一元运算符进行**显式**解引用，更多的场景下，编译器（Rust compiler）会**自动**进行隐式解引用（上述编译器执行解引用的情况 2 和 3。在 immutable 的上下文中，使用 `Deref`；在 mutable 的上下文中，使用 `DerefMut`），称为 `Deref coercion`。

如果没有 `Deref coercion`，需按照 `hello(&str)` 的签名进行严格匹配（支持 `Deref coercion`，编译器会在编译期（compile time）自动进行转换），写出来的代码不易阅读；但同时也应认识到，过分的依赖 `Deref` 会使代码不易维护，因此 [Deref](https://doc.rust-lang.org/std/ops/trait.Deref.html) / [DerefMut](https://doc.rust-lang.org/std/ops/trait.DerefMut.html) trait 的文档中都提到：

> **`Deref` / `DerefMut` should only be implemented for smart pointers** to avoid confusion.

Rust 编译器执行 `Deref coercion` 时会区分可变和不可变，[The Book - How Deref Coercion Interacts with Mutability](https://doc.rust-lang.org/book/ch15-02-deref.html#how-deref-coercion-interacts-with-mutability)：

- From `&T` to `&U` when `T: Deref<Target=U>`
- From `&mut T` to `&mut U` when `T: DerefMut<Target=U>`
- From `&mut T` to `&U` when `T: Deref<Target=U>` 一个可变借用（可变借用是排他的，只能有一个）可以解引用为不可变借用，满足 Rust 的借用规则；反过来不行，将一个不可变借用（不可变借用可以有多个）解引用为可变借用会破坏 Rust 的借用规则。

### into_iter()

3、`v.into_iter()`，`std::vec::Vec` 实现 `IntoIterator` trait，将 `std::vec::Vec` 转换为迭代器 `std::vec::IntoIter`（实现了 `Iterator` trait）。

```rust {hl_lines=[6,14,21]}
// https://doc.rust-lang.org/src/core/iter/traits/collect.rs.html#204-235
pub trait IntoIterator {
    type Item;
    type IntoIter: Iterator;

    fn into_iter(self) -> Self::IntoIter;
}

// https://doc.rust-lang.org/src/alloc/vec/mod.rs.html#2522-2561
impl<T, A: Allocator> IntoIterator for Vec<T, A> {
    type Item = T;
    type IntoIter = IntoIter<T, A>;

   fn into_iter(self) -> IntoIter<T, A> {}
}

// https://doc.rust-lang.org/src/alloc/vec/into_iter.rs.html#131-209
impl<T, A: Allocator> Iterator for IntoIter<T, A> {
    type Item = T;

    fn next(&mut self) -> Option<T> {}
}
```

需要特别注意的是，`.into_iter(self)` 的签名，伴随有所有权的转移。借助图 2 进行理解。

{{< figure src="images/vec-into-iter-impl-iterator.png" caption="图 2：`std::vec` module 下的 `Vec<T>` 和 `IntoIter<T>`" >}}

这里会产生一个疑问：为什么 Rust 不直接为 `Vec<T>` 实现 `Iterator` trait 呢，而是另外定义了一个 `IntoIter<T> struct` 来实现 `Iterator` trait 呢？

理由有以下两点：

1、回顾一下 `Iterator` trait `next(&mut self)` 的签名，为可变引用，基于 Rust 的借用规则，活跃的可变引用只能有一个。因此，如果为 `Vec<T>` 实现 `Iterator` trait，就不支持同时经由 `Vec<T>` 创建多个迭代器；并且由于可以在迭代期间修改迭代器，很容易出现错误，不符合 Rust 安全的宣言；

2、外部迭代器需要保存当前迭代的状态，并且此状态需要在每次迭代时更新。因此，如果为 `Vec<T>` 实现 `Iterator` trait，就需要在 `Vec<T>` 保存迭代状态，经由 `Vec<T>` 不可变引用上创建的迭代器，修改不了其保存的迭代状态，也就实现不了迭代器。

因此，Rust 另外定义一个 `IntoIter<T> struct` 来实现 `Iterator` trait。

### for-in-loops / Iterator loops

[语法](https://doc.rust-lang.org/reference/expressions/loop-expr.html#iterator-loops)表示为：

```bash
IteratorLoopExpression :
   for Pattern in Expression_{except struct expression} BlockExpression
```

Rust 语法糖，`in` 关键字后的表达式需要实现 `IntoIterator` trait，`for` 循环遍历`.into_iter()` 返回的迭代器，当迭代器返回 `Some(val)` 时，按照 `Pattern` 匹配，然后执行 `for-block` 中的语句。`for` 循环多次执行，直至迭代器返回 `None` 或显式 `break`。

写一段代码测试一下，[代码 3，for-in-loops](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=a1c4f6688fb064aefd732f27aac1979f)，代码示例来源于文档 [iter-for-loops-and-IntoIterator](https://doc.rust-lang.org/std/iter/#for-loops-and-intoiterator)：

```rust
fn main() {
    let values = vec![1, 2, 3, 4, 5];
    for x in values {
        println!("{}", x);
    }
}
```

de-sugars 后：

```rust {hl_lines=[7]}
fn main() {
    let values = vec![1, 2, 3, 4, 5];
    // for x in values {
    //     println!("{}", x);
    // }
    {
        let result = match IntoIterator::into_iter(values) {
            mut iter => loop {
                let next;
                match iter.next() {
                    Some(val) => next = val,
                    None => break,
                };
                let x = next;
                let () = { println!("{}", x); };
            },
        };
        result
    }
}
```

### five types of for-in-loops

针对第二部分内容，看一段综合的代码，[代码 4，five-for-iterator](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=f46910738cabf6db121bb1c3c8086f43)：

```rust {hl_lines=[3,11,19,26,36]}
fn main() {
    let v1 = vec![1, 2, 3];
    for x1 in v1.iter() {
        // std::slice::Iter struct 实现了 Iterator trait
        // 对于所有 Iterator trait bound 的类型，都实现了 IntoIterator trait
        println!("{}", x1);
    }
    println!("v1 = {:?}", v1);  // v1.iter() borrows immutable, so v1 can access
    
    let mut v2 = vec![1, 2, 3];
    for x2 in v2.iter_mut() {
        // std::slice::IterMut struct 实现了 Iterator trait
        // 对于所有 Iterator trait bound 的类型，都实现了 IntoIterator trait
        println!("{}", x2);
    }
    println!("v2 = {:?}", v2);  // v2.iter() borrows mutable, so v2 can access
    
    let v3 = vec![1, 2, 3];
    for x3 in v3 {
        // 隐式调用 v3.into_iter(), v3 所有权 move 了，后续不能继续访问 v3
        println!("{}", x3);
    }
    // println!("v3 = {:?}", v3);  // error[E0382]: value borrowed here after move
    
    let v4 = vec![1, 2, 3];
    for x4 in &v4 {
        // &v4 -- &Vec<{integer}>
        // https://doc.rust-lang.org/src/alloc/vec/mod.rs.html#2564-2571
        // impl<'a, T, A: Allocator> IntoIterator for &'a Vec<T, A>
        // IntoIterator::into_iter(&v4) === v4.iter()
        println!("{}", x4);
    }
    println!("v4 = {:?}", v4);  // &v4 borrows immutable, so v4 still access
    
    let mut v5 = vec![1, 2, 3];
    for x5 in &mut v5 {
        // &mut v5 -- &mut Vec<{integer}>
        // https://doc.rust-lang.org/src/alloc/vec/mod.rs.html#2574-2581
        // impl<'a, T, A> IntoIterator for &'a mut Vec<T, A>
        // IntoIterator::into_iter(&mut v5) === v5.iter_mut()
        println!("{}", x5);
    }
    println!("v5 = {:?}", v5);  // &mut v5 borrows immutable, so v5 can access
}
```

1、`v1.iter()` 和 `v2.iter_mut()` 返回切片的迭代器（`std::slice::Iter struct` 和 `std::slice::IterMut struct`），都实现了 `Iterator` trait。而所有迭代器（实现了 `Iterator` trait 的类型），均实现了 `IntoIterator` trait（返回该迭代器本身），因此可以使用 `for-in-loops` 进行迭代访问：

```rust {hl_lines=[2,4,7]}
// https://doc.rust-lang.org/src/core/iter/traits/collect.rs.html#238-246
impl<I: Iterator> IntoIterator for I {
    type Item = I::Item;
    type IntoIter = I;

    #[inline]
    fn into_iter(self) -> I {
        self
    }
}
```

2、`v3` 与上一节的示例代码相同，不重复解释；

3、`&v4` 和 `&mut v5` 对应为 `&'a Vec<T, A>` 和 `&'a mut Vec<T, A>` 实现 `IntoIterator` trait，在 `into_iter(self)` 的实现中直接调用 `iter()` 和 `iter_mut()`；与 `v1` 和 `v2` 的处理逻辑等价

```rust {hl_lines=[2,7,12,17]}
// https://doc.rust-lang.org/src/alloc/vec/mod.rs.html#2564-2571
impl<'a, T, A: Allocator> IntoIterator for &'a Vec<T, A> {
    type Item = &'a T;
    type IntoIter = slice::Iter<'a, T>;

    fn into_iter(self) -> slice::Iter<'a, T> {
        self.iter()
    }
}

// https://doc.rust-lang.org/src/alloc/vec/mod.rs.html#2574-2581
impl<'a, T, A: Allocator> IntoIterator for &'a mut Vec<T, A> {
    type Item = &'a mut T;
    type IntoIter = slice::IterMut<'a, T>;

    fn into_iter(self) -> slice::IterMut<'a, T> {
        self.iter_mut()
    }
}
```

借助图 3 进行理解：

{{< figure src="images/three-forms-for-in-loop.png" caption="图 3：三种类型的 `for-in-loop`" >}}

如果一个集合类型 `C` 提供了 `iter()` 方法，通常会为 `&C` 实现 `IntoIterator` trait（直接调用 `iter()` 方法）；同理，如果 `C` 提供了 `iter_mut()` 方法，通常会为 `&mut C` 实现 `IntoIterator` trait（直接调用 `iter_mut()` 方法）。

自然会产生一个疑问：既然为 `&C` / `&mut C` 实现 `IntoIterator` trait，与 `C` 上的  `iter(&self)` / `iter_mut(&mut self)` 等价，为什么 Rust 要同时提供这两种方式呢？只提供一种方式是否可以？

基于以下两个方面考虑：

1、实现 `IntoIterator` trait 是使用 `for-in-loops` 的要求；当不在 `for-in-loops` 中使用时，使用 `v.iter()` 要比 `(&v).into_iter()` 更清晰，代码更易读；

2、`IntoIterator` trait 可以作为 trait bounds，范型编程中进行参数类型约束，`T: IntoIterator` 表示参数类型 `T` 需要能够作为迭代器进行访问；或者，`T: IntoIterator<Item = U>` 表示被迭代的类型需要是类型 `U`；而 `iter(&self)` / `iter_mut(&mut self)` 表达不了 trait bounds 约束。例如下面这个例子（[代码 5，dump-function](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=a413366a115c86dec36bb38021f3aeb4)），`dump` 函数将传入的可迭代变量依次打印出来，`Item` 需要实现 `Display` trait；`Vec<T>` 未实现 `Display` trait，因此 `dump(v3)`  会编译报错。

```rust {hl_lines=[5,6]}
use std::fmt::Display;

fn dump<T, U>(t: T)
where
    T: IntoIterator<Item = U>,
    U: Display,
{
    for u in t {
        println!("{}", u);
    }
}

fn main() {
    let v1 = vec![1, 2, 3];
    dump(v1);
    
    let v2 = vec!["a".to_string(), "b".to_string(), "c".to_string()];
    dump(v2);
    
    let v3 = vec![vec![1, 4], vec![2, 5], vec![3, 6]];
    dump(v3); // error[E0277]: `Vec<{integer}>` doesn't implement `std::fmt::Display`
}
```

---

至此，第两部分结束，使用 `Vec<T>` 为例，分析了 `iter()` / `iter_mut()` / `into_iter()` 三种方式的原理：

- 通过为 `Vec<T>` 实现 `Deref` / `DerefMut` trait，可以使用 `v.iter()` / `v.iter_mut()` 调用切片类型 `[T]` 的方法；
- 通过为 `Vec<T>` 实现 `IntoIterator` trait，可以使用 `v.into_iter()` 获取迭代器，同时可以使用 `for x in v { ... }` 进行迭代访问；
- 通过为 `&Vec<T>` / `&mut Vec<T>` 实现 `IntoIterator` trait，可以使用 `for x in &v { ... }` / `for x in &mut v { ... }` 进行迭代访问（等价于 `for x in v.iter()` / `for x in v.iter_mut()`）；

按照上述分析 `Vec<T>` 的思路，读者可以试着分析 `HashMap` 对迭代器的支持。

---

前两部分学习完，来动手练习一下，实现一个自己的迭代器 —— `our_flatten()` —— 支持从前往后和从后往前同时遍历。

## Implementing our_flatten()

首先，看一下 `Iterator` trait 中 [flatten()](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.flatten) 方法的功能，将一个嵌套的迭代器往下平铺**一层**（one level down），[代码 6，flatten-one-level-down](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=2fb3fe9722d21cfa00868701bbfcb2fa)：

```rust {hl_lines=[4,13]}
fn main() {
    // data1 -- Vec<Vec<{integer}>>
    let data1 = vec![vec![1, 2], vec![3, 4]];
    let mut flattened1 = data1.into_iter().flatten();
    assert_eq!(flattened1.next(), Some(1));
    assert_eq!(flattened1.next(), Some(2));
    assert_eq!(flattened1.next(), Some(3));
    assert_eq!(flattened1.next(), Some(4));
    assert_eq!(flattened1.next(), None);

    // data2 -- Vec<Vec<Vec<{integer}>>>
    let data2 = vec![vec![vec![1, 2], vec![3, 4]], vec![vec![5, 6], vec![7, 8]]];
    let mut flattened2 = data2.into_iter().flatten();
    assert_eq!(flattened2.next(), Some(vec![1, 2]));
    assert_eq!(flattened2.next(), Some(vec![3, 4]));
    assert_eq!(flattened2.next(), Some(vec![5, 6]));
    assert_eq!(flattened2.next(), Some(vec![7, 8]));
    assert_eq!(flattened2.next(), None);
}
```

`data1` / `data2`  的每一个元素类型为 `Vec<T>`（`outer::Item`），实现了 `IntoIterator` trait，都可以调用 `.flatten()` 将嵌套的迭代器向下平铺一层：

- `data1.into_iter().flatten()` 得到的迭代器，其遍历的元素类型为 `T`；
- `data2.into_iter().flatten()` 得到的迭代器，其遍历的元素类型为 `Vec<T>`。`flatten()` 只往下平铺一层，就是这个含义，如果需要再往下一层，可以进行多次调用 `data2.into_inter().flatten().flatten()`。

弄清楚了标准库 `std::iter::Iterator::flatten()` 的功能，接下来看看我们应该如何实现该功能，实现 `our_flatten()`。

### version #1: set up

`flatten(iter)` 的入参需遵循以下要求（图 4）：

- `iter` 为迭代器（iterator，实现 `Iterator` trait）或者可以被迭代（iterable，实现 `IntoIterator` trait）；
- `iter::Item` 可以被迭代（iterable，实现 `IntoIterator` trait）；

{{< figure src="images/flatten-outer-item-bounds.png" caption="图 4：`iter` 为迭代器，`iter::Item` 可以被迭代" >}}

第一层 `outer` 调用 `next()` 获取 `Option<Item>`，当存在待处理的值时 —— `Some(inner)` —— 调用 `.into_iter().next()`。这样就实现了 `flatten()` 的第一个版本，[代码 7，version #1: set-up](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=41717cc3d5ab80bb07b0ba7700ef5b3f)。

```rust {hl_lines=[17,18,23]}
pub fn flatten<O>(iter: O) -> Flatten<O> {
    Flatten::new(iter)
}

pub struct Flatten<O> {
    outer: O,
}

impl<O> Flatten<O> {
    fn new(iter: O) -> Self {
        Flatten { outer: iter }
    }
}

impl<O> Iterator for Flatten<O>
where
    O: Iterator,
    O::Item: IntoIterator,
{
    type Item = <O::Item as IntoIterator>::Item;

    fn next(&mut self) -> Option<Self::Item> {
        self.outer.next().and_then(|inner| inner.into_iter().next())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty() {
        assert_eq!(flatten(std::iter::empty::<Vec<()>>()).count(), 0);
    }
    
    #[test]
    fn one() {
        assert_eq!(flatten(std::iter::once(vec!["a"])).count(), 1);
    }
    
    #[test]
    fn two() {
        assert_eq!(flatten(std::iter::once(vec!["a", "b"])).count(), 2);
    }
    
    #[test]
    fn two_wide() {
        assert_eq!(flatten(vec![vec!["a"], vec!["b"]].into_iter()).count(), 2);
    }
}
```

当 `Item` 存在多个元素时，测试错误。

`and_then()` 使用 `?` 展开，问题就更清晰了：每次调用 `next`，`outer` 都往前走了一步，即使 `inner_item` 存在多个元素待处理。

```rust {hl_lines=[9,"11-14"]}
impl<O> Iterator for Flatten<O>
where
    O: Iterator,
    O::Item: IntoIterator,
{
    type Item = <O::Item as IntoIterator>::Item;

    fn next(&mut self) -> Option<Self::Item> {
        // self.outer.next().and_then(|inner| inner.into_iter().next())
        
        // simplifying with ?
        let inner_item = self.outer.next()?;
        let mut inner_iter = inner_item.into_iter();  // 需要保存正在迭代的 inner_iter
        inner_iter.next()
    }
}
```

### version #2: save inner_iter

需要保存当前正在迭代的 `inner_iter`，从 `inner_item.into_iter()` 可知其类型为 `<O::Item as IntoIterator>::IntoIter`；同时，`inner_iter` 未开始迭代和迭代完成时，需切换迭代 `outer`，因此使用 `Option` 修饰 `inner_iter`：

1、迭代未开始，`outer` 指向入参迭代器，`inner` 为 `None`；

2、迭代开始，`outer.next()` 返回外层迭代器的第一个元素，若该元素为 `Some(inner_item)`，调用 `inner_item.into_iter()` 得到内层元素对应的迭代器，赋值给 `inner`；

3、处理内层迭代器 `inner`，若仍有待处理元素，将元素包裹在 `Some(i)` 中作为返回；若没有待处理元素，将 `inner` 设置为 `None`。外层迭代器的第一个元素迭代结束;

4、`outer.next()` 返回外层迭代器的后续元素，继续处理。

得到 `flatten()` 的第二个版本，[代码 8，version #2: save-inner-iter](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=7e2f1df53f70a2af30d02147f8fb3d31)，主要逻辑在 `next()` 的 `loop` 循环中，可以按照上述逻辑比对代码进行理解。

```rust {hl_lines=["38-50"]}
pub fn flatten<O>(iter: O) -> Flatten<O>
where
    O: Iterator,
    O::Item: IntoIterator,
{
    Flatten::new(iter)
}

pub struct Flatten<O>
where
    O: Iterator,
    O::Item: IntoIterator,
{
    outer: O,
    inner: Option<<O::Item as IntoIterator>::IntoIter>,
}

impl<O> Flatten<O>
where
    O: Iterator,
    O::Item: IntoIterator,
{
    fn new(iter: O) -> Self {
        Flatten {
            outer: iter,
            inner: None,
        }
    }
}

impl<O> Iterator for Flatten<O>
where
    O: Iterator,
    O::Item: IntoIterator,
{
    type Item = <O::Item as IntoIterator>::Item;

    fn next(&mut self) -> Option<Self::Item> {
        loop {
            if let Some(ref mut inner_iter) = self.inner {
                if let Some(i) = inner_iter.next() {
                    return Some(i);
                }
                self.inner = None;
            }

            let next_inner_iter = self.outer.next()?.into_iter();
            self.inner = Some(next_inner_iter);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty() {
        assert_eq!(flatten(std::iter::empty::<Vec<()>>()).count(), 0);
    }

    #[test]
    fn one() {
        assert_eq!(flatten(std::iter::once(vec!["a"])).count(), 1);
    }

    #[test]
    fn two() {
        assert_eq!(flatten(std::iter::once(vec!["a", "b"])).count(), 2);
    }

    #[test]
    fn two_wide() {
        assert_eq!(flatten(vec![vec!["a"], vec!["b"]].into_iter()).count(), 2);
    }
}
```

### version #3: impl DoubleEndedIterator trait

实现 `Iterator` trait 后，可以使用 `.next()` 从前往后进行迭代；实现 `DoubleEndedIterator` trait，就可以使用 `next_back()` 从后往前迭代。

直接看定义：

```rust
pub trait DoubleEndedIterator: Iterator {
    // Removes and returns an element from the end of the iterator.
    fn next_back(&mut self) -> Option<Self::Item>;
}
```

前、后是相对的，因此实现 `DoubleEndedIterator` trait，一定也实现了 `Iterator` trait （supertrait），同时 `next()` 和 `next_back()` 处理的是相同 Range，`next()` 从前往后，`next_back()` 从后往前，当二者相遇时，就没有剩余待处理的元素了，都返回 `None`。标准库文档中给到了一段代码示进行阐述，[代码 9，next-and-next-back](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=289b9ae3fa768a21647515c759f36473)。

```rust
fn main() {
    let numbers = vec![1, 2, 3, 4, 5, 6];

    let mut iter = numbers.iter();

    assert_eq!(Some(&1), iter.next());
    assert_eq!(Some(&6), iter.next_back());
    assert_eq!(Some(&5), iter.next_back());
    assert_eq!(Some(&2), iter.next());
    assert_eq!(Some(&3), iter.next());
    assert_eq!(Some(&4), iter.next());
    assert_eq!(None, iter.next());
    assert_eq!(None, iter.next_back());
}
```

回到 `flatten()` 的实现，为 `Flatten struct` 实现 `DoubleEndedIterator` trait，模仿着 [代码 8，version #2: save-inner-iter](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=7e2f1df53f70a2af30d02147f8fb3d31) 中 `next()` 的实现，补充 `next_back()` 的实现。同时需补充上外层迭代器和内层迭代器需要满足 `DoubleEndedIterator` trait bounds。[代码 10，version #3: impl-DoubleEndedIterator-trait](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=b65cce6accf0efc97c5ac5831c7c08cb)，增加了两个测试用例，测试正常。`flatten_iter.rev()` 返回 `struct std::iter::Rev`，`struct std::iter::Rev` 实现了 `Iterator` trait，`next()` 方法调用 `flatten_iter.next_back()`，感兴趣的读者可以查看 [`Recv` 标准库的源码实现](https://doc.rust-lang.org/src/core/iter/adapters/rev.rs.html#33)。

```rust {hl_lines=["7-19"]}
impl<O> DoubleEndedIterator for Flatten<O>
where
    O: Iterator + DoubleEndedIterator,
    O::Item: IntoIterator,
    <O::Item as IntoIterator>::IntoIter: DoubleEndedIterator,
{
    fn next_back(&mut self) -> Option<Self::Item> {
        loop {
            if let Some(ref mut inner_iter) = self.inner {
                if let Some(i) = inner_iter.next_back() {
                    return Some(i);
                }
                self.inner = None;
            }

            let next_inner_iter = self.outer.next_back()?.into_iter();
            self.inner = Some(next_inner_iter);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reverse() {
        assert_eq!(
            flatten(std::iter::once(vec!["a", "b"]).into_iter())
                .rev()
                .collect::<Vec<_>>(),
            vec!["b", "a"]
        );
    }

    #[test]
    fn reverse_wide() {
        assert_eq!(
            flatten(vec![vec!["a"], vec!["b"]].into_iter())
                .rev()
                .collect::<Vec<_>>(),
            vec!["b", "a"]
        );
    }
}
```

如果在 `flatten_iter` 上同时调用 `next()` 和 `next_back()` 会出现什么问题？前面提到，`next()` 和 `next_back()` 处理的是相同 Range。增加 `both_ends` 测试用例，测试报错：

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn both_ends() {
        let mut iter = flatten(
            vec![vec!["a1", "a2", "a3"], vec!["b1", "b2", "b3"]].into_iter());
        assert_eq!(iter.next(), Some("a1"));
        assert_eq!(iter.next_back(), Some("b3")); // a3
        assert_eq!(iter.next(), Some("a2"));
        assert_eq!(iter.next_back(), Some("b2"));
        assert_eq!(iter.next(), Some("a3"));
        assert_eq!(iter.next_back(), Some("b1"));
        assert_eq!(iter.next(), None);
        assert_eq!(iter.next_back(), None);
    }
}
```

分析原因：在外层迭代器上调用 `next()` 后，`inner` 保存的是第一个元素的内层迭代器，`next()` 和 `next_back()` 后续都是基于 `inner` 进行处理，对于 `next()` 返回符合预期，但 `next_back()` 返回的是 `inner` 迭代器最后一个元素，不符合预期（预期返回外层迭代器最后一个元素（其作为内部迭代器）的最后一个元素）。

{{< figure src="images/flatten-next-next-back-both-end.png" caption="图 5：`next()` 和 `next_back()` 迭代相同的 `inner`" >}}

### version #4: save front_iter and back_iter

也就是说，`next()` 迭代访问的内部迭代器与 `next_back()` 迭代访问的内部迭代器，需要分别保存，如下图所示，使用 `front_iter` 和 `back_iter` 表示。

```rust {hl_lines=["7-8"]}
pub struct Flatten<O>
where
    O: Iterator,
    O::Item: IntoIterator,
{
    outer: O,
    front_iter: Option<<O::Item as IntoIterator>::IntoIter>,
    back_iter: Option<<O::Item as IntoIterator>::IntoIter>,
}
```

{{< figure src="images/flatten-front-iter-and-back-iter.png" caption="图 6：`next()` 和 `next_back()` 分别迭代 `front_iter` 和 `back_iter`" >}}

由于 `next()` 和 `next_back()` 处理的是相同 Range，在迭代处理的最后，会出现两种类似的情况：

- 情况 1：`front_iter` 还有元素可以进行处理，`back_iter` 已处理完毕，调用 `next_back()` 时外层迭代器已经处理完毕；
- 情况 2：`back_iter` 还有元素可以进行处理，`front_iter` 已处理完毕，调用 `next()` 时外层迭代器已经处理完毕；

{{< figure src="images/flatten-front-iter-back-iter-only-one.png" caption="图 7：两种边界情况均需要继续进行迭代" >}}

这两种情况下，都要继续进行迭代。

基于以上分析，得到 `flatten()` 的第四个版本，[代码 11，version #4: save-front_iter-and-back_iter](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=f16e1494e0f61fa913876969439bd54d)。`next()` 和 `next_back()` 的主体逻辑与 version #2 和 version #3 一致，以 `next_back()` 的实现为例：

1、判断对应的内层迭代器 `back_iter` 是否有待处理的元素

- 刚开始迭代时，对应的内层迭代器均为 `None`，继续执行步骤 2；
- 进行处理，内层迭代器调用 `.next_back()`，有值，作为 `next_back()` 的调用返回值，返回；无值，说明内层迭代器已处理完毕，赋值为 `None` ，继续执行步骤 2；

2、判断对应的外层迭代器 `outer.next_back()` 是否有待处理的元素

- 存在待处理的元素 `Some(next_back_inner)`，获取外层迭代器对应的元素，`Some(next_back_inner.into_iter())` 赋值给内层迭代器 `back_iter`，循环处理，跳转到步骤 1 执行；
- 外层迭代器返回 `None`（对应图示情况 1），使用另一个内层迭代器 `front_iter` 进行迭代访问。

```rust {hl_lines=["22-25","51-54"]}
impl<O> Iterator for Flatten<O>
where
    O: Iterator,
    O::Item: IntoIterator,
{
    type Item = <O::Item as IntoIterator>::Item;

    fn next(&mut self) -> Option<Self::Item> {
        loop {
            // front_iter 还有数据可以遍历
            if let Some(ref mut front_iter) = self.front_iter {
                if let Some(i) = front_iter.next() {
                    return Some(i);
                }
                self.front_iter = None;
            }

            if let Some(next_inner) = self.outer.next() {
                // 外层迭代器还有元素待处理
                self.front_iter = Some(next_inner.into_iter());
            } else {
                // 处理图示情况 2
                // back_iter 被调用过一次，consume 了一个 outer Item，还有内容可以遍历
                // 此时调用 front_iter.next() 时需要返回数据
                return self.back_iter.as_mut()?.next();
            }
        }
    }
}

impl<O> DoubleEndedIterator for Flatten<O>
where
    O: Iterator + DoubleEndedIterator,
    O::Item: IntoIterator,
    <O::Item as IntoIterator>::IntoIter: DoubleEndedIterator,
{
    fn next_back(&mut self) -> Option<Self::Item> {
        loop {
            // back_iter 还有数据可以遍历
            if let Some(ref mut back_iter) = self.back_iter {
                if let Some(i) = back_iter.next_back() {
                    return Some(i);
                }
                self.back_iter = None;
            }

            if let Some(next_back_inner) = self.outer.next_back() {
                // 外层迭代器还有元素待处理
                self.back_iter = Some(next_back_inner.into_iter());
            } else {
                // 处理图示情况 1
                // front_iter 被调用过一次，consume 了一个 outer Item，还有内容可以遍历
                // 此时调用 back_iter.next_back() 时需要返回数据
                return self.front_iter.as_mut()?.next_back();
            }
        }
    }
}
```

注意：`next(&mut self)` 和 `next_back(&mut self)` 都是可变引用（mutable references），不能并发进行调用（活跃的可变引用只能存在一个，独占）。

至此，我们实现了自己的 `our_flatten(iter)` 🎉🎉🎉，入参迭代器作为函数参数传入，[代码 11，version #4: save-front_iter-and-back_iter](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=f16e1494e0f61fa913876969439bd54d)。

标准库 `flatten()` 的实现与上述实现基本一致，感兴趣的读者可以跳转过去查看

- 实现 `Iterator` trait —— https://doc.rust-lang.org/src/core/iter/adapters/flatten.rs.html#183
- 实现 `DoubleEndedIterator` trait —— https://doc.rust-lang.org/src/core/iter/adapters/flatten.rs.html#431

## Extension traits

为了让 API 更好用（Rust 中称为语言的人体工程学，[Rust's language ergonomics initiative](https://blog.rust-lang.org/2017/03/02/lang-ergonomics.html)），作为迭代器的方法直接调用 `iter.our_flatten()`，引入 [extension traits](https://github.com/rust-lang/rfcs/blob/master/text/0445-extension-trait-conventions.md)。

对于 extension traits，查看 Rust for Rustaceans Chapter 13.2 Pattern in the Wild：

> Extension traits allow crates to provide additional functionality to types that implement a trait from a different crate. For example, the `itertools` crate provides an extension trait for `Iterator`, which adds a number of convenient shortcuts for common (and not so common) iterator operations. As another example, `tower` provides `ServiceExt`, which adds several more ergonomic operations to wrap the low-level interface in the `Service` trait from `tower-service`.
>
> Extension traits tend to be useful either when you do not control the base trait, as with `Iterator`, or when the base trait lives in a crate of its own so that it rarely sees breaking releases and thus doesn’t cause unnecessary ecosystem splits, as with `Service`.
>
> An extension trait extends the base trait it is an extension of (`trait ServiceExt: Service`) and consists solely of provided methods. It also comes with a blanket implementation for any `T` that implements the base trait (`impl<T> ServiceExt for T where T: Service {}`). Together, these conditions ensure that the extension trait’s methods are available on anything that implements the base trait.

这段话中提到了两个例子，看看这两个例子是如何使用 extension traits 的。

### two examples of using extension traits

```rust
// https://docs.rs/itertools/0.10.3/src/itertools/lib.rs.html#429
// An Iterator blanket implementation that provides extra adaptors and methods.
pub trait Itertools : Iterator {
    // more than 100 methods ...
}

// https://docs.rs/itertools/0.10.3/src/itertools/lib.rs.html#3475
// blanket implementations
impl<T: ?Sized> Itertools for T where T: Iterator { }
```

`Iterator` trait 是 `Itertools` trait 的 [supertrait](https://doc.rust-lang.org/book/ch19-03-advanced-traits.html#using-supertraits-to-require-one-traits-functionality-within-another-trait)（前面提到的 `trait DerefMut: Deref` 和 `trait DoubleEndedIterator: Iterator` 都是如此），可以使用面向对象中的“**继承（inheriting）**”进行理解，`trait B: A`，是说任何类型 `T`，如果实现了 trait B（`impl B for T`），它也必须实现 trait A（`impl A for T`），换句话说，**trait B 在定义时可以使用 trait A 中的关联类型和方法**。

定义好 `Itertools` trait 后，提供方法的缺省实现，再为外部类型 `T`（使用 `where T: Iterator` 子句为 `T` 添加 trait bounds）实现 `Itertools` trait —— 即对于所有的满足 `Iterator` trait bounds 的类型 `T`，都实现了 `Itertools` trait —— 因此所有的迭代器都可以直接使用 `Itertools` trait 中的所有方法，相当于对 `Iterator` trait 进行了扩展（extension）。

同理，查看 `tower::ServiceExt` 源码实现：

```rust
// https://docs.rs/tower/0.4.11/src/tower/util/mod.rs.html#65
// An extension trait for `Service`s that provides a variety of convenient adapters
pub trait ServiceExt<Request>: tower_service::Service<Request> {
    // methods ...
}

// https://docs.rs/tower/0.4.11/src/tower/util/mod.rs.html#1055
// blanket implementations
impl<T: ?Sized, Request> ServiceExt<Request> for T
where
    T: tower_service::Service<Request> {}
```

两个例子使用 extension traits 的方式是一样的：

1、定义一个 `trait XxxxExt`，可以指定 supertrait，可以提供方法的缺省实现；

2、为外部类型实现步骤 1 中定义的 trait（`impl<T: ?Sized> XxxxExt for T where T: ExternalTrait { ... }`）。

注：外部类型约束 `ExternalTrait` trait 与 `XxxxExt` trait 不在同一个 crate。

### blanket implementations

为指定了 trait bounds 的外部类型 `T` 实现自定义的 `XxxxExt` trait，称为 blanket implementations。

例如，标准库中的 `ToString` trait —— 只要 `T` 实现了 `Display` trait，`T` 就实现了 `ToString` trait，就可以调用 `to_string()` 方法。

```rust {hl_lines=[5,9]}
// https://doc.rust-lang.org/src/alloc/string.rs.html#2357-2373
/// A trait for converting a value to a `String`.
pub trait ToString {
    /// Converts the given value to a `String`.
    fn to_string(&self) -> String;
}

// https://doc.rust-lang.org/src/alloc/string.rs.html#2383
impl<T: fmt::Display + ?Sized> ToString for T {
    default fn to_string(&self) -> String {
        let mut buf = String::new();
        let mut formatter = core::fmt::Formatter::new(&mut buf);
        // Bypass format_args!() to avoid write_str with zero-length strs
        fmt::Display::fmt(self, &mut formatter)
            .expect("a Display implementation returned an error unexpectedly");
        buf
    }
}
```

[cheats.rs](https://cheats.rs) 有 blanket implementations 的说明（对应的说明是默认折叠的，入口 Working with Types-Types, Traits, Generics-Generics-Blanket Implementations）。

{{< figure src="images/cheatsrs-blanket-implementations.png" caption="图 8：[cheats.rs](https://cheats.rs) 关于 blanket implementations 的说明" >}}

### traits with generic types

查看 `tower_service::Service<Request>` trait 的定义，使用了范型参数 `Request`，允许某个 service 的实现能处理多个不同的 `Request`；但对于某个确定的 `Request` 类型，只会返回对应的 `Respone` 类型，因此 `Response` 定义为关联类型，而非范型参数。

```rust {hl_lines=[3,4]}
// https://docs.rs/tower-service/0.3.1/tower_service/trait.Service.html
// Service trait 允许某个 service 的实现能处理多个不同的 Request
pub trait Service<Request> {
    type Response;
    type Error;
    type Future: Future<Output = Result<Self::Response, Self::Error>>;

    pub fn poll_ready(
        &mut self, 
        cx: &mut Context<'_>
    ) -> Poll<Result<(), Self::Error>>;
    pub fn call(&mut self, req: Request) -> Self::Future;
}
```

### why use associated types in Iterator trait?

基于 `tower_service::Service<Request>` trait 的定义，重新审视一下标准库中 `Iterator` trait 的定义：

```rust
// 使用关联类型（associated types）进行定义
trait Iterator {
    type Item;

    fn next(&mut self) -> Option<Self::Item>;
}
```

使用关联类型，定义迭代器每次返回的值；是否可以使用范型参数进行定义呢？

```rust
// 使用范型参数（generic type parameters）进行定义
trait Iterator<T> {
    fn next(&mut self) -> Option<T>;
}
```

以 [Counter](https://doc.rust-lang.org/stable/book/ch13-02-iterators.html#creating-our-own-iterators-with-the-iterator-trait) 为例：

```rust
struct Counter {
    count: u32,
}

impl Counter {
    fn new() -> Counter {
        Counter { count: 0 }
    }
}
```

使用范型参数定义，为 `Counter` 实现 `Iterator<T>` trait，`impl Iterator<u32> for Counter` / `impl Iterator<String> for Counter`，可以为 `Counter` 实现多种类型的迭代器（multiple implementations of `Iterator` for `Counter`），在调用时，需要指定类型，[代码 12，use-generic-define-Iterator-trait](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=3c0e439269e1e9076de77ab3f1df9bc7)。

```rust
// 使用范型参数（generic type parameters）进行定义
trait Iterator<T> {
    fn next(&mut self) -> Option<T>;
}

impl Iterator<u32> for Counter {
    fn next(&mut self) -> Option<u32> {
        if self.count < 5 {
            self.count += 1;
            Some(self.count)
        } else {
            None
        }
    }
}
```

使用关联类型定义，实现时指定一个确定的返回值类型，因此就只会有一种实现 `impl Iterator for Counter`，调用时不用指定类型。

```rust
// 使用关联类型（associated types）进行定义
trait Iterator {
    type Item;

    fn next(&mut self) -> Option<Self::Item>;
}

impl Iterator for Counter {
    type Item = u32;

    fn next(&mut self) -> Option<Self::Item> {
        if self.count < 5 {
            self.count += 1;
            Some(self.count)
        } else {
            None
        }
    }
}
```

二者的区别没有那么明显，但使用原则很明了：为某一类型（Type）实现 trait，若仅需要一种实现，使用关联类型（associated type），否则使用范型参数（generic type parameter）。

> Rust traits can be generic in one of two ways: with generic type parameters like `trait Foo<T>` or with associated types like `trait Foo { type Bar; }`. The difference between these is not immediately apparent, but luckily the rule of thumb is quite simple: **use an associated type if you expect only one implementation of the trait for a given type, and use a generic type parameter otherwise**.
>
> —— Rust for Rustaceans，Chapter 2.2 Generic Traits

- 对于 `Iterator` trait，将集合作为迭代器进行访问，集合的每个元素类型固定，因此选择关联类型（associated types）；
- 对于 `tower_service::Service<Request>` trait，需要为不同的 `Request` 实现不同的 trait，因此选择范型参数（generic type parameter）。

更多关于 generic and associated types 的内容可以参考 [StackOverflow 上的回答](https://stackoverflow.com/a/32065644)、博客 [On Generics and Associated Types](https://blog.thomasheartman.com/posts/on-generics-and-associated-types)、Rust for Rustaceans Chapter 2.2 Generic Traits。

### version #5: define IteratorExt trait

定义 `IteratorExt` trait，提供 `our_flatten()` 方法的缺省实现；同时，为外部类型 `T`（使用 `where T: Iterator` 子句为 `T` 添加 trait bounds）实现 `IteratorExt` trait，就可以直接在迭代器上调用我们实现的 `our_flatten()` 了，[代码 13，define-IteratorExt-trait](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=99a1fd34e596705960b259d6a39e998c)。

```rust {hl_lines=["1-14"]}
// traits 默认绑定了 `?Sized` trait
pub trait IteratorExt: Iterator {
    // IteratorExt trait 默认绑定了 `?Sized` trait
    // 也就是说，实现 IteratorExt trait 的类型可以是一个 unsized type（例如 str）
    // 同时 our_flatten 的参数类型是 pass by value
    // 因此对这个函数单独进行限制，Self: Sized
    fn our_flatten(self) -> Flatten<Self>
    where
        Self: Sized,  // --- 读者可以试着注释掉 playground 中的这行语句，看看编译报错信息
        Self::Item: IntoIterator,
    {
        flatten(self)
    }
}

impl<T: ?Sized> IteratorExt for T where T: Iterator {}

// 默认情况下，所有泛型类型参数都与 `Sized` trait 绑定
pub fn flatten<I>(iter: I) -> Flatten<I>
where
    I: Iterator, // I: Iterator + Sized
    I::Item: IntoIterator,
{
    Flatten::new(iter)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ext() {
        assert_eq!(vec![vec![1, 2]].into_iter().our_flatten().count(), 2);
    }
}
```

`our_flatten()` 的最终实现，我们添加了关于 `Sized` trait 的注释。

[`Sized` trait](https://doc.rust-lang.org/std/marker/trait.Sized.html) 为 [marker trait](https://doc.rust-lang.org/std/marker/index.html)，标记编译期能够确定大小的类型（Types with a constant size known at compile time）。如果一个类型不能在编译期间确定其大小（只能在运行时确定），则称其为 DST（dynamically sized type），例如 `str` 类型。

默认情况下：

- 所有范型参数（generic type parameters）都会隐式添加 `Sized` trait bound（all generic type parameters have an implicit bound of `Sized` by default）；
- 所有 trait 都是 DST，默认的 trait bound 为 `?Sized`，表示实现该 trait 的类型可以是 unsized type（不满足 `Sized` trait bound，例如 `str`），也可以是 sized type（满足 `Sized` trait bound，例如 `&str`）。

借助下面的示例代码进行理解，[代码 14，Sized-trait-pass-by-value-or-by-reference](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=f1a4ae4aea4d3466c4f68411ed5cb4de)。关于 `Sized` trait 更详细的介绍推荐阅读 [rust-blog/sizedness-in-rust](https://github.com/pretzelhammer/rust-blog/blob/master/posts/sizedness-in-rust.md)。

```rust {hl_lines=[20,23]}
// Trait 默认为 `?Sized` trait bound
// 实现该 trait 的类型可以是 unsized type，也可以是 sized type
trait Trait {
    // pass by value
    // 需要限制调用该方法的类型为 Sized
    fn method1(self)
    where
        Self: Sized,
    {
        println!("method1");
    }

    // pass by reference，编译期就能够知道大小
    fn method2(&self) {
        println!("method2");
    }
}

// 为 str（unsized type）实现 Trait trait
impl Trait for str {}

// 为 &str（sized type）实现 Trait trait
impl Trait for &str {}

fn main() {
    // "str".method1();// method1 参数为 Self, pass by value，需满足 Sized trait bound
    "str".method2();

    let hello: &str = "hello";
    hello.method1();
    hello.method2();
}
```

## Summary

在本文中，我们介绍了 Rust 外部迭代器的基础知识，包括 `Iterator` trait 的含义、从集合获取迭代器的三种方式、并对这三种方式进行了详细比较，接下来实现了我们自己的迭代器 `our_flatten()`，支持从前往后和从后往前同时遍历。最后，为 `Iterator` trait 引入 extension traits，让所有迭代器都可以直接调用 `our_flatten()`。

对于迭代器的 Laziness 特性，会在后续介绍闭包（closures）时，结合适配器（adapter）一起讲解。

除了对迭代器的介绍外，本文还对其他的知识点做了一些分析：

- `Deref` / `DerefMut` trait
- Deref coercion
- `for-in-loops`
- blanket implementations
- 关联类型（associated type）和范型参数（generic type parameter）
- extension traits
- etc ...

本文为作者学习 Rust 的一篇学习笔记，肯定存在遗漏或错误，欢迎大家在评论区讨论指出。

【系列文章】：

1、[Rust 中的生命周期](https://qiaoin.github.io/2021/12/15/rust-lifetime/)

2、[Rust 中的迭代器](https://qiaoin.github.io/2022/01/17/rust-iterator/)

3、更多 Rust 相关的文章，敬请期待

## 版权声明

本作品采用[知识共享署名 4.0 国际许可协议](http://creativecommons.org/licenses/by/4.0/)进行许可，转载时请注明原文链接。

## References

- Crust of Rust 系列 [Iterators](https://www.youtube.com/watch?v=yozQ9C69pNs&list=PLqbS7AVVErFiWDOAVrPt7aYmnuuOLYvOa&index=3&ab_channel=JonGjengset)，本文为学习此视频后的笔记
- [std::iter](https://doc.rust-lang.org/std/iter/index.html)，迭代器标准库文档，文中给到的标准库代码片段，在注释开始处均贴了对应的源码链接
- 极客时间专栏 [陈天 · Rust 编程第一课](https://time.geekbang.org/column/intro/100085301)，第 12 讲 - 第 16 讲，traits with generic types 的内容来源于第 13 讲
- [Rust The Book](https://doc.rust-lang.org/stable/book/)，Chapter 10、13、19.2、19.3
- [Design Patterns: Elements of Reusable Object-Oriented Software](https://book.douban.com/subject/1436745/), Chater 5.4 Iterator，内部迭代器（internal iterator）和外部迭代器（external iterator）的来源
- [rust - What are the main differences between a Rust Iterator and C++ Iterator? - Stack Overflow](https://stackoverflow.com/questions/48999776/what-are-the-main-differences-between-a-rust-iterator-and-c-iterator)
- [Creating an Iterator in Rust](https://aloso.github.io/2021/03/09/creating-an-iterator)，强烈推荐阅读，实现树的深度优先遍历
- [Programming Rust (2nd Edition)](https://book.douban.com/subject/34973905/)，Chapter 15，`dump` 示例来源，有修改
- [Rust for Rustaceans](https://book.douban.com/subject/35520588/)，Chapter 2.2 Generic Traits、Chapter 13.2 Pattern in the Wild
- [rfcs/0445-extension-trait-conventions.md at master · rust-lang/rfcs](https://github.com/rust-lang/rfcs/blob/master/text/0445-extension-trait-conventions.md)，extension traits 对应的 RFC
- [Extension traits in Rust](http://xion.io/post/code/rust-extension-traits.html)，描述了两种使用 extension traits 的场景
- [cheats.rs](https://cheats.rs/)，Iterators、Blanket Implementations、Sized
- [rust-blog/sizedness-in-rust](https://github.com/pretzelhammer/rust-blog/blob/master/posts/sizedness-in-rust.md)，强烈推荐阅读，关于 `Sized` trait 的所有内容，这篇博客都会给到解答
- [rust - When is it appropriate to use an associated type versus a generic type? - Stack Overflow](https://stackoverflow.com/questions/32059370/when-is-it-appropriate-to-use-an-associated-type-versus-a-generic-type)
- [Rust Playground](https://play.rust-lang.org/) 文中的代码示例都给到了 playground 的链接，在阅读的时候可以点击跳转过去 Run 起来看一下运行结果或错误提示
- 文中的所有图片均使用 [excalidraw](https://excalidraw.com/) 绘制
