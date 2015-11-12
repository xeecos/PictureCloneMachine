package com.powerflasher.as3potrace.backend
{
	import com.powerflasher.as3potrace.backend.IBackend;
	import com.powerflasher.as3potrace.geom.Curve;
	import com.powerflasher.as3potrace.geom.CurveKind;
	
	import flash.display.Shape;
	import flash.geom.Point;
	
	import cc.makeblock.geom.GCBezier;

	public class TraceBackend implements IBackend
	{
		public var list:Array = [];
		public var shape:Shape = new Shape;
		private var gcodeScale:Number = 1/5;
		private var workingSpeed:Number = 6000;
		private var w:uint = 320;
		
		private var xPos:Number = 45;
		private var yPos:Number = 5;
		public function init(width:int, height:int):void
		{
			list = [];
			removeTool();
			goHome();
			w = width;
			shape.graphics.lineStyle(1,0xffcc00,1);
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
			shape.graphics.moveTo(a.x*gcodeScale,a.y*gcodeScale);
			addTool();
			
		}

		public function addBezier(a:Point, cpa:Point, cpb:Point, b:Point):void
		{
			var bc:GCBezier = new GCBezier();
			bc.start(a,cpa,cpb,b);
			var lines:Array = bc.lines();
			for(var i:uint = 0;i<lines.length;i++){
				var p1:Point = lines[i][0];
				var p2:Point = lines[i][1];
				list.push("G1 X"+((w-p1.x-xPos)*gcodeScale)+" Y"+(p1.y*gcodeScale)+" A"+workingSpeed);
				shape.graphics.lineTo(p1.x*gcodeScale,p1.y*gcodeScale);
			}
			trace("      Bezier a:" + a + ", cpa:" + cpa + ", cpb:" + cpb + ", b:" + b);
			
		}
		public function addLine(a:Point, b:Point):void
		{
			trace("      Line a:" + a + ", b:" + b);
			if(a.x == 0||a.y==0||b.x==0||b.y==0){
				return;
			}
			shape.graphics.moveTo(a.x*gcodeScale,a.y*gcodeScale);
			shape.graphics.lineTo(b.x*gcodeScale,b.y*gcodeScale);
			list.push("G1 X"+((w-a.x-xPos)*gcodeScale)+" Y"+(a.y*gcodeScale)+" A"+workingSpeed);
			list.push("G1 X"+((w-b.x-xPos)*gcodeScale)+" Y"+(b.y*gcodeScale)+" A"+workingSpeed);
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
