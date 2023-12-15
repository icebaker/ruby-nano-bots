# frozen_string_literal: true

require 'openai'

module NanoBot
  module Logic
    module Google
      module Tokens
        def self.apply_policies!(_cartridge, payload)
          payload[:contents] = payload[:contents].map { |message| message.except(:_meta) }
          payload
        end
      end
    end
  end
end
