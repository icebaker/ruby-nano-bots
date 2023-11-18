# frozen_string_literal: true

require 'openai'

require_relative 'base'
require_relative '../crypto'

require_relative '../../logic/providers/openai/tools'
require_relative '../../controllers/interfaces/tools'

require_relative 'openai/tools'

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

        def evaluate(input, &feedback)
          messages = input[:history].map do |event|
            if event[:message].nil? && event[:meta] && event[:meta][:tool_calls]
              { role: 'assistant', content: nil, tool_calls: event[:meta][:tool_calls] }
            elsif event[:who] == 'tool'
              { role: event[:who], content: event[:message],
                tool_call_id: event[:meta][:id], name: event[:meta][:name] }
            else
              { role: event[:who] == 'user' ? 'user' : 'assistant', content: event[:message] }
            end
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

          payload[:tools] = input[:tools].map { |raw| NanoBot::Logic::OpenAI::Tools.adapt(raw) } if input[:tools]

          if stream(input)
            content = ''
            tools = []

            payload[:stream] = proc do |chunk, _bytesize|
              partial_content = chunk.dig('choices', 0, 'delta', 'content')
              partial_tools = chunk.dig('choices', 0, 'delta', 'tool_calls')

              if partial_tools
                partial_tools.each do |partial_tool|
                  tools[partial_tool['index']] = {} if tools[partial_tool['index']].nil?

                  partial_tool.keys.reject { |key| ['index'].include?(key) }.each do |key|
                    target = tools[partial_tool['index']]

                    if partial_tool[key].is_a?(Hash)
                      target[key] = {} if target[key].nil?
                      partial_tool[key].each_key do |sub_key|
                        target[key][sub_key] = '' if target[key][sub_key].nil?

                        target[key][sub_key] += partial_tool[key][sub_key]
                      end
                    else
                      target[key] = '' if target[key].nil?

                      target[key] += partial_tool[key]
                    end
                  end
                end
              end

              if partial_content
                content += partial_content
                feedback.call(
                  { should_be_stored: false,
                    interaction: { who: 'AI', message: partial_content } }
                )
              end

              if chunk.dig('choices', 0, 'finish_reason')
                if tools&.size&.positive?
                  feedback.call(
                    { should_be_stored: true,
                      needs_another_round: true,
                      interaction: { who: 'AI', message: nil, meta: { tool_calls: tools } } }
                  )
                  Tools.apply(input[:tools], tools, feedback).each do |interaction|
                    feedback.call({ should_be_stored: true, needs_another_round: true, interaction: })
                  end
                end

                feedback.call(
                  { should_be_stored: !(content.nil? || content == ''),
                    interaction: content.nil? || content == '' ? nil : { who: 'AI', message: content },
                    finished: true }
                )
              end
            end

            @client.chat(parameters: payload)
          else
            result = @client.chat(parameters: payload)

            raise StandardError, result['error'] if result['error']

            tools = result.dig('choices', 0, 'message', 'tool_calls')

            if tools&.size&.positive?
              feedback.call(
                { should_be_stored: true,
                  needs_another_round: true,
                  interaction: { who: 'AI', message: nil, meta: { tool_calls: tools } } }
              )
              Tools.apply(input[:tools], tools, feedback).each do |interaction|
                feedback.call({ should_be_stored: true, needs_another_round: true, interaction: })
              end
            end

            content = result.dig('choices', 0, 'message', 'content')

            feedback.call(
              { should_be_stored: !(content.nil? || content == ''),
                interaction: content.nil? || content == '' ? nil : { who: 'AI', message: content },
                finished: true }
            )
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
