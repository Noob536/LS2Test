/* expected
1+1=2
1-1=0
10/2=5
5*5=25
7%5=2
1|2=3
3&2=2
1<<1=2
2>>1=1
3^1=2
*/

namespace noob536.Test{

	public class Operators{
		public static void main(){
			System.Console.WriteLine("1+1=" + (1+1).ToString());
			System.Console.WriteLine("1-1=" + (1-1).ToString());
			System.Console.WriteLine("10/2=" + (10/2).ToString());
			System.Console.WriteLine("5*5=" + (5*5).ToString());
			System.Console.WriteLine("7%5=" + (7%5).ToString());
			System.Console.WriteLine("1|2=" + (1|2).ToString());
			System.Console.WriteLine("3&2=" + (3&2).ToString());
			System.Console.WriteLine("1<<1=" + (1<<1).ToString());
			System.Console.WriteLine("2>>1=" + (2>>1).ToString());
			System.Console.WriteLine("3^1=" + (3^1).ToString());
		}
	}
}