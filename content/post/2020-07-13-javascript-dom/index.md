---
title: 《JavaScript DOM 编程艺术》读书笔记
author: qiaoin
date: '2020-07-13'
slug: javascript-dom
categories:
  - 编程语言
tags:
  - JS
---

> 本书的精华：书中提到的关于 JavaScript 和 DOM 脚本编程工作的**基本原则、良好习惯和正确思路**

DOM 编程技术的设计思路和原则：平稳退化、渐进增强和以用户为中心，或者说**最佳实践**

标准化 DOM（Document Object Model，文档对象模型）

HTML 超文本标记语言

CSS 层叠样式表

BOM 浏览器对象模型

DOM 是一套对文档的内容进行抽象和概念化的方法，是一种应用编程接口（API）

> DOM 是一种适用于多种环境和多种程序设计语言的通用型 API。

W3C 对 DOM 的定义是：“一个与系统平台和编程语言无关的接口，程序和脚本可以通过这个接口动态地访问和修改文档的内容、结构和样式。”

> 尽管还没有一款浏览器完美无瑕地实现 W3C DOM ，但所有现代浏览器对 DOM 特性的覆盖率都基本达到了 95% ，而且每款浏览器都几乎会在第一时间实现最新的特性。这意味着什么？意味着大量的任务都不必依靠分支代码了。以前，为了探查浏览器，我们不得不编写大量分支判断脚本，现在，终于可以实现"编写一次，随处运行" 的梦想了。只要遵循 DOM 标准，就可以放心大胆地去做，因为你的脚本无论在哪里都不会遇到问题。
>
> 在软件编程领域中，虽然存在着多种不同的语言，但很多任务却是相同或相似的。这也正是 人们需要 API 的原因。一旦掌握了某个标准，就可以把它应用在许多不同的环境中。虽然语法会因为使用的程序设计语言而有所变化，但这些约定却总是保持不变的。
>
> 因此，虽然本书的重点是教会你如何通过 JavaScript 使用 DOM ，当你需要使用诸如 PHP 或 Python 之类的程序设计语言去解析 XML 文档的时候，你获得的 DOM 新知识将会有很大的帮助。
>

- 利用 HTML 把网页标记为各种元素；
- 利用 CSS 设置元素样式和它们的显示位置；
- 利用 JavaScript 实时地操控页面和改变样式。

**如何实践？**

1、新建一个 `example.html` 文件，包含一个 `<script>` 标签，放置在 HTML 文档的最后，`</body>` 标签之前，在 `src` 属性设置好 JavaScript 文件的名字；

```html
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <title>Just a test</title>
    </head>
    <body>
        <script src="example.js"></script>
    </body>
</html>
```

2、新建一个 `example.js` 文件

---

{{< toc >}}

---

## 基础

- 建议在每条语句的末尾都加上一个分号

- 字符串需要包在引号里，单引号或双引号都可以 ------ 代码规范是推荐使用哪种引号

- 基本的数据类型：

  - 字符串

    - 使用 `+` 进行字符串拼接

  - 数值：浮点数

  - 布尔值

  - > 字符串、数值和布尔值都是标量（scalar）。如果某个变量是标量，它在任意时刻就只能有一个值。

  - 数组

    - 声明数组的同时给出数组的长度，`var a = Array(4);`
    - 使用索引下标向数组中填充元素，`a[0] = 'Bing';`
    - 声明数组的同时填充元素，`var a = Array('Liu', 'Bing', 1, true);`
    - 甚至不用明确表示是在创建数组，使用方括号进行包围，`var a = ['Liu', 'Bing', 1, true];`
    - 数组支持同时存储不同的数据类型

- > 如果在填充数组时只给出了元素的值，这个数组就将是一个传统数组，它的各个元素的下标将被自动创建和刷新。
  >
  > 可以通过在填充数组时为每个新元素明确地给出下标来改变这种默认的行为。在为新元素给出下标时，不必局限于使用整数数字，也可以用字符串：
  >
  > ```javascript
  > var lennon = Array();
  > lennon['name'] = 'Bing';
  > lennon['year'] = 1993;
  > lennon['student'] = false;
  > ```

关联数组，不推荐直接使用

- 对象

  - 使用点运算符获取属性

    ```javascript
    var lennon = Object();
    lennon.name = 'Bing';
    lennon.year = 1993;
    lennon.student = false;
    ```

  - 创建对象可以使用花括号语法

    ```javascript
    var lennon = {name:'Bing', year:1993, student:false };
    ```

  - 声明一个空对象

    ```javascript
    var beatles = {};
    ```

- 相等操作符 `==`，认为空字符串和 `false` 的含义相同

- 完全等于 `===`，会执行严格的比较，不仅比较值，而且会比较变量的类型

- 同样有，`!=` 和 `!==`

- if，while，do-while，for 语句都和 C/C++ 语法一致

> **如何命名变量和函数**？在命名变量时，我用下划线来分隔各个单词；在命名函数时，我从第二个单词开始把每个单词的第一个字母写成大写形式（也就是所谓的驼峰命名法）。我这么做是为了能够一眼看出哪些名字是变量，哪些名字是函数。与变量的情况一样，JavaScript 语言也不允许函数的名字里包含空格。驼峰命名法可以在不违反这一规定的前提下， 把变量和函数的名字以一种既简单又 明确的方式区分开来。

## 全局变量和局部变量

