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