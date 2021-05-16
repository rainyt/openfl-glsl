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
当前仅实现了`:glFragmentSource`的GLSL的编写支持。
