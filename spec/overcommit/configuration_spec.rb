require 'spec_helper'

describe Overcommit::Configuration do
  let(:hash) { {} }
  let(:config) { described_class.new(hash) }

  before do
    Overcommit::Utils.instance_variable_set(:@repo_root, nil)
  end

  describe '#new' do
    let(:internal_hash) { config.instance_variable_get(:@hash) }
    subject { config }

    context 'when no configuration exists for a hook type' do
      it 'creates sections for those hook types' do
        internal_hash.should have_key 'pre_commit'
      end

      it 'creates the special ALL section for the hook type' do
        internal_hash['pre_commit'].should have_key 'ALL'
      end
    end

    context 'when keys with empty values exist' do
      let(:hash) do
        {
          'pre_commit' => {
            'SomeHook' => nil
          },
        }
      end

      it 'converts the values to empty hashes' do
        internal_hash['pre_commit']['SomeHook'].should == {}
      end
    end
  end

  describe '#plugin_directory' do
    let(:hash) { { 'plugin_directory' => 'some-directory' } }
    subject { config.plugin_directory }

    around do |example|
      repo do
        example.run
      end
    end

    it { should == File.expand_path('some-directory') }
  end

  describe '#enabled_builtin_hooks' do
    let(:hash) do
      {
        'pre_commit' => {
          'SomeHook' => nil,
          'SomeOtherHook' => {
            'enabled' => false
          },
        }
      }
    end

    subject { config.enabled_builtin_hooks('pre_commit') }

    it 'includes hooks that are not disabled' do
      subject.should == ['SomeHook']
    end
  end

  describe '#for_hook' do
    let(:hash) do
      {
        'pre_commit' => {
          'ALL' => {
            'required' => false,
          },
          'SomeHook' => {
            'enabled' => true,
            'quiet' => false,
          }
        }
      }
    end

    subject { config.for_hook('SomeHook', 'pre_commit') }

    it 'returns the subset of the config for the specified hook' do
      subject['enabled'].should be_true
      subject['quiet'].should be_false
    end

    it 'merges the the hook config with the ALL section' do
      subject['required'].should be_false
    end
  end

  describe '#merge' do
    let(:parent_config) { described_class.new(parent) }
    let(:child_config) { described_class.new(child) }
    subject { parent_config.merge(child_config) }

    context 'when parent and child are empty' do
      let(:parent) { {} }
      let(:child) { {} }

      it 'returns a config equivalent to both' do
        subject.should == parent_config
        subject.should == child_config
      end
    end

    context 'when parent and child are the same' do
      let(:parent) { child }

      let(:child) do
        {
          'plugin_directory' => 'some-directory',
          'pre-commit' => {
            'SomeHook' => {
              'enabled' => false,
            }
          },
        }
      end

      it 'returns a config equivalent to both' do
        subject.should == parent_config
        subject.should == child_config
      end
    end

    context 'when parent item contains a hash' do
      let(:parent) { { 'pre_commit' => { 'SomeHook' => { 'some-value' => 1 } } } }

      context 'and child item contains a different hash under the same key' do
        let(:child) { { 'pre_commit' => { 'SomeOtherHook' => { 'something' => 2 } } } }

        it 'merges the hashes together' do
          subject.for_hook('SomeHook', 'pre_commit').should == { 'some-value' => 1 }
          subject.for_hook('SomeOtherHook', 'pre_commit').should == { 'something' => 2 }
        end
      end

      context 'and child item contains a hash under a different key' do
        let(:child) { { 'commit_msg' => { 'SomeHook' => { 'some-value' => 2 } } } }

        it 'appends the item to the parent array' do
          subject.for_hook('SomeHook', 'pre_commit').should == { 'some-value' => 1 }
          subject.for_hook('SomeHook', 'commit_msg').should == { 'some-value' => 2 }
        end
      end
    end

    context 'when parent item contains an array' do
      let(:parent) { { 'pre_commit' => { 'SomeHook' => { 'list' => [1, 2, 3] } } } }

      context 'and child item contains an array' do
        let(:child) { { 'pre_commit' => { 'SomeHook' => { 'list' => [4, 5] } } } }

        it 'concatenates the arrays together' do
          subject.for_hook('SomeHook', 'pre_commit')['list'] == [1, 2, 3, 4, 5]
        end
      end

      context 'and child item contains a single item' do
        let(:child) { { 'pre_commit' => { 'SomeHook' => { 'list' => 4 } } } }

        it 'appends the item to the parent array' do
          subject.for_hook('SomeHook', 'pre_commit')['list'] == [1, 2, 3, 4]
        end
      end
    end
  end
end
