package glsl.macro;

import haxe.macro.ComplexTypeTools;
import glsl.utils.GLSLFormat;
import haxe.macro.ExprTools;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;

#if macro
class GLSLCode implements IGLSL {
	/**
	 * 已编译的GLSL代码
	 */
	private var glslCode:String;

	/**
	 * GLSL中定义的参数
	 */
	public var defines:Array<GLSLDefine> = [];

	/**
	 * 已使用的变量定义
	 */
	public var useVars:Map<String, IGLSL> = [];

	/**
	 * 方法名
	 */
	public var name:String;

	/**
	 * 原始定义
	 */
	public var rootField:Field;

	private var __parser:GLSLParser;

	public function new(methodName:String, field:Field, parser:GLSLParser) {
		this.name = methodName;
		this.__parser = parser;
		this.rootField = field;
		switch field.kind {
			case FFun(f):
				for (item in field.meta.iterator()) {
					switch (item.name) {
						case ":define", ":d":
							// 定义
							var d = new GLSLDefine();
							d.parserDefine(ExprTools.getValue(item.params[0]));
							defines.push(d);
					}
				}
				glslCode = parserCodeExpr(f.expr);
				glslCode = GLSLFormat.format(glslCode);
			default:
		}
	}

	private function __getGLSLField(key:String):GLSLField {
		var f = __parser.getGLSLField(key);
		if (f != null) {
			this.useVars.set(f.name, f);
		}
		return f;
	}

	private function __formatField(field:String):String {
		if (field.indexOf("gl_openfl_") == 0) {
			return StringTools.replace(field, "gl_openfl_", "openfl_");
		}
		return field;
	}

