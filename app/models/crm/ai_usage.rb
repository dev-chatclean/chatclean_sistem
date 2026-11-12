# Monthly spend of the pipeline AI per account, checked against the cap set in the AI settings (crm_ai.monthly_cap, in R$).
# Prices come from the model registry the LLM layer already uses (config/llm_models.json, in US$); CRM_AI_USD_BRL converts them.
class Crm::AiUsage < ApplicationRecord
  self.table_name = 'crm_ai_usages'

  belongs_to :account

  scope :current_month, -> { where(month: Time.current.beginning_of_month.to_date) }

  def self.record!(account:, model:, input_tokens:, output_tokens:)
    usd = RubyLLM.models.find(model).cost_for(RubyLLM::Tokens.new(input: input_tokens, output: output_tokens)).total
    usage = current_month.create_or_find_by!(account: account)
    # Atomic increment: calls finishing at the same time all count.
    update_counters(usage.id, input_tokens: input_tokens, output_tokens: output_tokens, # rubocop:disable Rails/SkipsModelValidations
                              cost_brl: usd * ENV.fetch('CRM_AI_USD_BRL').to_d)
  end

  def self.month_cost(account)
    (current_month.where(account: account).pick(:cost_brl) || 0).to_d
  end
end
