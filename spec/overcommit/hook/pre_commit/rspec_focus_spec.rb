require 'spec_helper'

describe Overcommit::Hook::PreCommit::RspecFocus do
  let(:config)      { Overcommit::ConfigurationLoader.default_configuration }
  let(:context)     { double('context') }
  let(:staged_file) { 'my_spec.rb' }

  subject           { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return([staged_file])
  end

  around do |example|
    repo do
      File.open(staged_file, 'w') { |f| f.write(contents) }
      `git add #{staged_file}`
      example.run
    end
  end

  context 'when file contains a long form focused in Ruby 1.8 syntax' do
    let(:contents) do """
      it 'does things', :focused=>true do
        # spec code
      end
    """
    end

    it { should fail_hook }
  end

  context 'when file contains a short form focused in Ruby 1.8 syntax' do
    let(:contents) do """
      it 'does things', :focus=>true do
        # spec code
      end
    """
    end

    it { should fail_hook }
  end

  context 'when file contains a long form focused in Ruby 1.9 syntax' do
    let(:contents) do """
      it 'does things', focused: true do
        # spec code
      end
    """
    end

    it { should fail_hook }
  end

  context 'when file contains a short form focused in Ruby 1.9 syntax' do
    let(:contents) do """
      it 'does things', focus: true do
        # spec code
      end
    """
    end

    it { should fail_hook }
  end

  context 'when file contains a long form focused meta key' do
    let(:contents) do """
      it 'does things', :focused do
        # spec code
      end
    """
    end

    it { should fail_hook }
  end

  context 'when file contains a short form focused meta key' do
    let(:contents) do """
      it 'does things', :focus do
        # spec code
      end
    """
    end

    it { should fail_hook }
  end

  context 'when file does not contain any kind of focused' do
    let(:contents) do """
      it 'does things' do
        # spec code
      end
    """
    end

    it { should pass }
  end
end
