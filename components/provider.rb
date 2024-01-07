# frozen_string_literal: true

require_relative 'providers/openai'
require_relative 'providers/ollama'
require_relative 'providers/mistral'
require_relative 'providers/google'
require_relative 'providers/cohere'
require_relative 'providers/maritaca'

module NanoBot
  module Components
    class Provider
      def self.new(provider, environment: {})
        case provider[:id]
        when 'openai'
          Providers::OpenAI.new(nil, provider[:settings], provider[:credentials], environment:)
        when 'ollama'
          Providers::Ollama.new(provider[:options], provider[:settings], provider[:credentials], environment:)
        when 'mistral'
          Providers::Mistral.new(provider[:options], provider[:settings], provider[:credentials], environment:)
        when 'google'
          Providers::Google.new(provider[:options], provider[:settings], provider[:credentials], environment:)
        when 'cohere'
          Providers::Cohere.new(provider[:options], provider[:settings], provider[:credentials], environment:)
        when 'maritaca'
          Providers::Maritaca.new(provider[:options], provider[:settings], provider[:credentials], environment:)
        else
          raise "Unsupported provider \"#{provider[:id]}\""
        end
      end
    end
  end
end
