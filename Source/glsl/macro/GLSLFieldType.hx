package glsl.macro;

/**
 * GLSL变量定义类型
 */
enum abstract GLSLFieldType(Int) {
	var UNIFORM;
	var VARYING;
	var ATTRIBUTE;
	var NONE;
}
