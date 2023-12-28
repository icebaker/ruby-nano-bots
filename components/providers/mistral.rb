# frozen_string_literal: true

require 'mistral-ai'

require_relative 'base'

require_relative '../../logic/providers/mistral/tokens'
require_relative '../../logic/helpers/hash'
require_relative '../../logic/cartridge/default'

module NanoBot
  module Components
    module Providers
      class Mistral < Base
        attr_reader :settings

        CHAT_SETTINGS = %i[
          model temperature top_p max_tokens stream safe_mode random_seed
        ].freeze

        def initialize(options, settings, credentials, _environment)
          @settings = settings

          mistral_options = if options
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

          mistral_options[:server_sent_events] = @settings[:stream]

          @client = ::Mistral.new(
            credentials: credentials.transform_keys { |key| key.to_s.gsub('-', '_').to_sym },
            options: mistral_options
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

          raise 'Mistral does not support tools.' if input[:tools]

          if streaming
            content = ''

            stream_call_back = proc do |event, _parsed, _raw|
              partial_content = event.dig('choices', 0, 'delta', 'content')

              if partial_content
                content += partial_content
                feedback.call(
                  { should_be_stored: false,
                    interaction: { who: 'AI', message: partial_content } }
                )
              end

              if event.dig('choices', 0, 'finish_reason')
                feedback.call(
                  { should_be_stored: !(content.nil? || content == ''),
                    interaction: content.nil? || content == '' ? nil : { who: 'AI', message: content },
                    finished: true }
                )
              end
            end

            @client.chat_completions(
              Logic::Mistral::Tokens.apply_policies!(cartridge, payload),
              server_sent_events: true, &stream_call_back
            )
          else
            result = @client.chat_completions(
              Logic::Mistral::Tokens.apply_policies!(cartridge, payload),
              server_sent_events: false
            )

            content = result.dig('choices', 0, 'message', 'content')

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
