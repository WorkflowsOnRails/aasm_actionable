module AasmActionable
  # A StateAction groups together the various attributes for an action
  # being rendered, such as it's title, HTML ID, and the name of the
  # partial to render.
  #
  # Note that the HTML ID is not unique, so it is not currently possible
  # to call render_state_actions multiple times for the same taskable type
  # on one page.
  #
  # @author Brendan MacDonell
  class StateAction
    attr_reader :title, :id, :partial

    def initialize(event, action_view_prefix)
      @title = event.to_s.titleize
      @id = "action-#{event}"
      @partial = "#{action_view_prefix}/#{event}"
    end
  end

  # The ControllerMixin concern implements a controller-based helper
  # that can automatically render those actions which can be performed by a
  # user on a taskable. In order to use it, you must do the following:
  #
  # 1. Create a Pundit policy for the taskable, with one method named
  #    <event>? for every event in the taskable's state machine. For
  #    example, define submit? if there is a submit event.
  #
  # 2. Create a partial with the same name as every event defined in the
  #    taskable's state machine. For example, create _submit.html.erb if
  #    there is a submit event.
  #
  # Partials are looked up in the view directory with the same name as the
  # controller by default. You can change this by providing the method
  # action_view_prefix(event) in your controller, and returning the view
  # prefix you wish to look up partials in.
  #
  # @author Brendan MacDonell
  module ControllerMixin
    extend ActiveSupport::Concern

    included do
      helper_method :render_state_actions
    end

    def action_view_prefix(event)
      controller_name
    end

    def render_state_actions(taskable)
      a_policy = policy(taskable)
      events = taskable.aasm.events
        .select { |event| a_policy.send("#{event}?") }

      actions = events.map do |event|
        StateAction.new(event, action_view_prefix(event))
      end
      actions.sort_by! {|action| action.title}

      rendered = render_to_string partial: 'aasm_actionable/list',
                                  locals: {actions: actions, taskable: taskable}
      rendered.html_safe
    end
  end
end
