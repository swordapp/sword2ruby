require 'atom/service'

module Sword2Ruby
  
  #Extend existing Atom::Service with Sword methods
  #
  #For more information, see the Sword2 specification: {section 6.1. "Retrieving a Service Document"}[http://sword-app.svn.sourceforge.net/viewvc/sword-app/spec/tags/sword-2.0/SWORDProfile.html?revision=377#protocoloperations_retreivingservicedocument].
  class ::Atom::Service < ::Atom::Element
    
    #This method returns the URI object of the service document.
    def service_document_uri
      base.to_s
    end
    
    #This method returns the string value of the <sword:version> tag (usually contained in the Service Document),
    #or nil if it is not defined.
    def sword_version
      Utility.find_element_text(extensions, "sword:version")
    end

    #This method returns the integer value of the <sword:maxUploadSize> tag (usually contained in the Service Document),
    #or 0 if it is not defined.     
    def sword_max_upload_size
      Utility.find_element_integer(extensions, "sword:maxUploadSize")
    end
    
    #Retrieves and parses an Atom service document.
    #===Parameters
    #:\service_uri:: The URI to the Sword Service Document.
    #:connection:: (optional) Sword2Ruby::Connection object used to perform the operation. If not supplied, a new Connection object will be created.
    def initialize(service_uri, connection = Connection.new())
      Utility.check_argument_class('service_uri', service_uri, String)
      Utility.check_uri(service_uri)
      Utility.check_argument_class('connection', connection, Connection)
      
      
      super()

      @http = connection

      return if service_uri.empty?

      base = URI.parse(service_uri)

      rxml = nil

      res = connection.get(base, "Accept" => "application/atomsvc+xml")
     
      
      if res.is_a? Net::HTTPSuccess
        res.validate_content_type(["application/atomsvc+xml"])
        
        service = self.class.parse(res.body, base, self)

        #Update workspaces, collections and their feeds to use the Service's http connection
        set_http(connection)

        service
      else
       raise Sword2Ruby::Exception.new("Failed to do get(#{service_uri}): server returned #{res.code} #{res.message}")
      end

    end
    
    
    private
    #Update workspaces, collections and their feeds to use the Service's http connection
    #Unfortunately this is necessary because the atom-tools library does not propagate the
    #http connection object from Service to Workspace
    def set_http(connection)
      workspaces.each do |w|
        w.http = connection
        w.collections.each do |c|
          c.http = connection
          c.feed.http = connection
        end
      end
    end 
   
  end #class
end #module