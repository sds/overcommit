# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::BundleAudit do
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
      subject.stub(:execute).with(%w[git ls-files -o -i --exclude-standard -- Gemfile.lock]).
        and_return(double(stdout: ''))
      subject.stub(:execute).with(%w[bundle-audit]).and_return(result)
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

    context 'and it reports bundle up to date' do
      let(:result) do
        double(success?: true, stdout: 'No vulnerabilities found')
      end

      it { should pass }
    end
  end
end
