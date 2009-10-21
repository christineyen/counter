package model
{
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class BuddyLogEntry
	{
		private var conn:SQLConnection;
		private var userId:int;
		private var buddyId:int;
		private var userSN:String;
		
		private var size:int;
		private var ts:Date;
		
		private var fileNm:String; // TEMPORARY, just for debugging purposes
		
		public function BuddyLogEntry(conn:SQLConnection, userScreenName:String, userId:int, buddyId:int, fileNm:String)
		{
			this.conn = conn;
			
			this.userSN = userScreenName;
			this.userId = userId;
			this.buddyId = buddyId;
			
			this.fileNm = fileNm;
			var f:File = new File(fileNm);
			size = f.size;
			ts = f.creationDate;
			
			XML.ignoreWhitespace = true;
			
			var xmlLoader:URLLoader = new URLLoader();
			xmlLoader.addEventListener(Event.COMPLETE, save);
			xmlLoader.load(new URLRequest(f.url));
		}
		
		private function save(e:Event):void {
			var xmlData:XML = new XML(e.target.data);
			var msgs:Array = [];
			var myMsgCt:int = 0;
			
			for each (var dat:XML in xmlData.children()) {
				if (dat.name().localName == 'message') {
					msgs.push(dat);
					if (dat.attribute('sender') == this.userSN) {
						myMsgCt++;
					}
				}
			}
			if (xmlData.children().length == 0) return; 
			
			try {				
                var startTime:Date = Util.isoToDate(xmlData.children()[0].attribute('time'));
			} catch (err:TypeError) {
				trace("TYPE ERROR FOUND WITH " + xmlData.toString() + " IN FILE " + this.fileNm);
			}
			var endTime:Date = startTime;
			var initiated:int = this.userId;
			
			if (msgs.length > 0) {
				startTime = Util.isoToDate(msgs[0].attribute('time'));
				endTime = Util.isoToDate(msgs[msgs.length-1].attribute('time'));
				initiated = (msgs[0].attribute('sender') == this.userSN) ? this.userId : this.buddyId;
			}
			
			var saveStmt:SQLStatement = new SQLStatement();
			saveStmt.sqlConnection = this.conn;
			saveStmt.text = "INSERT INTO conversations (user_id, buddy_id, size, initiated, msgs_user, msgs_buddy, start_time, end_time, timestamp)";
			saveStmt.text += " VALUES (@user_id, @buddy_id, @size, @initiated, @msgs_user, @msgs_buddy, @start_time, @end_time, @timestamp)";
			
			saveStmt.parameters['@user_id'] = this.userId;
			saveStmt.parameters['@buddy_id'] = this.buddyId;
			saveStmt.parameters['@size'] = this.size; 
			saveStmt.parameters['@initiated'] = initiated;
			saveStmt.parameters['@msgs_user'] = myMsgCt;
			saveStmt.parameters['@msgs_buddy'] = msgs.length - myMsgCt;
			saveStmt.parameters['@start_time'] = startTime;
			saveStmt.parameters['@end_time'] = endTime;
			saveStmt.parameters['@timestamp'] = this.ts;
			
			try {
                saveStmt.execute();
            } catch (error:SQLError) {
            	trace('ERRORED OUT saving conversation: ' + this.fileNm);
            	trace(error.message);
            	trace(error.details);
            }
		}

	}
}