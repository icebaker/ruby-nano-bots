# frozen_string_literal: true

require_relative '../../embedding'

require 'concurrent'

module NanoBot
  module Components
    module Providers
      class OpenAI < Base
        module Tools
          def self.apply(cartridge, tools, feedback)
            prepared_tools = NanoBot::Logic::OpenAI::Tools.prepare(cartridge, tools)

            futures = prepared_tools.map do |tool|
              Concurrent::Promises.future { process!(tool, feedback) }
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

          def self.process!(tool, feedback)
            feedback.call(
              { should_be_stored: false,
                interaction: { who: 'AI', message: nil, meta: {
                  tool: { action: 'call', id: tool[:id], name: tool[:name], parameters: tool[:parameters] }
                } } }
            )

            call = { parameters: %w[parameters], values: [tool[:parameters]], safety: false }

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
