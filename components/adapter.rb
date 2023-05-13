# frozen_string_literal: true

require 'sweet-moon'

module NanoBot
  module Components
    class Adapter
      def self.apply(_direction, params)
        content = params[:content]

        if params[:fennel] && params[:lua]
          raise StandardError, 'Adapter conflict: You can only use either Lua or Fennel, not both.'
        end

        if params[:fennel]
          content = fennel(content, params[:fennel])
        elsif params[:lua]
          content = lua(content, params[:lua])
        end

        "#{params[:prefix]}#{content}#{params[:suffix]}"
      end

      def self.fennel(content, expression)
        path = "#{File.expand_path('../static/fennel', __dir__)}/?.lua"
        state = SweetMoon::State.new(package_path: path).fennel
        state.fennel.eval("(set _G.adapter (fn [content] #{expression}))")
        adapter = state.get(:adapter)
        adapter.call([content])
      end

      def self.lua(content, expression)
        state = SweetMoon::State.new
        state.eval("adapter = function(content) return #{expression}; end")
        adapter = state.get(:adapter)
        adapter.call([content])
      end
    end
  end
end
