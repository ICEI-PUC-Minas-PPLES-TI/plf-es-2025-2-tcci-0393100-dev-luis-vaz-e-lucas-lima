(* Template definitions using string-based HTML *)

(* Modern minimalist CSS with dark/light mode *)
let common_styles = {|
<style>
  :root {
    /* Light theme */
    --bg-primary: #ffffff;
    --bg-secondary: #f8fafc;
    --bg-card: #ffffff;
    --text-primary: #1a202c;
    --text-secondary: #4a5568;
    --text-muted: #718096;
    --border-color: #e2e8f0;
    --accent: #10b981;
    --accent-hover: #059669;
    --shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
    --shadow-lg: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  }
  
  html[data-theme="dark"] {
    /* Dark theme */
    --bg-primary: #0f172a;
    --bg-secondary: #1e293b;
    --bg-card: #334155;
    --text-primary: #f1f5f9;
    --text-secondary: #cbd5e1;
    --text-muted: #94a3b8;
    --border-color: #475569;
    --accent: #10b981;
    --accent-hover: #34d399;
    --shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.3), 0 2px 4px -1px rgba(0, 0, 0, 0.2);
    --shadow-lg: 0 20px 25px -5px rgba(0, 0, 0, 0.3), 0 10px 10px -5px rgba(0, 0, 0, 0.2);
  }
  
  * {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
  }
  
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    line-height: 1.6;
    color: var(--text-primary);
    background: var(--bg-primary);
    transition: all 0.3s ease;
  }
  
  .header {
    background: var(--bg-card);
    border-bottom: 1px solid var(--border-color);
    padding: 1rem 0;
    position: sticky;
    top: 0;
    z-index: 100;
    backdrop-filter: blur(10px);
  }
  
  .header-content {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 1.5rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  .logo-container {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    text-decoration: none;
    color: var(--text-primary);
  }
  
  .logo-image {
    height: 70px;
    width: auto;
    transition: transform 0.3s ease;
  }
  
  .logo-image:hover {
    transform: scale(1.05);
  }
  
  .header-actions {
    display: flex;
    align-items: center;
    gap: 1rem;
  }
  
  .theme-toggle {
    background: none;
    border: 1px solid var(--border-color);
    padding: 0.5rem;
    border-radius: 0.5rem;
    cursor: pointer;
    color: var(--text-primary);
    transition: all 0.2s ease;
  }
  
  .theme-toggle:hover {
    background: var(--bg-secondary);
  }
  
  .nav-menu {
    display: flex;
    list-style: none;
    gap: 1.5rem;
  }
  
  .nav-menu a {
    color: var(--text-secondary);
    text-decoration: none;
    font-weight: 500;
    transition: color 0.2s ease;
    padding: 0.5rem 1rem;
    border-radius: 0.5rem;
  }
  
  .nav-menu a:hover {
    color: var(--accent);
    background: var(--bg-secondary);
  }
  
  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 1.5rem;
  }
  
  .hero {
    text-align: center;
    padding: 4rem 0;
    background: var(--bg-secondary);
  }
  
  .hero h1 {
    font-size: clamp(2.5rem, 5vw, 3.5rem);
    font-weight: 800;
    margin-bottom: 1rem;
    color: var(--text-primary);
    letter-spacing: -0.025em;
  }
  
  .hero p {
    font-size: 1.25rem;
    color: var(--text-muted);
    margin-bottom: 2rem;
  }
  
  .search-section {
    background: var(--bg-card);
    border: 1px solid var(--border-color);
    border-radius: 1rem;
    padding: 2rem;
    margin: -3rem auto 3rem;
    position: relative;
    z-index: 10;
    box-shadow: var(--shadow-lg);
  }
  
  .search-form {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
    align-items: end;
  }
  
  .form-group {
    display: flex;
    flex-direction: column;
  }
  
  .form-group label {
    margin-bottom: 0.5rem;
    font-weight: 600;
    color: var(--text-secondary);
    font-size: 0.875rem;
  }
  
  .form-group select,
  .form-group input {
    padding: 0.75rem 1rem;
    border: 1px solid var(--border-color);
    border-radius: 0.5rem;
    font-size: 1rem;
    background: var(--bg-primary);
    color: var(--text-primary);
    transition: all 0.2s ease;
  }
  
  .form-group select:focus,
  .form-group input:focus {
    outline: none;
    border-color: var(--accent);
    box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
  }
  
  .btn {
    background: var(--accent);
    color: white;
    border: none;
    padding: 0.75rem 1.5rem;
    border-radius: 0.5rem;
    cursor: pointer;
    font-size: 1rem;
    font-weight: 600;
    transition: all 0.2s ease;
    text-decoration: none;
    display: inline-block;
    text-align: center;
  }
  
  .btn:hover {
    background: var(--accent-hover);
    transform: translateY(-1px);
  }
  
  .btn-outline {
    background: transparent;
    color: var(--accent);
    border: 1px solid var(--accent);
  }
  
  .btn-outline:hover {
    background: var(--accent);
    color: white;
  }
  
  .filters-section {
    background: var(--bg-card);
    border: 1px solid var(--border-color);
    border-radius: 1rem;
    padding: 1.5rem;
    margin-bottom: 2rem;
    box-shadow: var(--shadow);
  }
  
  .filters-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1.5rem;
  }
  
  .filter-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 1rem;
  }
  
  .vehicle-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
    gap: 1.5rem;
    margin: 2rem 0;
  }
  
  .vehicle-card {
    background: var(--bg-card);
    border: 1px solid var(--border-color);
    border-radius: 1rem;
    overflow: hidden;
    transition: all 0.3s ease;
    cursor: pointer;
  }
  
  .vehicle-card:hover {
    transform: translateY(-4px);
    box-shadow: var(--shadow-lg);
    border-color: var(--accent);
  }
  
  .vehicle-image {
    width: 100%;
    height: 240px;
    background-size: cover;
    background-position: center;
    position: relative;
  }
  
  .vehicle-badge {
    position: absolute;
    top: 1rem;
    right: 1rem;
    background: var(--accent);
    color: white;
    padding: 0.25rem 0.75rem;
    border-radius: 2rem;
    font-size: 0.75rem;
    font-weight: 600;
  }
  
  .vehicle-info {
    padding: 1.5rem;
  }
  
  .vehicle-title {
    font-size: 1.125rem;
    font-weight: 700;
    margin-bottom: 0.5rem;
    color: var(--text-primary);
  }
  
  .vehicle-price {
    font-size: 1.5rem;
    font-weight: 800;
    color: var(--accent);
    margin-bottom: 1rem;
  }
  
  .vehicle-specs {
    display: grid;
    grid-template-columns: 1fr 1fr 1fr;
    gap: 0.5rem;
    margin-bottom: 1rem;
  }
  
  .spec-item {
    text-align: center;
    padding: 0.5rem;
    background: var(--bg-secondary);
    border-radius: 0.5rem;
  }
  
  .spec-label {
    font-size: 0.75rem;
    color: var(--text-muted);
    display: block;
  }
  
  .spec-value {
    font-size: 0.875rem;
    font-weight: 600;
    color: var(--text-primary);
  }
  
  .footer {
    background: var(--bg-secondary);
    border-top: 1px solid var(--border-color);
    text-align: center;
    padding: 3rem 0;
    margin-top: 4rem;
  }
  
  .login-container, .form-container {
    max-width: 480px;
    margin: 3rem auto;
    background: var(--bg-card);
    padding: 2rem;
    border-radius: 1rem;
    border: 1px solid var(--border-color);
    box-shadow: var(--shadow-lg);
  }
  
  .dashboard-header {
    display: flex;
    flex-wrap: wrap;
    justify-content: space-between;
    align-items: center;
    gap: 1rem;
    margin-bottom: 2rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid var(--border-color);
  }
  
  .stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
    margin-bottom: 2rem;
  }
  
  .stat-card {
    background: var(--bg-card);
    border: 1px solid var(--border-color);
    padding: 1.5rem;
    border-radius: 1rem;
    text-align: center;
  }
  
  .stat-value {
    font-size: 2rem;
    font-weight: 800;
    color: var(--accent);
    display: block;
  }
  
  .stat-label {
    font-size: 0.875rem;
    color: var(--text-muted);
    margin-top: 0.5rem;
  }
  
  .ad-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.9);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 9999;
  }
  
  .ad-content {
    background: var(--bg-card);
    padding: 3rem;
    border-radius: 1rem;
    text-align: center;
    max-width: 500px;
    margin: 0 1rem;
    border: 1px solid var(--border-color);
  }
  
  .mobile-menu-toggle {
    display: none;
    background: none;
    border: none;
    color: var(--text-primary);
    font-size: 1.5rem;
    cursor: pointer;
  }
  
  .vehicle-detail-grid {
    display: grid;
    grid-template-columns: 2fr 1fr;
    gap: 2rem;
    margin: 2rem 0;
  }
  
  .detail-images {
    background: var(--bg-card);
    border: 1px solid var(--border-color);
    border-radius: 1rem;
    overflow: hidden;
    margin-bottom: 2rem;
  }
  
  .detail-info {
    background: var(--bg-card);
    border: 1px solid var(--border-color);
    padding: 2rem;
    border-radius: 1rem;
    margin-bottom: 2rem;
  }
  
  .sidebar {
    background: var(--bg-card);
    border: 1px solid var(--border-color);
    padding: 2rem;
    border-radius: 1rem;
    position: sticky;
    top: 7rem;
    height: fit-content;
  }
  
  /* Mobile Responsive - Improved */
  @media (max-width: 768px) {
    .container {
      padding: 0 1rem;
    }
    
    .hero {
      padding: 2rem 0;
    }
    
    .hero h1 {
      font-size: 2rem;
    }
    
    .search-form {
      grid-template-columns: 1fr;
      gap: 1.5rem;
    }
    
    .filter-grid {
      grid-template-columns: 1fr;
    }
    
    .vehicle-grid {
      grid-template-columns: 1fr;
      gap: 1rem;
    }
    
    /* Detail page mobile fixes */
    .vehicle-detail-grid {
      grid-template-columns: 1fr !important;
      gap: 2rem;
    }
    
    .header-content {
      flex-direction: column;
      gap: 1rem;
    }
    
    .header-actions {
      width: 100%;
      justify-content: space-between;
    }
    
    .nav-menu {
      display: none;
    }
    
    .mobile-menu-toggle {
      display: block;
    }
    
    .logo-image {
      height: 50px;
    }
    
    .vehicle-specs {
      grid-template-columns: 1fr 1fr;
      gap: 0.75rem;
    }
    
    .dashboard-header {
      flex-direction: column;
      text-align: center;
    }
    
    .stats-grid {
      grid-template-columns: 1fr 1fr;
    }
    
    /* Mobile slideshow improvements */
    .slideshow-container {
      height: 300px !important;
    }
    
    .thumbnail-gallery {
      display: grid !important;
      grid-template-columns: repeat(4, 1fr) !important;
      gap: 0.5rem !important;
    }
    
    .thumb-item img {
      width: 100% !important;
      height: 50px !important;
    }
    
    .slide-controls button {
      width: 40px !important;
      height: 40px !important;
      font-size: 1.2rem !important;
    }
    
    /* Mobile typography */
    h1 {
      font-size: 1.75rem !important;
    }
    
    h2 {
      font-size: 1.5rem !important;
    }
    
    .vehicle-title {
      font-size: 1.1rem !important;
    }
    
    .vehicle-price {
      font-size: 1.3rem !important;
    }
    
    /* Mobile spacing */
    .detail-info {
      padding: 2rem 1.5rem !important;
    }
    
    /* Mobile sidebar - make it not sticky */
    .vehicle-detail-grid > div:last-child {
      position: static !important;
      margin-top: 2rem;
    }
    
    /* Mobile buttons */
    .btn {
      padding: 0.875rem 1rem !important;
      font-size: 1rem !important;
    }
    
    /* Mobile forms */
    .form-container {
      margin: 2rem 1rem !important;
      padding: 1.5rem !important;
    }
    
    /* Mobile listing layout */
    .listing-layout {
      grid-template-columns: 1fr !important;
      gap: 1rem !important;
    }
    
    .listing-layout > div:first-child {
      position: static !important;
      order: 2;
      margin-top: 2rem;
    }
    
    .listing-layout > div:last-child {
      order: 1;
    }
    
    /* Mobile vehicle cards - completely restructured for mobile */
    .vehicle-card-mobile {
      height: auto !important;
      margin-bottom: 2rem !important;
    }
    
    .vehicle-card-mobile > div {
      display: flex !important;
      flex-direction: column !important;
      grid-template-columns: 1fr !important;
      height: auto !important;
      min-height: auto !important;
    }
    
    .vehicle-card-mobile > div > div:first-child {
      height: 200px !important;
      width: 100% !important;
      order: 1;
    }
    
    .vehicle-card-mobile > div > div:nth-child(2) {
      padding: 1.5rem !important;
      order: 2;
      flex: 1;
    }
    
    .vehicle-card-mobile > div > div:last-child {
      padding: 1.5rem !important;
      min-width: auto !important;
      width: 100% !important;
      order: 3;
      background: var(--bg-primary) !important;
    }
    
    /* Mobile specs grid - better layout */
    .vehicle-card-mobile .vehicle-specs {
      grid-template-columns: repeat(2, 1fr) !important;
      gap: 0.5rem !important;
    }
    
    /* Mobile buttons - ensure visibility */
    .vehicle-card-mobile .btn {
      padding: 1rem !important;
      font-size: 1rem !important;
      margin-bottom: 0.75rem !important;
    }
    
    /* Mobile pagination */
    .pagination-mobile {
      flex-direction: column !important;
      gap: 1.5rem !important;
      padding: 1.5rem !important;
    }
  }
  
  @media (max-width: 480px) {
    .hero h1 {
      font-size: 1.75rem;
    }
    
    .search-section {
      margin: -2rem auto 2rem !important;
      padding: 1.5rem !important;
    }
    
    .vehicle-specs {
      grid-template-columns: 1fr !important;
    }
    
    .slideshow-container {
      height: 250px !important;
    }
    
    .thumbnail-gallery {
      grid-template-columns: repeat(3, 1fr) !important;
    }
  }
  
  /* Dark mode images */
  html[data-theme="dark"] img {
    opacity: 0.9;
  }
  
  /* Animations */
  .fade-in {
    animation: fadeIn 0.5s ease-in;
  }
  
  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(20px); }
    to { opacity: 1; transform: translateY(0); }
  }
  
  /* Loading states */
  .loading {
    opacity: 0.7;
    pointer-events: none;
  }
  
  /* Error states */
  .error {
    color: #ef4444;
    background: rgba(239, 68, 68, 0.1);
    padding: 0.75rem 1rem;
    border-radius: 0.5rem;
    border: 1px solid rgba(239, 68, 68, 0.3);
    margin-bottom: 1rem;
  }
  
  /* Success states */
  .success {
    color: var(--accent);
    background: rgba(16, 185, 129, 0.1);
    padding: 0.75rem 1rem;
    border-radius: 0.5rem;
    border: 1px solid rgba(16, 185, 129, 0.3);
    margin-bottom: 1rem;
  }
