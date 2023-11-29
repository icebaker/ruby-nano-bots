# frozen_string_literal: true

require_relative 'embedding'
require_relative '../logic/cartridge/safety'

module NanoBot
  module Components
    class Adapter
      def self.apply(params, cartridge)
        content = params[:content]

        raise StandardError, 'conflicting adapters' if %i[fennel lua clojure].count { |key| !params[key].nil? } > 1

        call = {
          parameters: %w[content], values: [content],
          safety: { sandboxed: Logic::Cartridge::Safety.sandboxed?(cartridge) }
        }

        if params[:fennel]
          call[:source] = params[:fennel]
          content = Components::Embedding.fennel(**call)
        elsif params[:clojure]
          call[:source] = params[:clojure]
          content = Components::Embedding.clojure(**call)
        elsif params[:lua]
          call[:source] = params[:lua]
          content = Components::Embedding.lua(**call)
        end

        "#{params[:prefix]}#{content}#{params[:suffix]}"
      end
    end
  end
end
