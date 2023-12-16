package glsl.macro;

import haxe.macro.Expr.Field;

#if macro
class GLSLCode {
	public function new(methodName:String, field:Field) {
		switch field.kind {
			case FFun(f):
			default:
		}
	}
}
#end