</style>
|}

(* Use types from the Types module *)
open Types

(* Base HTML template with dark/light mode *)
let base_template ~title ~content = 
  "<!DOCTYPE html>" ^
  "<html lang='pt-BR'>" ^
  "<script>(function(){var c=document.cookie.match(/theme=([^;]+)/);var t=c?c[1]:'light';document.documentElement.setAttribute('data-theme',t);if(t==='dark'){document.documentElement.style.backgroundColor='#0f172a';document.documentElement.style.color='#f1f5f9';} else {document.documentElement.style.backgroundColor='#ffffff';document.documentElement.style.color='#1a202c';}})();</script>" ^
  "<head>" ^
    "<meta charset='UTF-8'>" ^
    "<meta name='viewport' content='width=device-width, initial-scale=1.0'>" ^
    "<title>" ^ title ^ "</title>" ^
    common_styles ^
    {|<script>
      function setCookie(name, value, days) {
        var expires = '';
        if (days) {
          var date = new Date();
          date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
          expires = '; expires=' + date.toUTCString();
        }
        document.cookie = name + '=' + value + expires + '; path=/';
      }
      
      function toggleTheme() {
        var html = document.documentElement;
        var currentTheme = html.getAttribute('data-theme') || 'light';
        var newTheme = currentTheme === 'dark' ? 'light' : 'dark';
        html.setAttribute('data-theme', newTheme);
        var icon = document.getElementById('theme-icon');
        if (icon) {
          icon.textContent = newTheme === 'dark' ? '☀️' : '🌙';
        }
        setCookie('theme', newTheme, 365);
      }
      
      // Theme is already set by inline script, just ensure it's correct
      var currentTheme = document.documentElement.getAttribute('data-theme') || 'light';
    </script>|} ^
  "</head>" ^
  "<body>" ^
    "<header class='header'>" ^
      "<div class='header-content'>" ^
        "<a href='/' class='logo-container'>" ^
          "<img src='/logo-buscar.png' alt='BusCars' class='logo-image'>" ^
        "</a>" ^
        "<div class='header-actions'>" ^
          "<nav>" ^
            "<ul class='nav-menu'>" ^
              "<li><a href='/'>Início</a></li>" ^
              "<li><a href='/vehicles'>Veículos</a></li>" ^
              "<li><a href='/login'>Login</a></li>" ^
              "<li><a href='/dashboard'>Dashboard</a></li>" ^
            "</ul>" ^
          "</nav>" ^
          "<button class='theme-toggle' id='theme-button' aria-label='Alternar tema'>" ^
            "<span id='theme-icon'>🌙</span>" ^
          "</button>" ^
          "<button class='mobile-menu-toggle' onclick='toggleMobileMenu()'>☰</button>" ^
        "</div>" ^
      "</div>" ^
    "</header>" ^
    "<main class='fade-in'>" ^ content ^ "</main>" ^
    "<footer class='footer'>" ^
      "<div class='container'>" ^
        "<p>© 2025 BusCars - Encontre seu carro ideal no Brasil</p>" ^
      "</div>" ^
    "</footer>" ^
    "<script>" ^
      "function toggleMobileMenu() {" ^
        "const navMenu = document.querySelector('.nav-menu');" ^
        "navMenu.style.display = navMenu.style.display === 'flex' ? 'none' : 'flex';" ^
      "}" ^
      
      
      "document.addEventListener('DOMContentLoaded', function() {" ^
        "var currentTheme = document.documentElement.getAttribute('data-theme') || 'light';" ^
        "var icon = document.getElementById('theme-icon');" ^
        "if (icon) {" ^
          "icon.textContent = currentTheme === 'dark' ? '☀️' : '🌙';" ^
        "}" ^
        "var themeButton = document.getElementById('theme-button');" ^
        "if (themeButton) {" ^
          "themeButton.addEventListener('click', toggleTheme);" ^
        "}" ^
      "});" ^
    "</script>" ^
  "</body>" ^
  "</html>"

