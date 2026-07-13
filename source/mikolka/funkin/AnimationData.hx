package mikolka.funkin;

 typedef AnimationData =
 {
   > UnnamedAnimationData,
 
   var name:String;
 }
 
 typedef UnnamedAnimationData =
 {
   @:optional
   var prefix:String;
 
   @:optional
   var assetPath:Null<String>;
 
   @:default([0, 0])
   @:optional
   var offsets:Null<Array<Float>>;
 
   @:default(false)
   @:optional
   var looped:Bool;
 
   @:default(false)
   @:optional
   var flipX:Null<Bool>;
 
   @:default(false)
   @:optional
   var flipY:Null<Bool>;
 
   @:default(24)
   @:optional
   var frameRate:Null<Int>;
 
   @:default([])
   @:optional
   var frameIndices:Null<Array<Int>>;
 }