	public function parserCodeExpr(expr:Expr, ?custom:Dynamic):String {
		if (expr == null)
			return null;
		switch expr.expr {
			case EConst(c):
				switch c {
					case CInt(v, s):
						switch (custom) {
							case "vec2", "vec3", "vec4", "float":
								return v + ".";
							default:
								if (custom != null) {
									var call = __parser.glslsMap.get(custom);
									if (call != null) {
										switch call.rootField.kind {
											case FFun(f):
											// trace("参数：", f.args);
											default:
										}
									}
								}
						}
					case CIdent(s):
						var field = __getGLSLField(s);
						if (field != null) {
							return field.fieldName;
						} else {
							return __formatField(s);
						}
					default:
				}
			case EArray(e1, e2):
			case EBinop(op, e1, e2):
				switch op {
					case OpAdd:
						return '${parserCodeExpr(e1)}+${parserCodeExpr(e2)}';
					case OpMult:
						return '${parserCodeExpr(e1)}*${parserCodeExpr(e2)}';
					case OpDiv:
						return '${parserCodeExpr(e1)}/${parserCodeExpr(e2)}';
					case OpSub:
						return '${parserCodeExpr(e1)}-${parserCodeExpr(e2)}';
					case OpAssign:
						return '${parserCodeExpr(e1)}=${parserCodeExpr(e2)}';
					case OpEq:
						return '${parserCodeExpr(e1)}==${parserCodeExpr(e2)}';
					case OpNotEq:
						return '${parserCodeExpr(e1)}!=${parserCodeExpr(e2)}';
					case OpGt:
						return '${parserCodeExpr(e1)}>${parserCodeExpr(e2)}';
					case OpGte:
						return '${parserCodeExpr(e1)}>=${parserCodeExpr(e2)}';
					case OpLt:
						return '${parserCodeExpr(e1)}<${parserCodeExpr(e2)}';
					case OpLte:
						return '${parserCodeExpr(e1)}<=${parserCodeExpr(e2)}';
					case OpAnd:
					case OpOr:
					case OpXor:
					case OpBoolAnd:
						return '${parserCodeExpr(e1)} && ${parserCodeExpr(e2)}';
					case OpBoolOr:
						return '${parserCodeExpr(e1)} || ${parserCodeExpr(e2)}';
					case OpShl:
					case OpShr:
					case OpUShr:
					case OpMod:
						return '${parserCodeExpr(e1)}%${parserCodeExpr(e2)}';
					case OpAssignOp(op):
						switch op {
							case OpAdd:
								return '${parserCodeExpr(e1)}+=${parserCodeExpr(e2)}';
							case OpMult:
								return '${parserCodeExpr(e1)}*=${parserCodeExpr(e2)}';
							case OpDiv:
								return '${parserCodeExpr(e1)}/=${parserCodeExpr(e2)}';
							case OpSub:
								return '${parserCodeExpr(e1)}-=${parserCodeExpr(e2)}';
							default:
						}
					case OpInterval:
						return '= ${parserCodeExpr(e1)}; $custom < ${parserCodeExpr(e2)}; $custom++';
					case OpArrow:
					case OpIn:
						var varid = parserCodeExpr(e1);
						return 'int ${varid} ${parserCodeExpr(e2, varid)}';
					case OpNullCoal:
				}
			case EField(e, field, kind):
				var objectKey = parserCodeExpr(e);
				if (objectKey == "super") {
					// TODO 父方法，这里需要将父节点的代码合并进来
					// return field;
				} else if (objectKey == "this") {
					return __formatField(field);
				} else {
					var glslField = __getGLSLField(objectKey);
					if (glslField != null) {
						return '${glslField.fieldName}.${__formatField(field)}';
					}
					return '$objectKey.$field';
				}
			case EParenthesis(e):
				return '(${parserCodeExpr(e)})';
			case EObjectDecl(fields):
			case EArrayDecl(values):
			case ECall(e, params):
				var funcKey = parserCodeExpr(e);
				var array = params.map(f -> parserCodeExpr(f, funcKey));
				return '$funcKey(${array.join(", ")})';
			case ENew(t, params):
			case EUnop(op, postFix, e):
			case EVars(vars):
				var codes = [];
				for (item in vars) {
					var type = item.type != null ? getComplexType(item.type) : getExprType(item.expr);
					if (item.expr != null)
						codes.push('${type} ${item.name} = ${parserCodeExpr(item.expr)}');
					else
						codes.push('${type} ${item.name}');
				}
				return codes.join("\n");
			case EFunction(kind, f):
			case EBlock(exprs):
				var codes = [];
				for (item in exprs) {
					switch item.expr {
						case EBlock(exprs):
							codes.push(parserCodeExpr(item));
						case EFor(it, expr):
							codes.push(parserCodeExpr(item));
						case EIf(econd, eif, eelse):
							codes.push(parserCodeExpr(item));
						case EWhile(econd, e, normalWhile):
							codes.push(parserCodeExpr(item));
						case ESwitch(e, cases, edef):
							codes.push(parserCodeExpr(item));
						default:
							codes.push(parserCodeExpr(item) + ";");
					}
				}
				return '{
					${codes.join("\n")}
				}';
			case EFor(it, expr):
				return 'for(${parserCodeExpr(it)}) ${parserCodeExpr(expr)}${semicolon(expr)}';
			case EIf(econd, eif, null):
				return 'if(${parserCodeExpr(econd)}) ${parserCodeExpr(eif)}${semicolon(eif)}';
			case EIf(econd, eif, eelse):
				return 'if(${parserCodeExpr(econd)})
					${parserCodeExpr(eif)}${semicolon(eif)}
				else ${parserCodeExpr(eelse)}${semicolon(eelse)}';
			case EWhile(econd, e1, true):
				return 'while (${parserCodeExpr(econd)})${parserCodeExpr(e1)}${semicolon(e1)}';
			case EWhile(econd, e1, false):
				return 'do 
					${parserCodeExpr(e1)}${semicolon(e1)}
				  while (${parserCodeExpr(econd)})';
			case ESwitch(e, cases, edef):
			case ETry(e, catches):
			case EReturn(e):
				return 'return ${parserCodeExpr(e)}';
			case EBreak:
			case EContinue:
			case EUntyped(e):
			case EThrow(e):
			case ECast(e, t):
			case EDisplay(e, displayKind):
			case ETernary(econd, eif, eelse):
			case ECheckType(e, t):
			case EMeta(s, e):
			case EIs(e, t):
		}
		return #if false'(${expr.expr.getName()})' + #end
		ExprTools.toString(expr);
	}

	private function semicolon(expr:Expr):String {
		if (expr.expr.getName() == "EBlock") {
			return "";
		}
		return ";";
	}

	public function getComplexType(type:ComplexType):String {
		if (type == null)
			return "void";
		var t = ComplexTypeTools.toString(type);
		return t.toLowerCase();
	}

	public function getExprType(expr:Expr):String {
		switch expr.expr {
			case EConst(c):
				switch c {
					case CInt(v, s):
						return "int";
					case CFloat(f, s):
						return "float";
					default:
						throw "Don't support " + c.getName() + "type";
				}
			case ECall(e, params):
				var funName = parserCodeExpr(e);
				switch (funName) {
					case "vec2", "vec3", "vec4":
						return funName;
				}
			// case EArray(e1, e2):
			// case EBinop(op, e1, e2):
			// case EField(e, field, kind):
			// case EParenthesis(e):
			// case EObjectDecl(fields):
			// case EArrayDecl(values):
			// case ENew(t, params):
			// case EUnop(op, postFix, e):
			// case EVars(vars):
			// case EFunction(kind, f):
			// case EBlock(exprs):
			// case EFor(it, expr):
			// case EIf(econd, eif, eelse):
			// case EWhile(econd, e, normalWhile):
			// case ESwitch(e, cases, edef):
			// case ETry(e, catches):
			// case EReturn(e):
			// case EBreak:
			// case EContinue:
			// case EUntyped(e):
			// case EThrow(e):
			// case ECast(e, t):
			// case EDisplay(e, displayKind):
			// case ETernary(econd, eif, eelse):
			// case ECheckType(e, t):
			// case EMeta(s, e):
			// case EIs(e, t):
			default:
				throw "Don't support " + expr.expr.getName() + " type";
		}
		return "???";
	}

	public function getGLSLCode():String {
		var code = [];
		switch __parser.platfrom {
			case "openfl":
				if (this.name == "vexter" || this.name == "fragment")
					return code.concat(["\nvoid main(void)" + glslCode]).join("\n");
				else {
					var params = [];
					var ret:Null<ComplexType> = null;
					switch this.rootField.kind {
						case FFun(f):
							ret = f.ret;
							for (item in f.args) {
								params.push('${getComplexType(item.type)} ${item.name}');
							}
						default:
					}
					return code.concat([
						"\n" + getComplexType(ret) + " " + this.name + "(" + params.join(", ") + ")" + glslCode
					]).join("\n");
				}
			default:
				return code.concat(["\nvoid " + this.name + "(void)" + glslCode]).join("\n");
		}
	}
}
#end
