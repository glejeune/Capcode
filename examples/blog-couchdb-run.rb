require 'blog-couchdb'

Capcode.run( :port => 3001, :host => "localhost", :db_config => "blog-couchdb.yml" ) do |c|
  admin = User.find_by_login( "admin" )
  if admin.nil?
    puts "Create admin user..."
    admin = User.create( :login => "admin", :passwd => "admin" )
  end
  puts "Admin user : \n\tlogin = #{admin.login}\n\tpassword = #{admin.passwd}"
end