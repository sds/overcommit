# frozen_string_literal: true

require 'spec_helper'
require 'timeout'

describe 'running a hook with parallelism disabled' do
  subject { shell(%w[git commit --allow-empty -m Test]) }

  let(:config) { <<-YML }
    concurrency: 20
    CommitMsg:
      SerialHook:
        enabled: true
        parallelize: false
        required_executable: ruby
        command: ['ruby', '-e', 'sleep 1; File.write("serial-hook-ran", "done")']
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
    # Include Git and hook interpreter startup in the deadline on slower runners.
    result = Timeout.timeout(30) { subject }
    expect(result.status).to eq(0), result.stdout + result.stderr
    File.read('serial-hook-ran').should == 'done'
    result.stderr.should_not include 'No live threads left. Deadlock?'
  end
end
