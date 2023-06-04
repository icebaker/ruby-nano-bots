# frozen_string_literal: true

require 'openai'

require_relative './base'
require_relative '../crypto'

module NanoBot
  module Components
    module Providers
      class OpenAI < Base
        DEFAULT_ADDRESS = 'https://api.openai.com'

        CHAT_SETTINGS = %i[
          model stream temperature top_p n stop max_tokens
          presence_penalty frequency_penalty logit_bias
        ].freeze

        attr_reader :settings

        def initialize(settings, credentials, environment: {})
          @settings = settings
          @credentials = credentials
          @environment = environment

          uri_base = if @credentials[:address].nil? || @credentials[:address].to_s.strip.empty?
                       "#{DEFAULT_ADDRESS}/"
                     else
                       "#{@credentials[:address].to_s.sub(%r{/$}, '')}/"
                     end

          @client = ::OpenAI::Client.new(uri_base:, access_token: @credentials[:'access-token'])
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

          payload = { user: OpenAI.end_user(@settings, @environment), messages: }

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

        def self.end_user(settings, environment)
          user = ENV.fetch('NANO_BOTS_END_USER', nil)

          user = settings[:user] if !settings[:user].nil? && !settings[:user].to_s.strip.empty?

          candidate = environment && (
            environment['NANO_BOTS_END_USER'] ||
            environment[:NANO_BOTS_END_USER]
          )

          user = candidate if !candidate.nil? && !candidate.to_s.strip.empty?

          user = if user.nil? || user.to_s.strip.empty?
                   'unknown'
                 else
                   user.to_s.strip
                 end

          Crypto.encrypt(user, soft: true)
        end
      end
    end
  end
end
