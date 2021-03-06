class Roster
  include ActiveModel::Model
  include Virtus.model
  attribute :country
  attribute :rows
  attribute :extra_columns

  def self.headers
    %w(email phone phone2 first_name last_name pcv_id role location time_zone)
  end

  def self.from_csv csv, country:
    rows = CSV.parse csv.strip, headers: true, converters: ->(f) { f ? f.strip : nil }
    unrecognized = rows.headers - headers
    new country: country, rows: rows.map { |r| Row.new r.to_hash }, extra_columns: unrecognized
  end

  def self.for_user user
    rows = user.admin? ? User : user.country.users
    new country: user.country, rows: rows
  end

  class Row
    include Virtus.model
    Roster.headers.each do |header|
      attribute header
    end

    def persisted?; end
    def save; end

    def email
      s = super
      s && s.strip.downcase
    end

    def user_hash
      {
        email:      email,
        first_name: first_name,
        last_name:  last_name,
        pcv_id:     pcv_id,
        role:       role,
        location:   location,
        time_zone:  time_zone
      }
    end

    def phone_numbers
      [phone, phone2].select(&:present?)
    end
  end

  def persisted?; end
  def inspect; "Roster(#{country.name}: #{rows.count} rows)"; end

  def save
    # TODO: this clobbers user edits. Do we need to allow PCVs to edit?
    import_new_users
    update_existing_users
    inactivate_removed_pcvs
    true
  end

  def removed_pcvs
    country.users.pcv.where(email: removed_emails.to_a)
  end

  def active_emails
    rows.map &:email
  end

  def country_id
    country.id
  end

  private

  def new_rows
    rows.reject { |row| existing_users.include? row.email  }
  end

  def existing_rows
    rows.select { |row| existing_users.include? row.email }
  end

  def import_new_users
    new_rows.each do |row|
      begin
        user = country.users.create! row.user_hash.merge password: Devise.friendly_token
        row.phone_numbers.each { |number| user.claim_phone_number number }
      rescue => e
        Notification.send :invalid_roster_upload_row,
          "Failed to create from upload row #{row.user_hash}: #{e}"
      end
    end
  end

  def update_existing_users
    existing_rows.each do |row|
      user = existing_users.fetch row.email
      begin
        user.update! row.user_hash
        row.phone_numbers.each { |number| user.claim_phone_number number }
      rescue => e
        Notification.send :invalid_roster_upload_row,
          "Failed to update from upload row #{row.user_hash}: #{e}"
      end
    end
  end

  def inactivate_removed_pcvs
    removed_pcvs.update_all active: false
  end

  def existing_users
    @_existing_users ||= country.users.map { |user| [user.email, user] }.to_h
  end

  def removed_emails
    existing_users.keys - active_emails
  end
end
