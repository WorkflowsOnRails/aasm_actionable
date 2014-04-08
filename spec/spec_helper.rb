Bundler.require(:default, :development)

require 'tmpdir'
require 'active_support/core_ext'


SimpleCov.start do
  add_filter "/spec/"
end

require_relative '../lib/aasm_actionable/controller_mixin'

module SpecHelper
  # Check if the stubbed fake controller has received a render request
  # with the given partials specified as local variables.
  def expect_to_have_rendered(controller, partials)
    expect(controller).to have_received(:render_to_string) do |hash|
      actions = hash[:locals][:actions].map(&:partial).sort
      expect(actions).to eq(partials.sort)
    end
  end
end
