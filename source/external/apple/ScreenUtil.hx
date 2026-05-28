package external.apple;

class ScreenUtil {
	public static function getSafeAreaInsets(top:cpp.Pointer<Float>, bottom:cpp.Pointer<Float>, left:cpp.Pointer<Float>, right:cpp.Pointer<Float>):Void {
		if (top != null) top[0] = 0;
		if (bottom != null) bottom[0] = 0;
		if (left != null) left[0] = 0;
		if (right != null) right[0] = 0;
	}

	public static function getScreenSize(width:cpp.Pointer<Float>, height:cpp.Pointer<Float>):Void {
		if (width != null) width[0] = 1280;
		if (height != null) height[0] = 720;
	}
}