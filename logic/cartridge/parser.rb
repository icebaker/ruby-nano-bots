# frozen_string_literal: true

require 'singleton'

require 'redcarpet'
require 'redcarpet/render_strip'

module NanoBot
  module Logic
    module Cartridge
      module Parser
        def self.parse(raw, format:)
          normalized = format.to_s.downcase.gsub('.', '')

          if %w[yml yaml].include?(normalized)
            yaml(raw)
          elsif %w[markdown mdown mkdn md].include?(normalized)
            markdown(raw)
          else
            raise "Unknown cartridge format: '#{format}'"
          end
        end

        def self.markdown(raw)
          yaml(Markdown.instance.render(raw))
        end

        def self.yaml(raw)
          Logic::Helpers::Hash.symbolize_keys(
            YAML.safe_load(raw, permitted_classes: [Symbol])
          )
        end

        class Renderer < Redcarpet::Render::Base
          def block_code(code, _language)
            "\n#{code}\n"
          end
        end

        class Markdown
          include Singleton

          attr_reader :markdown

          def initialize
            @markdown = Redcarpet::Markdown.new(Renderer, fenced_code_blocks: true)
          end

          def render(raw)
            @markdown.render(raw)
          end
        end
      end
    end
  end
end
