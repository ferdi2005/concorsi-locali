namespace :analytics do
  desc "Backfill creators.creationdate mancanti dalle repliche Wikimedia (Toolforge)"
  task backfill_creationdates: :environment do
    missing = Creator.where(creationdate: nil).to_a
    puts "Creatori senza creationdate: #{missing.size}"
    next if missing.empty?

    registrations = WikimediaReplicaClient.fetch_user_registrations(missing.map(&:username))
    updated = 0
    missing.each do |creator|
      ts = registrations[creator.username]
      next if ts.nil?

      creator.update!(creationdate: ts)
      updated += 1
    end
    puts "Aggiornati #{updated} creatori."
  end

  desc "Ricalcola creatorsapposta su tutti i contest_years usando creators.creationdate"
  task recalculate_creatorsapposta: :environment do
    Year.order(:year).each do |year|
      ContestYear.where(year: year).includes(:contest).find_each do |cy|
        count = year.new_creators(contest: cy.contest).count
        cy.update!(creatorsapposta: count)
      end
      puts "Ricalcolato creatorsapposta per #{year.year}."
    end
  end

  desc "Aggiorna usedonwiki per tutte le foto storiche dalle repliche Wikimedia"
  task backfill_usedonwiki: :environment do
    Toolforge::UpdateGlobalUsageWorker.new.perform
    puts "Aggiornamento usedonwiki completato."
  end

  desc "Ricalcola year_analytics e contest_year_analytics per tutti gli anni"
  task recalculate: :environment do
    AnalyticsCalculator.recalculate_all!
    puts "Ricalcolo analytics completato per #{Year.count} anni."
  end

  desc "Aggiorna upload_source, QI/FP e attività fuori settembre (Toolforge)"
  task sync_toolforge_phase2: :environment do
    Toolforge::UpdateUploadSourceWorker.new.perform
    Toolforge::UpdateQualityStatusWorker.new.perform
    Toolforge::UpdateCreatorActivityWorker.new.perform
    puts "Sincronizzazione fase 2 completata."
  end

  desc "Sincronizza l'anagrafica monumenti da cerca (wikilovesmonuments)"
  task sync_monuments: :environment do
    SyncMonumentsWorker.new.perform
    puts "Sincronizzati #{Monument.count} monumenti da cerca."
  end

  desc "Estrae i metadati EXIF per le foto non ancora analizzate (Toolforge)"
  task update_exif: :environment do
    Toolforge::UpdateExifWorker.new.perform(nil, 50_000)
    puts "Estrazione EXIF completata."
  end

  desc "Aggiorna le visite mensili tramite Wikimedia Pageviews API"
  task update_pageviews: :environment do
    UpdatePageviewsWorker.new.perform
    puts "Aggiornamento pageviews completato."
  end

  desc "Allinea il flag photos.special per tutti gli anni con tema speciale e ricalcola le analytics (Toolforge)"
  task backfill_special_photos: :environment do
    Toolforge::UpdateSpecialPhotosWorker.new.perform
    puts "Backfill photos.special completato."
  end
end
