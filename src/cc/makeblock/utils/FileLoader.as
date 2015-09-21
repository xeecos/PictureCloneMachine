package cc.makeblock.utils
{
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	
	public class FileLoader extends EventDispatcher
	{
		private var _fileLoad: File = new File();
		private var _bmd:BitmapData;
		private var _isReady:Boolean = false;
		public function FileLoader()
		{
			_fileLoad.addEventListener(Event.SELECT, onImageSelected);
			_fileLoad.addEventListener(Event.COMPLETE, onImageLoaded);
		}
		public function browse(): void {
			_fileLoad.browse();
		}
		private function onImageSelected(evt: Event): void {
			_fileLoad.load();
		}
		private function onImageLoaded(evt: Event): void {
			var movieClipLoader: Loader = new Loader();
			movieClipLoader.loadBytes(evt.target.data);
			movieClipLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
		}
		
		private function onLoaderComplete(evt: Event): void {
			_bmd = evt.target.content.bitmapData.clone();
			this.dispatchEvent(new Event(Event.COMPLETE));
		}
		public function get bitmapData():BitmapData{
			return _bmd;
		}
	}
}