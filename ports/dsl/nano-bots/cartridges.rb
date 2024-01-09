# frozen_string_literal: true

require_relative '../../controllers/cartridges'

module NanoBot
  module Cartridges
    def self.all
      Controllers::Cartridges.all
    end

    def self.load(path)
      Controllers::Cartridges.load(path)
    end
  end
end
