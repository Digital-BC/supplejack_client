# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

module Supplejack

  # The +User+ class represents a User on the Supplejack API
  #
  # A User instance can have a relationship to many UserSet objects, this
  # relationship is managed through the UserSetRelation class which adds 
  # ActiveRecord like behaviour to the relationship.
  #
  # A User object can have the following values:
  # - id
  # - name
  # - username
  # - email
  # - api_key
  # - encrypted_password
  #
  class User
    extend Supplejack::Request

    attr_reader :id, :attributes, :api_key, :name, :username, :email, :encrypted_password, :sets_attributes
    attr_accessor :use_own_api_key, :regenerate_api_key

    def initialize(attributes={})
      @attributes = attributes.try(:symbolize_keys) || {}
      @api_key = @attributes[:api_key] || @attributes[:authentication_token]
      @id = @attributes[:id]
      @sets_attributes = @attributes[:sets]
      @use_own_api_key = @attributes[:use_own_api_key] || false
      @regenerate_api_key = @attributes[:regenerate_api_key] || false

      [:name, :username, :email, :encrypted_password].each do |attr|
        self.instance_variable_set("@#{attr}", @attributes[attr])
      end
    end

    def sets
      @sets ||= UserSetRelation.new(self)
    end

    # Initializes a UserSetRelation class which adds behaviour to build, create
    # find and order sets related to this particular User instance
    #
    # @return [ UserSetRelation ] A UserSetRelation object
    #
    # def sets
    #   @sets ||= UserSetRelation.new(self)
    # end

    # Executes a PUT request to the API with the user attributes
    #
    # @return [ true, false ] True if the API returned a success response, false if not.
    #
    def save
      begin
        updated_user = self.class.put("/users/#{self.api_key}", {}, self.api_attributes)
        @api_key = updated_user['user']['api_key'] if regenerate_api_key?
        return true
      rescue StandardError => e
        return false
      end
    end

    # Execures a DELETE request to the API to remove the User object.
    #
    # @return [ true, false ] True if the API returned a success response, false if not.
    #
    def destroy
      begin
        id_or_api_key = self.id || self.api_key
        self.class.delete("/users/#{id_or_api_key}")
        return true
      rescue StandardError => e
        return false
      end
    end

    # Returns a Hash of attributes which will be sent with the POST request.
    #
    # @return [ Hash ] A hash of field names and their values
    #
    def api_attributes
      attrs = {}
    
      [:name, :username, :email, :encrypted_password].each do |attr|
        value = self.public_send(attr)
        attrs[attr] = value if value.present?
      end
      
      attrs[:sets] = @sets_attributes if @sets_attributes.present?
      attrs[:authentication_token] = nil if regenerate_api_key?
      attrs
    end

    # Returns true/false depending whether it will use it's own API Key
    # for managing sets
    #
    # @return [ true/false ] False by default, true when intentionally set at user initialization.
    #
    def use_own_api_key?
      !!@use_own_api_key
    end

    # Returns true/false depending whether it will regenerate it's API Key
    #
    # @return [ true/false ] False by default, true when intentionally set.
    #
    def regenerate_api_key?
      !!@regenerate_api_key
    end

    # Executes a GET request to the API to find the user with the provided ID.
    #
    # @return [ Supplejack::User ] A Supplejack::User object
    #
    def self.find(id)
      response = get("/users/#{id}")
      new(response["user"])
    end

    # Executes a POST request to the API with the user attributes to create a User object.
    #
    # @return [ Supplejack::User ] A Supplejack::User object with recently created id and api_key.
    #
    def self.create(attributes={})
      response = post("/users", {}, {user: attributes})
      new(response["user"])
    end

    def self.update(attributes={})
      response = put("/users/#{attributes[:api_key]}", {}, {user: attributes})
      new(response["user"])
    end
  end
end
