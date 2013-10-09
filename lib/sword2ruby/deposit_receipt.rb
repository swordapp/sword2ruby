module Sword2Ruby
  #The DepositReceipt object is returned following Post, Put and Delete operations on the Sword server.
  #In some cases (e.g. Post), an Atom::Entry will usually be returned describing the newly created entry. Operations such as Delete do not return an Atom::Entry.
  #If the Sword server does not automatically return the Atom::Entry but instead provides a link to it, the DepositReceipt object will automatically fetch it.
  #
  #For more information, see the Sword2 specification: {section 10 "Deposit Receipt"}[http://sword-app.svn.sourceforge.net/viewvc/sword-app/spec/tags/sword-2.0/SWORDProfile.html?revision=377#depositreceipt].
  class DepositReceipt
    
    #Boolean value indicating whether there is an Atom::Entry associated with this receipt.
    attr_reader :has_entry

    #The Atom::Entry associated with this receipt, or nil if not supplied. The Atom::Entry will be automatically fetched from the server when necessary.
    attr_reader :entry
    
    #The location header returned by the Sword server, usually after Posting or Putting. 
    attr_reader :location

    #The http status code returned by the Sword server.
    attr_reader :status_code
    
    #The http status message returned by the Sword server.
    attr_reader :status_message
    
    #Create a new DepositReceipt using the Response object returned by the server.
    #===Parameters
    #response:: the response object returned by the request
    #connection:: a Sword2Ruby::Connection object
    def initialize(response, connection)
      @location = response.header["location"]
      @status_code = response.code
      @status_message = response.message
            
      if response.body
                      
        #If a receipt was returned, parse it
        begin
          #ensure that there are not parse errors. If there are, warn, rather then raise
          @entry = ::Atom::Entry.parse(response.body)          
          @has_entry = true
          @entry.http = connection
        rescue Exception => message
          @has_entry = false
          $stderr.puts "ERROR: An error occured processing the Response XML: #{message}"
        rescue StandardError => error
          @has_entry = false
          $stderr.puts "WARN: The deposit was successful, but there was an issue with Response XML. It could be missing. (#{error})"
        end
        
      else
        #if the receipt was not returned, try and retrieve it
        if @location
          @entry = ::Atom::Entry.parse(connection.get(@location).body)
          @has_entry = true
        else
          #Otherwise, there is no receipt (e.g. for a delete)
          @has_entry = false
          @entry = nil
        end
      end
    end
    
  end
end