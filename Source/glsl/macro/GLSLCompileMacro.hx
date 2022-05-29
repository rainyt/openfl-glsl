package glsl.macro;

import sys.FileSystem;
import sys.io.File;
import haxe.macro.Type.ClassField;
import glsl.utils.GLSLFormat;
#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

/**
 * 使用Haxe编写GLSL，编写时，请确保你使用的类都是GLSL所支持的，基础类由vector-math支持。
 * 在Haxe中，你可以正常使用：Array<T>、int、float、bool、vec2、vec3、vec4、mat2、mat3、mat4等。
 * Use Haxe to write GLSL. When writing, please make sure that the classes you use are supported by GLSL, and the basic classes are supported by vector-math.
 * In Haxe, you can use it normally: Array<T>, int, float, bool, vec2, vec3, vec4, mat2, mat3, mat4, etc.
 */
class GLSLCompileMacro {
	#if macro
	/**
	 * 数组使用量映射关系
	 */
	public static var arrayUid:Int;

	public static var arrayUidByName:Map<String, {
		id:Int,
		len:Int
	}>;

	/**
	 * uniform映射
	 */
	public static var uniform:Map<String, String>;

	/**
	 * varying映射
	 */
	public static var varying:Map<String, String>;

	/**
	 * attribute映射
	 */
	public static var attribute:Map<String, String>;

	/**
	 * vexter的define实现
	 */
	public static var vdefines:Array<String>;

	/**
	 * fragment的define实现
	 */
	public static var fdefines:Array<String>;

	/**
	 * glsl方法名映射关系
	 */
	public static var glslFuncs:Array<String>;

	/**
	 * 仅在vertex生效的glsl方法
	 */
	public static var vertexglslFuncs:Array<String>;

	/**
	 * 仅在fragment生效的glsl方法
	 */
	public static var fragmentFuncs:Array<String>;

	/**
	 * glsl通用变量定义
	 */
	public static var vars:Map<String, String>;

	/**
	 * glsl通用方法实现
	 */
	public static var maps:Map<String, String>;

	/**
	 * 历史上一次类型记录
	 */
	public static var lastType:String;

	/**
	 * 编译平台
	 */
	public static var platform:String;

	public static var shader:String;

	public static var fields:Array<Field>;

	public static var isDebug:Bool;

	/**
	 * 顶点着色器的头部属性是否仍然包含
	 */
	public static var vnoheader:Bool = false;

	/**
	 * 像素着色器的头部属性是否仍然包含
	 */
	public static var fnoheader:Bool = false;

	/**
	 * 是否输出，需要输出时，需要使用`-D output=./bin`定义输出目录
	 */
	public static var output:String;

