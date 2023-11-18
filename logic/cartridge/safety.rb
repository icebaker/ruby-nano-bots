# frozen_string_literal: true

require_relative 'fetch'

module NanoBot
  module Logic
    module Cartridge
      module Safety
        def self.sandboxed?(cartridge)
          sandboxed = Fetch.cascate(cartridge, [%i[safety functions sandboxed]])
          return true if sandboxed.nil?

          sandboxed
        end
      end
    end
  end
end
