# frozen_string_literal: true

require 'spec_helper'
require 'json'

describe 'coverage configuration' do
  let(:config) { File.expand_path('coverage_config.rb', __dir__) }
  let(:worker) do
    <<~RUBY
      SimpleCov.start do
        coverage_dir ARGV.fetch(0)
        command_name ARGV.fetch(0)
        formatter SimpleCov::Formatter::MultiFormatter.new([])
      end
      require './decision'
      decision(ARGV.fetch(1) == 'yes')
    RUBY
  end

  def run_coverage(code, *args)
    result = shell([Gem.ruby, '-r', config, '-e', code] + args)
    expect(result.status).to eq(0), result.stderr
  end

  before do
    @ci = ENV['CI']
  end

  after do
    ENV['CI'] = @ci
  end

  it 'records covered and uncovered branches alongside lines locally' do
    ENV.delete('CI')
    directory do
      File.write('decision.rb', "def decision(value)\n  value ? :yes : :no\nend\n")
      run_coverage(worker, 'worker', 'yes')

      report = JSON.parse(File.read('worker/.resultset.json')).fetch('worker').fetch('coverage')
      coverage = report.fetch(File.expand_path('decision.rb'))
      expect(coverage.fetch('lines')).to eq([1, 1, nil])
      expect(coverage.fetch('branches').values.first.values.sort).to eq([0, 1])
    end
  end

  it 'preserves branch hits when collating worker reports for CI uploads' do
    ENV['CI'] = 'true'
    directory do
      File.write('decision.rb', "def decision(value)\n  value ? :yes : :no\nend\n")
      run_coverage(worker, 'worker-yes', 'yes')
      run_coverage(worker, 'worker-no', 'no')
      run_coverage("SimpleCov.collate(Dir['worker-*/.resultset.json'])")

      report = File.read('coverage/lcov.info')
      expect(report).to include("SF:./decision.rb\n", "DA:2,2\n", "BRF:2\n", "BRH:2\n")
      expect(report.scan(/^BRDA:\d+,\d+,\d+,1$/).size).to eq(2)
    end
  end
end
