package glsl.macro;

import haxe.macro.Expr.Field;

#if macro
class GLSLParser {
	/**
	 * 所有定义
	 */
	public var fields:Array<GLSLField> = [];

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

	public function new(list:Array<Field>) {
		for (item in list) {
			switch item.kind {
				case FVar(t, e):
					// 参数定义 @:uniform @:varying @:attribute
					this.pushField(item);
				case FFun(f):
					// 方法定义 @:fragmentglsl @:vertexglsl
					// 默认方法名 vertex fragment
					this.pushMethod(item);
				case FProp(get, set, t, e):
					// 不支持
			}
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
					switch fieldType {
						case UNIFORM:
							uniforms.push(new GLSLField(fieldType, field));
						case VARYING:
							uniforms.push(new GLSLField(fieldType, field));
						case ATTRIBUTE:
							uniforms.push(new GLSLField(fieldType, field));
						case NONE:
					}
					fields.push(new GLSLField(fieldType, field));
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
					glsls.push(new GLSLCode(field.name, field));
				}
			case FProp(get, set, t, e):
		}
	}

	/**
	 * 
	 */
	public function getVertexGLSLCode():String {
		return "";
	}

	/**
	 * @return String
	 */
	public function getFragmentGLSLCode():String {
		return "";
	}
}
#end