(* Landing page - search only like AutoTempest *)
let home_template () =
  let content = 
    "<section class='hero'>" ^
        "<div class='container'>" ^
          "<h1>Todos os carros. Uma busca.</h1>" ^
          "<p>Navegue por anúncios de todos os principais sites de carros usados e novos do Brasil</p>" ^
          "<div style='margin: 2rem 0; opacity: 0.8;'>" ^
            "<p style='font-size: 0.9rem;'>Incluindo: <strong>Webmotors, OLX, Localiza Seminovos, Vrum, iCarros</strong> e muito mais!</p>" ^
          "</div>" ^
        "</div>" ^
      "</section>" ^
      
      "<div class='container'>" ^
        "<section class='search-section'>" ^
          "<form method='post' action='/search' class='search-form'>" ^
            "<div class='form-group'>" ^
              "<label for='brand'>Marca</label>" ^
              "<select name='brand' id='brand' onchange='updateModels()'>" ^
                "<option value=''>Todas as marcas</option>" ^
                "<option value='Porsche'>Porsche</option>" ^
                "<option value='Toyota'>Toyota</option>" ^
                "<option value='BMW'>BMW</option>" ^
                "<option value='Volkswagen'>Volkswagen</option>" ^
                "<option value='Ford'>Ford</option>" ^
                "<option value='Chevrolet'>Chevrolet</option>" ^
              "</select>" ^
            "</div>" ^
            "<div class='form-group'>" ^
              "<label for='model'>Modelo</label>" ^
              "<select name='model' id='model'>" ^
                "<option value=''>Todos os modelos</option>" ^
              "</select>" ^
            "</div>" ^
            "<div class='form-group'>" ^
              "<label for='condition'>Condição</label>" ^
              "<select name='condition' id='condition'>" ^
                "<option value=''>Usado + Novo</option>" ^
                "<option value='used'>Usado</option>" ^
                "<option value='new'>Novo</option>" ^
              "</select>" ^
            "</div>" ^
            "<div class='form-group'>" ^
              "<label for='year_min'>Ano mínimo</label>" ^
              "<select name='year_min' id='year_min'>" ^
                "<option value=''>Qualquer ano</option>" ^
                "<option value='2023'>2023+</option>" ^
                "<option value='2020'>2020+</option>" ^
                "<option value='2018'>2018+</option>" ^
                "<option value='2015'>2015+</option>" ^
                "<option value='2010'>2010+</option>" ^
              "</select>" ^
            "</div>" ^
            "<button type='submit' class='btn' style='padding: 1rem 2rem; font-size: 1.1rem;'>🔍 Buscar Veículos</button>" ^
          "</form>" ^
        "</section>" ^

        "<!-- How it Works Section -->" ^
        "<section style='margin: 4rem 0; padding: 3rem; background: var(--bg-secondary); border-radius: 1rem;'>" ^
          "<div style='text-align: center; margin-bottom: 3rem;'>" ^
            "<h2 style='color: var(--text-primary); font-size: 2rem; font-weight: 700; margin-bottom: 1rem;'>Como Funciona</h2>" ^
            "<p style='color: var(--text-muted); font-size: 1.1rem;'>Encontre carros de todos os principais sites em uma única busca</p>" ^
          "</div>" ^
          
          "<div style='display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 2rem;'>" ^
            "<div style='text-align: center;'>" ^
              "<div style='width: 80px; height: 80px; background: var(--accent); border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1rem; font-size: 2rem;'>🔍</div>" ^
              "<h3 style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem;'>Busque Uma Vez</h3>" ^
              "<p style='color: var(--text-muted); line-height: 1.6;'>Pesquise em todos os principais sites de carros do Brasil simultaneamente</p>" ^
            "</div>" ^
            "<div style='text-align: center;'>" ^
              "<div style='width: 80px; height: 80px; background: var(--accent); border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1rem; font-size: 2rem;'>📊</div>" ^
              "<h3 style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem;'>Compare Preços</h3>" ^
              "<p style='color: var(--text-muted); line-height: 1.6;'>Veja todos os resultados organizados para encontrar o melhor negócio</p>" ^
            "</div>" ^
            "<div style='text-align: center;'>" ^
              "<div style='width: 80px; height: 80px; background: var(--accent); border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1rem; font-size: 2rem;'>🚗</div>" ^
              "<h3 style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem;'>Compre Seguro</h3>" ^
              "<p style='color: var(--text-muted); line-height: 1.6;'>Contate vendedores direto pelos canais oficiais de cada plataforma</p>" ^
            "</div>" ^
          "</div>" ^
        "</section>" ^
        
        "<!-- Pricing Plans Section -->" ^
        "<section style='margin: 4rem 0;'>" ^
          "<div style='text-align: center; margin-bottom: 3rem;'>" ^
            "<h2 style='color: var(--text-primary); font-size: 2rem; font-weight: 700; margin-bottom: 1rem;'>Anuncie no BusCars</h2>" ^
            "<p style='color: var(--text-muted); font-size: 1.1rem;'>Alcance milhões de compradores com nossos planos de anúncios</p>" ^
          "</div>" ^
          
          "<div style='display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 2rem;'>" ^
            "<!-- Individual Plan -->" ^
            "<div style='background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem; padding: 2rem; text-align: center; position: relative;'>" ^
              "<h3 style='color: var(--text-primary); font-size: 1.25rem; font-weight: 600; margin-bottom: 1rem;'>Individual</h3>" ^
              "<div style='margin-bottom: 1.5rem;'>" ^
                "<span style='color: var(--accent); font-size: 2.5rem; font-weight: 800;'>R$ 30</span>" ^
                "<span style='color: var(--text-muted); font-size: 0.9rem;'>/mês</span>" ^
              "</div>" ^
              "<ul style='list-style: none; padding: 0; margin-bottom: 2rem; text-align: left;'>" ^
                "<li style='color: var(--text-secondary); margin-bottom: 0.5rem; padding-left: 1.5rem; position: relative;'>✓ 1 anúncio ativo</li>" ^
                "<li style='color: var(--text-secondary); margin-bottom: 0.5rem; padding-left: 1.5rem; position: relative;'>✓ 5 fotos por anúncio</li>" ^
                "<li style='color: var(--text-secondary); margin-bottom: 0.5rem; padding-left: 1.5rem; position: relative;'>✓ Contato direto</li>" ^
                "<li style='color: var(--text-secondary); margin-bottom: 0.5rem; padding-left: 1.5rem; position: relative;'>✓ Suporte básico</li>" ^
              "</ul>" ^
              "<button class='btn' style='width: 100%;'>Começar Agora</button>" ^
            "</div>" ^
            
            "<!-- Professional Plan -->" ^
            "<div style='background: var(--bg-card); border: 2px solid var(--accent); border-radius: 1rem; padding: 2rem; text-align: center; position: relative;'>" ^
              "<div style='position: absolute; top: -12px; left: 50%; transform: translateX(-50%); background: var(--accent); color: white; padding: 0.25rem 1rem; border-radius: 1rem; font-size: 0.75rem; font-weight: 600;'>POPULAR</div>" ^
              "<h3 style='color: var(--text-primary); font-size: 1.25rem; font-weight: 600; margin-bottom: 1rem;'>Profissional</h3>" ^
              "<div style='margin-bottom: 1.5rem;'>" ^
                "<span style='color: var(--accent); font-size: 2.5rem; font-weight: 800;'>R$ 89</span>" ^
                "<span style='color: var(--text-muted); font-size: 0.9rem;'>/mês</span>" ^
              "</div>" ^
              "<ul style='list-style: none; padding: 0; margin-bottom: 2rem; text-align: left;'>" ^
                "<li style='color: var(--text-secondary); margin-bottom: 0.5rem; padding-left: 1.5rem; position: relative;'>✓ 5 anúncios ativos</li>" ^
                "<li style='color: var(--text-secondary); margin-bottom: 0.5rem; padding-left: 1.5rem; position: relative;'>✓ 15 fotos por anúncio</li>" ^
                "<li style='color: var(--text-secondary); margin-bottom: 0.5rem; padding-left: 1.5rem; position: relative;'>✓ Destaque nos resultados</li>" ^
                "<li style='color: var(--text-secondary); margin-bottom: 0.5rem; padding-left: 1.5rem; position: relative;'>✓ Relatórios de desempenho</li>" ^
                "<li style='color: var(--text-secondary); margin-bottom: 0.5rem; padding-left: 1.5rem; position: relative;'>✓ Suporte prioritário</li>" ^
              "</ul>" ^
              "<button class='btn' style='width: 100%;'>Escolher Plano</button>" ^
            "</div>" ^
            
            "<!-- Business Plan -->" ^
            "<div style='background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem; padding: 2rem; text-align: center; position: relative;'>" ^
              "<h3 style='color: var(--text-primary); font-size: 1.25rem; font-weight: 600; margin-bottom: 1rem;'>Empresarial</h3>" ^
              "<div style='margin-bottom: 1.5rem;'>" ^
                "<span style='color: var(--accent); font-size: 2.5rem; font-weight: 800;'>R$ 299</span>" ^
                "<span style='color: var(--text-muted); font-size: 0.9rem;'>/mês</span>" ^
              "</div>" ^
              "<ul style='list-style: none; padding: 0; margin-bottom: 2rem; text-align: left;'>" ^
                "<li style='color: var(--text-secondary); margin-bottom: 0.5rem; padding-left: 1.5rem; position: relative;'>✓ Anúncios ilimitados</li>" ^
                "<li style='color: var(--text-secondary); margin-bottom: 0.5rem; padding-left: 1.5rem; position: relative;'>✓ Fotos ilimitadas</li>" ^
                "<li style='color: var(--text-secondary); margin-bottom: 0.5rem; padding-left: 1.5rem; position: relative;'>✓ API integração</li>" ^
                "<li style='color: var(--text-secondary); margin-bottom: 0.5rem; padding-left: 1.5rem; position: relative;'>✓ Marca personalizada</li>" ^
                "<li style='color: var(--text-secondary); margin-bottom: 0.5rem; padding-left: 1.5rem; position: relative;'>✓ Gerente dedicado</li>" ^
              "</ul>" ^
              "<button class='btn' style='width: 100%;'>Falar com Vendas</button>" ^
            "</div>" ^
          "</div>" ^
        "</section>" ^

        "<section style='margin: 4rem 0; padding: 3rem; border-radius: 1rem;'>" ^
          "<!-- Available Platforms (No Redirect) -->" ^
          "<div style='background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem; padding: 2rem; margin-bottom: 3rem;'>" ^
            "<div style='text-align: center; margin-bottom: 2rem;'>" ^
              "<h2 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1rem;'>🌐 Plataformas Integradas</h2>" ^
              "<p style='color: var(--text-muted);'>Resultados agregados das principais plataformas do Brasil</p>" ^
            "</div>" ^
            
            "<div style='display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1.5rem;'>" ^
              "<div style='text-align: center; padding: 1.5rem; background: var(--bg-secondary); border-radius: 1rem;'>" ^
                "<img src='https://placehold.co/120x40/10b981/ffffff?text=BusCars' style='height: 25px; margin-bottom: 1rem;'>" ^
                "<h4 style='color: var(--text-primary); margin-bottom: 0.5rem; font-size: 1rem;'>BusCars Premium</h4>" ^
                "<p style='color: var(--text-muted); font-size: 0.8rem;'>Anúncios verificados</p>" ^
              "</div>" ^
              
              "<div style='text-align: center; padding: 1.5rem; background: var(--bg-secondary); border-radius: 1rem;'>" ^
                "<img src='https://placehold.co/120x40/10b981/ffffff?text=Webmotors' style='height: 25px; margin-bottom: 1rem;'>" ^
                "<h4 style='color: var(--text-primary); margin-bottom: 0.5rem; font-size: 1rem;'>Webmotors</h4>" ^
                "<p style='color: var(--text-muted); font-size: 0.8rem;'>Maior plataforma</p>" ^
              "</div>" ^
              
              "<div style='text-align: center; padding: 1.5rem; background: var(--bg-secondary); border-radius: 1rem;'>" ^
                "<img src='https://placehold.co/120x40/059669/ffffff?text=Localiza' style='height: 25px; margin-bottom: 1rem;'>" ^
                "<h4 style='color: var(--text-primary); margin-bottom: 0.5rem; font-size: 1rem;'>Localiza</h4>" ^
                "<p style='color: var(--text-muted); font-size: 0.8rem;'>Seminovos</p>" ^
              "</div>" ^
              
              "<div style='text-align: center; padding: 1.5rem; background: var(--bg-secondary); border-radius: 1rem;'>" ^
                "<img src='https://placehold.co/120x40/374151/ffffff?text=iCarros' style='height: 25px; margin-bottom: 1rem;'>" ^
                "<h4 style='color: var(--text-primary); margin-bottom: 0.5rem; font-size: 1rem;'>iCarros</h4>" ^
                "<p style='color: var(--text-muted); font-size: 0.8rem;'>Avaliações</p>" ^
              "</div>" ^
            "</div>" ^
          "</div>" ^
        "</section>" ^
      "</div>" ^
      
      {|<script>
const brandModels = {
  'Porsche': ['911', 'Cayenne', 'Macan', 'Panamera', 'Taycan', '356A'],
  'Toyota': ['Corolla', 'Camry', 'Prius', 'RAV4', 'Hilux'],
  'BMW': ['Série 3', 'Série 5', 'X3', 'X5', 'i4'],
  'Volkswagen': ['Golf', 'Jetta', 'Passat', 'Tiguan', 'T-Cross'],
  'Ford': ['Ka', 'Fiesta', 'Focus', 'EcoSport', 'Ranger'],
  'Chevrolet': ['Onix', 'Prisma', 'Cruze', 'Tracker', 'S10']
};

function updateModels() {
  const brandSelect = document.getElementById('brand');
  const modelSelect = document.getElementById('model');
  const selectedBrand = brandSelect.value;
  
  modelSelect.innerHTML = '<option value="">Todos os modelos</option>';
  
  if (selectedBrand && brandModels[selectedBrand]) {
    brandModels[selectedBrand].forEach(function(model) {
      const option = document.createElement('option');
      option.value = model;
      option.textContent = model;
      modelSelect.appendChild(option);
    });
  }
}
</script>|} in
  base_template ~title:"BusCars - Todos os carros. Uma busca." ~content

