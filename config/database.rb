#!/user/bin/env ruby
#coding: utf-8

# database
Time.zone = 'UTC'
ActiveRecord::Base.time_zone_aware_attributes = true
ActiveRecord::Base.default_timezone = :utc
ActiveRecord::Base.record_timestamps = true
# see http://stackoverflow.com/questions/18139003/how-to-solve-an-error-in-herokus-config-database-yml-file-mapping-values-are-n
dbconfig = YAML.load(ERB.new(File.read(File.join("config","database.yml"))).result)
ActiveRecord::Base.establish_connection dbconfig[ENV['RACK_ENV'] || 'development']
