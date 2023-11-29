# frozen_string_literal: true

require 'openai'

require_relative 'providers/openai'

module NanoBot
  module Components
    class Provider
      def self.new(provider, environment: {})
        case provider[:id]
        when 'openai'
          Providers::OpenAI.new(provider[:settings], provider[:credentials], environment:)
        else
          raise "Unsupported provider \"#{provider[:id]}\""
        end
      end
    end
  end
end
