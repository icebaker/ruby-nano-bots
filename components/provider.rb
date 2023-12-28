# frozen_string_literal: true

require_relative 'providers/google'
require_relative 'providers/mistral'
require_relative 'providers/openai'

module NanoBot
  module Components
    class Provider
      def self.new(provider, environment: {})
        case provider[:id]
        when 'openai'
          Providers::OpenAI.new(nil, provider[:settings], provider[:credentials], environment:)
        when 'google'
          Providers::Google.new(provider[:options], provider[:settings], provider[:credentials], environment:)
        when 'mistral'
          Providers::Mistral.new(provider[:options], provider[:settings], provider[:credentials], environment:)
        else
          raise "Unsupported provider \"#{provider[:id]}\""
        end
      end
    end
  end
end