(* Professional vehicle listing page with sidebar layout *)
let vehicle_listing_template ~vehicles ~page ~total_pages ~total_count ~start_index ~end_index () =
  
  (* Enhanced vehicle cards with more details *)
  let vehicle_cards = 
    List.fold_left (fun acc vehicle ->
      acc ^
      "<div class='vehicle-card-mobile' data-price='" ^ vehicle.price ^ "' data-year='" ^ string_of_int vehicle.year ^ "' data-mileage='" ^ vehicle.mileage ^ "' style='background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem; padding: 0; margin-bottom: 1.5rem; overflow: hidden; transition: all 0.3s ease; cursor: pointer;' onclick=\"goToVehicle('" ^ vehicle.slug ^ "')\" onmouseover='this.style.transform=\"translateY(-2px)\"; this.style.boxShadow=\"var(--shadow-lg)\"' onmouseout='this.style.transform=\"translateY(0)\"; this.style.boxShadow=\"var(--shadow)\"'>" ^
        "<div style='display: grid; grid-template-columns: 300px 1fr 200px; gap: 0; min-height: 220px;'>" ^
          
          "<!-- Vehicle Image -->" ^
          "<div style='position: relative; background-image: url(\"" ^ vehicle.image ^ "\"); background-size: cover; background-position: center;' onclick=\"event.stopPropagation(); goToVehicle('" ^ vehicle.slug ^ "')\">" ^
            "<div style='position: absolute; top: 1rem; left: 1rem; background: " ^ 
              (if vehicle.condition = "new" then "var(--accent)" else 
               match vehicle.source with 
               | "buscar" -> "linear-gradient(135deg, var(--accent), var(--accent-hover))"
               | "webmotors" -> "#10b981" 
               | "localiza" -> "#059669"
               | "icarros" -> "#374151"
               | _ -> "#764ba2") ^ 
              "; color: white; padding: 0.375rem 0.75rem; border-radius: 1rem; font-size: 0.75rem; font-weight: 700;'>" ^
              (if vehicle.condition = "new" then "NOVO" else String.uppercase_ascii vehicle.source) ^ 
            "</div>" ^
            (if vehicle.source = "buscar" then
              "<div style='position: absolute; top: 1rem; right: 1rem; background: rgba(255,255,255,0.95); color: var(--accent); padding: 0.25rem 0.5rem; border-radius: 0.5rem; font-size: 0.7rem; font-weight: 700;'>✓ VERIFICADO</div>"
             else "") ^
          "</div>" ^
          
          "<!-- Vehicle Info -->" ^
          "<div style='padding: 1.5rem; display: flex; flex-direction: column; justify-content: space-between;'>" ^
            "<div>" ^
              "<div style='display: flex; justify-content: space-between; align-items: start; margin-bottom: 0.75rem;'>" ^
                "<h3 style='color: var(--text-primary); font-size: 1.25rem; font-weight: 700; margin: 0; line-height: 1.3; cursor: pointer;' onclick=\"event.stopPropagation(); location.href='/vehicle/" ^ vehicle.slug ^ "'\">" ^ vehicle.brand ^ " " ^ vehicle.model ^ " " ^ string_of_int vehicle.year ^ "</h3>" ^
                "<span style='color: var(--text-muted); font-size: 0.8rem; opacity: 0.8;'>" ^ vehicle.location_city ^ "</span>" ^
              "</div>" ^
              
              "<p style='color: var(--text-muted); font-size: 0.9rem; margin-bottom: 1rem; line-height: 1.4;'>" ^ vehicle.description ^ "</p>" ^
              
              "<div style='display: grid; grid-template-columns: repeat(auto-fit, minmax(100px, 1fr)); gap: 0.5rem; margin-bottom: 1rem;'>" ^
                "<div style='text-align: center; padding: 0.5rem; background: var(--bg-secondary); border-radius: 0.5rem;'>" ^
                  "<div style='color: var(--text-muted); font-size: 0.7rem; margin-bottom: 0.25rem;'>ANO</div>" ^
                  "<div style='color: var(--text-primary); font-weight: 600; font-size: 0.85rem;'>" ^ string_of_int vehicle.year ^ "</div>" ^
                "</div>" ^
                "<div style='text-align: center; padding: 0.5rem; background: var(--bg-secondary); border-radius: 0.5rem;'>" ^
                  "<div style='color: var(--text-muted); font-size: 0.7rem; margin-bottom: 0.25rem;'>KM</div>" ^
                  "<div style='color: var(--text-primary); font-weight: 600; font-size: 0.85rem;'>" ^ vehicle.mileage ^ "</div>" ^
                "</div>" ^
                "<div style='text-align: center; padding: 0.5rem; background: var(--bg-secondary); border-radius: 0.5rem;'>" ^
                  "<div style='color: var(--text-muted); font-size: 0.7rem; margin-bottom: 0.25rem;'>MOTOR</div>" ^
                  "<div style='color: var(--text-primary); font-weight: 600; font-size: 0.85rem;'>" ^ vehicle.fuel_type ^ "</div>" ^
                "</div>" ^
                "<div style='text-align: center; padding: 0.5rem; background: var(--bg-secondary); border-radius: 0.5rem;'>" ^
                  "<div style='color: var(--text-muted); font-size: 0.7rem; margin-bottom: 0.25rem;'>COR</div>" ^
                  "<div style='color: var(--text-primary); font-weight: 600; font-size: 0.85rem;'>" ^ vehicle.color ^ "</div>" ^
                "</div>" ^
                
                (if vehicle.financing_available then
                  "<div style='text-align: center; padding: 0.5rem; background: var(--accent); color: white; border-radius: 0.5rem;'>" ^
                    "<div style='font-size: 0.7rem; margin-bottom: 0.25rem;'>FINANC.</div>" ^
                    "<div style='font-weight: 600; font-size: 0.85rem;'>💳 SIM</div>" ^
                  "</div>"
                 else "") ^
                
                (if vehicle.trade_accepted then
                  "<div style='text-align: center; padding: 0.5rem; background: var(--bg-secondary); border: 1px solid var(--accent); border-radius: 0.5rem;'>" ^
                    "<div style='color: var(--text-muted); font-size: 0.7rem; margin-bottom: 0.25rem;'>TROCA</div>" ^
                    "<div style='color: var(--accent); font-weight: 600; font-size: 0.85rem;'>🔄 SIM</div>" ^
                  "</div>"
                 else "") ^
                
                (if vehicle.test_drive_available then
                  "<div style='text-align: center; padding: 0.5rem; background: var(--bg-secondary); border: 1px solid var(--accent); border-radius: 0.5rem;'>" ^
                    "<div style='color: var(--text-muted); font-size: 0.7rem; margin-bottom: 0.25rem;'>TEST</div>" ^
                    "<div style='color: var(--accent); font-weight: 600; font-size: 0.85rem;'>🚗 SIM</div>" ^
                  "</div>"
                 else "") ^
              "</div>" ^
            "</div>" ^
            
            "<div style='display: flex; justify-content: flex-end; align-items: center;'>" ^
              "<span style='color: var(--text-muted); font-size: 0.8rem; font-style: italic;'>Via " ^ (String.capitalize_ascii vehicle.source) ^ "</span>" ^
            "</div>" ^
          "</div>" ^
          
          "<!-- Price Section -->" ^
          "<div style='padding: 1.5rem; background: var(--bg-secondary); display: flex; flex-direction: column; justify-content: space-between; align-items: center; width: 200px;'>" ^
            "<div style='text-align: center; margin-bottom: 1rem;'>" ^
              "<h4 style='color: var(--accent); font-size: 1.6rem; font-weight: 800; margin-bottom: 0.25rem; line-height: 1.1;'>R$ " ^ vehicle.price ^ "</h4>" ^
              "<p style='color: var(--text-muted); font-size: 0.8rem;'>" ^ (if vehicle.condition = "new" then "Novo" else "À vista") ^ "</p>" ^
            "</div>" ^
              
            "<div style='display: flex; flex-direction: column; gap: 0.75rem; width: 100%;'>" ^
              "<button onclick=\"event.stopPropagation(); location.href='/vehicle/" ^ vehicle.slug ^ "'\" class='btn' style='background: var(--accent); color: white; border: none; padding: 0.75rem 1rem; border-radius: 0.5rem; font-size: 0.85rem; font-weight: 600; cursor: pointer; width: 100%; text-align: center;'>Ver Detalhes</button>" ^
            "</div>" ^
          "</div>" ^
        "</div>" ^
      "</div>"
    ) "" vehicles
  in
  
  base_template ~title:"BusCars - Catálogo de Veículos" ~content:(
      "<div class='container' style='max-width: 1400px;'>" ^
        "<!-- Header -->" ^
        "<div style='margin: 2rem 0;'>" ^
          "<h1 style='color: var(--text-primary); font-size: 2.25rem; font-weight: 800; margin-bottom: 0.5rem;'>Catálogo de Veículos</h1>" ^
          "<p style='color: var(--text-muted); font-size: 1.1rem;'>Encontre o carro ideal entre milhares de opções</p>" ^
        "</div>" ^
        
        "<!-- Main Content Area -->" ^
        "<div class='listing-layout' style='display: grid; grid-template-columns: 300px 1fr; gap: 2rem;'>" ^
          "<!-- Left Sidebar - Filters -->" ^
          "<div style='position: sticky; top: 7rem; height: fit-content;'>" ^
            "<div style='background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem; padding: 2rem;'>" ^
              "<div style='margin-bottom: 2rem;'>" ^
                "<h3 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1rem;'>🔍 Filtros</h3>" ^
                "<div style='display: flex; gap: 0.5rem;'>" ^
                  "<button type='submit' form='filter-form' class='btn' style='flex: 1; padding: 0.5rem 1rem; font-size: 0.85rem;'>Filtrar</button>" ^
                  "<button onclick='clearFilters()' class='btn-outline btn' style='flex: 1; padding: 0.5rem 1rem; font-size: 0.85rem;'>Limpar</button>" ^
                "</div>" ^
              "</div>" ^
              
              "<form method='get' action='/vehicles' id='filter-form'>" ^
                "<div style='display: flex; flex-direction: column; gap: 1.5rem;'>" ^
                  
                  "<!-- Source Filter -->" ^
                  "<div class='form-group'>" ^
                    "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.9rem;'>Fonte</label>" ^
                    "<select name='source' id='source' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      "<option value=''>Todas as fontes</option>" ^
                      "<option value='buscar'>BusCars Premium</option>" ^
                      "<option value='webmotors'>Webmotors</option>" ^
                      "<option value='localiza'>Localiza</option>" ^
                      "<option value='icarros'>iCarros</option>" ^
                    "</select>" ^
                  "</div>" ^
                  
                  "<!-- Brand Filter -->" ^
                  "<div class='form-group'>" ^
                    "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.9rem;'>Marca</label>" ^
                    "<select name='brand' id='brand' onchange='filterModels()' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      "<option value=''>Todas as marcas</option>" ^
                      "<option value='Porsche'>Porsche</option>" ^
                      "<option value='Toyota'>Toyota</option>" ^
                      "<option value='BMW'>BMW</option>" ^
                      "<option value='Volkswagen'>Volkswagen</option>" ^
                      "<option value='Ford'>Ford</option>" ^
                      "<option value='Chevrolet'>Chevrolet</option>" ^
                    "</select>" ^
                  "</div>" ^
                  
                  "<!-- Model Filter -->" ^
                  "<div class='form-group'>" ^
                    "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.9rem;'>Modelo</label>" ^
                    "<select name='model' id='model' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      "<option value=''>Todos os modelos</option>" ^
                    "</select>" ^
                  "</div>" ^
                  
                  "<!-- Condition Filter -->" ^
                  "<div class='form-group'>" ^
                    "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.9rem;'>Condição</label>" ^
                    "<select name='condition' id='condition' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      "<option value=''>Usado + Novo</option>" ^
                      "<option value='used'>Usado</option>" ^
                      "<option value='new'>Novo</option>" ^
                    "</select>" ^
                  "</div>" ^
                  
                  "<!-- Year Filter -->" ^
                  "<div class='form-group'>" ^
                    "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.9rem;'>Ano Mínimo</label>" ^
                    "<select name='year_min' id='year_min' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      "<option value=''>Qualquer ano</option>" ^
                      "<option value='2023'>2023+</option>" ^
                      "<option value='2020'>2020+</option>" ^
                      "<option value='2018'>2018+</option>" ^
                      "<option value='2015'>2015+</option>" ^
                      "<option value='2010'>2010+</option>" ^
                    "</select>" ^
                  "</div>" ^
                  
                  "<!-- Price Filter -->" ^
                  "<div class='form-group'>" ^
                    "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.9rem;'>Preço Máximo</label>" ^
                    "<select name='price_max' id='price_max' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      "<option value=''>Qualquer preço</option>" ^
                      "<option value='100000'>Até R$ 100k</option>" ^
                      "<option value='300000'>Até R$ 300k</option>" ^
                      "<option value='500000'>Até R$ 500k</option>" ^
                      "<option value='1000000'>Até R$ 1M</option>" ^
                    "</select>" ^
                  "</div>" ^
                  
                  "<!-- Fuel Filter -->" ^
                  "<div class='form-group'>" ^
                    "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.9rem;'>Combustível</label>" ^
                    "<select name='fuel_type' id='fuel_type' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      "<option value=''>Todos</option>" ^
                      "<option value='Gasolina'>Gasolina</option>" ^
                      "<option value='Flex'>Flex</option>" ^
                      "<option value='Diesel'>Diesel</option>" ^
                      "<option value='Elétrico'>Elétrico</option>" ^
                      "<option value='Híbrido'>Híbrido</option>" ^
                    "</select>" ^
                  "</div>" ^
                "</div>" ^
              "</form>" ^
            "</div>" ^
          "</div>" ^
          
          "<!-- Right Content - Vehicle List -->" ^
          "<div>" ^
            "<div style='display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;'>" ^
              "<div>" ^
                "<h2 style='color: var(--text-primary); font-weight: 700; margin-bottom: 0.25rem;'>Veículos Disponíveis</h2>" ^
                "<p style='color: var(--text-muted); font-size: 0.95rem;'>" ^ string_of_int total_count ^ " resultados encontrados • Página " ^ string_of_int page ^ " de " ^ string_of_int total_pages ^ " • Mostrando " ^ string_of_int (List.length vehicles) ^ " veículos</p>" ^
              "</div>" ^
              "<div style='display: flex; gap: 1rem; align-items: center;'>" ^
                "<select id='sort-dropdown' onchange='applySorting()' style='padding: 0.5rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary); font-size: 0.875rem;'>" ^
                  "<option value='relevance'>Ordenar por relevância</option>" ^
                  "<option value='price_asc'>Menor preço</option>" ^
                  "<option value='price_desc'>Maior preço</option>" ^
                  "<option value='year_desc'>Mais novo</option>" ^
                  "<option value='mileage_asc'>Menor KM</option>" ^
                "</select>" ^
              "</div>" ^
            "</div>" ^
            
            (if total_count = 0 then
              "<div style='text-align: center; padding: 4rem; color: var(--text-muted);'>" ^
                "<h3>Nenhum veículo encontrado</h3>" ^
                "<p>Tente ajustar os filtros ou buscar em outras plataformas</p>" ^
              "</div>"
             else
              "<div>" ^
                "<div class='vehicle-list-container' style='display: flex; flex-direction: column;'>" ^
                  vehicle_cards ^
                "</div>" ^
                
                "<!-- Proper Pagination -->" ^
                (if total_pages > 1 then
                  "<div class='pagination-mobile' style='display: flex; justify-content: center; align-items: center; gap: 1rem; margin: 3rem 0; padding: 2rem; background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem;'>" ^
                    (if page > 1 then
                      "<button onclick='goToPage(" ^ string_of_int (page - 1) ^ "); console.log(\"Clicked previous\");' style='background: var(--accent); color: white; border: none; padding: 0.75rem 1rem; border-radius: 0.5rem; cursor: pointer; font-weight: 600;'>← Anterior</button>"
                     else
                      "<button disabled style='background: var(--bg-secondary); color: var(--text-muted); border: none; padding: 0.75rem 1rem; border-radius: 0.5rem; cursor: not-allowed; font-weight: 600;'>← Anterior</button>") ^
                    
                    "<div style='display: flex; gap: 0.5rem; align-items: center;'>" ^
                      "<span style='color: var(--text-muted); margin-right: 1rem;'>Página " ^ string_of_int page ^ " de " ^ string_of_int total_pages ^ "</span>" ^
                      
                      "<!-- Debug: Current page " ^ string_of_int page ^ ", Total pages " ^ string_of_int total_pages ^ " -->" ^
                      (if page = 1 then
                        "<span style='background: var(--accent); color: white; padding: 0.5rem 0.75rem; border-radius: 0.5rem; font-weight: 600; min-width: 40px; text-align: center; margin: 0 0.25rem;'>1</span>"
                       else
                        "<button onclick='goToPage(1); console.log(\"Clicked page 1\");' style='background: var(--bg-secondary); color: var(--text-primary); border: 1px solid var(--border-color); padding: 0.5rem 0.75rem; border-radius: 0.5rem; cursor: pointer; font-weight: 600; min-width: 40px; margin: 0 0.25rem;'>1</button>") ^
                      
                      (if total_pages > 1 then
                        (if page = 2 then
                          "<span style='background: var(--accent); color: white; padding: 0.5rem 0.75rem; border-radius: 0.5rem; font-weight: 600; min-width: 40px; text-align: center; margin: 0 0.25rem;'>2</span>"
                         else
                          "<button onclick='goToPage(2); console.log(\"Clicked page 2\");' style='background: var(--bg-secondary); color: var(--text-primary); border: 1px solid var(--border-color); padding: 0.5rem 0.75rem; border-radius: 0.5rem; cursor: pointer; font-weight: 600; min-width: 40px; margin: 0 0.25rem;'>2</button>")
                       else "") ^
                      
                      (if total_pages > 2 then
                        (if page = 3 then
                          "<span style='background: var(--accent); color: white; padding: 0.5rem 0.75rem; border-radius: 0.5rem; font-weight: 600; min-width: 40px; text-align: center; margin: 0 0.25rem;'>3</span>"
                         else
                          "<button onclick='goToPage(3); console.log(\"Clicked page 3\");' style='background: var(--bg-secondary); color: var(--text-primary); border: 1px solid var(--border-color); padding: 0.5rem 0.75rem; border-radius: 0.5rem; cursor: pointer; font-weight: 600; min-width: 40px; margin: 0 0.25rem;'>3</button>")
                       else "") ^
                    "</div>" ^
                    
                    (if page < total_pages then
                      "<button onclick='goToPage(" ^ string_of_int (page + 1) ^ "); console.log(\"Clicked next\");' style='background: var(--accent); color: white; border: none; padding: 0.75rem 1rem; border-radius: 0.5rem; cursor: pointer; font-weight: 600;'>Próxima →</button>"
                     else
                      "<button disabled style='background: var(--bg-secondary); color: var(--text-muted); border: none; padding: 0.75rem 1rem; border-radius: 0.5rem; cursor: not-allowed; font-weight: 600;'>Próxima →</button>") ^
                    
                    "<div style='margin-left: 2rem; color: var(--text-muted); font-size: 0.875rem;'>" ^
                      "<span>Mostrando " ^ string_of_int (start_index + 1) ^ "-" ^ string_of_int end_index ^ " de " ^ string_of_int total_count ^ " resultados</span>" ^
                    "</div>" ^
                  "</div>"
                 else "") ^
              "</div>") ^
          "</div>" ^
        "</div>" ^
      "</div>" ^
      
      {|<script>
// Brand models data
const brandModels = {
  'Porsche': ['911', 'Cayenne', 'Macan', 'Panamera', 'Taycan', '356A'],
  'Toyota': ['Corolla', 'Camry', 'Prius', 'RAV4', 'Hilux'],
  'BMW': ['Série 3', 'Série 5', 'X3', 'X5', 'i4'],
  'Volkswagen': ['Golf', 'Jetta', 'Passat', 'Tiguan', 'T-Cross'],
  'Ford': ['Ka', 'Fiesta', 'Focus', 'EcoSport', 'Ranger'],
  'Chevrolet': ['Onix', 'Prisma', 'Cruze', 'Tracker', 'S10']
};

// Filter models based on selected brand
function filterModels() {
  console.log('Filtering models');
  const brandSelect = document.getElementById('brand');
  const modelSelect = document.getElementById('model');
  const selectedBrand = brandSelect.value;
  
  modelSelect.innerHTML = '<option value="">Todos os modelos</option>';
  
  if (selectedBrand && brandModels[selectedBrand]) {
    brandModels[selectedBrand].forEach(function(model) {
      const option = document.createElement('option');
      option.value = model;
      option.textContent = model;
      modelSelect.appendChild(option);
    });
  }
}

// Clear all filters
function clearFilters() {
  console.log('Clearing filters');
  window.location.href = '/vehicles';
}

// Apply sorting
function applySorting() {
  console.log('Applying sort');
  const sortValue = document.getElementById('sort-dropdown').value;
  const params = new URLSearchParams(window.location.search);
  params.set('sort', sortValue);
  params.set('page', '1');
  window.location.href = '/vehicles?' + params.toString();
}

// Navigate to specific page
function goToPage(pageNum) {
  console.log('Going to page:', pageNum);
  const params = new URLSearchParams(window.location.search);
  params.set('page', pageNum.toString());
  window.location.href = '/vehicles?' + params.toString();
}

// Navigate to vehicle with current state preserved
function goToVehicle(slug) {
  const params = new URLSearchParams(window.location.search);
  // Remove page param since we're leaving the listing
  params.delete('page');
  const returnUrl = params.toString() ? '?' + params.toString() : '';
  window.location.href = '/vehicle/' + slug + '?return=' + encodeURIComponent('/vehicles' + returnUrl);
}

// Initialize page on load
document.addEventListener('DOMContentLoaded', function() {
  console.log('DOM loaded, initializing page');
  const urlParams = new URLSearchParams(window.location.search);
  
  // Set brand and trigger model update
  const brandValue = urlParams.get('brand');
  if (brandValue) {
    const brandSelect = document.getElementById('brand');
    if (brandSelect) {
      brandSelect.value = brandValue;
      filterModels();
      const modelValue = urlParams.get('model');
      if (modelValue) {
        setTimeout(function() {
          const modelSelect = document.getElementById('model');
          if (modelSelect) modelSelect.value = modelValue;
        }, 100);
      }
    }
  }
  
  // Set other filter values
  const filterFields = ['year_min', 'price_max', 'fuel_type', 'condition', 'source'];
  filterFields.forEach(function(field) {
    const value = urlParams.get(field);
    if (value) {
      const element = document.getElementById(field);
      if (element) element.value = value;
    }
  });
  
  // Set sort dropdown
  const sortValue = urlParams.get('sort');
  if (sortValue) {
    const sortDropdown = document.getElementById('sort-dropdown');
    if (sortDropdown) sortDropdown.value = sortValue;
  }
  
  console.log('Page initialized successfully');
});
</script>|}
    )

