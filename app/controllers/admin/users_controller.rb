class Admin::UsersController < ApplicationController
  def select
    authorize :user, :edit?
    redirect_to edit_admin_user_path(params[:user][:id])
  end

  def new
    @user = NewUserForm.new current_user.country.users.new, submitter: current_user
    authorize @user
  end

  def create
    @user = NewUserForm.new current_user.country.users.new, submitter: current_user
    if save_form @user, params[:user]
      redirect_to country_roster_path, notice: I18n.t!("flash.user.added")
    else
      render :new
    end
  end

  def edit
    @user = UserForm.new User.find(params[:id]), submitter: current_user
    authorize @user
  end

  def update
    @user = UserForm.new User.find(params[:id]), submitter: current_user
    if save_form @user, params[:user]
      redirect_to country_roster_path, @user.flash
    else
      render :edit
    end
  end

  def inactivate
    user = User.find params[:id]
    authorize user
    user.inactivate!
    redirect_to country_roster_path, notice: I18n.t!("flash.user.inactive_user", user: user.name)
  end

  def activate
    user = User.find params[:id]
    authorize user
    Notification.send :user_activated, "#{user.email} re-activated by #{current_user.email}"
    user.activate!
    redirect_to country_roster_path, notice: I18n.t!("flash.user.active_user", user: user.name)
  end
end
