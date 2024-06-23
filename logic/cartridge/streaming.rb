# frozen_string_literal: true

require_relative '../helpers/hash'

module NanoBot
  module Logic
    module Cartridge
      module Streaming
        def self.enabled?(cartridge, interface)
          provider_stream = case Helpers::Hash.fetch(cartridge, %i[provider id])
                            when 'openai', 'mistral', 'anthropic', 'cohere', 'ollama'
                              Helpers::Hash.fetch(cartridge, %i[provider settings stream])
                            when 'google', 'maritaca'
                              Helpers::Hash.fetch(cartridge, %i[provider options stream])
                            end

          return false if provider_stream == false

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
