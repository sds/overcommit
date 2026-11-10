# frozen_string_literal: true

require 'spec_helper'

{
  W3cCss: ['CSSValidator', { 'language' => 'en', 'profile' => 'css3', 'warn_level' => 2 },
           { set_language!: ['en'], set_profile!: ['css3'], set_warn_level!: [2] }],
  W3cHtml: ['MarkupValidator', { 'charset' => 'utf-8', 'doctype' => 'HTML5' },
            { set_charset!: ['utf-8', true], set_doctype!: ['HTML5', true], set_debug!: [] }],
}.each do |hook_name, (validator_name, options, setters)|
  describe Overcommit::Hook::PreCommit.const_get(hook_name) do
    let(:config) { Overcommit::ConfigurationLoader.default_configuration }
    let(:hook) { described_class.new(config, double('context')) }
    let(:validator_class) { double('validator class') }
    let(:validator) { double('validator') }
    let(:connection) do
      { 'validator_uri' => 'https://validator.example', 'proxy_server' => 'proxy.example',
        'proxy_port' => 8080, 'proxy_user' => 'user', 'proxy_pass' => 'password' }
    end

    before do
      stub_const("W3CValidators::#{validator_name}", validator_class)
      stub_const('W3CValidators::ParsingError', Class.new(StandardError))
      stub_const('W3CValidators::ValidatorUnavailable', Class.new(StandardError))
      allow(config).to receive(:for_hook).and_return(connection.merge(options))
      allow(hook).to receive(:applicable_files).and_return(['file'])
      allow(validator).to receive(:validate_file).with('file').
        and_return(double('results', errors: [], warnings: []))
    end

    it 'configures and reuses the validator across runs' do
      expect(validator_class).to receive(:new).once.
        with(connection.transform_keys(&:to_sym)).and_return(validator)
      setters.each do |method, args|
        expect(validator).to receive(method).once.with(*(args.empty? ? [no_args] : args))
      end
      expect(hook.run).to eq([])
      expect(hook.run).to eq([])
    end
  end
end
