# frozen_string_literal: true

require 'gemini-ai'

require_relative 'base'

require_relative '../../logic/providers/google/tools'
require_relative '../../logic/providers/google/tokens'
require_relative '../../logic/helpers/hash'
require_relative '../../logic/cartridge/default'

require_relative 'tools'

module NanoBot
  module Components
    module Providers
      class Google < Base
        SAFETY_SETTINGS = %i[category threshold].freeze

        SETTINGS = {
          generationConfig: %i[
            temperature maxOutputTokens candidateCount presencePenalty
            frequencyPenalty topK topP stopSequences
            responseMimeType responseSchema
          ].freeze
        }.freeze

        attr_reader :settings

        def initialize(options, settings, credentials, _environment)
          @settings = settings

          @service = credentials[:service]

          gemini_options = options.transform_keys { |key| key.to_s.gsub('-', '_').to_sym }

          unless gemini_options.key?(:stream)
            gemini_options[:stream] = Logic::Helpers::Hash.fetch(
              Logic::Cartridge::Default.instance.values, %i[provider settings stream]
            )
          end

          gemini_options[:server_sent_events] = gemini_options.delete(:stream)

          @client = Gemini.new(
            credentials: credentials.transform_keys { |key| key.to_s.gsub('-', '_').to_sym },
            options: gemini_options
          )
        end

        def evaluate(input, streaming, cartridge, &feedback)
          messages = input[:history].map do |event|
            if event[:message].nil? && event[:meta] && event[:meta][:tool_calls]
              { role: 'model',
                parts: event[:meta][:tool_calls],
                _meta: { at: event[:at] } }
            elsif event[:who] == 'tool'
              { role: 'function',
                parts: [
                  { functionResponse: {
                    name: event[:meta][:name],
                    response: { name: event[:meta][:name], content: event[:message].to_s }
                  } }
                ],
                _meta: { at: event[:at] } }
            else
              { role: event[:who] == 'user' ? 'user' : 'model',
                parts: { text: event[:message] },
                _meta: { at: event[:at] } }
            end
          end

          if input[:behavior][:backdrop]
            messages.prepend(
              { role: 'model',
                parts: { text: 'Understood.' },
                _meta: { at: Time.now } }
            )

            messages.prepend(
              { role: 'user',
                parts: { text: input[:behavior][:backdrop] },
                _meta: { at: Time.now } }
            )
          end

          payload = { contents: messages, generationConfig: { candidateCount: 1 } }

          if input[:behavior][:directive] && @service == 'vertex-ai-api'
            payload[:system_instruction] = {
              role: 'user',
              parts: { text: input[:behavior][:directive] }
            }
          elsif input[:behavior][:directive]
            # TODO: Will generative-language-api support system instructions?
            messages.prepend(
              { role: 'user',
                parts: { text: input[:behavior][:directive] },
                _meta: { at: Time.now } }
            )
          end

          if @settings
            SETTINGS.each_key do |key|
              SETTINGS[key].each do |sub_key|
                if @settings.key?(key) && @settings[key].key?(sub_key)
                  payload[key] = {} unless payload.key?(key)
                  payload[key][sub_key] = @settings[key][sub_key]
                end
              end
            end

            if @settings[:safetySettings].is_a?(Array)
              payload[:safetySettings] = [] unless payload.key?(:safetySettings)

              @settings[:safetySettings].each do |safety_setting|
                setting = {}
                SAFETY_SETTINGS.each { |key| setting[key] = safety_setting[key] }
                payload[:safetySettings] << setting
              end
            end
          end

          if input[:tools]
            payload[:tools] = {
              function_declarations: input[:tools].map { |raw| Logic::Google::Tools.adapt(raw) }
            }
          end

          if streaming
            content = ''
            tools = []

            stream_call_back = proc do |event, _parsed, _raw|
              # TODO: How to better handle finishReason == 'OTHER'?
              return if event.dig('candidates', 0, 'finishReason') == 'OTHER'

              partial_content = event.dig('candidates', 0, 'content', 'parts')&.filter do |part|
                part.key?('text')
              end&.map { |part| part['text'] }&.join || ''

              partial_tools = event.dig('candidates', 0, 'content', 'parts')&.filter do |part|
                part.key?('functionCall')
              end || []

              tools.concat(partial_tools) if partial_tools.size.positive?

              if partial_content
                content += partial_content
                feedback.call(
                  { should_be_stored: false,
                    interaction: { who: 'AI', message: partial_content } }
                )
              end

              if event.dig('candidates', 0, 'finishReason') == 'SAFETY'
                reasons = event.dig('candidates', 0, 'safetyRatings')
                raise StandardError, "Generation stopped for safety reasons: #{reasons}"
              end
            end

            @client.stream_generate_content(
              Logic::Google::Tokens.apply_policies!(cartridge, payload),
              server_sent_events: true, &stream_call_back
            )

            if tools&.size&.positive?
              feedback.call(
                { should_be_stored: true,
                  needs_another_round: true,
                  interaction: { who: 'AI', message: nil, meta: { tool_calls: tools } } }
              )
              Tools.apply(
                cartridge, input[:tools], tools, feedback, Logic::Google::Tools
              ).each do |interaction|
                feedback.call({ should_be_stored: true, needs_another_round: true, interaction: })
              end
            end

            feedback.call(
              { should_be_stored: !(content.nil? || content == ''),
                interaction: content.nil? || content == '' ? nil : { who: 'AI', message: content },
                finished: true }
            )
          else
            result = @client.stream_generate_content(
              Logic::Google::Tokens.apply_policies!(cartridge, payload),
              server_sent_events: false
            )

            tools = result.dig(0, 'candidates', 0, 'content', 'parts').filter do |part|
              part.key?('functionCall')
            end

            if tools&.size&.positive?
              feedback.call(
                { should_be_stored: true,
                  needs_another_round: true,
                  interaction: { who: 'AI', message: nil, meta: { tool_calls: tools } } }
              )

              Tools.apply(
                cartridge, input[:tools], tools, feedback, Logic::Google::Tools
              ).each do |interaction|
                feedback.call({ should_be_stored: true, needs_another_round: true, interaction: })
              end
            end

            content = result.map do |answer|
              parts = answer.dig('candidates', 0, 'content', 'parts')

              if parts
                parts.filter { |part| part.key?('text') }.map { |part| part['text'] }.join
              else
                ''
              end
            end.join

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