	/**
	 * 自动编译buildShader
	 * @param platform 定义编译平台，目前支持openfl、glsl
	 * @return Array<Field>
	 */
	macro public static function build(platform:String = "openfl"):Array<Field> {
		GLSLCompileMacro.platform = platform;
		fields = Context.getBuildFields();
		output = Context.getDefines().get("output");
		shader = "\n";
		var pos:Position = Context.currentPos();
		isDebug = Context.getLocalClass().get().meta.has(":debug");
		var noShader = Context.getLocalClass().get().meta.has(":noshader");
		var info = Context.getPosInfos(pos);
		Context.registerModuleDependency(Context.getLocalModule(), info.file);
		if (noShader) {
			return fields;
		}
		vdefines = [];
		fdefines = [];
		glslFuncs = [];
		vertexglslFuncs = [];
		fragmentFuncs = [];
		vars = [];
		maps = [];
		arrayUid = 0;
		arrayUidByName = [];
		uniform = [];
		varying = [];
		attribute = [];

		// if (platform == "glsl") {
		// 允许继承父节点的着色器对象
		var localClass = Context.getLocalClass().get();
		var superClass = localClass.superClass != null ? localClass.superClass.t.get() : null;
		var parent = superClass;
		if (parent != null)
			parserGLSL(parent.fields.get(), false);
		// }
		parserGLSL(fields);

		// 创建new
		// var vertex = (vnoheader || platform == "glsl") ? "" : "#pragma header\n";
		// var fragment = (fnoheader || platform == "glsl") ? "" : "#pragma header\n";
		var vertex = (platform == "glsl") ? "" : "#pragma header\n";
		var fragment = (platform == "glsl") ? "" : "#pragma header\n";
		for (d in fdefines) {
			fragment += d;
		}
		for (d in vdefines) {
			vertex += d;
		}

		// attribute定义
		for (key => value in attribute) {
			vertex += value;
		}
		// uniform定义
		for (key => value in uniform) {
			// if (value.indexOf("sampler") == -1)
			if (vertexglslFuncs.length > 0)
				vertex += value;
			else {
				fragment += value;
			}
			// if (value.indexOf("mat") == -1)
			// fragment += value;
		}
		// varying定义
		for (key => value in varying) {
			vertex += value;
			fragment += value;
		}
		// var定义
		for (key => value in vars) {
			vertex += value;
			fragment += value;
		}
		// 方法定义
		for (index => value in glslFuncs) {
			vertex += maps.get(value);
			fragment += maps.get(value);
		}
		for (index => value in vertexglslFuncs) {
			vertex += maps.get(value);
		}
		for (index => value in fragmentFuncs) {
			fragment += maps.get(value);
		}
		fragment += maps.get("fragment");
		vertex += maps.get("vertex");

		// 数组长度转义
		for (key => value in arrayUidByName) {
			fragment = StringTools.replace(fragment, "$[" + value.id + "]", "[" + value.len + "]");
			vertex = StringTools.replace(vertex, "$[" + value.id + "]", "[" + value.len + "]");
		}

		// #pragma body
		fragment = StringTools.replace(fragment, "super.fragment();", "#pragma body");
		vertex = StringTools.replace(vertex, "super.vertex();", "#pragma body");

		// 格式化
		fragment = GLSLFormat.format(fragment);
		vertex = GLSLFormat.format(vertex);

		if (output != null) {
			if (!FileSystem.exists(output))
				FileSystem.createDirectory(output);
			if (maps.exists("fragment"))
				File.saveContent(output + "/" + Context.getLocalClass() + ".frag", fragment);
			if (maps.exists("vertex"))
				File.saveContent(output + "/" + Context.getLocalClass() + ".vert", vertex);
		}

		if (isDebug) {
			trace("class=", Context.getLocalClass());
			trace("uniform=" + uniform);
			trace("\nGLSL脚本：\n" + shader);
			if (maps.exists("fragment"))
				trace("fragment=\n" + fragment);
			if (maps.exists("vertex"))
				trace("vertex=\n" + vertex);
		}
		if (platform == "openfl") {
			var openflGLSource = [];
			if (maps.exists("fragment")) {
				openflGLSource.push({
					name: ":glFragmentSource",
					params: [macro $v{fragment}],
					pos: pos
				});
			}
			if (maps.exists("vertex")) {
				openflGLSource.push({
					name: ":glVertexSource",
					params: [macro $v{vertex}],
					pos: pos
				});
			}
			var newField = null;
			if (isDebug)
				trace("fields.length=", fields.length);
			for (f in fields) {
				if (f.name == "new") {
					newField = f;
					newField.meta = openflGLSource;
					break;
				}
			}
			if (newField == null) {
				newField = {
					name: "new",
					doc: null,
					meta: openflGLSource,
					access: [APublic],
					kind: FFun({
						args: [],
						ret: macro:Void,
						expr: macro {super();}
					}),
					pos: pos
				};
				fields.push(newField);
			}
		} else {
			// 纯Haxe转义GLSL
			if (maps.exists("fragment")) {
				fields.push({
					name: "fragmentSource",
					doc: null,
					meta: [],
					access: [APublic, AStatic],
					kind: FVar(macro:String, macro $v{fragment}),
					pos: pos
				});
			}
			if (maps.exists("vertex")) {
				fields.push({
					name: "vertexSource",
					doc: null,
					meta: [],
					access: [APublic, AStatic],
					kind: FVar(macro:String, macro $v{vertex}),
					pos: pos
				});
			}
		}
		if (isDebug)
			trace("编译结束");
		return fields;
	}

