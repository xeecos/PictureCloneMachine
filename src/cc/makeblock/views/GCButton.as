package cc.makeblock.views
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	public class GCButton extends Sprite
	{
		private var _title:String = "";
		private var _overColor:uint;
		private var _outColor:uint;
		private var _isBorder:Boolean;
		private var _width:uint = 120;
		private var _height:uint = 40;
		private var _textField:TextField = new TextField();
		public function GCButton(title:String = "",overColor:uint = 0xffcccc,outColor:uint = 0xffcc00,isBorder:Boolean = false)
		{
			super();
			_title = title;
			_overColor = overColor;
			_outColor = outColor;
			_isBorder = isBorder;
			this.addChild(_textField);
			this.mouseChildren = false;
			this.buttonMode = true;
			this.addEventListener(MouseEvent.MOUSE_OVER,onRollOver);
			this.addEventListener(MouseEvent.MOUSE_OUT,onRollOut);
			this.addEventListener(Event.ADDED_TO_STAGE,init);
			onRollOut(null);
		}
		private function init(evt:Event):void{
			var tf:TextFormat = new TextFormat;
			tf.font = "Arial";
			tf.size = 14;
			tf.align = TextFormatAlign.CENTER;
			_textField.width = 120;
			_textField.height = 20;
			_textField.y = (_height - _textField.height)/2;
			_textField.defaultTextFormat = tf;
			_textField.text = _title;
			_textField.selectable = false;
		}
		public function setTitle(title:String):void{
			_title = title;
			_textField.text = _title;
		}
		public function get title():String{
			return _title;
		}
		public function setHeight(height:uint):void{
			_height = height;
			_textField.y = (_height - _textField.height)/2;
			onRollOut();
		}
		public function setWidth(width:uint):void{
			_width = width;
			_textField.width = _width;
			_textField.x = (_width - _textField.width)/2;
			onRollOut();
		}
		private function onRollOver(evt:MouseEvent):void{
			this.graphics.clear();
			this.graphics.beginFill(_overColor,1);
			if(_isBorder){
				this.graphics.lineStyle(1,0,1);
			}
			this.graphics.drawRect(0,0,_width,_height);
			this.graphics.endFill();
		}
		private function onRollOut(evt:MouseEvent=null):void{
			this.graphics.clear();
			this.graphics.beginFill(_outColor,1);
			if(_isBorder){
				this.graphics.lineStyle(1,0,1);
			}
			this.graphics.drawRect(0,0,_width,_height);
			this.graphics.endFill();
		}
	}
}