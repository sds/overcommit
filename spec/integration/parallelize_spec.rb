# frozen_string_literal: true

require 'spec_helper'
require 'timeout'

describe 'running a hook with parallelism disabled' do
  subject { shell(%w[git commit --allow-empty -m Test]) }

  let(:config) { <<-YML }
    concurrency: 20
    CommitMsg:
      TrailingPeriod:
        enabled: true
        parallelize: false
        command: ['ruby', '-e', 'sleep 1']
      TextWidth:
        enabled: true
        parallelize: true
        processors: 1
  YML

  around do |example|
    repo do
      File.open('.overcommit.yml', 'w') { |f| f.write(config) }
      `overcommit --install > #{File::NULL}`
      example.run
    end
  end

  # Test fails on Ruby 3.0 on Windows but nothing else. Would glady accept a pull
  # request that resolves.
  unless Overcommit::OS.windows? &&
    Overcommit::Utils::Version.new(RUBY_VERSION) >= '3' &&
    Overcommit::Utils::Version.new(RUBY_VERSION) < '3.1'
    it 'does not hang' do
      result = Timeout.timeout(5) { subject }
      result.stderr.should_not include 'No live threads left. Deadlock?'
    end
  end
end
