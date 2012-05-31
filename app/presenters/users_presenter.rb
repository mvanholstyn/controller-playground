class UsersPresenter < Presenter
  attr_accessor :name, :id, :user
  
  def users
    @users ||= User.find(:all, :conditions => ["first_name LIKE :name OR last_name LIKE :name", {:name => "%#{name}%"}])
  end
  
  def user
    @user ||= id ? User.find(id) : User.new
  end
end