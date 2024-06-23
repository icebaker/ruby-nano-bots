# frozen_string_literal: true

require 'anthropic'

require_relative 'base'

require_relative '../../logic/providers/anthropic/tokens'
require_relative '../../logic/helpers/hash'
require_relative '../../logic/cartridge/default'

module NanoBot
  module Components
    module Providers
      class Anthropic < Base
        attr_reader :settings

        CHAT_SETTINGS = %i[
          model stream max_tokens
        ].freeze

        def initialize(_options, settings, credentials, _environment)
          @settings = settings

          unless @settings.key?(:stream)
            @settings = Marshal.load(Marshal.dump(@settings))
            @settings[:stream] = Logic::Helpers::Hash.fetch(
              Logic::Cartridge::Default.instance.values, %i[provider settings stream]
            )
          end

          @client = ::Anthropic::Client.new(
            access_token: credentials[:'api-key'],
            anthropic_version: credentials[:'anthropic-version']
          )
        end

        def evaluate(input, streaming, cartridge, &feedback)
          messages = input[:history].map do |event|
            { role: event[:who] == 'user' ? 'user' : 'assistant',
              content: event[:message],
              _meta: { at: event[:at] } }
          end

          if input[:behavior][:backdrop]
            messages.prepend(
              { role: 'user',
                content: input[:behavior][:backdrop],
                _meta: { at: Time.now } }
            )
          end

          payload = { messages: }

          payload[:system] = input[:behavior][:directive] if input[:behavior][:directive]

          CHAT_SETTINGS.each do |key|
            payload[key] = @settings[key] unless payload.key?(key) || !@settings.key?(key)
          end

          raise 'Anthropic does not support tools.' if input[:tools]

          if streaming
            content = ''

            stream_call_back = proc do |event|
              partial_content = event.dig('delta', 'text')

              if partial_content && event['type'] == 'content_block_delta'
                content += partial_content
                feedback.call(
                  { should_be_stored: false,
                    interaction: { who: 'AI', message: partial_content } }
                )
              end

              if event['type'] == 'content_block_stop'
                feedback.call(
                  { should_be_stored: !(content.nil? || content == ''),
                    interaction: content.nil? || content == '' ? nil : { who: 'AI', message: content },
                    finished: true }
                )
              end
            end

            @client.messages(
              parameters: Logic::Anthropic::Tokens.apply_policies!(cartridge, payload).merge({
                                                                                               stream: stream_call_back
                                                                                             })
            )
          else
            result = @client.messages(
              parameters: Logic::Anthropic::Tokens.apply_policies!(cartridge, payload)
            )

            content = result['content'].map { |content| content['text'] }.join

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
