package {
	import asunit.framework.TestSuite;
	
	public class AllTests extends TestSuite
	{
		public function AllTests()
		{
			super();
			addTest(new BuddySummaryTest("dummyTest"));
            addTest(new BuddySummaryTest("dummyTest2"));
		}

	}
}