(* Modern login template *)
let login_template ?error () =
  let error_msg = match error with
    | Some msg -> "<div class='error'>" ^ msg ^ "</div>"
    | None -> ""
  in
  
  base_template ~title:"BusCars - Login" ~content:(
      "<div class='container'>" ^
        "<div class='login-container'>" ^
          "<div style='text-align: center; margin-bottom: 2rem;'>" ^
            "<img src='/logo-buscar.png' alt='BusCars' style='height: 60px; width: auto; margin-bottom: 1rem;'>" ^
            "<h2 style='color: var(--text-primary); font-weight: 700; margin-bottom: 0.5rem;'>Bem-vindo de volta</h2>" ^
            "<p style='color: var(--text-muted);'>Entre na sua conta</p>" ^
          "</div>" ^
          error_msg ^
          
          "<form method='post' action='/login'>" ^
            "<div class='form-group'>" ^
              "<label for='email'>E-mail</label>" ^
              "<input type='email' name='email' id='email' required placeholder='seu@email.com' value='admin@buscar.com'>" ^
            "</div>" ^
            "<div class='form-group'>" ^
              "<label for='password'>Senha</label>" ^
              "<input type='password' name='password' id='password' required placeholder='Sua senha' value='123456'>" ^
            "</div>" ^
            "<button type='submit' class='btn' style='width: 100%; margin-top: 1.5rem;'>Entrar na Conta</button>" ^
          "</form>" ^
          
          "<div style='text-align: center; margin-top: 2rem; padding-top: 2rem; border-top: 1px solid var(--border-color);'>" ^
            "<p style='color: var(--text-muted); font-size: 0.875rem;'>Não tem uma conta?</p>" ^
            "<a href='/register' style='color: var(--accent); font-weight: 600; text-decoration: none;'>Cadastre-se gratuitamente</a>" ^
          "</div>" ^
        "</div>" ^
      "</div>"
    )

