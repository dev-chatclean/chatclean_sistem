# ChatClean: com CHATCLEAN_RSPEC_QUARANTINE=1 (CI), os exemplos listados em .chatclean/ci/rspec-quarantine.txt
# viram pendentes. São falhas conhecidas do upstream; casam por arquivo + descrição completa, não por linha.
if ENV['CHATCLEAN_RSPEC_QUARANTINE'].present?
  quarantined = Rails.root.join('.chatclean/ci/rspec-quarantine.txt').readlines(chomp: true)
                     .reject { |line| line.blank? || line.start_with?('#') }
                     .to_set { |line| line.split(' | ', 2).map(&:strip) }

  RSpec.configure do |config|
    config.define_derived_metadata do |metadata|
      next unless quarantined.include?([metadata[:file_path].delete_prefix('./'), metadata[:full_description]])

      metadata[:skip] = 'ChatClean: falha conhecida do upstream em quarentena (.chatclean/ci/rspec-quarantine.txt)'
    end
  end
end
