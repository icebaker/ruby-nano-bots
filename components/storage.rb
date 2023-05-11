# frozen_string_literal: true

require 'babosa'

require_relative '../logic/helpers/hash'

module NanoBot
  module Components
    class Storage
      def self.build_path_and_ensure_state_file!(key, cartridge)
        path = [
          Logic::Helpers::Hash.fetch(cartridge, %i[state directory]),
          ENV.fetch('NANO_BOTS_STATE_DIRECTORY', nil)
        ].find do |candidate|
          !candidate.nil? && !candidate.empty?
        end

        path = "#{user_home!.sub(%r{/$}, '')}/.local/state/nano-bots" if path.nil?

        path = "#{path.sub(%r{/$}, '')}/nano-bots-rb/#{cartridge[:name].to_slug.normalize}"
        path = "#{path}/#{cartridge[:version].to_slug.normalize}/#{key.to_slug.normalize}"
        path = "#{path}/state.json"

        FileUtils.mkdir_p(File.dirname(path))

        File.write(path, JSON.generate({ key:, history: [] })) unless File.exist?(path)

        path
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

          partial = path.sub(%r{^\.?/}, '')

          candidates << "#{directory}/#{partial}"
          candidates << "#{directory}/#{partial}.yml"
          candidates << "#{directory}/#{partial}.yaml"
        end

        directory = "#{user_home!.sub(%r{/$}, '')}/.local/share/nano-bots/cartridges"

        partial = File.join(File.dirname(partial), File.basename(partial, File.extname(partial)))

        partial = path.sub(%r{^\.?/}, '')

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
