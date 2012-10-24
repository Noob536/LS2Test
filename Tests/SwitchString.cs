/* expected
1
2 or 3
2 or 3
4
not 1 2 3 or 4
*/

namespace noob536.Tests{
	
	public class SwitchString{

		public static void Main()
		{
			Switch("One");
			Switch("Two");
			Switch("Three");
			Switch("Four");
			Switch("Five");
		}
		public static void Switch(string s){
			switch(s){
				case "One":
					System.Console.WriteLine("1");
					break;
				case "Two":
				case "Three":
					System.Console.WriteLine("2 or 3");
					break;
				case "Four":
					System.Console.WriteLine("4");
					break;
				default:
					System.Console.WriteLine("not 1 2 3 or 4");
					break;
			}
		}
	}
}