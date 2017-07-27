require 'redcarpet'
require 'redcarpet/render_strip'

module Textilizable
  extend ActiveSupport::Concern

  module ClassMethods

    private

    def textilizable(*arr)
      arr.each do |a|
        define_method "#{a}_plain" do
          as_plaintext.render(self[a.to_s])
        end

        define_method "#{a}_source" do
          self.send("#{a.to_s}_before_type_cast".to_sym)
        end

        define_method(a) do |*args|
          type_options = %w( plain source)
          type = args.first
          if type.nil? && self[a]
            as_markdown.render(self[a])
          elsif type.nil? && self[a].nil?
            nil
          elsif type_options.include?(type.to_s)
            self.send("#{a}_#{type}")
          else
            raise "I don't understand the `#{type}' option.  Try #{type_options.join(' or ')}."
          end
        end
      end
    end
  end

  included do
    def as_markdown
      @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: false, tables: true, hard_wrap: true)
    end

    def as_plaintext
      @plain ||= Redcarpet::Markdown.new(Redcarpet::Render::StripDown)
    end
  end
end
