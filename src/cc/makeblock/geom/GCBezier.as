package cc.makeblock.geom
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	public class GCBezier
	{
		private var count:int = 0;
		
		private var p1:Point;
		private var p2:Point;
		private var p3:Point;
		private var p4:Point;
		
		private var p0:Point = new Point(0,0);
		
		private var lineX:Number = 0;
		private var lineY:Number = 0;
		private var t:Number = 0;
		private var _points:Array = [];
		private var _lines:Array = [];
		private var _step:Number = 0.4;
		public function GCBezier():void
		{
		}
		public function start(a:Point,cpa:Point,cpb:Point,b:Point):void
		{
			p1 = a;
			p2 = cpa;
			p3 = cpb;
			p4 = b;
			t = 0;
			_points = [];
			_lines = [];
			generalPoints();
		}
		public function lines():Array{
			return _lines;
		}
		private function generalPoints():void
		{
			t +=  _step;
			
			//二次贝塞尔曲线公式
			//lineX = Math.pow((1-t),2)*p1.x+2*t*(1-t)*p2.x + Math.pow(t,2)*p3.x;
			//lineY = Math.pow((1-t),2)*p1.y+2*t*(1-t)*p2.y + Math.pow(t,2)*p3.y;
			
			//三次贝塞尔曲线公式
			lineX = Math.pow((1-t),3)*p1.x + 3*p2.x*t*(1-t)*(1-t) + 3*p3.x*t*t*(1-t) + p4.x *Math.pow(t,3);
			lineY = Math.pow((1-t),3)*p1.y + 3*p2.y*t*(1-t)*(1-t) + 3*p3.y*t*t*(1-t) + p4.y *Math.pow(t,3);
			
			_points.push(new Point(lineX, lineY));
			//        if (lineX > stage.stageWidth||lineX<0 || lineY<0||lineY>stage.stageHeight)
			if(t<=1)
			{
				generalPoints();
			}else{
				for(var i:uint=1;i<_points.length;i++){
					_lines.push([_points[i-1],_points[i]]);
				}
			}
		}
	}
}