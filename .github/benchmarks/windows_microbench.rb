# frozen_string_literal: true
require 'json'
require 'rbconfig'
require 'tmpdir'
require 'overcommit/subprocess'

report = { ruby: RUBY_VERSION, platform: RUBY_PLATFORM }
clock = -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
measure = lambda do |count, &block|
  Array.new(count) do
    started = clock.call
    result = block.call
    raise 'Unexpected subprocess failure' if result.respond_to?(:success?) && !result.success?
    clock.call - started
  end
end
report[:powershell] = measure.call(5) do
  result = Overcommit::Subprocess.spawn([
    'powershell.exe', '-NoProfile', '-NonInteractive', '-Command',
    "(Get-CimInstance Win32_Process -Filter 'ProcessId = #{Process.pid}').CommandLine"
  ])
  raise 'Missing parent query result' unless result.stdout.include?('windows_microbench.rb')
  result
end
begin
  report[:cscript] = measure.call(5) do
    result = Overcommit::Subprocess.spawn(['cscript.exe', '//nologo', '//U', '.github/benchmarks/parent_query.js', Process.pid.to_s])
    command = result.stdout.dup.force_encoding('UTF-16LE').encode('UTF-8')
    raise 'Missing cscript result' unless command.include?('windows_microbench.rb')
    result
  end
rescue StandardError => error
  report[:cscript_error] = "#{error.class}: #{error.message}"
end
begin
  started = clock.call
  require 'win32ole'
  report[:win32ole_require] = clock.call - started
  report[:win32ole] = measure.call(5) do
    command = nil
    service = WIN32OLE.connect('winmgmts:root/cimv2')
    service.ExecQuery("SELECT CommandLine FROM Win32_Process WHERE ProcessId = #{Process.pid}").each { |process| command = process.CommandLine }
    raise 'Missing COM result' unless command&.include?('windows_microbench.rb')
    command
  end
rescue LoadError, StandardError => error
  report[:win32ole_error] = "#{error.class}: #{error.message}"
end

def capture_pipes(args)
  out_reader, out_writer = IO.pipe
  err_reader, err_writer = IO.pipe
  pid = Process.spawn(*args, out: out_writer, err: err_writer)
  out_writer.close
  err_writer.close
  out_thread = Thread.new { out_reader.read }
  err_thread = Thread.new { err_reader.read }
  status = Process.wait2(pid).last
  Overcommit::Subprocess::Result.new(status.exitstatus, out_thread.value, err_thread.value)
ensure
  [out_reader, out_writer, err_reader, err_writer].compact.each { |io| io.close unless io.closed? }
end
Dir.mktmpdir do |directory|
  Dir.chdir(directory) do
    raise 'init failed' unless system('git', 'init', '--quiet', '--template=', '--initial-branch=master')
    command = %w[git status --porcelain]
    report[:tempfile_capture] = measure.call(30) { Overcommit::Subprocess.spawn(command) }
    report[:pipe_capture] = measure.call(30) { capture_pipes(command) }
    code = 'require "rbconfig"; Process.spawn(RbConfig.ruby, "-e", "sleep 2", out: STDOUT, err: STDERR); STDOUT.write("parent done")'
    [[:tempfile_descendant, -> { Overcommit::Subprocess.spawn([RbConfig.ruby, '-e', code]) }],
     [:pipe_descendant, -> { capture_pipes([RbConfig.ruby, '-e', code]) }]].each do |name, implementation|
      begin
        report[name] = measure.call(1, &implementation)
      rescue StandardError => error
        report["#{name}_error"] = "#{error.class}: #{error.message}"
      end
    end
  end
end
File.write('windows-microbench.json', JSON.pretty_generate(report))
puts "MICROBENCH #{JSON.generate(report)}"
