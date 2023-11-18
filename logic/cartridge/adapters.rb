# frozen_string_literal: true

require_relative '../helpers/hash'
require_relative 'default'

module NanoBot
  module Logic
    module Cartridge
      module Adapter
        def self.expression(cartridge, interface, direction, language)
          adapter = [
            {
              exists: (Helpers::Hash.fetch(cartridge, [:interfaces, direction, :adapter]) || {}).key?(language),
              value: Helpers::Hash.fetch(cartridge, [:interfaces, direction, :adapter, language])
            },
            {
              exists: (Helpers::Hash.fetch(cartridge,
                                           [:interfaces, interface, direction, :adapter]) || {}).key?(language),
              value: Helpers::Hash.fetch(cartridge, [:interfaces, interface, direction, :adapter, language])
            }
          ].filter { |candidate| candidate[:exists] }.last

          return nil if adapter.nil?

          adapter[:value]
        end
      end
    end
  end
end
