require 'spec_helper'
require 'timeout'

describe 'running a hook with parallelism disabled' do
  subject { shell(%w[git commit --allow-empty -m Test]) }

  let(:config) { <<-YML }
    CommitMsg:
      TrailingPeriod:
        enabled: true
        parallelize: false
  YML

  around do |example|
    repo do
      File.open('.overcommit.yml', 'w') { |f| f.write(config) }
      `overcommit --install > #{File::NULL}`
      example.run
    end
  end

  it 'does not hang' do
    Timeout.timeout(5) { subject }
  end
end
