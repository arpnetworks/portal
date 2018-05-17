module JobsHelper
  def jobs_colspan(admin, action_name)
    if admin && action_name == 'index'
      7
    else
      4
    end
  end
end