> 全局变量（global variable）可以在脚本中的任何位置被引用。一旦你在某个脚本里声明了一个全局变量，就可以从这个脚本中的任何位置——包括函数内部——引用它。全局变量的作用域是整个脚本。
>
> 局部变量（local variable）只存在于声明它的那个函数的内部， 在那个函数的外部是无法去引用它的。局部变量的作用域仅限于某个特定的函数。
>
> 可以用 `var` 关键字明确地为函数变量设定作用域。
>
> 如果在某个函数中使用了 `var`，那个变量就将被视为一个局部变量，它只存在于这个函数的上下文中；反之，如果没有使用 `var`， 那个变量就将被视为一个全局变量，如果脚本里已经存在 一个与之同名的全局变量，这个函数就会改变那个全局变量的值。
>
> 请记住，函数在行为方面应该像一个自给自足的脚本，在定义一个函数肘，我们一定要把它内部的变量全都明确地声明为局部变量。如果你总是在函数里使用 `var` 关键字来定义变量，就能避免任何形式的二义性隐患。

## 对象

对象是自包含的数据集合，包含在对象里的数据可以通过两种形式访问——属性（property）和方法（method）

- **属性**是隶属于某个特定对象的变量
- **方法**是只有某个特定对象才能调用的函数

对象就是由一些属性和方法组合在一起而构成的一个数据实体。

三种对象

1、用户定义对象（user-defined object）：由程序员自行创建的对象

2、内建对象（native object）：内建在 JavaScript 语言里的对象

- 数组 Array
- 数值 Math
- 日期 Date

3、宿主对象（host object）：由浏览器提供的对象。除了内建对象，还可以在 JavaScript 脚本里使用一些已经预先定义好的其他对象。这些对象不是由 JavaScript 语言本身而是由它的**运行环境**提供的。具体到 Web 应用，这个环境就是浏览器。由浏览器提供的预定义对象被称为宿主对象。

- 网页上的表单 Form
- 图像 Image
- 各种表单元素 Element
- document 对象，能够用来获得网页上的任何一个元素的信息

## DOM: document 对象

> W3C 标准的 DOM

1、文档：D，当创建了一个网页并把它加载到 Web 浏览器中时，DOM 会将编写的网页文档转换为一个文档对象

2、对象：O，document 对象的主要功能就是处理网页内容

3、模型：M，节点树

- 元素节点，HTML 标签的名字就是元素的名字
- 文本节点
- 属性节点，用于对元素进行更具体的描述。因为属性总是被放在起始标签里，所以属性节点总是被包含在元素节点中。并非所有的元素都包含着属性，但所有的属性都被元素包含。

## CSS 层叠样式表

> CSS 技术的最大优点是，它能够帮助你将 Web 文档的内容结构(标记)和版面设计(样式)分离开来。
>
> 作为 CSS 技术的突出优点，文档结构与文档样式的分离可以确保网页都能平稳退化。具备 CSS 支持的浏览器固然可以把网页呈现得美轮美奂，不支持或禁用了 CSS 功能的浏览器同样可以把网页的内容按照正确的结构显示出来。
>

告诉浏览器应该如何显示一份文档的内容。类似 JavaScript 脚本，对样式的声明既可以嵌在文档的 `<head>` 部分（`<style>` 标签之间），也可以放在另一个样式表文件中。

```css
selector {
  property: value;
}
```

在样式声明里，我们可以定义浏览器在显示元素时使用的颜色、字体和色号

```css
p {
  color: yellow;
  font-family: "arial", sans-serif;
  font-size: 1.2em;
}
```

**继承（inheritance）** 是 CSS 技术中的一项强大功能。类似于 DOM，CSS 也把文档的内容视为一颗节点树，节点树上的各个元素将继承其父元素的样式属性

为了把某一个或某几个元素与其他元素区分开来，需要使用 `class` 属性或 `id` 属性

**class 属性**：可以在所有的元素上任意应用 `class` 属性

```css
example.html
<p class="special">This paragraph has the special class</p>
<h2 class="special">So does this headline</h2>

example.css
.special {
    font-style: italic;
}

h2.special {
    text-transform: uppercase;
}
```

**id 属性**：给网页里的某个元素添加上一个独一无二的标识符

- 尽管 id 本身只能使用一次，样式表可以利用 id 属性为包含在该特定元素里的其他元素定义样式

```css
example.html
<ul id="purchases">

example.css
#purchases {
    border: 1px solid white;
    background-color: #333;
    color: #ccc;
    padding: 1em;
}

#purchases li {
    font-weight: bold;
}
```

`typeof` 操作符：得到给定操作数的**类型**，字符串、数值、函数、布尔值、对象

## 获取元素

有三种 DOM 方法可获取元素节点，分别是通过元素 ID、通过标签名字和通过 class 名字来获取

### 1、getElementById

```javascript
document.getElementById(id);
```

输入：元素的 id 属性，例如 “purchases”

输出：返回一个对象，对应着 document 对象里的一个独一无二的元素节点，其 HTML id 属性值为 “purchases”

> 事实上，文档中的每一个元素节点都是一个对象，这些对象天生具有一些非常有用的方法，这样归功于 DOM。例如这些预先定义好的方法，我们不仅可以检索出文档里任何一个对象的信息，而且还可以改变元素的属性

### 2、getElementsByTagName

```javascript
element.getElementsByTagName(tag);
```

输入：HTML 标签，例如 `li` 标签

输出：返回一个对象数组，每个对象分别对应着文档里有着给定**标签**的一个元素节点。即使整个 HTML 文档对应这个标签只有一个元素，`getElementsByTagName` 也会返回一个数组，此时数组长度为 1

