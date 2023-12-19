package glsl.macro;

import glsl.utils.GLSLExprTools;
import haxe.macro.Expr;

class GLSLExprTree {
	public var expr:Expr;

	public var parentTree:GLSLExprTree;

	public function new(expr:Expr) {
		this.expr = expr;
	}

	public function addChild(expr:Expr):GLSLExprTree {
		var child = new GLSLExprTree(expr);
		child.parentTree = this;
		return child;
	}

	/**
	 * 是否为浮点树结构
	 * @return Bool
	 */
	public function isFloatTree():Bool {
		if (parentTree != null) {
			switch parentTree.expr.expr {
				case EConst(c):
					switch c {
						case CInt(v, s):
						case CFloat(f, s):
						case CString(s, kind):
						case CIdent(s):
						case CRegexp(r, opt):
					}
				case EArray(e1, e2):
				case EBinop(op, e1, e2):
					switch op {
						case OpDiv:
							return true;
						default:
							var type = GLSLExprTools.getExprType(e1);
							switch (type) {
								case "float":
									return true;
							}
					}
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
				case EFor(it, expr):
				case EIf(econd, eif, eelse):
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
			return parentTree.isFloatTree();
		}
		return false;
	}
}
