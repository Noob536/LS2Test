; global states
variable bool CompilingCompleted
variable bool CleanupCompleted

; tests
variable index:TestRunner Tests
variable int RunningTest
variable bool AcceptOutput = FALSE

;copy of this at the bottom of the script.. i might put my lib up later
;#include ${LavishScript.HomeDirectory}/Scripts/Noob/Timer.iss

function main(... args)
{
	echo \atLS2Test started
	osexecute cleanup
	while !${CleanupCompleted}
		waitframe
	
	if ${args.Used}
		call PopulateTests ${args[1]}
	else
		call PopulateTests
	
	echo \agRunning ${Tests.Used} Tests
	
	AddTrigger ConsoleOutput "@line@"
	
	variable int i
	for(i:Set[1]; ${i} <= ${Tests.Used}; i:Inc)
	{
		echo \atRunning test: ${Tests[${i}].Name}
		RunningTest:Set[${i}]
		call Tests[${i}].RunTest
	}
	
	variable int TestsPassed = 0
	variable int TestsFailed = 0
	variable int RunningTimeouts = 0
	variable int CompileErrors = 0
	variable int CompileExceptions = 0
	variable int CompileTimeouts = 0
	variable int NoOutput = 0
	echo \ag-----------------------
	echo \ag------ Results --------
	echo \ag-----------------------
	for(i:Set[1]; ${i} <= ${Tests.Used}; i:Inc)
	{
		if ${Tests[${i}].Passed}
		{
			TestsPassed:Inc
			continue
		}
		else
			TestsFailed:Inc
		if !${Tests[${i}].Compiled}
		{
			echo \aoTest [\ap${Tests[${i}].Name}\ao] failed to compile
			if ${Tests[${i}].CompilerException}
			{
				CompileExceptions:Inc
				echo \aoException generated: 
				Tests[${i}]:DumpExceptionFile
			}
			if ${Tests[${i}].CompileError}
			{
				CompileErrors:Inc
				echo \aoError generated:
				Tests[${i}]:DumpErrorFile
			}
			if ${Tests[${i}].CompilerTimeout}
			{
				CompileTimeouts:Inc
				echo \arCompiler Timed Out for unknown reasons!
			}
		}
		else
		{
			echo \aoTest [\ap${Tests[${i}].Name}\ao] failed
			if ${Tests[${i}].TimedOut}
			{
				RunningTimeouts:Inc
				echo \arTook too long to complete
			} 
			elseif !${Tests[${i}].TestOutput.Size}
			{
				NoOutput:Inc[]
				echo \ao Test failed to output anything
			}
			else
			{
				echo \ao Test Output did not match expected output
				echo \ao Expected:
				Tests[${i}]:DumpExpectedOutput
				echo \ao Actual:
				Tests[${i}]:DumpTestOutput
			}
		}
		echo -------------------------------
	}
	
	;output stats/what failed
	echo \atTests Complete
	echo \ag ${Tests.Used} ran
	echo \ag ${TestsPassed} passed
	if ${TestsFailed}
		echo \ar ${TestsFailed} failed
	if ${CompileErrors}
		echo \ar ${CompileErrors} compile errors
	if ${CompileExceptions}
		echo \ar ${CompileExceptions} compile exceptions
	if ${CompileTimeouts}
		echo \ar ${CompileTimeouts} compile timeouts
	if ${RunningTimeouts}
		echo \ar ${RunningTimeouts} running timeouts
	if ${NoOutput}
		echo \ar ${NoOutput} no output
}

atom ConsoleOutput(string line, string line2)
{
	if ${AcceptOutput}
		Tests[${RunningTest}].TestOutput:Insert["${line2.Escape}"]
}

function PopulateTests(string filter="")
{
	
	variable filelist FileList
	FileList:GetFiles["Tests\\*"]
	variable int i
	for(i:Set[1]; ${i} <= ${FileList.Files}; i:Inc)
	{
		if ${filter.Equal[""]} || (!${filter.Equal[""]} && ${FileList.File[${i}].Filename.Find[${filter}]})
			Tests:Insert["${FileList.File[${i}].Filename}"]
	}
}


atom(global) LS2Test(... args)
{
	if !${args.Used}
		return
	switch ${args[1]}
	{
		case CompilingCompleted
			CompilingCompleted:Set[TRUE]
			break	
		case CleanupCompleted
			CleanupCompleted:Set[TRUE]
			break
	}		
	
}


