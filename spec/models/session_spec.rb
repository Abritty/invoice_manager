require 'rails_helper'

RSpec.describe Session, type: :model do
  let(:user) do
    User.create!(
      first_name: "John",
      last_name: "Doe",
      email_address: "john.doe@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  let(:session) { Session.new(user: user) }

  describe 'validations' do
    it 'should be valid with valid attributes' do
      expect(session).to be_valid
    end

    it 'should require a user' do
      session.user = nil
      expect(session).not_to be_valid
      expect(session.errors[:user]).to include("must exist")
    end
  end

  describe 'associations' do
    it 'should belong to user' do
      expect(session).to respond_to(:user)
      expect(session.user).to eq(user)
    end

    it 'should be able to save and retrieve session' do
      expect(session.save).to be_truthy
      expect(Session.exists?(session.id)).to be_truthy
    end

    it 'should be destroyed when user is destroyed' do
      session.save!
      user_id = user.id
      user.destroy
      expect(Session.exists?(user_id: user_id)).to be_falsy
    end
  end

  describe 'timestamps' do
    it 'should have timestamps' do
      session.save!
      expect(session.created_at).not_to be_nil
      expect(session.updated_at).not_to be_nil
    end
  end

  describe 'user access' do
    it 'should be able to access user through session' do
      session.save!
      session_user = Session.find(session.id).user
      expect(session_user).to eq(user)
      expect(session_user.full_name).to eq("John Doe")
    end
  end
end
