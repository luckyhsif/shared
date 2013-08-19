#!/user/bin/env ruby
#coding: utf-8

module IGE_Agent_Admin::Application
  module EmailHelpers
  
    def build_messge(body_template, template_locals)
      email_body = slim(body_template, layout: false, locals: template_locals )
      type = 'text/html'
      return email_body, type
    end

    def send_email(to,from,subject, type, message)
      if self.settings.environment == :test
          puts "simulate sending email from #{from} to #{to} with subject #{subject}"
      elsif self.settings.environment == :development # assumed to be on your local machine
        # mountain-lion turned off sendmail by default.
        # see http://apple.stackexchange.com/questions/54051/sendmail-error-on-os-x-mountain-lion
        # to turn it on.
        Pony.mail :to => to, :via =>:sendmail,  # might not work on Windows!
          :charset => 'UTF-8',
          :from => from, :subject => subject,
          :headers => { 'Content-Type' => type }, :body => message
      elsif self.settings.environment == :production # assumed to be Heroku
        Pony.mail :to => to, :from => from, :subject => subject,
          :headers => { 'Content-Type' => type }, :body => message, :via => :smtp,
          :via_options => {
            :address => 'smtp.sendgrid.net',
            :port => 25,
            :authentication => :plain,
            :user_name => ENV['SENDGRID_USERNAME'],
            :password => ENV['SENDGRID_PASSWORD'],
            :domain => ENV['SENDGRID_DOMAIN'] }
      end
    end

    def send_email_to(email_address, subject, body_template, template_locals)
      email_body, type = build_messge(body_template,template_locals)
      send_email(email_address,app_info['email']['no_reply'],subject, type, email_body)
    end

    def send_notification_email(from_email_address, subject, body_template, template_locals)
      email_body, type = build_messge(body_template,template_locals)
      send_email(app_info['email']['notification'],from_email_address,subject, type, email_body)
    end

  end
end