(* Modern dashboard template *)
let dashboard_template ~user ~vehicles () =
  let total_vehicles = List.length vehicles in
  let vehicle_cards = 
    List.fold_left (fun acc vehicle ->
      acc ^
      "<div class='vehicle-card'>" ^
        "<div class='vehicle-image' style='background-image: url(\"" ^ vehicle.image ^ "\")'></div>" ^
        "<div class='vehicle-info'>" ^
          "<h3 class='vehicle-title'>" ^ vehicle.brand ^ " " ^ vehicle.model ^ "</h3>" ^
          "<p class='vehicle-price'>R$ " ^ vehicle.price ^ "</p>" ^
          "<div class='vehicle-specs'>" ^
            "<div class='spec-item'>" ^
              "<span class='spec-label'>Status</span>" ^
              "<span class='spec-value'>Ativo</span>" ^
            "</div>" ^
            "<div class='spec-item'>" ^
              "<span class='spec-label'>Visualizações</span>" ^
              "<span class='spec-value'>" ^ string_of_int (Random.int 100 + 20) ^ "</span>" ^
            "</div>" ^
            "<div class='spec-item'>" ^
              "<span class='spec-label'>Interessados</span>" ^
              "<span class='spec-value'>" ^ string_of_int (Random.int 10 + 1) ^ "</span>" ^
            "</div>" ^
          "</div>" ^
          "<div style='display: flex; gap: 0.5rem; margin-top: 1rem;'>" ^
            "<a href='/dashboard/edit/" ^ string_of_int vehicle.id ^ "' class='btn' style='font-size: 0.875rem; padding: 0.5rem 1rem;'>Editar</a>" ^
            "<a href='/dashboard/delete/" ^ string_of_int vehicle.id ^ "' class='btn-outline btn' style='font-size: 0.875rem; padding: 0.5rem 1rem;'>Excluir</a>" ^
          "</div>" ^
        "</div>" ^
      "</div>"
    ) "" vehicles
  in
  
  base_template ~title:"BusCars - Dashboard" ~content:(
      "<div class='container'>" ^
        "<div style='margin: 2rem 0;'>" ^
          "<div class='dashboard-header'>" ^
            "<div>" ^
              "<h1 style='color: var(--text-primary); margin-bottom: 0.5rem;'>Dashboard</h1>" ^
              "<p style='color: var(--text-muted);'>Olá, " ^ user.name ^ "! Gerencie seus anúncios</p>" ^
            "</div>" ^
            "<a href='/dashboard/add-vehicle' class='btn'>+ Novo Anúncio</a>" ^
          "</div>" ^
          
          "<div class='stats-grid'>" ^
            "<div class='stat-card'>" ^
              "<span class='stat-value'>" ^ string_of_int total_vehicles ^ "</span>" ^
              "<span class='stat-label'>Anúncios Ativos</span>" ^
            "</div>" ^
            "<div class='stat-card'>" ^
              "<span class='stat-value'>" ^ string_of_int (total_vehicles * 45 + 120) ^ "</span>" ^
              "<span class='stat-label'>Visualizações</span>" ^
            "</div>" ^
            "<div class='stat-card'>" ^
              "<span class='stat-value'>" ^ string_of_int (total_vehicles * 5 + 8) ^ "</span>" ^
              "<span class='stat-label'>Contatos</span>" ^
            "</div>" ^
            "<div class='stat-card'>" ^
              "<span class='stat-value'>R$ " ^ string_of_int (total_vehicles * 125000) ^ "</span>" ^
              "<span class='stat-label'>Valor Total</span>" ^
            "</div>" ^
          "</div>" ^
          
          "<section>" ^
            "<div style='display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem;'>" ^
              "<h2 style='color: var(--text-primary); font-weight: 600;'>Seus Anúncios</h2>" ^
              "<a href='/logout' style='color: var(--text-muted); text-decoration: none; font-size: 0.875rem;'>Sair</a>" ^
            "</div>" ^
            (if total_vehicles = 0 then
              "<div style='text-align: center; padding: 4rem; color: var(--text-muted);'>" ^
                "<h3>Nenhum anúncio ainda</h3>" ^
                "<p>Comece criando seu primeiro anúncio de veículo</p>" ^
                "<a href='/dashboard/add-vehicle' class='btn' style='margin-top: 1rem;'>Criar Primeiro Anúncio</a>" ^
              "</div>"
             else
              "<div class='vehicle-grid'>" ^ vehicle_cards ^ "</div>") ^
          "</section>" ^
        "</div>" ^
      "</div>"
    )

