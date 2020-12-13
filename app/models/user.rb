class User < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  has_secure_password

  after_destroy :ensure_an_admin_remains

  private
  def ensure_an_admin_remains
    if User.count.zero?
      raise "Останного користувача неможливо видалити"
    end
  end
end