	public static function parserGLSL(fields:Array<Dynamic>, hasVertexFragment:Bool = true):Void {
		var pos:Position = Context.currentPos();
		for (field in fields) {
			if (field.meta.get != null) {
				var c:ClassField = cast field;
				// 不能调用expr，否则会引起Redefinition of variable time in subclass is not allowed. Previously declared at XXXX.XXXX的问题
				// var expr = field.expr();
				// var value = expr == null ? null : toExprValue(expr.expr);
				var expr = null;
				var value = null;
				var kind:ExprDef = field.kind;
				if (kind.getName() == "FVar") {
					parserGLSLField({
						name: field.name,
						doc: null,
						meta: field.meta.get(),
						access: [APublic],
						kind: expr == null ? FVar(field.type) : FVar(expr.t, macro $v{value}),
						pos: Context.currentPos()
					}, hasVertexFragment);
				}
			} else {
				parserGLSLField(field, hasVertexFragment);
			}
		}
	}

	/**
	 * 解析类里的每个定义：变量、方法
	 * @param field 
	 * @param hasVertexFragment 
	 */
	public static function parserGLSLField(field:Field, hasVertexFragment:Bool = true):Void {
		switch (field.kind.getName()) {
			case "FVar":
				// arrayLen支持，可定义数组的长度
				var arrayLen = 0;
				var isVarArrayLen = field.meta.filter(f -> f.name == ":arrayLen").length > 0;
				if (isVarArrayLen)
					arrayLen = Std.parseInt(toExprValue(field.meta.filter(f -> f.name == ":arrayLen")[0].params[0].expr));
				var isGLSLVar = field.meta.filter((f) -> f.name == ":glsl").length != 0;
				var isUniform = field.meta.filter(f -> f.name == ":uniform").length > 0;
				var isVarying = field.meta.filter(f -> f.name == ":varying").length > 0;
				var isAttribute = field.meta.filter(f -> f.name == ":attribute").length > 0;
				if (isUniform || isGLSLVar || isVarying || isAttribute) {
					// 变量定义
					var type:ExprDef = cast field.kind.getParameters()[0];
					var value = cast field.kind.getParameters()[1];
					var c = type == null ? toExprType(value.expr) : toExprType(type);
					var isArray = c.indexOf("$array") != -1;
					if (isArray)
						c = c.substr(0, c.lastIndexOf("$"));
					var varmap:Map<String, String> = isAttribute ? attribute : isVarying ? varying : isUniform ? uniform : vars;
					var vardefine = isAttribute ? "attribute" : isVarying ? "varying" : isUniform ? "uniform" : "";
					varmap.set(field.name,
						vardefine
						+ " "
						+ c
						+ (platform != "openfl" ? " " : (isUniform ? " u_" : isAttribute ? " a_" : " "))
						+ field.name
						+ (isArray ? (isVarArrayLen ? "[" + arrayLen + "]" : "$[" + arrayUid + "]") : ""));
					if (value != null) {
						varmap.set(field.name, varmap.get(field.name) + "=" + toExprValue(value.expr));
					}
					varmap.set(field.name, varmap.get(field.name) + ";\n");

					// 如果是数组，则需要定义数量
					if (isArray) {
						arrayUidByName.set(field.name, {
							id: arrayUid,
							len: 1
						});
						arrayUid++;
					}
					shader += uniform.get(field.name);
				}
			case "FFun":
				// 方法解析
				var isFragmentGLSLVar = field.meta.filter((f) -> f.name == ":fragmentglsl").length != 0;
				var isVertexGLSLVar = field.meta.filter((f) -> f.name == ":vertexglsl").length != 0;
				var isGLSLFunc = isFragmentGLSLVar || isVertexGLSLVar || field.meta.filter((f) -> f.name == ":glsl").length != 0;
				if (field.name != "vertex" && field.name != "fragment" && !isGLSLFunc)
					return;
				if (!hasVertexFragment || (field.name == "vertex" && field.name == "fragment"))
					return;
				if (isFragmentGLSLVar) {
					fragmentFuncs.push(field.name);
				} else if (isVertexGLSLVar) {
					vertexglslFuncs.push(field.name);
				} else if (isGLSLFunc) {
					glslFuncs.push(field.name);
				}
				maps.set(field.name, "");
				// 定义
				for (index => value in field.meta) {
					var line = null;
					switch (value.name) {
						case ":noheader":
							// 不包含头部，未完成
							if (field.name == "vertex") {
								vnoheader = true;
							} else if (field.name == "fragment") {
								fnoheader = true;
							}
						case ":precision":
							var expr:ExprDef = value.params[0].expr.getParameters()[0];
							line = "precision " + expr.getParameters()[0] + ";\n";
						case ":define":
							var expr:ExprDef = value.params[0].expr.getParameters()[0];
							var defineValue = expr.getParameters()[0];
							line = "#define " + defineValue + "\n";
							var newDefineField = {
								name: defineValue.substr(0, defineValue.indexOf(" ")),
								doc: null,
								meta: [],
								access: [APublic],
								kind: FVar(macro:Dynamic),
								pos: Context.currentPos()
							};
							fields.push(newDefineField);
					}
					if (line != null) {
						(field.name == "fragment" ? fdefines : vdefines).push(line);
						shader += line;
					}
				}
				var retType = toExprType(field.kind.getParameters()[0].ret);
				shader += "\n" + retType + " " + field.name + "(" + toExprArgs(field.kind.getParameters()[0].args) + "){\n";
				if (isGLSLFunc)
					maps.set(field.name,
						maps.get(field.name)
						+ "\n"
						+ retType
						+ " "
						+ field.name
						+ "("
						+ toExprArgs(field.kind.getParameters()[0].args)
						+ "){\n");
				else {
					if (platform == "glsl")
						maps.set(field.name, maps.get(field.name) + "\n void main(void){\n");
					else
						maps.set(field.name, maps.get(field.name) + "\n void main(void){\n");
				}
				var func:ExprDef = cast field.kind.getParameters()[0].expr.expr;
				var array:Array<Dynamic> = func.getParameters()[0];
				for (index => value in array) {
					var expr:ExprDef = cast value.expr;
					var line:String = "";
					switch (expr.getName()) {
						case "EField":
						// 已定义对象赋值
						case "EVars":
							// 定义局部变量
							var vars = expr.getParameters()[0];
							var varvalue = vars[0].expr;
							line += "\t" + (vars[0].type != null ? toExprType(vars[0].type) : toExprType(varvalue.expr)) + " " + vars[0].name;
							// trace(varvalue);
							if (varvalue != null) line += "=" + toExprValue(varvalue.expr);
						case "ECall":
							// 调用方法
							var value = toExprValue(expr);
							if (value.indexOf("null") != 0) line += "\t" + value;
						case "EBinop", "EIf", "EReturn", "EFor", "EConst", "EUnop", "EWhile":
							// 赋值
							line += "\t" + toExprValue(expr);
						default:
							throw "意外的运行符：" + expr.getName();
					}
					if (line != "") {
						switch (expr.getName()) {
							case "EIf", "EFor", "EWhile":
								maps.set(field.name, maps.get(field.name) + line + "\n");
								shader += line + "\n";
							default:
								maps.set(field.name, maps.get(field.name) + line + ";\n");
								shader += line + ";\n";
						}
					}
				}
				shader += "\n}\n";
				maps.set(field.name, maps.get(field.name) + "\n}\n");
		}
	}

