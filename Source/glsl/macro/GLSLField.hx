package glsl.macro;

import haxe.macro.ComplexTypeTools;
import haxe.macro.Expr.Field;

#if macro
class GLSLField {
	/**
	 * 代入值
	 */
	private var __field:Field;

	/**
	 * GLSL变量定义名
	 */
	private var fieldName:String;

	/**
	 * GLSL变量定义类型
	 */
	private var fieldType:String;

	/**
	 * GLSL变量定义类型
	 */
	public var glslFieldType:GLSLFieldType;

	public function new(type:GLSLFieldType, field:Field) {
		__field = field;
		this.glslFieldType = type;
		fieldName = field.name;
		switch glslFieldType {
			case UNIFORM:
				fieldName = "u_" + fieldName;
			case VARYING:
			case ATTRIBUTE:
				fieldName = "a_" + fieldName;
			case NONE:
		}
		switch field.kind {
			case FVar(t, e):
				// TODO e参数可以作为默认值实现，待支持
				var typeName = ComplexTypeTools.toString(t);
				fieldType = typeName;
			default:
				throw "Don't support FFun FProp";
		}
	}

	public function getGLSLCode():String {
		return fieldType.toLowerCase() + " " + fieldName + ";";
	}
}
#end
