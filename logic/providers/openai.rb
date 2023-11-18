# frozen_string_literal: true

require 'json'

module NanoBot
  module Logic
    module OpenAI
      def self.prepare_tools(cartridge, tools)
        applies = []
        tools.each do |tool|
          cartridge.each do |candidate|
            next unless candidate[:type] == 'function' &&
                        tool[:type] == candidate[:type] &&
                        tool[:function][:name] == candidate[:name]

            source = {}

            source[:fennel] = candidate[:fennel] if candidate[:fennel]
            source[:lua] = candidate[:lua] if candidate[:lua]

            applies << {
              name: tool[:function][:name],
              type: candidate[:type],
              parameters: JSON.parse(tool[:function][:arguments]),
              source:
            }
          end
        end

        applies
      end

      def self.adapt_tool(cartridge)
        raise 'unsupported tool' if cartridge[:type] != 'function'

        adapted = {
          type: 'function',
          function: {
            name: cartridge[:name], description: cartridge[:description],
            parameters: { type: 'object', properties: {} }
          }
        }

        properties = adapted[:function][:parameters][:properties]

        cartridge[:parameters].each do |parameter|
          key = parameter[:name].to_sym
          properties[key] = {}
          properties[key][:type] = parameter[:type] || 'string'
          properties[key][:description] = parameter[:description] if parameter[:description]
        end

        adapted
      end
    end
  end
end
