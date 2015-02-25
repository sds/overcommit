require 'spec_helper'

describe Overcommit::Hook::PreCommit::Scalastyle do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.scala file2.scala])
  end

  context 'when scalastyle exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    context 'with no errors or warnings' do
      before do
        result.stub(:stdout).and_return([
          'Processed 1 file(s)',
          'Found 0 errors',
          'Found 0 warnings',
          'Finished in 490 ms'
        ].join("\n"))
      end

      it { should pass }
    end

    context 'and it reports a warning' do
      before do
        result.stub(:stdout).and_return([
          'warning file=file1.scala message=Use : Unit = for procedures line=1 column=15',
          'Processed 1 file(s)',
          'Found 0 errors',
          'Found 1 warnings',
          'Finished in 490 ms'
        ].join("\n"))

        subject.stub(:modified_lines_in_file).and_return([2, 3])
      end

      it { should warn }
    end
  end

  context 'when scalastyle exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return([
          'error file=file1.scala message=Use : Unit = for procedures line=1 column=15',
          'Processed 1 file(s)',
          'Found 1 errors',
          'Found 0 warnings',
          'Finished in 490 ms'
        ].join("\n"))

        subject.stub(:modified_lines_in_file).and_return([1, 2])
      end

      it { should fail_hook }
    end
  end
end
