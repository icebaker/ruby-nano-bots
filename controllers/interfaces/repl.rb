# frozen_string_literal: true

require 'pry'
require 'rainbow'

require_relative '../../logic/helpers/hash'

module NanoBot
  module Controllers
    module Interfaces
      module REPL
        def self.start(cartridge, session)
          if Logic::Helpers::Hash.fetch(
            cartridge, %i[interfaces repl prefix]
          )
            session.print(Logic::Helpers::Hash.fetch(cartridge,
                                                     %i[interfaces repl prefix]))
          end

          session.boot(mode: 'repl')

          session.print(Logic::Helpers::Hash.fetch(cartridge, %i[interfaces repl postfix]) || "\n")

          session.flush

          prompt = build_prompt(cartridge[:interfaces][:repl][:prompt])

          Pry.config.prompt = Pry::Prompt.new(
            'REPL',
            'REPL Prompt',
            [proc { prompt }, proc { 'MISSING INPUT' }]
          )

          Pry.commands.block_command(/(.*)/, 'handler') do |line|
            if Logic::Helpers::Hash.fetch(
              cartridge, %i[interfaces repl prefix]
            )
              session.print(Logic::Helpers::Hash.fetch(
                              cartridge, %i[interfaces repl prefix]
                            ))
            end

            session.evaluate_and_print(line, mode: 'repl')
            session.print(Logic::Helpers::Hash.fetch(cartridge, %i[interfaces repl postfix]) || "\n")
            session.flush
          end

          Pry.start
        end

        def self.build_prompt(prompt)
          result = ''

          prompt.each do |partial|
            result += if partial[:color]
                        Rainbow(partial[:text]).send(partial[:color])
                      else
                        partial[:text]
                      end
          end

          result
        end
      end
    end
  end
end
