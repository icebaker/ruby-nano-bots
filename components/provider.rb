# frozen_string_literal: true

require 'openai'

require_relative './providers/openai'

module NanoBot
  module Components
    class Provider
      def self.new(provider, environment: {})
        case provider[:name]
        when 'openai'
          Providers::OpenAI.new(provider[:settings], environment:)
        else
          raise "Unsupported provider #{provider[:name]}"
        end
      end
    end
  end
end
