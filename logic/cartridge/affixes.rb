# frozen_string_literal: true

require_relative '../helpers/hash'
require_relative './default'

module NanoBot
  module Logic
    module Cartridge
      module Affixes
        def self.get(cartridge, interface, direction, kind)
          affix = [
            {
              exists: (Helpers::Hash.fetch(cartridge, [:interfaces, direction]) || {}).key?(kind),
              value: Helpers::Hash.fetch(cartridge, [:interfaces, direction, kind])
            },
            {
              exists: (Helpers::Hash.fetch(cartridge, [:interfaces, interface, direction]) || {}).key?(kind),
              value: Helpers::Hash.fetch(cartridge, [:interfaces, interface, direction, kind])
            }
          ].filter { |candidate| candidate[:exists] }.last

          if affix.nil?
            return Helpers::Hash.fetch(
              Default.instance.values, [:interfaces, interface, direction, kind]
            )
          end

          affix[:value]
        end
      end
    end
  end
end
