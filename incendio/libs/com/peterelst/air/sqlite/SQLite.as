package com.peterelst.air.sqlite
{
	import flash.data.SQLConnection;
	import flash.events.*;
	import flash.filesystem.File;
	
	[Event(name="open", type="flash.events.SQLEvent")]
	[Event(name="close", type="flash.events.SQLEvent")]
	[Event(name="error", type="flash.events.SQLErrorEvent")]
	public class SQLite
	{
		
		private var _connection:SQLConnection;
		private var _databaseFileName:String;	
		private var _databaseFile:File;
		
		public function SQLite()
		{
		}
		
		[Bindable]
		public function get file():String
		{
			return _databaseFileName;
		}
		
		public function set file(filename:String):void
		{
			_databaseFileName = filename;
			_databaseFile = File.applicationDirectory.resolvePath(_databaseFileName);
			connect();
		}
		
		[Bindable]
		public function get connection():SQLConnection
		{
			return _connection;
		}		

		public function set connection(conn:SQLConnection):void
		{
			_connection = conn;
		}	
		
		public function connect():void
		{
			_connection = new SQLConnection();
			_connection.addEventListener(SQLEvent.OPEN, onDatabaseOpen);
			_connection.addEventListener(SQLEvent.CLOSE, onDatabaseClose);
			_connection.addEventListener(SQLErrorEvent.ERROR, onDatabaseError);
			_connection.openAsync(_databaseFile);
		}
		
		public function close():void
		{
			_connection.close();
		}
		
		private function onDatabaseOpen(evt:SQLEvent):void
		{
			dispatchEvent(evt);
		}

		private function onDatabaseClose(evt:SQLEvent):void
		{
			dispatchEvent(evt);
		}
		
		private function onDatabaseError(evt:SQLErrorEvent):void
		{
			dispatchEvent(evt);
		}

	}
}