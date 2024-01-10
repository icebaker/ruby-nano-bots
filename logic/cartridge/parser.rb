# frozen_string_literal: true

require 'singleton'

require 'redcarpet'
require 'redcarpet/render_strip'

module NanoBot
  module Logic
    module Cartridge
      module Parser
        def self.parse(raw, format:)
          normalized = format.to_s.downcase.gsub('.', '').strip

          if %w[yml yaml].include?(normalized)
            yaml(raw)
          elsif %w[markdown mdown mkdn md].include?(normalized)
            markdown(raw)
          else
            raise "Unknown cartridge format: '#{format}'"
          end
        end

        def self.markdown(raw)
          yaml_source = []

          tools = []

          blocks = Markdown.new.render(raw).blocks

          previous_block_is_tool = false

          blocks.each do |block|
            if block[:language] == 'yaml'
              parsed = Logic::Helpers::Hash.symbolize_keys(
                YAML.safe_load(block[:source], permitted_classes: [Symbol])
              )

              if parsed.key?(:tools) && parsed[:tools].is_a?(Array) && !parsed[:tools].empty?
                previous_block_is_tool = true

                tools.concat(parsed[:tools])

                parsed.delete(:tools)

                unless parsed.empty?
                  yaml_source << YAML.dump(Logic::Helpers::Hash.stringify_keys(
                                             parsed
                                           )).gsub(/^---/, '') # TODO: Is this safe enough?
                end
              else
                yaml_source << block[:source]
                previous_block_is_tool = false
                nil
              end
            elsif previous_block_is_tool
              tools.last[block[:language].to_sym] = block[:source]
              previous_block_is_tool = false
            end
          end

          unless tools.empty?
            yaml_source << YAML.dump(Logic::Helpers::Hash.stringify_keys(
                                       { tools: }
                                     )).gsub(/^---/, '') # TODO: Is this safe enough?
          end

          yaml(yaml_source.join("\n"))
        end

        def self.yaml(raw)
          Logic::Helpers::Hash.symbolize_keys(
            YAML.safe_load(raw, permitted_classes: [Symbol])
          )
        end

        class Renderer < Redcarpet::Render::Base
          LANGUAGES_MAP = {
            'yml' => 'yaml',
            'yaml' => 'yaml',
            'lua' => 'lua',
            'fnl' => 'fennel',
            'fennel' => 'fennel',
            'clj' => 'clojure',
            'clojure' => 'clojure'
          }.freeze

          LANGUAGES = LANGUAGES_MAP.keys.freeze

          def initialize(...)
            super(...)
            @_nano_bots_blocks = []
          end

          attr_reader :_nano_bots_blocks

          def block_code(code, language)
            key = language.to_s.downcase.strip

            return nil unless LANGUAGES.include?(key)

            @_nano_bots_blocks << { language: LANGUAGES_MAP[key], source: code }

            nil
          end
        end

        class Markdown
          attr_reader :markdown

          def initialize
            @renderer = Renderer.new
            @markdown = Redcarpet::Markdown.new(@renderer, fenced_code_blocks: true)
          end

          def blocks
            @renderer._nano_bots_blocks
          end

          def render(raw)
            @markdown.render(raw.gsub(/```\w/, "\n\n\\0"))
            self
          end
        end
      end
    end
  end
end
