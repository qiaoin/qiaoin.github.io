---
title: Go 语言基础 -- A Tour of Go
author: qiaoin
date: '2020-06-09'
slug: go-basis
categories:
  - 编程语言
tags:
  - Go
---

---

{{< toc >}}

---

## 环境搭建

按照 [Getting Started](https://golang.org/doc/install) 进行安装，并设置好环境变量和创建好对应目录

```bash
# go, for mit 6.824
export GOPATH=$HOME/golang
export GOROOT="/usr/local/opt/go/libexec"
export PATH=$GOPATH/bin:$PATH
export PATH=$GOROOT/bin:$PATH
```

[How to Write Go Code](https://golang.org/doc/code.html)

- 模块组织
- 使用本地模块和远程模块
- 单元测试

## 语言基础

### Packages and Imports

每个 Go 程序都是由 packages 组成，程序从 main package 开始运行

使用圆括号、分行引入多个 `import`，是更好的形式

### Exported names

> 使用 C++ 中的 public、private 类比

Go 语言中，属性和方法如果以大写字母开头，那么它就是 public 的；否则就是 private 的

当导入一个包时，我们可以引用 public 修饰的属性和方法，但访问不了 private 修饰的

### Functions

顺序：变量名 变量类型

当函数的两个或多个已命名形参的类型相同时，除最后一个类型意外，其它都可以省略

函数可以返回任意数量的返回值，即 tuple

```go
package main

func swap(x, y string) (string, string) {
    return y, x
}
```

Go 的函数返回值允许命名，它们会被视作定义在函数顶部的变量；没有参数的 `return` 语句返回已命名的返回值，也就是直接返回

```go
package main

func split(sum int) (x, y int) {
    x = sum * a / 9
    y = sum - x
    return
}
```

### 变量

`var` 语句用于声明一个变量列表，跟函数的参数列表一样，类型在最后

`var` 语句可以出现在包或函数级别

变量声明可以包含初始值，每个变量对应一个

如果初始值已存在，可以省略类型；变量会从初识值中获得类型

```go
package main

var c, python, java bool
var i, j int = 1, 2
var a, b, c = true, false, "no!"
```

使用 `var` 声明变量，但在函数中可以使用简洁赋值语句 `:=` 代替 `var` 声明

函数外的每行语句都必须以关键字开始（`var` `func` 等等），因此 `:=` 结构不能在函数外使用

同导入语句一样，变量声明也可以“分组”成一个语法块。

```go
package main

import (
    "fmt"
    "math/cmplx"
)

var (
    ToBe   bool       = false
    MaxInt uint64     = 1<<64 - 1
    z      complex128 = cmplx.Sqrt(-5 + 12i)
)
```

### 常量

常量的声明与变量类似，只不过是使用 `const` 关键字。

常量可以是字符、字符串、布尔值或数值

常量不能用 `:=` 语法声明

### 基础数据类型

Go 的基本类型有

```go
bool

string

int  int8  int16  int32  int64
uint uint8 uint16 uint32 uint64 uintptr

byte // alias for uint8

rune // alias for int32
     // represents a Unicode code point, 代表一个 Unicode 的码点

float32 float64

complex64 complex128
```

`int`, `uint` 和 `uintptr` 在 32 位系统上通常为 32 位宽，在 64 位系统上则为 64 位宽。 当需要一个整数值时应使用 `int` 类型，除非你有特殊的理由使用固定大小或无符号的整数类型。

没有明确初始值的变量声明会被赋予它们的**零值（zero value）**：

- 数字类型 `0`
- 布尔类型 `false`
- 字符串类型 `""`（空字符串）

```go
package main

import "fmt"

func main() {
    var i int
    var f float64
    var b bool
    var s string
    fmt.Printf("%v %v %v %q\n", i, f, b, s)
}
```

### 数据类型转换

表达式 `T(v)` 将值 `v` 转换为类型 `T`

与 C 不同的是，Go 在不同类型的项之间赋值时需要**显式类型转换**

### 类型推导

在声明一个变量而不指定其类型时（即使用不带类型的 `:=` 语法或 `var` = 表达式语法），变量的类型由右值推导得出

```go
package main

import "fmt"

func main() {
    v := 3.142 // 修改这里！
    fmt.Printf("v is of type %T\n", v)
}
```

### for

Go 只有一种循环结构，`for` 循环。初始化语句通常为一句短变量声明，该变量声明仅在 `for` 语句的作用域中可见

初始化语句和后置语句是可选的，此时可以去掉分号，因为 C 的 `while` 在 Go 中叫做 `for`

```go
package main

import "fmt"

func main() {
    sum := 0
    for i := 0; i < 10; i++ {
        sum += i
    }
    fmt.Println(sum)

    all := 1
    for ; all < 1000; {
        all += all
    }
    fmt.Println(all)

    all2 := 1
    for all2 < 1000 {
        all2 += all2
    }
    fmt.Println(all2)

    // 无限循环
    for {
    }
}
```

### if

Go 的 `if` 语句与 `for` 循环类似，表达式外无需小括号 `( )`，而大括号 `{ }` 则是必须的

同 `for` 一样， `if` 语句可以在条件表达式前执行一个简单的语句；该语句声明的变量作用域仅在 `if` 之内

在 `if` 的简短语句中声明的变量同样可以在任何对应的 `else` 块中使用

```go
package main

import (
    "fmt"
    "math"
)

func sqrt(x float64) string {
    if x < 0 {
        return sqrt(-x) + "i"
    }
    return fmt.Sprint(math.Sqrt(x))
}

func pow(x, n, lim float64) float64 {
    if v := math.Pow(x, n); v < lim {
        return v
    } else {
        fmt.Printf("%g >= %g\n", v, lim)
    }
    return lim
}

func main() {

}
```

牛顿法求平方根

```go
package main

import (
    "fmt"
    "math"
)

func IsEnough(x, guess float64) bool {
    return math.Abs(x - guess * guess) < 0.0000000000001
}

func Improve(x, guess float64) float64 {
    return guess - (guess * guess - x) / (2 * guess)
}

func Sqrt(x float64) float64 {
    guess := 1.0
    for !IsEnough(x, guess) {
        fmt.Println(guess)
        guess = Improve(x, guess)
    }
    return guess
}

func main() {
    fmt.Println(Sqrt(2))
}
```

### switch

- Go 只运行满足条件的 `case`，而非之后的所有的 `case`。实际上，Go 自动提供给了其他语言在 `case` 后面所需要的 `break` 语句
- 除非以 `fallthrough` 语句结束，否则分支会自动终止
- Go 的 `switch` 的 `case` 无需为常量，且取值不必为整数

switch 的 case 语句从上到下顺次执行，直到匹配成功时停止。

```go
switch i {
    case 0:
    case f():
}
```

在 `i==0` 时 `f` 不会被调用

没有条件的 `switch` 同 `switch true` 一样；这种形式能将一长串 `if-then-else` 写得更加清晰。

```go
package main

import (
    "fmt"
    "time"
)

func main() {
    t := time.Now()
    switch {
    case t.Hour() < 12:
        fmt.Println("Good morning!")
    case t.Hour() < 17:
        fmt.Println("Good afternoon.")
    default:
        fmt.Println("Good evening.")
    }
}
```

### defer

`defer` 语句会将函数推迟到外层函数返回之后执行。推迟调用的函数其参数会立即求值，但直到外层函数返回前该函数都不会被调用

推迟的函数调用会被压入一个栈中。当外层函数返回时，被推迟的函数会按照后进先出的顺序调用。

```go
package main

import "fmt"

func main() {
    fmt.Println("counting")

    for i := 0; i < 10; i++ {
        defer fmt.Println(i)
    }

    fmt.Println("done")
}
```

### 指针

Go 语言中也有指针，指针保存了值的内存地址。类型 `*T` 是指向 `T` 类型值的指针。其零值为 `nil`

`&` 操作符会生成一个指向其操作数的指针

`*` 操作符表示指针指向的底层值

与 C 不同，Go 没有指针运算

### 结构体 struct

- 一个结构体（`struct`）就是一组字段（field）
- 结构体字段使用点号来访问
- 结构体字段可以通过结构体指针来访问。如果我们有一个指向结构体的指针 `p`，那么可以通过 `(*p).X` 来访问其字段 `X`。不过这么写太啰嗦了，所以语言也允许我们使用隐式间接引用，直接写 `p.X` 就可以

```go
package main

import "fmt"

type Vertex struct {
    X int
    Y int
}

func main() {
    v := Vertex{1, 2}
    fmt.Println(v)
    v.X = 4
    fmt.Println(v)

    p := &v
    p.X = 9
    fmt.Println(v)
}
```

- 结构体文法通过直接列出字段的值来新分配一个结构体。
- 使用 `Name:` 语法可以仅列出部分字段。（字段名的顺序无关。）
- 特殊的前缀 `&` 返回一个指向结构体的指针。

```go
package main

import "fmt"

type Vertex struct {
    X, Y int
}

var (
    v1 = Vertex{1, 2}  // 创建一个 Vertex 类型的结构体
    v2 = Vertex{X: 1}  // Y:0 被隐式地赋予
    v3 = Vertex{}      // X:0 Y:0
    p  = &Vertex{1, 2} // 创建一个 *Vertex 类型的结构体（指针）
)

func main() {
    fmt.Println(v1, p, v2, v3)
}
```

### 数组

类型 `[n]T` 表示拥有 n 个 `T` 类型的值的数组

数组的长度是其类型的一部分，因此数组不能改变大小

```go
package main

import "fmt"

func main() {
    var a [2]string
    a[0] = "Hello"
    a[1] = "World"
    fmt.Println(a[0], a[1])
    fmt.Println(a)

    primes := [6]int{2, 3, 5, 7, 11, 13}
    fmt.Println(primes)
}
```

### 切片 slice

每个数组的大小都是固定的。而切片则为数组元素提供动态大小的、灵活的视角。在实践中，切片比数组更常用。

类型 `[]T` 表示一个元素类型为 `T` 的切片。

切片通过两个下标来界定，即一个上界和一个下界，二者以冒号分隔：

```go
// a[low : high]
// 切片下界的默认值为 0，上界则是该切片的长度
package main

import "fmt"

func main() {
    primes := [6]int{2, 3, 5, 7, 11, 13}

    var s []int = primes[1:4]  // [3, 5, 7]
    fmt.Println(s)

    s = s[:2]
    fmt.Println(s)

    s = s[1:]
    fmt.Println(s)
}
```

它会选择一个半开区间，包括第一个元素，但排除最后一个元素

- 切片并不存储任何数据，它只是描述了底层数组中的一段。
- 更改切片的元素会修改其底层数组中对应的元素。
- 与它共享底层数组的切片都会观测到这些修改。

切片文法类似于没有长度的数组文法。

```go
// 数组文法
[3]bool{true, true, false}

// 会创建一个和上面相同的数组，然后构建一个引用了它的切片
[]bool{true, true, false}
```

切片拥有**长度**和**容量**

切片的**长度**就是它所包含的元素个数。

切片的**容量**是从它的第一个元素开始数，到其底层数组元素末尾的个数。

切片 `s` 的长度和容量可通过表达式 `len(s)` 和 `cap(s)` 来获取。

切片的默认值是 `nil`。`nil` 切片的长度和容量为 0 且没有底层数组。

切片可以用内建函数 `make` 来创建，这也是创建动态数组的方式。

`make` 函数会分配一个元素为零值的数组并返回一个引用了它的切片：

```go
a := make([]int, 5)  // len(a)=5
```

要指定它的容量，需向 `make` 传入第三个参数：

```go
b := make([]int, 0, 5) // len(b)=0, cap(b)=5

b = b[:cap(b)]  // len(b)=5, cap(b)=5
b = b[1:]      // len(b)=4, cap(b)=4
```

切片可包含任何类型，甚至包括其它的切片

```go
package main

import (
    "fmt"
    "strings"
)

func main() {
    // 创建一个井字板（经典游戏）
    board := [][]string{
        []string{"_", "_", "_"},
        []string{"_", "_", "_"},
        []string{"_", "_", "_"},
    }

    // 两个玩家轮流打上 X 和 O
    board[0][0] = "X"
    board[2][2] = "O"
    board[1][2] = "X"
    board[1][0] = "O"
    board[0][2] = "X"

    for i := 0; i < len(board); i++ {
        fmt.Printf("%s\n", strings.Join(board[i], " "))
    }
}
```

向切片追加元素：为切片追加新的元素是种常用的操作，为此 Go 提供了内建的 `append` 函数。内建函数的文档对此函数有详细的介绍。

```go
func append(s []T, vs ...T) []T
```

`append` 的第一个参数 `s` 是一个元素类型为 `T` 的切片，其余类型为 `T` 的值将会追加到该切片的末尾。

`append` 的结果是一个包含原切片所有元素加上新添加元素的切片。

当 `s` 的底层数组太小，不足以容纳所有给定的值时，它就会分配一个更大的数组。返回的切片会指向这个新分配的数组。

`for` 循环的 `range` 形式可遍历切片或映射。当使用 `for` 循环遍历切片时，每次迭代都会返回两个值。第一个值为当前元素的下标，第二个值为该下标所对应元素的一份副本。

```go
package main

import "fmt"

var pow = []int{1, 2, 4, 8, 16, 32, 64, 128}

func main() {
    for i, v := range pow {
        fmt.Printf("2**%d = %d\n", i, v)
    }
}
```

可以将下标或值赋予 `_` 来忽略它。

```go
for i, _ := range pow
for _, value := range pow
```

若你只需要索引，忽略第二个变量即可。

```go
for i := range pow
```

```go
package main

import "fmt"

func main() {
    pow := make([]int, 10)
    for i := range pow {
        pow[i] = 1 << uint(i) // == 2**i
    }
    for _, value := range pow {
        fmt.Printf("%d\n", value)
    }
}

func Pic(dx, dy int) [][]uint8 {
    items := make([][]uint8, dy)
    for i := 0; i < dy; i++ {
        items[i] = make([]uint8, dx)
        for j :=0; j < dx; j++ {
            items[i][j] = uint8(i * j)
        }
    }

    return items
}
```

### 映射/字典 map

映射将键映射到值。映射的零值为 `nil` 。`nil` 映射既没有键，也不能添加键。`make` 函数会返回给定类型的映射，并将其初始化备用。

映射的文法与结构体相似，不过必须有键名。

```go
package main

import "fmt"

type Vertex struct {
    Lat, Long float64
}

var m = map[string]Vertex{
    "Bell Labs": Vertex{
        40.68433, -74.39967,
    },
    "Google": Vertex{
        37.42202, -122.08408,
    },
}

// 若顶级类型只是一个类型名，你可以在文法的元素中省略它。
// var m = map[string]Vertex{
//     "Bell Labs": {40.68433, -74.39967},
//     "Google":    {37.42202, -122.08408},
// }

var n map[string]Vertex

func main() {
    fmt.Println(m)

    n = make(map[string]Vertex)
    n["Bell Labs"] = Vertex{
        40.68433, -74.39967,
    }
    fmt.Println(n["Bell Labs"])
}
```

在映射 `m` 中插入或修改元素：

```go
m[key] = elem
```

获取元素：

```go
elem = m[key]
```

删除元素：

```go
delete(m, key)
```

通过双赋值检测某个键是否存在：

```go
elem, ok = m[key]
```

- 若 `key` 在 `m` 中，`ok` 为 `true`；否则，`ok` 为 `false`。
- 若 `key` 不在映射中，那么 `elem` 是该映射元素类型的零值。

同样的，当从映射中读取某个不存在的键时，结果是映射的元素类型的零值。

注 ：若 `elem` 或 `ok` 还未声明，你可以使用短变量声明：

```go
elem, ok := m[key]
```

实现简单的 WordCount

```go
package main

import (
    "strings"
    "golang.org/x/tour/wc"
)

func WordCount(s string) map[string]int {
    slices := strings.Fields(s)
    ret := make(map[string]int)
    for _, value := range slices {
         ret[value] += 1
    }
    return ret
}

func main() {
    wc.Test(WordCount)
}
```

### 函数值

函数也是值。它们可以像其它值一样传递。函数值可以用作函数的参数或返回值。

```go
package main

import (
    "fmt"
    "math"
)

func compute(fn func(float64, float64) float64) float64 {
    return fn(3, 4)
}

func main() {
    hypot := func(x, y float64) float64 {
        return math.Sqrt(x*x + y*y)
    }
    fmt.Println(hypot(5, 12))

    fmt.Println(compute(hypot))
    fmt.Println(compute(math.Pow))
}
```

Go 支持函数闭包，实现斐波拉切数列

```go
package main

import "fmt"

// 返回一个“返回int的函数”
func fibonacci() func() int {
    a := 0
    b := 1
    return func() int {
        a, b = b, a + b
        return a
    }
}

func main() {
    f := fibonacci()
    for i := 0; i < 10; i++ {
        fmt.Println(f())
    }
}
```

### 方法

Go 没有类，但可以为结构体类型定义**方法**。方法就是一类带特殊的**接收者**参数的函数。方法接收者在它自己的参数列表内，位于 `func` 关键字和方法名之间。

```go
package main

import (
    "fmt"
    "math"
)

type Vertex struct {
    X, Y float64
}

func (v Vertex) Abs() float64 {
    return math.Sqrt(v.X*v.X + v.Y*v.Y)
}

func main() {
    v := Vertex{3, 4}
    fmt.Println(v.Abs())
}
```

记住：方法只是个带接收者参数的函数。

也可以为非结构体类型声明方法。接收者的类型定义和方法声明必须在同一包内；不能为内建类型声明方法。

```go{10}
package main

import (
    "fmt"
    "math"
)

type MyFloat float64

func (f MyFloat) Abs() float64 {
    if f < 0 {
        return float64(-f)
    }
    return float64(f)
}

func main() {
    f := MyFloat(-math.Sqrt2)
    fmt.Println(f.Abs())
}
```

可以为指针接收者声明方法，这意味着对于某类型 `T`，接收者的类型可以用 `*T` 的文法。（此外，`T` 不能是像 `*int` 这样的指针。）

例如，这里为 `*Vertex` 定义了 `Scale` 方法。指针接收者的方法可以修改接收者指向的值（就像 `Scale` 在这做的）。由于方法经常需要修改它的接收者，指针接收者比值接收者更常用。试着移除第 16 行 `Scale` 函数声明中的 `*`，观察此程序的行为如何变化。

若使用值接收者，那么 `Scale` 方法会对原始 `Vertex` 值的**副本**进行操作。（对于函数的其它参数也是如此。）`Scale` 方法必须用指针接受者来更改 `main` 函数中声明的 `Vertex` 的值。

```go{16}
package main

import (
    "fmt"
    "math"
)

type Vertex struct {
    X, Y float64
}

func (v Vertex) Abs() float64 {
    return math.Sqrt(v.X*v.X + v.Y*v.Y)
}

func (v *Vertex) Scale(f float64) {
    v.X = v.X * f
    v.Y = v.Y * f
}

func main() {
    v := Vertex{3, 4}
    v.Scale(10)
    fmt.Println(v.Abs())
}
```

将 `Abs` 和 `Scale` 方法重写为函数

```go
package main

import (
    "fmt"
    "math"
)

type Vertex struct {
    X, Y float64
}

func Abs(v Vertex) float64 {
    return math.Sqrt(v.X*v.X + v.Y*v.Y)
}

func Scale(v *Vertex, f float64) {
    v.X = v.X * f
    v.Y = v.Y * f
}

func main() {
    v := Vertex{3, 4}
    Scale(&v, 10)
    fmt.Println(Abs(v))
}
```

比较前两个程序，你大概会注意到带指针参数的函数必须接受一个指针：

```go
var v Vertex
ScaleFunc(v, 5)  // 编译错误！
ScaleFunc(&v, 5) // OK
```

而以指针为接收者的方法被调用时，接收者既能为值又能为指针：

```go
var v Vertex
v.Scale(5)  // OK
p := &v
p.Scale(10) // OK
```

对于语句 `v.Scale(5)`，即便 `v` 是个值而非指针，带指针接收者的方法也能被直接调用。 也就是说，由于 `Scale` 方法有一个指针接收者，为方便起见，Go 会将语句 `v.Scale(5)` 解释为 `(&v).Scale(5)`。

同样的事情也发生在相反的方向。接受一个值作为参数的函数必须接受一个指定类型的值：

```go
var v Vertex
fmt.Println(AbsFunc(v))  // OK
fmt.Println(AbsFunc(&v)) // 编译错误！
```

而以值为接收者的方法被调用时，接收者既能为值又能为指针：

```go
var v Vertex
fmt.Println(v.Abs()) // OK
p := &v
fmt.Println(p.Abs()) // OK
```

这种情况下，方法调用 `p.Abs()` 会被解释为 `(*p).Abs()`。

使用指针接收者的原因有二：

1. 方法能够修改其接收者指向的值。
2. 可以避免在每次调用方法时复制该值。若值的类型为大型结构体时，这样做会更加高效。

通常来说，所有给定类型的方法都应该有值或指针接收者，但并不应该二者混用。

### 接口

**接口类型**是由一组方法签名定义的集合。接口类型的变量可以保存任何实现了这些方法的值。

```go
package main

import (
    "fmt"
    "math"
)

type Abser interface {
    Abs() float64
}

func main() {
    var a Abser
    f := MyFloat(-math.Sqrt2)
    v := Vertex{3, 4}

    a = f  // a MyFloat 实现了 Abser
    a = &v // a *Vertex 实现了 Abser

    // 下面一行，v 是一个 Vertex（而不是 *Vertex）
    // 所以没有实现 Abser。
    // a = v

    fmt.Println(a.Abs())
}

type MyFloat float64

func (f MyFloat) Abs() float64 {
    if f < 0 {
        return float64(-f)
    }
    return float64(f)
}

type Vertex struct {
    X, Y float64
}

func (v *Vertex) Abs() float64 {
    return math.Sqrt(v.X*v.X + v.Y*v.Y)
}
```

### 接口与隐式实现

类型通过实现一个接口的所有方法来实现该接口。既然无需专门显式声明，也就没有“implements”关键字。

隐式接口从接口的实现中解耦了定义，这样接口的实现可以出现在任何包中，无需提前准备。

因此，也就无需在每一个实现上增加新的接口名称，这样同时也鼓励了明确的接口定义。

```go
package main

import "fmt"

type I interface {
    M()
}

type T struct {
    S string
}

// 此方法表示类型 T 实现了接口 I，但我们无需显式声明此事。
func (t T) M() {
    fmt.Println(t.S)
}

func main() {
    var i I = T{"hello"}
    i.M()
}
```

### 接口值

接口也是值。它们可以像其它值一样传递。接口值可以用作函数的参数或返回值。

在内部，接口值可以看做包含值和具体类型的元组：

```go
(value, type)
```

接口值保存了一个具体底层类型的具体值。接口值调用方法时会执行其底层类型的同名方法。

即便接口内的具体值为 `nil`，方法仍然会被 `nil` 接收者调用。在一些语言中，这会触发一个空指针异常，但在 Go 中通常会写一些方法来优雅地处理它（如本例中的 `M` 方法）。

注意: 保存了 `nil` 具体值的接口其自身并不为 `nil`。

```go
package main

import (
    "fmt"
    "math"
)

type I interface {
    M()
}

type T struct {
    S string
}

func (t *T) M() {
    if t == nil {
        fmt.Println("<nil>")
        return
    }
    fmt.Println(t.S)
}

type F float64

func (f F) M() {
    fmt.Println(f)
}

func main() {
    var i I

    i = &T{"Hello"}
    describe(i)
    i.M()

    var t *T
    i = t
    describe(i)
    i.M()

    i = F(math.Pi)
    describe(i)
    i.M()

    var ii I
    describe(ii)
    ii.M()
}

func describe(i I) {
    fmt.Printf("(%v, %T)\n", i, i)
}
```

`nil` 接口值既不保存值也不保存具体类型。为 `nil` 接口调用方法会产生运行时错误，因为接口的元组内并未包含能够指明该调用哪个**具体**方法的类型。

### 空接口

指定了零个方法的接口值被称为**空接口**：

```go
interface{}
```

空接口可保存任何类型的值。（因为每个类型都至少实现了零个方法。）空接口被用来处理未知类型的值。例如，`fmt.Print` 可接受类型为 `interface{}` 的任意数量的参数。

```go
package main

import "fmt"

func main() {
    var i interface{}
    describe(i)

    i = 42
    describe(i)

    i = "hello"
    describe(i)
}

func describe(i interface{}) {
    fmt.Printf("(%v, %T)\n", i, i)
}
```

### 类型断言

**类型断言**提供了访问接口值底层具体值的方式。

```go
t := i.(T)
```

该语句断言接口值 `i` 保存了具体类型 `T`，并将其底层类型为 `T` 的值赋予变量 `t`。若 `i` 并未保存 `T` 类型的值，该语句就会触发一个 panic。

为了**判断**一个接口值是否保存了一个特定的类型，类型断言可返回两个值：其底层值以及一个报告断言是否成功的布尔值。

```go
t, ok := i.(T)
```

若 `i` 保存了一个 `T`，那么 `t` 将会是其底层值，而 `ok` 为 `true`。

否则，`ok` 将为 `false` 而 `t` 将为 `T` 类型的零值，程序并不会产生 panic。

请注意这种语法和读取一个映射时的相同之处。

```go
package main

import "fmt"

func main() {
    var i interface{} = "hello"

    s := i.(string)
    fmt.Println(s)

    s, ok := i.(string)
    fmt.Println(s, ok)

    f, ok := i.(float64)
    fmt.Println(f, ok)

    f = i.(float64) // 报错(panic)
    fmt.Println(f)
}
```

### 类型选择

**类型选择**是一种按顺序从几个类型断言中选择分支的结构。

类型选择与一般的 `switch` 语句相似，不过类型选择中的 `case` 为类型（而非值）， 它们针对给定接口值所存储的值的类型进行比较。

```go
switch v := i.(type) {
case T:
    // v 的类型为 T
case S:
    // v 的类型为 S
default:
    // 没有匹配，v 与 i 的类型相同
}
```

类型选择中的声明与类型断言 `i.(T)` 的语法相同，只是具体类型 `T` 被替换成了关键字 `type`。

此选择语句判断接口值 `i` 保存的值类型是 `T` 还是 `S`。在 `T` 或 `S` 的情况下，变量 `v` 会分别按 `T` 或 `S` 类型保存 `i` 拥有的值。在默认（即没有匹配）的情况下，变量 `v` 与 `i` 的接口类型和值相同。

### Strings

`fmt` 包中定义的 `Stringer` 是最普遍的接口之一。

```go
type Stringer interface {
    String() string
}
```

`Stringer` 是一个可以用字符串描述自己的类型。`fmt` 包（还有很多包）都通过此接口来打印值。

```go
package main

import "fmt"

type Person struct {
    Name string
    Age  int
}

func (p Person) String() string {
    return fmt.Sprintf("%v (%v years)", p.Name, p.Age)
}

func main() {
    a := Person{"Arthur Dent", 42}
    z := Person{"Zaphod Beeblebrox", 9001}
    fmt.Println(a, z)
}
```

### 错误

Go 程序使用 `error` 值来表示错误状态。

与 `fmt.Stringer` 类似，`error` 类型是一个内建接口：

```go
type error interface {
    Error() string
}
```

（与 `fmt.Stringer` 类似，`fmt` 包在打印值时也会满足 `error`。）

通常函数会返回一个 `error` 值，调用的它的代码应当判断这个错误是否等于 `nil` 来进行错误处理。

```go
i, err := strconv.Atoi("42")
if err != nil {
    fmt.Printf("couldn't convert number: %v\n", err)
    return
}
fmt.Println("Converted integer:", i)
```

`error` 为 `nil` 时表示成功；非 `nil` 的 `error` 表示失败。

```go
package main

import (
    "fmt"
    "math"
)

type ErrNegativeSqrt float64

func (e ErrNegativeSqrt) Error() string {
    return fmt.Sprintf("cannot Sqrt negative number: %v", float64(e))
}

func IsEnough(x, guess float64) bool {
    return math.Abs(x - guess * guess) < 0.0000000000001
}

func Improve(x, guess float64) float64 {
    return guess - (guess * guess - x) / (2 * guess)
}

func Sqrt(x float64) (float64, error) {
    if x < 0 {
        return x, ErrNegativeSqrt(x)
    }

    guess := 1.0
    for !IsEnough(x, guess) {
        guess = Improve(x, guess)
    }
    return guess, nil
}

func main() {
    fmt.Println(Sqrt(2))
    fmt.Println(Sqrt(-2))
}
```

```go
package main

import (
    "io"
    "os"
    "strings"
)

type rot13Reader struct {
    r io.Reader
}

func rot13(b byte) byte {
    switch {
    case ('A' <= b && b <= 'M') || ('a' <= b && b <= 'm'):
        b = b + 13;
    case ('M' < b && b <= 'Z') || ('m' < b && b <= 'z'):
        b = b - 13;
    }
    return b
}

func (reader rot13Reader) Read(b []byte) (int, error) {
    n, e := reader.r.Read(b)

    for i := 0; i < n; i++ {
        b[i] = rot13(b[i])
    }

    return n, e
}

func main() {
    s := strings.NewReader("Lbh penpxrq gur pbqr!")
    r := rot13Reader{s}
    io.Copy(os.Stdout, &r)
}
```

### Go 协程 Goroutine

Go 协程（goroutine）是由 Go 运行时管理的轻量级线程。

```go
go f(x, y, z)
```

会启动一个新的 Go 协程并执行

```go
f(x, y, z)
```

`f`, `x`, `y` 和 `z` 的求值发生在当前的 Go 协程中，而 `f` 的执行发生在新的 Go 协程中。

Go 协程在相同的地址空间中运行，因此在访问共享的内存时必须进行同步。`sync` 包提供了这种能力，不过在 Go 中并不经常用到，一般使用 `channel` 进行同步。

### 信道 channel

channel 是带有类型的管道，可以通过 channel 操作符 `<-` 来发送或者接收值。

```go
ch <- v    // 将 v 发送至信道 ch。
v := <-ch  // 从 ch 接收值并赋予 v。
```

（“箭头”就是数据流的方向。）

和映射与切片一样，channel 在使用前必须创建：

```go
ch := make(chan int)
```

默认情况下，**发送和接收操作在另一端准备好之前都会阻塞**。这使得 Go 协程可以在没有显式的锁或竞态变量的情况下进行同步。

```go
package main

import "fmt"

func sum(s []int, c chan int) {
    sum := 0
    for _, v := range s {
        sum += v
    }
    c <- sum // 将和送入 c
}

func main() {
    s := []int{7, 2, 8, -9, 4, 0}

    c := make(chan int)
    go sum(s[:len(s)/2], c)
    go sum(s[len(s)/2:], c)
    x, y := <-c, <-c // 从 c 中接收

    fmt.Println(x, y, x+y)
}
```

channel 可以是**带缓冲的**，将缓冲长度作为第二个参数提供给 `make` 来初始化一个带缓冲的信道：

```go
ch := make(chan int, 100)
```

仅当 channel 的缓冲区填满后，向其发送数据时才会阻塞。当缓冲区为空时，接受方会阻塞。

发送者可通过 `close` 关闭一个 channel 来表示没有需要发送的值了。接收者可以通过为接收表达式分配第二个参数来测试 channel 是否被关闭：若没有值可以接收且 channel 已被关闭，那么在执行完

```go
v, ok := <-ch
```

之后 `ok` 会被设置为 `false`。

循环 `for i := range c` 会不断从 channel 接收值，直到它被关闭。

**注意**：只有发送者才能关闭 channel，而接收者不能。向一个已经关闭的 channel 发送数据会引发程序 panic。

**还要注意**：channel 与文件不同，通常情况下无需关闭它们。只有在必须告诉接收者不再有需要发送的值时才有必要关闭，例如终止一个 `range` 循环。

```go
package main

import "fmt"

func fibonacci(n int, c chan int) {
    x, y := 0, 1
    for i := 0; i < n; i++ {
        c <- x
        x, y = y, x+y
    }
    close(c)
}

func main() {
    c := make(chan int, 10)
    go fibonacci(cap(c), c)
    for i := range c {
        fmt.Println(i)
    }
}
```

### select

`select` 语句使一个 Go 协程可以等待多个通信操作。`select` 会阻塞到某个分支可以继续执行为止，这时就会执行该分支。当多个分支都准备好时会随机选择一个执行。

```go
package main

import "fmt"

func fibonacci(c, quit chan int) {
    x, y := 0, 1
    for {
        select {
        case c <- x:
            x, y = y, x+y
        case <-quit:
            fmt.Println("quit")
            return
        }
    }
}

func main() {
    c := make(chan int)
    quit := make(chan int)
    go func() {
        for i := 0; i < 10; i++ {
            fmt.Println(<-c)
        }
        quit <- 0
    }()
    fibonacci(c, quit)
}
```

当 `select` 中的其它分支都没有准备好时，`default` 分支就会执行。为了在尝试发送或者接收时不发生阻塞，可使用 `default` 分支：

```go
select {
case i := <-c:
    // 使用 i
default:
    // 从 c 中接收会阻塞时执行
}
```

### 等价二叉树

> https://tour.go-zh.org/concurrency/8

```go
package main

import (
    "golang.org/x/tour/tree"
    "fmt"
)

// Walk 步进 tree t 将所有的值从 tree 发送到 channel ch。
func Walk(t *tree.Tree, ch chan int) {
    if t.Left != nil {
        Walk(t.Left, ch)
    }
    ch <- t.Value
    if t.Right != nil {
        Walk(t.Right, ch)
    }
}

// Same 检测树 t1 和 t2 是否含有相同的值。
func Same(t1, t2 *tree.Tree) bool {
    ch1, ch2 := make(chan int, 10), make(chan int, 10)

    go Walk(t1, ch1)
    go Walk(t2, ch2)

    for i := 1; i < 10; i++ {
        if <-ch1 != <-ch2 {
            return false
        }
    }
    return true
}

func main() {
    ch := make(chan int, 10)
    go Walk(tree.New(1), ch)
    // 使用下面这种方式会出现死锁，为什么？
    // for i := range ch {
    //     fmt.Println(i)
    // }
    for i := 1; i < 10; i++ {
        fmt.Println(<-ch)
    }

    fmt.Println(Same(tree.New(1), tree.New(1)))
    fmt.Println(Same(tree.New(1), tree.New(2)))
}
```

### sync.Mutex

channel 非常适合在各个 Go 协程间进行通信。

但是如果我们并不需要通信呢？比如说，若我们只是想保证每次只有一个 Go 协程能够访问一个共享的变量，从而避免冲突？

这里涉及的概念叫做 **互斥（mutual exclusion）** ，通常使用 **互斥锁（Mutex）** 这一数据结构来提供这种机制。

Go 标准库中提供了 `sync.Mutex` 互斥锁类型及其两个方法：

```go
Lock
Unlock
```

通过在代码前调用 `Lock` 方法，在代码后调用 `Unlock` 方法来保证一段代码的互斥执行。也可以用 `defer` 语句来保证互斥锁一定会被解锁。

### Web 爬虫

> https://tour.go-zh.org/concurrency/10

在这个练习中，我们将会使用 Go 的并发特性来并行化一个 Web 爬虫。

修改 `Crawl` 函数来并行地抓取 URL，并且保证不重复。

提示：你可以用一个 `map` 来缓存已经获取的 URL，但是要注意 `map` 本身并不是并发安全的！

```go
package main

import (
    "fmt"
    "sync"
)

type Fetcher interface {
    // Fetch 返回 URL 的 body 内容，并且将在这个页面上找到的 URL 放到一个 slice 中。
    Fetch(url string) (body string, urls []string, err error)
}

// Crawl 使用 fetcher 从某个 URL 开始递归的爬取页面，直到达到最大深度。
func Crawl(url string, depth int, fetcher Fetcher) {
    // TODO: 并行的抓取 URL。
    // TODO: 不重复抓取页面。
    if depth <= 0 {
        return
    }
    body, urls, err := fetcher.Fetch(url)
    if err != nil {
        fmt.Println(err)
        return
    }
    fmt.Printf("found: %s %q\n", url, body)
    for _, u := range urls {
        Crawl(u, depth-1, fetcher)
    }
    return
}

// 序列化爬取
func Serial(url string, fetcher Fetcher, fetched map[string]bool) {
    if fetched[url] {
        return
    }
    fetched[url] = true
    body, urls, err := fetcher.Fetch(url)
    if err != nil {
        fmt.Println(err)
        return
    }
    fmt.Printf("found: %s %q\n", url, body)
    for _, u := range urls {
        Serial(u, fetcher, fetched)
    }
    return
}

// 分布式爬取，使用共享数据+互斥锁
type fetchState struct {
    mu sync.Mutex
    fetched map[string]bool
}

func ConcurrentMutex(url string, fetcher Fetcher, f *fetchState) {
    f.mu.Lock()
    already := f.fetched[url]
    f.fetched[url] = true
    f.mu.Unlock()

    if already {
        return
    }

    body, urls, err := fetcher.Fetch(url)
    if err != nil {
        fmt.Println(err)
        return
    }
    fmt.Printf("found: %s %q\n", url, body)
    var done sync.WaitGroup
    for _, u := range urls {
        done.Add(1)
        go func(u string) {
            defer done.Done()
            ConcurrentMutex(u, fetcher, f)
        }(u)
    }
    done.Wait()

    return
}

// 分布式爬取，使用 channel 进行主从通信
func worker(url string, ch chan []string, fetcher Fetcher) {
    body, urls, err := fetcher.Fetch(url)
    if err != nil {
        fmt.Println(err)
        ch <- []string{}
    } else {
        fmt.Printf("found: %s %q\n", url, body)
        ch <- urls
    }
}

func master(ch chan []string, fetcher Fetcher) {
    n := 1
    fetched := make(map[string]bool)
    for urls := range ch {
        for _, u := range urls {
            if fetched[u] == false {
                fetched[u] = true
                n += 1
                go worker(u, ch, fetcher)
            }
        }
        // ch 中的数据都为空字符串或者都为 true，就不会进入内层 for 循环，n = 1
        // n -= 1，然后 n = 0 就能够作为循环退出的条件了
        n -= 1
        if n == 0 {
            break
        }
    }
}

func ConcurrentChannel(url string, fetcher Fetcher) {
    ch := make(chan []string)
    // 初始化
    go func() {
        ch <- []string{url}
    }()

    master(ch, fetcher)
}


func main() {
    fmt.Println("Crawl...")
    Crawl("https://golang.org/", 4, fetcher)
    fmt.Println()

    fmt.Println("Serial...")
    fetched := make(map[string]bool)
    Serial("https://golang.org/", fetcher, fetched)
    fmt.Println()

    fmt.Println("ConcurrentMutex...")
    f := &fetchState{fetched: make(map[string]bool)}
    ConcurrentMutex("https://golang.org/", fetcher, f)
    fmt.Println()

    fmt.Println("ConcurrentChannel...")
    ConcurrentChannel("https://golang.org/", fetcher)
    fmt.Println()
}

// fakeFetcher 是返回若干结果的 Fetcher。
type fakeFetcher map[string]*fakeResult

type fakeResult struct {
    body string
    urls []string
}

func (f fakeFetcher) Fetch(url string) (string, []string, error) {
    if res, ok := f[url]; ok {
        return res.body, res.urls, nil
    }
    return "", nil, fmt.Errorf("not found: %s", url)
}

// fetcher 是填充后的 fakeFetcher。
var fetcher = fakeFetcher{
    "https://golang.org/": &fakeResult{
        "The Go Programming Language",
        []string{
            "https://golang.org/pkg/",
            "https://golang.org/cmd/",
        },
    },
    "https://golang.org/pkg/": &fakeResult{
        "Packages",
        []string{
            "https://golang.org/",
            "https://golang.org/cmd/",
            "https://golang.org/pkg/fmt/",
            "https://golang.org/pkg/os/",
        },
    },
    "https://golang.org/pkg/fmt/": &fakeResult{
        "Package fmt",
        []string{
            "https://golang.org/",
            "https://golang.org/pkg/",
        },
    },
    "https://golang.org/pkg/os/": &fakeResult{
        "Package os",
        []string{
            "https://golang.org/",
            "https://golang.org/pkg/",
        },
    },
}
```

## 版权声明

本作品采用[知识共享署名 4.0 国际许可协议](http://creativecommons.org/licenses/by/4.0/)进行许可，转载时请注明原文链接。
