package model
{
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	
	public class BuddySummary
	{
		public var size:int = -1;
		public var ct:int = -1;
		public var initiated:int = int(Number.MIN_VALUE);
		public var buddyId:int = -1;
		public var buddySN:String = null;
		public var ts:Date = null;
				
//		public function BuddySummary(buddySN:String, count:int, size:int) {
//			this.userSN = buddy;
//			this.ct = count;
//			this.size = size;
//		}
		public function BuddySummary(buddySN:String, buddyId:int = -1, conn:SQLConnection = null) {
            this.buddySN = buddySN;
            if (buddyId < 0) {
            	this.buddyId = Util.getUser(conn, buddySN);
            } else {
                this.buddyId = buddyId;
            }
            
			if (conn == null) return;
			
			var summaryStmt:SQLStatement = new SQLStatement();
			summaryStmt.sqlConnection = conn;
			summaryStmt.text = "select count(buddy_id) as ct, sum(size) as sz, sum(initiated) as initiated, max(timestamp) as ts \
                from conversations inner join users on users.id = conversations.buddy_id \
                where users.screenname = '"+buddySN+"' group by buddy_id limit 1";
            summaryStmt.execute();
            
            if (summaryStmt.getResult().data == null) return;
            
            var data:Object = summaryStmt.getResult().data[0];
            
            this.ct = int(data['ct']);
            this.size = int(data['sz']);
            this.initiated = int(data['initiated']) - (this.ct / 2);
            this.ts = Util.isoToDate(data['ts']);
		}
		
		/**
		 * @returns - an Array of all BuddySummaries represented in the database
		 **/ 
		public static function getAll(conn:SQLConnection, userId:int):Array {
			var getStmt:SQLStatement = new SQLStatement();
			getStmt.sqlConnection = conn;
			getStmt.text = "SELECT users.screenname as sn, buddy_id as bid, COUNT(buddy_id) AS ct, SUM(size) AS sz, SUM(initiated) as initiated,";
			getStmt.text += " DATETIME(MAX(end_time)) AS ts";
            getStmt.text += " FROM conversations INNER JOIN users ON users.id = conversations.buddy_id";
            getStmt.text += " WHERE conversations.user_id = "+userId+" GROUP BY buddy_id";
            getStmt.execute();
            
            var data:Object = getStmt.getResult().data;
            if (data == null) {
                trace('NULLL?!?!?');
                return [];
            }
            
            var all:Array = [];
            for each (var row:Object in data) {
            	trace("0: " + row['sn'] + ", 1: " + row['ct'] + ", 2: " + row['sz'] + ", 3: " + row['ts']);
            	var bs:BuddySummary = new BuddySummary(row['sn'], int(row['bid']));
            	bs.ct = int(row['ct']);
            	bs.size = int(row['sz']);
                bs.initiated = int(row['initiated']) - (bs.ct / 2);
            	bs.ts = new Date(Date.parse(row['ts'].replace(/-/g, '/')));
            	all.push(bs);
            }
            return all;
		}
		
		public function nil():Boolean {
			return (this.size < 0) &&
			         (this.ct < 0) &&
			         (this.initiated < 0) &&
			         (this.buddySN == null) &&
			         (this.ts == null);
		}
		
		public function toString():String {
			return "BuddySummary for " + this.buddySN +
			       "(id " + this.buddyId + "), " + this.ct + " conversations taking up " + this.size +
			       " bytes, last modified on " + this.ts.toDateString();
		}
	}
}