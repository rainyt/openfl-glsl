package glsl.macro;

import glsl.utils.GLSLFormat;
import haxe.macro.ExprTools;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;

#if macro
class GLSLCode {
	/**
	 * 已编译的GLSL代码
	 */
	public var glslCode:String;

	/**
	 * GLSL中定义的参数
	 */
	public var defines:Array<GLSLDefine> = [];

	public var name:String;

	public function new(methodName:String, field:Field) {
		this.name = methodName;
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

	public function parserCodeExpr(expr:Expr, ?custom:Dynamic):String {
		if (expr == null)
			return null;
		switch expr.expr {
			case EConst(c):
				switch c {
					case CInt(v, s):
						switch (custom) {
							case "vec2", "vec3", "vec4":
								return v + ".";
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
				var objectKey = ExprTools.toString(e);
				if (objectKey == "this") {
					return field;
				} else {
					return '$objectKey.$field';
				}
			case EParenthesis(e):
			case EObjectDecl(fields):
			case EArrayDecl(values):
			case ECall(e, params):
				var funcKey = parserCodeExpr(e);
				var array = params.map(f -> parserCodeExpr(f, funcKey));
				return '$funcKey(${array.join(", ")})';
			case ENew(t, params):
			case EUnop(op, postFix, e):
			case EVars(vars):
				trace(vars);
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
				return 'for(${parserCodeExpr(it)}) {
					${parserCodeExpr(expr)}
				}';
			case EIf(econd, eif, null):
				return 'if(${parserCodeExpr(econd)}){
					${parserCodeExpr(eif)}
				}';
			case EIf(econd, eif, eelse):
				return 'if(${parserCodeExpr(econd)})
					${parserCodeExpr(eif)}
				else ${parserCodeExpr(eelse)}';
			case EWhile(econd, e1, true):
				return 'while (${parserCodeExpr(econd)})${parserCodeExpr(e1)}';
			case EWhile(econd, e1, false):
				return 'do 
					${parserCodeExpr(e1)}
				  while (${parserCodeExpr(econd)})';
			case ESwitch(e, cases, edef):
			case ETry(e, catches):
			case EReturn(e):
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
}
#end
