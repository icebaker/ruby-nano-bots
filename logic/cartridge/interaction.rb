# frozen_string_literal: true

require 'sweet-moon'

require_relative './affixes'
require_relative './adapters'

module NanoBot
  module Logic
    module Cartridge
      module Interaction
        def self.input(cartridge, interface, content)
          lua = Adapter.expression(cartridge, interface, :input, :lua)
          fennel = Adapter.expression(cartridge, interface, :input, :fennel)

          prefix = Affixes.get(cartridge, interface, :input, :prefix)
          suffix = Affixes.get(cartridge, interface, :input, :suffix)

          { content:, prefix:, suffix:, lua:, fennel: }
        end

        def self.output(cartridge, interface, result, streaming, _finished)
          if streaming
            result[:message] = { content: result[:message], lua: nil, fennel: nil }
            return result
          end

          lua = Adapter.expression(cartridge, interface, :output, :lua)
          fennel = Adapter.expression(cartridge, interface, :output, :fennel)

          result[:message] = { content: result[:message], lua:, fennel: }

          result
        end
      end
    end
  end
end
