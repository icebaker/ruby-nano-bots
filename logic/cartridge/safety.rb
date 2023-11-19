# frozen_string_literal: true

require_relative 'fetch'

module NanoBot
  module Logic
    module Cartridge
      module Safety
        def self.default_answer(cartridge)
          default = Fetch.cascate(cartridge, [%i[interfaces tools confirm default]])
          return [] if default.nil?

          default
        end

        def self.yeses(cartridge)
          yeses_values = Fetch.cascate(cartridge, [%i[interfaces tools confirm yeses]])
          return [] if yeses_values.nil?

          yeses_values
        end

        def self.confirmable?(cartridge)
          confirmable = Fetch.cascate(cartridge, [%i[safety tools confirmable]])
          return true if confirmable.nil?

          confirmable
        end

        def self.sandboxed?(cartridge)
          sandboxed = Fetch.cascate(cartridge, [%i[safety functions sandboxed]])
          return true if sandboxed.nil?

          sandboxed
        end
      end
    end
  end
end
