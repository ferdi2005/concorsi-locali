require "active_record"
namespace :db do
  desc "Crea tutte le regioni per l'Italia"
  task :concorsi => :environment do
    # Contest(id: integer, category: string, name: string, created_at: datetime, updated_at: datetime, url: string)

    # Concorsi locali 2021

    # Puglia
    Contest.create(region: "Puglia", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Apulia", name: "Wiki Loves Puglia", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali", year: Date.today.year)
    puts "Creating Puglia..."
    # Toscana
    Contest.create(region: "Toscana", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Tuscany", name: "Wiki Loves Toscana", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali", year: Date.today.year)
    puts "Creating Toscana..."
    # Abruzzo
    Contest.create(region: "Abruzzo", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Abruzzo", name: "Wiki Loves Abruzzo", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali", year: Date.today.year)
    puts "Creating Abruzzo..."
    # Basilicata
    Contest.create(region: "Basilicata", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Basilicata", name: "Wiki Loves Basilicata", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali", year: Date.today.year)
    puts "Creating Basilicata..."
    # Veneto
    Contest.create(region: "Veneto", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Veneto", name: "Wiki Loves Veneto",url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali", year: Date.today.year)
    puts "Creating Veneto..."
    # Liguria
    Contest.create(region: "Liguria", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Liguria", name: "Wiki Loves Liguria", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali", year: Date.today.year)
    puts "Creating Liguria..."
    puts "Creating other italian regions..."
    Contest.create(region: "Umbria", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Umbria", name: "Umbria", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali", year: Date.today.year)
    Contest.create(region: "Lombardia", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Lombardy", name: "Lombardia", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali", year: Date.today.year)
    Contest.create(region: "Lazio", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Lazio", name: "Lazio", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali", year: Date.today.year)
    Contest.create(region: "Valle d'Aosta", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Aosta Valley", name: "Valle d'Aosta", url: "https://wikilovesmonuments.wikimedia.it", year: Date.today.year)
    Contest.create(region: "Calabria", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Calabria", name: "Calabria", url: "https://wikilovesmonuments.wikimedia.it", year: Date.today.year)
    Contest.create(region: "Campania", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Campania", name: "Campania", url: "https://wikilovesmonuments.wikimedia.it", year: Date.today.year)
    Contest.create(region: "Emilia-Romagna", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Emilia-Romagna", name: "Emilia-Romagna", url: "https://wikilovesmonuments.wikimedia.it", year: Date.today.year)
    Contest.create(region: "Friuli-Venezia Giulia", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Friuli-Venezia Giulia", name: "Friuli-Venezia Giulia", url: "https://wikilovesmonuments.wikimedia.it", year: Date.today.year)
    Contest.create(region: "Marche", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Marche", name: "Marche", url: "https://wikilovesmonuments.wikimedia.it", year: Date.today.year)
    Contest.create(region: "Molise", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Molise", name: "Molise", url: "https://wikilovesmonuments.wikimedia.it", year: Date.today.year)
    Contest.create(region: "Piemonte", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Piedmont", name: "Piemonte", url: "https://wikilovesmonuments.wikimedia.it", year: Date.today.year)
    Contest.create(region: "Sardegna", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Sardinia", name: "Sardegna", url: "https://wikilovesmonuments.wikimedia.it", year: Date.today.year)
    Contest.create(region: "Sicilia", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Sicily", name: "Sicilia", url: "https://wikilovesmonuments.wikimedia.it", year: Date.today.year)
    Contest.create(region: "Trentino-Alto Adige", category: "Category:Images from Wiki Loves Monuments #{Date.today.year} in Italy - Trentino-South Tyrol‎‎", name: "Trentino-Alto Adige", url: "https://wikilovesmonuments.wikimedia.it", year: Date.today.year)
    puts "Done"
  end
end
