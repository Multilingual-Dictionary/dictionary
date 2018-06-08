#!/usr/bin/env ruby
### dict.rb --- RFC 2229 client for ruby.
## Copyright 2002,2003 by Dave Pearson <davep@davep.org>
## $Revision: 1.10 $
##
## dict.rb is free software distributed under the terms of the GNU General
## Public Licence, version 2. For details see the file COPYING.

### Commentary:
##
## The following code provides a set of RFC 2229 client classes for ruby.
## See <URL:http://www.dict.org/> for more details about dictd.

### TODO:
##
## o Add support for AUTH.

# We need sockets.
require "socket"

############################################################################
# Dictionary error class.
class DictError < RuntimeError
end

############################################################################
# Dict utility code.
module Dict

  # Default host.
  DEFAULT_HOST = "localhost"
  
  # Default port.
  DEFAULT_PORT = 2628

  # End of line marker.
  EOL = "\r\n"

  # End of data marker
  EOD = "." + EOL

  # The special database names.
  DB_FIRST = "!"
  DB_ALL   = "*"

  # The guaranteed match strategies.
  MATCH_DEFAULT = "."
  MATCH_EXACT   = "exact"
  MATCH_PREFIX  = "prefix"
  
  # The various response numbers.
  RESPONSE_DATABASES_FOLLOW    = 110
  RESPONSE_STRATEGIES_FOLLOW   = 111
  RESPONSE_INFO_FOLLOWS        = 112
  RESPONSE_HELP_FOLLOWS        = 113
  RESPONSE_SERVER_INFO_FOLLOWS = 114
  RESPONSE_DEFINITIONS_FOLLOW  = 150
  RESPONSE_DEFINITION_FOLLOWS  = 151
  RESPONSE_MATCHES_FOLLOW      = 152
  RESPONSE_CONNECTED           = 220
  RESPONSE_OK                  = 250
  RESPONSE_NO_MATCH            = 552
  RESPONSE_NO_DATABASES        = 554
  RESPONSE_NO_STRATEGIES       = 555
  
  # Get the reply code of the passed text.
  def replyCode( text, default = nil )

    if text =~ /^\d{3} /
      text.to_i
    elsif default
      default
    else
      raise DictError.new(), "Invalid reply from host \"#{text}\"."
    end
    
  end

  # replyCode should be private.
  private :replyCode
  
end

############################################################################
# Dict base class.
class DictBase
  # Mixin the Dict utility code.
  include Dict
end

############################################################################
# Dictionary definition class.
class DictDefinition < Array

  # Mixin the Dict utility code.
  include Dict
  
  # Constructor
  def initialize( details, conn )

    # Call to the super.
    super()

    # Split the details out.
    details     = /^\d{3} "(.*?)"\s+(\S+)\s+"(.*)"/.match( details )
    @word       = details[ 1 ]
    @database   = details[ 2 ]
    @name       = details[ 3 ]

    # Read in the definition.
    while ( reply = conn.readline() ) != EOD
      push( reply.chop() )
    end

  end
  
  # Access to the word
  def word
    @word
  end

  # Access to the database
  def database
    @database
  end

  # Access to the database name
  def name
    @name
  end

  # Return an array of words you should also see in regard to this definition.
  def seeAlso
    join( " " ).scan( /\{(.*?)\}/ )
  end

end

############################################################################
# Dictionary definition list class.
class DictDefinitionList < Array

  # Mixin the Dict utility code.
  include Dict
  
  # Constructor
  def initialize( conn )

    # Call to the super.
    super()

    # While there's a definition to be had...
    while replyCode( reply = conn.readline() ) == RESPONSE_DEFINITION_FOLLOWS
      # ...add it to the list.
      push( DictDefinition.new( reply, conn ) )
    end

  end
  
end

############################################################################
# Base dictionary array class.
class DictArray < Array

  # Mixin the Dict utility code.
  include Dict

  # Constructor
  def initialize( conn )

    # Call to the super.
    super()

    # While there's a match to be had...
    while replyCode( reply = conn.readline(), 0 ) != RESPONSE_OK
      # ...add it to the list.
      push( reply ) if reply != EOD
    end

  end
  
end

############################################################################
# Class for holding a dictionary item in a dictionary array.
class DictArrayItem

  # Constructor.
  def initialize( text )
    match        = /^(\S+)\s+"(.*)"/.match( text )
    @name        = match[ 1 ]
    @description = match[ 2 ]
  end

  # Access to the name.
  def name
    @name
  end

  # Access to the description.
  def description
    @description
  end
  
