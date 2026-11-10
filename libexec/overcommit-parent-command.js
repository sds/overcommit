// Query WMI without PowerShell's startup overhead.
// cscript //U writes redirected output as UTF-16LE.
var pid = String(WScript.Arguments(0));
if (!/^\d+$/.test(pid)) WScript.Quit(2);
var service = GetObject('winmgmts:root/cimv2');
// Git for Windows keeps an env.exe launcher between Git and the Ruby hook.
for (var level = 0; level < 4; level++) {
  var processes = service.ExecQuery(
    'SELECT Name, CommandLine, ParentProcessId FROM Win32_Process WHERE ProcessId = ' + pid
  );
  var items = new Enumerator(processes);
  if (items.atEnd()) break;
  var process = items.item();
  if (String(process.Name).toLowerCase() !== 'env.exe') {
    if (process.CommandLine !== null) WScript.StdOut.WriteLine(process.CommandLine);
    break;
  }
  pid = String(process.ParentProcessId);
}