objectdef TestRunner
{
	variable string Name
	
	variable string FileName
	variable string CompiledFileName
	variable string CompilerExceptionLogFile
	
	variable index:string Args
	
	variable index:string TestOutput
	variable index:string ExpectedOutput
	
	variable bool CompileError = FALSE
	variable bool CompilerException = FALSE
	variable bool CompilerTimeout = FALSE
	variable bool Compiled = FALSE
	
	variable bool Ran = FALSE
	variable bool Passed = FALSE
	variable bool TimedOut = FALSE
	
	method Initialize(string testFileName)
	{
		This.FileName:Set["${testFileName}"]
		This.Name:Set["${testFileName.Left[-3]}"]
		This.CompiledFileName:Set["${This.Name}.ls2il"]
		This.CompilerExceptionLogFile:Set["${This.Name}.txt"]
		
		variable file TestFile = "Tests\\${testFileName}"
		
		if ${TestFile:Open[readonly](exists)}
		{
			variable string Line
			variable string CommentStart = "/"
			CommentStart:Concat["*"]
			variable string CommentEnd = "*"
			CommentEnd:Concat["/"]
			variable bool InExpected = FALSE
			variable bool InArgs = FALSE
			do
			{
				Line:Set["${TestFile.Read.Escape}"]
				Line:Set["${Line.Replace["\r","","\n",""]}"]
				if ${Line.Equal[""]}
					continue
				if ${Line.Find[${CommentEnd}]}
				{
					InExpected:Set[FALSE]
					InArgs:Set[FALSE]
				}
				
				if ${InExpected}
				{
					This.ExpectedOutput:Insert["${Line.Escape}"]
					;echo ${Line.Escape}
				}
				if ${InArgs}
					This.Args:Insert["${Line.Escape}"]					
				
				if ${Line.Find["${CommentStart}"]} && ${Line.Find["expected"]}
				{
					;echo Expected: 
					InExpected:Set[TRUE]
				}
				if ${Line.Find["${CommentStart}"]} && ${Line.Find["args"]}
					InArgs:Set[TRUE]
			}
			while !${TestFile.EOF}
			TestFile:Close
		}
	}
	
	function RunTest()
	{
		This.Ran:Set[TRUE]
		; Script TestCompleted for the commands atom for the batch file to callback
		CompilingCompleted:Set[FALSE]
		
		variable Noob_Timer timer
		
		osexecute compile ${This.Name}
		timer:Set[5000]
		while ${timer.IsRunning} && !${CompilingCompleted}
			waitframe
		
		;if global compiled
		if ${CompilingCompleted}
		{
			variable filepath ErrorFilePath = "CompileErrors"
			variable bool ErrorFileExists = FALSE
			if ${ErrorFilePath.FileExists["${This.CompilerExceptionLogFile}"]}
			{
				variable file ErrorFile = "${ErrorFilePath.AbsolutePath}\\${This.CompilerExceptionLogFile}"
				if ${ErrorFile.Size}
				{
					ErrorFileExists:Set[TRUE]
				}
			}
			if !${ErrorFileExists}
			{
				variable file CompiledFile = "Compiled\\${This.CompiledFileName}"
				variable string Line
				if ${CompiledFile:Open[readonly](exists)}
				{
					do
					{
						Line:Set["${CompiledFile.Read.Escape}"]
						if ${Line.Left[3].Equal["Fix"]} && ${Line.Find[Errors]}
						{
							This.CompileError:Set[TRUE]
							return
						}
					}
					while !${CompiledFile.EOF}
				}
				CompiledFile:Close
				This.Compiled:Set[TRUE]
			}
			else
			{
				This.CompilerException:Set[TRUE]
				return
			}
		}		
		else
		{
			This.CompilerTimeout:Set[TRUE]
			return
		}
		
		
		AcceptOutput:Set[TRUE]
		
		timer:Set[10000]
		LavishScript2.RegisterScript[-ls2il,"${This.Name}","Compiled\\${This.CompiledFileName}"]:Start
		while ${timer.IsRunning} && ${LavishScript2.GetScript["${This.Name}"].IsStarted}
			waitframe
			
		AcceptOutput:Set[FALSE]
		
		if !${LavishScript2.GetScript["${This.Name}"].IsStarted}
		{
			;echo finished running
			This.Completed:Set[TRUE]
			LavishScript2.GetScript["${This.Name}"]:Stop
			LavishScript2:UnregisterScript["${This.Name}"]
		}
		else
		{
			;echo stopped running
			LavishScript2.GetScript["${This.Name}"]:Stop
			waitframe
			LavishScript2:UnregisterScript["${This.Name}"]
			This.TimedOut:Set[TRUE]
			return
		}
		

		;echo ${This.TestOutput.Used}
		if !${This.TestOutput.Size}
		{
			;echo failed no output
			return
		}

		variable int i
		for(i:Set[1]; ${i} <= ${This.TestOutput.Used}; i:Inc)
		{
			if !${This.ExpectedOutput[${i}](exists)}
				return
			if ${This.TestOutput[${i}].Equal[""]} || ${This.ExpectedOutput[${i}].Equal[""]}
				return
			if !${This.TestOutput[${i}].Equal["${This.ExpectedOutput[${i}].Escape}"]}
				return
		}
		This.Passed:Set[TRUE]
	}
	
	method DumpExceptionFile()
	{
		This:DumpFile["CompileErrors\\${This.CompilerExceptionLogFile}"]	
	}
	
	method DumpErrorFile()
	{
		This:DumpFile["Compiled\\${This.CompiledFileName}"]	
	}
	
	method DumpFile(string fileName)
	{
		
		variable file File = "${fileName.Escape}"
		if ${File:Open[readonly](exists)}
		{
			variable string Line
			do
			{
				Line:Set["${File.Read.Escape}"]
				if !${Line.Equal[NULL]}
					echo "\ar${Line.Escape}"
			}
			while !${File.EOF}
			File:Close
		}	
	}
	
	method DumpExpectedOutput()
	{
		This:DumpIndex[ExpectedOutput]
	}
	
	method DumpTestOutput()
	{
		This:DumpIndex[TestOutput]
	}
	
	method DumpIndex(string var)
	{
		variable int i
		for(i:Set[1]; ${i} <= ${This.${var}.Used}; i:Inc)
		{
			echo ${This.${var}[${i}].Escape}
		}
	}
}


