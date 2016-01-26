require 'spec_helper'

describe Overcommit::MessageProcessor do
  # Shorthand to make writing these tests a little more sane
  EMH = Overcommit::MessageProcessor::ERRORS_MODIFIED_HEADER + "\n"
  WMH = Overcommit::MessageProcessor::WARNINGS_MODIFIED_HEADER + "\n"
  EUH = Overcommit::MessageProcessor::ERRORS_UNMODIFIED_HEADER + "\n"
  WUH = Overcommit::MessageProcessor::WARNINGS_UNMODIFIED_HEADER + "\n"
  EGH = Overcommit::MessageProcessor::ERRORS_GENERIC_HEADER + "\n"
  WGH = Overcommit::MessageProcessor::WARNINGS_GENERIC_HEADER + "\n"

  let(:config) { double('config') }
  let(:context) { double('context') }
  let(:hook) { Class.new(Overcommit::Hook::Base).new(config, context) }

  subject { described_class.new(hook, setting) }

  describe '#hook_result' do
    let(:modified_lines) { {} }
    subject { super().hook_result(messages) }

    before do
      config.stub(:for_hook).and_return({})

      modified_lines.each do |file, lines|
        hook.stub(:modified_lines_in_file).
             with(file).
             and_return(lines.to_set)
      end
    end

    def error(file = nil, line = nil)
      Overcommit::Hook::Message.new(:error, file, line, 'Error')
    end

    def warning(file = nil, line = nil)
      Overcommit::Hook::Message.new(:warning, file, line, 'Warning')
    end

    context 'when there are no messages' do
      let(:messages) { [] }

      context 'and setting is `report`' do
        let(:setting) { 'report' }
        it { should == [:pass, ''] }
      end

      context 'and setting is `warn`' do
        let(:setting) { 'warn' }
        it { should == [:pass, ''] }
      end

      context 'and setting is `ignore`' do
        let(:setting) { 'ignore' }
        it { should == [:pass, ''] }
      end
    end

    context 'when there are errors on modified lines' do
      let(:modified_lines) { { 'a.txt' => [2] } }
      let(:messages) { [error('a.txt', 2)] }

      context 'and setting is `report`' do
        let(:setting) { 'report' }
        it { should == [:fail, "#{EMH}Error\n"] }
      end

      context 'and setting is `warn`' do
        let(:setting) { 'warn' }
        it { should == [:fail, "#{EMH}Error\n"] }
      end

      context 'and setting is `ignore`' do
        let(:setting) { 'ignore' }
        it { should == [:fail, "#{EMH}Error\n"] }
      end
    end

    context 'when there are errors on unmodified lines' do
      let(:modified_lines) { { 'a.txt' => [3] } }
      let(:messages) { [error('a.txt', 2)] }

      context 'and setting is `report`' do
        let(:setting) { 'report' }
        it { should == [:fail, "#{EUH}Error\n"] }
      end

      context 'and setting is `warn`' do
        let(:setting) { 'warn' }
        it { should == [:warn, "#{EUH}Error\n"] }
      end

      context 'and setting is `ignore`' do
        let(:setting) { 'ignore' }
        it { should == [:pass, ''] }
      end
    end

    context 'when there are warnings on modified lines' do
      let(:modified_lines) { { 'a.txt' => [2] } }
      let(:messages) { [warning('a.txt', 2)] }

      context 'and setting is `report`' do
        let(:setting) { 'report' }
        it { should == [:warn, "#{WMH}Warning\n"] }
      end

      context 'and setting is `warn`' do
        let(:setting) { 'warn' }
        it { should == [:warn, "#{WMH}Warning\n"] }
      end

      context 'and setting is `ignore`' do
        let(:setting) { 'ignore' }
        it { should == [:warn, "#{WMH}Warning\n"] }
      end
    end

    context 'when there are warnings on unmodified lines' do
      let(:modified_lines) { { 'a.txt' => [3] } }
      let(:messages) { [warning('a.txt', 2)] }

      context 'and setting is `report`' do
        let(:setting) { 'report' }
        it { should == [:warn, "#{WUH}Warning\n"] }
      end

      context 'and setting is `warn`' do
        let(:setting) { 'warn' }
        it { should == [:warn, "#{WUH}Warning\n"] }
      end

      context 'and setting is `ignore`' do
        let(:setting) { 'ignore' }
        it { should == [:pass, ''] }
      end
    end

    context 'when there are errors and warnings on modified lines' do
      let(:modified_lines) { { 'a.txt' => [2], 'b.txt' => [3, 4] } }
      let(:messages) { [warning('a.txt', 2), error('b.txt', 4)] }

      context 'and setting is `report`' do
        let(:setting) { 'report' }
        it { should == [:fail, "#{EMH}Error\n#{WMH}Warning\n"] }
      end

      context 'and setting is `warn`' do
        let(:setting) { 'warn' }
        it { should == [:fail, "#{EMH}Error\n#{WMH}Warning\n"] }
      end

      context 'and setting is `ignore`' do
        let(:setting) { 'ignore' }
        it { should == [:fail, "#{EMH}Error\n#{WMH}Warning\n"] }
      end
    end

    context 'when there are errors and warnings on unmodified lines' do
      let(:modified_lines) { { 'a.txt' => [2], 'b.txt' => [3, 4] } }
      let(:messages) { [warning('a.txt', 3), error('b.txt', 5)] }

      context 'and setting is `report`' do
        let(:setting) { 'report' }
        it { should == [:fail, "#{EUH}Error\n#{WUH}Warning\n"] }
      end

      context 'and setting is `warn`' do
        let(:setting) { 'warn' }
        it { should == [:warn, "#{EUH}Error\n#{WUH}Warning\n"] }
      end

      context 'and setting is `ignore`' do
        let(:setting) { 'ignore' }
        it { should == [:pass, ''] }
      end
    end

    context 'when there are errors and warnings on modified/unmodified lines' do
      let(:modified_lines) { { 'a.txt' => [2], 'b.txt' => [3, 4] } }

      let(:messages) do
        [
          warning('a.txt', 3),
          warning('b.txt', 3),
          error('a.txt', 2),
          error('b.txt', 5),
        ]
      end

      context 'and setting is `report`' do
        let(:setting) { 'report' }

        it do
          should == [:fail, "#{EMH}Error\n#{WMH}Warning\n" \
                            "#{EUH}Error\n#{WUH}Warning\n"]
        end
      end

      context 'and setting is `warn`' do
        let(:setting) { 'warn' }

        it do
          should == [:fail, "#{EMH}Error\n#{WMH}Warning\n" \
                            "#{EUH}Error\n#{WUH}Warning\n"]
        end
      end

      context 'and setting is `ignore`' do
        let(:setting) { 'ignore' }
        it { should == [:fail, "#{EMH}Error\n#{WMH}Warning\n"] }
      end
    end

    context 'when there are generic errors' do
      let(:messages) { [error] * 2 }
      let(:setting) { 'report' }

      it { should == [:fail, "Error\nError\n"] }
    end

    context 'when there are generic warnings' do
      let(:messages) { [warning] * 2 }
      let(:setting) { 'report' }

      it { should == [:warn, "Warning\nWarning\n"] }
    end

    context 'when there are generic errors and warnings' do
      let(:messages) { [warning, error] * 2 }
      let(:setting) { 'report' }

      it { should == [:fail, "Warning\nError\nWarning\nError\n"] }
    end

    context 'when there are errors and warnings on modified/unmodified lines' do
      let(:modified_lines) { { 'a.txt' => [2], 'b.txt' => [3, 4] } }
      let(:setting) { 'report' }

      let(:messages) do
        [
          warning('a.txt', 3),
          warning('b.txt', 3),
          error('a.txt', 2),
          error('b.txt', 5),
        ]
      end

      context 'and there are generic errors before them' do
        let(:messages) { [error] * 2 + super() }

        it do
          should == [:fail, "#{EGH}Error\nError\n" \
                            "#{EMH}Error\n#{WMH}Warning\n" \
                            "#{EUH}Error\n#{WUH}Warning\n"]
        end
      end

      context 'and there are generic warnings before them' do
        let(:messages) { [warning] * 2 + super() }

        it do
          should == [:fail, "#{WGH}Warning\nWarning\n" \
                            "#{EMH}Error\n#{WMH}Warning\n" \
                            "#{EUH}Error\n#{WUH}Warning\n"]
        end
      end

      context 'and there are generic errors after them' do
        let(:messages) { super() + [error] * 2 }

        it do
          should == [:fail, "#{EGH}Error\nError\n" \
                            "#{EMH}Error\n#{WMH}Warning\n" \
                            "#{EUH}Error\n#{WUH}Warning\n"]
        end
      end

      context 'and there are generic warnings after them' do
        let(:messages) { super() + [warning] * 2 }

        it do
          should == [:fail, "#{WGH}Warning\nWarning\n" \
                            "#{EMH}Error\n#{WMH}Warning\n" \
                            "#{EUH}Error\n#{WUH}Warning\n"]
        end
      end
    end
  end
end
