require 'spec_helper'

describe Overcommit::Configuration do
  describe '#templates' do
    subject { described_class.instance.templates }

    it { should_not be_nil }

    it { should have_key 'default' }

    it { should have_key 'all' }
  end

  describe '#desired_plugins' do
    subject do
      described_class.instance.desired_plugins.map do |file|
        ::File.basename(file, '.rb')
      end
    end

    before do
      # Pretend we're running the pre_commit hook
      Overcommit::Utils.stub(:hook_name).and_return('pre_commit')
    end

    context 'with no excludes' do
      its(:count) { should be > 0 }

      it { should include 'js_syntax' }
    end

    context 'with excludes' do
      before do
        described_class.instance.stub(:repo_settings).and_return(
          'excludes' => {
            'pre_commit' => %w[js_syntax]
          }
        )
      end

      it { should_not include 'js_syntax' }
    end
  end
end
