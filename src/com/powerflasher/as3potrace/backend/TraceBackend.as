package com.powerflasher.as3potrace.backend
{
	import com.powerflasher.as3potrace.backend.IBackend;
	
	import flash.geom.Point;

	public class TraceBackend implements IBackend
	{
		public var list:Array = [];
		
		private var gcodeScale:Number = 1/3.3;
		private var workingSpeed:Number = 6000;
		private var w:uint = 320;
		
		private var xPos:Number = 180;
		private var yPos:Number = 0;
		public function init(width:int, height:int):void
		{
			list = [];
			removeTool();
			goHome();
			w = width;
			trace("Canvas width:" + width + ", height:" + height);
		}

		public function initShape():void
		{
			trace("  Shape");
		}
		
		public function initSubShape(positive:Boolean):void
		{
			trace("    SubShape positive:" + positive);
		}
		
		public function moveTo(a:Point):void
		{
			trace("      MoveTo a:" + a);
			
			if(a.x == 0||a.y==0){
				return;
			}
			removeTool();
			list.push("G1 X"+((w-a.x-xPos)*gcodeScale)+" Y"+(a.y*gcodeScale)+" A1000");
			addTool();
			
		}

		public function addBezier(a:Point, cpa:Point, cpb:Point, b:Point):void
		{
			trace("      Bezier a:" + a + ", cpa:" + cpa + ", cpb:" + cpb + ", b:" + b);
			list.push("G1 X"+((w-a.x-xPos)*gcodeScale)+" Y"+(a.y*gcodeScale)+" A"+workingSpeed);
		}

		public function addLine(a:Point, b:Point):void
		{
			trace("      Line a:" + a + ", b:" + b);
			if(a.x == 0||a.y==0||b.x==0||b.y==0){
				return;
			}
			list.push("G1 X"+((w-a.x-xPos)*gcodeScale)+" Y"+(a.y*gcodeScale)+" A"+workingSpeed);
			list.push("G1 X"+((w-a.x-xPos)*gcodeScale)+" Y"+(a.y*gcodeScale)+" A"+workingSpeed);
		}

		public function exitSubShape():void
		{
			removeTool();
		}
		
		public function exitShape():void
		{
			removeTool();
		}
		
		public function exit():void
		{
			removeTool();
			goHome();
		}
		private function addTool():void{
			list.push("M3 P160");
		}
		private function removeTool():void{
			list.push("M3 P0");
		}
		private function goHome():void{
			list.push("G28");
		}
	}
}
