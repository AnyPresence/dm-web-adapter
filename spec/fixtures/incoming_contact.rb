class IncomingContact
  include ::DataMapper::Resource

  property :id, Serial
  property :email, String
  property :message, String
  property :name, String
  property :contact_by_email, Boolean
  property :created, DateTime
  
end