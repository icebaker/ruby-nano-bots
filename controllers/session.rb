# frozen_string_literal: true

require 'babosa'

require 'fileutils'

require_relative '../logic/helpers/hash'
require_relative '../logic/cartridge/streaming'
require_relative '../logic/cartridge/interaction'
require_relative '../components/storage'
require_relative '../components/adapter'

module NanoBot
  module Controllers
    STREAM_TIMEOUT_IN_SECONDS = 5

    class Session
      attr_accessor :stream

      def initialize(provider:, cartridge:, state: nil, stream: $stdout)
        @stream = stream
        @provider = provider
        @cartridge = cartridge

        @stateless = state.nil? || state.strip == '-' || state.strip.empty?

        if @stateless
          @state = { history: [] }
        else
          @state_path = Components::Storage.build_path_and_ensure_state_file!(
            state.strip, @cartridge
          )
          @state = load_state
        end
      end

      def state
        { state: { path: @state_path, content: @state } }
      end

      def load_state
        @state = Logic::Helpers::Hash.symbolize_keys(JSON.parse(File.read(@state_path)))
      end

      def store_state!
        File.write(@state_path, JSON.generate(@state))
      end

      def boot(mode:)
        return unless Logic::Helpers::Hash.fetch(@cartridge, %i[behaviors boot instruction])

        behavior = Logic::Helpers::Hash.fetch(@cartridge, %i[behaviors boot]) || {}

        input = { behavior:, history: [] }

        process(input, mode:)
      end

      def evaluate_and_print(message, mode:)
        behavior = Logic::Helpers::Hash.fetch(@cartridge, %i[behaviors interaction]) || {}

        @state[:history] << {
          who: 'user',
          message: Components::Adapter.apply(
            :input, Logic::Cartridge::Interaction.input(@cartridge, mode.to_sym, message)
          )
        }

        input = { behavior:, history: @state[:history] }

        process(input, mode:)
      end

      def process(input, mode:)
        interface = Logic::Helpers::Hash.fetch(@cartridge, [:interfaces, mode.to_sym]) || {}

        streaming = Logic::Cartridge::Streaming.enabled?(@cartridge, mode.to_sym)

        input[:interface] = interface

        updated_at = Time.now

        ready = false
        @provider.evaluate(input) do |output, finished|
          output = Logic::Cartridge::Interaction.output(
            @cartridge, mode.to_sym, output, streaming, finished
          )

          output[:message] = Components::Adapter.apply(:output, output[:message])

          updated_at = Time.now

          if finished
            @state[:history] << output
            self.print(output[:message]) unless streaming
            ready = true
            flush
          elsif streaming
            self.print(output[:message])
          end
        end

        until ready
          seconds = (Time.now - updated_at).to_i
          raise StandardError, 'The stream has become unresponsive.' if seconds >= STREAM_TIMEOUT_IN_SECONDS
        end

        store_state! unless @stateless
      end

      def flush
        @stream.flush
      end

      def print(content)
        @stream.write(content)
      end
    end
  end
end
