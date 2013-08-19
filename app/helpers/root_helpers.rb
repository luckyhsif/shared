#!/user/bin/env ruby
#coding: utf-8

module IGE_Agent_Admin::Application
  module RootHelpers
  
    def is_spam?
      # see http://www.sitepoint.com/captcha-alternatives/
      return true if params[:email_honey].nil? || !params[:email_honey].empty? #5
      return true if params[:timer].nil? || params[:timer].empty?
      begin
        form_time = DateTime.rfc3339(params[:timer]).to_time.utc
        return true if Time.now.utc - form_time < 30.0                           #8
      rescue ArgumentError => ae
        # invalid timer field.
        return true
      end
      # TODO: Check user agent and referrer
      return false
    end

  end
end
