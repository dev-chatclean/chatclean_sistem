# The "Filtrar" options of the sales report, as validated by the controller: ids, a value range, date ranges and text.
module CrmDealReportFilters
  extend ActiveSupport::Concern

  COLUMN_FILTERS = %i[pipeline_id stage_id assignee_id value created_at closed_at stage_entered_at].freeze

  class_methods do
    def report_filtered(filters)
      deals = where(filters.slice(*COLUMN_FILTERS))
      deals = deals.joins(:conversation).where(conversations: { inbox_id: filters[:inbox_id] }) if filters[:inbox_id]
      deals.matching_report_texts(filters)
    end

    def matching_report_texts(filters)
      deals = all
      deals = deals.where(arel_table[:title].matches(like_pattern(filters[:title]))) if filters[:title]
      deals = deals.joins(:company).where(Company.arel_table[:name].matches(like_pattern(filters[:company]))) if filters[:company]
      deals = deals.joins(:contact).where(contact_matches(filters[:contact])) if filters[:contact]
      deals
    end

    private

    def like_pattern(term)
      "%#{sanitize_sql_like(term)}%"
    end

    def contact_matches(term)
      contacts = Contact.arel_table
      pattern = like_pattern(term)
      contacts[:name].matches(pattern).or(contacts[:email].matches(pattern)).or(contacts[:phone_number].matches(pattern))
    end
  end
end
