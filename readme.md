## OpenFL-GLSL
使用Haxe编写GLSL，编写时，请确保你使用的类都是GLSL所支持的，基础类由vector-math支持。
在Haxe中，你可以正常使用：Array<T>、int、float、bool、vec2、vec3、vec4、mat2、mat3、mat4等。
Use Haxe to write GLSL. When writing, please make sure that the classes you use are supported by GLSL, and the basic classes are supported by vector-math.
In Haxe, you can use it normally: Array<T>, int, float, bool, vec2, vec3, vec4, mat2, mat3, mat4, etc.

## Test.hx
```haxe
@:debug
class Test extends glsl.OpenFLShader {
	public function new() {
		super();
	}

	override function fragment() {
		super.fragment();
		var v:Vec2 = this.gl_openfl_TextureCoordv * 0.5;
		this.gl_FragColor = texture2D(gl_openfl_Texture, v);
	}
}
```

## Test.hx to GLSL
最终Test.hx的fragment方法会被编译成GLSL，并可直接被OpenFL使用。
Finally, the fragment method of Test.hx will be compiled into GLSL and can be used directly by OpenFL.
```glsl
#pragma header

 void main(void){
    #pragma body
    vec2 v=openfl_TextureCoordv*0.5;
    gl_FragColor=texture2D(openfl_Texture,v);
}
```

Use:
```haxe
var bitmap = new Bitmap();
bitmap.shader = new Test();
```

## 注意
- 当前已实现了`:glFragmentSource`以及`:glVertexSource`的GLSL的编写支持。Currently, GLSL writing support for `:glFragmentSource` and `:glVertexSource` has been implemented.
- 需要依赖（Need to rely on vector-math）[vector-math](https://github.com/haxiomic/vector-math) 

# 宏功能

## @:debug
在Class上添加`:debug`可以将转义后的GLSL输出：
Add `:debug` to class to output escaped glsl:
```haxe
@:debug
class Shader extends glsl.OpenFLShader {}
```
通过`haxe build.hxml`编译后会自动输出。
After compiling through 'haxe build. Hxml', it will output automatically.

## @:glsl
在方法中添加`@:glsl`则会将方法转义成GLSL，并提供给着色器使用：
Adding 'glsl' to the method will escape the method to glsl and provide it to the shader for use:
Reference examples:
[:glsl Use Function](https://github.com/rainyt/openfl-glsl-samples/blob/main/Source/glsl/BitmapGLSL4.hx)
```haxe
@:glsl public function name(v:Vec2):Float{
	return v.x + v.y;
}
```

## @:uniform
在类中添加`@:uniform`变量，当需要提供参数时，需要通过`u_`+变量名组合赋值：
Add the ': uniform' variable to the class. When you need to provide parameters, you need to use the 'U'_`+ Variable name combination assignment:
```haxe
class Shader extends glsl.OpenFLShader {
	@:uniform public var time:Float;
	public function new(){
		super();
		this.u_time.value = [0];
	}
}
```

## @:varying
在类中添加`@:varying`变量，可以定义varying变量：
Add the `@:varying` variable to the class, you can define the varying variable:
```haxe
class Shader extends glsl.OpenFLShader {
	@:varying public var textureCoords:Vec2;
	override function vertex() {
		super.vertex();
		textureCoords = vec2(gl_openfl_Position.x, 0);
	}
	override function fragment() {
		super.fragment();
		gl_FragColor = vec4(textureCoords, 0, 1);
	}
}
```

## @:define
在指定的`fragment()`或者`vertex()`方法中，新增`@:define`可以对该着色器添加宏定义，他们之间定义的宏不会互相定义。
```haxe
@:define("VALUE 10.")
override public function fragment(){
	color.r = 10 / VALUE;
}
```
或者
```haxe
@:define("VALUE 10.")
override public function vertex(){
	color.r = 10 / VALUE;
}
```

## @:precision
`@:precision`允许用来定义precision：
```haxe
@:precision("highp float")
override public function fragment(){}
```