end

############################################################################
# Dictionary item array class.
class DictItemArray < DictArray

  # Push the text as a DictArrayItem.
  def push( text )
    super( DictArrayItem.new( text ) )
  end

end

############################################################################
# Dict client class.
class DictClient < DictBase

  # Constructor.
  def initialize( host = DEFAULT_HOST, port = DEFAULT_PORT )
    @host   = host
    @port   = port
    @conn   = nil
    @banner = nil
  end

  # Read-only access to the host.
  def host
    @host
  end

  # Read-only access to the port.
  def port
    @port
  end

  # Are we connected?
  def connected?
    @conn != nil
  end

  # Check if there's a connected, throw an error if there isn't one.
  def checkConnection
    unless connected?
      raise DictError.new(), "Not connected."
    end
  end

  # checkConnection should be private.
  private :checkConnection
  
  # Send text to the server
  def send( text )
    checkConnection()
    @conn.write( text + EOL )
  end

  # send should be private.
  private :send
  
  # Connect to the host.
  def connect

    # Are we already connected?
    if connected?
      # Yes, throw an error.
      raise DictError.new(), "Attempt to connect a conencted client."
    else

      # Nope, open a connection
      @conn = TCPSocket.open( host, port )
      
      # Get the banner.
      @banner = @conn.readline()

      # Valid return value?
      unless replyCode( @banner ) == RESPONSE_CONNECTED
        raise DictError.new(), "Connection refused \"#{@banner}\"."
      end

      # Now we announce ourselves to the server.
      send( "client org.davep.dict.rb $Revision: 1.10 $ <URL:http://www.davep.org/misc/dict.rb>" )
      unless replyCode( reply = @conn.readline() ) == RESPONSE_OK
        raise DictError.new(), "Client announcement failed \"#{reply}\""
      end
      
      # If we were passed a block, yield to it
      yield self if block_given?
      
    end

  end

  # Disconnect.
  def disconnect

    # Are we connected?
    if connected?
      # Yes, close the connection
      send( "quit" )
      @conn.close()
      @conn   = nil
      @banner = nil
    else
      # No, throw an error.
      raise DictError.new(), "Attempt to disconnect a disconnected client."
    end

  end

  # Return the banner we were handed.
  def banner
    checkConnection()
    @banner
  end

  # Core code for array oriented command.
  def arrayCommand( command, array_class, good, bad = nil )

    # Send the command
    send( command )

    # Worked?
    if replyCode( reply = @conn.readline() ) == good

      # Yes, load up the array
      array_class.new( @conn )
    elsif bad and replyCode( reply ) == bad
      # "Bad" response, return an empty array
      Array.new()
    else
      # Something else, throw an error.
      raise DictError.new(), reply
    end
    
  end

  # arrayCommand is private.
  private :arrayCommand
  
  # Define a word.
  def define( word, database = DB_ALL )
    arrayCommand( "define #{database} \"#{word}\"", DictDefinitionList, RESPONSE_DEFINITIONS_FOLLOW, RESPONSE_NO_MATCH )
  end

  # Match a word.
  def match( word, strategy = MATCH_DEFAULT, database = DB_ALL )
    arrayCommand( "match #{database} #{strategy} \"#{word}\"", DictItemArray, RESPONSE_MATCHES_FOLLOW, RESPONSE_NO_MATCH )
  end

  # Get a list of available databases.
  def databases
    arrayCommand( "show db", DictItemArray, RESPONSE_DATABASES_FOLLOW, RESPONSE_NO_DATABASES )
  end

  # Get a list of available strategies.
  def strategies
    arrayCommand( "show strat", DictItemArray, RESPONSE_STRATEGIES_FOLLOW, RESPONSE_NO_STRATEGIES )
  end

  # Get the information for a given database.
  def info( database )
    arrayCommand( "show info \"#{database}\"", DictArray, RESPONSE_INFO_FOLLOWS )
  end

  # Get information about the server.
  def server
    arrayCommand( "show server", DictArray, RESPONSE_SERVER_INFO_FOLLOWS )
  end

  # Get help from the server.
  def help
    arrayCommand( "help", DictArray, RESPONSE_HELP_FOLLOWS )
  end
  
end

