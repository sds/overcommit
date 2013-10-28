require 'spec_helper'

describe Overcommit::GitHook::RubyStyle do
  let(:ruby_style) { subject }

  describe '#possible_files' do
    it 'returns all possible paths for the rubocop config file' do
      result = ruby_style.send(:possible_files, 'foo/bar')
      result.map { |path| path.to_s }.
        should eq %w[foo/bar/.rubocop.yml foo/.rubocop.yml .rubocop.yml]
    end
  end

  describe '#rubocop_yml_for' do
    let(:staged_file) { stub(:original_path => 'some/dir') }
    let(:existing) { stub(:file? => true) }
    let(:non_existing) { stub(:file? => false) }

    it 'returns the file that exists' do
      ruby_style.should_receive(:possible_files).
                 with('some/dir').
                 and_return([existing, non_existing])
      ruby_style.send(:rubocop_yml_for, staged_file).should eq existing
    end

    it 'returns nil if none of the files exist' do
      ruby_style.stub(:possible_files => [non_existing])
      ruby_style.send(:rubocop_yml_for, staged_file).should be_nil
    end
  end

  describe '#rubocop_config_mapping' do
    it 'inserts the staged files into a hash' do
      file = stub(:path => 'foobar/file.x')
      ruby_style.stub(:staged => [file])
      ruby_style.should_receive(:rubocop_yml_for).with(file).and_return('boing')
      ruby_style.send(:rubocop_config_mapping).should eq('boing' => ['foobar/file.x'])
    end
  end
end
