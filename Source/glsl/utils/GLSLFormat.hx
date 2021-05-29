package glsl.utils;

/**
 * GLSL语法格式化
 */
class GLSLFormat {
	private static inline var __s:String = "\t";

	public static function format(source:String):String {
		var list = source.split("\n");
		var s:Int = 0;
		for (index => value in list) {
			var cat = 0;
			for (i in 0...value.length) {
				if (value.charAt(i) != "\t" && value.charAt(i) != " ") {
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
			value = formatLine(value.substr(cat));
			list[index] = value;
			if (value != "")
				for (i in 0...(s - (startAdd ? 1 : 0))) {
					list[index] = __s + list[index];
				}
		}
		return list.filter((k) -> {
			return k != "";
		}).join("\n");
	}

	private static var _kkeys:String = "!*=-/+?:><,";

	private static var _rightigones:String = _kkeys + ")};";

	private static function formatLine(line:String):String {
		var ret:Array<String> = [];
		var lastStr = "";
		for (i in 0...line.length) {
			var c = line.charAt(i);
			if (i == 0)
				ret.push(c);
			else if (_kkeys.indexOf(c) != -1 && _kkeys.indexOf(lastStr) == -1 && lastStr != " " && c != ",") {
				ret.push(" ");
				ret.push(c);
			} else if (_kkeys.indexOf(lastStr) != -1 && _rightigones.indexOf(c) == -1 && c != " ") {
				ret.push(" ");
				ret.push(c);
			} else {
				ret.push(c);
			}
			lastStr = c;
		}
		return ret.join("");
	}
}
