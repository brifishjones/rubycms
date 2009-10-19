class Subscription < ActiveRecord::Base
  has_many :pages
end
