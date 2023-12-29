# frozen_string_literal: true

module NanoBot
  module Logic
    module Cohere
      module Tokens
        def self.apply_policies!(_cartridge, payload)
          if payload[:chat_history]
            payload[:chat_history] = payload[:chat_history].map { |message| message.except(:_meta) }
          end

          payload
        end
      end
    end
  end
end
