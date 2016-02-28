class ApplicationController < ActionController::Base
  protect_from_forgery

  before_action :json_format, if: :api_controller?
  before_action :authenticate_user!
  after_action :verify_authorized, except: :index, unless: :devise_controller?

  unless Rails.env.development?
    around_action :alert_if_slow
  end

  include Pundit
  rescue_from Pundit::NotAuthorizedError do |exception|
    # TODO: what should we actually do here?
    render text: "Not Authorized", status: 403
  end

  private

  def after_sign_in_path_for user
    if Video.new(user).seen?
      root_path
    else
      welcome_path
    end
  end

  def sort_table prefix=nil
    @_sort_table_registry ||= SortTable::Registry.new
    @_sort_table_registry.build(prefix, params) { |t| yield t }
  end

  def save_form reform, *args
    valid = reform.validate *args
    authorize reform
    reform.save if valid
    valid
  end

  def alert_if_slow
    start = Time.now
    yield
    duration = Time.now - start
    if duration > Rails.configuration.slow_timeout.seconds
      Notification.send :slow, "`#{params[:controller]}##{params[:action]}` took #{duration} for user #{current_user.try(:id) || '??'} (`#{request.path}`)"
    end
  end

  def api_controller?
    false
  end

  def json_format
    request.format = :json
  end
end
