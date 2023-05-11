# frozen_string_literal: true

require 'openai'

module NanoBot
  module Components
    module Providers
      class Base
        def evaluate(_payload)
          raise NoMethodError, "The 'evaluate' method is not implemented for the current provider."
        end
      end
    end
  end
end