(* Premium BusCars detail page - BaT quality with Webmotors slideshow *)
let vehicle_detail_template ~vehicle ~return_url () =
  (* Simple markdown to HTML converter *)
  let markdown_to_html text =
    text
    |> Str.global_replace (Str.regexp "# \\([^\n]+\\)") "<h1 style='color: var(--text-primary); font-size: 1.75rem; font-weight: 800; margin: 2rem 0 1rem 0;'>\\1</h1>"
    |> Str.global_replace (Str.regexp "## \\([^\n]+\\)") "<h2 style='color: var(--text-primary); font-size: 1.5rem; font-weight: 700; margin: 1.5rem 0 1rem 0;'>\\1</h2>"
    |> Str.global_replace (Str.regexp "### \\([^\n]+\\)") "<h3 style='color: var(--text-primary); font-size: 1.25rem; font-weight: 600; margin: 1.25rem 0 0.75rem 0;'>\\1</h3>"
    |> Str.global_replace (Str.regexp "\\*\\*\\([^*]+\\)\\*\\*") "<strong style='font-weight: 700; color: var(--text-primary);'>\\1</strong>"
    |> Str.global_replace (Str.regexp "\\*\\([^*]+\\)\\*") "<em style='font-style: italic;'>\\1</em>"
    |> Str.global_replace (Str.regexp "- \\([^\n]+\\)") "<li style='margin: 0.25rem 0; color: var(--text-secondary);'>\\1</li>"
    |> Str.global_replace (Str.regexp "✅ \\([^\n]+\\)") "<div style='color: var(--accent); margin: 0.5rem 0;'><span style='margin-right: 0.5rem;'>✅</span>\\1</div>"
    |> Str.global_replace (Str.regexp "\n\n") "</p><p style='margin: 1rem 0; line-height: 1.7; color: var(--text-secondary);'>"
    |> fun s -> "<p style='margin: 1rem 0; line-height: 1.7; color: var(--text-secondary);'>" ^ s ^ "</p>"
  in
  
  let all_images = vehicle.image :: vehicle.images in
  let gallery_thumbs = 
    List.mapi (fun i img ->
      "<div class='thumb-item' onclick='changeSlide(" ^ string_of_int i ^ ")' style='cursor: pointer; flex-shrink: 0;'>" ^
        "<img src='" ^ img ^ "' style='width: 80px; height: 60px; object-fit: cover; border-radius: 0.5rem; border: 2px solid transparent; transition: all 0.2s;'>" ^
      "</div>"
    ) all_images |> String.concat ""
  in
  
  let features_list =
    List.map (fun feature ->
      "<div style='padding: 1rem; background: var(--bg-secondary); border-radius: 0.75rem; margin-bottom: 0.75rem;'>" ^
        "<span style='color: var(--accent); margin-right: 0.75rem; font-size: 1.1rem;'>✓</span>" ^
        "<span style='color: var(--text-primary); font-weight: 600;'>" ^ feature ^ "</span>" ^
      "</div>"
    ) vehicle.features |> String.concat ""
  in
  
  let service_timeline =
    List.mapi (fun i service ->
      "<div style='display: flex; gap: 1rem; margin-bottom: 1rem; padding-bottom: 1rem; border-bottom: 1px solid var(--border-color);'>" ^
        "<div style='background: var(--accent); color: white; width: 30px; height: 30px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 600; font-size: 0.875rem;'>" ^ string_of_int (i + 1) ^ "</div>" ^
        "<div style='flex: 1;'>" ^
          "<p style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.25rem;'>" ^ service ^ "</p>" ^
        "</div>" ^
      "</div>"
    ) vehicle.service_history |> String.concat ""
  in
  
  base_template ~title:("BusCars Premium - " ^ vehicle.brand ^ " " ^ vehicle.model ^ " " ^ string_of_int vehicle.year)
    ~content:(
      "<div class='container' style='max-width: 1400px;'>" ^
        "<nav style='margin: 1.5rem 0; padding: 1rem; background: var(--bg-secondary); border-radius: 0.5rem;'>" ^
          "<a href='" ^ return_url ^ "' style='color: var(--text-muted); text-decoration: none; font-size: 0.9rem;'>← Voltar aos resultados</a>" ^
        "</nav>" ^
        
        "<!-- Vehicle Header -->" ^
        "<div style='margin-bottom: 3rem;'>" ^
          "<div style='display: flex; align-items: center; gap: 1rem; margin-bottom: 1rem; flex-wrap: wrap;'>" ^
            "<h1 style='color: var(--text-primary); font-size: clamp(2rem, 4vw, 3rem); font-weight: 900; margin: 0;'>" ^ vehicle.brand ^ " " ^ vehicle.model ^ " " ^ string_of_int vehicle.year ^ "</h1>" ^
            "<span style='background: linear-gradient(135deg, var(--accent), var(--accent-hover)); color: white; padding: 0.5rem 1rem; border-radius: 2rem; font-size: 0.875rem; font-weight: 700;'>🏆 VERIFICADO BUSCARS</span>" ^
          "</div>" ^
          "<div style='display: flex; gap: 3rem; flex-wrap: wrap; color: var(--text-muted); font-size: 1rem; margin-bottom: 1rem;'>" ^
            "<span><strong>" ^ vehicle.mileage ^ " km</strong></span>" ^
            "<span><strong>" ^ vehicle.color ^ "</strong></span>" ^
            "<span><strong>" ^ (if vehicle.condition = "new" then "Novo" else "Usado") ^ "</strong></span>" ^
            "<span><strong>" ^ vehicle.location_city ^ ", " ^ vehicle.location_state ^ "</strong></span>" ^
          "</div>" ^
          "<div style='display: flex; gap: 1rem; flex-wrap: wrap; font-size: 0.875rem;'>" ^
            (if vehicle.financing_available then "<span style='background: var(--accent); color: white; padding: 0.25rem 0.75rem; border-radius: 1rem;'>💳 Financiamento</span>" else "") ^
            (if vehicle.trade_accepted then "<span style='background: var(--bg-secondary); color: var(--text-primary); padding: 0.25rem 0.75rem; border-radius: 1rem;'>🔄 Aceita Troca</span>" else "") ^
            (if vehicle.test_drive_available then "<span style='background: var(--bg-secondary); color: var(--text-primary); padding: 0.25rem 0.75rem; border-radius: 1rem;'>🚗 Test Drive</span>" else "") ^
          "</div>" ^
        "</div>" ^
        
        "<div class='vehicle-detail-grid'>" ^
          "<!-- Left Column - Images and Content -->" ^
          "<div>" ^
            "<!-- Image Slideshow -->" ^
            "<div style='margin-bottom: 3rem;'>" ^
              "<div class='slideshow-container' style='position: relative; background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem; overflow: hidden; margin-bottom: 1rem; height: 600px;'>" ^
                "<img id='main-slide-image' src='" ^ vehicle.image ^ "' style='width: 100%; height: 100%; object-fit: cover;'>" ^
                "<div class='slide-controls'>" ^
                  "<button onclick='previousSlide()' style='position: absolute; left: 1rem; top: 50%; transform: translateY(-50%); background: rgba(0,0,0,0.8); color: white; border: none; border-radius: 50%; width: 50px; height: 50px; font-size: 1.5rem; cursor: pointer; transition: all 0.2s; z-index: 10; display: flex; align-items: center; justify-content: center;'>‹</button>" ^
                  "<button onclick='nextSlide()' style='position: absolute; right: 1rem; top: 50%; transform: translateY(-50%); background: rgba(0,0,0,0.8); color: white; border: none; border-radius: 50%; width: 50px; height: 50px; font-size: 1.5rem; cursor: pointer; transition: all 0.2s; z-index: 10; display: flex; align-items: center; justify-content: center;'>›</button>" ^
                "</div>" ^
                "<div style='position: absolute; bottom: 1rem; right: 1rem; background: rgba(0,0,0,0.9); color: white; padding: 0.75rem 1rem; border-radius: 1rem; font-size: 0.875rem; font-weight: 600;'>" ^
                  "<span id='slide-counter'>1 / " ^ string_of_int (List.length all_images) ^ "</span>" ^
                "</div>" ^
                
                "<!-- Mobile swipe area -->" ^
                "<div style='position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 1;' " ^
                     "ontouchstart='touchStart(event)' ontouchend='touchEnd(event)'></div>" ^
              "</div>" ^
              
              "<!-- Thumbnail Gallery -->" ^
              "<div class='thumbnail-gallery' style='display: flex; gap: 0.75rem; overflow-x: auto; padding: 1rem 0; scroll-behavior: smooth;'>" ^
                gallery_thumbs ^
              "</div>" ^
            "</div>" ^
            
            "<!-- Rich Description -->" ^
            "<div style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 3rem; border-radius: 1rem; margin-bottom: 3rem;'>" ^
              "<div class='markdown-content'>" ^
                (markdown_to_html vehicle.detailed_description_md) ^
              "</div>" ^
            "</div>" ^
            
            "<!-- Technical Specifications -->" ^
            "<div style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 3rem; border-radius: 1rem; margin-bottom: 3rem;'>" ^
              "<h2 style='color: var(--text-primary); font-weight: 800; margin-bottom: 2rem; font-size: 1.75rem;'>🔧 Especificações Técnicas</h2>" ^
              "<div style='display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 2rem;'>" ^
                "<div style='background: var(--bg-secondary); padding: 2rem; border-radius: 1rem;'>" ^
                  "<h3 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1.5rem; font-size: 1.2rem;'>🚗 Motor & Performance</h3>" ^
                  "<div style='display: grid; gap: 1rem;'>" ^
                    "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                      "<span style='color: var(--text-muted); font-weight: 500;'>Motor</span>" ^
                      "<span style='color: var(--text-primary); font-weight: 700;'>" ^ vehicle.engine ^ "</span>" ^
                    "</div>" ^
                    "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                      "<span style='color: var(--text-muted); font-weight: 500;'>Combustível</span>" ^
                      "<span style='color: var(--text-primary); font-weight: 700;'>" ^ vehicle.fuel_type ^ "</span>" ^
                    "</div>" ^
                    "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0;'>" ^
                      "<span style='color: var(--text-muted); font-weight: 500;'>Transmissão</span>" ^
                      "<span style='color: var(--text-primary); font-weight: 700;'>" ^ vehicle.transmission ^ "</span>" ^
                    "</div>" ^
                  "</div>" ^
                "</div>" ^
                
                "<div style='background: var(--bg-secondary); padding: 2rem; border-radius: 1rem;'>" ^
                  "<h3 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1.5rem; font-size: 1.2rem;'>📋 Informações Gerais</h3>" ^
                  "<div style='display: grid; gap: 1rem;'>" ^
                    "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                      "<span style='color: var(--text-muted); font-weight: 500;'>Ano</span>" ^
                      "<span style='color: var(--text-primary); font-weight: 700;'>" ^ string_of_int vehicle.year ^ "</span>" ^
                    "</div>" ^
                    "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                      "<span style='color: var(--text-muted); font-weight: 500;'>Quilometragem</span>" ^
                      "<span style='color: var(--text-primary); font-weight: 700;'>" ^ vehicle.mileage ^ " km</span>" ^
                    "</div>" ^
                    "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                      "<span style='color: var(--text-muted); font-weight: 500;'>Cor</span>" ^
                      "<span style='color: var(--text-primary); font-weight: 700;'>" ^ vehicle.color ^ "</span>" ^
                    "</div>" ^
                    "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0;'>" ^
                      "<span style='color: var(--text-muted); font-weight: 500;'>Carroceria</span>" ^
                      "<span style='color: var(--text-primary); font-weight: 700;'>" ^ vehicle.body_style ^ "</span>" ^
                    "</div>" ^
                  "</div>" ^
                "</div>" ^
                
                "<div style='background: var(--bg-secondary); padding: 2rem; border-radius: 1rem;'>" ^
                  "<h3 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1.5rem; font-size: 1.2rem;'>🔍 Condições</h3>" ^
                  "<div style='display: grid; gap: 1rem;'>" ^
                    "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                      "<span style='color: var(--text-muted); font-weight: 500;'>Exterior</span>" ^
                      "<span style='color: var(--accent); font-weight: 700;'>" ^ vehicle.exterior_condition ^ "</span>" ^
                    "</div>" ^
                    "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                      "<span style='color: var(--text-muted); font-weight: 500;'>Interior</span>" ^
                      "<span style='color: var(--accent); font-weight: 700;'>" ^ vehicle.interior_condition ^ "</span>" ^
                    "</div>" ^
                    "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                      "<span style='color: var(--text-muted); font-weight: 500;'>Mecânica</span>" ^
                      "<span style='color: var(--accent); font-weight: 700;'>" ^ vehicle.mechanical_condition ^ "</span>" ^
                    "</div>" ^
                    "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0;'>" ^
                      "<span style='color: var(--text-muted); font-weight: 500;'>Proprietários</span>" ^
                      "<span style='color: var(--text-primary); font-weight: 700;'>" ^ string_of_int vehicle.previous_owners ^ "</span>" ^
                    "</div>" ^
                  "</div>" ^
                "</div>" ^
              "</div>" ^
            "</div>" ^
            
            "<!-- Equipment & Features -->" ^
            (if List.length vehicle.features > 0 then
              "<div style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 3rem; border-radius: 1rem; margin-bottom: 3rem;'>" ^
                "<h2 style='color: var(--text-primary); font-weight: 800; margin-bottom: 2rem; font-size: 1.75rem;'>⚙️ Equipamentos & Opcionais</h2>" ^
                "<div style='display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1rem;'>" ^
                  features_list ^
                "</div>" ^
              "</div>"
             else "") ^
            
            "<!-- Service History -->" ^
            (if List.length vehicle.service_history > 0 then
              "<div style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 3rem; border-radius: 1rem; margin-bottom: 3rem;'>" ^
                "<h2 style='color: var(--text-primary); font-weight: 800; margin-bottom: 2rem; font-size: 1.75rem;'>📋 Histórico de Manutenção</h2>" ^
                "<div style='max-width: 600px;'>" ^
                  service_timeline ^
                "</div>" ^
              "</div>"
             else "") ^
            
            "<!-- Inspection Report -->" ^
            (if vehicle.inspection_notes <> "" then
              "<div style='background: linear-gradient(135deg, var(--accent), var(--accent-hover)); color: white; padding: 3rem; border-radius: 1rem; margin-bottom: 3rem;'>" ^
                "<h2 style='font-weight: 800; margin-bottom: 1.5rem; font-size: 1.75rem;'>🔍 Relatório de Inspeção BusCars</h2>" ^
                "<p style='line-height: 1.8; font-size: 1.1rem; opacity: 0.95;'>" ^ vehicle.inspection_notes ^ "</p>" ^
                "<div style='margin-top: 2rem; padding-top: 2rem; border-top: 1px solid rgba(255,255,255,0.3); display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; font-size: 0.9rem;'>" ^
                  "<div>✓ <strong>127 pontos verificados</strong></div>" ^
                  "<div>✓ <strong>Histórico limpo</strong></div>" ^
                  "<div>✓ <strong>Documentação completa</strong></div>" ^
                  "<div>✓ <strong>Procedência garantida</strong></div>" ^
                "</div>" ^
              "</div>"
             else "") ^
          "</div>" ^
          
          "<!-- Right Sidebar -->" ^
          "<div style='position: sticky; top: 6rem; height: fit-content; max-height: calc(100vh - 8rem); overflow-y: auto;'>" ^
            "<!-- Price and Contact -->" ^
            "<div style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 2.5rem; border-radius: 1rem; margin-bottom: 2rem;'>" ^
              "<div style='text-align: center; margin-bottom: 2rem; padding: 2rem; background: var(--bg-secondary); border-radius: 1rem;'>" ^
                "<h2 style='color: var(--accent); font-size: 3rem; font-weight: 900; margin-bottom: 0.5rem;'>R$ " ^ vehicle.price ^ "</h2>" ^
                "<p style='color: var(--text-muted); font-size: 0.95rem; margin-bottom: 1rem;'>" ^ (if vehicle.condition = "new" then "Preço de lançamento" else "Preço à vista") ^ "</p>" ^
                (if vehicle.financing_available then
                  "<p style='color: var(--accent); font-size: 1rem; font-weight: 700;'>💳 Financiamento disponível em até 60x</p>"
                 else "") ^
              "</div>" ^
              
              "<!-- Seller Info -->" ^
              "<div style='background: var(--bg-secondary); padding: 2rem; border-radius: 1rem; margin-bottom: 2rem;'>" ^
                "<h3 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1.5rem; font-size: 1.2rem;'>👤 Vendedor Verificado</h3>" ^
                "<div style='margin-bottom: 1.5rem;'>" ^
                  "<p style='color: var(--text-primary); font-weight: 700; margin-bottom: 0.5rem; font-size: 1.1rem;'>" ^ vehicle.seller_name ^ "</p>" ^
                  "<p style='color: var(--text-muted); font-size: 0.95rem; margin-bottom: 0.25rem;'>" ^ vehicle.seller_phone ^ "</p>" ^
                  "<p style='color: var(--text-muted); font-size: 0.95rem;'>" ^ vehicle.seller_email ^ "</p>" ^
                  "<p style='color: var(--accent); font-size: 0.85rem; margin-top: 0.75rem; font-weight: 600;'>📍 " ^ vehicle.location_city ^ ", " ^ vehicle.location_state ^ "</p>" ^
                "</div>" ^
              "</div>" ^
              
              "<!-- Action Buttons -->" ^
              "<div style='display: flex; flex-direction: column; gap: 1rem;'>" ^
                "<button class='btn' style='width: 100%; padding: 1rem; font-size: 1.1rem; font-weight: 700;'>💬 Entrar em Contato</button>" ^
              "</div>" ^
            "</div>" ^
            
            "<!-- Vehicle Stats -->" ^
            "<div style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 2rem; border-radius: 1rem;'>" ^
              "<h3 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1.5rem; font-size: 1.2rem;'>📊 Estatísticas</h3>" ^
              "<div style='display: grid; gap: 1rem;'>" ^
                "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                  "<span style='color: var(--text-muted); font-weight: 500;'>Visualizações</span>" ^
                  "<span style='color: var(--accent); font-weight: 700;'>" ^ string_of_int (2500 + Random.int 1500) ^ "</span>" ^
                "</div>" ^
                "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                  "<span style='color: var(--text-muted); font-weight: 500;'>Interessados</span>" ^
                  "<span style='color: var(--accent); font-weight: 700;'>" ^ string_of_int (25 + Random.int 35) ^ "</span>" ^
                "</div>" ^
                "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                  "<span style='color: var(--text-muted); font-weight: 500;'>Favoritado</span>" ^
                  "<span style='color: var(--accent); font-weight: 700;'>" ^ string_of_int (8 + Random.int 15) ^ " vezes</span>" ^
                "</div>" ^
                "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0;'>" ^
                  "<span style='color: var(--text-muted); font-weight: 500;'>Publicado</span>" ^
                  "<span style='color: var(--text-primary); font-weight: 700;'>" ^ string_of_int (2 + Random.int 10) ^ " dias atrás</span>" ^
                "</div>" ^
              "</div>" ^
            "</div>" ^
          "</div>" ^
        "</div>" ^
      "</div>" ^
      
      "<!-- Working Slideshow JavaScript -->" ^
      "<script>" ^
        "const slideImages = [" ^ String.concat ", " (List.map (fun img -> "'" ^ img ^ "'") all_images) ^ "];" ^
      "</script>" ^
      {|<script>
let currentSlide = 0;
let touchStartX = 0;
let touchEndX = 0;

function changeSlide(index) {
  console.log('Changing to slide:', index);
  
  if (index < 0 || index >= slideImages.length) return;
  currentSlide = index;
  
  const mainImage = document.getElementById('main-slide-image');
  const counter = document.getElementById('slide-counter');
  
  if (mainImage && counter) {
    mainImage.src = slideImages[index];
    counter.textContent = (index + 1) + ' / ' + slideImages.length;
    
    // Update thumbnail styles
    document.querySelectorAll('.thumb-item img').forEach(function(thumb, i) {
      if (i === index) {
        thumb.style.border = '3px solid #10b981';
        thumb.style.opacity = '1';
      } else {
        thumb.style.border = '2px solid #e2e8f0';
        thumb.style.opacity = '0.7';
      }
    });
  }
}

function nextSlide() {
  const newIndex = (currentSlide + 1) % slideImages.length;
  changeSlide(newIndex);
}

function previousSlide() {
  const newIndex = currentSlide === 0 ? slideImages.length - 1 : currentSlide - 1;
  changeSlide(newIndex);
}

// Touch support for mobile
function touchStart(e) {
  touchStartX = e.changedTouches[0].screenX;
}

function touchEnd(e) {
  touchEndX = e.changedTouches[0].screenX;
  const swipeDistance = touchStartX - touchEndX;
  const minSwipeDistance = 50;
  
  if (Math.abs(swipeDistance) > minSwipeDistance) {
    if (swipeDistance > 0) {
      nextSlide();
    } else {
      previousSlide();
    }
  }
}

// Keyboard navigation
document.addEventListener('keydown', function(e) {
  if (e.key === 'ArrowRight') nextSlide();
  if (e.key === 'ArrowLeft') previousSlide();
});

// Initialize
document.addEventListener('DOMContentLoaded', function() {
  console.log('DOM loaded, initializing slideshow with', slideImages.length, 'images');
  if (slideImages.length > 0) {
    changeSlide(0);
  }
});
</script>|}
    )

