# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::BundleOutdated do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  context 'when Gemfile.lock is ignored' do
    around do |example|
      repo do
        touch 'Gemfile.lock'
        echo('Gemfile.lock', '.gitignore')
        `git add .gitignore`
        `git commit -m "Ignore Gemfile.lock"`
        example.run
      end
    end

    it { should pass }
  end

  context 'when Gemfile.lock is not ignored' do
    around do |example|
      repo do
        example.run
      end
    end

    before do
      subject.stub(:execute).with(%w[git ls-files -o -i --exclude-standard]).
                             and_return(double(stdout: ''))
      subject.stub(:execute).with(%w[bundle outdated --strict --parseable]).
                             and_return(result)
    end

    context 'and it reports some outdated gems' do
      let(:result) do
        double(stdout: <<-MSG
Warning: the running version of Bundler is older than the version that created the lockfile. We suggest you upgrade to the latest version of Bundler by running `gem install bundler`.
airbrake (newest 5.3.0, installed 5.2.3, requested ~> 5.0)
aws-sdk (newest 2.3.3, installed 2.3.1, requested ~> 2)
font-awesome-rails (newest 4.6.2.0, installed 4.6.1.0)
mechanize (newest 2.7.4, installed 2.1.1)
minimum-omniauth-scaffold (newest 0.4.3, installed 0.4.1)
airbrake-ruby (newest 1.3.0, installed 1.2.4)
aws-sdk-core (newest 2.3.3, installed 2.3.1)
aws-sdk-resources (newest 2.3.3, installed 2.3.1)
config (newest 1.1.1, installed 1.1.0)
ruby_parser (newest 3.8.2, installed 3.8.1)
        MSG
        )
      end

      it { should warn }
    end

    context 'and it reports bundle up to date' do
      let(:result) do
        double(stdout: <<-MSG
Warning: the running version of Bundler is older than the version that created the lockfile. We suggest you upgrade to the latest version of Bundler by running `gem install bundler`.
        MSG
        )
      end

      it { should pass }
    end
  end
end
