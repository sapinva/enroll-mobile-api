class PlanYear
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :employer_profile

  # Plan Year time period
  field :start_on, type: Date
  field :end_on, type: Date

  field :open_enrollment_start_on, type: Date
  field :open_enrollment_end_on, type: Date

  # Number of full-time employees
  field :fte_count, type: Integer, default: 0

  # Number of part-time employess
  field :pte_count, type: Integer, default: 0

  # Number of Medicare second payers
  field :msp_count, type: Integer, default: 0

  embeds_many :benefit_groups, cascade_callbacks: true
  accepts_nested_attributes_for :benefit_groups, reject_if: :all_blank, allow_destroy: true

  validates_presence_of :start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on

  validate :open_enrollment_date_checks

  def parent
    raise "undefined parent employer_profile" unless employer_profile?
    self.employer_profile
  end

  # embedded association: has_many :employee_families
  def employee_families
    parent.employee_families.where(:plan_year_id => self.id)
  end

  def editable?
    !benefit_groups.any?(&:assigned?)
  end

  def employee_participation_percent
  end

  def last_day_of_month(month = Date.today.month, year = Date.today.year)
    Date.civil(year, month, -1)
  end

  def open_enrollment_contains?(date)
    (open_enrollment_start_on <= date) && (date <= open_enrollment_end_on)
  end

  def coverage_period_contains?(date)
    return (start_on <= date) if (end_on.blank?)
    (start_on <= date) && (date <= end_on)
  end


  class << self
    def find(id)
      organizations = Organization.where("employer_profile.plan_years._id" => BSON::ObjectId.from_string(id))
      organizations.size > 0 ? organizations.first.employer_profile.plan_years.unscoped.detect { |py| py._id.to_s == id.to_s} : nil
    end
  end

private

  def open_enrollment_date_checks
    return if start_on.blank? || end_on.blank? || open_enrollment_start_on.blank? || open_enrollment_end_on.blank?
    if start_on.day != 1
      errors.add(:start_on, "must be first day of the month")
    end

    if end_on != Date.civil(end_on.year, end_on.month, -1)
      errors.add(:end_on, "must be last day of the month")
    end

    # TODO: Create HBX object with configuration settings including shop_plan_year_maximum_in_days
    shop_plan_year_maximum_in_days = 365
    if (end_on - start_on) > shop_plan_year_maximum_in_days
      errors.add(:end_on, "must be less than #{shop_plan_year_maximum_in_days} days from start date")
    end

    if open_enrollment_end_on > start_on
      errors.add(:start_on, "can't occur before open enrollment end date")
    end

    if open_enrollment_end_on < open_enrollment_start_on
      errors.add(:open_enrollment_end_on, "can't occur before open enrollment start date")
    end

    # TODO: Create HBX object with configuration settings including shop_open_enrollment_minimum_in_days
    shop_open_enrollment_minimum_in_days = 5
    if (open_enrollment_end_on - open_enrollment_start_on) < shop_open_enrollment_minimum_in_days
      errors.add(:open_enrollment_end_on, "can't be less than #{shop_open_enrollment_minimum_in_days} days")
    end
  end

end
