/* expected
Peek: 1 Size: 1
Peek: 3 Size: 2
Pop: 3
Peek: 1 Size: 1
*/

namespace noob536.Test{
	public class StackTest{
		public static void Main(){
			noob536.Stack s = new noob536.Stack();
			s.Push(1);
			System.Console.WriteLine("Peek: " + s.Peek().ToString() + " Size: " + s.Size);
			s.Push(3);
			System.Console.WriteLine("Peek: " + s.Peek().ToString() + " Size: " + s.Size);
			int i = s.Pop();
			System.Console.WriteLine("Pop: " + i.ToString());
			System.Console.WriteLine("Peek: " + s.Peek().ToString() + " Size: " + s.Size);
		}
	}
}

namespace noob536 {
	
	public class Stack {
		public Stack(){
			Size = 0;
		}

		protected StackItem _top;
		public int Size{
			get;
			private set;
		}

		public void Push(int i){
			_top = new StackItem(i, _top);
			try {
				//works
				//Size += 1;
				// Push Exception: Illegal operand for instruction
				Size++;
			} catch (System.Exception e){
				System.Console.WriteLine("Push Exception: " + e);
			}
		}

		public int Pop(){
			int value = _top.Value;
			_top = _top.Next;
			try {
				// works
				// Size -= 1;
				// this works
				--Size;
			} catch (System.Exception e){
				System.Console.WriteLine("Pop Exception: " + e.ToString());
			}
			return value;
		}

		public int Peek(){
			return _top.Value;
		}
	}
	
	public class StackItem {
		public int Value{ get; private set; }
		public StackItem Next{ get; private set; }
		
		public StackItem(int i, StackItem next){
			Value = i;
			Next = next;
		}
		
		
	}
}

