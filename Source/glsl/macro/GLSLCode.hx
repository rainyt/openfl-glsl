package glsl.macro;

import glsl.utils.GLSLExprTools;
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
				glslCode = parserCodeExpr(f.expr, null);
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

	public function parserCodeExpr(expr:Expr, exprTree:GLSLExprTree, ?custom:String):String {
		if (expr == null)
			return null;
		if (exprTree == null)
			exprTree = new GLSLExprTree(expr);
		exprTree = exprTree.addChild(expr);
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
								} else if (exprTree != null) {
									// 查找父节点是否为浮点，如果是浮点，则为Int添加浮点支持
									if (exprTree.isFloatTree())
										return v + ".";
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
						return '${parserCodeExpr(e1, exprTree)}+${parserCodeExpr(e2, exprTree)}';
					case OpMult:
						return '${parserCodeExpr(e1, exprTree)}*${parserCodeExpr(e2, exprTree)}';
					case OpDiv:
						return '${parserCodeExpr(e1, exprTree)}/${parserCodeExpr(e2, exprTree)}';
					case OpSub:
						return '${parserCodeExpr(e1, exprTree)}-${parserCodeExpr(e2, exprTree)}';
					case OpAssign:
						return '${parserCodeExpr(e1, exprTree)}=${parserCodeExpr(e2, exprTree)}';
					case OpEq:
						return '${parserCodeExpr(e1, exprTree)}==${parserCodeExpr(e2, exprTree)}';
					case OpNotEq:
						return '${parserCodeExpr(e1, exprTree)}!=${parserCodeExpr(e2, exprTree)}';
					case OpGt:
						return '${parserCodeExpr(e1, exprTree)}>${parserCodeExpr(e2, exprTree)}';
					case OpGte:
						return '${parserCodeExpr(e1, exprTree)}>=${parserCodeExpr(e2, exprTree)}';
					case OpLt:
						return '${parserCodeExpr(e1, exprTree)}<${parserCodeExpr(e2, exprTree)}';
					case OpLte:
						return '${parserCodeExpr(e1, exprTree)}<=${parserCodeExpr(e2, exprTree)}';
					case OpAnd:
					case OpOr:
					case OpXor:
					case OpBoolAnd:
						return '${parserCodeExpr(e1, exprTree)} && ${parserCodeExpr(e2, exprTree)}';
					case OpBoolOr:
						return '${parserCodeExpr(e1, exprTree)} || ${parserCodeExpr(e2, exprTree)}';
					case OpShl:
					case OpShr:
					case OpUShr:
					case OpMod:
						return '${parserCodeExpr(e1, exprTree)}%${parserCodeExpr(e2, exprTree)}';
					case OpAssignOp(op):
						switch op {
							case OpAdd:
								return '${parserCodeExpr(e1, exprTree)}+=${parserCodeExpr(e2, exprTree)}';
							case OpMult:
								return '${parserCodeExpr(e1, exprTree)}*=${parserCodeExpr(e2, exprTree)}';
							case OpDiv:
								return '${parserCodeExpr(e1, exprTree)}/=${parserCodeExpr(e2, exprTree)}';
							case OpSub:
								return '${parserCodeExpr(e1, exprTree)}-=${parserCodeExpr(e2, exprTree)}';
							default:
						}
					case OpInterval:
						return '= ${parserCodeExpr(e1, exprTree)}; $custom < ${parserCodeExpr(e2, exprTree)}; $custom++';
					case OpArrow:
					case OpIn:
						var varid = parserCodeExpr(e1, exprTree);
						return 'int ${varid} ${parserCodeExpr(e2, exprTree, varid)}';
					case OpNullCoal:
				}
			case EField(e, field, kind):
				var objectKey = parserCodeExpr(e, exprTree);
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
				return '(${parserCodeExpr(e, exprTree)})';
			case EObjectDecl(fields):
			case EArrayDecl(values):
			case ECall(e, params):
				var funcKey = parserCodeExpr(e, exprTree);
				var array = params.map(f -> parserCodeExpr(f, exprTree, funcKey));
				return '$funcKey(${array.join(", ")})';
			case ENew(t, params):
			case EUnop(op, postFix, e):
			case EVars(vars):
				var codes = [];
				for (item in vars) {
					var type = item.type != null ? getComplexType(item.type) : GLSLExprTools.getExprType(item.expr);
					if (item.expr != null)
						codes.push('${type} ${item.name} = ${parserCodeExpr(item.expr, exprTree)}');
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
							codes.push(parserCodeExpr(item, exprTree));
						case EFor(it, expr):
							codes.push(parserCodeExpr(item, exprTree));
						case EIf(econd, eif, eelse):
							codes.push(parserCodeExpr(item, exprTree));
						case EWhile(econd, e, normalWhile):
							codes.push(parserCodeExpr(item, exprTree));
						case ESwitch(e, cases, edef):
							codes.push(parserCodeExpr(item, exprTree));
						default:
							codes.push(parserCodeExpr(item, exprTree) + ";");
					}
				}
				return '{
					${codes.join("\n")}
				}';
			case EFor(it, expr):
				return 'for(${parserCodeExpr(it, exprTree)}) ${parserCodeExpr(expr, exprTree)}${semicolon(expr)}';
			case EIf(econd, eif, null):
				return 'if(${parserCodeExpr(econd, exprTree)}) ${parserCodeExpr(eif, exprTree)}${semicolon(eif)}';
			case EIf(econd, eif, eelse):
				return 'if(${parserCodeExpr(econd, exprTree)})
					${parserCodeExpr(eif, exprTree)}${semicolon(eif)}
				else ${parserCodeExpr(eelse, exprTree)}${semicolon(eelse)}';
			case EWhile(econd, e1, true):
				return 'while (${parserCodeExpr(econd, exprTree)})${parserCodeExpr(e1, exprTree)}${semicolon(e1)}';
			case EWhile(econd, e1, false):
				return 'do 
					${parserCodeExpr(e1, exprTree)}${semicolon(e1)}
				  while (${parserCodeExpr(econd, exprTree)})';
			case ESwitch(e, cases, edef):
			case ETry(e, catches):
			case EReturn(e):
				return 'return ${parserCodeExpr(e, exprTree)}';
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
