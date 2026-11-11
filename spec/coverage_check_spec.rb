# frozen_string_literal: true

require 'spec_helper'

# Exercise the same coverage gate used after CI artifacts are combined.
describe 'combined coverage check' do
  let(:script) { File.expand_path('../script/check_coverage.rb', __dir__) }

  def check_coverage(*reports)
    result = nil
    directory do
      paths = reports.each_with_index.map do |report, index|
        path = "coverage-#{index}.info"
        File.write(path, report)
        path
      end
      result = shell([Gem.ruby, script] + paths)
    end
    result
  end

  it 'combines shards and platforms before requiring every line to be covered' do
    result = check_coverage("SF:./lib/a.rb\nDA:1,0\nDA:2,1\nend_of_record\n",
                            "SF:./lib/a.rb\nDA:1,1\nDA:2,0\nend_of_record\n")
    result.status.should == 0
    result.stdout.should include '100% (2/2)'
  end

  it 'fails for any uncovered line even if the rounded percentage would be 100%' do
    result = check_coverage("SF:./lib/a.rb\nDA:1,99999\nDA:2,0\nend_of_record\n")
    result.status.should_not == 0
    result.stderr.should include './lib/a.rb:2', '100% line coverage is required'
  end

  it 'does not confuse lines at the same position in different source files' do
    result = check_coverage("SF:a.rb\nDA:1,1\nend_of_record\nSF:b.rb\nDA:1,0\nend_of_record\n")
    result.status.should_not == 0
    result.stderr.should include 'b.rb:1'
  end

  it 'fails when no reports are supplied' do
    check_coverage.status.should_not == 0
  end

  it 'fails when reports contain no coverage' do
    result = check_coverage('')
    result.status.should_not == 0
    result.stderr.should include 'No line coverage found'
  end

  it 'rejects line records without a source file' do
    result = check_coverage("DA:1,1\n")
    result.status.should_not == 0
    result.stderr.should include 'Line coverage without a source file'
  end

  it 'resets the source at the end of each record' do
    result = check_coverage("SF:a.rb\nDA:1,1\nend_of_record\nDA:2,1\n")
    result.status.should_not == 0
  end
end