(* Advertisement overlay with redirect to external car sites *)
let advertisement_with_redirect ~redirect_url ~source () =
  let platform_info = match source with
    | "webmotors" -> ("Webmotors", "Maior site de carros do Brasil", "#10b981")
    | "localiza" -> ("Localiza Seminovos", "Seminovos certificados", "#059669")
    | "icarros" -> ("iCarros", "Avaliação e comparação", "#374151")
    | "bringatrailer" -> ("Bring a Trailer", "Clássicos internacionais", "#dc2626")
    | _ -> ("Parceiro", "Plataforma de carros", "#374151")
  in
  
  base_template ~title:"BusCars - Redirecionando..."
    ~content:(
      "<div class='ad-overlay' id='ad-overlay'>" ^
        "<div class='ad-content' style='max-width: 90%; margin: 0 1rem;'>" ^
          "<div style='text-align: center; margin-bottom: 2rem;'>" ^
            "<img src='/logo-buscar.png' alt='BusCars' style='height: 60px; width: auto; margin-bottom: 1rem;'>" ^
            "<h2 style='color: var(--text-primary); margin-bottom: 1rem; font-size: clamp(1.5rem, 4vw, 2rem);'>🚗 Resultado Encontrado!</h2>" ^
            "<p style='color: var(--text-muted); margin-bottom: 1rem; font-size: clamp(0.9rem, 3vw, 1rem);'>Encontramos veículos correspondentes em nossos parceiros</p>" ^
          "</div>" ^
          
          "<div style='background: var(--bg-secondary); padding: 2rem; border-radius: 1rem; margin-bottom: 2rem; text-align: center;'>" ^
            "<div style='background: white; padding: 1.5rem; border-radius: 0.75rem; margin-bottom: 1.5rem; display: inline-block;'>" ^
              "<div style='background: " ^ (let (_, _, color) = platform_info in color) ^ "; color: white; padding: 1rem 2rem; border-radius: 0.5rem; font-weight: 600;'>" ^ (let (name, _, _) = platform_info in name) ^ "</div>" ^
            "</div>" ^
            "<p style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem;'>Redirecionando para " ^ (let (name, _, _) = platform_info in name) ^ "</p>" ^
            "<p style='color: var(--text-muted); font-size: 0.9rem;'>" ^ (let (_, desc, _) = platform_info in desc) ^ "</p>" ^
          "</div>" ^
          
          "<div style='text-align: center;'>" ^
            "<p style='color: var(--text-muted); margin-bottom: 1rem; font-size: clamp(0.9rem, 3vw, 1rem);'>Você será redirecionado em</p>" ^
            "<span id='countdown' style='font-size: clamp(2rem, 8vw, 3rem); color: var(--accent); font-weight: 800; display: block; margin-bottom: 1rem;'>5</span>" ^
            "<p style='color: var(--text-muted); font-size: clamp(0.8rem, 2.5vw, 0.9rem); margin-bottom: 2rem;'>segundos</p>" ^
            "<div style='display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap;'>" ^
              "<button onclick='continueNow()' style='background: var(--accent); color: white; border: none; padding: 0.75rem 2rem; border-radius: 0.5rem; font-weight: 600; cursor: pointer; font-size: 1rem; transition: background 0.2s; min-width: 150px;' onmouseover='this.style.background=\"var(--accent-hover)\"' onmouseout='this.style.background=\"var(--accent)\"'>Continuar Agora</button>" ^
              "<button onclick='closeAd()' style='background: var(--bg-secondary); color: var(--text-secondary); border: 1px solid var(--border-color); padding: 0.75rem 2rem; border-radius: 0.5rem; font-weight: 600; cursor: pointer; font-size: 1rem; transition: all 0.2s; min-width: 150px;' onmouseover='this.style.background=\"var(--border-color)\"' onmouseout='this.style.background=\"var(--bg-secondary)\"'>Pular</button>" ^
            "</div>" ^
          "</div>" ^
          
          "<p style='color: var(--text-muted); font-size: 0.8rem; text-align: center; margin-top: 2rem; opacity: 0.7;'>" ^
            "Esta página é patrocinada. BusCars recebe comissão por direcionamentos.<br>" ^
            "<span style='font-size: 0.7rem; margin-top: 0.5rem; display: block;'>Atalhos: Enter/Espaço = Continuar | Esc = Voltar</span>" ^
          "</p>" ^
        "</div>" ^
      "</div>" ^
      
      "<script>" ^
        "const redirectUrl = '" ^ redirect_url ^ "';" ^
      "</script>" ^
      {|<script>
let countdown = 5;
const countdownElement = document.getElementById('countdown');
let timer;

function startCountdown() {
  timer = setInterval(function() {
    countdown--;
    countdownElement.textContent = countdown;
    
    if (countdown <= 0) {
      clearInterval(timer);
      redirect();
    }
  }, 1000);
}

function redirect() {
  // Direct full-page redirect - no popups, works in all browsers
  window.location.href = redirectUrl;
}

function closeAd() {
  if (timer) clearInterval(timer);
  window.history.back();
}

function continueNow() {
  if (timer) clearInterval(timer);
  redirect();
}

// Handle page visibility changes (user switched tabs)
document.addEventListener('visibilitychange', function() {
  if (document.hidden) {
    if (timer) clearInterval(timer);
  } else {
    if (countdown > 0) {
      startCountdown();
    }
  }
});

document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') closeAd();
  if (e.key === 'Enter' || e.key === ' ') continueNow();
});

// Start countdown when page loads
document.addEventListener('DOMContentLoaded', function() {
  startCountdown();
});
</script>|}
    )

(* Modern add vehicle form template *)
let add_vehicle_template ?error () =
  let error_msg = match error with
    | Some msg -> "<div class='error'>" ^ msg ^ "</div>"
    | None -> ""
  in
  
  base_template ~title:"BusCars - Adicionar Veículo" ~content:(
      "<div class='container'>" ^
        "<div class='form-container' style='max-width: 900px;'>" ^
          "<div style='text-align: center; margin-bottom: 2rem;'>" ^
            "<h2 style='color: var(--text-primary); font-weight: 700; margin-bottom: 0.5rem;'>Criar Novo Anúncio</h2>" ^
            "<p style='color: var(--text-muted);'>Preencha as informações do seu veículo</p>" ^
          "</div>" ^
          error_msg ^
          
          "<form method='post' action='/dashboard/add-vehicle'>" ^
            "<div style='display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='brand'>Marca</label>" ^
                "<select name='brand' id='brand' required>" ^
                  "<option value=''>Selecione uma marca</option>" ^
                  "<option value='Porsche'>Porsche</option>" ^
                  "<option value='Toyota'>Toyota</option>" ^
                  "<option value='BMW'>BMW</option>" ^
                "</select>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='model'>Modelo</label>" ^
                "<input type='text' name='model' id='model' required placeholder='Ex: 911 Carrera'>" ^
              "</div>" ^
            "</div>" ^
            
            "<div style='display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem; margin-bottom: 1rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='year'>Ano</label>" ^
                "<input type='number' name='year' id='year' required min='1980' max='2024'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='price'>Preço (R$)</label>" ^
                "<input type='text' name='price' id='price' required placeholder='Ex: 150.000'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='mileage'>Quilometragem</label>" ^
                "<input type='text' name='mileage' id='mileage' required placeholder='Ex: 25.000'>" ^
              "</div>" ^
            "</div>" ^
            
            "<div style='display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1rem; margin-bottom: 1rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='fuel_type'>Combustível</label>" ^
                "<select name='fuel_type' id='fuel_type' required>" ^
                  "<option value=''>Selecione</option>" ^
                  "<option value='Gasolina'>Gasolina</option>" ^
                  "<option value='Flex'>Flex</option>" ^
                  "<option value='Diesel'>Diesel</option>" ^
                  "<option value='Elétrico'>Elétrico</option>" ^
                  "<option value='Híbrido'>Híbrido</option>" ^
                "</select>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='color'>Cor</label>" ^
                "<input type='text' name='color' id='color' required placeholder='Ex: Branco'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='transmission'>Transmissão</label>" ^
                "<select name='transmission' id='transmission' required>" ^
                  "<option value=''>Selecione</option>" ^
                  "<option value='Manual'>Manual</option>" ^
                  "<option value='Automática'>Automática</option>" ^
                  "<option value='CVT'>CVT</option>" ^
                "</select>" ^
              "</div>" ^
            "</div>" ^
            
            "<div class='form-group' style='margin-bottom: 1rem;'>" ^
              "<label for='image'>URL da Imagem</label>" ^
              "<input type='url' name='image' id='image' required placeholder='https://exemplo.com/imagem.jpg'>" ^
            "</div>" ^
            
            "<div class='form-group' style='margin-bottom: 1rem;'>" ^
              "<label for='description'>Descrição</label>" ^
              "<textarea name='description' id='description' rows='6' required placeholder='Descreva o veículo detalhadamente...' style='width: 100%; padding: 0.75rem; border: 2px solid #e1e5e9; border-radius: 8px; font-size: 1rem; resize: vertical;'></textarea>" ^
            "</div>" ^
            
            "<div style='display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 2rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='seller_name'>Nome do Vendedor</label>" ^
                "<input type='text' name='seller_name' id='seller_name' required placeholder='Seu nome'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='seller_phone'>Telefone</label>" ^
                "<input type='tel' name='seller_phone' id='seller_phone' required placeholder='(11) 99999-9999'>" ^
              "</div>" ^
            "</div>" ^
            
            "<div style='display: flex; gap: 1rem;'>" ^
              "<button type='submit' class='btn'>Adicionar Veículo</button>" ^
              "<a href='/dashboard' class='btn' style='background: #6c757d; text-decoration: none; display: inline-block;'>Cancelar</a>" ^
            "</div>" ^
          "</form>" ^
        "</div>" ^
      "</div>"
    )
