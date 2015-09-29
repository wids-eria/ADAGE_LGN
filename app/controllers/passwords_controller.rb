class PasswordsController < Devise::PasswordsController
  prepend_view_path 'app/views/devise'
  
  def edit
 	reset_session
    super
  end
end
