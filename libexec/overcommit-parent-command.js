// Query the same WMI property as PowerShell without its startup overhead.
// cscript //U writes redirected output as UTF-16LE.
var pid = String(WScript.Arguments(0));
if (!/^\d+$/.test(pid)) WScript.Quit(2);
var service = GetObject('winmgmts:root/cimv2');
var processes = service.ExecQuery('SELECT CommandLine FROM Win32_Process WHERE ProcessId = ' + pid);
var items = new Enumerator(processes);
for (; !items.atEnd(); items.moveNext()) {
  var command = items.item().CommandLine;
  if (command !== null) WScript.StdOut.WriteLine(command);
}
