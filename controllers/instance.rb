# frozen_string_literal: true

require 'yaml'

require_relative '../logic/helpers/hash'
require_relative '../components/provider'
require_relative '../components/storage'
require_relative './interfaces/repl'
require_relative './session'

module NanoBot
  module Controllers
    class Instance
      def initialize(cartridge_path:, state: nil)
        load_cartridge!(cartridge_path)

        provider = Components::Provider.new(@cartridge[:provider])

        @session = Session.new(provider:, cartridge: @cartridge, state:)
      end

      def debug
        @session.debug
      end

      def eval(input)
        @session.evaluate_and_print(input, mode: 'eval')
      end

      def repl
        Interfaces::REPL.start(@cartridge, @session)
      end

      private

      def load_cartridge!(path)
        @cartridge = Logic::Helpers::Hash.symbolize_keys(
          YAML.safe_load(
            File.read(Components::Storage.cartridge_path(path)),
            permitted_classes: [Symbol]
          )
        )

        inject_environment_variables!(@cartridge)
      end

      def inject_environment_variables!(node)
        case node
        when Hash
          node.each do |key, value|
            node[key] = inject_environment_variables!(value)
          end
        when Array
          node.each_with_index do |value, index|
            node[index] = inject_environment_variables!(value)
          end
        when String
          node.start_with?('ENV') ? ENV.fetch(node.sub(/^ENV./, ''), nil) : node
        else
          node
        end
      end
    end
  end
end
