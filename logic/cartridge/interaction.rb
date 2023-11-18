# frozen_string_literal: true

require_relative 'affixes'
require_relative 'adapters'

module NanoBot
  module Logic
    module Cartridge
      module Interaction
        def self.input(cartridge, interface, content)
          lua = Adapter.expression(cartridge, interface, :input, :lua)
          fennel = Adapter.expression(cartridge, interface, :input, :fennel)
          clojure = Adapter.expression(cartridge, interface, :input, :clojure)

          prefix = Affixes.get(cartridge, interface, :input, :prefix)
          suffix = Affixes.get(cartridge, interface, :input, :suffix)

          { content:, prefix:, suffix:, lua:, fennel:, clojure: }
        end

        def self.output(cartridge, interface, result, streaming, _finished)
          if streaming
            result[:message] = { content: result[:message], lua: nil, fennel: nil, clojure: nil }
            return result
          end

          lua = Adapter.expression(cartridge, interface, :output, :lua)
          fennel = Adapter.expression(cartridge, interface, :output, :fennel)
          clojure = Adapter.expression(cartridge, interface, :output, :clojure)

          result[:message] = { content: result[:message], lua:, fennel:, clojure: }

          result
        end
      end
    end
  end
end
