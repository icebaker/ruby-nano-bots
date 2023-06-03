# frozen_string_literal: true

require_relative '../../logic/cartridge/affixes'

module NanoBot
  module Controllers
    module Interfaces
      module Eval
        def self.evaluate(input, cartridge, session, mode)
          prefix = Logic::Cartridge::Affixes.get(cartridge, mode.to_sym, :output, :prefix)
          suffix = Logic::Cartridge::Affixes.get(cartridge, mode.to_sym, :output, :suffix)

          session.print(prefix) unless prefix.nil?

          session.evaluate_and_print(input, mode:)

          session.print(suffix) unless suffix.nil?
        end
      end
    end
  end
end
