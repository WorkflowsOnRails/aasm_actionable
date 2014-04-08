# Unit tests covering the use of the aasm_actionable controller mixin.
# These tests evaluate the mixin within the context of a faked controller, and
# assert success or failure based on the partials the application attempts
# to render.
#
# @author Brendan MacDonell

require 'spec_helper'


class Proposal
  include ActiveModel::Model
  attr_accessor :aasm_state
  include AASM

  aasm do
    state :writing, initial: true
    state :reviewing
    state :completed

    event :submit do
      transitions from: :writing, to: :reviewing
      transitions from: :reviewing, to: :reviewing
    end

    event :return do
      transitions from: :reviewing, to: :writing
    end

    event :accept do
      transitions from: :reviewing, to: :completed
    end

    event :guarded do
      transitions from: [:reviewing, :completed], to: :completed, guard: :completed?
    end
  end
end

class ProposalPolicy
  def initialize(*args)
  end

  # By default, we return true (we can override this by adding appropriate
  # mocked methods to the policy object.)
  def method_missing(m, *args, &block)
    true
  end
end

# TODO: We really need to get better test isolation for the controller
#       mixin. There is no reason I should have to put this much effort
#       into a fake just to test the logic.
class ProposalController
  def self.helper_method(*args)
  end

  def controller_name
    'proposals'
  end

  def current_user
    nil
  end

  include Pundit
  include AasmActionable::ControllerMixin
end


describe AasmActionable do
  include SpecHelper

  before :each do
    @proposal = Proposal.new
    @controller = ProposalController.new

    allow(@controller).to receive(:render_to_string) { '' }
  end

  it 'filters actions based on the current state' do
    @controller.render_state_actions @proposal
    expect_to_have_rendered(@controller, ['proposals/submit'])
  end

  it 'filters actions based on the pundit policy' do
    # Ensure that the submit action is not performable by the current user.
    allow_any_instance_of(ProposalPolicy).to receive(:submit?) { false }
    @proposal.submit
    @controller.render_state_actions @proposal
    expect_to_have_rendered(@controller, ['proposals/accept', 'proposals/return'])
  end

  it 'filters actions based on dynamic guard conditions' do
    allow_any_instance_of(ProposalPolicy).to receive(:submit?) { false }
    @proposal.submit
    @proposal.accept
    @controller.render_state_actions @proposal
    expect_to_have_rendered(@controller, ['proposals/guarded'])
  end

  it 'uses the controller name as the target directory' do
    allow(@controller).to receive(:controller_name) { 'controller' }
    @controller.render_state_actions @proposal
    expect_to_have_rendered(@controller, ['controller/submit'])
  end
end
