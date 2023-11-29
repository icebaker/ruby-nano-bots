# frozen_string_literal: true

require 'babosa'

require_relative '../logic/helpers/hash'
require_relative 'crypto'

module NanoBot
  module Components
    class Storage
      def self.end_user(cartridge, environment)
        user = ENV.fetch('NANO_BOTS_END_USER', nil)

        if cartridge[:provider][:id] == 'openai' &&
           !cartridge[:provider][:settings][:user].nil? &&
           !cartridge[:provider][:settings][:user].to_s.strip.empty?
          user = cartridge[:provider][:settings][:user]
        end

        candidate = environment && (
          environment['NANO_BOTS_END_USER'] ||
          environment[:NANO_BOTS_END_USER]
        )

        user = candidate if !candidate.nil? && !candidate.to_s.strip.empty?

        user = if user.nil? || user.to_s.strip.empty?
                 'unknown'
               else
                 user.to_s.strip
               end

        Crypto.encrypt(user, soft: true)
      end

      def self.build_base_path_and_ensure_state_directory!(key, cartridge, environment: {})
        path = [
          Logic::Helpers::Hash.fetch(cartridge, %i[state directory]),
          ENV.fetch('NANO_BOTS_STATE_DIRECTORY', nil)
        ].find do |candidate|
          !candidate.nil? && !candidate.empty?
        end

        path = "#{user_home!.sub(%r{/$}, '')}/.local/state/nano-bots" if path.nil?

        path = "#{path.sub(%r{/$}, '')}/ruby-nano-bots"

        path = "#{path}/#{cartridge[:meta][:author].to_slug.normalize}"
        path = "#{path}/#{cartridge[:meta][:name].to_slug.normalize}"
        path = "#{path}/#{cartridge[:meta][:version].to_s.gsub('.', '-').to_slug.normalize}"
        path = "#{path}/#{end_user(cartridge, environment)}"

        if key.nil?
          path = "#{path}/temp-#{Crypto.encrypt(SecureRandom.hex, soft: true)}"
        else
          path = "#{path}/#{Crypto.encrypt(key, soft: true)}"
        end
        path = "#{path}/state.json"
      end

      def self.build_path_and_ensure_state_file!(key, cartridge, environment: {})
        path = [
          Logic::Helpers::Hash.fetch(cartridge, %i[state directory]),
          ENV.fetch('NANO_BOTS_STATE_DIRECTORY', nil)
        ].find do |candidate|
          !candidate.nil? && !candidate.empty?
        end

        path = "#{user_home!.sub(%r{/$}, '')}/.local/state/nano-bots" if path.nil?

        path = "#{path.sub(%r{/$}, '')}/ruby-nano-bots"

        path = "#{path}/#{cartridge[:meta][:author].to_slug.normalize}"
        path = "#{path}/#{cartridge[:meta][:name].to_slug.normalize}"
        path = "#{path}/#{cartridge[:meta][:version].to_s.gsub('.', '-').to_slug.normalize}"
        path = "#{path}/#{end_user(cartridge, environment)}"
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
