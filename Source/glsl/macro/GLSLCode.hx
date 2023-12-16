package glsl.macro;

import haxe.macro.ExprTools;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;

#if macro
class GLSLCode {
	public var codes:Array<String> = [];

	public function new(methodName:String, field:Field) {
		switch field.kind {
			case FFun(f):
				var code = parserCodeExpr(f.expr);
				trace("code=", code);
			default:
		}
	}

	public function parserCodeExpr(expr:Expr):String {
		if (expr == null)
			return null;
		switch expr.expr {
			case EConst(c):
				switch c {
					case CInt(v, s):
						return '[$v,$s]';
					case CFloat(f, s):
					case CString(s, kind):
					case CIdent(s):
					case CRegexp(r, opt):
				}
			case EArray(e1, e2):
			case EBinop(op, e1, e2):
			case EField(e, field, kind):
			case EParenthesis(e):
			case EObjectDecl(fields):
			case EArrayDecl(values):
			case ECall(e, params):
			case ENew(t, params):
			case EUnop(op, postFix, e):
			case EVars(vars):
			case EFunction(kind, f):
			case EBlock(exprs):
				var codes = [];
				for (item in exprs) {
					codes.push(parserCodeExpr(item));
				}
				return codes.join("\n");
			case EFor(it, expr):
			case EIf(econd, eif, eelse):
                var codes = [];
				var code1 = 'if(${parserCodeExpr(econd)})';
				var code2 = parserCodeExpr(eif);
				var code3 = parserCodeExpr(eelse);
			// trace(code1, code2, code3);
			// return code1 + "," + code2 + "," + code3;
			case EWhile(econd, e, normalWhile):
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
		return '(${expr.expr.getName()})' + ExprTools.toString(expr);
	}
}
#end
