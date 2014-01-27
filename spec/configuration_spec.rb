require 'spec_helper'

describe Overcommit::Configuration do
  describe '#new' do
    context 'when hash keys contain nils' do
      let(:hash) { { 'some_key' => nil } }

      it 'converts nils to empty hashes'
    end
  end
end
