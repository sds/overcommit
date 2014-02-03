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
end
