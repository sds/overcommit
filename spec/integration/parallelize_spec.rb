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

  it 'does not hang' do
    result = Timeout.timeout(5) { subject }
    result.stderr.should_not include 'No live threads left. Deadlock?'
  end
end
