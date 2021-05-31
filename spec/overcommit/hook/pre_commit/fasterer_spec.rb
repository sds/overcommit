# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::Fasterer do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  let(:applicable_files) { %w[file1.rb file2.rb] }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(applicable_files)
  end

  around do |example|
    repo do
      example.run
    end
  end

  before do
    subject.stub(:execute).with(%w[fasterer], args: applicable_files).and_return(result)
  end

  context 'and has 2 suggestions for speed improvement' do
    let(:result) do
      double(
        success?: false,
        stdout: <<-MSG
spec/models/product_spec.rb
Using each_with_index is slower than while loop. Occurred at lines: 52.
1 files inspected, 1 offense detected
spec/models/book_spec.rb
Using each_with_index is slower than while loop. Occurred at lines: 32.
1 files inspected, 1 offense detected
spec/models/blog_spec.rb
Using each_with_index is slower than while loop. Occurred at lines: 12.
2 files inspected, 0 offense detected
        MSG
      )
    end

    it { should warn }
  end

  context 'and has single suggestion for speed improvement' do
    let(:result) do
      double(
        success?: false,
        stdout: <<-MSG
spec/models/product_spec.rb
Using each_with_index is slower than while loop. Occurred at lines: 52.
1 files inspected, 1 offense detected
        MSG
      )
    end

    it { should warn }
  end

  context 'and does not have any suggestion' do
    let(:result) do
      double(success?: true, stdout: '55 files inspected, 0 offenses detected')
    end

    it { should pass }
  end
end
