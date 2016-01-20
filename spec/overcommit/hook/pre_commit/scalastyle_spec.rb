require 'spec_helper'

describe Overcommit::Hook::PreCommit::Scalastyle do
  let(:config)  { Overcommit::ConfigurationLoader.default_configuration }
  let(:context) { double('context') }
  subject { described_class.new(config, context) }

  before do
    subject.stub(:applicable_files).and_return(%w[file1.scala file2.scala])
  end

  context 'when scalastyle exits successfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(true)
      subject.stub(:execute).and_return(result)
    end

    context 'with no errors or warnings' do
      before do
        result.stub(stderr: '', stdout: normalize_indent(<<-OUT))
          Processed 1 file(s)
          Found 0 errors
          Found 0 warnings
          Finished in 490 ms
        OUT
      end

      it { should pass }
    end

    context 'and it reports a warning' do
      before do
        result.stub(stderr: '', stdout: normalize_indent(<<-OUT))
          warning file=file1.scala message=Use : Unit = for procedures line=1 column=15
          Processed 1 file(s)
          Found 0 errors
          Found 1 warnings
          Finished in 490 ms
        OUT
      end

      it { should warn }
    end
  end

  context 'when scalastyle exits unsuccessfully' do
    let(:result) { double('result') }

    before do
      result.stub(:success?).and_return(false)
      subject.stub(:execute).and_return(result)
    end

    context 'and it reports an error' do
      before do
        result.stub(stderr: '', stdout: normalize_indent(<<-OUT))
          error file=file1.scala message=Use : Unit = for procedures line=1 column=15
          Processed 1 file(s)
          Found 1 errors
          Found 0 warnings
          Finished in 490 ms
        OUT
      end

      it { should fail_hook }
    end

    context 'with a usage message' do
      before do
        result.stub(stderr: '', stdout: normalize_indent(<<-OUT))
          scalastyle 0.7.0
          Usage: scalastyle [options] <source directory>
           -c, --config FILE               configuration file (required)
           -v, --verbose true|false        verbose output
           -q, --quiet true|false          be quiet
               --xmlOutput FILE            write checkstyle format output to this file
               --xmlEncoding STRING        encoding to use for the xml file
               --inputEncoding STRING      encoding for the source files
           -w, --warnings true|false       fail if there are warnings
           -e, --externalJar FILE          jar containing custom rules
        OUT
      end

      it { should fail_hook }
    end

    context 'with a runtime error' do
      before do
        result.stub(stdout: '', stderr: normalize_indent(<<-ERR))
          Exception in thread "main" java.io.FileNotFoundException: scalastyle-config.xml (No such file or directory)
                  at java.io.FileInputStream.open0(Native Method)
                  at java.io.FileInputStream.open(FileInputStream.java:195)
                  at java.io.FileInputStream.<init>(FileInputStream.java:138)
                  at java.io.FileInputStream.<init>(FileInputStream.java:93)
                  at scala.xml.Source$.fromFile(XML.scala:22)
                  at scala.xml.factory.XMLLoader$class.loadFile(XMLLoader.scala:50)
                  at scala.xml.XML$.loadFile(XML.scala:60)
                  at org.scalastyle.ScalastyleConfiguration$.readFromXml(ScalastyleConfiguration.scala:87)
                  at org.scalastyle.Main$.execute(Main.scala:106)
                  at org.scalastyle.Main$.main(Main.scala:95)
                  at org.scalastyle.Main.main(Main.scala)
        ERR
      end

      it { should fail_hook }
    end
  end
end
