# frozen_string_literal: true

require 'pry'
require 'rainbow'

require_relative '../../logic/helpers/hash'
require_relative '../../logic/cartridge/affixes'

module NanoBot
  module Controllers
    module Interfaces
      module REPL
        def self.start(cartridge, session)
          prefix = Logic::Cartridge::Affixes.get(cartridge, :repl, :output, :prefix)
          suffix = Logic::Cartridge::Affixes.get(cartridge, :repl, :output, :suffix)

          if Logic::Helpers::Hash.fetch(cartridge, %i[behaviors boot instruction])
            session.print(prefix) unless prefix.nil?
            session.boot(mode: 'repl')
            session.print(suffix) unless suffix.nil?
            session.print("\n")
          end

          prompt = build_prompt(Logic::Helpers::Hash.fetch(cartridge, %i[interfaces repl prompt]))

          Pry.config.prompt = Pry::Prompt.new(
            'REPL',
            'REPL Prompt',
            [proc { prompt }, proc { 'MISSING INPUT' }]
          )

          Pry.commands.block_command(/(.*)/, 'handler') do |line|
            session.print(prefix) unless prefix.nil?
            session.evaluate_and_print(line, mode: 'repl')
            session.print(suffix) unless suffix.nil?
            session.print("\n")
            session.flush
          end

          Pry.start
        end

        def self.build_prompt(prompt)
          result = ''

          if prompt.is_a?(Array)
            prompt.each do |partial|
              result += if partial[:color]
                          Rainbow(partial[:text]).send(partial[:color])
                        else
                          partial[:text]
                        end
            end
          elsif prompt.is_a?(String)
            result = prompt
          else
            result = "🤖#{Rainbow('> ').blue}"
          end

          result
        end
      end
    end
  end
end
