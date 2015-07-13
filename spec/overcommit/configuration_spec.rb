require 'spec_helper'

describe Overcommit::Configuration do
  let(:hash) { {} }
  let(:config) { described_class.new(hash) }

  describe '#new' do
    let(:internal_hash) { config.instance_variable_get(:@hash) }
    subject { config }

    context 'when no configuration exists for a hook type' do
      it 'creates sections for those hook types' do
        internal_hash.should have_key 'PreCommit'
      end

      it 'creates the special ALL section for the hook type' do
        internal_hash['PreCommit'].should have_key 'ALL'
      end
    end

    context 'when keys with empty values exist' do
      let(:hash) do
        {
          'PreCommit' => {
            'SomeHook' => nil
          },
        }
      end

      it 'converts the values to empty hashes' do
        internal_hash['PreCommit']['SomeHook'].should == {}
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
        'PreCommit' => {
          'AuthorName' => nil,
          'AuthorEmail' => {
            'enabled' => false
          },
        }
      }
    end

    let(:context) { double('context') }
    subject { config.enabled_builtin_hooks(context) }

    before do
      context.stub(hook_class_name: 'PreCommit',
                   hook_type_name: 'pre_commit')
    end

    it 'excludes hooks that are not explicitly enabled' do
      subject.should_not include 'AuthorName'
    end
  end

  describe '#for_hook' do
    let(:hash) do
      {
        'PreCommit' => {
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

    subject { config.for_hook('SomeHook', 'PreCommit') }

    it 'returns the subset of the config for the specified hook' do
      subject['enabled'].should == true
      subject['quiet'].should == false
    end

    it 'merges the the hook config with the ALL section' do
      subject['required'].should == false
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
      let(:parent) { { 'PreCommit' => { 'SomeHook' => { 'some-value' => 1 } } } }

      context 'and child item contains a different hash under the same key' do
        let(:child) { { 'PreCommit' => { 'SomeOtherHook' => { 'something' => 2 } } } }

        it 'merges the hashes together' do
          subject.for_hook('SomeHook', 'PreCommit').should include('some-value' => 1)
          subject.for_hook('SomeOtherHook', 'PreCommit').should include('something' => 2)
        end
      end

      context 'and child item contains a hash under a different key' do
        let(:child) { { 'CommitMsg' => { 'SomeHook' => { 'some-value' => 2 } } } }

        it 'appends the item to the parent array' do
          subject.for_hook('SomeHook', 'PreCommit').should include('some-value' => 1)
          subject.for_hook('SomeHook', 'CommitMsg').should include('some-value' => 2)
        end
      end

      context 'and child item contains a hash under the ALL key' do
        let(:child) do
          {
            'PreCommit' => {
              'ALL' => { 'some-value' => 2 },
              'SomeOtherHook' => { 'some-value' => 3 },
            },
          }
        end

        it 'overrides the value in the parent item' do
          subject.for_hook('SomeHook', 'PreCommit').should include('some-value' => 2)
        end

        it 'does not override the value in other child items' do
          subject.for_hook('SomeOtherHook', 'PreCommit').should include('some-value' => 3)
        end

        context 'and the parent contains a hash under the ALL key' do
          let(:parent) do
            super().tap do |hash|
              hash['PreCommit']['ALL'] = { 'some-value' => 1 }
            end
          end

          it 'overrides the ALL value in the parent item' do
            subject.for_hook('SomeHook', 'PreCommit').should include('some-value' => 2)
          end

          it 'does not override the value in other child items' do
            subject.for_hook('SomeOtherHook', 'PreCommit').should include('some-value' => 3)
          end
        end
      end
    end

    context 'when parent item contains an array' do
      let(:parent) { { 'PreCommit' => { 'SomeHook' => { 'list' => [1, 2, 3] } } } }

      context 'and child item contains an array' do
        let(:child) { { 'PreCommit' => { 'SomeHook' => { 'list' => [4, 5] } } } }

        it 'overrides the value in the parent item' do
          subject.for_hook('SomeHook', 'PreCommit')['list'].should == [4, 5]
        end
      end

      context 'and child item contains a single item' do
        let(:child) { { 'PreCommit' => { 'SomeHook' => { 'list' => 4 } } } }

        it 'overrides the value in the parent item' do
          subject.for_hook('SomeHook', 'PreCommit')['list'].should == 4
        end
      end
    end
  end

  describe '#apply_environment!' do
    let(:hash) { {} }
    let(:config) { described_class.new(hash) }
    let!(:old_config) { described_class.new(hash.dup) }
    let(:context) { double('context') }
    subject { config }

    before do
      context.stub(:hook_type_name).and_return('pre_commit')
      context.stub(:hook_class_name).and_return('PreCommit')
      config.apply_environment!(context, env)
    end

    context 'when no hooks are requested to be skipped' do
      let(:env) { {} }

      it 'does nothing to the configuration' do
        subject.should == old_config
      end
    end

    context 'when a non-existent hook is requested to be skipped' do
      let(:env) { { 'SKIP' => 'SomeMadeUpHook' } }

      it 'does nothing to the configuration' do
        subject.should == old_config
      end
    end

    context 'when an existing hook is requested to be skipped' do
      let(:env) { { 'SKIP' => 'AuthorName' } }

      it 'sets the skip option of the hook to true' do
        subject.for_hook('AuthorName', 'PreCommit')['skip'].should == true
      end

      context 'and the hook is spelt with underscores' do
        let(:env) { { 'SKIP' => 'author_name' } }

        it 'sets the skip option of the hook to true' do
          subject.for_hook('AuthorName', 'PreCommit')['skip'].should == true
        end
      end

      context 'and the hook is spelt with hyphens' do
        let(:env) { { 'SKIP' => 'author-name' } }

        it 'sets the skip option of the hook to true' do
          subject.for_hook('AuthorName', 'PreCommit')['skip'].should == true
        end
      end
    end

    context 'when the word "all" is included in the skip list' do
      let(:env) { { 'SKIP' => 'all' } }

      it 'sets the skip option of the ALL section to true' do
        subject.for_hook('ALL', 'PreCommit')['skip'].should == true
      end

      context 'and "all" is capitalized' do
        let(:env) { { 'SKIP' => 'ALL' } }

        it 'sets the skip option of the special ALL config to true' do
          subject.for_hook('ALL', 'PreCommit')['skip'].should == true
        end
      end
    end

    context 'when hooks are filtered using the ONLY environment variable' do
      let(:env) { { 'ONLY' => 'AuthorName' } }

      it 'sets the skip option of the ALL section to true' do
        subject.for_hook('ALL', 'PreCommit')['skip'].should == true
      end

      it 'sets the skip option of the filtered hook to false' do
        subject.for_hook('AuthorName', 'PreCommit')['skip'].should == false
      end
    end
  end
end