	/**
	 * 解析Args参数
	 * @param array 
	 * @return String
	 */
	public static function toExprArgs(array:Array<Dynamic>):String {
		var rets = [];
		for (index => value in array) {
			rets.push(toExprType(value.type) + " " + value.name);
		}
		return rets.join(",");
	}

	/**
	 * 解析Expr的层级类型
	 * @return String
	 */
	public static function toExprType(expr:ExprDef):String {
		if (expr == null)
			return "void";
		var ret = "#invalidType#";
		var type = expr.getName();
		lastType = null;
		switch (type) {
			case "TLazy":
				throw "子类型不能默认赋值(Subtype cannot be assigned by default)";
			case "TAbstract":
				var type = Std.string(expr.getParameters()[0]);
				lastType = type;
				return lastType.charAt(0).toLowerCase() + lastType.substr(1);
			case "TPType":
				expr = expr.getParameters()[0];
				lastType = expr.getParameters()[0].name;
				return lastType.charAt(0).toLowerCase() + lastType.substr(1);
			case "ENew", "TPath":
				lastType = expr.getParameters()[0].name;
				if (lastType == "Array") {
					// 数组转换GLSL
					lastType = toExprType(expr.getParameters()[0].params[0]) + "$array";
				}
				return lastType.charAt(0).toLowerCase() + lastType.substr(1);
			case "EConst":
				expr = expr.getParameters()[0];
				lastType = expr.getName().substr(1);
				return lastType.charAt(0).toLowerCase() + lastType.substr(1);
			default:
				throw "无法使用" + type + "建立类型关系" + expr;
		}
		return ret;
	}

