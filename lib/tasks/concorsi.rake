require "active_record"
namespace :db do
  desc "Crea tutte le regioni per l'Italia"
  task :concorsi => :environment do
    # Contest(id: integer, category: string, name: string, created_at: datetime, updated_at: datetime, url: string)
    # Puglia
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime('%Y')} in Italy - Apulia", name: "Wiki Loves Puglia", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali")
    puts "Creating Puglia..."
    # Basilicata
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Basilicata", name: "Wiki Loves Basilicata", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali")
    puts "Creating Basilicata..."
    # Veneto
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Veneto", name: "Wiki Loves Veneto",url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali")
    puts "Creating Veneto..."
    # Liguria
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Liguria", name: "Wiki Loves Liguria", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali")
    puts "Creating Liguria..."
    # Toscana
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Tuscany", name: "Wiki Loves Toscana", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali")
    puts "Creating Toscana..."
    # Umbria
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Umbria", name: "Wiki Loves Umbria", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali")
    puts "Creating Umbria..."
    # Lazio
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Lazio", name: "Wiki Loves Lazio", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali")
    puts "Creating Lazio..."
    # Abruzzo
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Abruzzo", name: "Wiki Loves Abruzzo", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali")
    puts "Creating Abruzzo..."
    # Lake Como
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Lake Como", name: "Wiki Loves Monuments - Lake Como", url: "https://wikilovesmonuments.wikimedia.it/concorso/concorsi-locali")
    puts "Creating Lake Como..."

    puts "Creating other italian regions..."

    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Aosta Valley", name: "Valle d'Aosta", url: "https://wikilovesmonuments.wikimedia.it")
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Calabria", name: "Calabria", url: "https://wikilovesmonuments.wikimedia.it")
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Campania", name: "Campania", url: "https://wikilovesmonuments.wikimedia.it")
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Emilia-Romagna", name: "Emilia-Romagna", url: "https://wikilovesmonuments.wikimedia.it")
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Friuli-Venezia Giulia", name: "Friuli-Venezia Giulia", url: "https://wikilovesmonuments.wikimedia.it")
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Marche", name: "Marche", url: "https://wikilovesmonuments.wikimedia.it")
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Molise", name: "Molise", url: "https://wikilovesmonuments.wikimedia.it")
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Piedmont", name: "Piemonte", url: "https://wikilovesmonuments.wikimedia.it")
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Sardinia", name: "Sardegna", url: "https://wikilovesmonuments.wikimedia.it")
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Sicily", name: "Sicilia", url: "https://wikilovesmonuments.wikimedia.it")
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Trentino-South Tyrol‎‎", name: "Trentino-Alto Adige", url: "https://wikilovesmonuments.wikimedia.it")
    Contest.create(category: "Category:Images from Wiki Loves Monuments #{DateTime.now.strftime("%Y")} in Italy - Umbria", name: "Umbria", url: "https://wikilovesmonuments.wikimedia.it")
    puts "Done"

  end
end
