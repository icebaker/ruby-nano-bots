# frozen_string_literal: true

require_relative 'embedding'

module NanoBot
  module Components
    class Adapter
      def self.apply(_direction, params)
        content = params[:content]

        raise StandardError, 'conflicting adapters' if %i[fennel lua clojure].count { |key| !params[key].nil? } > 1

        call = { parameters: %w[content], values: [content], safety: false }

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
