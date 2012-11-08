# -*- encoding : utf-8 -*-
ActionMailer::Base.smtp_settings = {
  :address        => 'smtp.sendgrid.net',
  :port           => '587',
  :authentication => :plain,
  :user_name      => 'app1875752@heroku.com',
  :password       => 'pdgvrrxc',
  :domain         => 'heroku.com'
}
ActionMailer::Base.delivery_method = :smtp
