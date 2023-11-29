# frozen_string_literal: true

require 'babosa'

require 'fileutils'
require 'rainbow'

require_relative '../logic/helpers/hash'
require_relative '../logic/cartridge/safety'
require_relative '../logic/cartridge/streaming'
require_relative '../logic/cartridge/interaction'
require_relative '../logic/cartridge/fetch'
require_relative 'interfaces/tools'
require_relative '../components/storage'
require_relative '../components/adapter'
require_relative '../components/crypto'

module NanoBot
  module Controllers
    STREAM_TIMEOUT_IN_SECONDS = 5
    INFINITE_LOOP_PREVENTION = 10

    class Session
      attr_accessor :stream

      def initialize(provider:, cartridge:, state: nil, stream: $stdout, environment: {})
        @stream = stream
        @provider = provider
        @cartridge = cartridge
        @environment = environment

        @stateless = state.nil? || state.strip == '-' || state.strip.empty?

        if @stateless
          @state_expression = nil
          @state = { history: [] }
        else
          @state_expression = state.strip
          @state_path = Components::Storage.build_path_and_ensure_state_file!(
            @state_expression, @cartridge, environment: @environment
          )

          @state = load_state
        end
      end

      def state_base_path
        @state_base_path ||= Components::Storage.build_base_path_and_ensure_state_directory!(
            @state_expression, @cartridge, environment: @environment
          )
      end

      def state
        { state: { path: @state_path, content: @state } }
      end

      def load_state
        @state = Logic::Helpers::Hash.symbolize_keys(
          JSON.parse(Components::Crypto.decrypt(File.read(@state_path)))
        )
      end

      def store_state!
        File.write(@state_path, Components::Crypto.encrypt(JSON.generate(@state)))
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
          mode: mode.to_s,
          input: message,
          message: Components::Adapter.apply(
            Logic::Cartridge::Interaction.input(@cartridge, mode.to_sym, message), @cartridge
          )
        }

        input = { behavior:, history: @state[:history] }

        process(input, mode:)
      end

      def process(input, mode:)
        interface = Logic::Helpers::Hash.fetch(@cartridge, [:interfaces, mode.to_sym]) || {}

        input[:interface] = interface
        input[:tools] = @cartridge[:tools]

        needs_another_round = true

        rounds = 0

        while needs_another_round
          needs_another_round = process_interaction(input, mode:)
          rounds += 1
          raise StandardError, 'infinite loop prevention' if rounds > INFINITE_LOOP_PREVENTION
        end
      end

      def process_interaction(input, mode:)
        prefix = Logic::Cartridge::Affixes.get(@cartridge, mode.to_sym, :output, :prefix)
        suffix = Logic::Cartridge::Affixes.get(@cartridge, mode.to_sym, :output, :suffix)

        color = Logic::Cartridge::Fetch.cascate(
          @cartridge, [[:interfaces, mode.to_sym, :output, :color], %i[interfaces output color]]
        )

        color = color.to_sym if color

        streaming = Logic::Cartridge::Streaming.enabled?(@cartridge, mode.to_sym)

        updated_at = Time.now

        ready = false

        needs_another_round = false

        @provider.evaluate(input, streaming, @cartridge) do |feedback|
          needs_another_round = true if feedback[:needs_another_round]

          updated_at = Time.now

          if feedback[:interaction] &&
             feedback.dig(:interaction, :meta, :tool, :action) &&
             feedback[:interaction][:meta][:tool][:action] == 'confirming'
            Interfaces::Tool.confirming(self, @cartridge, mode, feedback[:interaction][:meta][:tool])
          else

            if feedback[:interaction] && feedback.dig(:interaction, :meta, :tool, :action)
              Interfaces::Tool.dispatch_feedback(
                self, @cartridge, mode, feedback[:interaction][:meta][:tool]
              )
            end

            if feedback[:interaction]
              event = Marshal.load(Marshal.dump(feedback[:interaction]))
              event[:mode] = mode.to_s
              event[:output] = nil

              if feedback[:interaction][:who] == 'AI' && feedback[:interaction][:message]
                event[:output] = feedback[:interaction][:message]
                unless streaming
                  output = Logic::Cartridge::Interaction.output(
                    @cartridge, mode.to_sym, feedback[:interaction], streaming, feedback[:finished]
                  )
                  output[:message] = Components::Adapter.apply(output[:message], @cartridge)
                  event[:output] = (output[:message]).to_s
                end
              end

              @state[:history] << event if feedback[:should_be_stored]

              if event[:output] && ((!feedback[:finished] && streaming) || (!streaming && feedback[:finished]))
                self.print(color ? Rainbow(event[:output]).send(color) : event[:output])
              end

              # The `print` function already outputs a prefix and a suffix, so
              # we should add them afterwards to avoid printing them twice.
              event[:output] = "#{prefix}#{event[:output]}#{suffix}"
            end

            if feedback[:finished]
              flush
              ready = true
            end
          end
        end

        until ready
          seconds = (Time.now - updated_at).to_i
          raise StandardError, 'The stream has become unresponsive.' if seconds >= STREAM_TIMEOUT_IN_SECONDS
        end

        store_state! unless @stateless

        needs_another_round
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
