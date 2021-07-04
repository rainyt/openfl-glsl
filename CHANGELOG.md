## 0.1.0
- 修复：修复`if else`解析错误问题。
- 新增：新增`:vertexglsl`元数据支持，仅在vertex着色器中生效的方法。

## 0.0.9
- 改进：改进格式化GLSL，使GLSL看起来更美观。
- 改进：新增了`else if`的支持。
- 改进：使用`/t`代替空格。
- 新增：新增OpenFLGraphicsShader支持，可用于OpenFL的`beginShaderFill`中使用。
- 改进：super.fragment()以及super.vertex()如果不实现则可以移除#pragma body。
- 修复：修复`@:attribute`在OpenFlShader的错误定义，访问`@:attribute`的时候，需要使用`a_变量名`进行访问。

## 0.0.6
- 新增：新增`break`语法识别。
- 改进：改进`;`的生成。
- 改进：多余的空白行自动移除。
- 修复：修复数组变量引用访问错误的问题。
- 改进：修改GLSL的方法与变量的循序。

## 0.0.5
- 1、补充：`EUnop`以及`Binop`的操作符补充。
- 2、新增：新增子类继承父类的变量，如：在父类建立的`:glsl`/`:uniform`等变量，都会被子类继承。
- 3、修复：修复`elseif`语句解析。
- 4、修复：修复`==`语句解析。
- 5、新增：新增GLSL语法格式化。
- 6、新增：新增Define`output`支持，可定义一个输出目录，编译后会将GLSL全部编译到目录下。
- 7、新增：新增`(conf)?else:else`的语法支持。

## 0.0.4
- 1、改进：将`GLSLCompileMacro`与OpenFL功能解耦，允许单独对类使用。
- 2、新增：`@:autoBuild(glsl.macro.GLSLCompileMacro.build("glsl"))`用于支持Haxe解析为GLSL。
- 3、新增：`@:attribute`创建attribute变量。

## 0.0.3
- 1、新增：新增OpenFL的GLSL参数访问。 New: Added GLSL parameter access of OpenFL.
- 2、新增`vertex`顶点着色器`:glVertexSource`支持。Added support for `vertex` vertex shader`:glVertexSource`.
- 3、新增`:varying`支持，可定义varying变量。Added `:varying` support to define varying variables.
- 4、新增`:define`对`vertex`和`fragment`的独立支持。Added `:define` independent support for `vertex` and `fragment`.
- 5、新增`setFrameEvent`的支持，直接启动onFrame方法。Added support for `setFrameEvent` to directly start the onFrame method.
- 6、新增`Array<T>`的解析支持。Added support for parsing `Array<T>`.

## 0.0.1~0.0.2
- 1、新增`OpenFLShader`的支持，允许使用Haxe直接编写GLSL。
- 2、GLSL新增`Vec2`,`Vec3`,`Vec4`变量类型支持。
- 3、GLSL新增`@:uniform`变量类型支持。
- 4、GLSL新增`@:precision`语法。
- 5、GLSL新增`@:define`宏定义语法。
- 6、GLSL新增`@:glsl`宏定义GLSL方法使用。
- 7、改进GLSL的数组语法访问支持。