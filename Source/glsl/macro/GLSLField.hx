package glsl.macro;

import haxe.macro.Context;
import haxe.macro.Expr.Field;

#if macro
class GLSLField {
	/**
	 * 代入值
	 */
	private var __field:Field;

	/**
	 * 新增的变量定义
	 */
	public var exprField:Field;

	/**
	 * GLSL变量定义类型
	 */
	public var glslFieldType:GLSLFieldType;

	public function new(type:GLSLFieldType, field:Field) {
		__field = field;
		this.glslFieldType = type;
		var fieldName = field.name;
		switch glslFieldType {
			case UNIFORM:
				fieldName = "u_" + fieldName;
			case VARYING:
			case ATTRIBUTE:
				fieldName = "a_" + fieldName;
			case NONE:
		}
		exprField = {
			name: fieldName,
			access: [APublic],
			kind: field.kind,
			pos: Context.currentPos()
		};
	}
}
#end
