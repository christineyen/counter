package model
{
	public class Util
	{
		public function Util()
		{
		}
        
        public static function isoToDate(value:String):Date {
            var matches:Array = value.match(/\d+/g);
            
            if (matches.length < 7)
                matches.push('0');
            return new Date(int(matches[0]), int(matches[1]), int(matches[2]),
                            int(matches[3]), int(matches[4]), int(matches[5]),
                            int(matches[6]));
        }

	}
}