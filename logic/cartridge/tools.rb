# frozen_string_literal: true

require_relative 'fetch'
require_relative 'affixes'
require_relative 'adapters'

module NanoBot
  module Logic
    module Cartridge
      module Tools
        def self.fetch_from_interface(cartridge, interface, action, path)
          Fetch.cascate(cartridge, [
                          [:interfaces, interface, :tools, action].concat(path),
                          [:interfaces, :tools, action].concat(path),
                          %i[interfaces tools].concat(path)
                        ])
        end

        def self.feedback?(cartridge, interface, action)
          Fetch.cascate(cartridge, [
                          [:interfaces, interface, :tools, action, :feedback],
                          [:interfaces, :tools, action, :feedback],
                          %i[interfaces tools feedback]
                        ])
        end

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
