# Feriado da conta (US 19, CCV2-27): no dia, o canal com horário ligado fica fora do horário e
# responde com a mensagem do feriado.
class Chatclean::Holiday < Chatclean::ApplicationRecord
  # Feriados nacionais de data fixa (mês, dia, chave do nome).
  NATIONAL = [
    [1, 1, :new_year], [4, 21, :tiradentes], [5, 1, :labour_day], [9, 7, :independence],
    [10, 12, :aparecida], [11, 2, :all_souls], [11, 15, :republic], [11, 20, :black_consciousness], [12, 25, :christmas]
  ].freeze

  belongs_to :account

  validates :name, presence: true
  validates :date, presence: true, uniqueness: { scope: :account_id }

  scope :in_year, ->(year) { where(date: Date.new(year, 1, 1)..Date.new(year, 12, 31)) }

  # Os 9 nacionais de data fixa e a Sexta-feira Santa do ano, sem duplicar nem sobrescrever (CA 19.6).
  def self.import_national!(account, year)
    I18n.with_locale(account.locale) do
      dates = NATIONAL.to_h { |month, day, key| [Date.new(year, month, day), I18n.t("chatclean.holidays.national.#{key}")] }
      dates[easter(year) - 2] = I18n.t('chatclean.holidays.national.good_friday')
      existing = where(account: account, date: dates.keys).pluck(:date)
      dates.except(*existing).each { |date, name| create!(account: account, date: date, name: name) }
    end
  end

  # Domingo de Páscoa pelo algoritmo de Meeus/Jones/Butcher (calendário gregoriano). A fórmula fica
  # inteira para poder ser conferida com a referência.
  def self.easter(year) # rubocop:disable Metrics/AbcSize
    a = year % 19
    b, c = year.divmod(100)
    d, e = b.divmod(4)
    g = ((8 * b) + 13) / 25
    h = ((19 * a) + b - d - g + 15) % 30
    i, k = c.divmod(4)
    l = (32 + (2 * e) + (2 * i) - h - k) % 7
    m = (a + (11 * h) + (19 * l)) / 433
    month = (h + l - (7 * m) + 90) / 25
    Date.new(year, month, (h + l - (7 * m) + (33 * month) + 19) % 32)
  end
end
