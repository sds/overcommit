# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::LicenseHeader do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  around do |example|
    repo do
      example.run
    end
  end

  context 'when license file is missing' do
    it { should fail_hook }
  end

  context 'when license file exists' do
    let(:license_contents) { <<-LICENSE }
    Look at me
    I'm a license
    LICENSE

    let(:file) { 'some-file.txt' }

    before do
      File.open('LICENSE.txt', 'w') { |f| f.write(license_contents) }
      subject.stub(:applicable_files).and_return([file])
    end

    context 'when all files contain the license header' do
      before do
        File.open(file, 'w') do |f|
          license_contents.split("\n").each do |line|
            f.puts("// #{line}")
          end
          f.write('And some text')
        end
      end

      it { should pass }
    end

    context 'when a file is missing a license header' do
      before do
        File.open(file, 'w') { |f| f.write('Some text without a license') }
      end

      it { should fail_hook }
    end
  end
end
