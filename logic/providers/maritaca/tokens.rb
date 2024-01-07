# frozen_string_literal: true

module NanoBot
  module Logic
    module Maritaca
      module Tokens
        def self.apply_policies!(_cartridge, payload)
          payload[:messages] = payload[:messages].map { |message| message.except(:_meta) }
          payload
        end
      end
    end
  end
end
