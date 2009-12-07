package model
{
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	
	public class Util
	{
        public static var snsToIds = {} 
        
		public function Util()
		{
		}
        
        public static function getUser(conn:SQLConnection, screenName:String):int {
        	if (snsToIds[screenName] != undefined) {
                trace("snsToIds contains " + screenName + ", returning value " + snsToIds[screenName]); 
        	    return snsToIds[screenName];
        	}
        	
            var getUserStmt:SQLStatement = new SQLStatement();
            getUserStmt.sqlConnection = conn;
            getUserStmt.text = 'SELECT id FROM users WHERE screenname = @sn LIMIT 1';
            getUserStmt.parameters['@sn'] = screenName;
            
            var setUserStmt:SQLStatement = new SQLStatement();
            setUserStmt.sqlConnection = conn;
            
            getUserStmt.execute();
            var id:Array = getUserStmt.getResult().data;
            if (id == null) {
                trace('inserting record into users for ' + screenName);
                setUserStmt.text = 'INSERT INTO users (screenname) VALUES ("' + screenName + '");';
                setUserStmt.execute();
                getUserStmt.execute();
                id = getUserStmt.getResult().data;
            }
            trace('statement data: ' + id[0]['id']);
            snsToIds[screenName] = int(id[0]['id']); 
            return snsToIds[screenName];
        }
        
        public static function isoToDate(value:String):Date {
            var matches:Array = value.match(/\d+/g);
            
            if (matches.length < 7)
                matches.push('0');
            var d:Date = new Date(int(matches[0]), int(matches[1]), int(matches[2]),
                            int(matches[3]), int(matches[4]), int(matches[5]),
                            int(matches[6]));
            return d;
        }
        
        public static function dateCmpFunction(a:Date, b:Date):Number {
        	if (a.time > b.time)
        	   return 1;
    	    else if (a.time < b.time)
    	       return -1;
    	    
	        return 0; 
        }
	}
}