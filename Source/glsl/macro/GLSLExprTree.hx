package glsl.macro;

import haxe.macro.Expr;

class GLSLExprTree {
	public var expr:Expr;

	public var parentExpr:Expr;

	public function new(expr:Expr) {
		this.expr = expr;
	}

	public function addChild(expr:Expr):GLSLExprTree {
		var child = new GLSLExprTree(expr);
		child.parentExpr = expr;
		return child;
	}
}
