require 'blog-couchdb'

app = Capcode.application( :db_config => "blog-couchdb.yml" ) do |c|
  admin = User.find_by_login( "admin" )
  if admin.nil?
    puts "Create admin user..."
    admin = User.create( :login => "admin", :passwd => "admin" )
  end
  puts "Log as admin with : \n\tlogin = #{admin.login}\n\tpassword = #{admin.passwd}"
end

run app