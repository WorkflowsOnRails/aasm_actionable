require 'rails/generators/base'


module AasmActionable
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      desc 'Install a copy of the default aasm_actionable views'
      source_root File.expand_path('../../../../app/views', __FILE__)

      def copy_views
        directory 'aasm_actionable', 'app/views/aasm_actionable'
      end
    end
  end
end
