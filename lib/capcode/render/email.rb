begin
  require 'mail'
rescue LoadError => e
  raise MissingLibrary, "mail could not be loaded (is it installed?): #{e.message}"
end

module Capcode
  module Helpers
    def render_email( f, _ ) #:nodoc:
      if @smtp.nil?
        @smtp = { :server => "127.0.0.1", :port => 25 }.merge(Capcode.options[:email] || {})
      end

      # Set SMTP info
      conf = Mail::Configuration.instance.defaults
      conf.smtp @smtp[:server], @smtp[:port]
      
      # Create mail
      mail = Mail.new()

      # Mail Header
      mail.from = f[:from]
      mail.subject = f[:subject] if f.has_key?(:subject)      
      [:to, :cc, :bcc].each do |t|
        next unless f.has_key?(t) and not f[t].nil?
        if f[t].class == Array
          mail[t] = f[t]
        else
          mail[t] = f[t].to_s.split( ',' ).map { |x| x.strip }
        end
      end
      mail.message_id = f[:message_id] if f.has_key?(:message_id)      
      
      # Mail Body
      if f[:body].class == String
        mail.body = f[:body]
      elsif f[:body].class == Hash
        if f[:body].has_key?(:html)
          mail.html_part = Mail::Part.new
          mail.html_part.content_type = f[:body][:html].delete(:content_type) { |_| 'text/html' }
          mail.html_part.body = render( f[:body][:html] )
        end
        if f[:body].has_key?(:text)
          mail.text_part = Mail::Part.new
          mail.text_part.body = render( f[:body][:text] )
        end        
      end
      
      # Mail Attachment
      if f.has_key?(:file)
        f[:file] = [f[:file]] unless f[:file].class == Array
        f[:file].each do |file|
          data = {}
          if file.class == Hash
            data[:filename] = file.delete(:filename) if file.has_key?(:filename)
            data[:mime_type] = file.delete(:mime_type) if file.has_key?(:mime_type)
            data[:data] = self.send(file[:data])
          else 
            data = { :data => render( :static => file, :exact_path => false ), :filename => File.basename(file) }
          end
          mail.add_file(data)
        end
      end

      begin
        mail.deliver!
        render f[:ok]
      rescue
        render f[:error]
      end
    end
  end
end