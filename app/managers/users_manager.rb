class UsersManager < Manager
  attr_accessor :id, :user
  
  def create
    user = User.new(self.user)
    if user.save
      respond(:success, user)
    else
      respond(:failure, user)
    end
  end
  
  def update
    user = User.find(id)
    if user.update_attributes(self.user)
      respond(:success, user)
    else
      respond(:failure, user)
    end
  end
  
  def destroy
    User.destroy(id)
  end
end