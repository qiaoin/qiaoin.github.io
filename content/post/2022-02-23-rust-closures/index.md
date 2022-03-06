---
title: Rust 中的闭包：function-like types and their traits
author: qiaoin
date: '2022-02-23'
slug: rust-closures
categories:
  - 编程语言
  - Rust
tags:
  - Closures
  - Rust
  - Learning-by-doing
---

在本文中，我们首先介绍 Rust 中三种 function-like types，分别是 function items、function pointers、closures，讲解它们之间的区别与联系。另一大部分是分析 `Fn*` traits —— `FnOnce`、`FnMut`、`Fn` 三个 traits，梳理它们的 supertrait 关系，以及 `move` 关键字对 closures 的影响。

---

{{< toc >}}

---

## Three function-like types

Rust 中包含三种 function-like types：

1、[Function item types](https://doc.rust-lang.org/reference/types/function-item.html)

2、[Function pointer types](https://doc.rust-lang.org/reference/types/function-pointer.html)

3、[Closure types](https://doc.rust-lang.org/reference/types/closure.html)

### function item types

直接从示例代码开始，[代码 1，function-item-types](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=cfb527e705feff799a7459f0487d702d)：

```rust
fn main() {
    // `not_ptr_bar` is zero-sized, uniquely identifying `bar`
    // `not_ptr_bar`'s type == fn item `fn() -> i32 {bar}`
    let mut not_ptr_bar = bar;
    assert_eq!(std::mem::size_of_val(&not_ptr_bar), 0);
    assert_eq!(not_ptr_bar(), 42);

    // error[E0308]: mismatched types
    // lefe side == fn item `fn() -> _ {bar}`
    // right side == fn item `fn() -> _ {foo}`
    // different `fn` items always have unique types, even if their signatures are
    // the same change the expected type to be function pointer `fn() -> i32`
    not_ptr_bar = foo;

    // a shared reference to the zero-sized type identifying `bar`
    // `&bar` is never what you want when `bar` is a function
    // `shared_ref_bar`'s type == reference `&fn() -> i32 {bar}`
    let shared_ref_bar = &bar;
    assert_eq!(std::mem::size_of_val(&shared_ref_bar), mem::size_of::<usize>());// 8
    assert_eq!(shared_ref_bar(), 42);
}

fn bar() -> i32 {
    42
}

fn foo() -> i32 {
    32
}
```

使用 `fn bar() -> i32 { ... }` 创建函数，`bar` 作为函数名表示一个不可命名的类型，唯一标识该函数（a value of an unnameable type that uniquely identifies the function `bar`），称为 [function item types](https://doc.rust-lang.org/reference/types/function-item.html)。function item types 是 ZST（Zero-Sized-Type, contains no data），因为类型已经唯一确定函数了，在执行函数调用时无需动态派发（no indirection is needed when the function is called; does not require dynamic dispatch）。

注意到 `bar` 和 `foo` 有相同的函数签名，但表示 function item types 时为不同的类型，因此不能相互赋值（`error[E0308]: mismatched types`）。编译器的错误信息中，将 `bar` function item type 打印为 `fn() -> i32 {bar}`（函数名 `bar` 包含在 `{}` 中）。

感兴趣的同学可以查看 [Implement unique types per fn item, rather than having all fn items have fn pointer type by nikomatsakis · Pull Request #19891](https://github.com/rust-lang/rust/pull/19891)。

funtion item types 唯一标识对应的函数（unique identifier），那对于包含有范型参数（generic type parameters）的函数应如何处理？

[代码 2，function-item-types-with-generic-type](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=05608259d3531c815a920f312d8c73d8)，范型参数作为 function item types 的一部分。

```rust
fn main() {
    // error[E0282]: type annotations needed for `fn() -> i32`
    // let without_generic_type_bar = bar;

    // `with_i32_bar`'s type == fn item `fn() -> i32 {bar::<i32>}`
    let mut with_i32_bar = bar::<i32>;
    assert_eq!(std::mem::size_of_val(&with_i32_bar), 0);

    // error[E0308]: mismatched types
    // left type == fn item `fn() -> _ {bar::<i32>}`
    // right type == fn item `fn() -> _ {bar::<u32>}`
    // different `fn` items always have unique types, even if their signatures are
    // the same change the expected type to be function pointer `fn() -> i32`
    // if the expected type is due to type inference,
    // cast the expected `fn` to a function pointer: `bar::<i32> as fn() -> i32`
    with_i32_bar = bar::<u32>;
}

fn bar<T>() -> i32 {
    42
}
```

所有的 function items 均实现了以下 traits：

- [`Fn`](https://doc.rust-lang.org/std/ops/trait.Fn.html)
- [`FnMut`](https://doc.rust-lang.org/std/ops/trait.FnMut.html)
- [`FnOnce`](https://doc.rust-lang.org/std/ops/trait.FnOnce.html)
- [`Copy`](https://doc.rust-lang.org/reference/special-types-and-traits.html#copy)
- [`Clone`](https://doc.rust-lang.org/reference/special-types-and-traits.html#clone)
- [`Send`](https://doc.rust-lang.org/reference/special-types-and-traits.html#send)
- [`Sync`](https://doc.rust-lang.org/reference/special-types-and-traits.html#sync)

`error[E0308]` 提示信息中，编译器建议将 funtciont item types 转换为 function pointer types。什么是 function pointer types 呢？

### function pointer types

> Function pointers are pointers that point to **code**, not data. They can be called just like functions.

与 function item types 不同（function item types 不可命名，Rust 编译器打印为 `fn() -> i32 {bar}`，函数名 `bar` 包含在 `{}` 中），function pointer types 使用 `fn` 关键字进行命名（表示为 `fn() -> i32`），指向函数的入口地址（refer to a function whose identity is not necessarily known at compile-time），可以经由 function items 和 non-capturing [closures](https://doc.rust-lang.org/reference/types/closure.html) 转换得到。先看一下 function items 到 function pointers 的类型转换（non-capturing closures 到 function pointers 的类型转换在下一小节介绍），[代码 3，create-function-pointers-by-function-items](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=436e5f77b3e16dccf3b67d620e056178)：

```rust
fn main() {
    // `not_ptr_bar` is zero-sized, uniquely identifying `bar`
    // `not_ptr_bar`'s type == fn item `fn() -> i32 {bar}`
    let not_ptr_bar = bar;
    assert_eq!(std::mem::size_of_val(&not_ptr_bar), 0);
    assert_eq!(not_ptr_bar(), 42);

    // force coercion to function pointer
    // `ptr_bar`'s type == funtion pointer `fn() -> i32`
    let mut ptr_bar: fn() -> i32 = not_ptr_bar;
    assert_eq!(std::mem::size_of_val(&ptr_bar), std::mem::size_of::<usize>());
    assert_eq!(ptr_bar(), 42);

    // force coercion to function pointer
    // `ptr_bar`'s type == funtion pointer `fn() -> i32`
    ptr_bar = foo;
    assert_eq!(std::mem::size_of_val(&ptr_bar), std::mem::size_of::<usize>());
    assert_eq!(ptr_bar(), 32);
}

fn bar() -> i32 {
    42
}

fn foo() -> i32 {
    32
}
```

使用 Rust MIR（**M**id-level **I**ntermediate **R**epresentation，一种中间表示，我们只需能够阅读并理解即可，本文会大量使用 Rust MIR 进行内容阐述 ⚠️。关于 Rust MIR 的资料见本文附录 A）查看类型转换（[type-coercion](https://doc.rust-lang.org/reference/type-coercions.html)），有两种在线方式输出 MIR：

- 方式 1：[Rust Playground](https://play.rust-lang.org/)，左上角「RUN ▶️  ...」，点击「...」选择 MIR；
- 方式 2：[Compiler Explorer](https://godbolt.org/)，「➕ Add new...」选择「Rust MIR output」，输出的 MIR 支持关键字高亮展示和代码块折叠，本文截图都使用 Compiler Explorer。

将 `assert_eq!()` 删除，保留最简单的一段代码，function items 到 function pointers 的隐式类型转换，对应图 1 右侧 Line 25，使用 `as` 关键字将 `_3` 的 `fn() -> i32 {bar}` 转换为 `fn() -> i32 (Pointer(ReifyFnPointer))`，`ReifyFnPointer` 文档说明见 [PointerCast in rustc_middle::ty::adjustment](https://doc.rust-lang.org/nightly/nightly-rustc/rustc_middle/ty/adjustment/enum.PointerCast.html#variant.ReifyFnPointer) —— 「Go from a fn-item type to a fn-pointer type」。

{{< figure src="images/fn-item-force-coercion-fn-pointer.png" caption="图 1：fn items 转换为 fn pointers" >}}

以下两种情况会进行 function item type 到  function pointer type 的转换：

- 1、显式指定时：显式进行类型指定 `let ptr_bar: fn() -> i32 = not_ptr_bar;`（a function item is used when a function pointer is directly expected）；
- 2、模式匹配时：`if` or `match` 模式匹配中，相同函数签名的不同 function item types（different function item types with the same signature meet in different arms of the same `if` or `match`）。

```rust
fn foo<T>() -> i32 {
    42
}

// `foo_ptr_1` has function pointer type `fn() -> i32` here
let foo_ptr_1: fn() -> i32 = foo::<i32>;

// ... and so does `foo_ptr_2` - this type-checks.
let foo_ptr_2 = if want_i32 {
    foo::<i32>
} else {
    foo::<u32>
};
```

所有的 function pointers 均实现了以下 traits：

- [`Copy`](https://doc.rust-lang.org/std/marker/trait.Copy.html)
- [`Clone`](https://doc.rust-lang.org/std/clone/trait.Clone.html)
- [`PartialEq`](https://doc.rust-lang.org/std/cmp/trait.PartialEq.html)
- [`Eq`](https://doc.rust-lang.org/std/cmp/trait.Eq.html)
- [`PartialOrd`](https://doc.rust-lang.org/std/cmp/trait.PartialOrd.html)
- [`Ord`](https://doc.rust-lang.org/std/cmp/trait.Ord.html)
- [`Hash`](https://doc.rust-lang.org/std/hash/trait.Hash.html)
- [`Pointer`](https://doc.rust-lang.org/std/fmt/trait.Pointer.html)
- [`Debug`](https://doc.rust-lang.org/std/fmt/macro.Debug.html)

此外，所有的 **safe** function pointers 同时还实现了 [`Fn`](https://doc.rust-lang.org/std/ops/trait.Fn.html)、[`FnMut`](https://doc.rust-lang.org/std/ops/trait.FnMut.html) 和 [`FnOnce`](https://doc.rust-lang.org/std/ops/trait.FnOnce.html) traits。function pointers safety 相关的内容参见文档 [Safety](https://doc.rust-lang.org/std/primitive.fn.html#safety)。

接下来看一下 closures。

### closure types

Rust reference 对 [closure types](https://doc.rust-lang.org/reference/types/closure.html) 的介绍如下：

> A [closure expression](https://doc.rust-lang.org/reference/expressions/closure-expr.html) produces a closure value with a unique, anonymous type that cannot be written out. A closure type is approximately equivalent to a struct which contains the captured variables.

使用闭包语法（`|args| expression`）创建闭包，与 function item types 类似，每个闭包对应一个唯一的、不可命名的类型（闭包类型在生成的 MIR 中有体现，但无法在 Rust 代码的其他地方使用）。这个类型就像一个 `struct`，捕获的自由变量表示为 `struct` 的字段。

闭包类似于一个特殊的 `struct`？

写段代码测试，[代码 4，closure-types](https://play.rust-lang.org/?version=nightly&mode=debug&edition=2021&gist=e43563a0fe2c44d22239bfad8676cba1)，闭包类型大小与 `struct Person` 大小一致（内存对齐的规则也是一致的）。

```rust
// 闭包等价的结构体，该结构体需实现 FnOnce trait
// 对应图 2 中标记 2
// struct Person(String, u32); 
struct Person {
    name: String,
    age: u32,
}

enum Gender {
    Male,
    Famale,
}

fn main() {
    let name = String::from("qiao");  // 24 bytes
    let age: u32 = 28;  // 4 bytes
    // 捕获 name 和 age，类似 struct Person
    let me = move |gender: Gender| (name, age, gender);

    assert_eq!(std::mem::size_of_val(&me), 32);  // 内存对齐
    assert_eq!(std::mem::size_of::<Person>(), 32);  // 内存对齐

    let person = me(Gender::Male);
}
```

简化代码，图 2 为编译器生成的 MIR 中间代码，`me` 表示的闭包类型为 `[closure@/app/example.rs:10:14: 10:55]`（图 2 标记 1），包含两个字段，类型分别为 `std::string::String` 和 `u32`（图 2 标记 2），在执行调用时将闭包类型转换为 `FnOnce<(Gender,)>`，然后调用 `call_once([closure@/app/example.rs:10:14: 10:55], Gender)`（图 2 标记 3），对应匿名函数 `fn main::{closure#0}(_1: [closure@/app/example.rs:10:14: 10:55], _2: Gender) -> (String, u32, Gender)`（图 2 标记 4）。

{{< figure src="images/closure-impl-FnOnce-trait.png" caption="图 2：闭包类型实现 FnOnce trait，对应的 MIR" >}}

注意，标记 1 处的闭包类型包含有行号+列号（这只是目前 Rust MIR 对闭包类型的一种表示，唯一标识闭包类型），因此，图 3 中的赋值，即使二者定义完全相同，编译器也会报错 —— 类型不一致：

{{< figure src="images/same-signature-different-closures.png" caption="图 3：相同签名的闭包定义对应不同的闭包类型表示" >}}

图 2 中的标记 2、3、4 是相互关联的，将标记 0 处的代码修改一下，可以得到以下几个变种：

- shared reference —— 对应图 4，见下文；
- mutable reference —— 对应图 5，见下文；
- move or copy —— 对应图 2，显式 move 语义。

对于捕获到的变量，仅使用不可变引用，闭包类型为 `[closure@/app/example.rs:10:14: 10:52]`（图 4 标记 1），包含两个字段，类型分别为 `&std::string::String` 和 `&u32`（图 4 标记 2），实现 `Fn` trait（图 4 标记 3），匿名函数的第一个入参为不可变引用 `_1: &[closure@/app/example.rs:10:14: 10:52]`（图 4 标记 4）；

{{< figure src="images/closure-impl-Fn-trait.png" caption="图 4：闭包类型实现 Fn trait，对应的 MIR" >}}

对于捕获到的变量，执行修改，闭包类型为 `[closure@/app/example.rs:10:18: 13:6]`（图 5 标记 1），包含两个字段，类型分别为 `&mut std::string::String` 和 `&mut u32`（图 5 标记 2），实现 `FnMut` trait（图 5 标记 3），匿名函数的第一个入参为可变引用 `_1: &mut [closure@/app/example.rs:10:18: 13:6]`（图 5 标记 4）；

{{< figure src="images/closure-impl-FnMut-trait.png" caption="图 5：闭包类型实现 FnMut trait，对应的 MIR" >}}

将上述三个变种的闭包类型表示为 `C`（for closure type），表 1：

|                 | 图 2 - 显式 move    | 图 4 - 不可变引用    | 图 5 - 可变引用           |
| --------------- | ------------------- | -------------------- | ------------------------- |
| C.0             | std::string::String | &std::string::String | &mut std::string::String  |
| C.1             | u32                 | &u32                 | &mut u32                  |
| trait & method  | FnOnce::call_once() | Fn::call()           | FnMut::call_mut()         |
| first param `C` | self                | &self                | &mut self                 |
| call type `C`   | call-by-value       | call-by-reference    | call-by-mutable-reference |

图 6 为 [cheats.rs](https://cheats.rs/#closures-data) 上对 closures data layout 的介绍，同时生成的匿名函数 `fn` —— `f(C1, X)` 或 `f(&C2, X)` —— 即对应图 2、图 4、图 5 中的标记 4。

{{< figure src="images/cheatsrs-closures-data-layout.png" caption="图 6：closures data layout" >}}

上一小节中提到，non-capturing closures 可以转换为 function pointers，同样写段测试代码，[代码 5，non-capturing-closure-coerce-fn-pointer](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=47a498c5e14c8426d7fc0257b837bac3)，`closure_add` 未捕获自由变量，size 为 0。

```rust
fn main() {
    // `closure_add` is zero-sized, capturing no variables from env
    // `closure_add`'s type == closure@path:line:column
    let closure_add = |x: u32, y: u32| -> u32 { x + y };
    assert_eq!(std::mem::size_of_val(&closure_add), 0);
    assert_eq!(closure_add(1, 2), 3);

    // force coercion to function pointer
    // `ptr_add`'s type == funtion pointer `fn(u32, u32) -> u32`
    let ptr_add: fn(u32, u32) -> u32 = closure_add;
    assert_eq!(std::mem::size_of_val(&ptr_add), 8);
    assert_eq!(ptr_add(1, 2), 3);
}
```

简化代码，图 7 是编译器为 non-capturing closure（图 7 标记 0）生成的 MIR 中间代码，`closure_add` 表示的闭包类型为 `[closure@/app/example.rs:4:23: 4:56]`（图 7 标记 1），在执行调用时将闭包类型转换为 `Fn<(u32, u32)>`，然后调用 `call([closure@/app/example.rs:4:23: 4:56], (u32, u32))`（图 7 标记 2），对应匿名函数 `fn main::{closure#0}(_1: &[closure@/app/example.rs:4:23: 4:56], _2: u32, _3: u32) -> u32`（图 7 中标记 3）。

对于 non-capturing closures 到 function pointers 的转换（图 7 标记 4），`as` 关键字将 `_6` 的 `[closure@/app/example.rs:4:23: 4:56]` 转换为 `fn(u32, u32) -> u32 (Pointer(ClosureFnPointer(Normal))`，`ClosureFnPointer(Normal)` 文档说明见 [PointerCast in rustc_middle::ty::adjustment](https://doc.rust-lang.org/nightly/nightly-rustc/rustc_middle/ty/adjustment/enum.PointerCast.html#variant.ClosureFnPointer) —— 「Go from a non-capturing closure to an fn pointer or an unsafe fn pointer. It cannot convert a closure that requires unsafe」。

{{< figure src="images/non-capturing-closure-coerce-fn-pointer.png" caption="图 7：non-capturing closures 实现 Fn trait，可转换为 fn pointers" >}}

closure types 对 `Fn*` trait 的实现，直接引用 Rust reference 中 [Closure types - Call traits and coercions](https://doc.rust-lang.org/reference/types/closure.html#call-traits-and-coercions) 的介绍：

> Closure types all implement [`FnOnce`](https://doc.rust-lang.org/std/ops/trait.FnOnce.html), indicating that they can be called once by consuming ownership of the closure. Additionally, some closures implement more specific call traits:
>
> - A closure which does not move out of any captured variables implements [`FnMut`](https://doc.rust-lang.org/std/ops/trait.FnMut.html), indicating that it can be called by mutable reference.
> - A closure which does not mutate or move out of any captured variables implements [`Fn`](https://doc.rust-lang.org/std/ops/trait.Fn.html), indicating that it can be called by shared reference.
>
> Note: `move` closures may still implement [`Fn`](https://doc.rust-lang.org/std/ops/trait.Fn.html) or [`FnMut`](https://doc.rust-lang.org/std/ops/trait.FnMut.html), even though they capture variables by move. This is because **the traits implemented by a closure type are determined by what the closure does with captured values, not how it captures them.**

看完这段引用，可能会有点迷糊，不用着急，`Fn`、`FnMut`、`FnOnce` 三个 function traits 的介绍和 closure types 与 `Fn*` traits 之间的联系，会在下一节 Three `Fn*` traits 详细讲解，到时候读者再来看上面这段引用，就会一目了然了。

### summary

参考 StackOverflow 上的这个 [问题](https://stackoverflow.com/questions/27895946/expected-fn-item-found-a-different-fn-item-when-working-with-function-pointer)，补充上 no capturing closure，[代码 6，three-function-like-types-and-type-coercion](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=13b2997636a647bcd1a98dea7dc2f8d7)，按照 `call_three(foo, bar, baz);` 直接进行调用，编译器报类型不匹配：

- `foo` 类型为 fn item `fn() -> _ {foo}`（fn items 实现了 `Fn` trait，满足 `call_three` 的 trait bounds），因此 generic type `F` 绑定为 `fn() -> i32 {foo}`；
- `bar` 类型为 fn item `fn() -> _ {bar}`，按照 `call_three` 函数签名，需要为 `F` 类型（`F` 已绑定为 `fn() -> i32 {foo}`），但由于每一个 fn item 都是一个唯一标识的类型（unique identifies），因此类型不一致；
- `baz` 类型为 closure `[closure@src/main.rs:2:15: 2:20]`，同样，按照 `call_three` 函数签名，需要为 `F` 类型（`fn() -> i32 {foo}`），很明显类型不一致。

```rust
fn main() {
    // no capturing closure
    let baz = || 49;

    // call_three(foo, bar, baz);  // error[E0308]: mismatched types

    call_three(foo as fn() -> i32, bar as fn() -> i32, baz as fn() -> i32);
    call_three(foo as fn() -> i32, bar, baz);

    call_three::<fn() -> i32>(foo, bar, baz);
    call_three::<fn() -> _>(foo, bar, baz);
}

// foo and bar with the signature `fn() -> i32`
fn foo() -> i32 {
    32
}

fn bar() -> i32 {
    42
}

fn call_three<F>(a: F, b: F, c: F)
where
    F: Fn() -> i32,
{
    a();
    b();
    c();
}
```

明确了错误原因，修复比较简单，让 generic type `F` 的类型设置为 fn pointer `fn() -> i32`（fn pointers 实现了 `Fn` trait，满足 `call_three` 的 trait bounds），有几种方式：

- 1、显式使用 `as fn() -> i32` 对入参做类型转换；
- 2、使用 `turbofish` 语法 `call_three::<fn() -> i32>(...)` 指定 generic type，文档参见 [Where to put the turbofish](https://matematikaadit.github.io/posts/rust-turbofish.html)。

结合图 8 进行理解。

{{< figure src="images/fn-like-types-coercion-and-fn-traits.png" caption="图 8：三类 function-like types 之间的关系，以及对 `Fn*` traits 的实现" >}}

为什么 function items 和 no-capturing closures 可以转换为 function pointers？而 capture env closures 不能转换为 function pointers？

function items 和 function pointers 都没有 `Self`（they don't care about `Self`），它们表示为内存中的一段代码，未指向其他的 references 或者其他任何东西

- 没有指向不是所属自己的内存；
- 类型本身没有生命周期标志。

按照这个思路思考闭包类型 `C`，capture env variables 的时候，对应 `C` 是包含字段的，也就是有状态的；而 function items 和 no-capturing closures 是没有状态的，因此可以转换为 function pointers。

## Three `Fn*` traits

直接看 `Fn*` traits 的定义。

### FnOnce trait

```rust
// https://doc.rust-lang.org/src/core/ops/function.rs.html#219-228
pub trait FnOnce<Args> {
    /// The returned type after the call operator is used.
    #[lang = "fn_once_output"]
    #[stable(feature = "fn_once_output", since = "1.12.0")]
    type Output;

    /// Performs the call operation.
    #[unstable(feature = "fn_traits", issue = "29625")]
    extern "rust-call" fn call_once(self, args: Args) -> Self::Output;
}
```

包含两个部分：

- 关联类型（associated types）。`Output` 定义了闭包返回的数据类型；
- 方法（methods），也称关联函数（associated functions）。`call_once` 第一个参数是 `self`，会转移 `self` 的所有权到 `call_once` 函数中。因此，在仅实现了 `FnOnce` trait 类型的实例上，**只能进行一次调用**；再次调用，编译器会提示 [`error[E0382]`: use of moved value](https://doc.rust-lang.org/stable/error-index.html#E0382)。

在 [代码 4，closure-types](https://play.rust-lang.org/?version=nightly&mode=debug&edition=2021&gist=e43563a0fe2c44d22239bfad8676cba1) 中再次调用 `me`：

```rust
enum Gender {
    Male,
    Famale,
}

fn main() {
    let name = String::from("qiao");
    let age: u32 = 28;
    let me = move |gender: Gender| (name, age, gender);

    let person1 = me(Gender::Male);
    
    let person2 = me(Gender::Famale);
}
```

编译器给到的报错信息很明确 —— `me` 对应的闭包类型实现了 `FnOnce` trait，调用时会将 `me`（捕获自由变量 `name`）的所有权转移到 `call_once` 函数中，再次调用时提示 value used here after move：

```bash
error[E0382]: use of moved value: `me`
  --> src/main.rs:13:19
   |
11 |     let person = me(Gender::Male);
   |                  ---------------- `me` moved due to this call
12 | 
13 |     let person2 = me(Gender::Famale);
   |                   ^^ value used here after move
   |
note: closure cannot be invoked more than once because it moves the variable `name`
  out of its environment
  --> src/main.rs:9:37
   |
9  |     let me = move |gender: Gender| (name, age, gender);
   |                                     ^^^^
note: this value implements `FnOnce`, which causes it to be moved when called
  --> src/main.rs:11:18
   |
11 |     let person = me(Gender::Male);
   |                  ^^

For more information about this error, try `rustc --explain E0382`.
```

针对上述代码示例，在 nightly 环境下试着为 `struct Person` 实现 `FnOnce` trait（[代码 7，impl-FnOnce-for-struct-Person](https://play.rust-lang.org/?version=nightly&mode=debug&edition=2021&gist=22cc0902869faaecbe0c1c5f61f3915e)），enable 两个 unstable feature flags，对应 [Tracking issue for Fn traits (`unboxed_closures` & `fn_traits` feature) · Issue #29625 · rust-lang/rust](https://github.com/rust-lang/rust/issues/29625)。

- [fn_traits](https://doc.rust-lang.org/beta/unstable-book/library-features/fn-traits.html) —— 允许用户为自定义类型实现 `Fn*` traits，实现后该 closure-like types 可以作为函数进行调用；
- [unboxed_closures](https://doc.rust-lang.org/beta/unstable-book/language-features/unboxed-closures.html) —— 允许用户在实现 `Fn*` traits 时使用 "rust-call" ABI，"rust-call" ABI 只能有唯一一个入参（非 `self`），使用 tuple 表示参数列表（the argumements must be a tuple representing the argument list），例如 `args: (Gender,)`，更多信息参考错误列表 [E0045](https://doc.rust-lang.org/error-index.html#E0045)、[E0059](https://doc.rust-lang.org/error-index.html#E0059)、[E0183](https://doc.rust-lang.org/error-index.html#E0183)。

```rust
#![feature(fn_traits, unboxed_closures)]

#[derive(Debug)]
struct Person {
    name: String,
    age: u32,
}

impl FnOnce<(Gender,)> for Person {
    type Output = ();

    extern "rust-call" fn call_once(self, args: (Gender,)) -> Self::Output {
        println!("\n---- FnOnce call_once");
        ()
    }
}

#[derive(Debug)]
enum Gender {
    Male,
    Famale,
}

fn main() {
    let name = String::from("qiao");
    let age: u32 = 28;
    let person = Person { name, age };

    println!("{:?}", person);  // Person { name: "qiao", age: 28 }

    // 两种调用方式都可以
    // <Person as FnOnce<(Gender,)>>::call_once(person, (Gender::Famale,));
    person(Gender::Famale);  // ---- FnOnce call_once

    // println!("{:?}", person);  // error[E0382]: borrow of moved value: `person`
    
    // person(Gender::Famale);  // error[E0382]: use of moved value: `person`
}
```

### FnMut trait

```rust
// https://doc.rust-lang.org/src/core/ops/function.rs.html#147-151
pub trait FnMut<Args>: FnOnce<Args> {
    /// Performs the call operation.
    #[unstable(feature = "fn_traits", issue = "29625")]
    extern "rust-call" fn call_mut(&mut self, args: Args) -> Self::Output;
}
```

`FnOnce` 是 `FnMut` 的 supertrait，因此为 `Person` 实现 `FnMut` trait，需要先实现 `FnOnce` trait —— 在 [代码 7，impl-FnOnce-for-struct-Person](https://play.rust-lang.org/?version=nightly&mode=debug&edition=2021&gist=22cc0902869faaecbe0c1c5f61f3915e) 的基础上，添加 `FnMut` trait 的实现（[代码 8，impl-FnMut-for-struct-Person](https://play.rust-lang.org/?version=nightly&mode=debug&edition=2021&gist=a3f970a893ac3bb7616147d25ffd2132)），执行调用时会优先使用 `<Person as FnMut<(Gender,)>>::call_mut(&mut person, (Gender::Famale,))` 进行调用：

```rust
// 完整代码点击跳转 代码 8 playground
impl FnMut<(Gender,)> for Person {
    extern "rust-call" fn call_mut(&mut self, args: (Gender,)) -> Self::Output {
        println!("\n---- FnMut call_mut");
        self.name = String::from("qiaoin");
        self.age = 29;
        ()
    }
}

fn main() {
    let name = String::from("qiao");
    let age: u32 = 28;
    let mut person = Person { name, age };

    println!("{:?}", person);  // Person { name: "qiao", age: 28 }

    // 两种调用方式都可以
    // <Person as FnMut<(Gender,)>>::call_mut(&mut person, (Gender::Famale,));
    person(Gender::Famale);  // FnMut call_mut

    println!("{:?}", person);  // Person { name: "qiaoin", age: 29 }
    
    person(Gender::Famale);  // 再次调用，FnMut call_mut
}
```

`Person` 实现了 `FnMut` trait 后，编译器会自动为 `&mut Person` 实现 `FnOnce` 和 `FnMut` traits（对应 [Issue #23015](https://github.com/rust-lang/rust/issues/23015)，[PR #23895](https://github.com/rust-lang/rust/pull/23895)，感兴趣的读者可以翻看一下） ：

```rust
// https://doc.rust-lang.org/src/core/ops/function.rs.html#263-282
impl<A, F: ?Sized> FnMut<A> for &mut F
where
    F: FnMut<A>,
{
    // self: &mut &mut Person
    extern "rust-call" fn call_mut(&mut self, args: A) -> F::Output {
        (*self).call_mut(args)
    }
}

impl<A, F: ?Sized> FnOnce<A> for &mut F
where
    F: FnMut<A>,
{
    type Output = <F as FnOnce<A>>::Output;

    // self: &mut Person
    extern "rust-call" fn call_once(self, args: A) -> F::Output {
        (*self).call_mut(args)
    }
}
```

### Fn trait

```rust
// https://doc.rust-lang.org/src/core/ops/function.rs.html#67-71
pub trait Fn<Args>: FnMut<Args> {
    /// Performs the call operation.
    #[unstable(feature = "fn_traits", issue = "29625")]
    extern "rust-call" fn call(&self, args: Args) -> Self::Output;
}
```

`Fn` trait，也是同理 —— 需要先实现 supertrait `FnMut` 和 `FnOnce` traits —— 在 [代码 8，impl-FnMut-for-struct-Person](https://play.rust-lang.org/?version=nightly&mode=debug&edition=2021&gist=a3f970a893ac3bb7616147d25ffd2132) 的基础上，添加 `Fn` trait 的实现（[代码 9，impl-Fn-for-struct-Person](https://play.rust-lang.org/?version=nightly&mode=debug&edition=2021&gist=6e97c0e64bb92ae2ef6ac7ad802af7b7)），执行调用时会优先使用 `<Person as Fn<(Gender,)>>::call(&person, (Gender::Famale,))` 进行调用：

```rust
// 完整代码点击跳转 代码 9 playground
impl Fn<(Gender,)> for Person {
    // self: &Person
    extern "rust-call" fn call(&self, args: (Gender,)) -> Self::Output {
        println!("\n---- Fn call");
        ()
    }
}

fn main() {
    let name = String::from("qiao");
    let age: u32 = 28;
    let person = Person { name, age };

    println!("{:?}", person);  // Person { name: "qiao", age: 28 }

    // 两种调用方式都可以
    // <Person as Fn<(Gender,)>>::call(&person, (Gender::Famale,));
    person(Gender::Famale);  // Fn call

    println!("{:?}", person);  // Person { name: "qiao", age: 28 }
    
    person(Gender::Famale);  // 再次调用，Fn call
}
```

同样的，`Person` 实现了 `Fn` trait 后，编译器会为 `&Person` 实现 `FnOnce`、`FnMut` 和 `Fn` traits（对应 [Issue #23015](https://github.com/rust-lang/rust/issues/23015)，[PR #23895](https://github.com/rust-lang/rust/pull/23895)，感兴趣的读者可以翻看一下） ：

```rust
// https://doc.rust-lang.org/src/core/ops/function.rs.html#231-261
impl<A, F: ?Sized> Fn<A> for &F
where
    F: Fn<A>,
{
    extern "rust-call" fn call(&self, args: A) -> F::Output {
        (**self).call(args)
    }
}

impl<A, F: ?Sized> FnMut<A> for &F
where
    F: Fn<A>,
{
    extern "rust-call" fn call_mut(&mut self, args: A) -> F::Output {
        (**self).call(args)
    }
}

impl<A, F: ?Sized> FnOnce<A> for &F
where
    F: Fn<A>,
{
    type Output = F::Output;

    extern "rust-call" fn call_once(self, args: A) -> F::Output {
        (*self).call(args)
    }
}
```

基于 [代码 9，impl-Fn-for-struct-Person](https://play.rust-lang.org/?version=nightly&mode=debug&edition=2021&gist=6e97c0e64bb92ae2ef6ac7ad802af7b7) 和 Rust 编译器自动实现的一些 `Fn*` traits，写一段代码测试一下，`main` 中的测试分为三组，[代码 10，test-all-manual-and-auto-Fn-traits](https://play.rust-lang.org/?version=nightly&mode=debug&edition=2021&gist=25d22d1191758641800e3054f282f56d)：

- 第 1 组：测试为 `Person` 实现的 `Fn*` traits（手动实现）；
- 第 2 组：测试为 `&mut Person` 实现的 `Fn*` traits（Rust 编译器自动实现，放到了代码注释中）；
- 第 3 组：测试为 `&Person` 实现的 `Fn*` traits（Rust 编译器自动实现，放到了代码注释中）。

TODO: 对 Line 132-134 有点疑问，`&mut` 未实现 `Copy` trait，为什么所有权转移后还可以被访问？

编译器提供自动实现，在作为参数传递时很有用（满足 trait bounds），可以查看 [Issue #23015](https://github.com/rust-lang/rust/issues/23015)，另外本文 `mut` keyword 小节也会有详细的讲解。

对于 `person()` 调用时优先匹配的问题，由于 `person` 的类型为 `struct Person`，候选类型列表为 `[Person, &Person, &mut Person]`，但测试时发现，`main` 中没有 trait bounds 时，编译器时按照 `Fn::call(&self)`、`FnMut::call_mut(&mut self)`、`FnOnce::call_once(self)` 的顺序来的，没有按照方法调用的匹配顺序。

FIXME: 可能的解释。rust stable version，在定义闭包的同时，编译器定义了唯一的闭包 `struct` + 对应的 `Fn*` 实现，具体实现哪一个 `Fn*` trait，是根据 closure body 对捕获变量的使用来的（&self / &mut self / self，详细见 `move` keyword 小节图 10）。nightly 下，自定义 `struct Person`，然后 `impl Fn* for Person`，定义后表现应该与 stable 保持一致，因此匹配时也是一样的特殊规则，而不是按照方法调用规则。

TODO: FIXME 这里的描述可能存在错误，读者可以在评论区指出。遇事不决还是要去看源码实现 🧐。

### supertrait between three

为 `struct Person` 实现三个 `Fn*` traits，三者有 supertrait 关系：

> `Fn` : `FnMut` : `FnOnce`

supertrait 要求：

- 1、一个闭包类型实现了 `Fn` trait，就必须同时实现了 `FnMut` 和 `FnOnce` traits；
- 2、一个闭包类型实现了 `FnMut` trait，就必须同时实现了 `FnOnce` trait。

Rust 编译器约定了三者的 supertrait 关系，但为什么是这样一个 supertrait 关系呢？

闭包 `c` 仅使用了不可变引用，Rust 编译器按照 closures capture modes（图 10 会进行详细介绍）确定闭包类型 `C` 实现了 `Fn` trait，由于 supertrait 关系（`Fn` : `FnMut` : `FnOnce`），闭包类型 `C` 也必须同时存在对 `FnOnce` 和 `FnMut` 这两个 traits 的实现。

使用上一节 closure types 的例子：

```rust
enum Gender {
    Male,
    Famale,
}

fn main() {
    let name = String::from("qiao");
    let age: u32 = 28;
    // 捕获 name 和 age，仅使用不可变引用，实现 `Fn` trait
    // 由于 supertrait，me 对应的闭包类型一定同时实现了 `FnOnce` 和 `FnMut`
    let person = |gender: Gender| {
        let x = &name;
        let y = &age;
        ()
    };

    person(Gender::Male);
}
```

闭包类型等价于 `struct Person` + 一些对应的函数实现：

```rust
// 闭包类型等价的结构体，该结构体实现 `Fn` trait
// 由于 supertrait，该结构体同时实现了 `FnOnce` 和 `FnMut`
// MIR 表示中对应结构体为 tuple struct，字段不具名，使用 `.0` 访问
// struct Person<'scope>(&'scope String, &'scope u32); 
// 为了表述方便使用具名的 struct
struct Person<'scope> {
    name: &'scope String,
    age: &'scope u32,
}
```

在定义闭包 `person` 时 closure body 仅使用了不可变引用 `&name` 和 `&age`，Rust 编译器推断 `person` 对应的闭包类型（包含两个字段，类型均为不可变引用）实现了 `Fn` trait，在调用 `<Person as Fn<(Gender,)>>::call(&person, (Gender::Famale,))` 时获取 `person` 的不可变引用 `&person`（满足 borrowing rules），其后使用不可变引用 `&person`  去访问对应字段 `(*self).0` 和 `(*self).1`。

厘清两个不可变引用：

- 1、`struct Person` 中包含的两个字段的不可变引用 —— closure body 对捕获变量的使用（by shared reference / by mutable reference / by move or copy），闭包一经定义便确定了下来；
- 2、闭包类型对应的 `struct Person` 的不可变引用 —— 根据实际调用的 `Fn*` trait 进行确定，这里调用 `<Person as Fn<(Gender,)>>::call(&person, (Gender::Famale,))`，因此获得闭包类型的不可变引用 `&person`。

这里我们不禁有个疑问 🤔️，在定义闭包 `person` 时 closure body 使用不可变引用（即 `struct Person` 包含的两个字段均为不可变引用，闭包类型实现 `Fn` trait），调用时却是获取闭包类型的所有权去调用 `<Person as FnOnce<(Gender,)>>::call_once(person, (Gender::Famale,))`，是否可行呢？

先从原理上分析一下：

1、是否可以调用 `FnOnce` trait 对应的 `call_once()`？

由于 supertrait 关系 `Fn` : `FnMut` : `FnOnce`，闭包类型对应的 `struct Person` 实现了 `Fn` trait，也一定实现了 `FnOnce` trait，因此在作为 `FnOnce` 进行调用时，获得闭包类型的所有权，然后从 owed 所有权得到不可变引用，满足 Rust borrowing rule，再执行与 closure body 中相同的语句（可以这样理解，为 `struct Person` 实现 `FnOnce` trait，其 `call_once` 的实现分为两步，步骤 1）从所有权获取不可变引用，步骤 2）将定义时的 closure body 原样拷贝过来）；

画外音：读者可以考虑一下，闭包类型实现 `FnMut` trait，可以作为 `FnOnce` 被调用，但不能作为 `Fn` 被调用，其本质是什么？（提示，从所有权可以获取得到可变引用，从可变引用可以获取不可变引用）

2、是否可以获得闭包类型的所有权？

闭包是在某一个上下文中定义的，满足 Rust 所有权规则，所有权被移动后就不能再次被调用。需要根据上下文来判断是否可以获得闭包类型的所有权。

写段代码测试一下，[代码 11，call-Fn-with-FnOnce-and-FnMut](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=995bc6641906173ec532b40553e20018)，特别注意闭包类型（等价描述的 `struct Person` 的类型）和闭包所捕获的自由变量的类型（等价描述的 `struct Person` 所 capture 的字段的类型）。

```rust
enum Gender {
    Male,
    Famale,
}

fn main() {
    let name = String::from("qiao");
    let age: u32 = 28;
    // 捕获 name 和 age，仅使用不可变引用，实现 `Fn` trait
    // person 为闭包类型，未使用 & 修饰
    let person = |gender: Gender| {
        let x = &name;
        let y = &age;
        ()
    };

    // 实际调用 <Person as Fn<(Gender,)>>::call(&person, (Gender::Famale,));
    person(Gender::Male);

    // person 作为 FnMut 被使用
    foo(person);
    foo(person);  // Fn 实现了 Copy trait

    // person 作为 FnOnce 被使用
    bar(person);
    bar(person);  // Fn 实现了 Copy trait
}

fn foo<F>(mut f: F) where F: FnMut(Gender) {
    // 实际调用 <Person as FnMut<(Gender,)>>::call(&mut f, (Gender::Famale,));
    f(Gender::Male);

    f(Gender::Male);
}

fn bar<F>(f: F) where F: FnOnce(Gender) {
    // 实际调用 <Person as FnOnce<(Gender,)>>::call(f, (Gender::Famale,));
    f(Gender::Male);

    // f(Gender::Male);  // error[E0382]: use of moved value: `f`
}
```

使用下表进行理解。

| closure body 使用情况 | closure type impl `Fn*`                    | closure type impl `Copy`                        | 代码示例                                                     |
| --------------------- | ------------------------------------------ | ----------------------------------------------- | ------------------------------------------------------------ |
| by shared references  | `Fn`，由于 supertrait，`FnMut` 和 `FnOnce` | Y                                               | [代码 11，call-Fn-with-FnOnce-and-FnMut](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=995bc6641906173ec532b40553e20018) |
| by mutable references | `FnMut`，由于 supertrait，`FnOnce`         | N                                               | [代码 12，call-FnMut-with-FnOnce](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=7b380aaae5c7514e2bb2f1d837e13924) |
| by move or copy       | `FnOnce`                                   | If all fields is `Copy`, closure type is `Copy` | /                                                            |

注意 ⚠️：表格不考虑显式的 `move` 关键字（会影响闭包类型实现 `Fn` trait 时，对 `Copy` trait 的实现），会在后面小结专门介绍。

同时，[cheats.rs](https://cheats.rs/#closures-in-apis) 上也有比较完美的解释：

{{< figure src="images/cheatsrs-closures-in-apis.png" caption="图 9：闭包在定义接口时需要注意的要点" >}}

### `mut` keyword

对于 [代码 11，call-Fn-with-FnOnce-and-FnMut](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=995bc6641906173ec532b40553e20018) 中 `foo` 函数的签名和 cheatrs 截图中 `g` 函数的签名，在需要满足 `F: FnMut` trait bounds 的同时，参数列表中都包含有 `mut` 关键字，为什么需要这个 `mut` 呢？是否可以去掉？

`mut` 关键字用来修饰[两种场景](https://doc.rust-lang.org/std/keyword.mut.html)：

1、修饰变量，表示对应的变量可以修改（mutable variables），`mut` 不作为类型的一部分；

```rust
fn main() {
    // a 的类型为 u8，这里的 `mut` 不作为类型的一部分
    // `mut` 表示变量 a 可以被修改
    let mut a = 5;
    a = 6;

    assert_eq!(foo(3, 4), 7);
    assert_eq!(a, 6);
}

// x 的类型为 u8，`mut` 不作为类型的一部分
// `mut` 表示变量 x 可以被修改
fn foo(mut x: u8, y: u8) -> u8 {
    x += y;
    x
}
```

2、从 mutable variables 获取，得到其可变引用（[mutable references](https://doc.rust-lang.org/reference/types/pointer.html#mutable-references-mut)），`mut` 作为类型的一部分，可变引用是独占的（unique, exclusive）。

```rust
fn main() {
    // 首先需要是可变变量（mutable variables）
    // v 的类型为 `Vec<u8>`，`mut` 表示 v 可以被修改
    let mut v = vec![0, 1];
    // 才能得到可变引用（mutable references），入参类型为 `&mut Vec<u8>`
    push_two(&mut v);

    assert_eq!(v, vec![0, 1, 2]);
}

// v 的类型为 `&mut Vec<u8>`
fn push_two(v: &mut Vec<u8>) {
    v.push(2);
}
```

在满足 `F: FnMut` trait bounds 时，参数列表中的 `mut` 关键字，有三种写法：

- 写法 1：`(mut f: F)`（即 [代码 11，call-Fn-with-FnOnce-and-FnMut](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=995bc6641906173ec532b40553e20018) 中 `foo` 函数签名和 cheatrs 截图中 `g` 函数签名的写法），表示 mutable variables，`f` 的类型是 `F`，`mut` 表示 `f` 能够被修改（指向其他内存）或得到 mutable references `&mut f`；
- 写法 2：`(f: &mut F)`，表示 mutable references，`f` 的类型是 `&mut F`；
- 写法 3：`(mut f: &mut F)`，左侧表示 mutable variables，右侧表示 mutable references，`f` 的类型是 `&mut F`，左侧 `mut` 不参与类型表示，左侧 `mut` 表示可以由 `f` 得到 `&mut f`。

执行 `f()` 时，会发生什么呢？

> 方法调用的步骤是根据以下几个文档和自测（附录 Appendix C）确定的，可能理解有误，请以官方文档为准，如 Guide to Rustc Development [Method Lookup](https://rustc-dev-guide.rust-lang.org/method-lookup.html) 所说，"More detailed notes are in the **code** itself, naturally."
>
> - Rust Reference, [Method-call expressions](https://doc.rust-lang.org/reference/expressions/method-call-expr.html#method-call-expressions)
> - Guide to Rustc Development, [Method Lookup](https://rustc-dev-guide.rust-lang.org/method-lookup.html)
> - The Rustonomicon, [The Dot Operator](https://doc.rust-lang.org/nomicon/dot-operator.html)
> - Stack Overflow, [What are Rust's exact auto-dereferencing rules?](https://stackoverflow.com/questions/28519997/what-are-rusts-exact-auto-dereferencing-rules)

按照以下步骤进行：

- 步骤 1：通过多次解引用获取得到候选类型，添加到候选列表中（build a list of candidate receiver types by repeatedly [dereferencing](https://doc.rust-lang.org/reference/expressions/operator-expr.html#the-dereference-operator) the receiver expression's type, finally attempting an [unsized coercion](https://doc.rust-lang.org/reference/type-coercions.html#unsized-coercions) at the end, and adding the result type if that is successful）；
- 步骤 2：对候选列表中的每一个类型 `T`，其后添加上 `&T` 和 `&mut T`（for each candidate `T`, add `&T` and `&mut T` to the list immediately after `T`），步骤 2 结束时，就得到的完整了候选类型列表；
- 步骤 3：对候选类型列表中的每一个类型 `T`，进行方法匹配。如何匹配在下文和附录 Appendix C - Method-call expressions 测试代码 2 均有说明。

对于上述步骤，有几点疑问：

- 疑问 1、步骤 2 中，对于候选类型 `T`，增加 `&mut T`，是否需要 variable 支持 mutable 以获取可变引用？

Rust Reference [Method-call expressions](https://doc.rust-lang.org/reference/expressions/method-call-expr.html#method-call-expressions) 中有这样一段描述：

> This process does not take into account the mutability or lifetime of the receiver, or whether a method is `unsafe`. Once a method is looked up, if it can't be called for one (or more) of those reasons, the result is a compiler error.

然而，实际测试（附录 Appendix C - Method-call expressions，测试代码 1），如果变量（类型为 `T`）不支持 mutable，是无法获得 `&mut T` 的，编译报错。

- 疑问 2、步骤 3 中，匹配规则是怎么样的？先匹配方法的 `self` 参数类型，还是先匹配 `Self` 类型？

FIXME: 直接给出自测后的结论，**针对候选类型列表中的每一个类型 `T`，匹配方法签名中的 `self` 参数类型，若匹配上，由于 `self` 的类型中一定包含有 `Self` 类型，从而确定 `Self` 的类型（`Self` 类型作为 `<xxx as yyy>` 中的 `xxx`）**。见附录 Appendix C - Method-call expressions，测试代码 2。

TODO: FIXME 这里的描述可能存在错误，读者可以在评论区指出。未来我可能会专门写一篇文章来详细讲解匹配过程（在阅读 rustc 对应的源码之后，感觉遥遥无期啊 😮‍💨）。

回到对 cheatrs 截图 `g` 函数签名中 `mut` 关键字的讨论，写一段测试代码测试一下，[代码 13，call-FnMut-with-mut-keyword](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=dd689932ca7d19d28d9a80580ffce0fe)，读者可以看代码中的详细注释，这里就不重复解释了。

```rust
fn main() {
    let mut name = String::from("hello");

    // c 的类型表示为 `ClosureStruct`（简写为 `C`）, 包含 `name: &mut String` 字段
    // impl `FnMut` for `C`
    // c 使用 mut 修饰，但 mut 不作为类型的一部分，表示后续可以获取得到 `&mut C`
    let mut c = || {
        name.push_str(" qiao");
        println!("c: {}", name);
    };

    // 由于定义 c 时使用 mut 修饰，因此可以获取 &mut c，即类型为 `&mut C`
    // 方法调用候选列表 [C, &C, &mut C]
    //                        ^^^^^^
    // <C as FnMut<()>>::call_mut(&mut c, ());
    // 第一个参数 &mut c 的类型与候选列表标记处一致，即 self: &mut c
    // 对应的 call_mut(&mut self, args)，则确定 Self 类型 `Self: C`
    // 因此，可以确定候选列表先匹配 `self`，再根据签名匹配 `Self`
    // 更细致的测试代码见： Appendix C - Method-call expressions 两个测试
    c();

    // 试着将两个 `call_mut1(c);` 的注释打开，看看编译器的报错信息
    // 入参类型 `C`
    // call_mut1(c);
    //        - value moved here, `C` not impl `Copy` trait
    // call_mut1(c);
    //        ^ value used here after move

    // 试着将两个 `call_mut2(c);` 的注释打开，看看编译器的报错信息
    // 入参类型 mutable reference `&mut C`
    // let mut_c_param = &mut c;
    // call_mut2(mut_c_param);
    //        ----------- value moved here, `&mut C` not impl `Copy` trait
    // call_mut2(mut_c_param);
    //        ^^^^^^^^^^^ value used here after move

    // 入参类型 mutable reference `&mut C`
    call_mut3(&mut c);
    call_mut3(&mut c);

    // 入参类型 mutable reference `&mut C`
    call_mut4(&mut c);
    call_mut4(&mut c);    
}

// 借助 `let mut f: F = c;` 进行理解
// F 对应 `C`, `C` impl `FnMut` ==> 满足 trait bounds
// c 的所有权转移给了 f，f 的类型为 `C`
// f 使用 mut 修饰，因此可以获取 &mut f，即类型 `&mut C`
// 方法调用候选列表 [C, &C, &mut C]
//                       ^^^^^^
// 假设调用的 FnMut 为 `impl FnMut for Self`
// 将命中的类型作为 `call_mut(&self, args)` 的第一个参数，&mut f 确定 self，则 `Self: C`
// <C as  FnMut<()>>::call_mut(&mut f, ());
fn call_mut1<F>(mut f: F) where F: FnMut() {
    f();
}

// 借助 `let mut f: F = &mut c;` 进行理解
// 等号左侧 `: F` 指定 type，等号右侧需要是相应 type 或者能够转换到
// F 对应 `&mut C`
// `C` impl `FnMut` ==> `&mut C` imple `FnMut` ==> 满足 trait bounds
//                      ^^^^^^^^^^^^^^^^^^^^^ Rust 编译器自动添加实现
// f 使用 mut 修饰，因此可以获取 &mut f, F 对应 `&mut C`，展开为 `&mut &mut C`
// 方法调用候选列表 [&mut C, & &mut C, &mut &mut C, C, &C, &mut C]
//                ^^^^^^
// 假设调用的 FnMut 为 `impl FnMut for Self`
// 将命中的类型作为 `call_mut(&self, args)` 的第一个参数，&mut c 确定 self，则 `Self: C`
// <C as FnMut<()>>::call_mut(&mut c, ());
// call_mut1 和 call_mut2 签名完全一样，只是入参不一样，
// 这里只是解释两种不同的入参是怎么满足 trait bounds 的
fn call_mut2<F>(mut f: F) where F: FnMut() {
    f();
}

// 借助 `let f: &mut F = &mut c;` 进行理解
// 等号左侧 `: &mut F` 指定 type，等号右侧需要是相应 type 或者能够转换到
// F 对应 `C`, `C` impl `FnMut` ==> 满足 trait bounds
// f 为 `&mut c`, f 未使用 mut 修饰，无法得到 &mut f, 即 `&mut &mut C` 不能进入候选列表
// 方法调用候选列表 [&mut C, & &mut C, C, &C, &mut C]
//                ^^^^^^
// 假设调用的 FnMut 为 `impl FnMut for Self`
// 将命中的类型作为 `call_mut(&self, args)` 的第一个参数，&mut c 确定 self，则 `Self: C`
// <C as FnMut<()>>::call_mut(&mut c, ());
fn call_mut3<F>(f: &mut F) where F: FnMut() {
    f();
}

// 借助 `let mut f: &mut F = &mut c;` 进行理解
// 等号左侧 `: &mut F` 指定 type，等号右侧需要是相应 type 或者能够转换到
// F 对应 `C`, `C` impl `FnMut` ==> 满足 trait bounds
// f 为 `&mut c`, f 使用 mut 修饰，因此可以获取 &mut f, 即 `&mut &mut C` 加入候选列表
// 方法调用候选列表 [&mut C, & &mut C, &mut &mut C, C, &C, &mut C]
//                ^^^^^^
// 假设调用的 FnMut 为 `impl FnMut for Self`
// 将命中的类型作为 `call_mut(&self, args)` 的第一个参数，&mut c 确定 self，`Self: C`
// <C as FnMut<()>>::call_mut(&mut c, ());
fn call_mut4<F>(mut f: &mut F) where F: FnMut() {
    f();
}
```

### `move` keyword

对闭包中的 `move` 关键字，Rust 编译器的处理方式如下（[Closure expressions](https://doc.rust-lang.org/reference/expressions/closure-expr.html)）：

> Without the `move` keyword, the closure expression [infers how it captures each variable from its environment](https://doc.rust-lang.org/reference/types/closure.html#capture-modes), preferring to capture by shared reference, effectively borrowing all outer variables mentioned inside the closure's body. If needed the compiler will infer that instead mutable references should be taken, or that the values should be moved or copied (depending on their type) from the environment.
>
> A closure can be forced to capture its environment by copying or moving values by prefixing it with the `move` keyword. This is often used to ensure that the closure's lifetime is `'static`.

[`move` 关键字](https://doc.rust-lang.org/std/keyword.move.html)表示对自由变量的捕获方式（how it captures them），而闭包类型对 `Fn*` traits 的实现是依据 closure body 对捕获变量的使用方式来确定的（the traits implemented by a closure type are determined by what the closure does with captured values）。借助图 10 进行理解。

{{< figure src="images/closures-capture-mode-with-move.png" caption="图 10：closure capture modes" >}}

针对 `move` closure，但是 Rust 编译器推断闭包类型实现 `Fn` / `FnMut` traits，通过生成的 MIR 来理解一下：

{{< figure src="images/closure-impl-Fn-with-move.png" caption="图 11：通过 move 捕获自由变量的所有权，但 closure body 仅使用不可变引用，实现 Fn trait" >}}

`me` 表示的闭包类型为 `[closure@/app/example.rs:11:14: 15:6]`（图 11 标记 1），包含两个字段，类型分别为 `std::string::String` 和 `u32`（图 11 标记 2，`name` 为 `String` 类型，未实现 `Copy` trait，因此所有权 move 到闭包类型实例中；`age` 为 `u32` 类型，实现了 `Copy` trait，因此 copy 到闭包类型实例中）。closure body 仅使用 `name`、`age` 的不可变引用（图 11 标记 0 和标记 5），闭包类型实现 `Fn` trait（图 11 标记 3），对应匿名函数 `fn main::{closure#0}(_1: &[closure@/app/example.rs:11:14: 15:6], _2: Gender) -> ()`（图 11 标记 4）。同时，由于闭包类型拥有 move `name` 和 copy `age` 的所有权，在闭包调用结束后需要负责清理（图 11 标记 6，关于 `Drop` trait 后续会单独写一篇文章）。

### summary

以 [std::ops](https://doc.rust-lang.org/std/ops/index.html) 文档对 `Fn*` 的介绍作为小结：

> The [`Fn`](https://doc.rust-lang.org/std/ops/trait.Fn.html), [`FnMut`](https://doc.rust-lang.org/std/ops/trait.FnMut.html), and [`FnOnce`](https://doc.rust-lang.org/std/ops/trait.FnOnce.html) traits are implemented by types that can be invoked like functions. Note that [`Fn`](https://doc.rust-lang.org/std/ops/trait.Fn.html) takes `&self`, [`FnMut`](https://doc.rust-lang.org/std/ops/trait.FnMut.html) takes `&mut self` and [`FnOnce`](https://doc.rust-lang.org/std/ops/trait.FnOnce.html) takes `self`. These correspond to the three kinds of methods that can be invoked on an instance: call-by-reference, call-by-mutable-reference, and call-by-value. The most common use of these traits is to act as bounds to higher-level functions that take functions or closures as arguments.

## Conclusion

在本文中，我们介绍了 Rust 中三种 function-like types，分别是 function items、function pointers、closures，讲解它们之间的区别与联系（特别关注了三者之间可能存在的转换）。针对 `Fn*` traits，着重讲解了 `FnOnce`、`FnMut`、`Fn` 三个 traits 之间的 supertrait 关系，以及 `move` 关键字对 closures 的影响。

闭包（closures）的使用场景，会在后续单独写一篇文件进行讲解。

除了对 function-like types 和 `Fn*` traits 的介绍外，本文还对其他的知识点做了一些分析：

- ZST（Zero-Sized-Type）
- Rust MIR（**M**id-level **I**ntermediate **R**epresentation）
- `turbofish` 语法
- `unboxed_closures` & `fn_traits` feature
- `Copy` trait
- `mut` keyword
- methods lookup
- `move` keyword
- etc ...

本文为作者学习 Rust 的一篇学习笔记，肯定存在遗漏或错误，欢迎大家在评论区讨论指出。

【系列文章】：

1、[Rust 中的生命周期](https://qiaoin.github.io/2021/12/15/rust-lifetime/)

2、[Rust 中的迭代器](https://qiaoin.github.io/2022/01/17/rust-iterator/)

3、[Rust 中的闭包：function-like types and their traits](https://qiaoin.github.io/2022/02/23/rust-closures/)

4、更多 Rust 相关的文章，敬请期待

## License

本作品采用[知识共享署名 4.0 国际许可协议](http://creativecommons.org/licenses/by/4.0/)进行许可，转载时请注明原文链接。

## References

- Crust of Rust 系列 [functions, closures, and their traits](https://www.youtube.com/watch?v=dHkzSZnYXmk&t=23s&ab_channel=JonGjengset)，本文为学习此视频后的笔记
- 极客时间专栏 [陈天 · Rust 编程第一课](https://time.geekbang.org/column/intro/100085301)，第 19 讲，写的非常好，推荐阅读
- [Rust The Book](https://doc.rust-lang.org/stable/book/)，Chapter 13.1、19.4
- [代码 1，fn-item-types](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=cfb527e705feff799a7459f0487d702d)，来源 [Creating function pointers](https://doc.rust-lang.org/std/primitive.fn.html#creating-function-pointers)，有修改
- Rust reference 中针对三种 function-like types 的介绍，1）[Function item types](https://doc.rust-lang.org/reference/types/function-item.html)，2）[Function pointer types](https://doc.rust-lang.org/reference/types/function-pointer.html)，3）[Closure types](https://doc.rust-lang.org/reference/types/closure.html)，同时标准库有 [fn](https://doc.rust-lang.org/std/primitive.fn.html) 的介绍
- [Implement unique types per fn item, rather than having all fn items have fn pointer type by nikomatsakis · Pull Request #19891 · rust-lang/rust (github.com)](https://github.com/rust-lang/rust/pull/19891)
- [In Rust, what is `fn() -> ()`?](https://stackoverflow.com/a/64298764)，回答写的非常好，可以作为本文的总结，推荐阅读
- [代码 6，three-function-like-types-and-type-coercion](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=13b2997636a647bcd1a98dea7dc2f8d7)，来源 StackOverflow 上的这个 [提问](https://stackoverflow.com/questions/27895946/expected-fn-item-found-a-different-fn-item-when-working-with-function-pointer)，有修改，补充上 no capturing closure
- [Function overloading in Rust](https://medium.com/swlh/function-overloading-in-rust-d591aff64a03)，参考这篇博客，在 nightly 环境下为 `struct Person` 实现 `Fn*` traits
- 方法调用的官方文档，1）Rust Reference, [Method-call expressions](https://doc.rust-lang.org/reference/expressions/method-call-expr.html#method-call-expressions)，2）Guide to Rustc Development, [Method Lookup](https://rustc-dev-guide.rust-lang.org/method-lookup.html)，3）The Rustonomicon, [The Dot Operator](https://doc.rust-lang.org/nomicon/dot-operator.html)，推荐阅读，并且以官方文档为准，本文中的方法调用总结只是我的理解，可能存在错误
- [What are Rust's exact auto-dereferencing rules?](https://stackoverflow.com/a/28552082/4238811)，回答可以作为方法调用匹配规则的一个简单概括
- 文中的所有图片均使用 [excalidraw](https://excalidraw.com/) 绘制
- MIR 输出均使用 [Compiler Explorer](https://godbolt.org/)

## Appendix

### A - tuple-like struct or enum variant

[Function item types](https://doc.rust-lang.org/reference/types/function-item.html) 开始部分

> When referred to, a function item, or the constructor of a tuple-like struct or enum variant, yields a zero-sized value of its *function item type*.

写段[代码](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=589b52a222f1ccb1c25f77f895a088d3)测试，在 `x` / `y` / `z` 后添加 `: ()` 编译器提示类型不匹配，就能够知道 `x` / `y` / `z` 对应的类型了，`x` 在 function item types 小节已经详细介绍了，`y` / `z` 为什么也是 function items 呢？

```rust
fn main() {
    // x's type == fn item `fn() -> i32 {bar}`
    let x = bar;
    println!("{}", std::mem::size_of_val(&x));  // 0

    // y's type == fn item `fn(i32) -> Foo {Foo}`
    let y = Foo;
    println!("{}", std::mem::size_of_val(&y));  // 0

    // z's type == fn item `fn(i32) -> Enum {Enum::First}`
    let z = Enum::First;
    println!("{}", std::mem::size_of_val(&z));  // 0

    let z2: () = Enum::Second;
    println!("{}", std::mem::size_of_val(&z2));  // 8
}

fn bar() -> i32 {
    42
}

struct Foo(i32);

enum Enum {
    First(i32),
    Second,
}
```

[Rust The Book](https://doc.rust-lang.org/stable/book/) Chapter 19.4 有两段话解释 tuple structs 和 tuple-struct enum variants 的实现：

> These types use `()` as initializer syntax, which looks like a function call. The initializers are actually implemented as functions returning an instance that’s constructed from their arguments. We can use these initializer functions as function pointers that implement the closure traits, which means we can specify the initializer functions as arguments for methods that take closures, like so:
>
> ```rust
>     enum Status {
>         Value(u32),
>         Stop,
>     }
> 
>     let list_of_statuses: Vec<Status>
>         = (0u32..20).map(Status::Value).collect();
> ```
>
> Here we create `Status::Value` instances using each `u32` value in the range that `map` is called on by using the initializer function of `Status::Value`.

### B - Rust MIR

对于 MIR，我们只需能够阅读并理解即可。下面给到一些链接，有部分文章未完整看完 😅。

- [Rust编译器专题 | 图解 Rust 编译器与语言设计 Part 1 - Rust精选](https://rustmagazine.github.io/rust_magazine_2021/chapter_1/rustc_part1.html)，最开始是看到这篇翻译，对 Rust 程序的编译过程有了一个大致的印象，在构思如何解释 closure types 时，希望能够有一个正式的直观的解释，从而找到了 Rust MIR，本文中对于 closures 的解释都是从 Rust MIR 进行延展开来的。在此，感谢 [RustMagazine 2021 期刊](https://github.com/RustMagazine/rust_magazine_2021)，感谢 [ZhangHanDong (Alex)](https://github.com/ZhangHanDong)；
- [Introducing MIR](https://blog.rust-lang.org/2016/04/19/MIR.html)，Rust 官方博客，写的非常好，推荐全文阅读；
- [rfcs/1211-mir.md · rust-lang/rfcs](https://github.com/rust-lang/rfcs/blob/master/text/1211-mir.md)，MIR 对应的 RFC，了解设计动机；
- [rust-lang/miri: An interpreter for Rust's mid-level intermediate representation](https://github.com/rust-lang/miri)，MIR 实现；
- [The MIR (Mid-level IR) - Guide to Rustc Development](https://rustc-dev-guide.rust-lang.org/mir/index.html)，MIR 语法介绍，必须阅读才能够理解 MIR 中各部分的含义；
- [Closure expansion - Guide to Rustc Development (rust-lang.org)](https://rustc-dev-guide.rust-lang.org/closure.html)，闭包在 MIR 中的表示；
- [The steps towards rustc, the great optimiser](https://kazlauskas.me/entries/the-road-to-bestest-optimiser)
- [Rust Compiler Internals : Mid-level Intermediate Representation (MIR)](https://kanishkarj.github.io/rust-internals-mir)

### C - Method-call expressions

为什么可以使用 `()` 执行函数调用，是因为实现了 `Fn*` traits 吗？

Rust Reference [Call expressions](https://doc.rust-lang.org/reference/expressions/call-expr.html) 有介绍：

> A *call expression* calls a function. The syntax of a call expression is an expression, called the *function operand*, followed by a parenthesized (用括号括起来的 `(arg0, arg1)`) comma-separated list of expression, called the *argument operands*. If the function eventually returns, then the expression completes. For [non-function types](https://doc.rust-lang.org/reference/types/function-item.html), the expression `f(...)` uses the method on one of the [`std::ops::Fn`](https://doc.rust-lang.org/std/ops/trait.Fn.html), [`std::ops::FnMut`](https://doc.rust-lang.org/std/ops/trait.FnMut.html) or [`std::ops::FnOnce`](https://doc.rust-lang.org/std/ops/trait.FnOnce.html) traits, which differ in whether they take the type by reference, mutable reference, or take ownership respectively. An automatic borrow will be taken if needed. The function operand will also be [automatically dereferenced](https://doc.rust-lang.org/reference/expressions/field-expr.html#automatic-dereferencing) as required.

#### test 1

[测试代码 1](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=afc5642e534c5564adbd86f7d22eea5f)，能够说明以下两点（更多可以验证的点，读者可以修改测试代码自行探索）：

1、`T` 类型对应的变量需使用 `mut` 修饰，候选类型列表才能够添加 `&mut T`；

2、在 inherent methods 和 trait impl 同时满足时（例如 `f2.bar()`），会优先选择 inherent methods。

inherent methods 的介绍在 Guide to Rustc Development [Method Lookup](https://rustc-dev-guide.rust-lang.org/method-lookup.html)，优先级相关的表述参见 StackOverflow 上的这个[回答](https://stackoverflow.com/a/28552082/4238811)（inherent methods take precedence over trait ones）。

#### test 2

[测试代码 2](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=3e1424088174bba86703d86048f707d3)，能够说明，候选类型匹配时，是对 `self` 进行匹配，然后确定 `Self`。

同样，StackOverflow 上的回答 [What are Rust's exact auto-dereferencing rules?](https://stackoverflow.com/a/28552082/4238811) 也印证了这里的测试结论。

{{< figure src="images/stackoverflow-dereferencing-self.jpg" >}}
