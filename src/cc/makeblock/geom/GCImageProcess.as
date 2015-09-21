package cc.makeblock.geom
{
	import flash.display.BitmapData;
	import flash.geom.Rectangle;

	public class GCImageProcess
	{
		private var _width:uint = 0;
		private var _height:uint = 0;
		private var _matrix:Array = [];
		private var _rect:Rectangle;
		public function GCImageProcess(width:uint,height:uint)
		{
			_width  = width
			_height = height;
			_matrix = [];
			_rect = new Rectangle(0,0,_width,_height);
		}
		public function get matrix():Array{
			return _matrix;
		}
		public function assign(i:uint,j:uint,val:Number):void{
			_matrix[i][j] = val;
		}
		public function fromImage(bmd:BitmapData,format:Boolean=false):void{
			_matrix = []
			var i:uint,j:uint;
			var pix:uint;
			if (format){
				var him:uint,wim:uint = bmd.width;
				for( i=0;i<wim;i++){
					api();
					for(j=0;j<him;j++){
						pix = bmd.getPixel(j,i);
						apj(i,pix);
					}
				}
			}else{
				him = bmd.width;
				wim = bmd.height;
				for(i=0;i<wim;i++){
					api();
					for(j=0;j<him;j++){
						pix = gray(bmd.getPixel(j,i));
						apj(i,pix);
					}
				}
				_width  = wim
				_height = him
				_rect.width = wim;
				_rect.height = him;
				//_t_offset = 0;
			}
		}
		
		public function padWZeros(tool:Rectangle):void{
			var ts:uint = tool.width
			for(var i:uint = _matrix.length;i<_width+ts;i++){
				api();
			}
			
			for(i=0;i<_matrix.length;i++){
				for(var j:uint=_matrix[i].length;j<_height+ts;j++){
					apj(i,-0xffffff);
				}
			}
		}
		private function heightCalc(x:uint,y:uint,tool:Rectangle):Number{
			var ts:Number = tool.width;
			var d:Number = -0xffffff
			var ilow:int  = (int)(x-(ts-1)/2)
			var ihigh:int = (int)(x+(ts-1)/2+1)
			var jlow:int  = (int)(y-(ts-1)/2)
			var jhigh:int = (int)(y+(ts-1)/2+1)
			
			var icnt:int = 0
			for(var i:int=ilow;i<ihigh;i++){
				var jcnt:int = 0
				for(var j:int=jlow;j<jhigh;j++){
					d = Math.max( d, _matrix[j][i] - 0);//tool(jcnt,icnt))
					jcnt = jcnt+1 
				}
				icnt = icnt+1
			}
			return d
		}
		public function min():Number{
			var minval:Number = 0xffffff;
			for(var i:uint=0;i<_width;i++){
				for(var j:uint=0;j<_height;j++){
					minval = Math.min(minval,_matrix[i][j]);
				}
			}
			return minval;
		}
		public function max():Number{
			var maxval:Number = -0xffffff;
			for(var i:uint=0;i<_width;i++){
				for(var j:uint=0;j<_height;j++){
					maxval = Math.max(maxval,_matrix[i][j]);
				}
			}
			return maxval;
		}
		public function api():void{
			_matrix.push([]);
		}
		public function apj(i:uint,val:uint):void{
			_matrix[i].push(val);
		}
		public function mult(val:Number):void{
			var fval:Number = val;
			var icnt:uint=0;
			for(var i:uint=0;i<_matrix.length;i++){
				var jcnt:uint = 0
				for(var j:uint=0;j<_matrix[i].length;j++){
					_matrix[icnt][jcnt] = fval * _matrix[i][j];
					jcnt = jcnt + 1;
				}
				icnt=icnt+1
			}
		}
		public function minus(val:Number):void{
			var fval:Number = val;
			var icnt:uint = 0;
			for(var i:uint=0;i<_matrix.length;i++){
				var jcnt:uint = 0;
				for(var j:uint=0;j<_matrix[i].length;j++){
					_matrix[icnt][jcnt] = _matrix[i][j] - fval;
					jcnt = jcnt + 1;
				}
				icnt=icnt+1
			}
		}
		private function gray(c:uint):uint{
			var g:uint = ((c>>16)&0xff)*0.3+((c>>8)&0xff)*0.6+(c&0xff)*0.1;
			return g;
		}
	}
}
					