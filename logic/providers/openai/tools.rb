# frozen_string_literal: true

require 'json'
require 'babosa'

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
              candidate_key = candidate[:name].to_slug.normalize.gsub('-', '_')
              tool_key = tool[:function][:name].to_slug.normalize.gsub('-', '_')

              next unless candidate_key == tool_key

              source = {}

              source[:clojure] = candidate[:clojure] if candidate[:clojure]
              source[:fennel] = candidate[:fennel] if candidate[:fennel]
              source[:lua] = candidate[:lua] if candidate[:lua]

              applies << {
                id: tool[:id],
                label: candidate[:name],
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
          output = {
            type: 'function',
            function: {
              name: cartridge[:name], description: cartridge[:description]
            }
          }

          output[:function][:parameters] = (cartridge[:parameters] || { type: 'object', properties: {} })

          output
        end
      end
    end
  end
end