- `getElementsByTagName("*")` 允许使用通配符作为它的参数，意味着文档里的每个元素都将在返回的数组中出现
- `getElementById()` 和 `getElementsByTagName()` 结合使用，例如想得到 id 属性值是 “purchases” 的元素包含着多少个列表项，必须通过一个更具体的对象去调用这个方法

```javascript
var shopping = document.getElementById("purchases");
var items = shopping.getElementsByTagName("*");
```

这两条语句执行完毕之后，`items` 数组将只包含 id 属性值是 “purchases” 的无需清单里的元素

### 3、getElementsByClassName

> HTML 中 class 按照空格分隔

```javascript
element.getElementsByClassName(class);
```

输入：元素的 class 属性，例如 “special”。如果需要指定多个类名，只要在字符串参数中用空格分隔类名即可

输出：返回一个对象数组，包含具有给定类名的元素节点

## 获取和设置属性

### 4、getAttribute

```javascript
object.getAttribute(attribute);
```

>getAttribute 方法不属于 document 对象，不能通过 document 对象调用；只能通过元素节点对象调用

输入：查询的属性名

输出：得到属性值

与 `getElementByTagName` 方法合用，获取每个 `<p>` 元素的 `title` 属性，过滤掉没有 `title` 属性的 `<p>` 元素

```javascript
var paras = document.getElementsByTagName("p");
for (var i = 0; i < paras.length; i++) {
    var title_text = paras[i].getAttribute("title");
    if (title_text != null) {
        alert(title_text);
    }
}
```

上述这段代码可以更简短些。当检查某项数据是否是 `null` 值时，我们其实是在检查它是否存在。这种检查可以简化为直接把被检查的数据用作 `if` 语句的条件。 `if (something)` 与 `if (something != null)` 完全等价，但前者显然更为简明。此时，如果 `something` 存在，则 `if` 语 句的条件将为真；如果 `something` 不存在，则 `if` 语句的条件将为假。

```javascript
var paras = document.getElementsByTagName("p");
for (var i = 0; i < paras.length; i++) {
    var title_text = paras[i].getAttribute("title");
    if (title_text) {
        alert(title_text);
    }
}
```

### 5、setAttribute

```javascript
object.setAttribute(attribute, value);
```

> 只能通过元素节点对象调用，（如果属性不存在）先创建这个属性，然后设置它的值；如果用在一个本身就有这个属性的元素节点上，原有属性值就被覆盖掉了
>
> **可以修改文档中的任何一个元素的任何一个属性**

输入：属性和属性值

```javascript
var shopping = document.getElementById("purchases");
alert(shopping.getAttribute("title"));
shopping.setAttribute("title", "a list of goods");
alert(shopping.getAttribute("title"));
```

> 有一个非常值得关注的细节：通过 `setAttribute` 对文档做出修改后，在通过浏览器的 view source (查看源代码)选项去查看文档的源代码时看到的仍将是改变前的属性值，也就是说，`setAttribute` 做出的修改不会反映在文档本身的源代码里。这种“表里不一”的现象源自 DOM 的工作模式：先加载文档的静态内容，再动态刷新，动态刷新不影响文档的静态内容。这正是 DOM 的真正威力：对页面内容进行刷新却不需要在浏览器里刷新页面。

### 6、childNodes 属性

获取任何一个元素的所有子元素，为包含这个元素全部子元素的数组

```javascript
element.childNodes
```

> 文档树的节点类型并非只有元素节点一种。由 **childNodes** 属性返回的数组包含所有类型的节点，而不仅仅是元素节点。事实上，文档里几乎每一样东西都是一个节点，甚至连空格和换行符都被解释为节点，而它们也全都包含在 **childNodes** 属性所返回的数组当中

### 7、nodeType 属性

文档中每一个节点的属性，返回节点类型，为一个数字

```javascript
node.nodeType
```

nodeType 属性总共有 12 种可取值，但其中仅有 3 种具有实用价值。

- 元素节点的 nodeType 属性值是 1
- 属性节点的 nodeType 属性值是 2
- 文本节点的 nodeType 属性值是 3

### 8、nodeValue 属性

得到（和**设置**）一个节点的值

```javascript
node.nodeValue
```

### 9、firstChild 和 lastChild 属性

```javascript
node.firstChild // node.childNodes[0]

node.lastChild // node.childNodes[node.childNodes.length - 1]
```

## JavaScript 图片库

方案1：简单的将所有图片都放到一个网页中，如果图片较多，这样网页就会下载缓慢

方案2：为每张图片分别创建一个网页，这样耗时，同时还需要提供不同的导航链接

方案3：把整个图片库的浏览链接集中安排在图片库主页里，只在用户点击了这个主页里的某个图片链接时才把对应的图片传送给他

添加事件处理函数（event handler）：在特定事件发生时调用特定的 JavaScript 代码

- `onmouseover` 事件处理函数 —— 鼠标指针悬停在某个元素上时触发
- `onmouseout` 事件处理函数 —— 鼠标指针离开某个元素时触发
- `onclick` 事件处理函数 —— 用户点击某个链接时触发

> 事件处理函数的工作机制。在给某个元素添加了事件处理函数后，一旦事件发生，相应的 JavaScript 代码就会得到执行。被调用的 JavaScript 代码可以返回一个值，这个值将被传递给那个事件处理函数。例如，我们可以给某个链接添加一个 onclick 事件处理函 蠢，并让这个处理函数所触发的 JavaScript 代码返回布尔值 true 或 false。这样一来，当这个链接被点击时，如果那段 JavaScript 代码返回的值是 true ， onclick 事件处理函数就认为“这个链接被点击了”；反之，如果返回的值是 false ， onclick 事件处理函数就认为"这个链接没有被点击"。

