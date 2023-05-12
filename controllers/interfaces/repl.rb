# frozen_string_literal: true

require 'pry'
require 'rainbow'

require_relative '../../logic/helpers/hash'

module NanoBot
  module Controllers
    module Interfaces
      module REPL
        def self.start(cartridge, session)
          prefix = build_prefix(cartridge)
          postfix = build_postfix(cartridge)

          if Logic::Helpers::Hash.fetch(cartridge, %i[behaviors boot instruction])
            session.print(prefix) unless prefix.nil?
            session.boot(mode: 'repl')
            session.print(postfix) unless postfix.nil?
            session.print("\n")
          end

          prompt = build_prompt(Logic::Helpers::Hash.fetch(cartridge, %i[interfaces repl prompt]))

          Pry.config.prompt = Pry::Prompt.new(
            'REPL',
            'REPL Prompt',
            [proc { prompt }, proc { 'MISSING INPUT' }]
          )

          Pry.commands.block_command(/(.*)/, 'handler') do |line|
            session.print(postfix) unless postfix.nil?
            session.evaluate_and_print(line, mode: 'repl')
            session.print(postfix) unless postfix.nil?
            session.print("\n")
            session.flush
          end

          Pry.start
        end

        def self.build_prefix(cartridge)
          repl = Logic::Helpers::Hash.fetch(cartridge, %i[interfaces repl])
          return "\n" if repl.nil? || !repl.key?(:prefix) # default

          repl[:prefix]
        end

        def self.build_postfix(cartridge)
          repl = Logic::Helpers::Hash.fetch(cartridge, %i[interfaces repl])
          return "\n" if repl.nil? || !repl.key?(:postfix) # default

          repl[:postfix]
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
