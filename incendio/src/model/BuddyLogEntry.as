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
		private static var conn:SQLConnection;
        
        public var userId:int;
        public var buddySN:String;
        public var buddyId:int;
        public var size:int;
        public var initiated:int;
        public var msgsUser:int;
        public var msgsBuddy:int;
        public var startTime:Date;
        public var endTime:Date;
        public var timestamp:Date;
		
		public function BuddyLogEntry(userId:int = -1, buddySN:String = '', buddyId:int = -1, size:int = -1, initiated:int = 1,
                msgsUser:int = 0, msgsBuddy:int = 0, startTime:Date = null, endTime:Date = null, timestamp:Date = null) {
            this.userId = userId;
            this.buddySN = buddySN;
            this.buddyId = buddyId;
            this.size = size;
            this.initiated = initiated;
            this.msgsUser = msgsUser;
            this.msgsBuddy = msgsBuddy;
            this.startTime = startTime;
            this.endTime = endTime;
            this.timestamp = timestamp;	
		}
		
		public static function getAllForUser(conn:SQLConnection, userId:int, buddyId:int, buddySN:String):Array {
            var getStmt:SQLStatement = new SQLStatement();
            getStmt.sqlConnection = conn;
            getStmt.text = "SELECT * FROM conversations WHERE user_id="+userId+" AND buddy_id="+buddyId;
            getStmt.execute();
            
            var data:Object = getStmt.getResult().data;
            if (data == null) {
            	trace("BuddyLogEntry.getAllForUser is NULL? for user " + userId + " and buddy " + buddyId);
                return [];
            }
            
            var allConvs:Array = [];
            for each (var row:Object in data) {
            	// we used to instantiate BuddyLogEntries per row
//                allConvs.push(new BuddyLogEntry(row['user_id'], buddySN, row['buddy_id'],
//                                                      row['size'], row['initiated'], row['msgs_user'],
//                                                      row['msgs_buddy'], row['start_time'], row['end_time'],
//                                                      row['timestamp']));
                allConvs.push([buddySN, row['size'], row['initiated'], row['msgs_user']+row['msgs_buddy'],
                              row['msgs_user'], row['end_time']-row['start_time'], row['start_time']]);
            }
            return allConvs;
		}
		
		public static function create(conn:SQLConnection, userScreenName:String, buddyId:int, fileNm:String):void {
            BuddyLogEntry.conn = conn;
            var f:File = new File(fileNm);
            
            XML.ignoreWhitespace = true;
            
            var xmlLoader:URLLoader = new URLLoader();
            xmlLoader.addEventListener(Event.COMPLETE, function(e:Event):void {
                save(e, userScreenName, buddyId, fileNm, f.size, f.creationDate);
            });
            xmlLoader.load(new URLRequest(f.url));
		}
		
		private static function save(e:Event, userSN:String, buddyId:int, fileNm:String, size:int, ts:Date):void {
			var xmlData:XML = new XML(e.target.data);
			var msgs:Array = [];
			var myMsgCt:int = 0;
			
			for each (var dat:XML in xmlData.children()) {
				if (dat.name().localName == 'message') {
					msgs.push(dat);
					if (dat.attribute('sender') == userSN) {
						myMsgCt++;
					}
				}
			}
			if (xmlData.children().length == 0) return; 
			
			try {				
                var startTime:Date = Util.isoToDate(xmlData.children()[0].attribute('time'));
			} catch (err:TypeError) {
				trace("TYPE ERROR FOUND WITH " + xmlData.toString() + " IN " + fileNm);
			}
			var endTime:Date = startTime;
			var initiated:int = 1;
			
			if (msgs.length > 0) {
				startTime = Util.isoToDate(msgs[0].attribute('time'));
				endTime = Util.isoToDate(msgs[msgs.length-1].attribute('time'));
				initiated = (msgs[0].attribute('sender') == userSN) ? 1 : 0;
			}
			
			var saveStmt:SQLStatement = new SQLStatement();
			saveStmt.sqlConnection = BuddyLogEntry.conn;
			saveStmt.text = "INSERT INTO conversations (user_id, buddy_id, size, initiated, msgs_user, msgs_buddy, start_time, end_time, timestamp)";
			saveStmt.text += " VALUES (@user_id, @buddy_id, @size, @initiated, @msgs_user, @msgs_buddy, @start_time, @end_time, @timestamp)";
			
			saveStmt.parameters['@user_id'] = Util.snsToIds[userSN];
			saveStmt.parameters['@buddy_id'] = buddyId;
			saveStmt.parameters['@size'] = size; 
			saveStmt.parameters['@initiated'] = initiated;
			saveStmt.parameters['@msgs_user'] = myMsgCt;
			saveStmt.parameters['@msgs_buddy'] = msgs.length - myMsgCt;
			saveStmt.parameters['@start_time'] = startTime;
			saveStmt.parameters['@end_time'] = endTime;
			saveStmt.parameters['@timestamp'] = ts;
			
			try {
                saveStmt.execute();
            } catch (error:SQLError) {
            	trace('ERRORED OUT saving conversation: ' + fileNm);
            	trace(error.message);
            	trace(error.details);
            }
		}

        public function toString():String {
            return "{ userId: " + this.userId + ", buddySN: " + this.buddySN +
                   ", buddyId: " + this.buddyId + ", size: " + this.size +
                   ", initiated: " + this.initiated + ", msgsUser: " + this.msgsUser +
                   ", msgsBuddy: " + this.msgsBuddy + ", startTime: " + this.startTime +
                   ", endTime: " + this.endTime + ", timestamp: " + this.timestamp + " }";
        }
	}
}