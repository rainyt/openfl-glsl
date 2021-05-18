package glsl.utils;

/**
 * GLSL语法格式化
 */
class GLSLFormat {
	private static inline var __s:String = "  ";

	public static function format(source:String):String {
		var list = source.split("\n");
		var s:Int = 0;
		for (index => value in list) {
			var cat = 0;
			for (i in 0...value.length) {
				if (value.charAt(i) != " ") {
					cat = i;
					break;
				}
			}
			var startAdd = false;
			if (value.indexOf("}") != -1)
				s--;
			if (value.indexOf("{") != -1) {
				startAdd = true;
				s++;
			}
			value = value.substr(cat);
			list[index] = value;
			for (i in 0...(s - (startAdd ? 1 : 0))) {
				list[index] = __s + list[index];
			}
		}
		return list.join("\n");
	}
}
