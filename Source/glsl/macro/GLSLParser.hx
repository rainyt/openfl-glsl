package glsl.macro;

import haxe.macro.TypeTools;
import haxe.macro.Type.Ref;
import haxe.macro.Type.ClassType;
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

	/**
	 * 父节点的解析
	 */
	public var parentParser:GLSLParser;

	/**
	 * 解析父节点的内容
	 * @param c 
	 */
	private function parserParentClass(c:Null<Ref<haxe.macro.ClassType>>):Void {
		// 父节点GLSL定义
		var parent = c.get().superClass;
		if (parent == null) {
			return;
		}
		var parentFields = parent.t.get().fields.get();
		var parentFieldList:Array<Field> = [];
		for (item in parentFields) {
			switch item.kind {
				case FVar(read, write):
					var type = TypeTools.toComplexType(item.type);
					parentFieldList.push({
						name: item.name,
						meta: item.meta.get(),
						doc: null,
						access: [APublic],
						kind: FVar(type),
						pos: item.pos
					});
				case FMethod(k):
					trace("这是个方法！");
			}
		}
		parentParser = new GLSLParser(parent.t, parentFieldList);
	}

	public function new(c:Null<Ref<haxe.macro.ClassType>>, list:Array<Field>) {
		// 解析父节点
		this.parserParentClass(c);
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
					pushGLSLField(f);
				}
			default:
		}
	}

	/**
	 * 追加GLSL的定义
	 * @param f 
	 */
	public function pushGLSLField(f:GLSLField):Void {
		switch f.glslFieldType {
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

	public function getGLSLField(name:String):GLSLField {
		if (this.fieldsMap.exists(name))
			return this.fieldsMap.get(name);
		if (parentParser != null) {
			return parentParser.getGLSLField(name);
		} else
			return null;
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
