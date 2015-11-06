Dir[File.join(File.dirname(__FILE__), "command/**/", "*.rb")].each do |file|
  require file
end
