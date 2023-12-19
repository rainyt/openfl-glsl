package glsl.utils;

import glsl.macro.GLSLParser;
import haxe.macro.ExprTools;
import glsl.macro.GLSLExprTree;
import haxe.macro.Expr;

#if macro
class GLSLExprTools {
	/**
	 * GLSL解析器
	 */
	public static var currentGLSLParser:GLSLParser;

	public static function getExprType(expr:Expr, ?exprTree:GLSLExprTree):String {
		switch expr.expr {
			case EConst(c):
				switch c {
					case CInt(v, s):
						return "int";
					case CFloat(f, s):
						return "float";
					case CIdent(s):
						var field = currentGLSLParser.fieldsMap.get(s);
						if (field != null) return field.fieldType;
					default:
						throw "Don't support " + c.getName() + "type";
				}
			case ECall(e, params):
				var funName = ExprTools.toString(e);
				switch (funName) {
					case "vec2", "vec3", "vec4":
						return funName;
				}
			// case EArray(e1, e2):
			case EBinop(op, e1, e2):
				return getExprType(e1);
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
				// throw "Don't support " + expr.expr.getName() + " type";
				return null;
		}
		return null;
	}
}
#end
