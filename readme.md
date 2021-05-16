## OpenFL-GLSL
允许在OpenFL中直接使用Haxe编写GLSL编码，并在OpenFL中直接使用。
Allow Haxe to write GLSL code directly in OpenFL and use it directly in OpenFL.

### Test.hx:
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
Use:
```haxe
var bitmap = new Bitmap();
bitmap.shader = new Test();
```