package glsl.macro;

import haxe.macro.Expr.Field;

#if macro
class GLSLParser {
	/**
	 * 所有定义
	 */
	public var fields:Array<GLSLField> = [];

	/**
	 * 所有定义，可通过名字访问
	 */
	public var fieldsMap:Map<String, GLSLField> = [];

	/**
	 * uniform定义
	 */
	public var uniforms:Array<GLSLField> = [];

	/**
	 * varying定义
	 */
	public var varyings:Array<GLSLField> = [];

	/**
	 * attribute定义
	 */
	public var attributes:Array<GLSLField> = [];

	/**
	 * GLSL代码
	 */
	public var glsls:Array<GLSLCode> = [];

	/**
	 * GLSL代码Map映射
	 */
	public var glslsMap:Map<String, GLSLCode> = [];

	public function new(list:Array<Field>) {
		for (item in list) {
			switch item.kind {
				case FVar(t, e):
					// 参数定义 @:uniform @:varying @:attribute
					this.pushField(item);
				case FFun(f):
				case FProp(get, set, t, e):
					// 不支持
			}
		}
		for (item in list) {
			switch item.kind {
				case FVar(t, e):
				case FFun(f):
					// 方法定义 @:fragmentglsl @:vertexglsl
					this.pushMethod(item);
				case FProp(get, set, t, e):
					// 不支持
			}
		}
		// 开始将属性追加到定义中
		for (code in glsls) {
			for (define in code.defines) {
				list.push(define.getField());
			}
			glslsMap.set(code.name, code);
		}
	}

	/**
	 * 追加定义
	 * @param field 
	 */
	public function pushField(field:Field):Void {
		switch field.kind {
			case FVar(t, e):
				var metas = field.meta.map(f -> f.name);
				var fieldType:GLSLFieldType = {
					if (metas.contains(":uniform") || metas.contains(":u"))
						UNIFORM;
					else if (metas.contains(":varying") || metas.contains(":v"))
						VARYING;
					else if (metas.contains(":attribute") || metas.contains(":a"))
						ATTRIBUTE;
					else
						NONE;
				};
				if (fieldType != NONE) {
					var f = new GLSLField(fieldType, field);
					switch fieldType {
						case UNIFORM:
							uniforms.push(f);
						case VARYING:
							uniforms.push(f);
						case ATTRIBUTE:
							uniforms.push(f);
						case NONE:
					}
					fields.push(f);
					fieldsMap.set(f.name, f);
				}
			default:
		}
	}

	public function pushMethod(field:Field):Void {
		switch field.kind {
			case FVar(t, e):
			case FFun(f):
				var metas = field.meta.map(f -> f.name);
				if (field.name == "vertex" || field.name == "fragment") {
					glsls.push(new GLSLCode(field.name, field, this));
				}
			case FProp(get, set, t, e):
		}
	}

	/**
	 * 获得vertex已编译好的代码
	 */
	public function getVertexGLSLCode():String {
		return "void main(void)" + glslsMap.get("vertex").glslCode;
	}

	/**
	 * 获得Framgemnt已编译好的代码
	 * @return String
	 */
	public function getFragmentGLSLCode():String {
		return "void main(void)" + glslsMap.get("fragment").glslCode;
	}
}
#end
