#!/user/bin/env ruby
#coding: utf-8

module IGE_Agent_Admin::Application
  module ApplicationHelpers
  
    def app_info
      return self.settings.info
    end

    # generate a localised page title
    # comprising of the site name and then, if available,
    # a page specific name.
    def page_title
      if defined?(@title) && !(@title.nil? || @title.empty?)
        return t.site.title_format(t.site.name, @title)
      end
      return t.site.name 
    end
    
    def description
      if defined?(@description) && !(@description.nil? || @description.empty?)
        return t.site.description_format(t.site.description, @description)
      end
      return t.site.description
    end

    def keywords
      kwds = t.site.keywords
      kwds << ", #{@keywords}" if defined?(@keywords) && !(@keywords.nil? || @keywords.empty?)
      return kwds
    end
    
    def image
      img = (defined?(@image) && !(@image.nil? || @image.empty?)) ? @image : nil
      img = app_info['image'] if img.nil?
      img = t.site.image if img.nil? && t.has_key?('site.image')
      return img.nil? ? nil : "#{request.scheme}://#{request.host}/images/#{img}"
    end
  end
end
