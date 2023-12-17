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
	 * 原变量名
	 */
	public var name:String;

	/**
	 * GLSL变量定义名
	 */
	public var fieldName:String;

	/**
	 * GLSL变量定义类型
	 */
	public var fieldType:String;

	/**
	 * GLSL变量定义类型
	 */
	public var glslFieldType:GLSLFieldType;

	public function new(type:GLSLFieldType, field:Field) {
		__field = field;
		this.glslFieldType = type;
		fieldName = field.name;
		name = field.name;
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
				if (typeName == "StdTypes.Float") {
					fieldType = "float";
				} else
					fieldType = typeName;
			default:
				throw "Don't support FFun FProp";
		}
	}

	public function getGLSLCode():String {
		switch this.glslFieldType {
			case UNIFORM:
				return "uniform " + fieldType.toLowerCase() + " " + fieldName + ";";
			case VARYING:
				return "varying " + fieldType.toLowerCase() + " " + fieldName + ";";
			case ATTRIBUTE:
				return "attribute " + fieldType.toLowerCase() + " " + fieldName + ";";
			case NONE:
				return fieldType.toLowerCase() + " " + fieldName + ";";
		}
	}
}
#end
