# frozen_string_literal: true

require 'babosa'

require 'fileutils'

require_relative '../logic/helpers/hash'

module NanoBot
  module Controllers
    STREAM_TIMEOUT_IN_SECONDS = 5

    class Session
      def initialize(provider:, cartridge:, state: nil)
        @provider = provider
        @cartridge = cartridge

        @output = $stdout

        @stateless = state.nil? || state.strip == '-' || state.strip.empty?

        if @stateless
          @state = { history: [] }
        else
          build_path_and_ensure_state_file!(state.strip)
          @state = load_state
        end
      end

      def debug
        pp({
             state: {
               path: @state_path,
               content: @state
             }
           })
      end

      def load_state
        @state = Logic::Helpers::Hash.symbolize_keys(JSON.parse(File.read(@state_path)))
      end

      def store_state!
        File.write(@state_path, JSON.generate(@state))
      end

      def build_path_and_ensure_state_file!(key)
        path = Logic::Helpers::Hash.fetch(@cartridge, %i[state directory])

        path = "#{user_home!.sub(%r{/$}, '')}/.local/share/.nano-bots" if path.nil? || path.empty?

        path = "#{path.sub(%r{/$}, '')}/nano-bots-rb/#{@cartridge[:name].to_slug.normalize}"
        path = "#{path}/#{@cartridge[:version].to_slug.normalize}/#{key.to_slug.normalize}"
        path = "#{path}/state.json"

        @state_path = path

        FileUtils.mkdir_p(File.dirname(@state_path))

        File.write(@state_path, JSON.generate({ key:, history: [] })) unless File.exist?(@state_path)
      end

      def user_home!
        [Dir.home, `echo ~`.strip, '~'].find do |candidate|
          !candidate.nil? && !candidate.empty?
        end
      end

      def boot(mode:)
        return unless Logic::Helpers::Hash.fetch(@cartridge, %i[behaviors boot instruction])

        behavior = Logic::Helpers::Hash.fetch(@cartridge, %i[behaviors boot]) || {}

        input = { behavior:, history: [] }

        process(input, mode:)
      end

      def evaluate_and_print(message, mode:)
        behavior = Logic::Helpers::Hash.fetch(@cartridge, %i[behaviors interaction]) || {}

        @state[:history] << ({ who: 'user', message: })

        input = { behavior:, history: @state[:history] }

        process(input, mode:)
      end

      def process(input, mode:)
        streaming = @provider.settings[:stream] && Logic::Helpers::Hash.fetch(
          @cartridge, [:interfaces, mode.to_sym, :stream]
        )

        interface = Logic::Helpers::Hash.fetch(@cartridge, [:interfaces, mode.to_sym]) || {}

        input[:interface] = interface

        updated_at = Time.now

        ready = false
        @provider.evaluate(input) do |output, finished|
          updated_at = Time.now
          if finished
            @state[:history] << output
            self.print(output[:message]) unless streaming
            unless Logic::Helpers::Hash.fetch(@cartridge, [:interfaces, mode.to_sym, :postfix]).nil?
              self.print(Logic::Helpers::Hash.fetch(@cartridge, [:interfaces, mode.to_sym, :postfix]))
            end
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
        @output.flush
      end

      def print(content)
        @output.write(content)
      end
    end
  end
end
