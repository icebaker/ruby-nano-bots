# frozen_string_literal: true

require 'babosa'

require 'fileutils'
require 'rainbow'

require_relative '../logic/helpers/hash'
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

    class Session
      attr_accessor :stream

      def initialize(provider:, cartridge:, state: nil, stream: $stdout, environment: {})
        @stream = stream
        @provider = provider
        @cartridge = cartridge

        @stateless = state.nil? || state.strip == '-' || state.strip.empty?

        if @stateless
          @state = { history: [] }
        else
          @state_path = Components::Storage.build_path_and_ensure_state_file!(
            state.strip, @cartridge, environment:
          )

          @state = load_state
        end
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
            :input, Logic::Cartridge::Interaction.input(@cartridge, mode.to_sym, message)
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

        # TODO: Improve infinite loop prevention.
        needs_another_round = process_interaction(input, mode:) while needs_another_round
      end

      def process_interaction(input, mode:)
        prefix = Logic::Cartridge::Affixes.get(@cartridge, mode.to_sym, :output, :prefix)
        suffix = Logic::Cartridge::Affixes.get(@cartridge, mode.to_sym, :output, :suffix)

        color = Logic::Cartridge::Fetch.cascate(@cartridge, [
                                                  [:interfaces, mode.to_sym, :output, :color],
                                                  %i[interfaces output color]
                                                ])

        color = color.to_sym if color

        streaming = Logic::Cartridge::Streaming.enabled?(@cartridge, mode.to_sym)

        updated_at = Time.now

        ready = false

        needs_another_round = false

        @provider.evaluate(input) do |feedback|
          updated_at = Time.now

          needs_another_round = true if feedback[:needs_another_round]

          if feedback[:interaction] && feedback.dig(:interaction, :meta, :tool, :action)
            Interfaces::Tool.dispatch_feedback(self, @cartridge, mode, feedback[:interaction][:meta][:tool])
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
                output[:message] = Components::Adapter.apply(:output, output[:message])
                event[:output] = (output[:message]).to_s
              end
            end

            @state[:history] << event if feedback[:should_be_stored]
            if event[:output] && ((!feedback[:finished] && streaming) || (!streaming && feedback[:finished]))
              # TODO: Color?
              if color
                self.print(Rainbow(event[:output]).send(color))
              else
                self.print(event[:output])
              end

              flush if feedback[:finished]
            end

            # `.print` already adds a prefix and suffix, so we add them after printing to avoid duplications.
            event[:output] = "#{prefix}#{event[:output]}#{suffix}"
          end

          ready = true if feedback[:finished]
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
