require 'spec_helper'

describe Overcommit::GitHook::Whitespace do
  let(:staged_filename) { 'filename.txt' }

  around do |example|
    repo do
      File.open(staged_filename, 'w') { |f| f.write(file_contents) }
      `git add #{staged_filename}`
      example.run
    end
  end

  context 'when file contains hard tabs' do
    let(:file_contents) { "Some\thard\ttabs" }
    it { should stop }
  end

  context 'when file has no hard tabs' do
    let(:file_contents) { 'Just some text' }
    it { should pass }
  end
end