以下为简单的实现，关注两个重点：一是如何利用 DOM 所提供的方法去编写图片库脚本， 二是如何利用事件处理函数把 JavaSαipt 代码与网页集成在一起。

```javascript
// gallery.html
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <title>Image Gallery</title>
        <link rel="stylesheet" href="styles/gallery.css" media="screen" />
    </head>
    <body>
        <h1>Snapshots</h1>
        <ul>
            <li>
                <a href="images/fireworks.png" title="A fireworks display" onclick="showPic(this); return false;">Fireworks</a>
            </li>
            <li>
                <a href="images/coffee.png" title="A cup of black coffee" onclick="showPic(this); return false;">Coffee</a>
            </li>
            <li>
                <a href="images/rose.png" title="A red, red rose" onclick="showPic(this); return false;">Rose</a>
            </li>
            <li>
                <a href="images/bigben.png" title="The famous clock" onclick="showPic(this); return false;">Big Ben</a>
            </li>
        </ul>
        <img id="placeholder" src="images/placeholder.png" alt="my image gallery" />
        <p id="description">Choose an image.</p>
        <script type="text/javascript" src="scripts/gallery.js"></script>
    </body>
</html>

// gallery.js
function showPic(whichpic) {
    var source = whichpic.getAttribute("href");
    var placeholder = document.getElementById("placeholder");
    placeholder.setAttribute("src", source);

    var text = whichpic.getAttribute("title");
    var description = document.getElementById("description");
    description.firstChild.nodeValue = text;
}

// gallery.css
body {
    font-family: "Helvetica", "Arial", serif;
    color: #333;
    background-color: #ccc;
    margin: 1em 10%;
}

h1 {
    color: #333;
    background-color: transparent;
}

a {
    color: #c60;
    background-color: transparent;
    font-weight: bold;
    text-decoration: none;
}

ul {
    padding: 0;
}

li {
    float: left;
    padding: 1em;
    list-style: none;
}

img {
    display: block;
    clear: both;
}
```

改进点：第六章，多次看一下，如何改进

## 最佳实践

> 达成目标的过程与目标本身同样重要。

- 若一个站点用到多个 JavaScript 文件，为了减少对站点的请求次数(提高性能) ，应 该把这些 JS 文件合并到一个文件中。

> 如果要使用 JavaScript，就要确认：这么做会对用户的浏览体验产生怎样的影响？还有个更重要的问题：如果用户的浏览器不支持 JavaScript 该怎么办?

### 平稳退化（graceful degradation）

确保网页在没有 JavaScript 的情况下也能正常工作；虽然某些功能无法使用，但最基本的操作仍能顺利完成。渐进增强的实现必然支持平稳退化

- 渐进增强：使用一些额外的信息层去包裹原始数据。按照“渐进增强”原则创建出来的网页几乎都符合“平稳退化”的原则
- 渐进增强原则基于这样一种思想：你应该总是从最核心的部分，也就是内容开始。应该根据内容使用标记实现良好的结构；然后再逐步加强这些内容。这些增强工作既可以是通过 CSS 改进呈现效果，也可以是通过 DOM 添加各种行为
- 类似 CSS，JavaScript 和 DOM 提供的所有功能也应该构成一个额外的指令层。CSS 代码负责提供关于“表示”的信息，JavaScript 代码负责提供关于“行为”的信息。行为层的应用方式和表示层一样

### 分离 JavaScript

把网页的结构和内容与 JavaScript 脚本的动作行为分开

```html
<a href="images/fireworks.png" title="A fireworks display" onclick="showPic(this); return false;">Fireworks</a>
```

- 在 HTML 文档里使用诸如 `onClick` 之类的属性是一种既没有效率又容易引发问题的做法
- JavaScript 不要求事件必须在 HTML 文档里处理，可以在外部 JavaScript 文件里把一个事件添加到 HTML 文档中的某个元素上

```javascript
element.[event] = [action ...]
```

- 如何将捕获这个事件的元素确定下来？可以利用 class 或 id 属性
- 如果想把一个事件添加到某个特定 id 属性的元素上，使用 `getElementById` 就可以解决问题：

```javascript
getElementById(id).[event] = [action]
```

- 如果事件涉及多个元素，可以用 `getElementsByTagName` 和 `getAttribute` 把事件添加到有着特定属性的一组元素上
  1. 把文档中的所有链接全放入一个数组里；
  2. 遍历数组；
  3. 如果某个链接的 class 属性等于 popup，就表示这个链接在被点击时应该调用 `popUp()` 函数
     - 把这个链接的 href 属性值传递给 `popUp()` 函数
     - 取消这个链接的默认行为，不让这个链接把访问者带离当前窗口
  4. 以下代码将把调用 `popUp()` 函数的 `onclick` 事件添加到有关的链接上。只需要将 JS 代码存入一个外部 JavaScript 文件，就等于是把这些操作从 HTML 文档里分离出来了

```javascript
<a href="http://www.example.com/" class="popup">Example</a>

function popUp(winURL) {
    window.open(winURL, "popup", "width=320, height=480");
}

var links = documents.getElementsByTagName("a");
for (var i = 0; i < links.length; i++) {
    if (links[i].getAtrribute("class") == "popup") {
        links[i].onclick = function() {
            popUp(this.getAttribute("href"));
            return false;
        }
    }
}
```

<font color='red'><b>问题：</b></font> 如果把这段代码存入外部 JavaScript 文件，它们将无法正常运行。因为这段代码的第一行是：

