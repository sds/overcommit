# frozen_string_literal: true

require 'overcommit/hook/shared/pronto'

module Overcommit::Hook::PrePush
  # Runs `pronto`
  #
  # @see https://github.com/mmozuras/pronto
  class Pronto < Base
    include Overcommit::Hook::Shared::Pronto
  end
end
