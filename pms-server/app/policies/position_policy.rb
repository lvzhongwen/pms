class PositionPolicy<ApplicationPolicy
	def update?
		user.av? || user.system? || user.admin?
		true
	end
end