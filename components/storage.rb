# frozen_string_literal: true

require 'babosa'

require_relative '../logic/helpers/hash'
require_relative './crypto'

module NanoBot
  module Components
    class Storage
      def self.build_path_and_ensure_state_file!(key, cartridge, environment: {})
        path = [
          Logic::Helpers::Hash.fetch(cartridge, %i[state directory]),
          ENV.fetch('NANO_BOTS_STATE_DIRECTORY', nil)
        ].find do |candidate|
          !candidate.nil? && !candidate.empty?
        end

        path = "#{user_home!.sub(%r{/$}, '')}/.local/state/nano-bots" if path.nil?

        prefix = environment && (
          environment['NANO_BOTS_USER_IDENTIFIER'] ||
          environment[:NANO_BOTS_USER_IDENTIFIER]
        )

        path = "#{path.sub(%r{/$}, '')}/ruby-nano-bots/vault"

        if prefix
          normalized = prefix.split('/').map do |part|
            Crypto.encrypt(
              part.to_s.gsub('.', '-').force_encoding('UTF-8').to_slug.normalize,
              soft: true
            )
          end.join('/')

          path = "#{path}/#{normalized}"
        end

        path = "#{path}/#{cartridge[:meta][:author].to_slug.normalize}"
        path = "#{path}/#{cartridge[:meta][:name].to_slug.normalize}"
        path = "#{path}/#{cartridge[:meta][:version].to_s.gsub('.', '-').to_slug.normalize}"
        path = "#{path}/#{Crypto.encrypt(key, soft: true)}"
        path = "#{path}/state.json"

        FileUtils.mkdir_p(File.dirname(path))

        unless File.exist?(path)
          File.write(
            path,
            Crypto.encrypt(JSON.generate({ key:, history: [] }))
          )
        end

        path
      end

      def self.cartridges_path
        [
          ENV.fetch('NANO_BOTS_CARTRIDGES_DIRECTORY', nil),
          "#{user_home!.sub(%r{/$}, '')}/.local/share/nano-bots/cartridges"
        ].compact.uniq.filter { |path| File.directory?(path) }.compact.first
      end

      def self.cartridge_path(path)
        partial = File.join(File.dirname(path), File.basename(path, File.extname(path)))

        candidates = [
          path,
          "#{partial}.yml",
          "#{partial}.yaml"
        ]

        unless ENV.fetch('NANO_BOTS_CARTRIDGES_DIRECTORY', nil).nil?
          directory = ENV.fetch('NANO_BOTS_CARTRIDGES_DIRECTORY').sub(%r{/$}, '')

          partial = File.join(File.dirname(partial), File.basename(partial, File.extname(partial)))

          partial = partial.sub(%r{^\.?/}, '')

          candidates << "#{directory}/#{partial}"
          candidates << "#{directory}/#{partial}.yml"
          candidates << "#{directory}/#{partial}.yaml"
        end

        directory = "#{user_home!.sub(%r{/$}, '')}/.local/share/nano-bots/cartridges"

        partial = File.join(File.dirname(partial), File.basename(partial, File.extname(partial)))

        partial = partial.sub(%r{^\.?/}, '')

        candidates << "#{directory}/#{partial}"
        candidates << "#{directory}/#{partial}.yml"
        candidates << "#{directory}/#{partial}.yaml"

        candidates = candidates.uniq

        candidates.find do |candidate|
          File.exist?(candidate) && File.file?(candidate)
        end
      end

      def self.user_home!
        [Dir.home, `echo ~`.strip, '~'].find do |candidate|
          !candidate.nil? && !candidate.empty?
        end
      end
    end
  end
end
