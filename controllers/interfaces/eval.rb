# frozen_string_literal: true

require 'pry'
require 'rainbow'

require_relative '../../logic/helpers/hash'

module NanoBot
  module Controllers
    module Interfaces
      module Eval
        def self.evaluate(input, cartridge, session)
          prefix = build_prefix(cartridge)
          postfix = build_postfix(cartridge)

          session.print(prefix) unless prefix.nil?

          session.evaluate_and_print(input, mode: 'eval')

          session.print(postfix) unless postfix.nil?
        end

        def self.build_prefix(cartridge)
          eval_interface = Logic::Helpers::Hash.fetch(cartridge, %i[interfaces eval])
          return nil if eval_interface.nil?

          eval_interface[:prefix]
        end

        def self.build_postfix(cartridge)
          eval_interface = Logic::Helpers::Hash.fetch(cartridge, %i[interfaces eval])
          return "\n" if eval_interface.nil? || !eval_interface.key?(:postfix) # default

          eval_interface[:postfix]
        end
      end
    end
  end
end
