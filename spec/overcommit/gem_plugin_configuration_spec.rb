# frozen_string_literal: true

require 'spec_helper'

describe 'gem plugin configuration' do
  let(:hash) do
    {
      'gem_plugins' => { 'Company' => 'company-hooks' },
      'PreCommit' => {
        'ALL' => { 'enabled' => false, 'description' => 'Shared' },
        'Company::Check' => { 'enabled' => true },
        'Company::AuthorName' => { 'enabled' => true },
        'Company::Disabled' => { 'enabled' => false },
        'CustomCommand' => { 'enabled' => true, 'command' => ['echo'] },
        'AuthorName' => { 'enabled' => true },
      },
    }
  end
  let(:config) { Overcommit::Configuration.new(hash) }
  let(:context) { double(hook_type_name: 'pre_commit', hook_class_name: 'PreCommit') }

  it 'does not discover, activate, or require gems during validation or discovery' do
    expect(Gem::Specification).not_to receive(:find_by_name)
    expect(config.enabled_gem_hooks(context)).to eq(%w[Company::Check Company::AuthorName])
  end

  it 'keeps gem hooks out of built-in and ad hoc discovery even when names overlap' do
    expect(config.enabled_builtin_hooks(context)).to eq(['AuthorName'])
    expect(config.enabled_ad_hoc_hooks(context)).to eq(['CustomCommand'])
  end

  it 'combines namespaced hook settings with the ALL defaults' do
    expect(config.for_hook('Company::Check', 'PreCommit')).
      to include('description' => 'Shared', 'enabled' => true)
  end

  it 'supports both namespaced and ordinary hooks in colon-separated SKIP lists' do
    config.apply_environment!(context, 'SKIP' => 'Company::Check:AuthorName')
    expect(config.for_hook('Company::Check', 'PreCommit')['skip']).to eq(true)
    expect(config.for_hook('AuthorName', 'PreCommit')['skip']).to eq(true)
  end

  it 'supports ONLY without splitting namespaces' do
    config.apply_environment!(context, 'ONLY' => 'Company::Check')
    expect(config.for_hook('Company::Check', 'PreCommit')['skip']).to eq(false)
    expect(config.for_hook('AuthorName', 'PreCommit')['skip']).to eq(true)
  end

  it 'does not silently enable undeclared namespaces through environment filters' do
    config.apply_environment!(context, 'ONLY' => 'Unknown::Check')
    expect(config.for_hook('Unknown::Check', 'PreCommit')['skip']).to eq(true)
  end

  [true, false, [], ['company-hooks'], 'company-hooks',
   { 'bad_namespace' => 'company-hooks' }, { 'company' => 'company-hooks' },
   { 'Company::Nested' => 'company-hooks' }, { 'Company' => nil },
   { 'Company' => ['company-hooks'] }, { 'Company' => '../company-hooks' },
   { 'Company' => 'company-hooks; code' }].each do |declaration|
    it "rejects malformed gem declarations: #{declaration.inspect}" do
      hash['gem_plugins'] = declaration
      expect { config }.to raise_error(Overcommit::Exceptions::ConfigurationError, /gem_plugins/)
    end
  end

  %w[Company::bad_name Company::Nested::Check ::Check Company::123 Company::].each do |name|
    it "rejects invalid qualified hook names: #{name}" do
      hash['PreCommit'][name] = { 'enabled' => true }
      expect { config }.to raise_error(Overcommit::Exceptions::ConfigurationError, /invalid names/)
    end
  end

  it 'allows an empty mapping to disable all gem sources' do
    hash['gem_plugins'] = {}
    expect { config }.not_to raise_error
  end
end
