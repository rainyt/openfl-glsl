package glsl.macro;

import haxe.macro.TypeTools;
import haxe.macro.Context;
import haxe.macro.Expr.Field;

#if macro
/**
 * 使用Haxe编写GLSL，编写时，请确保你使用的类都是GLSL所支持的，基础类由vector-math支持。
 * 在Haxe中，你可以正常使用：Array<T>、int、float、bool、vec2、vec3、vec4、mat2、mat3、mat4等。
 * Use Haxe to write GLSL. When writing, please make sure that the classes you use are supported by GLSL, and the basic classes are supported by vector-math.
 * In Haxe, you can use it normally: Array<T>, int, float, bool, vec2, vec3, vec4, mat2, mat3, mat4, etc.
 */
class GLSLCompileMacro {
	/**
	 * 构造GLSL代码
	 * @param mode 
	 * @return Array<Field>
	 */
	public static function build(mode:String):Array<Field> {
		

		var list = Context.getBuildFields();
		var glslFields = new GLSLParser(Context.getLocalClass(), list);
		var vertex = glslFields.getVertexGLSLCode();
		var fragment = glslFields.getFragmentGLSLCode();
		trace("vertex=", vertex);
		trace("fragment=", fragment);
		return list;
	}
}
#end
