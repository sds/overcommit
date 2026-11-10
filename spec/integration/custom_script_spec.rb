# frozen_string_literal: true

require 'spec_helper'
require 'json'

describe 'post-rewrite CustomScript input' do
  around do |example|
    repo do
      echo({ 'PostRewrite' => {
        'ALL' => { 'enabled' => false },
        'CustomScript' => {
          'enabled' => true,
          'command' => [Gem.ruby, 'record-rewrite.rb']
        }
      } }.to_yaml, '.overcommit.yml')
      echo(<<~RUBY, 'record-rewrite.rb')
        require 'json'
        STDIN.binmode
        input = STDIN.read
        # Like git-branchless, accept an empty stream but reject a blank record.
        input.each_line do |line|
          abort 'Invalid rewrite line' unless line.strip.match?(/\\A[0-9a-f]{40} [0-9a-f]{40}\\z/)
        end
        File.write('received.json', JSON.generate(args: ARGV, bytes: input.bytes))
      RUBY
      install_overcommit_hooks
      example.run
    end
  end

  pair = "#{'a' * 40} #{'b' * 40}"
  ['', pair, "#{pair}\n", "#{pair}\n#{pair}\n", "#{pair}\r\n"].each do |input|
    it "forwards the rewrite type and exact input bytes for #{input.inspect}" do
      result = Overcommit::Subprocess.spawn(
        [Gem.ruby, '.git/hooks/post-rewrite', 'rebase'], input: input,
      )

      expect(result.status).to eq(0), result.stdout + result.stderr
      JSON.parse(File.read('received.json')).should == { 'args' => ['rebase'],
                                                         'bytes' => input.bytes }
    end
  end
end
