/* expected
TestClass1.TestMethod
TestClass2.TestMethod
TestClass1.TestMethod
TestClass2.TestMethod
*/

namespace noob536.Test {

	public interface TestInterface {
		void TestMethod();
	}

	public class Interface {
		public static void Main(){
			TestInterface ti1 = new TestClass1();
			ti1.TestMethod();

			TestInterface ti2 = new TestClass2();
			ti2.TestMethod();

			OutputInterface(ti1);
			OutputInterface(ti2);
		}

		public static void OutputInterface(TestInterface ti){
			ti.TestMethod();
		}
	}

	public class TestClass1 : TestInterface {
		public void TestMethod(){
			System.Console.WriteLine("TestClass1.TestMethod");
		}
	}

	public class TestClass2 : TestInterface {
		public void TestMethod(){
			System.Console.WriteLine("TestClass2.TestMethod");
		}
	}
}