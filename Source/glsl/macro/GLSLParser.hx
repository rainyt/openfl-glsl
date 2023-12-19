package glsl.macro;

import glsl.utils.GLSLExprTools;
import haxe.macro.TypedExprTools;
import haxe.macro.TypeTools;
import haxe.macro.Type.Ref;
import haxe.macro.Type.ClassType;
import haxe.macro.Expr.Field;

#if macro
class GLSLParser {
	/**
	 * 编译平台
	 */
	public var platfrom:String = "openfl";

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
					// TODO 应该需要支持解析父节点的方法语法
					// trace("这是个方法！", TypedExprTools.toString(item.expr()));
			}
		}
		parentParser = new GLSLParser(parent.t, parentFieldList);
	}

	public function new(c:Null<Ref<haxe.macro.ClassType>>, list:Array<Field>) {
		// 绑定当前节点
		GLSLExprTools.currentGLSLParser = this;
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
				if (field.name == "vertex" || field.name == "fragment" || metas.contains(":glsl") || metas.contains(":vertexglsl")
					|| metas.contains(":fragmentglsl")) {
					var glsl = new GLSLCode(field.name, field, this);
					glsls.push(glsl);
					glslsMap.set(glsl.name, glsl);
				}
			case FProp(get, set, t, e):
		}
	}

	/**
	 * 获得vertex已编译好的代码
	 */
	public function getVertexGLSLCode():String {
		var code = glslsMap.get("vertex");
		if (code == null)
			return null;
		var codes = platfrom == "openfl" ? ["#pragma header"] : [];
		for (field in uniforms) {
			codes.push(field.getGLSLCode());
		}
		for (glsl in glsls) {
			if (glsl.name != "vertex" && glsl.name != "fragment")
				codes.push(glsl.getGLSLCode());
		}
		codes.push(code.getGLSLCode());
		var vertex = codes.join("\n");
		vertex = StringTools.replace(vertex, "super.vertex();", "#pragma body");
		return vertex;
	}

	/**
	 * 获得Framgemnt已编译好的代码
	 * @return String
	 */
	public function getFragmentGLSLCode():String {
		var code = glslsMap.get("fragment");
		if (code == null)
			return null;
		var codes = platfrom == "openfl" ? ["#pragma header"] : [];
		for (field in uniforms) {
			codes.push(field.getGLSLCode());
		}
		for (glsl in glsls) {
			if (glsl.name != "vertex" && glsl.name != "fragment")
				codes.push(glsl.getGLSLCode());
		}
		codes.push(code.getGLSLCode());
		var fragment = codes.join("\n");
		fragment = StringTools.replace(fragment, "super.fragment();", "#pragma body");
		return fragment;
	}
}
#end
