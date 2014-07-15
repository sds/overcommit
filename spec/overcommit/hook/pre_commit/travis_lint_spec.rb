require 'spec_helper'

describe Overcommit::Hook::PreCommit::TravisLint do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }
  let(:staged_file) { '.travis.yml' }

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

  context 'when travis-yaml is not installed' do
    let(:contents) { 'language: ruby' }

    before do
      subject.stub(:require_travis_yaml).and_raise(LoadError)
    end

    it { should warn }
  end

  context 'when travis-yaml has no warnings' do
    let(:contents) { 'language: ruby' }

    it { should pass }
  end

  context 'when travis-yaml has warnings' do
    let(:contents) do
      <<-EOS
      language: foo
      bar: baz
      notifications:
        email:
          illegal: key
      EOS
    end

    it { should fail_hook(/#{staged_file}/m) }

    it { should fail_hook(/language section - illegal value "foo"/) }

    it { should fail_hook(/notifications.email section/) }

    it { should fail_hook(/unexpected key "bar"/) }
  end
end
