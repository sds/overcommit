# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::BundleAudit do
  let(:config) do
    Overcommit::ConfigurationLoader.default_configuration.merge(
      Overcommit::Configuration.new('PreCommit' => { 'BundleAudit' => hook_config })
    )
  end
  let(:hook_config) { {} }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  it 'defaults to not updating the advisory database' do
    subject.config['update'].should == false
  end

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

    context 'when updating the advisory database is enabled' do
      let(:hook_config) { { 'update' => true } }

      before do
        subject.stub(:execute).and_call_original
        subject.should_not_receive(:execute).with(%w[bundle-audit --update])
      end

      it { should pass }
    end
  end

  context 'when Gemfile.lock is not ignored' do
    let(:audit_command) { %w[bundle-audit] }

    around do |example|
      repo do
        example.run
      end
    end

    before do
      subject.stub(:execute).with(%w[git ls-files -o -i --exclude-standard -- Gemfile.lock]).
        and_return(double(stdout: ''))
      subject.stub(:execute).with(audit_command).and_return(result)
    end

    context 'and it reports some outdated gems' do
      let(:result) do
        double(
          success?: false,
          stdout: <<-MSG
Name: rest-client
Version: 1.6.9
Advisory: CVE-2015-1820
Criticality: Unknown
URL: https://github.com/rest-client/rest-client/issues/369
Title: rubygem-rest-client: session fixation vulnerability via Set-Cookie headers in 30x redirection responses
Solution: upgrade to >= 1.8.0
Name: rest-client
Version: 1.6.9
Advisory: CVE-2015-3448
Criticality: Unknown
URL: http://www.osvdb.org/show/osvdb/117461
Title: Rest-Client Gem for Ruby logs password information in plaintext
Solution: upgrade to >= 1.7.3
Vulnerabilities found!
          MSG
        )
      end

      it { should warn }
    end

    let(:result) do
      double(
        success?: false,
        stdout: <<-MSG
Insecure Source URI found: git://github.com/xxx/overcommit.git
Vulnerabilities found!
        MSG
      )
    end

    it { should warn }

    context 'when updating the advisory database is enabled' do
      let(:audit_command) { %w[bundle-audit --update] }
      let(:hook_config) { { 'update' => true } }

      it { should warn(result.stdout) }

      context 'and no vulnerabilities are found' do
        let(:result) { double(success?: true, stdout: 'No vulnerabilities found') }

        it { should pass }
      end

      context 'with a custom command and flags' do
        let(:audit_command) { %w[bundle exec bundle-audit check --ignore CVE-2020-12345 --update] }

        let(:hook_config) do
          super().merge('command' => %w[bundle exec bundle-audit],
                        'flags' => %w[check --ignore CVE-2020-12345])
        end

        it { should warn(result.stdout) }
      end
    end

    context 'and it reports bundle up to date' do
      let(:result) do
        double(success?: true, stdout: 'No vulnerabilities found')
      end

      it { should pass }
    end
  end
end
