# frozen_string_literal: true

require 'ollama-ai'

require_relative 'base'

require_relative '../../logic/providers/ollama/tokens'
require_relative '../../logic/helpers/hash'
require_relative '../../logic/cartridge/default'

module NanoBot
  module Components
    module Providers
      class Ollama < Base
        attr_reader :settings

        CHAT_SETTINGS = %i[
          model template stream
        ].freeze

        CHAT_OPTIONS = %i[
          mirostat mirostat_eta mirostat_tau num_ctx num_gqa num_gpu num_thread repeat_last_n
          repeat_penalty temperature seed stop tfs_z num_predict top_k top_p
        ].freeze

        def initialize(options, settings, credentials, _environment)
          @settings = settings

          ollama_options = if options
                             options.transform_keys { |key| key.to_s.gsub('-', '_').to_sym }
                           else
                             {}
                           end

          unless @settings.key?(:stream)
            @settings = Marshal.load(Marshal.dump(@settings))
            @settings[:stream] = Logic::Helpers::Hash.fetch(
              Logic::Cartridge::Default.instance.values, %i[provider settings stream]
            )
          end

          ollama_options[:server_sent_events] = @settings[:stream]

          credentials ||= {}

          @client = ::Ollama.new(
            credentials: credentials.transform_keys { |key| key.to_s.gsub('-', '_').to_sym },
            options: ollama_options
          )
        end

        def evaluate(input, streaming, cartridge, &feedback)
          messages = input[:history].map do |event|
            { role: event[:who] == 'user' ? 'user' : 'assistant',
              content: event[:message],
              _meta: { at: event[:at] } }
          end

          %i[backdrop directive].each do |key|
            next unless input[:behavior][key]

            messages.prepend(
              { role: key == :directive ? 'system' : 'user',
                content: input[:behavior][key],
                _meta: { at: Time.now } }
            )
          end

          payload = { messages: }

          CHAT_SETTINGS.each do |key|
            payload[key] = @settings[key] unless payload.key?(key) || !@settings.key?(key)
          end

          if @settings.key?(:options)
            options = {}

            CHAT_OPTIONS.each do |key|
              options[key] = @settings[:options][key] unless options.key?(key) || !@settings[:options].key?(key)
            end

            payload[:options] = options unless options.empty?
          end

          raise 'Ollama does not support tools.' if input[:tools]

          if streaming
            content = ''

            stream_call_back = proc do |event, _raw|
              partial_content = event.dig('message', 'content')

              if partial_content
                content += partial_content
                feedback.call(
                  { should_be_stored: false,
                    interaction: { who: 'AI', message: partial_content } }
                )
              end

              if event['done']
                feedback.call(
                  { should_be_stored: !(content.nil? || content == ''),
                    interaction: content.nil? || content == '' ? nil : { who: 'AI', message: content },
                    finished: true }
                )
              end
            end

            @client.chat(
              Logic::Ollama::Tokens.apply_policies!(cartridge, payload),
              server_sent_events: true, &stream_call_back
            )
          else
            result = @client.chat(
              Logic::Ollama::Tokens.apply_policies!(cartridge, payload),
              server_sent_events: false
            )

            content = result.map { |event| event.dig('message', 'content') }.join

            feedback.call(
              { should_be_stored: !(content.nil? || content.to_s.strip == ''),
                interaction: content.nil? || content == '' ? nil : { who: 'AI', message: content },
                finished: true }
            )
          end
        end
      end
    end
  end
end
