package glsl.macro;

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
	 * 历史上一次类型记录
	 */
	public static var lastType:String;

	/**
	 * 自动编译buildShader
	 * @param platform 定义编译平台，目前支持openfl、glsl
	 * @return Array<Field>
	 */
	#if macro
	macro public static function build(platform:String = "openfl"):Array<Field> {
		var pos:Position = Context.currentPos();
		var fields = Context.getBuildFields();
		var isDebug = Context.getLocalClass().get().meta.has(":debug");
		var noShader = Context.getLocalClass().get().meta.has(":noshader");
		var info = Context.getPosInfos(pos);
		Context.registerModuleDependency(Context.getLocalModule(), info.file);
		if (noShader) {
			return fields;
		}
		var shader = "\n";
		var vdefines:Array<String> = [];
		var fdefines:Array<String> = [];
		var glslFuncs:Array<String> = [];
		var vars:Map<String, String> = [];
		var maps:Map<String, String> = [];
		arrayUid = 0;
		arrayUidByName = [];
		uniform = [];
		varying = [];
		for (field in fields) {
			switch (field.kind.getName()) {
				case "FVar":
					var isGLSLVar = field.meta.filter((f) -> f.name == ":glsl").length != 0;
					var isUniform = field.meta.filter(f -> f.name == ":uniform").length > 0;
					var isVarying = field.meta.filter(f -> f.name == ":varying").length > 0;
					if (isUniform || isGLSLVar || isVarying) {
						// 变量定义
						var type:ExprDef = cast field.kind.getParameters()[0];
						var value = cast field.kind.getParameters()[1];
						var c = type == null ? toExprType(value.expr) : toExprType(type);
						var isArray = c.indexOf("$array") != -1;
						if (isArray)
							c = c.substr(0, c.lastIndexOf("$"));
						if (isVarying) {
							if (value == null) {
								varying.set(field.name, "varying " + c + " " + field.name + (isArray ? "$[" + arrayUid + "]" : "") + ";\n");
							} else {
								varying.set(field.name,
									"varying "
									+ c
									+ " "
									+ field.name
									+ (isArray ? "$[" + arrayUid + "]" : "")
									+ "="
									+ toExprValue(value.expr)
									+ ";\n");
							}
						} else if (isUniform) {
							if (value == null) {
								uniform.set(field.name, "uniform " + c + " u_" + field.name + (isArray ? "$[" + arrayUid + "]" : "") + ";\n");
							} else {
								uniform.set(field.name,
									"uniform "
									+ c
									+ " u_"
									+ field.name
									+ (isArray ? "$[" + arrayUid + "]" : "")
									+ "="
									+ toExprValue(value.expr)
									+ ";\n");
							}
						} else {
							if (value == null) {
								vars.set(field.name, c + " " + field.name + (isArray ? "$[" + arrayUid + "]" : "") + ";\n");
							} else {
								vars.set(field.name, c + " " + field.name + (isArray ? "$[" + arrayUid + "]" : "") + "=" + toExprValue(value.expr) + ";\n");
							}
						}
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
					var isGLSLFunc = field.meta.filter((f) -> f.name == ":glsl").length != 0;
					if (field.name != "vertex" && field.name != "fragment" && !isGLSLFunc)
						continue;
					if (isGLSLFunc) {
						glslFuncs.push(field.name);
					}
					maps.set(field.name, "");
					// 定义
					for (index => value in field.meta) {
						var line = null;
						switch (value.name) {
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
									pos: pos
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
							+ "){");
					else
						maps.set(field.name, maps.get(field.name) + "\n void main(void){#pragma body\n");
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
								line += "  " + (vars[0].type != null ? toExprType(vars[0].type) : toExprType(varvalue.expr)) + " " + vars[0].name;
								// trace(varvalue);
								if (varvalue != null) line += "=" + toExprValue(varvalue.expr);
							case "ECall":
								// 调用方法
								var value = toExprValue(expr);
								if (value.indexOf("null") != 0) line += "  " + value;
							case "EBinop":
								// 赋值
								line += "  " + toExprValue(expr);
							case "EIf":
								// If判断
								line += "  " + toExprValue(expr);
							case "EReturn":
								// return
								line = "  " + toExprValue(expr);
							case "EFor":
								// for
								line = "  " + toExprValue(expr);
							case "EConst":
								line = "  " + toExprValue(expr);
							default:
								throw "意外的运行符：" + expr.getName();
						}
						if (line != "") {
							maps.set(field.name, maps.get(field.name) + line + ";\n");
							shader += line + ";\n";
						}
					}
					shader += "\n}\n";
					maps.set(field.name, maps.get(field.name) + "\n}\n");
			}
		}
		// 创建new
		var vertex = "#pragma header\n";
		var fragment = "#pragma header\n";
		for (d in fdefines) {
			fragment += d;
		}
		for (d in vdefines) {
			vertex += d;
		}
		// 方法定义
		for (index => value in glslFuncs) {
			vertex += maps.get(value);
			fragment += maps.get(value);
		}
		// uniform定义
		for (key => value in uniform) {
			vertex += value;
			fragment += value;
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
		fragment += maps.get("fragment");
		vertex += maps.get("vertex");

		// 数组长度转义
		for (key => value in arrayUidByName) {
			fragment = StringTools.replace(fragment, "$[" + value.id + "]", "[" + value.len + "]");
			vertex = StringTools.replace(vertex, "$[" + value.id + "]", "[" + value.len + "]");
		}

		if (isDebug) {
			trace("class=", Context.getLocalClass());
			trace("uniform=" + uniform);
			trace("\nGLSL脚本：\n" + shader);
			trace("fragment=\n" + fragment);
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
					access: [APublic,AStatic],
					kind: FVar(macro:String,macro $v{fragment}),
					pos: pos
				});
			}
			if (maps.exists("vertex")) {
				fields.push({
					name: "vertexSource",
					doc: null,
					meta: [],
					access: [APublic,AStatic],
					kind: FVar(macro:String,macro $v{vertex}),
					pos: pos
				});
			}
		}
		return fields;
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
			case "TPType":
				expr = expr.getParameters()[0];
				return expr.getParameters()[0].name;
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
				throw "无法使用" + type + "建立类型关系";
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
			case "OpSub":
				return "-";
			case "OpGt":
				return ">";
			case "OpLt":
				return "<";
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
			case "EParenthesis":
				return "(" + toExprValue(expr.getParameters()[0].expr) + ")";
			case "EVars":
				// 定义局部变量
				var ret = "";
				var vars = expr.getParameters()[0];
				var varvalue = vars[0].expr;
				ret += "  " + (vars[0].type != null ? toExprType(vars[0].type) : toExprType(varvalue.expr)) + " " + vars[0].name;
				if (varvalue != null)
					return ret + "=" + toExprValue(varvalue.expr);
			case "EArray":
				lastType = "int";
				var toarray = toExprValue(expr.getParameters()[0].expr);
				var value = Std.parseInt(toExprValue(expr.getParameters()[1].expr));
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
					ret += toExprValue(value.expr) + ";\n";
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
				var elsecontent = expr.getParameters()[2];
				if (ifcontent != null) {
					data += (args != null ? args[0] : "if") + "(" + ifcontent + "){" + content + ";}";
				}
				if (elsecontent != null) {
					data += "else{" + toExprValue(elsecontent.expr, ["elseif"]) + ";}";
				}
				return data;
			case "EField":
				var value = toExprValue(expr.getParameters()[0].expr);
				if (uniform.exists(value))
					value = "u_" + value;
				if (value == "this") {
					value = expr.getParameters()[1];
					if (value.indexOf("gl_openfl") == 0)
						value = value.substr(3);
					return value;
				}
				if (value.indexOf("gl_openfl") == 0)
					value = value.substr(3);
				var ret = value + "." + expr.getParameters()[1];
				if (ret.indexOf("super") == 0)
					return null;
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
					if (uniform.exists(value))
						value = "u_" + value;
					if (value.indexOf("gl_openfl") == 0)
						value = value.substr(3);
					if ((ctype == "CInt" || ctype == "CFloat") && lastType != null && lastType != "int" && value.indexOf(".") == -1) {
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