package cc.makeblock.geom
{
	import flash.geom.Point;

	public class Line
	{
		public var p1:Point;
		public var p2:Point;
		public function Line(p1:Point,p2:Point)
		{
			this.p1 = p1;
			this.p2 = p2;
		}
		public function hasPoint(p:Point):Boolean{
			if(p1.x==p.x&&p1.y==p.y){
				return true;
			}
			if(p2.x==p.x&&p2.y==p.y){
				return true;
			}
			return false;
		}
		public function isEqual(l:Line):Boolean{
			if((p1.x==l.p1.x&&p1.y==l.p1.y&&p2.x==l.p2.x&&p2.y==l.p2.y)||(p1.x==l.p2.x&&p1.y==l.p2.y&&p2.x==l.p1.x&&p2.y==l.p1.y)){
				return true;
			}
			return false;
		}
		public function get distance():Number{
			return Point.distance(p1,p2);
		}
	}
}