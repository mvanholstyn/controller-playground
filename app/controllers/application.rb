# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'bd05d94a47f02ed86196ad75cd3db503'
  
  def self.action(name, &block)
    define_method(name) do
      instance_eval(&block) if block
      presenter unless @presenter
      manager unless @manager
    end
  end
  
  def presenter(*args)
    options = args.extract_options!
    presenter_class = args.first || UsersPresenter
    options = options.merge(params.slice(*options.delete(:params)))
    @presenter = presenter_class.new(options)
  end
  
  def manager(*args, &block)
    options = args.extract_options!
    manager_class = args.first.is_a?(Class) ? args.shift : UsersManager
    manager_action = args.shift || action_name
    @manager = manager_class.new(params.slice(*options[:params]))
    @manager.invoke!(manager_action, &block)
  end
end
