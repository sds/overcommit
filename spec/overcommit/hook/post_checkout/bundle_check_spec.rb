require 'spec_helper'

describe Overcommit::Hook::PostCheckout::BundleCheck do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  let(:subject) { described_class.new(config, context) }
  let(:added_file) { "gem 'some-gem'" }

  around do |example|
    repo do
      `git commit --allow-empty -m "Initial commit"`
      File.open(added_file_name, 'w') { |f| f.write(added_file) }
      `git add #{added_file_name}`
      `git commit -m "File added"`
      example.run
    end
  end

  before do
    context.stub(:previous_head).and_return(`git rev-parse HEAD~`.chomp)
    context.stub(:new_head).and_return(`git rev-parse HEAD`.chomp)
  end

  context "when relevant files haven't changed" do
    let(:added_file_name) { 'some-file.txt' }

    it { should pass }
  end

  context 'when relevant files have changed' do
    let(:added_file_name) { 'Gemfile' }

    before do
      subject.stub(:dependencies_satisfied?).and_return(satisfied)
    end

    context 'and the dependencies are satisfied' do
      let(:satisfied) { true }

      it { should pass }
    end

    context 'and the dependencies are not satisfied' do
      let(:satisfied) { false }

      it { should warn }
    end
  end
end
