$:.unshift( "../lib" )
require 'capcode'

module Capcode
  before_filter :for_all, :except => [:SecretPage]
  before_filter :only_one, :only => [:One]
  before_filter :except_three, :except => [:Three, :SecretPage]
  before_filter :you_will_never_see_this_page, :only => [:SecretPage]
  
  def for_all
    @was ||= ""
    @was << "for_all "
    
    return nil
  end
  
  def only_one
    @was ||= ""
    @was << "only_one "

    return nil
  end
  
  def except_three
    @was ||= ""
    @was << "except_three "

    return nil
  end
  
  def you_will_never_see_this_page
    redirect Capcode::Index
  end
  
  class Index < Route "/"
    def get
      render :markaby => :index
    end
  end
  
  class One < Route "/one"
    def get
      @value = Time.now
      @wwas = @was
      @was = ""
      render :markaby => :count
    end
  end
  
  class Two < Route "/two"
    def get
      @value = Time.now
      @wwas = @was
      @was = ""
      render :markaby => :count
    end
  end
  
  class Three < Route "/three"
    def get
      @value = Time.now
      @wwas = @was
      @was = ""
      render :markaby => :count
    end
  end

  class SecretPage < Route "/secret"
    def get
      render :markaby => :secret
    end
  end
end

module Capcode::Views
  def index
    html do
      body do
        a "One", :href => URL(Capcode::One); br
        a "Two", :href => URL(Capcode::Two); br
        a "Three", :href => URL(Capcode::Three); br
        a "SecretPage", :href => URL(Capcode::SecretPage); br
      end
    end
  end
  
  def count
    html do
      body do
        span "I was in : #{@wwas}"; br
        span "It's #{@value}"
      end
    end
  end

  def secret
    html do
      body do
        span "If you see this page, there is a "; b "bug !!!"
      end
    end
  end
end

Capcode.run()