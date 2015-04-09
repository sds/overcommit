# encoding: utf-8
require 'spec_helper'

describe Overcommit::Hook::CommitMsg::SpellCheck do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:uncommented_commit_msg_file)
    subject.stub(:execute).and_return(result)
  end

  context 'when hunspell exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
    end

    context 'with no misspellings' do
      before do
        result.stub(:stdout).and_return(<<-EOS)
@(#) International Ispell Version 3.2.06 (but really Hunspell 1.3.3)
*
*
*
        EOS
      end

      it { should pass }
    end

    context 'with misspellings' do
      context 'with suggestions' do
        before do
          result.stub(:stdout).and_return(<<-EOS)
@(#) International Ispell Version 3.2.06 (but really Hunspell 1.3.3)
*
& msg 10 4: MSG, mag, ms, mg, meg, mtg, mug, mpg, mfg, ms g
*
          EOS
        end

        it { should warn(/^Potential misspelling: \w+. Suggestions: .+$/) }
      end

      context 'with no suggestions' do
        before do
          result.stub(:stdout).and_return(<<-EOS)
@(#) International Ispell Version 3.2.06 (but really Hunspell 1.3.3)
*
# supercalifragilisticexpialidocious 4
*
          EOS
        end

        it { should warn(/^Potential misspelling: \w+.$/) }
      end
    end
  end

  context 'when hunspell exits unsuccessfully' do
    let(:result) { double('result') }

    before do
      result.stub(success?: false, stderr: <<-EOS)
Can't open affix or dictionary files for dictionary named "foo".
      EOS
    end

    it { should fail_hook }
  end
end
