package cc.makeblock.geom
{
	import flash.geom.Point;

	public class Grid extends Object
	{
		public var gid:uint;
		private var _data:Array = [];
		public function Grid()
		{
		}
		public function push(point:Point):void{
			_data.push(point);
		}
		public function get enabled():Boolean{
			for(var i:uint=0;i<4;i++){
				if(_data[i]!=null){
					return true;
				}
			}
			return false;
		}
		public function position():Point{
			var pos:Point = new Point;
			var count:uint = 0;
			for(var i:uint=0;i<4;i++){
				var point:Point = _data[i];
				if(point){
					count++;
					pos.x+=point.x;
					pos.y+=point.y;
				}
			}
			return new Point(pos.x/count,pos.y/count);
		}
	}
}