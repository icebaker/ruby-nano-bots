# frozen_string_literal: true

require 'openai'

module NanoBot
  module Components
    module Providers
      class Base
        def initialize(_options, _settings, _credentials, _environment: {})
          raise NoMethodError, "The 'initialize' method is not implemented for the current provider."
        end

        def evaluate(_payload)
          raise NoMethodError, "The 'evaluate' method is not implemented for the current provider."
        end
      end
    end
  end
end
