# frozen_string_literal: true

require 'cohere-ai'

require_relative 'base'

require_relative '../../logic/providers/cohere/tokens'
require_relative '../../logic/helpers/hash'
require_relative '../../logic/cartridge/default'

module NanoBot
  module Components
    module Providers
      class Cohere < Base
        attr_reader :settings

        CHAT_SETTINGS = %i[
          model stream prompt_truncation connectors search_queries_only
          documents citation_quality temperature max_tokens max_input_tokens
          k p seed stop_sequences frequency_penalty presence_penalty
          force_single_step
        ].freeze

        def initialize(options, settings, credentials, _environment)
          @settings = settings

          cohere_options = if options
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

          cohere_options[:server_sent_events] = @settings[:stream]

          @client = ::Cohere.new(
            credentials: credentials.transform_keys { |key| key.to_s.gsub('-', '_').to_sym },
            options: cohere_options
          )
        end

        def evaluate(input, streaming, cartridge, &feedback)
          messages = input[:history].map do |event|
            { role: event[:who] == 'user' ? 'USER' : 'CHATBOT',
              message: event[:message],
              _meta: { at: event[:at] } }
          end

          if input[:behavior][:backdrop]
            messages.prepend(
              { role: 'USER',
                message: input[:behavior][:backdrop],
                _meta: { at: Time.now } }
            )
          end

          payload = { chat_history: messages }

          payload[:message] = payload[:chat_history].pop[:message]

          payload.delete(:chat_history) if payload[:chat_history].empty?

          payload[:preamble_override] = input[:behavior][:directive] if input[:behavior][:directive]

          CHAT_SETTINGS.each do |key|
            payload[key] = @settings[key] unless payload.key?(key) || !@settings.key?(key)
          end

          raise 'Cohere does not support tools.' if input[:tools]

          if streaming
            content = ''

            stream_call_back = proc do |event, _raw|
              partial_content = event['text']

              if partial_content && event['event_type'] == 'text-generation'
                content += partial_content
                feedback.call(
                  { should_be_stored: false,
                    interaction: { who: 'AI', message: partial_content } }
                )
              end

              if event['is_finished']
                feedback.call(
                  { should_be_stored: !(content.nil? || content == ''),
                    interaction: content.nil? || content == '' ? nil : { who: 'AI', message: content },
                    finished: true }
                )
              end
            end

            @client.chat(
              Logic::Cohere::Tokens.apply_policies!(cartridge, payload),
              server_sent_events: true, &stream_call_back
            )
          else
            result = @client.chat(
              Logic::Cohere::Tokens.apply_policies!(cartridge, payload),
              server_sent_events: false
            )

            content = result['text']

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
