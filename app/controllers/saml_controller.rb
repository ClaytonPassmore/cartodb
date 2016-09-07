require 'yaml'

class SamlController < ApplicationController
 layout 'frontend'
 skip_before_filter :verify_authenticity_token 

 before_filter :load_organization
 # acs method
 def initialize
   logger.info "initialized the saml"
   @signup_source = 'SAML Sign-On'
   @signup_errors = {}
 end

 def acs
    logger.info "inside smal acs"
    user_info = SamlAuthenticator.get_user_info(params)
    if user_info == nil
       @organization = BBOrganization.new
       @signup_errors[:saml_error] = ["You are not authorized to run the functionality"]
       logger.error @signup_errors[:saml_error].first
       render 'shared/signup_issue'
       return
    end

    scope = user_info.username

    logger.info "uuid after calling Saml " + scope

    user = authenticate!(:saml_header, {}, :scope => scope)

    if user == nil
      @organization = BBOrganization.new
      @signup_errors[:saml_error] = ["Single sign on athentication failed."]
      logger.error @signup_errors[:saml_error].first
      render 'shared/signup_issue'
    else
       relay_state = JSON.parse(params[:RelayState])
       wakeup_path = relay_state["wakeup_state"]["wakeup_path"]
       
       case wakeup_path

       #datasets
       when "datasets"
	 tag = relay_state["wakeup_state"]["tag"]
	 redirect_to CartoDB.url(self, 'datasets_tag', { tag: tag }, user)
       else
	 redirect_to CartoDB.url(self, 'dashboard', {trailing_slash: true}, user)
       end
    end

 end

 def handle_relay_state params

     
   
   #redirect_to datasets_tag_url(user: user.username, tag:":commodities")
   #redirect_to CartoDB.url(self, 'datasets_tag', { tag: "commodities" }, user)
 end

 def load_organization
    subdomain = CartoDB.subdomain_from_request(request)
    @organization = Carto::Organization.where(name: subdomain).first if subdomain
 end


end #end of the controller class

class UserInfo < Sequel::Model
end

class BBOrganization
  class BBOwner
    def email
     "bshaklton@bloomberg.net"
    end
  end

  def initialize
  @owner = BBOwner.new
  end

  def name
     "PWHO MAPS"
  end
  def color
     "#FF5522"
  end
  def owner
     @owner
  end
end


