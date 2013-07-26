require 'spec_helper'

describe DataMapper::Adapters::WebAdapter do
  
  before :all do
   @adapter = DataMapper.setup(:default, :adapter => 'web', :host => 'localhost', :port => 5000)      
  end
  
  describe '#create' do
    it 'should not raise any errors' do
      incoming_contact = IncomingContact.new(:name => 'humpty')
      lambda {
        incoming_contact.save
      }.should_not raise_error
    end
  end
end