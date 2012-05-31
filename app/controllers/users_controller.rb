class UsersController < ApplicationController
  action :index do
    presenter :params => :name
  end

  action :show do
    presenter :params => :id
  end

  action :new

  action :edit do
    presenter :params => :id
  end

  action :create do
    manager :params => :user do |response|
      response.success do |user|
        flash[:notice] = 'User was successfully created.'
        redirect_to(user)
      end
      
      response.failure do |user|
        presenter :user => user
        render :action => "new"
      end
    end
  end

  action :update do
    manager :params => [:id, :user] do |response|
      response.success do |user|
        flash[:notice] = 'User was successfully updated.'
        redirect_to(user)
      end
      
      response.failure do |user|
        presenter :user => user
        render :action => "edit"
      end
    end
  end

  action :destroy do
    manager :params => :id do
      redirect_to(users_url)
    end
  end
end