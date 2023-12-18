package;

import glsl.Sampler2D;
import glsl.GLSL.texture2D;
import VectorMath;

function float(a:Dynamic):Dynamic {
	return a;
}

/**
 * 使用Haxe转换为GLSL，通过fragmentSource和vertexSource进行访问
 */
@:debug
class Haxe2GLSL extends BaseGLSL {
	@:attribute public var a:Vec2;

	@:glsl
	public function circleCheck(i:Float):Float {
		return i;
	}

	@:glsl
	public function getAlpha() {
		return texture2D(gl_openfl_Texture, vec2(1, 1)).a;
	}

	@:define("TEXT 1")
	override public function fragment():Void {
		super.fragment();
		time++;
		--time;
		if (!(time > 10 || time < 30 && time != 0)) {
			this.gl_FragColor = vec4(float(TEXT), 1., 0., 1.);
		} else if (time == 0) {
			gl_FragColor = vec4(1, 1, 0.5, 1);
		} else {
			gl_FragColor = vec4(1, 1, 1, 1);
		}
		var w:Float = circleCheck(0);
		while (w < 100) {
			for (i in 0...10) {
				w++;
				w++;
				w++;
			}
			if (w == 5)
				break;
		}
		var v3 = vec4(1, 1, 1, 1);
		// Int
		var w2 = 1;
		// Float
		var w3 = 1.;
		w3 += abc + this.a.x + (time);
	}

	public function vertex():Void {
		this.gl_Position = vec4(1, 1, 1, 1);
	}
}

@:autoBuild(glsl.macro.GLSLCompileMacro.build("glsl"))
class BaseGLSL {
	@:uniform public var time:Float;

	@:uniform public var mouse:Vec2;

	@:uniform public var resolution:Vec2;

	@:glsl public var abc:Float;

	@:glsl public var b:Bool;

	@:glsl public var gl_openfl_Texture:Sampler2D;

	/**
	 * 最终值输出
	 */
	public var gl_FragColor:Vec4;

	/**
	 * 最终顶点坐标输出
	 */
	public var gl_Position:Vec4;

	public function fragment():Void {
		var color:Vec4 = vec4(1, 1, 1, 1);
	}
}
