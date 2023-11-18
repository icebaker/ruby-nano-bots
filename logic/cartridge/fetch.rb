# frozen_string_literal: true

require_relative 'default'
require_relative '../helpers/hash'

module NanoBot
  module Logic
    module Cartridge
      module Fetch
        def self.cascate(cartridge, paths)
          results = paths.map { |path| Helpers::Hash.fetch(cartridge, path) }
          result = results.find { |candidate| !candidate.nil? }
          return result unless result.nil?

          results = paths.map { |path| Helpers::Hash.fetch(Default.instance.values, path) }
          result = results.find { |candidate| !candidate.nil? }
          return result unless result.nil?

          nil
        end
      end
    end
  end
end
