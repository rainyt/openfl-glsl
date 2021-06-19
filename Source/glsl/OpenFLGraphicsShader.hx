package glsl;

#if zygame
import zygame.core.Start;
#end
#if openfl
import openfl.display.GraphicsShader;

@:autoBuild(glsl.macro.GLSLCompileMacro.build())
class OpenFLGraphicsShader extends GraphicsShader #if zygame implements zygame.core.Refresher #end {
	/** 
	 * 纹理UV
	 */
	public var gl_openfl_TextureCoordv:Vec2;

	/**
	 * 颜色偏移
	 */
	public var gl_openfl_ColorOffsetv:Vec4;

	/**
	 * 颜色相乘
	 */
	public var gl_openfl_ColorMultiplierv:Vec4;

	/**
	 * 是否存在颜色转换
	 */
	public var gl_openfl_HasColorTransform:Bool;

	/**
	 * 纹理尺寸
	 */
	public var gl_openfl_TextureSize:Vec2;

	/**
	 * 纹理对象
	 */
	public var gl_bitmap:Sampler2D;

	/**
	 * 当前纹理透明度
	 */
	public var gl_openfl_Alphav:Float;

	/**
	 * 
	 */
	public var gl_openfl_Matrix:Mat4;

	/**
	 * 顶点参数
	 */
	public var gl_openfl_Position:Vec4;

	/**
	 * 最终值输出
	 */
	public var gl_FragColor:Vec4;

	/**
	 * gl_FragCoord，舞台的像素比，单位为px
	 */
	public var gl_FragCoord:Vec4;

	/**
	 * 最终顶点坐标输出
	 */
	public var gl_Position:Vec4;

	/**
	 * 当前着色器获得到的颜色
	 */
	public var color:Vec4;

	/**
	 * 片段着色器，需要Fragment时，请重写这个
	 */
	public function fragment():Void {}

	/**
	 * 顶点着色器，需要时，请重写这个
	 */
	public function vertex():Void {}

	#if !zygame
	private var __intervalId:Int = -1;
	#end

	public function new() {
		super();
	}

	public function setFrameEvent(bool:Bool):Void {
		#if zygame
		if (bool)
			Start.current.addToUpdate(this);
		else
			Start.current.removeToUpdate(this);
		#else
		// Use OpenFL Event.EVENT_FRAME
		if (__intervalId != -1)
			openfl.Lib.clearInterval(__intervalId);
		if (bool)
			__intervalId = openfl.Lib.setInterval(onFrame, 0);
		#end
	}

	/**
	 * 释放当前着色器
	 */
	public function dispose():Void {
		#if zygame
		Start.current.removeToUpdate(this);
		#else
		if (__intervalId != -1)
			openfl.Lib.clearInterval(__intervalId);
		__intervalId = -1;
		#end
	}

	public function onFrame():Void {}
}
#end
