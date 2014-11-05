require 'spec_helper'

describe Overcommit::ConfigurationLoader do
  describe '.load_repo_config' do
    subject { described_class.load_repo_config }

    context 'when repo does not contain a configuration file' do
      around do |example|
        repo do
          example.run
        end
      end

      it 'returns the default configuration' do
        subject.should == described_class.default_configuration
      end
    end

    context 'when repo contains a configuration file' do
      let(:config_contents) { <<-CFG }
        plugin_directory: 'some-directory'
      CFG

      around do |example|
        repo do
          File.open('.overcommit.yml', 'w') { |f| f.write(config_contents) }
          example.run
        end
      end

      it 'loads the file' do
        described_class.should_receive(:load_file).
                        with(File.expand_path('.overcommit.yml'))
        subject
      end

      it 'merges the loaded file with the default configuration' do
        subject.plugin_directory.should == File.expand_path('some-directory')
      end
    end
  end
end
