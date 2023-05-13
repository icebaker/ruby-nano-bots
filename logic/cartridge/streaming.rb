# frozen_string_literal: true

require_relative '../helpers/hash'

module NanoBot
  module Logic
    module Cartridge
      module Streaming
        def self.enabled?(cartridge, interface)
          return false if Helpers::Hash.fetch(cartridge, %i[provider settings stream]) == false

          specific_interface = Helpers::Hash.fetch(cartridge, [:interfaces, interface, :output, :stream])

          return specific_interface unless specific_interface.nil?

          interface = Helpers::Hash.fetch(cartridge, %i[interfaces output stream])

          return interface unless interface.nil?

          true
        end
      end
    end
  end
end
