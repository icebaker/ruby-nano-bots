# frozen_string_literal: true

require 'rainbow'

require_relative '../../logic/cartridge/tools'
require_relative '../../components/embedding'

module NanoBot
  module Controllers
    module Interfaces
      module Tool
        def self.adapt(feedback, adapter)
          call = {
            parameters: %w[id name parameters parameters-as-json output],
            values: [
              feedback[:id], feedback[:name], feedback[:parameters],
              feedback[:parameters].to_json,
              feedback[:output]
            ],
            safety: false
          }

          raise StandardError, 'conflicting adapters' if %i[fennel lua clojure].count { |key| !adapter[key].nil? } > 1

          if adapter[:fennel]
            call[:source] = adapter[:fennel]
            Components::Embedding.fennel(**call)
          elsif adapter[:clojure]
            call[:source] = adapter[:clojure]
            Components::Embedding.clojure(**call)
          elsif adapter[:lua]
            call[:parameters] = %w[id name parameters parameters_as_json output]
            call[:source] = adapter[:lua]
            Components::Embedding.lua(**call)
          else
            raise 'missing handler for adapter'
          end
        end

        def self.dispatch_feedback(session, cartridge, mode, feedback)
          enabled = Logic::Cartridge::Tools.feedback?(cartridge, mode.to_sym, feedback[:action].to_sym)

          return unless enabled

          color = Logic::Cartridge::Tools.fetch_from_interface(
            cartridge, mode.to_sym, feedback[:action].to_sym, [:color]
          )

          adapter = Tool.adapter(cartridge, mode, feedback)

          if %i[fennel lua clojure].any? { |key| !adapter[key].nil? }
            message = adapt(feedback, adapter)
          else
            message = "(#{feedback[:name]} #{feedback[:parameters].to_json})"

            message += " =>\n#{feedback[:output]}" if feedback[:action].to_sym == :response
          end

          message = "#{adapter[:prefix]}#{message}#{adapter[:suffix]}"

          session.print(color.nil? ? message : Rainbow(message).send(color))
        end

        def self.adapter(cartridge, mode, feedback)
          prefix = Logic::Cartridge::Tools.fetch_from_interface(
            cartridge, mode.to_sym, feedback[:action].to_sym, [:prefix]
          )

          suffix = Logic::Cartridge::Tools.fetch_from_interface(
            cartridge, mode.to_sym, feedback[:action].to_sym, [:suffix]
          )

          fennel = Logic::Cartridge::Tools.fetch_from_interface(
            cartridge, mode.to_sym, feedback[:action].to_sym, %i[adapter fennel]
          )

          lua = Logic::Cartridge::Tools.fetch_from_interface(
            cartridge, mode.to_sym, feedback[:action].to_sym, %i[adapter lua]
          )

          clojure = Logic::Cartridge::Tools.fetch_from_interface(
            cartridge, mode.to_sym, feedback[:action].to_sym, %i[adapter clojure]
          )

          { prefix:, suffix:, fennel:, lua:, clojure: }
        end
      end
    end
  end
end
