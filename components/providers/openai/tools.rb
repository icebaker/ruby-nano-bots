# frozen_string_literal: true

require_relative '../../embedding'
require_relative '../../../logic/cartridge/safety'

require 'concurrent'

module NanoBot
  module Components
    module Providers
      class OpenAI < Base
        module Tools
          def self.apply(cartridge, function_cartridge, tools, feedback)
            prepared_tools = NanoBot::Logic::OpenAI::Tools.prepare(function_cartridge, tools)

            # TODO: Confirm before starting futures.
            futures = prepared_tools.map do |tool|
              Concurrent::Promises.future { process!(tool, feedback, function_cartridge, cartridge) }
            end

            results = Concurrent::Promises.zip(*futures).value!

            results.map do |applied_tool|
              {
                who: 'tool',
                message: applied_tool[:output],
                meta: { id: applied_tool[:id], name: applied_tool[:name] }
              }
            end
          end

          def self.process!(tool, feedback, _function_cartridge, cartridge)
            feedback.call(
              { should_be_stored: false,
                interaction: { who: 'AI', message: nil, meta: {
                  tool: { action: 'call', id: tool[:id], name: tool[:name], parameters: tool[:parameters] }
                } } }
            )

            call = {
              parameters: %w[parameters],
              values: [tool[:parameters]],
              safety: { sandboxed: Logic::Cartridge::Safety.sandboxed?(cartridge) }
            }

            if %i[fennel lua clojure].count { |key| !tool[:source][key].nil? } > 1
              raise StandardError, 'conflicting tools'
            end

            if !tool[:source][:fennel].nil?
              call[:source] = tool[:source][:fennel]
              tool[:output] = Components::Embedding.fennel(**call)
            elsif !tool[:source][:clojure].nil?
              call[:source] = tool[:source][:clojure]
              tool[:output] = Components::Embedding.clojure(**call)
            elsif !tool[:source][:lua].nil?
              call[:source] = tool[:source][:lua]
              tool[:output] = Components::Embedding.lua(**call)
            else
              raise 'missing source code'
            end

            feedback.call(
              { should_be_stored: false,
                interaction: { who: 'AI', message: nil, meta: {
                  tool: {
                    action: 'response', id: tool[:id], name: tool[:name],
                    parameters: tool[:parameters], output: tool[:output]
                  }
                } } }
            )

            tool
          end
        end
      end
    end
  end
end
