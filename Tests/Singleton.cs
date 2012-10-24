namespace noob536.Test{
	public class SingletonTest{
		public static void Main(){
			Singleton s = Singleton.Instance;
			s.i = 5;
			PrintSingleton();
		}
		public static void PrintSingleton(){
			System.Console.WriteLine(Singleton.Instance.i.ToString());
		}
	}
	public class Singleton{

		private Singleton(){}

		private static Singleton instance;

		public static Singleton Instance{
			get{ 
				if(instance == null){
					instance = new Singleton();
				}
				return instance;
			}
			private set{ instance = value; }
		}

		public int i;
	}
}