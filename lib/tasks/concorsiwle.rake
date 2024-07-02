require "active_record"
namespace :db do
  desc "Crea tutte le regioni per l'Italia"
  task :concorsi => :environment do
    # Contest(id: integer, category: string, name: string, created_at: datetime, updated_at: datetime, url: string)

    # Lakes como da creare manualmente in un'altra istanza
    #  Contest.create(region: "Lake Como", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Lake Como", name: "Monuments - Lago di Como", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/lago-di-como", year: Date.today.year)
    # Valle del Primo presepe da creare manualmente in un'altra istanza ove necessario
    #  Contest.create(region: "Valle del Primo Presepe", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Valle del Primo Presepe", name: "Valle del Primo Presepe", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/valle-del-primo-presepe", year: Date.today.year)

    # Concorsi locali 2021
    
    # Puglia
    Contest.create(region: "Puglia", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Apulia", name: "Puglia", url: "https://wikilovesearthpuglia.it", year: Date.today.year)
    puts "Creating Puglia..."
    # Toscana
    Contest.create(region: "Toscana", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Tuscany", name: "Toscana", url: "https://wikilovesearth.it", year: Date.today.year)
    puts "Creating Toscana..."
    # Abruzzo
    Contest.create(region: "Abruzzo", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Abruzzo", name: "Abruzzo", url: "https://wikilovesearth.it/", year: Date.today.year)
    puts "Creating Abruzzo..."
    # Basilicata
    Contest.create(region: "Basilicata", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Basilicata", name: "Basilicata", url: "https://wikilovesearth.it/", year: Date.today.year)
    puts "Creating Basilicata..."
    # Veneto
    Contest.create(region: "Veneto", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Veneto", name: "Veneto",url: "https://wikilovesearth.it/", year: Date.today.year)
    puts "Creating Veneto..."
    # Liguria
    Contest.create(region: "Liguria", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Liguria", name: "Liguria", url: "https://wikilovesearth.it/", year: Date.today.year)
    puts "Creating Liguria..."
    # Umbria
    Contest.create(region: "Umbria", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Umbria", name: "Umbria", url: "https://wikilovesearth.it/", year: Date.today.year)
    puts "Creating Umbria..."
    # Lombardia
    Contest.create(region: "Lombardia", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Lombardy", name: "Lombardia", url: "https://wikilovesearth.it", year: Date.today.year)
    puts "Creating Lombardia..."
    # Lazio
    Contest.create(region: "Lazio", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Lazio", name: "Lazio", url: "https://wikilovesearth.it/", year: Date.today.year)
    puts "Creating Lazio..."
    # Valle d'Aosta
    Contest.create(region: "Valle d'Aosta", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Aosta Valley", name: "Valle d'Aosta", url: "https://wikilovesearth.it", year: Date.today.year)
    puts "Creating Valle d'Aosta..."
    # Calabria
    Contest.create(region: "Calabria", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Calabria", name: "Calabria", url: "https://wikilovesearth.it/", year: Date.today.year)
    puts "Creating Calabria..."
    # Campania
    Contest.create(region: "Campania", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Campania", name: "Campania", url: "https://wikilovesearth.it/", year: Date.today.year)
    puts "Creating Campania..."
    # Emilia-Romagna
    Contest.create(region: "Emilia-Romagna", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Emilia-Romagna", name: "Emilia-Romagna", url: "https://wikilovesearth.it/", year: Date.today.year)
    puts "Creating Emilia-Romagna..."
    # Friuli-Venezia Giulia
    Contest.create(region: "Friuli-Venezia Giulia", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Friuli-Venezia Giulia", name: "Friuli Venezia Giulia", url: "https://wikilovesearth.it/", year: Date.today.year)
    puts "Creating Friuli-Venezia Giulia..."
    # Marche
    Contest.create(region: "Marche", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Marche", name: "Marche", url: "https://wikilovesearth.it", year: Date.today.year)
    puts "Creating Marche..."
    # Molise
    Contest.create(region: "Molise", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Molise", name: "Molise", url: "https://wikilovesearth.it/", year: Date.today.year)
    puts "Creating Molise..."
    # Piemonte
    Contest.create(region: "Piemonte", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Piedmont", name: "Piemonte", url: "https://wikilovesearth.it", year: Date.today.year)
    puts "Creating Piemonte..."
    # Sardegna
    Contest.create(region: "Sardegna", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Sardinia", name: "Sardegna", url: "https://wikilovesearth.it", year: Date.today.year)
    puts "Creating Sardegna..."
    # Sicilia
    Contest.create(region: "Sicilia", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Sicily", name: "Sicilia", url: "https://wikilovesearth.it/", year: Date.today.year)
    puts "Creating Sicilia..."
    # Trentino-Alto Adige
    Contest.create(region: "Trentino-Alto Adige", category: "Category:Images from Wiki Loves Earth #{Date.today.year} in Italy - Trentino-South Tyrol", name: "Trentino-Alto Adige", url: "https://wikilovesearth.it/", year: Date.today.year)
    puts "Creating Trentino-Alto Adige..."
    puts "Done"
  end
end
