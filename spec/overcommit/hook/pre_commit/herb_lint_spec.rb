# frozen_string_literal: true

require 'spec_helper'

describe Overcommit::Hook::PreCommit::HerbLint do
  let(:config) { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.html.erb file2.html.erb])
  end

  context 'when herb-lint exits successfully' do
    before do
      result = double('result')
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    it { should pass }
  end

  context 'when herb-lint exits unsucessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(:stdout).and_return(<<-MSG)
{
  "offenses": [
    {
      "filename": "/home/tom/src/osm/rails/app/views/accounts/terms/_terms.html.erb",
      "message": "Avoid using instance variables in partials. Pass `@text` as a local variable instead.",
      "location": {
        "start": {
          "line": 2,
          "column": 6
        },
        "end": {
          "line": 2,
          "column": 11
        }
      },
      "severity": "error",
      "code": "erb-no-instance-variables-in-partials",
      "source": "Herb Linter"
    },
    {
      "filename": "/home/tom/src/osm/rails/app/views/accounts/terms/_terms.html.erb",
      "message": "Avoid using instance variables in partials. Pass `@text` as a local variable instead.",
      "location": {
        "start": {
          "line": 3,
          "column": 6
        },
        "end": {
          "line": 3,
          "column": 11
        }
      },
      "severity": "error",
      "code": "erb-no-instance-variables-in-partials",
      "source": "Herb Linter"
    }
  ],
  "summary": {
    "filesChecked": 263,
    "filesWithOffenses": 1,
    "totalErrors": 2,
    "totalWarnings": 0,
    "totalInfo": 0,
    "totalHints": 0,
    "totalIgnored": 1,
    "totalOffenses": 2,
    "ruleCount": 94
  },
  "timing": null,
  "completed": true,
  "clean": false,
  "message": null
}
        MSG
      end

      it { should fail_hook }
    end
  end
end