	/**
	 * 解析Expr的层级内容
	 * @param expr 
	 * @return String
	 */
	public static function toExprValue(expr:ExprDef, args:Array<Dynamic> = null):String {
		var ret = "#invalidValue#";
		var type = expr.getName();
		switch (type) {
			case "EBreak":
				return "break";
			case "OpEq":
				return "==";
			case "EWhile":
				return "while(" + toExprValue(expr.getParameters()[0].expr) + "){\n" + toExprValue(expr.getParameters()[1].expr) + "\n}";
			case "TFunction":
				return expr.getParameters()[0];
			case "TConst":
				expr = expr.getParameters()[0];
				return expr.getParameters()[0];
			case "OpUShr":
				return ">>>";
			case "OpMod":
				return "%";
			case "OpShl":
				return "<<";
			case "OpShr":
				return ">>";
			case "OpXor":
				return "^";
			case "OpAnd":
				return "&";
			case "OpOr":
				return "|";
			case "OpBoolAnd":
				return " && ";
			case "OpNotEq":
				return "!=";
			case "OpBoolOr":
				return " || ";
			case "OpSub":
				return "-";
			case "OpGt":
				return ">";
			case "OpGte":
				return ">=";
			case "OpLt":
				return "<";
			case "OpLte":
				return "<=";
			case "OpAssignOp":
				return toExprValue(expr.getParameters()[0]) + "=";
			case "OpAssign":
				return "=";
			case "OpAdd":
				return "+";
			case "OpDiv":
				return "/";
			case "OpMult":
				return "*";
			case "OpInterval":
				return "...";
			case "OpIn":
				return "in";
			case "OpNot":
				return "!";
			case "OpIncrement":
				return "++";
			case "OpDecrement":
				return "--";
			case "OpNeg":
				return "-";
			case "ETernary":
				return "(" + toExprValue(expr.getParameters()[0].expr) + ")?" + toExprValue(expr.getParameters()[1].expr) + ":"
					+ toExprValue(expr.getParameters()[2].expr);
			case "EUnop":
				var bool = expr.getParameters()[1];
				if (!bool)
					return toExprValue(expr.getParameters()[0]) + toExprValue(expr.getParameters()[2].expr);
				else
					return toExprValue(expr.getParameters()[2].expr) + toExprValue(expr.getParameters()[0]);
			case "EParenthesis":
				return "(" + toExprValue(expr.getParameters()[0].expr) + ")";
			case "EVars":
				// 定义局部变量
				var ret = "";
				var vars = expr.getParameters()[0];
				var varvalue = vars[0].expr;
				ret += "\t" + (vars[0].type != null ? toExprType(vars[0].type) : toExprType(varvalue.expr)) + " " + vars[0].name;
				if (varvalue != null)
					return ret + "=" + toExprValue(varvalue.expr);
			case "EArrayDecl":
				var array:Array<Expr> = expr.getParameters()[0];
				var t = lastType;
				return StringTools.replace(t, "$array", "") + "[](" + toExprListValue(array) + ")";
			case "EArray":
				lastType = "int";
				var toarray = toExprValue(expr.getParameters()[0].expr);
				var getIndex = toExprValue(expr.getParameters()[1].expr);
				var value:Dynamic = Std.parseInt(getIndex);
				if (value == null)
					value = getIndex;
				if (arrayUidByName.exists(toarray)) {
					var obj = arrayUidByName.get(toarray);
					if (obj.len <= value)
						obj.len = value + 1;
				}
				return toarray + "[" + value + "]";
			case "EBlock":
				var ret = "";
				var array:Array<Dynamic> = expr.getParameters()[0];
				for (index => value in array) {
					var e:ExprDef = value.expr;
					switch (e.getName()) {
						case "EIf", "EFor", "EWhile":
							ret += toExprValue(value.expr) + "\n";
						default:
							ret += toExprValue(value.expr) + ";\n";
					}
				}
				return ret;
			case "EFor":
				// For
				var it:ExprDef = expr.getParameters()[0].expr;
				var content:ExprDef = expr.getParameters()[1].expr;
				lastType = "int";
				var attr = toExprValue(it.getParameters()[1].expr);
				var it2:ExprDef = it.getParameters()[2].expr;
				var start = toExprValue(it2.getParameters()[1].expr);
				var end = toExprValue(it2.getParameters()[2].expr);
				return "for(int " + attr + " = " + start + ";" + attr + "<" + end + ";" + attr + "++){\n" + toExprValue(content) + "\n}";
			case "EReturn":
				return "return " + toExprValue(expr.getParameters()[0].expr);
			case "ECast":
				return toExprValue(expr.getParameters()[0].expr);
			case "EIf":
				var data = "";
				var ifcontent = toExprValue(expr.getParameters()[0].expr);
				var content = toExprValue(expr.getParameters()[1].expr);
				var existEnd = content.lastIndexOf(";\n") == content.length - 2 || content.lastIndexOf("}\n") == content.length - 2;
				var elsecontent = expr.getParameters()[2];
				if (ifcontent != null) {
					data += (args != null ? args[0] : "if") + "(" + ifcontent + "){\n" + content + (existEnd ? "\n}" : ";\n}");
				}
				if (elsecontent != null) {
					content = toExprValue(elsecontent.expr);
					existEnd = content.lastIndexOf(";\n") == content.length - 2 || content.lastIndexOf("}\n") == content.length - 2;
					if (content.indexOf("if") != -1) {
						data += "else {\n" + content + "\n}";
					} else
						data += "else{\n" + content + (existEnd ? "\n}" : ";\n}");
				}
				return data;
			case "EField":
				var value = toExprValue(expr.getParameters()[0].expr);
				if (attribute.exists(value) && platform == "openfl")
					value = "a_" + value;
				if (uniform.exists(value) && platform == "openfl")
					value = "u_" + value;
				if (isDebug)
					trace(value, attribute.get(value));
				if (value == "this") {
					value = expr.getParameters()[1];
					if (value.indexOf("gl_openfl") == 0 || value.indexOf("gl_bitmap") == 0)
						value = value.substr(3);
					return value;
				}
				if (value.indexOf("gl_openfl") == 0 || value.indexOf("gl_bitmap") == 0)
					value = value.substr(3);
				var ret = value + "." + expr.getParameters()[1];
				if (ret.indexOf("super") == 0)
					return "super." + expr.getParameters()[1];
				return ret;
			case "EBinop":
				var value1 = toExprValue(expr.getParameters()[1].expr);
				var value2 = toExprValue(expr.getParameters()[2].expr);
				var binop = toExprValue(expr.getParameters()[0]);
				return value1 + binop + value2;
			case "ECall":
				var callName = toExprValue(expr.getParameters()[0].expr);
				var args = expr.getParameters()[1];
				switch (callName) {
					case "asVec2", "asVec4", "asVec3":
						return toExprListValue(args);
					case "atan2":
						callName = "atan";
				}
				return callName + "(" + toExprListValue(args) + ")";
			case "ENew":
				var ctype = toExprType(expr);
				return ctype + "(" + toExprListValue(expr.getParameters()[1]) + ")";
			case "EConst":
				expr = expr.getParameters()[0];
				var value:Dynamic = expr.getParameters()[0];
				var ctype = expr.getName();
				if (Std.isOfType(value, String)) {
					if (attribute.exists(value) && platform == "openfl")
						value = "a_" + value;
					if (uniform.exists(value) && platform == "openfl")
						value = "u_" + value;
					if (value.indexOf("gl_openfl") == 0 || value.indexOf("gl_bitmap") == 0)
						value = value.substr(3);
					if ((ctype == "CInt" || ctype == "CFloat" || ctype == "CString")
						&& lastType != null
						&& lastType.toLowerCase() != "int"
						&& value.indexOf(".") == -1) {
						value = value + ".";
					}
				}
				return value;
			default:
				throw "无法使用" + type + "建立值";
		}
		return ret;
	}

	/**
	 * [Description]
	 * @param Array<Dynamic> 
	 * @return String
	 */
	public static function toExprListValue(array:Array<Dynamic>):String {
		var ret:Array<String> = [];
		for (index => value in array) {
			ret.push(toExprValue(value.expr));
		}
		return ret.join(",");
	}
	#end
}
