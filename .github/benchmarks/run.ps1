param([string]$Variant, [int]$Shard)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$root = (Get-Location).Path
$python = (Get-Command python).Source
$originalPath = $env:PATH
$originalTemp = $env:TEMP
$originalTmp = $env:TMP
$rubyBin = & ruby -rrbconfig -e 'print File.dirname(RbConfig.ruby)'
$gitBin = Split-Path (Get-Command git).Source -Parent
$gitRoot = Split-Path (Split-Path (git --exec-path) -Parent) -Parent
$gitUsr = Join-Path (Split-Path $gitRoot -Parent) 'usr\bin'
$reportRoot = Join-Path $root 'benchmark-results'
$patch = Join-Path $root ".github/benchmarks/$Variant.patch"
$failed = $false
$order = if ($Shard % 2 -eq 0) { @('candidate', 'control') } else { @('control', 'candidate') }
foreach ($phase in $order) {
  $env:PATH = $originalPath
  $env:TEMP = $originalTemp
  $env:TMP = $originalTmp
  $env:SPEC_WORKERS = '4'
  $env:SPEC_SHARD = "$Shard/5"
  $applied = $false
  if ($phase -eq 'candidate') {
    if (Test-Path $patch) {
      & git apply --check $patch
      if ($LASTEXITCODE -ne 0) { throw 'Patch check failed' }
      & git apply $patch
      if ($LASTEXITCODE -ne 0) { throw 'Patch failed' }
      $applied = $true
    }
    if ($Variant -eq 'workers6') { $env:SPEC_WORKERS = '6' }
    if ($Variant -eq 'workers8') { $env:SPEC_WORKERS = '8' }
    if ($Variant -eq 'short_temp') {
      $short = Join-Path (Split-Path $root -Qualifier) 't'
      New-Item -ItemType Directory -Force $short | Out-Null
      $env:TEMP = $short
      $env:TMP = $short
    }
    if ($Variant -eq 'lean_path') {
      $env:PATH = @($rubyBin, $gitBin, $gitUsr, "$env:SystemRoot\System32", $env:SystemRoot, "$env:SystemRoot\System32\WindowsPowerShell\v1.0") -join ';'
    }
  }
  $report = Join-Path $reportRoot $phase
  New-Item -ItemType Directory -Force $report | Out-Null
  $env:BENCHMARK_RESULTS_DIR = $report
  try {
    & $python .github/benchmarks/prepare_profile.py
    if ($LASTEXITCODE -ne 0) { throw 'Profile preparation failed' }
    $started = [System.Diagnostics.Stopwatch]::StartNew()
    & bundle exec ruby coverage/benchmark_rspec.rb *> (Join-Path $report 'rspec.log')
    $exit = $LASTEXITCODE
    $started.Stop()
    $summaryFile = Join-Path $report 'summary.json'
    if (Test-Path $summaryFile) { $summary = Get-Content $summaryFile -Raw | ConvertFrom-Json } else { $summary = $null }
    $result = @{variant=$Variant;shard=$Shard;phase=$phase;exit=$exit;wall=$started.Elapsed.TotalSeconds;summary=$summary}
    $result | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $report 'phase.json')
    Write-Output ('BENCHMARK ' + ($result | ConvertTo-Json -Depth 8 -Compress))
    if ($exit -ne 0) {
      $failed = $true
      Get-Content (Join-Path $report 'rspec.log') -Tail 80 | Write-Output
    }
  } finally {
    $env:PATH = $originalPath
    $env:TEMP = $originalTemp
    $env:TMP = $originalTmp
    if ($applied) {
      & git apply -R $patch
      if ($LASTEXITCODE -ne 0) { throw 'Patch rollback failed' }
    }
  }
}
if ($failed) { exit 1 }
