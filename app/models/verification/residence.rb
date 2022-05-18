class Verification::Residence
  include ActiveModel::Model
  include ActiveModel::Dates
  include ActiveModel::Validations::Callbacks

  attr_accessor :born_names, :paternal_last_name, :maternal_last_name, :birthplace, :gender, :user,
                :ife, :document_number, :document_type, :date_of_birth, :terms_of_service, :phone_number

  # Uncomment this validation if you would like to activate INE CIC verification and info retrieval
  # before_validation :retrieve_census_data

  # Uncomment document validations if document_number is present in verification/residence/new
  # validates :document_number, presence: true
  # validates :document_type, presence: true
  # validates :phone_number, presence: true
  validates :date_of_birth, presence: true
  validates :terms_of_service, acceptance: { allow_nil: false }

  validate :allowed_age
  # validate :document_number_uniqueness
  # validate  :exped_exist


  def initialize(attrs = {})

    self.born_names = attrs["born_names"].nil? && !attrs["user"].nil? ? attrs["user"][:born_names] : attrs["born_names"]
    self.paternal_last_name = attrs["paternal_last_name"].nil? && !attrs["user"].nil? ? attrs["user"][:paternal_last_name] : attrs["paternal_last_name"]
    self.maternal_last_name = attrs["maternal_last_name"].nil? && !attrs["user"].nil? ? attrs["user"][:maternal_last_name] : attrs["maternal_last_name"]
    self.date_of_birth = parse_date('date_of_birth', attrs)
    self.birthplace = attrs["birthplace"].nil? && !attrs["user"].nil? ? attrs["user"][:birthplace] : attrs["birthplace"]
    self.gender = attrs["gender"].nil? && !attrs["user"].nil? ? attrs["user"][:gender] : attrs["gender"]
    self.phone_number = attrs["phone_number"].nil? && !attrs["user"].nil? ? attrs["user"][:phone_number] : attrs["phone_number"]
    self.ife = attrs["ife"]
    attrs = remove_date('date_of_birth', attrs)
    super
    # clean_document_number
  end

  def save

    return false unless valid?

    user.take_votes_if_erased_document(document_number, document_type)

    user.update(ife: ife,
                born_names: born_names,
                paternal_last_name: paternal_last_name,
                maternal_last_name: maternal_last_name,
                birthplace: birthplace,
                gender: gender,
                date_of_birth:         date_of_birth.in_time_zone.to_datetime,
                document_number:       document_number,
                document_type:         '1', #document_type
                # geozone:               geozone,
                phone_number:          phone_number,
                sector:                "K1",
                residence_verified_at: Time.current)
  end

  def allowed_age
    return if errors[:date_of_birth].any? || Age.in_years(date_of_birth) >= User.minimum_required_age
    errors.add(:date_of_birth, I18n.t('verification.residence.new.error_not_allowed_age'))
  end

  def document_number_uniqueness
    if(User.active.where(document_number: document_number).count >= 4)
      errors.add(:document_number, "No pueden existir mas de 4 registros con este numero")
    else
      return true
    end
  end

  def store_failed_attempt
    FailedCensusCall.create(
      user: user,
      document_number: document_number,
      document_type: document_type,
      date_of_birth: date_of_birth,
    )
  end

  # def geozone
  #   Geozone.where(census_code: district_code).first #TODO: check Geozone identification
  # end

  # def district_code
  #   @census_data.electoral_section_id
  # end

  # def exped_exist
  #   self.errors.add(:document_number, "Este Numero No Existe") unless @census_data.present?
  # end

  private
    # Uncomment this method if you would like to activate INE CIC verification and info retrieval
    #
    # def retrieve_census_data
    #   @census_data = ElectoralRoll.find_by(
    #     "cic_number = ? or ocr_number = ?",
    #     document_number,
    #     document_number
    #   )
    #
    #   if @census_data.present?
    #     self.user.update(electoral_roll: @census_data)
    #   else
    #     errors.add(:cic_or_ocr_not_valid, "CIC or OCR not valid")
    #   end
    # end

    # def residency_valid?
    #   @census_data.present?
    # end

    # def clean_document_number
    #   self.document_number = document_number.gsub(/[^a-z0-9]+/i, "").upcase if document_number.present?
    # end

end
