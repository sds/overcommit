require 'spec_helper'

describe Overcommit::Logger do
  let(:io) { StringIO.new }
  let(:output) { io.string }
  subject { described_class.new(io) }

  describe '.silent' do
    subject { described_class.silent }

    it 'does not output anything' do
      capture_stdout { subject.log('Something') }.should be_empty
    end
  end

  describe '#partial' do
    subject { super().partial('Hello') }

    it 'writes to the output stream' do
      subject
      output.should_not be_empty
    end

    it 'does not append a newline' do
      subject
      output[-1].should_not == "\n"
    end
  end

  describe '#log' do
    subject { super().log('Hello') }

    it 'writes to the output stream' do
      subject
      output.should_not be_empty
    end

    it 'appends a newline' do
      subject
      output[-1].should == "\n"
    end
  end

  shared_examples_for 'colorized output' do
    subject { super().send(method, 'Hello') }

    it 'writes to the output stream' do
      subject
      output.should_not be_empty
    end

    it 'appends a newline' do
      subject
      output[-1].should == "\n"
    end

    context 'when the output stream is a TTY' do
      before do
        io.stub(:tty?).and_return(true)
      end

      it 'includes the color escape sequence' do
        subject
        output.should include "\033[#{color_code}m"
      end

      it 'ends with the color reset sequence' do
        subject
        output.should end_with "[0m\n"
      end
    end

    context 'when the output stream is not a TTY' do
      before do
        io.stub(:tty?).and_return(false)
      end

      it 'omits the color escape sequence' do
        subject
        output.should_not include "\033"
      end
    end
  end

  describe '#bold' do
    it_behaves_like 'colorized output' do
      let(:method) { :bold }
      let(:color_code) { '1;37' }
    end
  end

  describe '#error' do
    it_behaves_like 'colorized output' do
      let(:method) { :error }
      let(:color_code) { 31 }
    end
  end

  describe '#success' do
    it_behaves_like 'colorized output' do
      let(:method) { :success }
      let(:color_code) { 32 }
    end
  end

  describe '#warning' do
    it_behaves_like 'colorized output' do
      let(:method) { :warning }
      let(:color_code) { 33 }
    end
  end

  describe '#notice' do
    it_behaves_like 'colorized output' do
      let(:method) { :notice }
      let(:color_code) { '1;33' }
    end
  end
end
