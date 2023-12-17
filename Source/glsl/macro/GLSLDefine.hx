package glsl.macro;

import haxe.macro.Context;
import haxe.macro.Expr.Field;

#if macro
class GLSLDefine {
	private var __code:String;

	public var name:String;

	public var value:Dynamic;

	public function new() {}

	public function parserDefine(defineValue:String):Void {
		__code = defineValue;
		var array = defineValue.split(" ");
		this.name = array[0];
		this.value = array[1];
	}

	public function getField():Field {
		return {
			name: name,
			doc: __code,
			kind: FVar(macro :Dynamic),
			pos: Context.currentPos()
		}
	}
}
#end
