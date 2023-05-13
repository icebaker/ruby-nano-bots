# frozen_string_literal: true

require 'yaml'
require 'singleton'

require_relative '../helpers/hash'

module NanoBot
  module Logic
    module Cartridge
      class Default
        include Singleton

        def values
          return @values if @values

          path = File.expand_path('../../static/cartridges/default.yml', __dir__)
          cartridge = YAML.safe_load(File.read(path), permitted_classes: [Symbol])
          @values = Logic::Helpers::Hash.symbolize_keys(cartridge)
          @values
        end

        def baseline
          return @baseline if @baseline

          path = File.expand_path('../../static/cartridges/baseline.yml', __dir__)
          cartridge = YAML.safe_load(File.read(path), permitted_classes: [Symbol])
          @baseline = Logic::Helpers::Hash.symbolize_keys(cartridge)
          @baseline
        end
      end
    end
  end
end
