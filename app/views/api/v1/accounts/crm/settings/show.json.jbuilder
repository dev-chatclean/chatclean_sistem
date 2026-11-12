json.auto_create_deals Current.account.crm_auto_create_deals.present?
json.lead_entry Current.account.crm_lead_entry_settings
json.ai Current.account.crm_ai_settings
json.ai_month_cost Crm::AiUsage.month_cost(Current.account).to_f
