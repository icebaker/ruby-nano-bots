# frozen_string_literal: true

require 'openai'

require_relative './base'

module NanoBot
  module Components
    module Providers
      class OpenAI < Base
        CHAT_SETTINGS = %i[
          model stream temperature top_p n stop max_tokens
          presence_penalty frequency_penalty logit_bias
        ].freeze

        attr_reader :settings

        def initialize(settings)
          @settings = settings

          @client = ::OpenAI::Client.new(
            uri_base: "#{@settings[:credentials][:address].sub(%r{/$}, '')}/",
            access_token: @settings[:credentials][:'access-token']
          )
        end

        def stream(input)
          provider = @settings.key?(:stream) ? @settings[:stream] : true
          interface = input[:interface].key?(:stream) ? input[:interface][:stream] : true

          provider && interface
        end

        def evaluate(input, &block)
          messages = input[:history].map do |event|
            { role: event[:who] == 'user' ? 'user' : 'assistant',
              content: event[:message] }
          end

          %i[instruction backdrop directive].each do |key|
            next unless input[:behavior][key]

            messages.prepend(
              { role: key == :directive ? 'system' : 'user',
                content: input[:behavior][key] }
            )
          end

          payload = {
            model: @settings[:model],
            user: @settings[:credentials][:'user-identifier'],
            messages:
          }

          CHAT_SETTINGS.each do |key|
            payload[key] = @settings[key] if @settings.key?(key)
          end

          payload.delete(:logit_bias) if payload.key?(:logit_bias) && payload[:logit_bias].nil?

          if stream(input)
            content = ''

            payload[:stream] = proc do |chunk, _bytesize|
              partial = chunk.dig('choices', 0, 'delta', 'content')
              if partial
                content += partial
                block.call({ who: 'AI', message: partial }, false)
              end

              block.call({ who: 'AI', message: content }, true) if chunk.dig('choices', 0, 'finish_reason')
            end

            @client.chat(parameters: payload)
          else
            result = @client.chat(parameters: payload)

            raise StandardError, result['error'] if result['error']

            block.call({ who: 'AI', message: result.dig('choices', 0, 'message', 'content') }, true)
          end
        end
      end
    end
  end
end
