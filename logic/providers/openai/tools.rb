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
              next unless (
                            candidate[:type].nil? ||
                            (candidate[:type] == 'function' && tool[:type] == candidate[:type])
                          ) && tool[:function][:name] == candidate[:name]

              source = {}

              source[:clojure] = candidate[:clojure] if candidate[:clojure]
              source[:fennel] = candidate[:fennel] if candidate[:fennel]
              source[:lua] = candidate[:lua] if candidate[:lua]

              applies << {
                id: tool[:id],
                name: tool[:function][:name],
                type: candidate[:type] || 'function',
                parameters: JSON.parse(tool[:function][:arguments]),
                source:
              }
            end
          end

          applies
        end

        def self.adapt(cartridge)
          raise 'unsupported tool' if cartridge[:type] != 'function' && !cartridge[:type].nil?

          adapted = {
            type: cartridge[:type] || 'function',
            function: {
              name: cartridge[:name], description: cartridge[:description],
              parameters: { type: 'object', properties: {} }
            }
          }

          properties = adapted[:function][:parameters][:properties]

          adapted[:function][:parameters][:required] = cartridge[:required] if cartridge[:required]

          cartridge[:parameters]&.each do |parameter|
            key = parameter[:name].to_sym
            properties[key] = {}
            properties[key][:type] = parameter[:type] || 'string'
            properties[key][:description] = parameter[:description] if parameter[:description]
            properties[key][:items] = parameter[:items].slice(:type) if parameter[:items]
          end

          adapted
        end
      end
    end
  end
end