/*
copy/pasta because yea... lazy.
*/

#ifndef NOOB_TIMER
	#define NOOB_TIMER

objectdef Noob_Timer 
{

	variable int End
	variable int Start
	variable int Period
	
	/**
	* Instantiates a new Timer with a given time
	* period in milliseconds.
	*
	* @param period Time period in milliseconds.
	*/
	method Set(int length)
	{
		This.Period:Set[${length}]
		This.Start:Set[${Script.RunningTime}]
		This.End:Set[${Math.Calc[${This.Start}+${This.Period}]}]
	}
	
	/**
	* Returns the number of milliseconds elapsed since
	* the start time.
	*
	* @return The elapsed time in milliseconds.
	*/
	member:int GetElapsed() 
	{
		return ${Math.Calc[${Script.RunningTime}-${This.Start}]}
	}
	
	/**
	* Returns the number of milliseconds remaining
	* until the timer is up.
	*
	* @return The remaining time in milliseconds.
	*/
	member:int GetRemaining() 
	{
		if ${This.IsRunning}
		{
			return ${Math.Calc[${This.End}-${Script.RunningTime}]}
		}
		return 0
	}
	
	/**
	* Returns <tt>true</tt> if this timer's time period
	* has not yet elapsed.
	*
	* @return <tt>true</tt> if the time period has not yet passed.
	*/
	member:bool IsRunning() 
	{
		return ${If[${Script.RunningTime} < ${This.End},TRUE,FALSE]}
	}
	
	/**
	* Restarts this timer using its period.
	*/
	method Reset() 
	{
		This.End:Set[${Math.Calc[${Script.RunningTime}+${This.Period}]}]
	}
	
	/**
	* Sets the end time of this timer to a given number of
	* milliseconds from the time it is called. This does
	* not edit the period of the timer (so will not affect
	* operation after reset).
	*
	* @param ms The number of milliseconds before the timer
	* should stop running.
	* @return The new end time.
	*/
	member:int SetEndIn(int ms) 
	{
		This.End:Set[${Math.Calc[${Script.RunningTime}+${This.Period}]}]
	}
	
	/**
	* Returns a formatted String of the time elapsed.
	*
	* @return The elapsed time formatted hh:mm:ss.
	*/
	member:string ToElapsedString() 
	{
		return "${This.Format[${This.GetElapsed}].Escape}"
	}
	
	/**
	* Returns a formatted String of the time remaining.
	*
	* @return The remaining time formatted hh:mm:ss.
	*/
	member:string ToRemainingString() 
	{
		return "${This.Format[${This.GetRemaining}].Escape}"
	}
	
	/**
	* Converts milliseconds to a String in the format
	* hh:mm:ss.
	*
	* @param time The number of milliseconds.
	* @return The formatted String.
	*/
	member:string Format(int duration) 
	{
		variable string t
		variable int total_secs
		variable int total_mins
		variable int total_hrs
		variable int secs
		variable int mins
		variable int hrs
		
		total_secs:Set[${Math.Calc[${duration}/1000]}]
		total_mins:Set[${Math.Calc[${total_secs}/60]}]
		total_hrs:Set[${Math.Calc[${total_mins}/60]}]
		secs:Set[${Math.Calc[${total_secs}%60]}]
		mins:Set[${Math.Calc[${total_mins}%60]}]
		hrs:Set[${Math.Calc[${total_hrs}%60]}]
		
		t:Concat[${hrs.LeadingZeroes[2]}]
		t:Concat[":"]
		t:Concat[${mins.LeadingZeroes[2]}]
		t:Concat[":"]
		t:Concat[${secs.LeadingZeroes[2]}]
		
		return "${t.Escape}"
	}
}
#endif