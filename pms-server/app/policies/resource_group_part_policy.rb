class ResourceGroupPartPolicy<ApplicationPolicy
  def update?
    user.av? || user.system? || user.admin?
  end
end