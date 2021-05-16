## OpenFL-GLSL
允许在OpenFL中直接使用Haxe编写GLSL编码，并在OpenFL中直接使用。
Allow Haxe to write GLSL code directly in OpenFL and use it directly in OpenFL.

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
- 当前仅实现了`:glFragmentSource`的GLSL的编写支持。
- 需要依赖[vector-math](https://github.com/haxiomic/vector-math)

## :debug
在Class上添加`:debug`可以将转义后的GLSL输出：
Add `:debug` to class to output escaped glsl:
```haxe
@:debug
class Shader extends glsl.OpenFLShader {}
```
通过`haxe build.hxml`编译后会自动输出。
After compiling through 'haxe build. Hxml', it will output automatically.

## :glsl
在方法中添加`:glsl`则会将方法转义成GLSL，并提供给着色器使用：
Adding 'glsl' to the method will escape the method to glsl and provide it to the shader for use:
Reference examples:
[:glsl Use Function](https://github.com/rainyt/openfl-glsl-samples/blob/main/Source/glsl/BitmapGLSL4.hx)
```haxe
@:glsl public function name(v:Vec2):Float{
	return v.x + v.y;
}
```