```javascript
var links = documents.getElementsByTagName("a");
```

这条语句将在 JavaScript 文件被夹在时立刻执行。如果 JavaScript 文件是从 HTML 文件的 `<head>` 部分用 `<script>` 标签调用的，它将在 HTML 文档之前加载到浏览器里。同样，如果 `<script>` 标签位于文档底部 `<body>` 之前，就不能保证哪个文件最先结束加载（浏览器可能一次加载多个）。因为脚本加载时文档可能不完整，所以模型也不完整。没有完整的 DOM，`getElementsByTagName` 等方法就不能正常工作

==> 必须让这些代码在 HTML 文档全部加载到浏览器之后才开始执行。HTML 文档全部加载完毕时会触发一个[事件](https://developer.mozilla.org/zh-CN/docs/Web/API/GlobalEventHandlers/onload)

> 在文档装载完成后会触发  `load` 事件。此时，在文档中的所有对象都在DOM中，所有图片，脚本，链接以及子框都完成了装载。

因此，我们将 JavaScript 代码打包到 `prepareLinks` 函数里，并把这个函数添加到 window 对象 `onload` 事件上去。这样一来，DOM 就可以正常工作了：

```javascript
<a href="http://www.example.com/" class="popup">Example</a>

window.onload = prepareLinks;

function prepareLinks() {
    if (!document.getElementsByTagName) return false;
    var links = documents.getElementsByTagName("a");
    for (var i = 0; i < links.length; i++) {
        if (links[i].getAtrribute("class") == "popup") {
            links[i].onclick = function() {
                popUp(this.getAttribute("href"));
                return false;
            }
        }
    }
}

function popUp(winURL) {
    window.open(winURL, "popup", "width=320, height=480");
}
```

**向后兼容性**：确保老版本的浏览器不会因为你的 JavaScript 脚本而死掉

> 不同浏览器对 JavaScript 的支持程度不一样

- 对象检测（object detection）：检测浏览器对 JavaScript 的支持程度，只要把某个方法打包在一个 `if` 语句中，就可以根据这条 `if` 语句的条件表达式的求值结果是 `true` （这个方法存在）还是 `false` （这个方法不存在）来决定应该采取怎样的行动

> 几乎所有的东西（包括各种方法在内）都可以被当作对象，这就意味着我们可以很容易地把不支持某个特定 DOM 方法的浏览器检测出来

```javascript
if (method) {
    statements;
}

if (!method) return false;
```

> 例如，如果有一个使用了 getElementByld() 方法的函数，就可以在调用 getElementByld()方法之前先检查用户所使用的浏览器是否支持这个方法。在使用对象检测时，一定要删掉方法名后面的圆括号，如果不删掉，测试的将是方法的结果，无论方法是否存在。

```javascript
function myFunction() {
    if (document.getElementById) {
        // statements using getElementById
    }
  
    // 或者
    if (document.getElementById) return false;
    // statements using getElementById
}
```

**性能考虑**：确定脚本执行的效能最优

- 尽量少的访问 DOM 和尽量减少标记

  - 只要是查询 DOM 中的某些元素，浏览器就会搜索整个 DOM 树，从中查找可能匹配的元素

  > <font color='red'><b>没有明白这句话的意思？</b></font>在多个函数都会取得一组类似元素的情况下，可以考虑重构代码，把搜索结果保存在一个全局变量里，或者把一组元素直接以参数形式传递给函数

  - 过多不必要的元素只会增加 DOM 树的规模，进而增加遍历 DOM 树以查找特定元素的时间

- 合并脚本

  - 推荐是将多个脚本合并到一个脚本文件中，这样就可以减少加载页面时发送的请求数量

```javascript
<script src="script/functionA.js"></script>
<script src="script/functionB.js"></script>
<script src="script/functionC.js"></script>
<script src="script/functionD.js"></script>
```

- 放置脚本的位置
  - 脚本在标记中的位置对页面的初次加载时间也有很大影响
  - 1、将脚本放置在 `<head>` 区域。问题：位于 `<head>` 块中的脚本会导致浏览器无法并行加载其他文件（如图像或其他脚本）。一般来说，根据 HTTP 规范，浏览器每次从同一个域名中最多只能同时下载两个文件。而在下载脚本期间，浏览器不会下载其他任何文件，即使是来自不同域名的文件也不会下载，所有其他资源都要等脚本加载完毕后才能下载
  - 2、将所有 `<script>` 标签放到文档的末尾，`</body>` 标记之前，就可以让页面变得更快。这样，我们在加载脚本时，window 对象的 `load` 事件依然可以执行对文档进行的各种操作
- 压缩脚本文件：将脚本文件中不必要的字节，如空格和注释，统统删掉，从而达到“压缩”文件的目的
- 多数情况下，你应该有两个版本，一个是工作副本，可以修改代码并添加注释；另一个是精简副本，用于放在站点上

## DOM Core 和 HTML DOM

截止到现在，我们在编写 JavaScript 代码时只用到了一下几个 DOM 方法：

- `getElementById`
- `getElementsByTagName`
- `getAttribute`
- `setAttribute`

这些方法都是 DOM Core 的组成部分。它们并不专属于 JavaScript，支持 DOM 的任何一种程序设计语言都可以使用它们。它们的用途也并非仅限于处理网页，它们可以用来处理用任何一种标记语言（比如 XML）编写出来的文档

在使用 JavaScript 语言和 DOM 为 HTML 文件编写脚本时，还有许多属性可供选用。例如，`onclick` 属性，用于图片库中的事件管理。这些属性属于 HTML-DOM，它们在 DOM Core 出现之前很久就已经为人们所熟悉了

## 动态创建标记

**传统方法：**都是 HTML 专有属性，即 MIME 类型为 `application/html`

- `document.write` —— 避免使用
- `innerHTML` 属性 —— 既支持读取，又支持写入（表达式左边）

> - 一旦你使用了 `innerHTML` 属性，它的全部内容都将被替换
> - 在需要把一段 HTML 内容插入一份文档时，`innerHTML` 属性可以让你又快又简单地完成这一任务。不过，`innerHTML` 属性不会返回任何对刚插入的内容的引用。如果想对刚插入的内容进行处理，则需要使用 DOM 提供的那些精确的方法和属性
> - `innerHTML` 属性要比 `document.write()` 方法更值得推荐。使用 `innerHTML` 属性，你就可以把 JavaScript 代码从标记中分离出来。用不着再在标记的 `<body>` 部分插入 `<script>` 标签

**DOM 方法：**DOM 是文档的表示。DOM 所包含的信息与文档里的信息一一对应。只要使用正确的方法，就可以获取 DOM 节点树上任何一个节点的细节

- DOM 不仅可以获取文档的内容，还可以更新文档的内容
- 在浏览器看来，DOM 节点树才是文档
- 动态创建标记：实际上并不是在创建标记，而是在改变 DOM 节点树
- 一定要从 DOM 的角度去思考问题。在 DOM 看来，一个文档就是一棵节点树。如果你想在节点树上添加内容，就必须插入新的节点。如果你想添加一些标记到文档，就必须插入元素节点

### 10、createElement

```javascript
var ele = document.createElement(nodeName);
```

创建一个新的**元素节点**。这个方法本身并不能影响页面的表现，还需要把这个新创建出来的元素插入到文档中去。

但新创建的这个元素，已经有了自己的 DOM 属性，节点类型 `ele.nodeType`，节点值 `ele.nodeValue`

### 11、appendChild

把新创建的节点插入某个文档的节点树的最简单的办法是，让它成为这个文档某个现有节点的一个字节点

```javascript
parent.appendChild(child);
```

### 12、createTextNode

```javascript
var txt = document.createTextNode(text);
```

创建一个新的**文本节点**。

创建一个 `<p>` 节点，并添加文字 `hello, world`

```javascript
window.onload = function() {
    var testdiv = document.getElementById("testdiv");
    var para = document.createElement("p");
    testdiv.appendChild(para);
    var txt = document.createTextNode("hello, world");
    para.appendChild(txt);
}
```

### 13、createTextNode

```javascript
parentElement.insertBefore(newElement, targetElement);
```

在已有元素前插入一个新元素

- 新元素：想要插入的新元素（newElement）
- 目标元素：想要将这个新元素插入到哪个元素（targetElement）之前
- 父元素：目标元素的父元素（parentElement），目标元素的 `parentNode` 属性就是其父元素

> 在 DOM 里，元素节点的父元素必须是另一个元素节点，属性节点和文本节点的子元素不允许是元素节点

### 14、insertAfter：需要自己实现，DOM 未提供这个方法

在现有元素后面插入一个新元素

```javascript
function insertAfter(newElement, targetElement) {
    var parent = targetElement.parentNode;
    if (parent.lastChild === targetElement) {
        parent.appendChild(newElement);
    } else {
        parent.insertBefore(newElement, targetElement.nextSibling);
    }
}
```

使用到的 DOM 方法和属性：

- `parentNode` 属性
- `lastChild` 属性
- `appendChild` 方法
- `insertBefore` 方法
- `nextSibling` 属性

## 动态创建信息块

> 除了 HTML 标签之间的内容以外，标签内的属性中也包含语义信息。在对内容进行标记时，正确地设置标记属性也是工作的重要组成部分。
>
> 绝大多数属性的内容（即属性值）在 Web 浏览器里都是不显示的，只有极少数属性例外，但不同的浏览器在呈现这些属性时也常常千姿百态
>
> 使用 DOM 来显示属性的内容
>
>用 JavaScript 函数先把文档结构里的一些现有信息提取出来，再把那些信息以一种清晰和有意义的方式重新插入到文档里去

### 显示缩略语列表

```javascript
function displayAbbreviations() {
    if (!document.getElementsByTagName) return false;
    if (!document.createElement) return false;
    if (!document.createTextNode) return false;

    // 取得所有缩略词
    var abbreviations = document.getElementsByTagName("abbr");
    if (abbreviations.length < 1) return false;

    var defs = new Array();
    // 遍历所有缩略词
    for (var i = 0; i < abbreviations.length; i++) {
        var current_abbr = abbreviations[i];
        if (current_abbr.childNodes.length < 1) continue;
        var definition = current_abbr.getAttribute("title");
        var key = current_abbr.lastChild.nodeValue;
        console.log("key = ", key, ", definition = ", definition);

        defs[key] = definition;
    }

    // 创建定义列表
    var dlist = document.createElement("dl");
    for (const key in defs) {
        // 创建 dt 元素
        var dtitle = document.createElement("dt");
        var dtitle_txt = document.createTextNode(key);
        dtitle.appendChild(dtitle_txt);

        // 创建 dd 元素
        var ddesc = document.createElement("dd");
        var ddesc_txt = document.createTextNode(defs[key]);
        ddesc.appendChild(ddesc_txt);

        // 把它们添加到定义列表
        dlist.appendChild(dtitle);
        dlist.appendChild(ddesc);
    }

    if (dlist.childNodes.length < 1) return false;

    // 创建标题
    var header = document.createElement("h2");
    var header_txt = document.createTextNode("Abbreviations");
    header.appendChild(header_txt);

    // 将标题添加到 body
    document.getElementsByTagName("body")[0].appendChild(header);
    // 将定义列表添加到 body
    document.getElementsByTagName("body")[0].appendChild(dlist);
}
```

### 显示“文献来源链接表”

```javascript
function displayCitations() {
    if (!document.getElementsByTagName) return false;
    if (!document.createElement) return false;
    if (!document.createTextNode) return false;
    // 取得所有的引用
    var quotes = document.getElementsByTagName("blockquote");

    // 读取 cite，并设置
    for (var i = 0; i < quotes.length; i++) {
        if (!quotes[i].getAttribute("cite")) continue;
        var url = quotes[i].getAttribute("cite");

        // 取出当前 blockquote 元素里所有的元素节点
        var quoteChilds = quotes[i].getElementsByTagName("*");
        if (quoteChilds.length < 1) continue;
        // 得到 blockquote 元素的最后一个元素节点
        var elem = quoteChilds[quoteChilds.length - 1];

        // 创建链接，标识文本为 source，链接为 url
        var link = document.createElement("a");
        var link_txt = document.createTextNode("source");
        link.appendChild(link_txt);
        link.setAttribute("href", url);

        // 创建上标
        var superscript = document.createElement("sup");
        superscript.appendChild(link);

        // 插入链接
        elem.appendChild(superscript);
    }
}
```

### 显示快捷键清单

```javascript
function displayAccesskeys() {
    if (!document.getElementsByTagName) return false;
    if (!document.createElement) return false;
    if (!document.createTextNode) return false;

    // 取得所有链接
    var links = document.getElementsByTagName("a");
    var akeys = new Array();

    // 遍历所有链接
    for (var i = 0; i < links.length; i++) {
        var current_link = links[i];
        if (!current_link.getAttribute("accesskey")) continue;
        var key = current_link.getAttribute("accesskey");
        var txt = current_link.lastChild.nodeValue;
        akeys[key] = txt;
    }

    // 创建无序列表
    var list = document.createElement("ul");
    for (const key in akeys) {
        // 创建列表项 li
        var item = document.createElement("li");
        var item_txt = document.createTextNode(key + ": " + akeys[key]);
        item.appendChild(item_txt);

        // 将列表项添加到无序列表
        list.appendChild(item);
    }

    // 创建标题
    var header = document.createElement("h3");
    var header_txt = document.createTextNode("Accesskeys");
    header.appendChild(header_txt);

    // 将标题添加到 body
    document.getElementsByTagName("body")[0].appendChild(header);
    document.getElementsByTagName("body")[0].appendChild(list);
}
```

**生成一份目录：**把文档中 `h1` `h2` 元素提取出来放入一份清单，再将其插入到文档的开头，同时增加跳转链接

<font color='red'><b>【TODO】琢磨一下这个作为第一个练手的项目</b></font>

https://www.cnblogs.com/xdp-gacl/p/3718879.html

在需要对文档里的现有信息进行检索时，以下 DOM 方法很有用：

- `getElementById`
- `getElementByTagName`
- `getAttribute`

在需要把信息添加到文档里去时，以下 DOM 方法很有用：

- `createElement`
- `createTextNode`
- `appendChild`
- `insertBefore`
- `setAttribute`

## CSS-DOM

浏览器中看到的网页是由以下三层信息构成的一个共同体：

- 结构层：使用 HTML 搭建文档的结构
- 表示层：使用 CSS 去设置文档的呈现效果
- 行为层：使用 DOM 脚本去实现文档的行为

表示层和行为层总是存在的，即使未明确地给出任何具体的指令。此时，Web 浏览器将应用它的默认样式和默认事件处理函数。

HTML、CSS 和 DOM 脚本，这三种技术之间存在一些潜在的重叠区域

- DOM 可以改变网页的结构，诸如 `createElement` 和 `appendChild` 之类的 DOM 方法允许动态地创建和添加标记
- CSS 也有重叠的例子，诸如 `:hover` 和 `:focus` 之类的伪类允许根据用户触发事件改编元素的呈现效果
- DOM 样式可以给元素设定样式

### style 属性

文档中的每个元素都是一个对象，每个对象又有着各种各样的属性

- 【只读】有些属性告诉我们元素在节点树上的位置信息，例如，`parentNode`、`nextSibling`、`previousSibling`、`childNode`、`firstChild`、`lastChild`
- 【只读】一些属性包含元素本身的信息，例如，`nodeType` `nodeName`
- 【可读可写】文档的每个元素都有一个 `style` 属性，包含着元素的样式，表示为一个对象。style 对象的各个属性都是可读写的，不仅可以通过某个元素的 style 属性去获取样式，还可以通过它去更新样式

```javascript
// 获取样式
element.style.property;

// 更新样式
element.style.property = value;  // value 为一个字符串
```

- CSS 样式属性名字中的连字符 `-`，在访问时使用**驼峰命名**
- DOM 在表示样式属性时采用的单位并不总是与它们在 CSS 样式表里的设置相同
  - 这类例外情况并不多。绝大多数样式属性的返回值与它们的设置值都采用同样的计量单位
- CSS 的**速记属性**，DOM 可以解析

**通过 style 属性获取的样式的局限性**：只能返回内嵌样式。换句话说，只有把 CSS style 属性插入到标记里，才可以用 DOM style 属性去查询这些信息

```html
<p id="example" style="color: #999999; font: 12px 'Arial', sans-serif;">
    An example of a paragraph
</p>
```

- 单独放在 CSS 文件中的样式，DOM 检索不出来
- 放在 `<head>` 部分的 `<style>` 标签里，DOM style 属性也提取不到

=> 在外部样式表里使用的样式不会进入 style 对象，在文档 `<head>` 部分里声明的样式也是如此

=> 用 DOM 设置的样式，可以用 DOM 再把它们检索出来

### 何时该用 DOM 脚本设置样式

**使用 CSS 声明样式的方法**，注意 CSS 样式文件中 value 值不需要添加引号

1、为标签元素统一声明样式

```css
p {
    font-size: 1em;
}
```

2、为特定 class 属性的所有元素统一声明样式

```css
.fineprint {
    font-size: .8em;
}
```

3、为特定 id 属性的所有元素统一声明样式

```css
#intro {
    font-size: 1.2em;
}
```

**如何决定使用 CSS 还是 DOM 脚本实现样式设置**，使用 DOM 去修改样式，基于两点原因：

1. CSS 无法定位到想要处理的目标元素
2. CSS 寻找目标元素的办法还未得到广泛的支持

- 如果想改变某个元素的呈现效果，使用 CSS
- 如果想改变某个元素的行为，使用 DOM
- 如果想根据某个元素的行为去改变它的呈现效果。这一类场合，决定是采用纯粹的 CSS 来解决，还是利用 DOM 来设置样式，需要考虑以下因素：
  - 这个问题最简单的解决方案是什么？
  - 哪种解决方案会得到更多浏览器的支持？
  - => 要做出明智的抉择，就必须对 CSS 和 DOM 技术都有足够深入的了解

### 根据元素在节点树里的位置来设置样式

```javascript
function getNextElement(node) {
    if (node.nodeType === 1) {
        return node;
    }
    if (node.nextSibling) {
        return getNextElement(node.nextSibling);
    }
    return null;
}

function addClass(element, value) {
    if (!element.className) {
        element.className = value;
    } else {
        newClassName = element.className;
        newClassName += " ";
        newClassName += value;
        element.className = newClassName;
    }
}

function styleHeaderSiblings() {
    if (!document.getElementsByTagName) return false;
    var headers = document.getElementsByTagName("h1");
    var elem;
    for (var i = 0; i < headers.length; i++) {
        elem = getNextElement(headers[i].nextSibling);

        // 方式 1，不推荐
        // elem.style.fontWeight = "bold";
        // elem.style.fontSize = "1.2em";

        // 方式 2，推荐
        addClass(elem, "intro");
    }
}

// 在 CSS 文件中定义一个样式
.intro {
    font-weight: bold;
    font-size: 1.2em;
}
```

### 根据某种条件反复设置某种样式

```javascript
function stripeTables() {
    if (!document.getElementsByTagName) return false;
    var tables = document.getElementsByTagName("table");
    var odd, rows;
    for (var i = 0; i < tables.length; i++) {
        odd = false;
        rows = tables[i].getElementsByTagName("tr");
        for (var j = 0; j < rows.length; j++) {
            if (odd === true) {
                // rows[j].style.backgroundColor = "#ffc";
                addClass(row[j], "odd");
                odd = false;
            } else {
                odd = true;
            }
        }
    }
}

// 在 CSS 文件中定义一个样式
.odd {
    background-color: #ffc;
}
```

### 响应事件

```javascript
function highlightRows() {
    if (!document.getElementsByTagName) return false;
    var rows = document.getElementsByTagName("tr");
    for (var i = 0; i < rows.length; i++) {
        rows[i].onmouseover = function() {
            // this.style.fontWeight = "bold";
            addClass(this, "mouseover");
        }
        rows[i].onmouseout = function() {
            // this.style.fontWeight = "normal";
            addClass(this, "mouseot");
        }
    }
}

// 在 CSS 文件中定义两个样式
.mouseover {
    font-weight: bold;
}

.mouseout {
    font-weight: normal;
}
```

### 15、setTimeout、clearTimeout

```javascript
// 设置函数的延迟执行
var variable = setTimeout("function", interval);

// 取消某个正在排队等待执行的函数
clearTimeout(variable);
```

输入：

- `function`：函数名
- `interval`：间隔时间，单位毫秒，设置需要经过多长时间才开始执行第一个参数设置的函数

## Ajax 异步加载页面

<font color='red'><b>以前</b></font>，Web 应用都要涉及大量的页面刷新：用户点击了某个链接，请求发送回服务器，然后服务器根据用户的操作再返回新页面。即使用户看到的只是页面中的一小部分有变化，也要刷新和重新加载整个页面，包括公司标志、导航、头部区域、脚部区域等

<font color='red'><b>使用 Ajax</b></font> 就可以做到只更新页面中的一小部分。其他内容——标志、导航、头部、脚部，都不用重新加载。用户仍然像往常一样点击链接，但这一次，已经加载的页面中只有一小部分区域会更新，而不必再次加载整个页面

> Ajax 的主要优势是对页面的请求以异步方式发送到服务器。而服务器不会用整个页面来响应请求，它会在后台处理请求，与此同时用户还能继续浏览页面并与页面交互。你的脚本则可以按需加载和创建页面内容，而不会打断用户的浏览体验。

Ajax

- 依赖 JavaScript，所以可能有浏览器不支持
- 搜索引擎的爬虫程序抓去不到相关内容

**核心： XMLHttpRequest 对象**，JavaScript 通过这个对象可以自己发送请求，同时也自己处理响应
