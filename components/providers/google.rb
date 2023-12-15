# frozen_string_literal: true

require 'gemini-ai'

require_relative 'base'

require_relative '../../logic/providers/google/tools'
require_relative '../../logic/providers/google/tokens'

require_relative 'tools'

module NanoBot
  module Components
    module Providers
      class Google < Base
        SAFETY_SETTINGS = %i[category threshold].freeze

        SETTINGS = {
          generationConfig: %i[
            temperature topP topK candidateCount maxOutputTokens stopSequences
          ].freeze
        }.freeze

        attr_reader :settings

        def initialize(options, settings, credentials, _environment)
          @settings = settings

          gemini_credentials = if credentials[:'api-key']
                                 {
                                   service: credentials[:service],
                                   api_key: credentials[:'api-key'],
                                   project_id: credentials[:'project-id'],
                                   region: credentials[:region]
                                 }
                               else
                                 {
                                   service: credentials[:service],
                                   file_path: credentials[:'file-path'],
                                   project_id: credentials[:'project-id'],
                                   region: credentials[:region]
                                 }
                               end

          @client = Gemini.new(
            credentials: gemini_credentials,
            options: { model: options[:model], stream: options[:stream] }
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

          %i[backdrop directive].each do |key|
            next unless input[:behavior][key]

            messages.prepend(
              { role: 'model',
                parts: { text: 'Understood.' },
                _meta: { at: Time.now } }
            )

            # TODO: Does Gemini have system messages?
            messages.prepend(
              { role: 'user',
                parts: { text: input[:behavior][key] },
                _meta: { at: Time.now } }
            )
          end

          payload = { contents: messages, generationConfig: { candidateCount: 1 } }

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
              partial_content = event.dig('candidates', 0, 'content', 'parts').filter do |part|
                part.key?('text')
              end.map { |part| part['text'] }.join

              partial_tools = event.dig('candidates', 0, 'content', 'parts').filter do |part|
                part.key?('functionCall')
              end

              tools.concat(partial_tools) if partial_tools.size.positive?

              if partial_content
                content += partial_content
                feedback.call(
                  { should_be_stored: false,
                    interaction: { who: 'AI', message: partial_content } }
                )
              end

              if event.dig('candidates', 0, 'finishReason')
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
              end
            end

            begin
              @client.stream_generate_content(
                Logic::Google::Tokens.apply_policies!(cartridge, payload),
                stream: true, &stream_call_back
              )
            rescue StandardError => e
              raise e.class, e.response[:body] if e.response && e.response[:body]

              raise e
            end
          else
            begin
              result = @client.stream_generate_content(
                Logic::Google::Tokens.apply_policies!(cartridge, payload),
                stream: false
              )
            rescue StandardError => e
              raise e.class, e.response[:body] if e.response && e.response[:body]

              raise e
            end

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
              answer.dig('candidates', 0, 'content', 'parts').filter do |part|
                part.key?('text')
              end.map { |part| part['text'] }.join
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
