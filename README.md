aasm_actionable
===============

aasm_actionable is a Rails extension that helps factor out boilerplate state and authorization conditionals from view code. Using [pundit](https://github.com/elabs/pundit) for authorization, it allows developers to write partials for user actions that are automatically displayed to the user if the model is in an appropriate state, and the user has sufficient permissions.


Installation
------------

Add `aasm_actionable` to your Gemfile, and run Bundler to install it. You will also want to install Pundit, as described in the [Pundit documentation](https://github.com/elabs/pundit#installation).


Using aasm_actionable
---------------------

Each action that aasm_actionable may display requires the developer to provide three things:

1. An event with the same name as the desired action, ex. `do_action`;
2. A method on the pundit policy for the model on which the action is to be performed, ex. `do_action?`; and
3. A partial for the model with the same name as the action, ex. `mymodel/_do_action.html.erb`.
 
Additionally, you may wish to create a controller method and route to handle the action being performed. By convention, the controller method should have the same name as the action, ie. `do_action` for the example above.

Once you have provided one or more actions for a model, you can render a model instance's available actions by including `AasmActionable::ControllerMixin` in your controller, and adding `<%= render_state_actions my_instance %>` in your view. The default template uses styles and code from [Bootstrap 3](http://getbootstrap.com/), so you should either ensure that it is included in your application, or change the default template (see Custom Rendering below.) 


Example
-------

Consider the following contrived Order model (in `app/models/order.rb`) for a (trivial) online store:

```rb
class Order < ActiveRecord::Base
  include AASM
  aasm do
    state :new, initial: true
    state :processing
    state :shipping

    event :confirm do
      transitions from: :new, to: :processing
    end
    event :dispatch do
      transitions from: :processing, to: :shipping
    end
  end
end
```

Suppose that users in an inventory tracking role manually confirm an order by double-checking if the item is in stock, while users in shipping are responsible for marking an order as dispatched. We would like to render appropriate actions on a view of the order, depending on the order's state and the role that the user occupies. Confirmation does not add any new information to the order, but dispatching the order requires a shipping number.

First, we need to define an policy to describe which users can perform which actions. In `app/policies/order.rb`, we create a new `OrderPolicy` class, and define appropriate `confirm?` and `dispatch?` methods:

```rb
class OrderPolicy < ApplicationPolicy
  # ... other default policy methods (ex. show?) omitted for conciseness.

  def confirm?
    user.in_role? :inventory
  end

  def dispatch?
    user.in_role? :shipping
  end
end
```

Next, we add methods to the order controller to handle these actions, along with the mixin:

```rb
class OrderController < ApplicationController
  include AasmActionable::ControllerMixin

  # ... other controller methods omitted ...
  
  def show
    @order = find_order
    authorize @order
  end
  
  def confirm
    @order = find_order
    authorize @order

    if order.confirm!
      redirect_to order
    else
      # ... handle the error and re-render the order page ...
    end
  end
  
  def dispatch
    @order = find_order
    authorize @order
    
    dispatch_params = params.require(:order).permit(:shipping_number)
    order.assign_attributes(dispatch_params)

    if order.dispatch!
      redirect_to order
    else
      # ... handle the error and re-render the order page ...
    end
  end
  
  private
  
  def find_order
    Order.find(params[:id])
  end
end
```

(You may want to consider using [responders](https://github.com/plataformatec/responders) or a similar library to cut down on boilerplate in your custom controller methods.)

We must also add the new actions to `config/routes.rb`:

```rb
  # ... other routes omitted ...
  
  resources :orders do
    member do
      post 'confirm'
      post 'dispatch'
    end
  end
  
  # ...
```

Next, we create a partial for each action. For example, for the dispatch action we might write the following `app/views/order/_dispatch.html.erb`:

```erb
<% form_for @order, url: dispatch_order_path, method: :post do %>
  <div>
    <%= f.label :shipping_number %>:
    <%= f.text_field :shipping_number %>
  </div>
  <%= f.submit "Dispatch" %>
<% end %>
```

Finally, we render the actions in the order view by adding `<%= render_state_actions @order %>` to `app/views/order/show.html.erb`.


Custom Rendering
----------------

The default template for `aasm_actionable` can be customized as necessary. Run `rails g aasm_actionable:views` to copy the template to app/views/aasm_actionable/_list.html.erb, and edit it as required.
