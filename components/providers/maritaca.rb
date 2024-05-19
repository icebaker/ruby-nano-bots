# frozen_string_literal: true

require 'maritaca-ai'

require_relative 'base'

require_relative '../../logic/providers/maritaca/tokens'
require_relative '../../logic/helpers/hash'
require_relative '../../logic/cartridge/default'

module NanoBot
  module Components
    module Providers
      class Maritaca < Base
        attr_reader :settings

        CHAT_SETTINGS = %i[
          max_tokens model stream do_sample temperature top_p repetition_penalty stopping_tokens
        ].freeze

        def initialize(options, settings, credentials, _environment)
          @settings = settings

          maritaca_options = if options
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

          maritaca_options[:server_sent_events] = @settings[:stream]

          @client = ::Maritaca.new(
            credentials: credentials.transform_keys { |key| key.to_s.gsub('-', '_').to_sym },
            options: maritaca_options
          )
        end

        def evaluate(input, streaming, cartridge, &feedback)
          messages = input[:history].map do |event|
            { role: event[:who] == 'user' ? 'user' : 'assistant',
              content: event[:message],
              _meta: { at: event[:at] } }
          end

          # TODO: Does Maritaca have system messages?
          %i[backdrop directive].each do |key|
            next unless input[:behavior][key]

            messages.prepend(
              { role: 'user',
                content: input[:behavior][key],
                _meta: { at: Time.now } }
            )
          end

          payload = { chat_mode: true, messages: }

          CHAT_SETTINGS.each do |key|
            payload[key] = @settings[key] unless payload.key?(key) || !@settings.key?(key)
          end

          raise 'Maritaca does not support tools.' if input[:tools]

          if streaming
            content = ''

            stream_call_back = proc do |event, _raw|
              partial_content = event['text']

              if partial_content
                content += partial_content
                feedback.call(
                  { should_be_stored: false,
                    interaction: { who: 'AI', message: partial_content } }
                )
              end
            end

            @client.chat_inference(
              Logic::Maritaca::Tokens.apply_policies!(cartridge, payload),
              server_sent_events: true, &stream_call_back
            )

            feedback.call(
              { should_be_stored: !(content.nil? || content == ''),
                interaction: content.nil? || content == '' ? nil : { who: 'AI', message: content },
                finished: true }
            )
          else
            result = @client.chat_inference(
              Logic::Maritaca::Tokens.apply_policies!(cartridge, payload),
              server_sent_events: false
            )

            content = result['answer']

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
