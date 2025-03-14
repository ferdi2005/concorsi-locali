require "active_record"
namespace :db do
  desc "Crea tutte le regioni per l'Italia"
  task :concorsi => :environment do
    # Contest(id: integer, category: string, name: string, created_at: datetime, updated_at: datetime, url: string)

    # Lakes como da creare manualmente in un'altra istanza
    #  Contest.create(region: "Lake Como", category: "Lake Como", name: "WLM Lake Como", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/lago-di-como")
    # Valle del Primo presepe da creare manualmente in un'altra istanza ove necessario
    #  Contest.create(region: "Valle del Primo Presepe", category: "Valle del Primo Presepe", name: "Wiki Loves Valle del Primo Presepe", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/valle-del-primo-presepe")

    # Concorsi locali 2021

    # Puglia
    Contest.create(region: "Puglia", category: "Apulia", name: "Wiki Loves Puglia", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/puglia")
    puts "Creating Puglia..."
    # Toscana
    Contest.create(region: "Toscana", category: "Tuscany", name: "Wiki Loves Toscana", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/toscana")
    puts "Creating Toscana..."
    # Abruzzo
    Contest.create(region: "Abruzzo", category: "Abruzzo", name: "Abruzzo", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/abruzzo/")
    puts "Creating Abruzzo..."
    # Basilicata
    Contest.create(region: "Basilicata", category: "Basilicata", name: "Basilicata", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/")
    puts "Creating Basilicata..."
    # Veneto
    Contest.create(region: "Veneto", category: "Veneto", name: "Veneto",url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/")
    puts "Creating Veneto..."
    # Liguria
    Contest.create(region: "Liguria", category: "Liguria", name: "Wiki Loves Liguria", url: "https://www.wikimedia.it/wiki-loves-monuments-concorsi-locali-liguria/")
    puts "Creating Liguria..."
    # Umbria
    Contest.create(region: "Umbria", category: "Umbria", name: "Wiki Loves Umbria", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/")
    puts "Creating Umbria..."
    # Lombardia
    Contest.create(region: "Lombardia", category: "Lombardy", name: "Wiki Loves Lombardia", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali")
    puts "Creating Lombardia..."
    # Lazio
    Contest.create(region: "Lazio", category: "Lazio", name: "Wiki Loves Lazio", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/")
    puts "Creating Lazio..."
    # Valle d'Aosta
    Contest.create(region: "Valle d'Aosta", category: "Aosta Valley", name: "Valle d'Aosta", url: "https://commons.wikimedia.org/wiki/Commons:Wiki_Loves_Monuments_in_Italy/Piedmont_and_Aosta_Valley")
    puts "Creating Valle d'Aosta..."
    # Calabria
    Contest.create(region: "Calabria", category: "Calabria", name: "Calabria", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/")
    puts "Creating Calabria..."
    # Campania
    Contest.create(region: "Campania", category: "Campania", name: "Campania", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/")
    puts "Creating Campania..."
    # Emilia-Romagna
    Contest.create(region: "Emilia-Romagna", category: "Emilia-Romagna", name: "Emilia-Romagna", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/")
    puts "Creating Emilia-Romagna..."
    # Friuli-Venezia Giulia
    Contest.create(region: "Friuli-Venezia Giulia", category: "Friuli-Venezia Giulia", name: "Wiki Loves Friuli Venezia Giulia", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/")
    puts "Creating Friuli-Venezia Giulia..."
    # Marche
    Contest.create(region: "Marche", category: "Marche", name: "Wiki Loves Marche", url: "https://commons.wikimedia.org/wiki/Commons:Wiki_Loves_Monuments_in_Italy/Marche")
    puts "Creating Marche..."
    # Molise
    Contest.create(region: "Molise", category: "Molise", name: "Molise", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/")
    puts "Creating Molise..."
    # Piemonte
    Contest.create(region: "Piemonte", category: "Piedmont", name: "Wiki Loves Piemonte", url: "https://commons.wikimedia.org/wiki/Commons:Wiki_Loves_Monuments_in_Italy/Piedmont_and_Aosta_Valley")
    puts "Creating Piemonte..."
    # Sardegna
    Contest.create(region: "Sardegna", category: "Sardinia", name: "Sardegna", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/")
    puts "Creating Sardegna..."
    # Sicilia
    Contest.create(region: "Sicilia", category: "Sicily", name: "Sicilia", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/")
    puts "Creating Sicilia..."
    # Trentino-Alto Adige
    Contest.create(region: "Trentino-Alto Adige", category: "Trentino-South Tyrol", name: "Trentino-Alto Adige", url: "https://www.wikimedia.it/wiki-loves-monuments/concorsi-locali/")
    puts "Creating Trentino-Alto Adige..."
    puts "Done"
  end
end
