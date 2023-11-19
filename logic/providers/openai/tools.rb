# frozen_string_literal: true

require 'json'

require_relative '../../helpers/hash'

module NanoBot
  module Logic
    module OpenAI
      module Tools
        def self.prepare(cartridge, tools)
          applies = []

          tools = Marshal.load(Marshal.dump(tools))

          tools.each do |tool|
            tool = Helpers::Hash.symbolize_keys(tool)

            cartridge.each do |candidate|
              next unless tool[:function][:name] == candidate[:name]

              source = {}

              source[:clojure] = candidate[:clojure] if candidate[:clojure]
              source[:fennel] = candidate[:fennel] if candidate[:fennel]
              source[:lua] = candidate[:lua] if candidate[:lua]

              applies << {
                id: tool[:id],
                name: tool[:function][:name],
                type: 'function',
                parameters: JSON.parse(tool[:function][:arguments]),
                source:
              }
            end
          end

          raise 'missing tool' if applies.size != tools.size

          applies
        end

        def self.adapt(cartridge)
          {
            type: 'function',
            function: {
              name: cartridge[:name], description: cartridge[:description],
              parameters: cartridge[:parameters]
            }
          }
        end
      end
    end
  end
end
