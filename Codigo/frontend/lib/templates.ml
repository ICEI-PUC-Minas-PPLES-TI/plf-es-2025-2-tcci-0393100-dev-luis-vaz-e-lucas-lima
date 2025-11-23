(* Template definitions using string-based HTML *)

(* Helper function to get WhatsApp number from environment *)
let get_whatsapp_number () =
  try Sys.getenv "WHATSAPP_NUMBER"
  with Not_found -> "+5533988154380"

(* Helper function to URL encode a string *)
let url_encode s =
  let buffer = Buffer.create (String.length s * 3) in
  String.iter (function
    | 'A'..'Z' | 'a'..'z' | '0'..'9' | '-' | '_' | '.' | '~' as c ->
        Buffer.add_char buffer c
    | c ->
        let code = Char.code c in
        Buffer.add_string buffer (Printf.sprintf "%%%02X" code)
  ) s;
  Buffer.contents buffer

(* Helper function to generate WhatsApp link *)
let whatsapp_link ?message () =
  let number = get_whatsapp_number () in
  let encoded_number = url_encode number in
  match message with
  | Some msg ->
      let encoded_msg = url_encode msg in
      "https://wa.me/" ^ encoded_number ^ "?text=" ^ encoded_msg
  | None ->
      "https://wa.me/" ^ encoded_number

(* Helper function to normalize phone number for WhatsApp *)
let normalize_phone_for_whatsapp phone =
  (* Remove all non-numeric characters *)
  let digits_only = String.fold_left (fun acc c ->
    if c >= '0' && c <= '9' then acc ^ String.make 1 c else acc
  ) "" phone in
  (* If empty, return empty *)
  if digits_only = "" then ""
  else
    (* If doesn't start with country code, assume Brazil (55) *)
    if String.length digits_only >= 10 && String.length digits_only <= 11 then
      "55" ^ digits_only
    else if String.length digits_only >= 12 then
      digits_only
    else
      "55" ^ digits_only

let normalize_city_name city =
  (* Normalize city name to Title Case: first letter of each word uppercase, rest lowercase *)
  let words = String.split_on_char ' ' city in
  let capitalize_word word =
    if String.length word = 0 then word
    else
      let first = String.uppercase_ascii (String.sub word 0 1) in
      let rest = 
        if String.length word > 1 then
          String.lowercase_ascii (String.sub word 1 (String.length word - 1))
        else
          ""
      in
      first ^ rest
  in
  String.concat " " (List.map capitalize_word words)

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
  
  html, body {
    height: 100%;
    min-height: 100vh;
  }
  
  html {
    transition: none !important;
  }
  
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    line-height: 1.6;
    color: var(--text-primary);
    background: var(--bg-primary);
    transition: none !important;
    display: flex;
    flex-direction: column;
  }
  
  .header {
    background: var(--bg-card);
    border-bottom: 1px solid var(--border-color);
    padding: 1rem 0;
    position: sticky;
    top: 0;
    z-index: 1000;
    backdrop-filter: blur(10px);
  }
  
  .header-content {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 1.5rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
    position: relative;
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
    position: relative;
  }
  
  .header-actions nav {
    position: relative;
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
    padding: 1.5rem 0;
    margin-top: 0;
    width: 100%;
    position: relative;
  }
  
  .support-message {
    flex-shrink: 0;
  }
  
  .support-message a:hover {
    text-decoration: underline;
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
  
  .login-container {
    max-width: 450px;
    margin: 2rem auto;
    background: var(--bg-card);
    border: 1px solid var(--border-color);
    border-radius: 1rem;
    padding: 2.5rem;
    box-shadow: var(--shadow);
  }
  
  .mobile-menu-toggle {
    display: none;
    background: none;
    border: none;
    color: var(--text-primary);
    font-size: 1.5rem;
    cursor: pointer;
  }
  
  .vehicle-detail-header {
    margin-bottom: 2rem;
  }
  
  .vehicle-header-content {
    display: flex;
    justify-content: space-between;
    align-items: start;
    margin-bottom: 2rem;
    flex-wrap: wrap;
    gap: 1.5rem;
  }
  
  .vehicle-header-info {
    flex: 1;
    min-width: 300px;
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
  
  .vehicle-price-container {
    text-align: right;
    flex-shrink: 0;
  }
  
  .vehicle-price-card {
    background: linear-gradient(135deg, var(--accent), var(--accent-hover));
    color: white;
    padding: 2rem;
    border-radius: 1.5rem;
    box-shadow: 0 8px 16px rgba(16, 185, 129, 0.3);
    min-width: 250px;
    display: inline-block;
  }
  
  .price-label {
    font-size: 0.875rem;
    opacity: 0.9;
    margin-bottom: 0.5rem;
  }
  
  .price-value {
    font-size: 2.5rem;
    font-weight: 900;
    line-height: 1;
    margin-bottom: 0.5rem;
    word-break: break-word;
  }
  
  .price-subtitle {
    font-size: 0.875rem;
    opacity: 0.9;
  }
  
  /* Mobile Responsive - Improved */
  @media (max-width: 768px) {
    body {
      display: block !important;
    }
    
    main {
      flex: none !important;
      min-height: auto !important;
    }
    
    .footer {
      margin-top: 4rem !important;
      position: relative !important;
    }
    
    .container {
      padding: 0 1rem;
    }
    
    .header-content {
      flex-wrap: nowrap;
      gap: 0.5rem;
      padding: 0 1rem;
      justify-content: space-between;
      align-items: center;
    }
    
    .header-actions {
      width: auto;
      justify-content: flex-end;
      flex-wrap: nowrap;
      gap: 0.5rem;
      flex: 0 0 auto;
    }
    
    .logo-container {
      position: absolute !important;
      left: 50% !important;
      transform: translateX(-50%) !important;
      order: 2 !important;
    }
    
    .theme-toggle {
      order: 1 !important;
      flex: 0 0 auto;
      margin-right: auto;
    }
    
    .header-actions nav {
      position: static;
      display: block !important;
      width: 100%;
    }
    
    .nav-menu {
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      width: 100%;
      max-height: 0;
      overflow: hidden;
      background: var(--bg-card);
      border-bottom: 1px solid var(--border-color);
      flex-direction: column;
      padding: 0;
      margin: 0;
      box-shadow: var(--shadow-lg);
      z-index: 999;
      transition: max-height 0.3s ease-out, padding 0.3s ease-out;
    }
    
    .nav-menu.active {
      display: flex !important;
      max-height: 500px;
      padding: 1rem;
      padding-top: calc(70px + 1rem);
      gap: 0.5rem;
    }
    
    .nav-menu.active li {
      width: 100%;
      list-style: none;
      margin: 0;
      padding: 0;
    }
    
    .nav-menu.active a {
      display: block !important;
      width: 100%;
      min-height: 48px;
      padding: 1rem 1.5rem;
      border-radius: 0.5rem;
      pointer-events: auto !important;
      cursor: pointer !important;
      position: relative;
      z-index: 1002 !important;
      text-decoration: none;
      -webkit-tap-highlight-color: rgba(0, 0, 0, 0.1);
      user-select: none;
      -webkit-user-select: none;
      -moz-user-select: none;
      -ms-user-select: none;
      touch-action: manipulation;
      font-size: 1rem;
      font-weight: 500;
      color: var(--text-primary);
      background: var(--bg-secondary);
      border: 1px solid var(--border-color);
      transition: all 0.2s ease;
    }
    
    .nav-menu.active a:hover,
    .nav-menu.active a:active,
    .nav-menu.active a:focus {
      background: var(--bg-hover);
      outline: none;
      transform: scale(1.02);
    }
    
    /* Ensure nav menu doesn't block clicks */
    .nav-menu.active {
      pointer-events: auto !important;
    }
    
    .nav-menu.active li {
      pointer-events: auto !important;
    }
    
    .mobile-menu-toggle {
      display: block !important;
      background: none;
      border: 1px solid var(--border-color);
      padding: 0.5rem;
      border-radius: 0.5rem;
      cursor: pointer;
      color: var(--text-primary);
      font-size: 1.25rem;
      z-index: 999;
      position: relative;
    }
    
    .logo-image {
      height: 50px;
    }
    
    .header-actions .btn-outline {
      display: none;
    }
    
    .hero {
      padding: 2rem 0;
    }
    
    .hero h1 {
      font-size: clamp(1.75rem, 5vw, 2.5rem);
    }
    
    .hero p {
      font-size: clamp(0.95rem, 3vw, 1.1rem);
    }
    
    .search-section {
      padding: 1.5rem !important;
      margin: -2rem auto 2rem !important;
    }
    
    .search-form {
      grid-template-columns: 1fr !important;
      gap: 1rem !important;
    }
    
    /* Home page filters mobile */
    .home-filters-grid,
    #home-search-form > div,
    #home-advanced-form > div {
      grid-template-columns: 1fr !important;
      gap: 1rem !important;
      justify-items: stretch !important;
    }
    
    .home-filters-grid .form-group {
      max-width: 100% !important;
      width: 100% !important;
    }
    
    .home-filters-grid .btn {
      width: 100% !important;
      margin-top: 0.5rem;
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
      gap: 1.5rem !important;
    }
    
    .vehicle-specs {
      grid-template-columns: 1fr 1fr;
      gap: 0.75rem;
    }
    
    .dashboard-header {
      flex-direction: column;
      align-items: flex-start;
      gap: 1rem;
    }
    
    .stats-grid {
      grid-template-columns: 1fr 1fr;
      gap: 1rem;
    }
    
    /* Vehicle detail header mobile */
    .vehicle-header-content {
      flex-direction: column !important;
      align-items: stretch !important;
    }
    
    .vehicle-header-info {
      min-width: auto !important;
      width: 100%;
      margin-bottom: 1.5rem;
    }
    
    .vehicle-price-container {
      text-align: center !important;
      width: 100% !important;
      flex-shrink: 1 !important;
    }
    
    .vehicle-price-card {
      min-width: auto !important;
      width: 100% !important;
      padding: 1.5rem !important;
      margin: 0 auto;
      display: block !important;
    }
    
    .price-value {
      font-size: 2rem !important;
      line-height: 1.1 !important;
    }
    
    .price-label,
    .price-subtitle {
      font-size: 0.8rem !important;
    }
    
    /* Mobile slideshow improvements */
    .slideshow-container {
      height: 250px !important;
    }
    
    .thumbnail-gallery {
      display: grid !important;
      grid-template-columns: repeat(4, 1fr) !important;
      gap: 0.5rem !important;
    }
    
    .thumb-item img {
      width: 100% !important;
      height: 50px !important;
      object-fit: cover;
    }
    
    .slide-controls button {
      width: 36px !important;
      height: 36px !important;
      font-size: 1rem !important;
    }
    
    /* Mobile typography */
    h1 {
      font-size: 1.75rem !important;
    }
    
    h2 {
      font-size: 1.5rem !important;
    }
    
    h3 {
      font-size: 1.25rem !important;
    }
    
    .vehicle-title {
      font-size: 1.1rem !important;
    }
    
    .vehicle-price {
      font-size: 1.3rem !important;
    }
    
    /* Mobile spacing */
    .detail-info {
      padding: 1.5rem 1rem !important;
    }
    
    /* Mobile sidebar - make it not sticky */
    .vehicle-detail-grid > div:last-child {
      position: static !important;
      margin-top: 1.5rem;
    }
    
    /* Mobile buttons */
    .btn {
      padding: 0.875rem 1.25rem !important;
      font-size: 0.95rem !important;
      width: 100%;
      text-align: center;
    }
    
    .btn-outline {
      width: auto;
    }
    
    /* Mobile forms */
    .form-container {
      margin: 1rem !important;
      padding: 1.5rem !important;
    }
    
    .form-section {
      padding: 1.5rem !important;
      margin-bottom: 1.5rem !important;
    }
    
    /* Mobile listing layout */
    .listing-layout {
      grid-template-columns: 1fr !important;
      gap: 2rem !important;
      display: flex !important;
      flex-direction: column !important;
    }
    
    .listing-layout > div:first-child {
      position: static !important;
      order: 1 !important;
      margin-top: 0 !important;
      margin-bottom: 0 !important;
    }
    
    .listing-layout > div:last-child {
      order: 2 !important;
    }
    
    /* Mobile vehicle cards - completely restructured for mobile */
    .vehicle-card-mobile {
      height: auto !important;
      margin-bottom: 2rem !important;
      border-radius: 1rem !important;
      overflow: hidden !important;
    }
    
    .vehicle-card-mobile > div {
      display: flex !important;
      flex-direction: column !important;
      grid-template-columns: 1fr !important;
      height: auto !important;
      min-height: auto !important;
    }
    
    .vehicle-card-mobile > div > div:first-child {
      height: 220px !important;
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
      background: var(--bg-secondary) !important;
      border-top: 1px solid var(--border-color) !important;
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
      margin-bottom: 0 !important;
      width: 100% !important;
    }
    
    /* Mobile filters section */
    .filters-sidebar {
      position: static !important;
      order: 2;
      margin-top: 2rem !important;
    }
    
    .filters-container {
      padding: 1.5rem !important;
      margin-bottom: 2rem !important;
    }
    
    .filters-container .form-group {
      margin-bottom: 1.25rem !important;
    }
    
    .filters-container h3 {
      font-size: 1.25rem !important;
      margin-bottom: 1.25rem !important;
    }
    
    /* Mobile container padding */
    .container {
      padding: 0 1rem !important;
    }
    
    /* Mobile header spacing */
    .listing-header {
      margin: 1.5rem 0 !important;
      padding: 0 !important;
    }
    
    .listing-header h1 {
      font-size: 1.75rem !important;
      margin-bottom: 0.75rem !important;
    }
    
    .listing-header p {
      font-size: 0.95rem !important;
      margin-bottom: 0.5rem !important;
    }
    
    /* Mobile vehicle listing area */
    .vehicles-list {
      padding: 0 !important;
      margin: 0 !important;
    }
    
    .vehicle-grid {
      grid-template-columns: 1fr !important;
      gap: 1.5rem !important;
    }
    
    .vehicles-list > div:first-child {
      margin-bottom: 1.5rem !important;
      flex-direction: column !important;
      gap: 1rem !important;
      align-items: flex-start !important;
    }
    
    /* Mobile vehicle card improvements */
    .vehicle-card {
      margin-bottom: 0 !important;
    }
    
    .vehicle-card .vehicle-info {
      padding: 1.5rem !important;
    }
    
    .vehicle-card .vehicle-title {
      font-size: 1.25rem !important;
      margin-bottom: 0.5rem !important;
    }
    
    .vehicle-card .vehicle-price {
      font-size: 1.5rem !important;
      margin-bottom: 0.75rem !important;
    }
    
    .vehicle-card .vehicle-specs {
      grid-template-columns: repeat(2, 1fr) !important;
      gap: 0.75rem !important;
      margin: 1rem 0 !important;
    }
    
    .vehicle-card .spec-item {
      padding: 0.75rem !important;
    }
    
    .vehicle-card .spec-label {
      font-size: 0.75rem !important;
    }
    
    .vehicle-card .spec-value {
      font-size: 0.875rem !important;
    }
    
    .vehicle-card .btn {
      padding: 0.875rem !important;
      font-size: 0.95rem !important;
    }
    
    /* Mobile pagination */
    .pagination-mobile {
      flex-direction: column !important;
      gap: 1.5rem !important;
      padding: 1.5rem !important;
    }
    
    /* Home page filters - mobile responsive */
    #home-search-form > div[style*='grid-template-columns'] {
      grid-template-columns: 1fr !important;
      gap: 1.5rem !important;
    }
    
    #home-search-form .form-group {
      max-width: 100% !important;
      width: 100% !important;
    }
    
    #home-search-form .btn {
      width: 100% !important;
      margin-top: 0.5rem;
    }
    
    /* Advanced filters - mobile responsive */
    .advanced-filters-grid,
    #advanced-filters-section > form > div[style*='grid-template-columns'] {
      grid-template-columns: 1fr !important;
      gap: 1rem !important;
    }
  }
  
  @media (max-width: 480px) {
    .container {
      padding: 0 0.75rem !important;
    }
    
    .header-content {
      padding: 0 0.75rem !important;
    }
    
    .logo-image {
      height: 45px !important;
    }
    
    .hero {
      padding: 1.5rem 0 !important;
    }
    
    .hero h1 {
      font-size: clamp(1.5rem, 6vw, 2rem) !important;
      margin-bottom: 0.75rem !important;
    }
    
    .hero p {
      font-size: clamp(0.9rem, 3vw, 1rem) !important;
      margin-bottom: 1rem !important;
    }
    
    .search-section {
      margin: -1.5rem auto 1.5rem !important;
      padding: 1.25rem !important;
      border-radius: 0.75rem !important;
    }
    
    .form-group label {
      font-size: 0.875rem !important;
    }
    
    .form-group select,
    .form-group input {
      padding: 0.75rem !important;
      font-size: 0.9rem !important;
    }
    
    .btn {
      padding: 0.75rem 1rem !important;
      font-size: 0.9rem !important;
    }
    
    .vehicle-card-mobile > div > div:first-child {
      height: 180px !important;
    }
    
    .slideshow-container {
      height: 220px !important;
    }
    
    .thumbnail-gallery {
      grid-template-columns: repeat(3, 1fr) !important;
    }
    
    .stats-grid {
      grid-template-columns: 1fr !important;
    }
    
    .form-section {
      padding: 1.25rem !important;
    }
    
    .form-section-title {
      font-size: 1.1rem !important;
    }
    
    /* Dashboard mobile improvements */
    .dashboard-tabs {
      gap: 0.75rem !important;
      padding-bottom: 0.5rem;
    }
    
    .tab-button {
      font-size: 0.875rem !important;
      padding: 0.75rem 1rem !important;
      white-space: nowrap;
      flex-shrink: 0;
    }
    
    .dashboard-header {
      flex-direction: column !important;
      align-items: flex-start !important;
      gap: 1rem !important;
    }
    
    .dashboard-header > div:last-child {
      width: 100%;
    }
    
    .dashboard-header .btn {
      width: 100%;
    }
    
    /* Login/Register forms mobile */
    .login-container {
      padding: 1.5rem !important;
      margin: 1rem auto !important;
      max-width: 100% !important;
    }
    
    .login-container h2 {
      font-size: 1.5rem !important;
    }
    
    .login-container img {
      height: 50px !important;
    }
    
    /* All grids with repeat(auto-fit) - mobile */
    [style*='grid-template-columns: repeat(auto-fit'] {
      grid-template-columns: 1fr !important;
    }
    
    /* Platform cards mobile */
    .features-grid,
    .platforms-grid,
    [style*='grid-template-columns: repeat(auto-fit, minmax(250px'] {
      grid-template-columns: 1fr !important;
      gap: 1.5rem !important;
    }
    
    [style*='grid-template-columns: repeat(auto-fit, minmax(200px'] {
      grid-template-columns: 1fr !important;
      gap: 1rem !important;
    }
    
    [style*='grid-template-columns: repeat(auto-fit, minmax(300px'] {
      grid-template-columns: 1fr !important;
      gap: 1.5rem !important;
    }
    
    [style*='grid-template-columns: repeat(auto-fit, minmax(280px'] {
      grid-template-columns: 1fr !important;
      gap: 1rem !important;
    }
    
    /* Dashboard filters mobile */
    .dashboard-filters-header {
      flex-direction: column !important;
      align-items: flex-start !important;
    }
    
    #dashboard-vehicle-filters {
      grid-template-columns: 1fr !important;
      gap: 0.75rem !important;
    }
    
    #dashboard-vehicle-filters .form-group {
      width: 100%;
    }
    
    /* Home page filters - extra small mobile */
    #home-search-form > div[style*='grid-template-columns'] {
      gap: 1.25rem !important;
    }
    
    #home-search-form .form-group label {
      font-size: 0.875rem !important;
      margin-bottom: 0.5rem !important;
    }
    
    #home-search-form select,
    #home-search-form input {
      padding: 0.75rem !important;
      font-size: 0.9rem !important;
    }
    
    #home-search-form .btn {
      padding: 0.75rem 1.5rem !important;
      font-size: 0.95rem !important;
    }
    
    /* Advanced filters - extra small mobile */
    #advanced-filters-section {
      padding: 1.25rem !important;
    }
    
    #advanced-filters-section > form > div[style*='grid-template-columns'] {
      gap: 1.25rem !important;
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

(* Helper function to format price based on source *)
let format_price_display price_str source =
  let cleaned = String.trim price_str in
  if cleaned = "" then
    "R$ 0,00"
  else
    (* For BusCars source, always format from scratch *)
    if source = "buscar" then
      (* BusCars: format from scratch - remove R$ prefix if present *)
      let cleaned_upper = String.uppercase_ascii cleaned in
      let has_rs_prefix = String.length cleaned >= 2 && String.sub cleaned_upper 0 2 = "R$" in
      let without_prefix = 
        if has_rs_prefix then
          let rest = String.sub cleaned 2 (String.length cleaned - 2) in
          String.trim rest
        else
    cleaned
      in
      
      (* Extract all digits *)
      let digits_only = Str.global_replace (Str.regexp "[^0-9]") "" without_prefix in
      if digits_only = "" then
        "R$ 0,00"
      else
        (* Convert to integer *)
        let price_int = try int_of_string digits_only with _ -> 0 in
        (* Format with thousand separators (Brazilian format: 1.234.567,00) *)
        let formatted = 
          let rec format_number n =
            if n < 1000 then
              string_of_int n
            else
              let remainder = n mod 1000 in
              let quotient = n / 1000 in
              let remainder_str = 
                if remainder < 10 then "00" ^ string_of_int remainder
                else if remainder < 100 then "0" ^ string_of_int remainder
                else string_of_int remainder
              in
              let prefix = format_number quotient in
              prefix ^ "." ^ remainder_str
        in
        format_number price_int
      in
      "R$ " ^ formatted ^ ",00"
    else if source = "localiza" then
      (* Localiza: format with thousand separators if missing *)
      (* Remove R$ prefix if present *)
      let cleaned_upper = String.uppercase_ascii cleaned in
      let has_rs_prefix = String.length cleaned >= 2 && String.sub cleaned_upper 0 2 = "R$" in
      let without_prefix = 
        if has_rs_prefix then
          let rest = String.sub cleaned 2 (String.length cleaned - 2) in
          String.trim rest
        else
          cleaned
      in
      (* Check if it has comma (centavos) *)
      let has_comma = String.contains without_prefix ',' in
      if has_comma then
        (* Split by comma to separate integer part from cents *)
        let parts = String.split_on_char ',' without_prefix in
        let integer_part = List.hd parts in
        let cents_part = if List.length parts > 1 then List.nth parts 1 else "00" in
        (* Check if integer part needs formatting (no dots) *)
        let has_dots = String.contains integer_part '.' in
        if has_dots then
          (* Already has separators, just add R$ prefix if missing *)
          if has_rs_prefix then cleaned else "R$ " ^ cleaned
        else
          (* Format integer part with thousand separators *)
          let digits_only = Str.global_replace (Str.regexp "[^0-9]") "" integer_part in
          if digits_only = "" then
            "R$ 0," ^ cents_part
          else
            let price_int = try int_of_string digits_only with _ -> 0 in
            let rec format_number n =
              if n < 1000 then
                string_of_int n
              else
                let remainder = n mod 1000 in
                let quotient = n / 1000 in
                let remainder_str = 
                  if remainder < 10 then "00" ^ string_of_int remainder
                  else if remainder < 100 then "0" ^ string_of_int remainder
                  else string_of_int remainder
                in
                let prefix = format_number quotient in
                prefix ^ "." ^ remainder_str
            in
            "R$ " ^ (format_number price_int) ^ "," ^ cents_part
      else
        (* No comma, assume integer price - format it *)
        let digits_only = Str.global_replace (Str.regexp "[^0-9]") "" without_prefix in
        if digits_only = "" then
          "R$ 0,00"
        else
          let price_int = try int_of_string digits_only with _ -> 0 in
          let rec format_number n =
            if n < 1000 then
              string_of_int n
            else
              let remainder = n mod 1000 in
              let quotient = n / 1000 in
              let remainder_str = 
                if remainder < 10 then "00" ^ string_of_int remainder
                else if remainder < 100 then "0" ^ string_of_int remainder
                else string_of_int remainder
              in
              let prefix = format_number quotient in
              prefix ^ "." ^ remainder_str
          in
          "R$ " ^ (format_number price_int) ^ ",00"
    else
      (* Other sources: preserve original format exactly as stored *)
      (* Only add R$ prefix if missing, but don't modify the format *)
      let cleaned_upper = String.uppercase_ascii cleaned in
      let has_rs_prefix = String.length cleaned >= 2 && String.sub cleaned_upper 0 2 = "R$" in
      
      if has_rs_prefix then
        (* Already has R$ prefix, return as is *)
        cleaned
      else
        (* Add R$ prefix if missing, but preserve the rest exactly *)
    "R$ " ^ cleaned

let format_color color_str =
  let trimmed = String.trim color_str in
  if trimmed = "" then ""
  else
    (* Split by space and take first word *)
    let words = String.split_on_char ' ' trimmed in
    let first_word = if List.length words > 0 then List.hd words else trimmed in
    (* Convert to Title Case *)
    if String.length first_word = 0 then ""
    else
      let first_char = String.sub first_word 0 1 in
      let rest = if String.length first_word > 1 then String.sub first_word 1 (String.length first_word - 1) else "" in
      (String.uppercase_ascii first_char) ^ (String.lowercase_ascii rest)

let normalize_fuel_type fuel_str =
  let lower = String.lowercase_ascii (String.trim fuel_str) in
  (* Check for Flex variations: GASOLINA/ETANOL, ÁLC/GASOL, etc. *)
  if String.contains lower '/' || String.contains lower '\\' then
    (* Check if it contains both gasolina and etanol/alcohol indicators *)
    let has_gasolina = String.contains lower 'g' && String.contains lower 'a' && 
                       String.contains lower 's' && String.contains lower 'o' && 
                       String.contains lower 'l' in
    let has_etanol = (String.contains lower 'e' && String.contains lower 't' && 
                      String.contains lower 'a' && String.contains lower 'n' && 
                      String.contains lower 'o') in
    let has_alcool = (String.contains lower 'a' && String.contains lower 'l' && 
                      String.contains lower 'c') in
    if has_gasolina && (has_etanol || has_alcool) then
      "Flex"
    else
      fuel_str
  else
    fuel_str

let format_date date_str =
  if date_str = "" then "Não informado"
  else
    (* Parse ISO date string (e.g., "2024-11-25T15:30:00Z" or "2024-11-25 15:30:00") *)
    try
      let date_part = 
        if String.contains date_str 'T' then
          String.sub date_str 0 (String.index date_str 'T')
        else if String.contains date_str ' ' then
          String.sub date_str 0 (String.index date_str ' ')
        else
          date_str
      in
      (* Format: YYYY-MM-DD -> DD/MM/YYYY *)
      match String.split_on_char '-' date_part with
      | [year; month; day] -> day ^ "/" ^ month ^ "/" ^ year
      | _ -> date_str
    with _ -> date_str

(* Base HTML template with dark/light mode *)
let base_template ~(user:Types.user option) ~title ~content = 
  "<!DOCTYPE html>" ^
  "<script>(function(){var t=localStorage.getItem('theme')||(document.cookie.match(/theme=([^;]+)/)?.[1])||'light';var html=document.documentElement;html.setAttribute('data-theme',t);if(t==='dark'){html.style.backgroundColor='#0f172a';html.style.color='#f1f5f9';document.body&&(document.body.style.backgroundColor='#0f172a');document.body&&(document.body.style.color='#f1f5f9');}else{html.style.backgroundColor='#ffffff';html.style.color='#1a202c';document.body&&(document.body.style.backgroundColor='#ffffff');document.body&&(document.body.style.color='#1a202c');}})();</script>" ^
  "<html lang='pt-BR'>" ^
  "<head>" ^
    "<meta charset='UTF-8'>" ^
    "<meta name='viewport' content='width=device-width, initial-scale=1.0'>" ^
    "<title>" ^ title ^ "</title>" ^
    "<link rel='icon' type='image/png' href='/favicon.ico'>" ^
    "<style id='theme-prevent-flash'>html{background-color:#0f172a !important;color:#f1f5f9 !important;}html[data-theme='light']{background-color:#ffffff !important;color:#1a202c !important;}body{background-color:inherit !important;color:inherit !important;opacity:0;transition:none;}</style>" ^
    common_styles ^
    "<script>(function(){var t=localStorage.getItem('theme')||(document.cookie.match(/theme=([^;]+)/)?.[1])||'light';var html=document.documentElement;html.setAttribute('data-theme',t);if(t==='dark'){html.style.setProperty('background-color','#0f172a','important');html.style.setProperty('color','#f1f5f9','important');}else{html.style.setProperty('background-color','#ffffff','important');html.style.setProperty('color','#1a202c','important');}document.addEventListener('DOMContentLoaded',function(){var body=document.body;if(body){body.style.setProperty('background-color',t==='dark'?'#0f172a':'#ffffff','important');body.style.setProperty('color',t==='dark'?'#f1f5f9':'#1a202c','important');setTimeout(function(){body.style.opacity='1';var flashStyle=document.getElementById('theme-prevent-flash');if(flashStyle){flashStyle.remove();}},5);}});})();</script>" ^
  "</head>" ^
  "<body>" ^
    "<header class='header'>" ^
      "<div class='header-content'>" ^
        "<button class='theme-toggle' id='theme-button' aria-label='Alternar tema' style='order: 1;'>" ^
          "<span id='theme-icon'>🌙</span>" ^
        "</button>" ^
        "<a href='/' class='logo-container' style='order: 2; position: absolute; left: 50%; transform: translateX(-50%);'>" ^
          "<img src='/logo-buscar.png' alt='BusCars' class='logo-image'>" ^
        "</a>" ^
        "<div class='header-actions' style='order: 3;'>" ^
          "<nav>" ^
            "<ul class='nav-menu'>" ^
              "<li><a href='/vehicles'>Veículos</a></li>" ^
              (match user with
               | Some _ ->
                   "<li><a href='/fipe-consult'>📊 Consulta FIPE</a></li>" ^
                   (if (match user with Some u -> u.is_admin | None -> false) then "<li><a href='/dashboard' style='color: var(--accent);'>👑 Admin</a></li>" else "<li><a href='/dashboard'>Dashboard</a></li>")
               | None ->
                   "<li><a href='/login' style='background: var(--accent); color: white; padding: 0.5rem 1rem; border-radius: 0.5rem;'>Entrar</a></li>") ^
            "</ul>" ^
          "</nav>" ^
          (match user with
           | Some _ ->
               "<a href='/logout' class='btn-outline btn' style='padding: 0.5rem 1rem; margin-right: 0.5rem;'>Sair</a>"
           | None -> "") ^
          "<button class='mobile-menu-toggle' onclick='toggleMobileMenu()'>☰</button>" ^
        "</div>" ^
      "</div>" ^
    "</header>" ^
    "<main class='fade-in' style='flex: 1; padding-bottom: 2rem;'>" ^ content ^ "</main>" ^
    "<div class='support-message' style='background: var(--bg-secondary); border-top: 1px solid var(--border-color); padding: 1rem 0; text-align: center;'>" ^
      "<div class='container'>" ^
        "<p style='color: var(--text-muted); font-size: 0.85rem; margin: 0;'>Precisa de suporte? " ^
        "<a href='" ^ whatsapp_link ~message:"Olá! Preciso de ajuda com o BusCars." () ^ "' target='_blank' rel='noopener noreferrer' style='color: var(--accent); font-weight: 600; text-decoration: none;'>" ^
          "💬 Entre em contato via WhatsApp" ^
        "</a>" ^
        "</p>" ^
      "</div>" ^
    "</div>" ^
    "<footer class='footer'>" ^
      "<div class='container'>" ^
        "<p style='font-size: 0.875rem; margin: 0;'>© 2025 BusCars - Encontre seu carro ideal no Brasil</p>" ^
      "</div>" ^
    "</footer>" ^
    "<script>" ^
      "(function() {" ^
      "function toggleMobileMenu() {" ^
          "var navMenu = document.querySelector('.nav-menu');" ^
          "if (navMenu) {" ^
            "navMenu.classList.toggle('active');" ^
          "}" ^
        "}" ^
        "window.toggleMobileMenu = toggleMobileMenu;" ^
        "" ^
        "function toggleTheme() {" ^
          "var html = document.documentElement;" ^
          "var body = document.body;" ^
          "var currentTheme = html.getAttribute('data-theme') || 'light';" ^
          "var newTheme = currentTheme === 'dark' ? 'light' : 'dark';" ^
          "html.setAttribute('data-theme', newTheme);" ^
          "localStorage.setItem('theme', newTheme);" ^
          "var expires = new Date();" ^
          "expires.setTime(expires.getTime() + (365 * 24 * 60 * 60 * 1000));" ^
          "document.cookie = 'theme=' + newTheme + '; expires=' + expires.toUTCString() + '; path=/';" ^
          "if (newTheme === 'dark') {" ^
            "html.style.backgroundColor = '#0f172a';" ^
            "html.style.color = '#f1f5f9';" ^
            "if (body) {" ^
              "body.style.backgroundColor = '#0f172a';" ^
              "body.style.color = '#f1f5f9';" ^
            "}" ^
          "} else {" ^
            "html.style.backgroundColor = '#ffffff';" ^
            "html.style.color = '#1a202c';" ^
            "if (body) {" ^
              "body.style.backgroundColor = '#ffffff';" ^
              "body.style.color = '#1a202c';" ^
            "}" ^
          "}" ^
          "var icon = document.getElementById('theme-icon');" ^
          "if (icon) {" ^
            "icon.textContent = newTheme === 'dark' ? '☀️' : '🌙';" ^
          "}" ^
        "}" ^
        "window.toggleTheme = toggleTheme;" ^
        "" ^
        "function initTheme() {" ^
          "var savedTheme = localStorage.getItem('theme') || (document.cookie.match(/theme=([^;]+)/) ? document.cookie.match(/theme=([^;]+)/)[1] : null) || 'light';" ^
        "var html = document.documentElement;" ^
        "var body = document.body;" ^
        "html.setAttribute('data-theme', savedTheme);" ^
        "if (savedTheme === 'dark') {" ^
          "html.style.backgroundColor = '#0f172a';" ^
          "html.style.color = '#f1f5f9';" ^
          "if (body) {" ^
            "body.style.backgroundColor = '#0f172a';" ^
            "body.style.color = '#f1f5f9';" ^
          "}" ^
        "} else {" ^
          "html.style.backgroundColor = '#ffffff';" ^
          "html.style.color = '#1a202c';" ^
          "if (body) {" ^
            "body.style.backgroundColor = '#ffffff';" ^
            "body.style.color = '#1a202c';" ^
          "}" ^
        "}" ^
        "var icon = document.getElementById('theme-icon');" ^
        "if (icon) {" ^
          "icon.textContent = savedTheme === 'dark' ? '☀️' : '🌙';" ^
        "}" ^
        "}" ^
        "" ^
        "if (document.readyState === 'loading') {" ^
          "document.addEventListener('DOMContentLoaded', function() {" ^
            "initTheme();" ^
        "var themeButton = document.getElementById('theme-button');" ^
        "if (themeButton) {" ^
          "themeButton.addEventListener('click', toggleTheme);" ^
        "}" ^
            "var navLinks = document.querySelectorAll('.nav-menu a');" ^
            "navLinks.forEach(function(link) {" ^
              "link.addEventListener('click', function(e) {" ^
                "var navMenu = document.querySelector('.nav-menu');" ^
                "if (navMenu && navMenu.classList.contains('active')) {" ^
                  "setTimeout(function() {" ^
                    "navMenu.classList.remove('active');" ^
                  "}, 100);" ^
                "}" ^
              "}, true);" ^
      "});" ^
            "" ^
            "document.addEventListener('click', function(e) {" ^
              "var navMenu = document.querySelector('.nav-menu');" ^
              "var menuToggle = document.querySelector('.mobile-menu-toggle');" ^
              "var isClickInsideMenu = navMenu && navMenu.contains(e.target);" ^
              "var isClickOnToggle = menuToggle && menuToggle.contains(e.target);" ^
              "if (navMenu && navMenu.classList.contains('active') && !isClickInsideMenu && !isClickOnToggle) {" ^
                "navMenu.classList.remove('active');" ^
              "}" ^
            "});" ^
          "});" ^
        "} else {" ^
          "initTheme();" ^
          "var themeButton = document.getElementById('theme-button');" ^
          "if (themeButton) {" ^
            "themeButton.addEventListener('click', toggleTheme);" ^
          "}" ^
          "var navLinks = document.querySelectorAll('.nav-menu a');" ^
          "navLinks.forEach(function(link) {" ^
            "link.addEventListener('click', function(e) {" ^
              "var navMenu = document.querySelector('.nav-menu');" ^
              "if (navMenu && navMenu.classList.contains('active')) {" ^
                "setTimeout(function() {" ^
                  "navMenu.classList.remove('active');" ^
                "}, 100);" ^
              "}" ^
            "}, true);" ^
          "});" ^
          "" ^
          "document.addEventListener('click', function(e) {" ^
            "var navMenu = document.querySelector('.nav-menu');" ^
            "var menuToggle = document.querySelector('.mobile-menu-toggle');" ^
            "var isClickInsideMenu = navMenu && navMenu.contains(e.target);" ^
            "var isClickOnToggle = menuToggle && menuToggle.contains(e.target);" ^
            "if (navMenu && navMenu.classList.contains('active') && !isClickInsideMenu && !isClickOnToggle) {" ^
              "navMenu.classList.remove('active');" ^
            "}" ^
          "});" ^
        "}" ^
      "})();" ^
      "" ^
    "</script>" ^
  "</body>" ^
  "</html>"

(* Landing page - search only like AutoTempest *)
let home_template ~brands () =
  let html_escape s =
    let buffer = Buffer.create (String.length s) in
    String.iter (function
      | '&' -> Buffer.add_string buffer "&amp;"
      | '<' -> Buffer.add_string buffer "&lt;"
      | '>' -> Buffer.add_string buffer "&gt;"
      | '"' -> Buffer.add_string buffer "&quot;"
      | '\'' -> Buffer.add_string buffer "&#39;"
      | c -> Buffer.add_char buffer c
    ) s;
    Buffer.contents buffer
  in
  let brand_options =
    "<option value=''>Todas as marcas</option>" ^
    (String.concat "" (List.map (fun (brand: Types.fipe_brand) ->
      "<option value='" ^ html_escape brand.name ^ "' data-code='" ^ html_escape brand.code ^ "'>" ^ html_escape brand.name ^ "</option>"
    ) brands))
  in
  let content = 
    "<section class='hero' style='padding: 3rem 0; margin-bottom: 2rem;'>" ^
        "<div class='container' style='max-width: 1200px; margin: 0 auto; padding: 0 2rem;'>" ^
          "<h1 style='font-size: clamp(1.75rem, 5vw, 2.5rem); font-weight: 700; margin-bottom: 1rem; text-align: center; color: var(--text-primary);'>Todos os carros. Uma busca.</h1>" ^
          "<p style='font-size: clamp(0.95rem, 3vw, 1.1rem); text-align: center; color: var(--text-muted); margin-bottom: 1rem;'>Navegue por anúncios de todos os principais sites de carros usados e novos do Brasil</p>" ^
          "<div style='text-align: center;'>" ^
            "<p style='font-size: 0.95rem; color: var(--text-muted);'>Incluindo: <strong>Localiza Seminovos, iCarros</strong> e muito mais!</p>" ^
          "</div>" ^
        "</div>" ^
      "</section>" ^
      
      "<div class='container' style='max-width: 1200px; margin: 0 auto; padding: 0 2rem;'>" ^
        "<!-- Main Search Section -->" ^
        "<section class='search-section' style='background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem; padding: clamp(1.5rem, 4vw, 2.5rem); margin-bottom: 1.5rem; box-shadow: var(--shadow-md);'>" ^
          "<form method='get' action='/vehicles' class='search-form' id='home-search-form' style='max-width: 1000px; margin: 0 auto;'>" ^
            "<!-- Main Filters (Always Visible) -->" ^
            "<div class='home-filters-grid' style='display: grid; grid-template-columns: 1fr 1fr 1fr auto; gap: 2.5rem; align-items: end; justify-items: center;'>" ^
              "<!-- Brand Filter -->" ^
              "<div class='form-group' style='width: 100%; max-width: 220px;'>" ^
                "<label for='home-brand' style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.95rem; text-align: center;'>Marca</label>" ^
                "<select name='brand' id='home-brand' style='width: 100%; padding: 0.875rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary); font-size: 0.95rem;'>" ^
                  brand_options ^
              "</select>" ^
            "</div>" ^
              
              "<!-- Model Filter -->" ^
              "<div class='form-group' style='width: 100%; max-width: 220px;'>" ^
                "<label for='home-model' style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.95rem; text-align: center;'>Modelo</label>" ^
                "<select name='model' id='home-model' style='width: 100%; padding: 0.875rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary); font-size: 0.95rem;'>" ^
                "<option value=''>Todos os modelos</option>" ^
              "</select>" ^
            "</div>" ^
              
              "<!-- Condition Filter -->" ^
              "<div class='form-group' style='width: 100%; max-width: 220px;'>" ^
                "<label for='home-condition' style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.95rem; text-align: center;'>Condição</label>" ^
                "<select name='condition' id='home-condition' style='width: 100%; padding: 0.875rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary); font-size: 0.95rem;'>" ^
                "<option value=''>Usado + Novo</option>" ^
                "<option value='used'>Usado</option>" ^
                "<option value='new'>Novo</option>" ^
              "</select>" ^
            "</div>" ^
              
              "<!-- Search Button -->" ^
              "<div class='form-group' style='display: flex; align-items: end;'>" ^
                "<button type='submit' class='btn' style='padding: 0.875rem 2.5rem; font-size: 1rem; font-weight: 600; white-space: nowrap; height: fit-content;'>🔍 Buscar</button>" ^
              "</div>" ^
            "</div>" ^
          "</form>" ^
        "</section>" ^
        
        "<!-- Advanced Filters Toggle Link (Outside section) -->" ^
        "<div style='text-align: center; margin-bottom: 1.5rem;'>" ^
          "<a href='#' id='toggle-advanced-filters' style='color: var(--accent); text-decoration: none; font-size: 0.9rem; cursor: pointer;'>" ^
            "<span id='toggle-text'>➕ Filtros avançados</span>" ^
          "</a>" ^
        "</div>" ^
        
        "<!-- Advanced Filters Section (Hidden by default) -->" ^
        "<section id='advanced-filters-section' class='search-section' style='display: none; background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem; padding: 2rem; margin: 0 auto 4rem; max-width: 1000px; box-shadow: var(--shadow-md);'>" ^
          "<form method='get' action='/vehicles' class='search-form' id='home-advanced-form' style='max-width: 900px; margin: 0 auto;'>" ^
            "<div class='advanced-filters-grid' style='display: grid; grid-template-columns: repeat(3, 1fr); gap: 1.5rem;'>" ^
              "<!-- Fuel Type Filter -->" ^
            "<div class='form-group'>" ^
                "<label for='home-fuel-type' style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem; display: block; font-size: 0.9rem;'>Combustível</label>" ^
                "<select name='fuel_type' id='home-fuel-type' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary); font-size: 0.95rem;'>" ^
                  "<option value=''>Todos os combustíveis</option>" ^
                  "<option value='Gasolina'>Gasolina</option>" ^
                  "<option value='Etanol'>Etanol</option>" ^
                  "<option value='Flex'>Flex (Gasolina/Álcool)</option>" ^
                  "<option value='Híbrido'>Híbrido</option>" ^
                  "<option value='Elétrico'>Elétrico</option>" ^
                  "<option value='Diesel'>Diesel</option>" ^
              "</select>" ^
            "</div>" ^
              
              "<!-- Year Filter -->" ^
              "<div class='form-group'>" ^
                "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem; display: block; font-size: 0.9rem;'>Ano</label>" ^
                "<div style='display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem;'>" ^
                  "<div>" ^
                    "<label style='color: var(--text-muted); font-size: 0.8rem; margin-bottom: 0.25rem; display: block;'>De</label>" ^
                    "<input type='number' name='year_min' id='home-year-min' min='1900' max='2030' step='1' placeholder='Ex: 2020' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary); font-size: 0.95rem;'>" ^
                  "</div>" ^
                  "<div>" ^
                    "<label style='color: var(--text-muted); font-size: 0.8rem; margin-bottom: 0.25rem; display: block;'>Até</label>" ^
                    "<input type='number' name='year_max' id='home-year-max' min='1900' max='2030' step='1' placeholder='Ex: 2024' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary); font-size: 0.95rem;'>" ^
                  "</div>" ^
                "</div>" ^
              "</div>" ^
              
              "<!-- Price Filter -->" ^
              "<div class='form-group'>" ^
                "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem; display: block; font-size: 0.9rem;'>Preço (R$)</label>" ^
                "<div style='display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem;'>" ^
                  "<div>" ^
                    "<label style='color: var(--text-muted); font-size: 0.8rem; margin-bottom: 0.25rem; display: block;'>De</label>" ^
                    "<input type='number' name='price_min' id='home-price-min' min='0' step='1000' placeholder='Ex: 50000' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary); font-size: 0.95rem;'>" ^
                  "</div>" ^
                  "<div>" ^
                    "<label style='color: var(--text-muted); font-size: 0.8rem; margin-bottom: 0.25rem; display: block;'>Até</label>" ^
                    "<input type='number' name='price_max' id='home-price-max' min='0' step='1000' placeholder='Ex: 500000' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary); font-size: 0.95rem;'>" ^
                  "</div>" ^
                "</div>" ^
              "</div>" ^
              
              "<!-- Location State Filter -->" ^
              "<div class='form-group'>" ^
                "<label for='home-location-state' style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem; display: block; font-size: 0.9rem;'>Estado</label>" ^
                "<select name='location_state' id='home-location-state' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary); font-size: 0.95rem;'>" ^
                  "<option value=''>Todos os estados</option>" ^
                  "<option value='AC'>Acre</option>" ^
                  "<option value='AL'>Alagoas</option>" ^
                  "<option value='AP'>Amapá</option>" ^
                  "<option value='AM'>Amazonas</option>" ^
                  "<option value='BA'>Bahia</option>" ^
                  "<option value='CE'>Ceará</option>" ^
                  "<option value='DF'>Distrito Federal</option>" ^
                  "<option value='ES'>Espírito Santo</option>" ^
                  "<option value='GO'>Goiás</option>" ^
                  "<option value='MA'>Maranhão</option>" ^
                  "<option value='MT'>Mato Grosso</option>" ^
                  "<option value='MS'>Mato Grosso do Sul</option>" ^
                  "<option value='MG'>Minas Gerais</option>" ^
                  "<option value='PA'>Pará</option>" ^
                  "<option value='PB'>Paraíba</option>" ^
                  "<option value='PR'>Paraná</option>" ^
                  "<option value='PE'>Pernambuco</option>" ^
                  "<option value='PI'>Piauí</option>" ^
                  "<option value='RJ'>Rio de Janeiro</option>" ^
                  "<option value='RN'>Rio Grande do Norte</option>" ^
                  "<option value='RS'>Rio Grande do Sul</option>" ^
                  "<option value='RO'>Rondônia</option>" ^
                  "<option value='RR'>Roraima</option>" ^
                  "<option value='SC'>Santa Catarina</option>" ^
                  "<option value='SP'>São Paulo</option>" ^
                  "<option value='SE'>Sergipe</option>" ^
                  "<option value='TO'>Tocantins</option>" ^
                "</select>" ^
              "</div>" ^
              
              "<!-- Location City Filter -->" ^
              "<div class='form-group'>" ^
                "<label for='home-location-city' style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem; display: block; font-size: 0.9rem;'>Cidade</label>" ^
                "<select name='location_city' id='home-location-city' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary); font-size: 0.95rem;'>" ^
                  "<option value=''>Todas as cidades</option>" ^
                "</select>" ^
              "</div>" ^
            "</div>" ^
          "</form>" ^
        "</section>" ^

        "<section style='margin: 4rem 0; padding: 3rem; border-radius: 1rem;'>" ^
          "<!-- Available Platforms (No Redirect) -->" ^
          "<div style='background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem; padding: 2rem; margin-bottom: 3rem;'>" ^
            "<div style='text-align: center; margin-bottom: 2rem;'>" ^
              "<h2 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1rem;'>🌐 Plataformas Integradas</h2>" ^
              "<p style='color: var(--text-muted);'>Resultados agregados das principais plataformas do Brasil</p>" ^
            "</div>" ^
            
            "<div class='platforms-grid' style='display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1.5rem;'>" ^
              "<div style='text-align: center; padding: 1.5rem; background: var(--bg-secondary); border-radius: 1rem;'>" ^
                "<img src='https://placehold.co/120x40/10b981/ffffff?text=BusCars' style='height: 25px; margin-bottom: 1rem;'>" ^
                "<h4 style='color: var(--text-primary); margin-bottom: 0.5rem; font-size: 1rem;'>BusCars Premium</h4>" ^
                "<p style='color: var(--text-muted); font-size: 0.8rem;'>Anúncios verificados</p>" ^
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
      "</div>" ^
      
      {|<script>
// Fetch cities when state changes - works for both landing page and listing page
// Make it globally available
window.fetchCities = async function fetchCities(stateCode, selectedCity) {
  // Try both possible city select IDs (landing page and listing page)
  const citySelect = document.getElementById('home-location-city') || document.getElementById('location_city');
  if (!citySelect) {
    return;
  }
  citySelect.innerHTML = '<option value="">Todas as cidades</option>';
  if (!stateCode) {
    return;
  }
  citySelect.setAttribute('data-loading', 'true');
  try {
    const response = await fetch(`/api/vehicles/cities/${encodeURIComponent(stateCode)}`);
    if (!response.ok) throw new Error('Failed to fetch cities');
    const payload = await response.json();
    const cities = (payload.data && payload.data.cities) || payload.cities || [];
    cities.forEach(function(cityName) {
      const option = document.createElement('option');
      option.value = cityName;
      option.textContent = cityName;
      if (selectedCity && selectedCity === cityName) {
        option.selected = true;
      }
      citySelect.appendChild(option);
    });
  } catch (error) {
    // Silent fail - don't expose errors to console
  } finally {
    citySelect.removeAttribute('data-loading');
  }
};

// Fetch models dynamically from database when brand is selected
async function fetchHomeModels(brandName, selectedModel) {
  const modelSelect = document.getElementById('home-model');
  if (!modelSelect) return;
  modelSelect.innerHTML = '<option value="">Todos os modelos</option>';
  if (!brandName) {
    return;
  }
  modelSelect.setAttribute('data-loading', 'true');
  try {
    const response = await fetch(`/api/vehicles/models/${encodeURIComponent(brandName)}`);
    if (!response.ok) throw new Error('Failed to fetch models');
    const payload = await response.json();
    const models = (payload.data && payload.data.models) || payload.models || [];
    models.forEach(function(modelName) {
      const option = document.createElement('option');
      const modelValue = typeof modelName === 'string' ? modelName : modelName.name;
      option.value = modelValue;
      option.textContent = modelValue;
      if (selectedModel && selectedModel === modelValue) {
        option.selected = true;
      }
      modelSelect.appendChild(option);
    });
  } catch (error) {
    console.error('Erro ao carregar modelos:', error);
  } finally {
    modelSelect.removeAttribute('data-loading');
  }
}

// Toggle advanced filters
function toggleAdvancedFilters(event) {
  if (event) event.preventDefault();
  const advancedSection = document.getElementById('advanced-filters-section');
  const toggleText = document.getElementById('toggle-text');
  if (advancedSection.style.display === 'none') {
    advancedSection.style.display = 'block';
    toggleText.textContent = '➖ Ocultar filtros avançados';
  } else {
    advancedSection.style.display = 'none';
    toggleText.textContent = '➕ Filtros avançados';
  }
}

// Combine advanced filters with main form on submit
function combineFiltersOnSubmit(event) {
  const mainForm = document.getElementById('home-search-form');
  if (!mainForm) return;
  
  // Get advanced filter values
  const fuelType = document.getElementById('home-fuel-type');
  const yearMin = document.getElementById('home-year-min');
  const yearMax = document.getElementById('home-year-max');
  const priceMin = document.getElementById('home-price-min');
  const priceMax = document.getElementById('home-price-max');
  const locationState = document.getElementById('home-location-state');
  const locationCity = document.getElementById('home-location-city');
  
  // Add advanced filter values as hidden inputs to main form
  if (fuelType && fuelType.value) {
    let hidden = document.getElementById('hidden-fuel-type');
    if (!hidden) {
      hidden = document.createElement('input');
      hidden.type = 'hidden';
      hidden.name = 'fuel_type';
      hidden.id = 'hidden-fuel-type';
      mainForm.appendChild(hidden);
    }
    hidden.value = fuelType.value;
  }
  
  if (yearMin && yearMin.value) {
    let hidden = document.getElementById('hidden-year-min');
    if (!hidden) {
      hidden = document.createElement('input');
      hidden.type = 'hidden';
      hidden.name = 'year_min';
      hidden.id = 'hidden-year-min';
      mainForm.appendChild(hidden);
    }
    hidden.value = yearMin.value;
  }
  
  if (yearMax && yearMax.value) {
    let hidden = document.getElementById('hidden-year-max');
    if (!hidden) {
      hidden = document.createElement('input');
      hidden.type = 'hidden';
      hidden.name = 'year_max';
      hidden.id = 'hidden-year-max';
      mainForm.appendChild(hidden);
    }
    hidden.value = yearMax.value;
  }
  
  if (priceMin && priceMin.value) {
    let hidden = document.getElementById('hidden-price-min');
    if (!hidden) {
      hidden = document.createElement('input');
      hidden.type = 'hidden';
      hidden.name = 'price_min';
      hidden.id = 'hidden-price-min';
      mainForm.appendChild(hidden);
    }
    hidden.value = priceMin.value;
  }
  
  if (priceMax && priceMax.value) {
    let hidden = document.getElementById('hidden-price-max');
    if (!hidden) {
      hidden = document.createElement('input');
      hidden.type = 'hidden';
      hidden.name = 'price_max';
      hidden.id = 'hidden-price-max';
      mainForm.appendChild(hidden);
    }
    hidden.value = priceMax.value;
  }
  
  if (locationState && locationState.value) {
    let hidden = document.getElementById('hidden-location-state');
    if (!hidden) {
      hidden = document.createElement('input');
      hidden.type = 'hidden';
      hidden.name = 'location_state';
      hidden.id = 'hidden-location-state';
      mainForm.appendChild(hidden);
    }
    hidden.value = locationState.value;
  }
  
  if (locationCity && locationCity.value) {
    let hidden = document.getElementById('hidden-location-city');
    if (!hidden) {
      hidden = document.createElement('input');
      hidden.type = 'hidden';
      hidden.name = 'location_city';
      hidden.id = 'hidden-location-city';
      mainForm.appendChild(hidden);
    }
    hidden.value = locationCity.value;
  }
}

// Initialize home page
document.addEventListener('DOMContentLoaded', function() {
  const brandSelect = document.getElementById('home-brand');
  const toggleButton = document.getElementById('toggle-advanced-filters');
  const mainForm = document.getElementById('home-search-form');
  const homeLocationStateSelect = document.getElementById('home-location-state');
  
  if (brandSelect) {
    brandSelect.addEventListener('change', function(event) {
      const option = event.target.selectedOptions[0];
      const brandName = option ? option.value : '';
      fetchHomeModels(brandName, null);
    });
  }
  
  if (toggleButton) {
    toggleButton.addEventListener('click', toggleAdvancedFilters);
  }
  
  if (mainForm) {
    mainForm.addEventListener('submit', combineFiltersOnSubmit);
  }
  
  // Add listener for landing page state select (in advanced filters)
  if (homeLocationStateSelect) {
    homeLocationStateSelect.addEventListener('change', function(event) {
      const stateCode = event.target.value;
      if (window.fetchCities) {
        window.fetchCities(stateCode, null);
      }
    });
    
    // Load cities if state is already selected from URL params
    const urlParams = new URLSearchParams(window.location.search);
    const locationStateValue = urlParams.get('location_state');
    const locationCityValue = urlParams.get('location_city');
    if (locationStateValue && window.fetchCities) {
      homeLocationStateSelect.value = locationStateValue;
      window.fetchCities(locationStateValue, locationCityValue);
    }
  }
});
</script>|} in
  content

(* Calculate which 3 page numbers to show in pagination *)
let calculate_pagination_pages current_page total_pages =
  if total_pages <= 3 then
    (* Show all pages if 3 or fewer *)
    List.init total_pages (fun i -> i + 1)
  else if current_page <= 2 then
    (* Near the beginning: show 1, 2, 3 *)
    [1; 2; 3]
  else if current_page >= total_pages - 1 then
    (* Near the end: show last 3 pages *)
    [total_pages - 2; total_pages - 1; total_pages]
  else
    (* In the middle: show page-1, page, page+1 *)
    [current_page - 1; current_page; current_page + 1]

(* Professional vehicle listing page with sidebar layout *)
let vehicle_listing_template ~(vehicles : Types.vehicle list) ~page ~total_pages ~total_count ~start_index ~end_index ~per_page ~brands ~models ~selected_brand ~selected_model () =
  let html_escape s =
    let buffer = Buffer.create (String.length s) in
    String.iter (function
      | '&' -> Buffer.add_string buffer "&amp;"
      | '<' -> Buffer.add_string buffer "&lt;"
      | '>' -> Buffer.add_string buffer "&gt;"
      | '"' -> Buffer.add_string buffer "&quot;"
      | '\'' -> Buffer.add_string buffer "&#39;"
      | c -> Buffer.add_char buffer c
    ) s;
    Buffer.contents buffer
  in
  let selected_brand_code =
    match selected_brand with
    | Some name ->
        (try
           let brand = List.find (fun (b: Types.fipe_brand) -> b.name = name) brands in
           Some brand.code
         with Not_found -> None)
    | None -> None
  in
  let brand_options =
    "<option value=''>Todas as marcas</option>" ^
    (List.fold_left (fun acc (brand: Types.fipe_brand) ->
      let selected_attr = match selected_brand with
        | Some name when name = brand.name -> " selected"
        | _ -> ""
      in
      acc ^
      "<option value=\"" ^ (html_escape brand.name) ^ "\" data-code=\"" ^ (html_escape brand.code) ^ "\"" ^ selected_attr ^ ">" ^
        (html_escape brand.name) ^ "</option>"
    ) "" brands)
  in
  let model_options =
    "<option value=''>Todos os modelos</option>" ^
    (List.fold_left (fun acc (model: Types.fipe_model) ->
      let selected_attr = match selected_model with
        | Some name when name = model.name -> " selected"
        | _ -> ""
      in
      acc ^
      "<option value=\"" ^ (html_escape model.name) ^ "\"" ^ selected_attr ^ ">" ^
        (html_escape model.name) ^ "</option>"
    ) "" models)
  in
  
  (* Enhanced vehicle cards - similar to dashboard but for public listing *)
  let vehicle_cards = 
    List.fold_left (fun acc (vehicle : Types.vehicle) ->
      acc ^
      "<div class='vehicle-card' data-price='" ^ vehicle.price ^ "' data-year='" ^ string_of_int vehicle.year ^ "' data-mileage='" ^ vehicle.mileage ^ "' onclick=\"goToVehicle('" ^ vehicle.slug ^ "')\" style='cursor: pointer;'>" ^
        "<div class='vehicle-image' style='background-image: url(\"" ^ vehicle.image ^ "\"); position: relative;'>" ^
            "<div style='position: absolute; top: 1rem; left: 1rem; background: " ^ 
              (if vehicle.condition = "new" then "var(--accent)" else 
               match vehicle.source with 
               | "buscar" -> "linear-gradient(135deg, var(--accent), var(--accent-hover))"
               | "localiza" -> "#059669"
               | "icarros" -> "#374151"
               | _ -> "#764ba2") ^ 
            "; color: white; padding: 0.375rem 0.75rem; border-radius: 1rem; font-size: 0.75rem; font-weight: 700; z-index: 10;'>" ^
              (if vehicle.condition = "new" then "NOVO" else String.uppercase_ascii vehicle.source) ^ 
            "</div>" ^
            (if vehicle.source = "buscar" then
            "<div style='position: absolute; top: 1rem; right: 1rem; background: rgba(255,255,255,0.95); color: var(--accent); padding: 0.25rem 0.5rem; border-radius: 0.5rem; font-size: 0.7rem; font-weight: 700; z-index: 10;'>✓ VERIFICADO</div>"
             else "") ^
          "</div>" ^
        "<div class='vehicle-info'>" ^
          "<h3 class='vehicle-title'>" ^ vehicle.brand ^ " " ^ vehicle.model ^ " " ^ string_of_int vehicle.year ^ "</h3>" ^
          "<p class='vehicle-price'>" ^ format_price_display vehicle.price vehicle.source ^ "</p>" ^
          "<div class='vehicle-specs'>" ^
            "<div class='spec-item'>" ^
              "<span class='spec-label'>Ano</span>" ^
              "<span class='spec-value'>" ^ string_of_int vehicle.year ^ "</span>" ^
              "</div>" ^
            "<div class='spec-item'>" ^
              "<span class='spec-label'>KM</span>" ^
              "<span class='spec-value'>" ^ vehicle.mileage ^ "</span>" ^
                "</div>" ^
            "<div class='spec-item'>" ^
              "<span class='spec-label'>Combustível</span>" ^
              "<span class='spec-value'>" ^ (normalize_fuel_type vehicle.fuel_type) ^ "</span>" ^
                "</div>" ^
            "<div class='spec-item'>" ^
              "<span class='spec-label'>Cor</span>" ^
              "<span class='spec-value'>" ^ (format_color vehicle.color) ^ "</span>" ^
                "</div>" ^
                (if vehicle.financing_available then
              "<div class='spec-item' style='background: var(--accent); color: white;'>" ^
                "<span class='spec-label' style='color: white;'>Financiamento</span>" ^
                "<span class='spec-value' style='color: white;'>💳 Sim</span>" ^
                  "</div>"
                 else "") ^
                (if vehicle.trade_accepted then
              "<div class='spec-item'>" ^
                "<span class='spec-label'>Troca</span>" ^
                "<span class='spec-value'>🔄 Sim</span>" ^
                  "</div>"
                 else "") ^
              "</div>" ^
          "<div style='display: flex; justify-content: space-between; align-items: center; margin-top: 1rem; padding-top: 1rem; border-top: 1px solid var(--border-color);'>" ^
            "<span style='color: var(--text-muted); font-size: 0.85rem;'>📍 " ^ (normalize_city_name vehicle.location_city) ^ "</span>" ^
            "<span style='color: var(--text-muted); font-size: 0.85rem;'>Via " ^ (String.capitalize_ascii vehicle.source) ^ "</span>" ^
            "</div>" ^
          "<button onclick=\"event.stopPropagation(); goToVehicle('" ^ vehicle.slug ^ "')\" class='btn' style='width: 100%; margin-top: 1rem;'>Ver Detalhes</button>" ^
        "</div>" ^
      "</div>"
    ) "" vehicles
  in
  
  (
      "<div class='container' style='max-width: 1400px;'>" ^
        "<!-- Header -->" ^
        "<div class='listing-header' style='margin: 2rem 0;'>" ^
          "<h1 style='color: var(--text-primary); font-size: 2.25rem; font-weight: 800; margin-bottom: 0.5rem;'>Catálogo de Veículos</h1>" ^
          "<p style='color: var(--text-muted); font-size: 1.1rem;'>Encontre o carro ideal entre milhares de opções</p>" ^
          "<p style='color: var(--text-muted); font-size: 0.9rem;'>Mostrando até " ^ string_of_int per_page ^ " resultados por página</p>" ^
        "</div>" ^
        
        "<!-- Main Content Area -->" ^
        "<div class='listing-layout' style='display: grid; grid-template-columns: 300px 1fr; gap: 2rem;'>" ^
          "<!-- Left Sidebar - Filters -->" ^
          "<div class='filters-sidebar' style='position: sticky; top: 7rem; height: fit-content;'>" ^
            "<div class='filters-container' style='background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem; padding: 2rem;'>" ^
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
                      "<option value='localiza'>Localiza</option>" ^
                      "<option value='icarros'>iCarros</option>" ^
                    "</select>" ^
                  "</div>" ^
                  
                  "<!-- Brand Filter -->" ^
                  "<div class='form-group'>" ^
                    "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.9rem;'>Marca</label>" ^
                    "<select name='brand' id='brand' data-selected-brand-code='" ^
                      (match selected_brand_code with Some code -> html_escape code | None -> "") ^
                      "' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      brand_options ^
                    "</select>" ^
                  "</div>" ^
                  
                  "<!-- Model Filter -->" ^
                  "<div class='form-group'>" ^
                    "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.9rem;'>Modelo</label>" ^
                    "<select name='model' id='model' data-preloaded='" ^ (if models <> [] then "true" else "false") ^
                    "' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      model_options ^
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
                    "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.9rem;'>Ano</label>" ^
                    "<div style='display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem;'>" ^
                      "<div>" ^
                        "<label style='color: var(--text-muted); font-size: 0.8rem; margin-bottom: 0.25rem; display: block;'>De</label>" ^
                        "<input type='number' name='year_min' id='year_min' min='1900' max='2030' step='1' placeholder='Ex: 2020' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      "</div>" ^
                      "<div>" ^
                        "<label style='color: var(--text-muted); font-size: 0.8rem; margin-bottom: 0.25rem; display: block;'>Até</label>" ^
                        "<input type='number' name='year_max' id='year_max' min='1900' max='2030' step='1' placeholder='Ex: 2024' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      "</div>" ^
                    "</div>" ^
                  "</div>" ^
                  
                  "<!-- Price Filter -->" ^
                  "<div class='form-group'>" ^
                    "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.9rem;'>Preço (R$)</label>" ^
                    "<div style='display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem;'>" ^
                      "<div>" ^
                        "<label style='color: var(--text-muted); font-size: 0.8rem; margin-bottom: 0.25rem; display: block;'>De</label>" ^
                        "<input type='number' name='price_min' id='price_min' min='0' step='1000' placeholder='Ex: 50000' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      "</div>" ^
                      "<div>" ^
                        "<label style='color: var(--text-muted); font-size: 0.8rem; margin-bottom: 0.25rem; display: block;'>Até</label>" ^
                        "<input type='number' name='price_max' id='price_max' min='0' step='1000' placeholder='Ex: 500000' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      "</div>" ^
                    "</div>" ^
                  "</div>" ^
                  
                  "<!-- Location State Filter -->" ^
                  "<div class='form-group'>" ^
                    "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.9rem;'>Estado</label>" ^
                    "<select name='location_state' id='location_state' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      "<option value=''>Todos os estados</option>" ^
                      "<option value='AC'>Acre</option>" ^
                      "<option value='AL'>Alagoas</option>" ^
                      "<option value='AP'>Amapá</option>" ^
                      "<option value='AM'>Amazonas</option>" ^
                      "<option value='BA'>Bahia</option>" ^
                      "<option value='CE'>Ceará</option>" ^
                      "<option value='DF'>Distrito Federal</option>" ^
                      "<option value='ES'>Espírito Santo</option>" ^
                      "<option value='GO'>Goiás</option>" ^
                      "<option value='MA'>Maranhão</option>" ^
                      "<option value='MT'>Mato Grosso</option>" ^
                      "<option value='MS'>Mato Grosso do Sul</option>" ^
                      "<option value='MG'>Minas Gerais</option>" ^
                      "<option value='PA'>Pará</option>" ^
                      "<option value='PB'>Paraíba</option>" ^
                      "<option value='PR'>Paraná</option>" ^
                      "<option value='PE'>Pernambuco</option>" ^
                      "<option value='PI'>Piauí</option>" ^
                      "<option value='RJ'>Rio de Janeiro</option>" ^
                      "<option value='RN'>Rio Grande do Norte</option>" ^
                      "<option value='RS'>Rio Grande do Sul</option>" ^
                      "<option value='RO'>Rondônia</option>" ^
                      "<option value='RR'>Roraima</option>" ^
                      "<option value='SC'>Santa Catarina</option>" ^
                      "<option value='SP'>São Paulo</option>" ^
                      "<option value='SE'>Sergipe</option>" ^
                      "<option value='TO'>Tocantins</option>" ^
                    "</select>" ^
                  "</div>" ^
                  
                  "<!-- Location City Filter -->" ^
                  "<div class='form-group'>" ^
                    "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.9rem;'>Cidade</label>" ^
                    "<select name='location_city' id='location_city' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      "<option value=''>Todas as cidades</option>" ^
                    "</select>" ^
                  "</div>" ^
                  
                  "<!-- Fuel Filter -->" ^
                  "<div class='form-group'>" ^
                    "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.75rem; display: block; font-size: 0.9rem;'>Combustível</label>" ^
                    "<select name='fuel_type' id='fuel_type' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
                      "<option value=''>Todos os combustíveis</option>" ^
                      "<option value='Gasolina'>Gasolina</option>" ^
                      "<option value='Etanol'>Etanol</option>" ^
                      "<option value='Flex'>Flex (Gasolina/Álcool)</option>" ^
                      "<option value='Híbrido'>Híbrido</option>" ^
                      "<option value='Elétrico'>Elétrico</option>" ^
                      "<option value='Diesel'>Diesel</option>" ^
                    "</select>" ^
                  "</div>" ^
                "</div>" ^
              "</form>" ^
            "</div>" ^
          "</div>" ^
          
          "<!-- Right Content - Vehicle List -->" ^
          "<div class='vehicles-list'>" ^
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
                "<div class='vehicle-grid' style='margin-bottom: 2rem;'>" ^
                  vehicle_cards ^
                "</div>" ^
                
                "<!-- Proper Pagination -->" ^
                (if total_pages > 1 then
                  "<div class='pagination-mobile' style='display: flex; justify-content: center; align-items: center; gap: 1rem; margin: 3rem 0; padding: 2rem; background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem;'>" ^
                    (if page > 1 then
                      "<button onclick='goToPage(" ^ string_of_int (page - 1) ^ ");' style='background: var(--accent); color: white; border: none; padding: 0.75rem 1rem; border-radius: 0.5rem; cursor: pointer; font-weight: 600;'>← Anterior</button>"
                     else
                      "<button disabled style='background: var(--bg-secondary); color: var(--text-muted); border: none; padding: 0.75rem 1rem; border-radius: 0.5rem; cursor: not-allowed; font-weight: 600;'>← Anterior</button>") ^
                    
                    "<div style='display: flex; gap: 0.5rem; align-items: center;'>" ^
                      "<span style='color: var(--text-muted); margin-right: 1rem;'>Página " ^ string_of_int page ^ " de " ^ string_of_int total_pages ^ "</span>" ^
                      
                      (let pages_to_show = calculate_pagination_pages page total_pages in
                       String.concat "" (List.map (fun page_num ->
                         if page_num = page then
                           "<span style='background: var(--accent); color: white; padding: 0.5rem 0.75rem; border-radius: 0.5rem; font-weight: 600; min-width: 40px; text-align: center; margin: 0 0.25rem;'>" ^ string_of_int page_num ^ "</span>"
                         else
                           "<button onclick='goToPage(" ^ string_of_int page_num ^ ");' style='background: var(--bg-secondary); color: var(--text-primary); border: 1px solid var(--border-color); padding: 0.5rem 0.75rem; border-radius: 0.5rem; cursor: pointer; font-weight: 600; min-width: 40px; margin: 0 0.25rem;'>" ^ string_of_int page_num ^ "</button>"
                       ) pages_to_show)) ^
                    "</div>" ^
                    
                    (if page < total_pages then
                      "<button onclick='goToPage(" ^ string_of_int (page + 1) ^ ");' style='background: var(--accent); color: white; border: none; padding: 0.75rem 1rem; border-radius: 0.5rem; cursor: pointer; font-weight: 600;'>Próxima →</button>"
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
// Global function to fetch cities dynamically when state changes
// Make it globally available for both landing page and listing page
if (!window.fetchCities) {
  window.fetchCities = async function fetchCities(stateCode, selectedCity) {
    // Try both possible city select IDs (landing page and listing page)
    const citySelect = document.getElementById('home-location-city') || document.getElementById('location_city');
    if (!citySelect) {
      console.warn('City select element not found.');
      return;
    }
    citySelect.innerHTML = '<option value="">Todas as cidades</option>';
    if (!stateCode) {
      return;
    }
    citySelect.setAttribute('data-loading', 'true');
    try {
      const response = await fetch(`/api/vehicles/cities/${encodeURIComponent(stateCode)}`);
      if (!response.ok) throw new Error('Failed to fetch cities');
      const payload = await response.json();
      console.log('Cities response:', payload);
      const cities = (payload.data && payload.data.cities) || payload.cities || [];
      console.log('Parsed cities:', cities);
      if (!cities || cities.length === 0) {
        console.warn('No cities found in response for state:', stateCode);
      }
      cities.forEach(function(cityName) {
        const option = document.createElement('option');
        option.value = cityName;
        option.textContent = cityName;
        if (selectedCity && selectedCity === cityName) {
          option.selected = true;
        }
        citySelect.appendChild(option);
      });
    } catch (error) {
      console.error('Erro ao carregar cidades:', error);
      console.error('Error details:', error.message, error.stack);
    } finally {
      citySelect.removeAttribute('data-loading');
    }
  };
}

async function fetchModels(brandName, selectedModel) {
  const modelSelect = document.getElementById('model');
  if (!modelSelect) return;
  modelSelect.innerHTML = '<option value="">Todos os modelos</option>';
  if (!brandName) {
    return;
  }
  modelSelect.setAttribute('data-loading', 'true');
  try {
    const response = await fetch(`/api/vehicles/models/${encodeURIComponent(brandName)}`);
    if (!response.ok) throw new Error('Failed to fetch models');
    const payload = await response.json();
    const models = (payload.data && payload.data.models) || payload.models || [];
    models.forEach(function(modelName) {
      const option = document.createElement('option');
      const modelValue = typeof modelName === 'string' ? modelName : modelName.name;
      option.value = modelValue;
      option.textContent = modelValue;
      if (selectedModel && selectedModel === modelValue) {
        option.selected = true;
      }
      modelSelect.appendChild(option);
    });
  } catch (error) {
    console.error('Erro ao carregar modelos da FIPE', error);
  } finally {
    modelSelect.removeAttribute('data-loading');
  }
}

// Clear all filters
function clearFilters() {
  window.location.href = '/vehicles';
}

// Apply sorting
function applySorting() {
  const sortValue = document.getElementById('sort-dropdown').value;
  const params = new URLSearchParams(window.location.search);
  params.set('sort', sortValue);
  params.set('page', '1');
  window.location.href = '/vehicles?' + params.toString();
}

// Navigate to specific page
function goToPage(pageNum) {
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
  const urlParams = new URLSearchParams(window.location.search);
  const brandSelect = document.getElementById('brand');
  const modelSelect = document.getElementById('model');
  
  // Set brand and trigger model update
  const brandValue = urlParams.get('brand');
  if (brandValue) {
    if (brandSelect) {
      brandSelect.value = brandValue;
    }
  }

  if (brandSelect) {
    brandSelect.addEventListener('change', function(event) {
      const option = event.target.selectedOptions[0];
      const brandName = option ? option.value : '';
      fetchModels(brandName, null);
    });
  }
  
  // Add listener for listing page state select
  const locationStateSelect = document.getElementById('location_state');
  if (locationStateSelect) {
    locationStateSelect.addEventListener('change', function(event) {
      const stateCode = event.target.value;
      if (window.fetchCities) {
        window.fetchCities(stateCode, null);
      }
    });
  }
  
  // Add listener for landing page state select
  const homeLocationStateSelect = document.getElementById('home-location-state');
  if (homeLocationStateSelect) {
    homeLocationStateSelect.addEventListener('change', function(event) {
      const stateCode = event.target.value;
      if (window.fetchCities) {
        window.fetchCities(stateCode, null);
      }
    });
  }
  
      const modelValue = urlParams.get('model');
  if (brandSelect) {
    const selectedOption = brandSelect.selectedOptions[0];
    const brandName = selectedOption ? selectedOption.value : '';
    if (brandName) {
      fetchModels(brandName, modelValue);
    }
  }

  if (modelValue && modelSelect) {
    modelSelect.value = modelValue;
  }
  
  // Load cities if state is already selected
  const locationStateValue = urlParams.get('location_state');
  const locationCityValue = urlParams.get('location_city');
  if (locationStateValue && locationStateSelect && window.fetchCities) {
    locationStateSelect.value = locationStateValue;
    window.fetchCities(locationStateValue, locationCityValue);
  }
  
  // Set other filter values
  const filterFields = ['year_min', 'year_max', 'price_min', 'price_max', 'fuel_type', 'condition', 'source', 'location_state', 'location_city'];
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
  
});
</script>|}
    )

(* Modern login template *)
let login_template ?error () =
  let error_msg = match error with
    | Some msg -> "<div class='error'>" ^ msg ^ "</div>"
    | None -> ""
  in
  
  (
      "<div class='container'>" ^
        "<div class='login-container'>" ^
          "<div style='text-align: center; margin-bottom: 2rem;'>" ^
            "<h2 style='color: var(--text-primary); font-weight: 700; margin-bottom: 0.5rem;'>Bem-vindo de volta</h2>" ^
            "<p style='color: var(--text-muted);'>Entre na sua conta</p>" ^
          "</div>" ^
          error_msg ^
          
          "<form method='post' action='/login' autocomplete='off'>" ^
            "<div class='form-group'>" ^
              "<label for='email'>E-mail</label>" ^
              "<input type='email' name='email' id='email' required placeholder='Insira seu e-mail' autocomplete='off'>" ^
            "</div>" ^
            "<div class='form-group'>" ^
              "<label for='password'>Senha</label>" ^
              "<input type='password' name='password' id='password' required placeholder='Insira sua senha' autocomplete='off'>" ^
            "</div>" ^
            "<button type='submit' class='btn' style='width: 100%; margin-top: 1.5rem;'>Entrar na Conta</button>" ^
          "</form>" ^
          
          "<div style='text-align: center; margin-top: 1.5rem; padding-top: 1.5rem; border-top: 1px solid var(--border-color);'>" ^
            "<a href='" ^ whatsapp_link ~message:"Olá! Esqueci minha senha e preciso de ajuda para recuperá-la." () ^ "' target='_blank' rel='noopener noreferrer' style='color: var(--accent); font-weight: 600; text-decoration: none; font-size: 0.875rem; display: inline-block; margin-bottom: 1rem;'>" ^
              "🔐 Esqueci minha senha" ^
            "</a>" ^
          "</div>" ^
          
          "<div style='text-align: center; margin-top: 1.5rem; padding-top: 1.5rem; border-top: 1px solid var(--border-color);'>" ^
            "<p style='color: var(--text-muted); font-size: 0.875rem;'>Não tem uma conta?</p>" ^
            "<a href='/register' style='color: var(--accent); font-weight: 600; text-decoration: none;'>Cadastre-se gratuitamente</a>" ^
          "</div>" ^
        "</div>" ^
      "</div>"
    )

(* Registration template with CEP completion *)
let register_template ?error () =
  let error_msg =
    match error with
    | Some msg -> "<div class='error'>" ^ msg ^ "</div>"
    | None -> ""
  in
  
      "<div class='container'>" ^
        "<div class='login-container'>" ^
          "<div style='text-align: center; margin-bottom: 2rem;'>" ^
            "<h2 style='color: var(--text-primary); font-weight: 700; margin-bottom: 0.5rem;'>Crie sua conta</h2>" ^
            "<p style='color: var(--text-muted);'>Preencha seus dados para começar</p>" ^
          "</div>" ^
          error_msg ^
          
          "<form method='post' action='/register' id='register-form'>" ^
            "<div class='form-group'>" ^
              "<label for='name'>Nome Completo *</label>" ^
              "<input type='text' name='name' id='name' required placeholder='Seu nome completo'>" ^
            "</div>" ^
            
            "<div class='form-group'>" ^
              "<label for='document_number'>CPF/CNPJ *</label>" ^
        "<input type='text' name='document_number' id='document_number' required placeholder='000.000.000-00 ou 00.000.000/0000-00' " ^
          "pattern='[0-9]{3}\\.[0-9]{3}\\.[0-9]{3}-[0-9]{2}|[0-9]{2}\\.[0-9]{3}\\.[0-9]{3}/[0-9]{4}-[0-9]{2}' " ^
          "title='CPF: 000.000.000-00 ou CNPJ: 00.000.000/0000-00'>" ^
        "<small id='document-error' style='color: #ef4444; font-size: 0.75rem; display: none; margin-top: 0.25rem;'></small>" ^
            "</div>" ^
            
            "<div class='form-group'>" ^
              "<label for='email'>E-mail *</label>" ^
        "<input type='email' name='email' id='email' required placeholder='seu@email.com' " ^
          "pattern='[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}$' title='Digite um e-mail válido'>" ^
        "<small id='email-error' style='color: #ef4444; font-size: 0.75rem; display: none; margin-top: 0.25rem;'></small>" ^
            "</div>" ^
            
            "<div class='form-group'>" ^
              "<label for='phone'>Telefone *</label>" ^
        "<input type='tel' name='phone' id='phone' required placeholder='(33) 98815-4380' " ^
          "pattern='\\([0-9]{2}\\) [0-9]{5}-[0-9]{4}' title='Formato: (00) 00000-0000'>" ^
            "</div>" ^
            
            "<div class='form-group'>" ^
              "<label for='password'>Senha *</label>" ^
        "<input type='password' name='password' id='password' required " ^
          "placeholder='Mínimo 6 caracteres com 1 caractere especial' minlength='6' " ^
          "pattern='(?=.*[!@#$%^&*(),.?\":{}|<>]).{6,}' " ^
          "title='Mínimo 6 caracteres com pelo menos 1 caractere especial'>" ^
        "<small id='password-error' style='color: #ef4444; font-size: 0.75rem; display: none; margin-top: 0.25rem;'></small>" ^
        "<small style='color: var(--text-muted); font-size: 0.75rem; display: block; margin-top: 0.25rem;'>" ^
          "Mínimo 6 caracteres com pelo menos 1 caractere especial (!@#$%^&*)" ^
        "</small>" ^
      "</div>" ^

      "<div class='form-group'>" ^
        "<label for='confirm_password'>Confirmar Senha *</label>" ^
        "<input type='password' name='confirm_password' id='confirm_password' required placeholder='Digite a senha novamente' minlength='6'>" ^
        "<small id='confirm-password-error' style='color: #ef4444; font-size: 0.75rem; display: none; margin-top: 0.25rem;'>" ^
          "As senhas não coincidem" ^
        "</small>" ^
            "</div>" ^
            
            "<div class='form-group'>" ^
              "<label for='address_zipcode'>CEP *</label>" ^
        "<input type='text' name='address_zipcode' id='address_zipcode' required placeholder='00000-000' " ^
          "maxlength='9' pattern='[0-9]{5}-[0-9]{3}' title='Formato: 00000-000' autocomplete='postal-code'>" ^
              "<small style='color: var(--text-muted); font-size: 0.75rem;'>Digite o CEP para preencher automaticamente</small>" ^
            "</div>" ^
            
            "<div class='form-group'>" ^
              "<label for='address_street'>Rua *</label>" ^
              "<input type='text' name='address_street' id='address_street' required placeholder='Nome da rua'>" ^
            "</div>" ^
            
      "<div style='display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 1rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='address_number'>Número *</label>" ^
                "<input type='text' name='address_number' id='address_number' required placeholder='123'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='address_complement'>Complemento</label>" ^
                "<input type='text' name='address_complement' id='address_complement' placeholder='Apto, Bloco, etc.'>" ^
              "</div>" ^
            "</div>" ^
            
            "<div class='form-group'>" ^
              "<label for='address_neighborhood'>Bairro *</label>" ^
              "<input type='text' name='address_neighborhood' id='address_neighborhood' required placeholder='Nome do bairro'>" ^
            "</div>" ^
            
      "<div style='display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 1rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='address_city'>Cidade *</label>" ^
                "<input type='text' name='address_city' id='address_city' required placeholder='Nome da cidade'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='address_state'>Estado *</label>" ^
          "<select name='address_state' id='address_state' required " ^
            "style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); " ^
                   "border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
            "<option value=''>Selecione o estado</option>" ^
            "<option value='AC'>Acre</option>" ^
            "<option value='AL'>Alagoas</option>" ^
            "<option value='AP'>Amapá</option>" ^
            "<option value='AM'>Amazonas</option>" ^
            "<option value='BA'>Bahia</option>" ^
            "<option value='CE'>Ceará</option>" ^
            "<option value='DF'>Distrito Federal</option>" ^
            "<option value='ES'>Espírito Santo</option>" ^
            "<option value='GO'>Goiás</option>" ^
            "<option value='MA'>Maranhão</option>" ^
            "<option value='MT'>Mato Grosso</option>" ^
            "<option value='MS'>Mato Grosso do Sul</option>" ^
            "<option value='MG'>Minas Gerais</option>" ^
            "<option value='PA'>Pará</option>" ^
            "<option value='PB'>Paraíba</option>" ^
            "<option value='PR'>Paraná</option>" ^
            "<option value='PE'>Pernambuco</option>" ^
            "<option value='PI'>Piauí</option>" ^
            "<option value='RJ'>Rio de Janeiro</option>" ^
            "<option value='RN'>Rio Grande do Norte</option>" ^
            "<option value='RS'>Rio Grande do Sul</option>" ^
            "<option value='RO'>Rondônia</option>" ^
            "<option value='RR'>Roraima</option>" ^
            "<option value='SC'>Santa Catarina</option>" ^
            "<option value='SP'>São Paulo</option>" ^
            "<option value='SE'>Sergipe</option>" ^
            "<option value='TO'>Tocantins</option>" ^
          "</select>" ^
              "</div>" ^
            "</div>" ^
            
            "<div class='form-group'>" ^
              "<label for='referral_code'>Código de Acesso *</label>" ^
              "<input type='text' name='referral_code' id='referral_code' required placeholder='Digite o código de acesso'>" ^
              "<small style='color: var(--text-muted); font-size: 0.75rem;'>Código fornecido por um administrador ou usuário</small>" ^
            "</div>" ^
            
            "<button type='submit' class='btn' style='width: 100%; margin-top: 1.5rem;'>Criar Conta</button>" ^
          "</form>" ^
          
          "<div style='text-align: center; margin-top: 2rem; padding-top: 2rem; border-top: 1px solid var(--border-color);'>" ^
            "<p style='color: var(--text-muted); font-size: 0.875rem;'>Já tem uma conta?</p>" ^
            "<a href='/login' style='color: var(--accent); font-weight: 600; text-decoration: none;'>Fazer login</a>" ^
          "</div>" ^
        "</div>" ^
      "</div>" ^
      
  "<script type='text/javascript'>" ^
  "document.addEventListener('DOMContentLoaded', function() {" ^
    "var cepInput = document.getElementById('address_zipcode');" ^
    "var streetInput = document.getElementById('address_street');" ^
    "var neighborhoodInput = document.getElementById('address_neighborhood');" ^
    "var cityInput = document.getElementById('address_city');" ^
    "var stateInput = document.getElementById('address_state');" ^
    "var documentInput = document.getElementById('document_number');" ^
    "var emailInput = document.getElementById('email');" ^
    "var phoneInput = document.getElementById('phone');" ^
    "var passwordInput = document.getElementById('password');" ^
    "var confirmPasswordInput = document.getElementById('confirm_password');" ^
    "var documentError = document.getElementById('document-error');" ^
    "var emailError = document.getElementById('email-error');" ^
    "var passwordError = document.getElementById('password-error');" ^
    "var confirmPasswordError = document.getElementById('confirm-password-error');" ^
    "var form = document.getElementById('register-form');" ^

    "if (!form || !cepInput || !streetInput || !neighborhoodInput || !cityInput || !stateInput || " ^
        "!documentInput || !emailInput || !phoneInput || !passwordInput || !confirmPasswordInput) {" ^
      "return;" ^
    "}" ^

    "function formatCPFCNPJ(value) {" ^
      "value = value.replace(/[^0-9]/g, '');" ^
      "if (value.length <= 11) {" ^
        "if (value.length > 9) {" ^
          "value = value.substring(0, 9) + '-' + value.substring(9);" ^
        "}" ^
        "if (value.length > 6) {" ^
          "value = value.substring(0, 6) + '.' + value.substring(6);" ^
        "}" ^
        "if (value.length > 3) {" ^
          "value = value.substring(0, 3) + '.' + value.substring(3);" ^
        "}" ^
      "} else {" ^
        "if (value.length > 12) {" ^
          "value = value.substring(0, 12) + '-' + value.substring(12, 14);" ^
        "}" ^
        "if (value.length > 8) {" ^
          "value = value.substring(0, 8) + '/' + value.substring(8);" ^
        "}" ^
        "if (value.length > 5) {" ^
          "value = value.substring(0, 5) + '.' + value.substring(5);" ^
        "}" ^
        "if (value.length > 2) {" ^
          "value = value.substring(0, 2) + '.' + value.substring(2);" ^
        "}" ^
      "}" ^
      "return value;" ^
    "}" ^

    "function validateCPFCNPJ(value) {" ^
      "var digits = value.replace(/[^0-9]/g, '');" ^
      "return digits.length === 11 || digits.length === 14;" ^
    "}" ^

    "documentInput.addEventListener('input', function(e) {" ^
      "var formatted = formatCPFCNPJ(e.target.value);" ^
      "e.target.value = formatted;" ^
      "var digits = formatted.replace(/[^0-9]/g, '');" ^
      "if (digits.length > 0 && !validateCPFCNPJ(formatted)) {" ^
        "documentError.textContent = 'CPF deve ter 11 dígitos ou CNPJ deve ter 14 dígitos';" ^
        "documentError.style.display = 'block';" ^
      "} else {" ^
        "documentError.style.display = 'none';" ^
      "}" ^
    "}, true);" ^

    "function validateEmail(email) {" ^
      "var emailRegex = /^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/;" ^
      "return emailRegex.test(email);" ^
    "}" ^

    "emailInput.addEventListener('blur', function(e) {" ^
      "if (e.target.value && !validateEmail(e.target.value)) {" ^
        "emailError.textContent = 'Por favor, insira um e-mail válido';" ^
        "emailError.style.display = 'block';" ^
      "} else {" ^
        "emailError.style.display = 'none';" ^
      "}" ^
    "}, true);" ^

    "emailInput.addEventListener('input', function(e) {" ^
      "if (emailError.style.display === 'block' && validateEmail(e.target.value)) {" ^
        "emailError.style.display = 'none';" ^
      "}" ^
    "}, true);" ^

    "phoneInput.addEventListener('input', function(e) {" ^
      "var value = e.target.value.replace(/[^0-9]/g, '');" ^
      "if (value.length > 11) value = value.substring(0, 11);" ^
      "var formatted = '';" ^
      "if (value.length > 0) {" ^
        "if (value.length <= 2) {" ^
          "formatted = '(' + value;" ^
        "} else if (value.length <= 6) {" ^
          "formatted = '(' + value.substring(0, 2) + ') ' + value.substring(2);" ^
        "} else if (value.length <= 10) {" ^
          "formatted = '(' + value.substring(0, 2) + ') ' + value.substring(2, 6) + '-' + value.substring(6);" ^
        "} else {" ^
          "formatted = '(' + value.substring(0, 2) + ') ' + value.substring(2, 7) + '-' + value.substring(7, 11);" ^
        "}" ^
      "}" ^
      "e.target.value = formatted;" ^
    "}, true);" ^

    "function validatePassword(password) {" ^
      "if (password.length < 6) {" ^
        "return { valid: false, message: 'A senha deve ter no mínimo 6 caracteres' };" ^
      "}" ^
      "var specialChars = /[!@#$%^&*(),.?\":{}|<>]/;" ^
      "if (!specialChars.test(password)) {" ^
        "return { valid: false, message: 'A senha deve conter pelo menos 1 caractere especial (!@#$%^&*)' };" ^
      "}" ^
      "return { valid: true };" ^
    "}" ^

    "passwordInput.addEventListener('blur', function(e) {" ^
      "var validation = validatePassword(e.target.value);" ^
      "if (!validation.valid) {" ^
        "passwordError.textContent = validation.message;" ^
        "passwordError.style.display = 'block';" ^
      "} else {" ^
        "passwordError.style.display = 'none';" ^
      "}" ^
    "}, true);" ^

    "passwordInput.addEventListener('input', function(e) {" ^
      "if (passwordError.style.display === 'block') {" ^
        "var validation = validatePassword(e.target.value);" ^
        "if (validation.valid) {" ^
          "passwordError.style.display = 'none';" ^
        "}" ^
      "}" ^
      "if (confirmPasswordInput.value && e.target.value !== confirmPasswordInput.value) {" ^
        "confirmPasswordError.style.display = 'block';" ^
      "} else {" ^
        "confirmPasswordError.style.display = 'none';" ^
      "}" ^
    "}, true);" ^

    "confirmPasswordInput.addEventListener('input', function(e) {" ^
      "if (e.target.value !== passwordInput.value) {" ^
        "confirmPasswordError.style.display = 'block';" ^
      "} else {" ^
        "confirmPasswordError.style.display = 'none';" ^
      "}" ^
    "}, true);" ^

    "confirmPasswordInput.addEventListener('blur', function(e) {" ^
      "if (e.target.value && e.target.value !== passwordInput.value) {" ^
        "confirmPasswordError.style.display = 'block';" ^
      "}" ^
    "}, true);" ^

    "cepInput.addEventListener('input', function(e) {" ^
      "var value = e.target.value.replace(/[^0-9]/g, '');" ^
      "if (value.length > 8) value = value.substring(0, 8);" ^
      "if (value.length > 5) {" ^
        "value = value.substring(0, 5) + '-' + value.substring(5, 8);" ^
      "}" ^
      "e.target.value = value;" ^
    "}, true);" ^
          
          "cepInput.addEventListener('blur', function() {" ^
      "var cep = cepInput.value.replace(/[^0-9]/g, '');" ^
            "if (cep.length === 8) {" ^
        "cepInput.disabled = true;" ^
              "fetch('https://viacep.com.br/ws/' + cep + '/json/')" ^
          ".then(function(response) { return response.json(); })" ^
          ".then(function(data) {" ^
            "cepInput.disabled = false;" ^
                  "if (!data.erro) {" ^
                    "streetInput.value = data.logradouro || '';" ^
                    "neighborhoodInput.value = data.bairro || '';" ^
                    "cityInput.value = data.localidade || '';" ^
              "if (data.uf) stateInput.value = data.uf;" ^
                  "} else {" ^
              "alert('CEP não encontrado. Verifique o CEP digitado.');" ^
                  "}" ^
                "})" ^
          ".catch(function(error) {" ^
            "cepInput.disabled = false;" ^
                  "console.error('Erro ao buscar CEP:', error);" ^
            "alert('Erro ao buscar CEP. Tente novamente.');" ^
                "});" ^
      "} else if (cep.length > 0) {" ^
        "alert('CEP deve ter 8 dígitos');" ^
      "}" ^
    "}, true);" ^

    "form.addEventListener('submit', function(e) {" ^
      "var isValid = true;" ^
      "var documentDigits = documentInput.value.replace(/[^0-9]/g, '');" ^
      "if (documentDigits.length !== 11 && documentDigits.length !== 14) {" ^
        "documentError.textContent = 'CPF deve ter 11 dígitos ou CNPJ deve ter 14 dígitos';" ^
        "documentError.style.display = 'block';" ^
        "isValid = false;" ^
      "}" ^
      "if (!validateEmail(emailInput.value)) {" ^
        "emailError.textContent = 'Por favor, insira um e-mail válido';" ^
        "emailError.style.display = 'block';" ^
        "isValid = false;" ^
      "}" ^
      "var passwordValidation = validatePassword(passwordInput.value);" ^
      "if (!passwordValidation.valid) {" ^
        "passwordError.textContent = passwordValidation.message;" ^
        "passwordError.style.display = 'block';" ^
        "isValid = false;" ^
      "}" ^
      "if (passwordInput.value !== confirmPasswordInput.value) {" ^
        "confirmPasswordError.style.display = 'block';" ^
        "isValid = false;" ^
      "}" ^
      "if (!isValid) {" ^
        "e.preventDefault();" ^
        "return false;" ^
      "}" ^
    "}, true);" ^
          "});" ^
      "</script>"

(* Modern dashboard template with tabs for user/admin *)
let dashboard_template ~(user:Types.user) ~vehicles_page:(vehicles_page:Types.vehicle_page) ~brands ~models ?selected_brand ?selected_model ?selected_source ?selected_user_email ~referral_codes_page ?all_users_page () =
  let vehicles = vehicles_page.vehicles in
  let total_vehicles = vehicles_page.total_count in
  let current_page = vehicles_page.page in
  let total_pages = vehicles_page.total_pages in
  let is_admin = user.is_admin in
  
  (* Vehicle cards *)
  let vehicle_cards = 
    List.fold_left (fun acc vehicle ->
      acc ^
      "<div class='vehicle-card'>" ^
        "<div class='vehicle-image' style='background-image: url(\"" ^ vehicle.image ^ "\")'></div>" ^
        "<div class='vehicle-info'>" ^
          "<h3 class='vehicle-title'>" ^ vehicle.brand ^ " " ^ vehicle.model ^ "</h3>" ^
          "<p class='vehicle-price'>" ^ format_price_display vehicle.price vehicle.source ^ "</p>" ^
          "<div class='vehicle-specs'>" ^
            "<div class='spec-item'>" ^
              "<span class='spec-label'>Status</span>" ^
              "<span class='spec-value'>" ^ (if vehicle.is_active then "Ativo" else "Inativo") ^ "</span>" ^
            "</div>" ^
            "<div class='spec-item'>" ^
              "<span class='spec-label'>Ano</span>" ^
              "<span class='spec-value'>" ^ string_of_int vehicle.year ^ "</span>" ^
            "</div>" ^
            "<div class='spec-item'>" ^
              "<span class='spec-label'>Fonte</span>" ^
              "<span class='spec-value'>" ^ 
                (match vehicle.source with
                 | "buscar" -> "BusCars"
                 | "icarros" -> "iCarros"
                 | "localiza" -> "Localiza"
                 | "webmotors" -> "Webmotors"
                 | s -> String.capitalize_ascii s) ^
              "</span>" ^
            "</div>" ^
          "</div>" ^
          "<div style='display: flex; gap: 0.5rem; margin-top: 1rem;'>" ^
            "<a href='/dashboard/edit-vehicle/" ^ vehicle.slug ^ "' class='btn' style='font-size: 0.875rem; padding: 0.5rem 1rem;'>Editar</a>" ^
            "<button onclick='deleteVehicle(" ^ string_of_int vehicle.id ^ ", \"" ^ vehicle.slug ^ "\")' class='btn-outline btn' style='font-size: 0.875rem; padding: 0.5rem 1rem; background: #ef4444; color: white; border-color: #ef4444;'>Excluir</button>" ^
          "</div>" ^
        "</div>" ^
      "</div>"
    ) "" vehicles
  in
  
  (* Referral codes list HTML generator *)
  let referral_codes_list_html codes =
    List.fold_left (fun acc code ->
      let status = 
        if not code.is_active then
          "<span style='color: var(--text-muted); font-weight: 600;'>Desativado</span>"
        else
          match code.used_by_user_id with
          | Some _ -> 
              "<span style='color: #ef4444; font-weight: 600;'>Usado</span>" ^
              (match code.used_by_user_name with
               | Some name -> " por " ^ name
               | None -> "")
          | None -> "<span style='color: var(--accent); font-weight: 600;'>Disponível</span>"
      in
      acc ^
      "<div class='referral-code-item' style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 1.5rem; border-radius: 0.75rem; margin-bottom: 1rem;'>" ^
        "<div style='display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem;'>" ^
          "<div>" ^
            "<div style='font-weight: 700; color: var(--text-primary); font-size: 1.1rem; margin-bottom: 0.25rem;'>" ^ code.code ^ "</div>" ^
            "<div style='color: var(--text-muted); font-size: 0.875rem;'>Criado em " ^ code.created_at ^ "</div>" ^
          "</div>" ^
          "<div style='text-align: right;'>" ^
            status ^
            (if is_admin && code.is_active then
               "<button onclick='deactivateCode(" ^ string_of_int code.referral_code_id ^ ")' class='btn-outline btn' style='margin-left: 0.5rem; font-size: 0.75rem; padding: 0.25rem 0.75rem;'>Desativar</button>"
             else
               "") ^
          "</div>" ^
        "</div>" ^
      "</div>"
    ) "" codes
  in
  
  (* Initial referral codes list from page data *)
  let initial_codes_list = match referral_codes_page with
    | Some page -> referral_codes_list_html page.codes
    | None -> ""
  in
  
  (* All users list (admin only) - will be loaded dynamically *)
  let all_users_list = match all_users_page with
    | Some page ->
        List.fold_left (fun acc (u:Types.user) ->
          acc ^
          "<div class='user-item' data-user-id='" ^ string_of_int u.user_id ^ "' style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 1.5rem; border-radius: 0.75rem; margin-bottom: 1rem; cursor: pointer;'>" ^
            "<div style='display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem;'>" ^
              "<div>" ^
                "<div style='font-weight: 700; color: var(--text-primary); margin-bottom: 0.25rem;'>" ^ u.name ^ 
                  (if u.is_admin then " <span style='background: var(--accent); color: white; padding: 0.125rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem;'>ADMIN</span>" else "") ^
                "</div>" ^
                "<div style='color: var(--text-muted); font-size: 0.875rem;'>" ^ u.email ^ "</div>" ^
                (match u.phone with
                 | Some phone -> "<div style='color: var(--text-muted); font-size: 0.875rem;'>" ^ phone ^ "</div>"
                 | None -> "") ^
              "</div>" ^
              "<div style='color: var(--text-muted); font-size: 0.875rem;'>Cadastrado em " ^ u.created_at ^ "</div>" ^
            "</div>" ^
          "</div>"
        ) "" page.users
    | None -> ""
  in
  
  (* Change password form *)
  let change_password_form =
    "<form id='change-password-form' style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 2rem; border-radius: 1rem; margin-bottom: 2rem;'>" ^
      "<h3 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1.5rem;'>Alterar Senha</h3>" ^
      "<div class='form-group'>" ^
        "<label for='old-password'>Senha Atual</label>" ^
        "<input type='password' name='old_password' id='old-password' required>" ^
      "</div>" ^
      "<div class='form-group'>" ^
        "<label for='new-password'>Nova Senha</label>" ^
        "<input type='password' name='new_password' id='new-password' required placeholder='Mínimo 6 caracteres com 1 caractere especial'>" ^
        "<small id='new-password-error' style='color: #ef4444; font-size: 0.75rem; display: none; margin-top: 0.25rem;'></small>" ^
        "<small style='color: var(--text-muted); font-size: 0.75rem; display: block; margin-top: 0.25rem;'>Mínimo 6 caracteres com pelo menos 1 caractere especial (!@#$%^&*)</small>" ^
      "</div>" ^
      "<div class='form-group'>" ^
        "<label for='confirm-password'>Confirmar Nova Senha</label>" ^
        "<input type='password' name='confirm_password' id='confirm-password' required>" ^
        "<small id='password-match-error' style='color: var(--text-danger, #ef4444); font-size: 0.75rem; display: none; margin-top: 0.5rem;'>As senhas não coincidem</small>" ^
      "</div>" ^
      "<button type='submit' class='btn'>Alterar Senha</button>" ^
    "</form>"
  in
  
  (* User info form *)
  let readonly_attr = if is_admin then "" else " readonly" in
  let user_info_form =
    "<form id='user-info-form' style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 2rem; border-radius: 1rem;'>" ^
      "<h3 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1.5rem;'>Informações Pessoais</h3>" ^
      "<div class='form-group'>" ^
        "<label for='edit-name'>Nome Completo" ^ (if not is_admin then " <span style='color: var(--text-muted); font-size: 0.75rem;'>(somente leitura)</span>" else "") ^ "</label>" ^
        "<input type='text' name='name' id='edit-name' value='" ^ user.name ^ "'" ^ readonly_attr ^ " required>" ^
      "</div>" ^
      "<div class='form-group'>" ^
        "<label for='edit-email'>E-mail" ^ (if not is_admin then " <span style='color: var(--text-muted); font-size: 0.75rem;'>(somente leitura)</span>" else "") ^ "</label>" ^
        "<input type='email' name='email' id='edit-email' value='" ^ user.email ^ "'" ^ readonly_attr ^ " required>" ^
      "</div>" ^
      "<div class='form-group'>" ^
        "<label for='edit-phone'>Telefone" ^ (if not is_admin then " <span style='color: var(--text-muted); font-size: 0.75rem;'>(somente leitura)</span>" else "") ^ "</label>" ^
        "<input type='tel' name='phone' id='edit-phone' value='" ^ (Option.value ~default:"" user.phone) ^ "'" ^ readonly_attr ^ " required>" ^
      "</div>" ^
      "<div class='form-group'>" ^
        "<label for='edit-document'>CPF/CNPJ" ^ (if not is_admin then " <span style='color: var(--text-muted); font-size: 0.75rem;'>(somente leitura)</span>" else "") ^ "</label>" ^
        "<input type='text' name='document_number' id='edit-document' value='" ^ (Option.value ~default:"" user.document_number) ^ "'" ^ readonly_attr ^ " required>" ^
      "</div>" ^
      "<h3 style='color: var(--text-primary); font-weight: 700; margin: 2rem 0 1.5rem 0;'>Endereço</h3>" ^
      "<div class='form-group'>" ^
        "<label for='edit-zipcode'>CEP</label>" ^
        "<input type='text' name='address_zipcode' id='edit-zipcode' value='" ^ (Option.value ~default:"" user.address_zipcode) ^ "' required>" ^
      "</div>" ^
      "<div class='form-group'>" ^
        "<label for='edit-street'>Rua</label>" ^
        "<input type='text' name='address_street' id='edit-street' value='" ^ (Option.value ~default:"" user.address_street) ^ "' required>" ^
      "</div>" ^
      "<div style='display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;'>" ^
        "<div class='form-group'>" ^
          "<label for='edit-number'>Número</label>" ^
          "<input type='text' name='address_number' id='edit-number' value='" ^ (Option.value ~default:"" user.address_number) ^ "' required>" ^
        "</div>" ^
        "<div class='form-group'>" ^
          "<label for='edit-complement'>Complemento</label>" ^
          "<input type='text' name='address_complement' id='edit-complement' value='" ^ (Option.value ~default:"" user.address_complement) ^ "'>" ^
        "</div>" ^
      "</div>" ^
      "<div class='form-group'>" ^
        "<label for='edit-neighborhood'>Bairro</label>" ^
        "<input type='text' name='address_neighborhood' id='edit-neighborhood' value='" ^ (Option.value ~default:"" user.address_neighborhood) ^ "' required>" ^
      "</div>" ^
      "<div style='display: grid; grid-template-columns: 2fr 1fr; gap: 1rem;'>" ^
        "<div class='form-group'>" ^
          "<label for='edit-city'>Cidade</label>" ^
          "<input type='text' name='address_city' id='edit-city' value='" ^ (Option.value ~default:"" user.address_city) ^ "' required>" ^
        "</div>" ^
        "<div class='form-group'>" ^
          "<label for='edit-state'>Estado</label>" ^
          "<input type='text' name='address_state' id='edit-state' value='" ^ (Option.value ~default:"" user.address_state) ^ "' required maxlength='2'>" ^
        "</div>" ^
      "</div>" ^
      "<button type='submit' class='btn' style='margin-top: 1.5rem;'>Salvar Alterações</button>" ^
    "</form>"
  in
  
  (* Create referral code form (admin only) *)
  let create_code_form = if is_admin then
    "<div style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 2rem; border-radius: 1rem; margin-bottom: 2rem;'>" ^
      "<h3 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1.5rem;'>Criar Novo Código de Acesso</h3>" ^
      "<form id='create-code-form'>" ^
        "<div class='form-group'>" ^
          "<label for='new-code'>Código (opcional - será gerado automaticamente se vazio)</label>" ^
          "<input type='text' name='code' id='new-code' placeholder='Deixe vazio para gerar automaticamente'>" ^
          "<small style='color: var(--text-muted); font-size: 0.75rem; display: block; margin-top: 0.5rem;'>Se deixar vazio, um código único será gerado automaticamente</small>" ^
        "</div>" ^
        "<button type='submit' class='btn'>Criar Código</button>" ^
      "</form>" ^
    "</div>"
  else ""
  in
  
  (* Distribute referral codes form (admin only) *)
  let distribute_codes_form = if is_admin then
    "<div style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 2rem; border-radius: 1rem; margin-bottom: 2rem;'>" ^
      "<h3 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1.5rem;'>Distribuir Convites</h3>" ^
      "<form id='distribute-codes-form'>" ^
        "<div class='form-group'>" ^
          "<label for='distribute-email'>Email do usuário (deixe vazio ou digite 'all' para todos os usuários)</label>" ^
          "<input type='email' name='email' id='distribute-email' placeholder='email@exemplo.com ou deixe vazio para todos'>" ^
          "<small style='color: var(--text-muted); font-size: 0.75rem; display: block; margin-top: 0.5rem;'>Deixe vazio ou digite 'all' para distribuir códigos para todos os usuários da plataforma</small>" ^
        "</div>" ^
        "<div class='form-group'>" ^
          "<label for='distribute-count'>Quantidade de códigos por usuário</label>" ^
          "<input type='number' name='count' id='distribute-count' value='1' min='1' max='10' required>" ^
          "<small style='color: var(--text-muted); font-size: 0.75rem; display: block; margin-top: 0.5rem;'>Número de códigos a serem criados para cada usuário (máximo 10)</small>" ^
        "</div>" ^
        "<button type='submit' class='btn'>Distribuir Convites</button>" ^
      "</form>" ^
    "</div>"
  else ""
  in
  
  (
      "<div class='container'>" ^
        "<div style='margin: 2rem 0;'>" ^
          "<div class='dashboard-header'>" ^
            "<div>" ^
              "<h1 style='color: var(--text-primary); margin-bottom: 0.5rem;'>Dashboard" ^
              (if is_admin then " <span style='background: var(--accent); color: white; padding: 0.25rem 0.75rem; border-radius: 0.25rem; font-size: 0.875rem;'>ADMIN</span>" else "") ^
              "</h1>" ^
              "<p style='color: var(--text-muted);'>Olá, " ^ user.name ^ "!</p>" ^
            "</div>" ^
            "<div style='display: flex; gap: 1rem;'>" ^
              "<a href='/dashboard/add-vehicle' class='btn'>+ Novo Anúncio</a>" ^
            "</div>" ^
          "</div>" ^
          
          "<div style='border-bottom: 2px solid var(--border-color); margin-bottom: 2rem;'>" ^
            "<div style='display: flex; gap: 2rem; overflow-x: auto;'>" ^
              "<button class='tab-button active' data-tab='vehicles' data-tab-name='vehicles'>" ^
                (if is_admin then "Todos os Anúncios" else "Meus Anúncios") ^
              "</button>" ^
              "<button class='tab-button' data-tab='info' data-tab-name='info'>Minhas Informações</button>" ^
              "<button class='tab-button' data-tab='referrals' data-tab-name='referrals'>Códigos de Acesso</button>" ^
              (if is_admin then
                 "<button class='tab-button' data-tab='users' data-tab-name='users'>Usuários</button>" ^
                 "<button class='tab-button' data-tab='utilities' data-tab-name='utilities'>Utilitários</button>"
               else
                 "") ^
            "</div>" ^
          "</div>" ^
          
          (* Vehicles tab with filters and pagination *)
          "<div id='tab-vehicles' class='tab-content active'>" ^
            "<div style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 1.5rem; border-radius: 1rem; margin-bottom: 2rem;'>" ^
              "<div style='display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; flex-wrap: wrap; gap: 1rem;'>" ^
                "<div>" ^
                  "<h3 style='color: var(--text-primary); font-weight: 700; margin: 0 0 0.5rem 0;'>" ^
                    (if is_admin then "Gerenciar Anúncios" else "Meus Anúncios") ^
                  "</h3>" ^
                  "<div style='display: flex; gap: 1rem; align-items: center; flex-wrap: wrap;'>" ^
                    "<span style='color: var(--text-muted); font-size: 0.875rem;'>Total: " ^ string_of_int total_vehicles ^ " anúncio(s)</span>" ^
                    "<span style='color: var(--text-muted); font-size: 0.875rem;'>Mostrando 12 por página</span>" ^
                  "</div>" ^
                "</div>" ^
              "</div>" ^
              "<form id='dashboard-vehicle-filters' method='get' action='/dashboard' style='display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 1rem;'>" ^
                "<input type='hidden' name='page' value='1'>" ^
                "<div class='form-group' style='margin: 0;'>" ^
                  "<label for='dashboard-brand' style='font-size: 0.75rem; color: var(--text-muted); margin-bottom: 0.25rem; display: block;'>Marca</label>" ^
                  "<select name='brand' id='dashboard-brand' style='width: 100%; padding: 0.5rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-input); color: var(--text-primary);'>" ^
                    "<option value=''>Todas</option>" ^
                    (List.fold_left (fun acc (brand: Types.fipe_brand) ->
                      let html_escape s =
                        let buffer = Buffer.create (String.length s) in
                        String.iter (function
                          | '&' -> Buffer.add_string buffer "&amp;"
                          | '<' -> Buffer.add_string buffer "&lt;"
                          | '>' -> Buffer.add_string buffer "&gt;"
                          | '"' -> Buffer.add_string buffer "&quot;"
                          | '\'' -> Buffer.add_string buffer "&#39;"
                          | c -> Buffer.add_char buffer c
                        ) s;
                        Buffer.contents buffer
                      in
                      let selected = match selected_brand with
                        | Some name when name = brand.name -> " selected"
                        | _ -> ""
                      in
                      acc ^ "<option value=\"" ^ (html_escape brand.name) ^ "\" data-code=\"" ^ (html_escape brand.code) ^ "\"" ^ selected ^ ">" ^ (html_escape brand.name) ^ "</option>"
                    ) "" brands) ^
                  "</select>" ^
                "</div>" ^
                "<div class='form-group' style='margin: 0;'>" ^
                  "<label for='dashboard-model' style='font-size: 0.75rem; color: var(--text-muted); margin-bottom: 0.25rem; display: block;'>Modelo</label>" ^
                  "<select name='model' id='dashboard-model' style='width: 100%; padding: 0.5rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-input); color: var(--text-primary);'>" ^
                    "<option value=''>Todos</option>" ^
                    (List.fold_left (fun acc (model: Types.fipe_model) ->
                      let selected = match selected_model with
                        | Some name when name = model.name -> " selected"
                        | _ -> ""
                      in
                      acc ^ "<option value=\"" ^ model.name ^ "\"" ^ selected ^ ">" ^ model.name ^ "</option>"
                    ) "" models) ^
                  "</select>" ^
                "</div>" ^
                (if is_admin then
                  "<div class='form-group' style='margin: 0;'>" ^
                    "<label for='dashboard-source' style='font-size: 0.75rem; color: var(--text-muted); margin-bottom: 0.25rem; display: block;'>Fonte</label>" ^
                    "<select name='source' id='dashboard-source' style='width: 100%; padding: 0.5rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-input); color: var(--text-primary);'>" ^
                      "<option value=''>Todas</option>" ^
                      (let source_options = [
                        ("buscar", "BusCars");
                        ("icarros", "iCarros");
                        ("localiza", "Localiza");
                        ("webmotors", "Webmotors")
                      ] in
                      List.fold_left (fun acc (value, label) ->
                        let selected = match selected_source with
                          | Some s when s = value -> " selected"
                          | _ -> ""
                        in
                        acc ^ "<option value=\"" ^ value ^ "\"" ^ selected ^ ">" ^ label ^ "</option>"
                      ) "" source_options) ^
                    "</select>" ^
                  "</div>" ^
                  "<div class='form-group' style='margin: 0;'>" ^
                    "<label for='dashboard-user-email' style='font-size: 0.75rem; color: var(--text-muted); margin-bottom: 0.25rem; display: block;'>Email do Usuário</label>" ^
                    "<input type='email' name='user_email' id='dashboard-user-email' value=\"" ^ (match selected_user_email with Some e -> e | None -> "") ^ "\" placeholder='exemplo@email.com' style='width: 100%; padding: 0.5rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-input); color: var(--text-primary);'>" ^
                  "</div>"
                else
                  "") ^
                "<div class='form-group' style='margin: 0;'>" ^
                  "<label for='dashboard-sort' style='font-size: 0.75rem; color: var(--text-muted); margin-bottom: 0.25rem; display: block;'>Ordenar</label>" ^
                  "<select name='sort' id='dashboard-sort' style='width: 100%; padding: 0.5rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-input); color: var(--text-primary);'>" ^
                    "<option value=''>Padrão</option>" ^
                    "<option value='price_asc'>Preço: Menor</option>" ^
                    "<option value='price_desc'>Preço: Maior</option>" ^
                    "<option value='year_desc'>Ano: Mais recente</option>" ^
                    "<option value='year_asc'>Ano: Mais antigo</option>" ^
                  "</select>" ^
                "</div>" ^
                "<div class='form-group' style='margin: 0;'>" ^
                  "<button type='submit' class='btn' style='font-size: 0.875rem; padding: 0.5rem 1rem;'>Filtrar</button>" ^
                "</div>" ^
              "</form>" ^
            "</div>" ^
            (if total_vehicles = 0 then
              "<div style='text-align: center; padding: 4rem; color: var(--text-muted);'>" ^
                "<h3>Nenhum anúncio encontrado</h3>" ^
                "<p>Comece criando seu primeiro anúncio de veículo</p>" ^
                "<a href='/dashboard/add-vehicle' class='btn' style='margin-top: 1rem;'>Criar Primeiro Anúncio</a>" ^
              "</div>"
             else
              "<div class='vehicle-grid' style='margin-bottom: 2rem;'>" ^ vehicle_cards ^ "</div>" ^
              (if total_pages > 1 then
                "<div style='display: flex; justify-content: center; align-items: center; gap: 1rem; padding: 2rem; background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem;'>" ^
                  (if current_page > 1 then
                    (let uri_encode s = Uri.pct_encode ~component:`Query s in
                    let query_parts = ref [] in
                    (match selected_brand with Some b -> query_parts := ("brand=" ^ (uri_encode b)) :: !query_parts | None -> ());
                    (match selected_model with Some m -> query_parts := ("model=" ^ (uri_encode m)) :: !query_parts | None -> ());
                    let query_str = if !query_parts = [] then "" else "&" ^ (String.concat "&" (List.rev !query_parts))
                    in
                    "<a href='/dashboard?page=" ^ string_of_int (current_page - 1) ^ query_str ^ "' class='btn-outline btn'>← Anterior</a>")
                   else
                    "<button disabled class='btn-outline btn' style='opacity: 0.5; cursor: not-allowed;'>← Anterior</button>") ^
                  "<span style='color: var(--text-primary);'>Página " ^ string_of_int current_page ^ " de " ^ string_of_int total_pages ^ "</span>" ^
                  (if current_page < total_pages then
                    (let uri_encode s = Uri.pct_encode ~component:`Query s in
                    let query_parts = ref [] in
                    (match selected_brand with Some b -> query_parts := ("brand=" ^ (uri_encode b)) :: !query_parts | None -> ());
                    (match selected_model with Some m -> query_parts := ("model=" ^ (uri_encode m)) :: !query_parts | None -> ());
                    let query_str = if !query_parts = [] then "" else "&" ^ (String.concat "&" (List.rev !query_parts))
                    in
                    "<a href='/dashboard?page=" ^ string_of_int (current_page + 1) ^ query_str ^ "' class='btn-outline btn'>Próxima →</a>")
                   else
                    "<button disabled class='btn-outline btn' style='opacity: 0.5; cursor: not-allowed;'>Próxima →</button>") ^
                "</div>"
               else "")) ^
          "</div>" ^
          
          (* User info tab *)
          "<div id='tab-info' class='tab-content'>" ^
            change_password_form ^
            user_info_form ^
          "</div>" ^
          
          (* Referral codes tab *)
          "<div id='tab-referrals' class='tab-content'>" ^
            (if is_admin then 
              "<div style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 2rem; border-radius: 1rem; margin-bottom: 2rem;'>" ^
                "<h3 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1.5rem;'>Ações em Massa</h3>" ^
                "<button id='deactivate-all-codes-btn' class='btn' style='background: var(--text-danger, #ef4444); color: white;'>Desativar Todos os Códigos</button>" ^
                "<small style='color: var(--text-muted); font-size: 0.75rem; display: block; margin-top: 0.5rem;'>Esta ação desativará todos os códigos de acesso ativos no sistema</small>" ^
              "</div>" ^
              distribute_codes_form ^ create_code_form 
            else "") ^
            "<div style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 2rem; border-radius: 1rem; margin-bottom: 2rem;'>" ^
              "<div style='display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; flex-wrap: wrap; gap: 1rem;'>" ^
                "<h3 style='color: var(--text-primary); font-weight: 700; margin: 0;'>" ^
                (if is_admin then "Todos os Códigos de Acesso" else "Meus Códigos de Acesso") ^
                "</h3>" ^
                "<div id='referral-codes-count' style='color: var(--text-muted); font-size: 0.875rem;'>" ^
                (match referral_codes_page with
                 | Some page -> string_of_int page.total_count ^ " código(s)"
                 | None -> "0 código(s)") ^
                "</div>" ^
              "</div>" ^
              "<div style='display: grid; grid-template-columns: 2fr 1fr; gap: 1rem; margin-bottom: 1.5rem;'>" ^
                "<div class='form-group' style='margin: 0;'>" ^
                  "<input type='text' id='referral-code-search' placeholder='Buscar por código...' style='width: 100%;'>" ^
                "</div>" ^
                "<div class='form-group' style='margin: 0;'>" ^
                  "<select id='referral-code-status-filter' style='width: 100%;'>" ^
                    "<option value='available'>Disponíveis</option>" ^
                    "<option value='used'>Usados</option>" ^
                    "<option value='deactivated'>Desativados</option>" ^
                    "<option value='all'>Todos os status</option>" ^
                  "</select>" ^
                "</div>" ^
              "</div>" ^
            "</div>" ^
            "<div id='referral-codes-list-container'>" ^
              initial_codes_list ^
            "</div>" ^
            "<div id='referral-codes-pagination' style='display: flex; justify-content: center; align-items: center; gap: 1rem; margin-top: 2rem;'>" ^
              (match referral_codes_page with
               | Some page ->
                   "<button id='prev-page-btn' onclick='loadReferralCodes(" ^ string_of_int (page.page - 1) ^ ")' " ^
                   (if page.has_prev then "" else "disabled style='opacity: 0.5; cursor: not-allowed;'") ^
                   " class='btn-outline btn'>Anterior</button>" ^
                   "<span style='color: var(--text-primary);'>Página " ^ string_of_int page.page ^ " de " ^ string_of_int page.total_pages ^ "</span>" ^
                   "<button id='next-page-btn' onclick='loadReferralCodes(" ^ string_of_int (page.page + 1) ^ ")' " ^
                   (if page.has_next then "" else "disabled style='opacity: 0.5; cursor: not-allowed;'") ^
                   " class='btn-outline btn'>Próxima</button>"
               | None -> "") ^
            "</div>" ^
          "</div>" ^
          
          (* Users tab (admin only) *)
          (if is_admin then
            "<div id='tab-users' class='tab-content'>" ^
              "<div style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 2rem; border-radius: 1rem; margin-bottom: 2rem;'>" ^
                "<div style='display: flex; justify-content: space-between; align-items: center; margin-bottom: 1.5rem; flex-wrap: wrap; gap: 1rem;'>" ^
                  "<h3 style='color: var(--text-primary); font-weight: 700; margin: 0;'>Todos os Usuários</h3>" ^
                  "<div id='users-count' style='color: var(--text-muted); font-size: 0.875rem;'>" ^
                  (match all_users_page with
                   | Some page -> string_of_int page.total_count ^ " usuário(s)"
                   | None -> "0 usuário(s)") ^
                  "</div>" ^
                "</div>" ^
                "<div style='display: grid; grid-template-columns: 2fr 1fr 1fr; gap: 1rem; margin-bottom: 1.5rem;'>" ^
                  "<div class='form-group' style='margin: 0;'>" ^
                    "<input type='text' id='users-search' placeholder='Buscar por nome ou e-mail...' style='width: 100%;'>" ^
                  "</div>" ^
                  "<div class='form-group' style='margin: 0;'>" ^
                    "<select id='users-role-filter' style='width: 100%;'>" ^
                      "<option value='all'>Todos</option>" ^
                      "<option value='admin'>Administradores</option>" ^
                      "<option value='user'>Usuários</option>" ^
                    "</select>" ^
                  "</div>" ^
                  "<div class='form-group' style='margin: 0;'>" ^
                    "<select id='users-sort' style='width: 100%;'>" ^
                      "<option value='created_desc'>Mais recentes</option>" ^
                      "<option value='created_asc'>Mais antigos</option>" ^
                      "<option value='name_asc'>Nome: A-Z</option>" ^
                      "<option value='name_desc'>Nome: Z-A</option>" ^
                      "<option value='email_asc'>Email: A-Z</option>" ^
                      "<option value='email_desc'>Email: Z-A</option>" ^
                    "</select>" ^
                  "</div>" ^
                "</div>" ^
              "</div>" ^
              "<div id='users-list-container'>" ^
                all_users_list ^
              "</div>" ^
              "<div id='users-pagination' style='display: flex; justify-content: center; align-items: center; gap: 1rem; margin-top: 2rem;'>" ^
                (match all_users_page with
                 | Some page ->
                     "<button onclick='loadUsers(" ^ string_of_int (page.page - 1) ^ ")' " ^
                     (if page.has_prev then "" else "disabled style='opacity: 0.5; cursor: not-allowed;'") ^
                     " class='btn-outline btn'>Anterior</button>" ^
                     "<span style='color: var(--text-primary);'>Página " ^ string_of_int page.page ^ " de " ^ string_of_int page.total_pages ^ "</span>" ^
                     "<button onclick='loadUsers(" ^ string_of_int (page.page + 1) ^ ")' " ^
                     (if page.has_next then "" else "disabled style='opacity: 0.5; cursor: not-allowed;'") ^
                     " class='btn-outline btn'>Próxima</button>"
                 | None -> "") ^
              "</div>" ^
            "</div>" ^
            (* Utilities tab (admin only) *)
            "<div id='tab-utilities' class='tab-content'>" ^
              "<div style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 2rem; border-radius: 1rem; margin-bottom: 2rem;'>" ^
                "<h3 style='color: var(--text-primary); font-weight: 700; margin: 0 0 1.5rem 0;'>🔧 Utilitários do Sistema</h3>" ^
                "<div style='background: var(--bg-secondary); border: 1px solid var(--border-color); padding: 1.5rem; border-radius: 0.75rem; margin-bottom: 1.5rem;'>" ^
                  "<h4 style='color: var(--text-primary); font-weight: 600; margin: 0 0 1rem 0; display: flex; align-items: center; gap: 0.5rem;'>" ^
                    "<span>🧹</span> <span>Sanitização de Anúncios</span>" ^
                  "</h4>" ^
                  "<p style='color: var(--text-muted); margin: 0 0 1rem 0; line-height: 1.6;'>" ^
                    "Esta ferramenta desativa automaticamente anúncios de terceiros (Localiza, iCarros, Webmotors, etc.) " ^
                    "que não foram atualizados há mais de X dias. Isso garante que apenas anúncios ativos sejam exibidos no sistema." ^
                  "</p>" ^
                  "<div style='background: var(--accent); color: white; padding: 1rem; border-radius: 0.5rem; margin-bottom: 1rem;'>" ^
                    "<div style='display: flex; align-items: start; gap: 0.75rem;'>" ^
                      "<span style='font-size: 1.25rem;'>⏰</span>" ^
                      "<div style='flex: 1;'>" ^
                        "<strong style='display: block; margin-bottom: 0.25rem;'>Execução Automática</strong>" ^
                        "<span style='font-size: 0.875rem; opacity: 0.95;'>Esta tarefa é executada automaticamente todos os dias às 6h da manhã via cron job configurado no Docker.</span>" ^
                      "</div>" ^
                    "</div>" ^
                  "</div>" ^
                  "<div style='margin-bottom: 1rem;'>" ^
                    "<label for='deactivate-days' style='display: block; color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem;'>Número de Dias:</label>" ^
                    "<select id='deactivate-days' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary); font-size: 1rem;'>" ^
                      "<option value='1'>1 dia</option>" ^
                      "<option value='3' selected>3 dias</option>" ^
                      "<option value='5'>5 dias</option>" ^
                      "<option value='7'>7 dias</option>" ^
                      "<option value='10'>10 dias</option>" ^
                      "<option value='15'>15 dias</option>" ^
                      "<option value='30'>30 dias</option>" ^
                    "</select>" ^
                    "<p style='color: var(--text-muted); font-size: 0.875rem; margin-top: 0.5rem;'>Selecione quantos dias sem atualização um anúncio deve ter para ser desativado.</p>" ^
                  "</div>" ^
                  "<button id='deactivate-stale-btn' onclick='deactivateStaleVehicles()' class='btn' style='background: linear-gradient(135deg, var(--accent), var(--accent-hover)); color: white; padding: 0.875rem 1.5rem; border: none; border-radius: 0.5rem; font-weight: 600; cursor: pointer; transition: all 0.2s;'>" ^
                    "Executar Sanitização Agora" ^
                  "</button>" ^
                  "<div id='deactivate-stale-result' style='margin-top: 1rem; display: none;'></div>" ^
                "</div>" ^
                (* Scraper Jobs Management Section *)
                "<div style='background: var(--bg-secondary); border: 1px solid var(--border-color); padding: 1.5rem; border-radius: 0.75rem; margin-top: 2rem;'>" ^
                  "<h4 style='color: var(--text-primary); font-weight: 600; margin: 0 0 1rem 0; display: flex; align-items: center; gap: 0.5rem;'>" ^
                    "<span>🤖</span> <span>Gerenciamento de Scrapers</span>" ^
                  "</h4>" ^
                  "<p style='color: var(--text-muted); margin: 0 0 1.5rem 0; line-height: 1.6;'>" ^
                    "Configure os scrapers que serão executados automaticamente pela app-scrappers. " ^
                    "Cada job define uma marca, modelo e fonte (Localiza, iCarros ou Webmotors) para coleta de dados." ^
                  "</p>" ^
                  
                  (* Filters and New Job Button *)
                  "<div style='display: flex; gap: 1rem; margin-bottom: 1.5rem; flex-wrap: wrap; align-items: flex-end;'>" ^
                    "<div style='flex: 1; min-width: 200px;'>" ^
                      "<label for='scraper-jobs-search' style='display: block; color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem; font-size: 0.875rem;'>Buscar por Marca/Modelo</label>" ^
                      "<input type='text' id='scraper-jobs-search' placeholder='Ex: Toyota Corolla' autocomplete='off' data-lpignore='true' data-form-type='other' spellcheck='false' role='textbox' aria-label='Buscar scraper jobs' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary); font-size: 0.875rem;'>" ^
                    "</div>" ^
                    "<div style='flex: 1; min-width: 200px;'>" ^
                      "<label for='scraper-jobs-source-filter' style='display: block; color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem; font-size: 0.875rem;'>Fonte/Plataforma</label>" ^
                      "<select id='scraper-jobs-source-filter' autocomplete='off' data-lpignore='true' data-form-type='other' role='combobox' aria-label='Filtrar por fonte' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary); font-size: 0.875rem;'>" ^
                        "<option value=''>Todas as fontes</option>" ^
                        "<option value='localiza'>Localiza</option>" ^
                        "<option value='icarros'>iCarros</option>" ^
                        "<option value='webmotors'>Webmotors</option>" ^
                      "</select>" ^
                    "</div>" ^
                    "<button id='create-scraper-job-btn' onclick='openCreateScraperJobModal()' class='btn' style='background: linear-gradient(135deg, var(--accent), var(--accent-hover)); color: white; padding: 0.875rem 1.5rem; border: none; border-radius: 0.5rem; font-weight: 600; cursor: pointer; transition: all 0.2s; white-space: nowrap;'>" ^
                    "+ Novo Scraper Job" ^
                  "</button>" ^
                  "</div>" ^
                  
                  "<div id='scraper-jobs-list' style='display: grid; gap: 1rem;'>" ^
                    "<p style='color: var(--text-muted); text-align: center; padding: 2rem;'>Carregando jobs...</p>" ^
                  "</div>" ^
                  
                  (* Pagination *)
                  "<div id='scraper-jobs-pagination' style='display: flex; justify-content: center; align-items: center; gap: 0.5rem; margin-top: 2rem; flex-wrap: wrap;'>" ^
                    "<span id='scraper-jobs-count' style='color: var(--text-muted); font-size: 0.875rem; margin-right: 1rem;'></span>" ^
                    "<button id='scraper-jobs-prev' type='button' style='padding: 0.5rem 1rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-card); color: var(--text-primary); cursor: pointer; font-size: 0.875rem; transition: all 0.2s;' disabled>‹ Anterior</button>" ^
                    "<span id='scraper-jobs-page-info' style='color: var(--text-primary); font-size: 0.875rem; padding: 0 1rem;'></span>" ^
                    "<button id='scraper-jobs-next' type='button' style='padding: 0.5rem 1rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-card); color: var(--text-primary); cursor: pointer; font-size: 0.875rem; transition: all 0.2s;' disabled>Próximo ›</button>" ^
                  "</div>" ^
                "</div>" ^
              "</div>" ^
            "</div>"
           else "") ^
          (* Edit User Modal (admin only) *)
          (if is_admin then
            "<div id='edit-user-modal' style='display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0, 0, 0, 0.5); z-index: 1000; overflow-y: auto; padding: 2rem;'>" ^
              "<div style='max-width: 600px; margin: 0 auto; background: var(--bg-primary); border-radius: 1rem; padding: 2rem; position: relative;'>" ^
                "<button onclick='closeEditUserModal()' style='position: absolute; top: 1rem; right: 1rem; background: none; border: none; font-size: 1.5rem; color: var(--text-muted); cursor: pointer;'>&times;</button>" ^
                "<h2 style='color: var(--text-primary); font-weight: 700; margin-bottom: 2rem;'>Editar Usuário</h2>" ^
                "<form id='edit-user-form'>" ^
                  "<input type='hidden' id='edit-user-id' name='user_id'>" ^
                  "<div class='form-group'>" ^
                    "<label for='edit-user-name'>Nome Completo</label>" ^
                    "<input type='text' name='name' id='edit-user-name' required>" ^
                  "</div>" ^
                  "<div class='form-group'>" ^
                    "<label for='edit-user-email'>E-mail</label>" ^
                    "<input type='email' name='email' id='edit-user-email' required>" ^
                  "</div>" ^
                  "<div class='form-group'>" ^
                    "<label for='edit-user-phone'>Telefone</label>" ^
                    "<input type='tel' name='phone' id='edit-user-phone' required>" ^
                  "</div>" ^
                  "<div class='form-group'>" ^
                    "<label for='edit-user-document'>CPF/CNPJ</label>" ^
                    "<input type='text' name='document_number' id='edit-user-document' required>" ^
                  "</div>" ^
                  "<h3 style='color: var(--text-primary); font-weight: 700; margin: 2rem 0 1.5rem 0;'>Endereço</h3>" ^
                  "<div class='form-group'>" ^
                    "<label for='edit-user-zipcode'>CEP</label>" ^
                    "<input type='text' name='address_zipcode' id='edit-user-zipcode' required>" ^
                  "</div>" ^
                  "<div class='form-group'>" ^
                    "<label for='edit-user-street'>Rua</label>" ^
                    "<input type='text' name='address_street' id='edit-user-street' required>" ^
                  "</div>" ^
                  "<div style='display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;'>" ^
                    "<div class='form-group'>" ^
                      "<label for='edit-user-number'>Número</label>" ^
                      "<input type='text' name='address_number' id='edit-user-number' required>" ^
                    "</div>" ^
                    "<div class='form-group'>" ^
                      "<label for='edit-user-complement'>Complemento</label>" ^
                      "<input type='text' name='address_complement' id='edit-user-complement'>" ^
                    "</div>" ^
                  "</div>" ^
                  "<div class='form-group'>" ^
                    "<label for='edit-user-neighborhood'>Bairro</label>" ^
                    "<input type='text' name='address_neighborhood' id='edit-user-neighborhood' required>" ^
                  "</div>" ^
                  "<div style='display: grid; grid-template-columns: 2fr 1fr; gap: 1rem;'>" ^
                    "<div class='form-group'>" ^
                      "<label for='edit-user-city'>Cidade</label>" ^
                      "<input type='text' name='address_city' id='edit-user-city' required>" ^
                    "</div>" ^
                    "<div class='form-group'>" ^
                      "<label for='edit-user-state'>Estado</label>" ^
                      "<input type='text' name='address_state' id='edit-user-state' required maxlength='2'>" ^
                    "</div>" ^
                  "</div>" ^
                  "<button type='submit' class='btn' style='margin-top: 1.5rem;'>Salvar Alterações</button>" ^
                "</form>" ^
                "<hr style='margin: 2rem 0; border: none; border-top: 1px solid var(--border-color);'>" ^
                "<h3 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1.5rem;'>Alterar Senha</h3>" ^
                "<form id='edit-user-password-form'>" ^
                  "<input type='hidden' id='edit-user-password-id' name='user_id'>" ^
                  "<div class='form-group'>" ^
                    "<label for='edit-user-new-password'>Nova Senha</label>" ^
                    "<input type='password' name='new_password' id='edit-user-new-password' required placeholder='Mínimo 6 caracteres com 1 caractere especial'>" ^
                    "<small id='edit-user-new-password-error' style='color: #ef4444; font-size: 0.75rem; display: none; margin-top: 0.25rem;'></small>" ^
                    "<small style='color: var(--text-muted); font-size: 0.75rem; display: block; margin-top: 0.25rem;'>Mínimo 6 caracteres com pelo menos 1 caractere especial (!@#$%^&*)</small>" ^
                  "</div>" ^
                  "<div class='form-group'>" ^
                    "<label for='edit-user-confirm-password'>Confirmar Nova Senha</label>" ^
                    "<input type='password' name='confirm_password' id='edit-user-confirm-password' required>" ^
                    "<small id='edit-user-password-match-error' style='color: var(--text-danger, #ef4444); font-size: 0.75rem; display: none; margin-top: 0.5rem;'>As senhas não coincidem</small>" ^
                  "</div>" ^
                  "<button type='submit' class='btn'>Alterar Senha</button>" ^
                "</form>" ^
              "</div>" ^
            "</div>"
           else "") ^
          (* Scraper Job Modal (admin only) *)
          (if is_admin then
            "<div id='scraper-job-modal' style='display: none; position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0, 0, 0, 0.5); z-index: 1000; overflow-y: auto; padding: 2rem;'>" ^
              "<div style='max-width: 600px; margin: 0 auto; background: var(--bg-primary); border-radius: 1rem; padding: 2rem; position: relative;'>" ^
                "<button onclick='closeScraperJobModal()' style='position: absolute; top: 1rem; right: 1rem; background: none; border: none; font-size: 1.5rem; color: var(--text-muted); cursor: pointer;'>&times;</button>" ^
                "<h2 style='color: var(--text-primary); font-weight: 700; margin-bottom: 2rem;' id='scraper-job-modal-title'>Novo Scraper Job</h2>" ^
                "<form id='scraper-job-form'>" ^
                  "<input type='hidden' id='scraper-job-id' name='scraper_job_id'>" ^
                  "<div class='form-group'>" ^
                    "<label for='scraper-job-brand'>Marca *</label>" ^
                    "<input type='text' name='brand' id='scraper-job-brand' required placeholder='Ex: Toyota'>" ^
                  "</div>" ^
                  "<div class='form-group'>" ^
                    "<label for='scraper-job-model'>Modelo *</label>" ^
                    "<input type='text' name='model' id='scraper-job-model' required placeholder='Ex: Corolla Cross'>" ^
                  "</div>" ^
                  "<div class='form-group'>" ^
                    "<label for='scraper-job-source'>Fonte *</label>" ^
                    "<select name='source' id='scraper-job-source' required>" ^
                      "<option value=''>Selecione...</option>" ^
                      "<option value='localiza'>Localiza Seminovos</option>" ^
                      "<option value='icarros'>iCarros</option>" ^
                      "<option value='webmotors'>Webmotors</option>" ^
                    "</select>" ^
                  "</div>" ^
                  "<div class='form-group'>" ^
                    "<label style='display: flex; align-items: center; gap: 0.5rem;'>" ^
                      "<input type='checkbox' name='is_active' id='scraper-job-is-active' checked>" ^
                      "<span>Ativo</span>" ^
                    "</label>" ^
                    "<small style='color: var(--text-muted); font-size: 0.75rem;'>Apenas jobs ativos serão executados pela app-scrappers</small>" ^
                  "</div>" ^
                  "<button type='submit' class='btn' style='width: 100%; margin-top: 1.5rem;'>Salvar</button>" ^
                "</form>" ^
              "</div>" ^
            "</div>"
           else "") ^
        "</div>" ^
      "</div>" ^
      
      "<style>" ^
        ".tab-button { background: none; border: none; padding: 1rem 1.5rem; color: var(--text-muted); cursor: pointer; border-bottom: 2px solid transparent; font-weight: 600; transition: all 0.2s; }" ^
        ".tab-button:hover { color: var(--text-primary); }" ^
        ".tab-button.active { color: var(--accent); border-bottom-color: var(--accent); }" ^
        ".tab-content { display: none; }" ^
        ".tab-content.active { display: block; }" ^
      "</style>" ^

      "<script type='text/javascript'>" ^
        "document.addEventListener('DOMContentLoaded', function() {" ^

          "var currentReferralPage = " ^ (match referral_codes_page with Some p -> string_of_int p.page | None -> "1") ^ ";" ^
          "var currentReferralSearch = '';" ^
          "var currentReferralStatus = 'all';" ^

          "function showTab(tabName) {" ^
            "try {" ^
              "var tabElement = document.getElementById('tab-' + tabName);" ^
              "var buttonElement = document.querySelector('[data-tab-name=\"' + tabName + '\"]') || document.querySelector('[data-tab=\"' + tabName + '\"]');" ^
              "if (!tabElement) {" ^
                "return false;" ^
              "}" ^
              "if (!buttonElement) {" ^
                "return false;" ^
              "}" ^
              "document.querySelectorAll('.tab-content').forEach(function(tab) {" ^
                "tab.classList.remove('active');" ^
              "});" ^
              "document.querySelectorAll('.tab-button').forEach(function(btn) {" ^
                "btn.classList.remove('active');" ^
              "});" ^
              "tabElement.classList.add('active');" ^
              "buttonElement.classList.add('active');" ^
              "sessionStorage.setItem('activeTab', tabName);" ^
              "if (tabName === 'referrals' && typeof loadReferralCodes === 'function') {" ^
                "loadReferralCodes(" ^ (match referral_codes_page with Some p -> string_of_int p.page | None -> "1") ^ ");" ^
              "}" ^
              "return true;" ^
            "} catch (e) {" ^
              "return false;" ^
            "}" ^
          "}" ^
          "window.showTab = showTab;" ^

          "function attachTabListeners() {" ^
            "var buttons = document.querySelectorAll('.tab-button');" ^
            "for (var i = 0; i < buttons.length; i++) {" ^
              "(function(button) {" ^
                "var tabName = button.getAttribute('data-tab-name') || button.getAttribute('data-tab');" ^
                "if (tabName) {" ^
                  "button.addEventListener('click', function(e) {" ^
                    "e.preventDefault();" ^
                    "e.stopPropagation();" ^
                    "e.stopImmediatePropagation();" ^
                    "var clickedTab = button.getAttribute('data-tab-name') || button.getAttribute('data-tab');" ^
                    "if (clickedTab && window.showTab) {" ^
                      "window.showTab(clickedTab);" ^
                    "}" ^
                  "}, true);" ^
                "}" ^
              "})(buttons[i]);" ^
            "}" ^
          "}" ^

          "function initTabs() {" ^
            "try {" ^
              "var savedTab = sessionStorage.getItem('activeTab') || 'vehicles';" ^
              "attachTabListeners();" ^
              "showTab(savedTab);" ^
              "if (savedTab === 'referrals' && typeof loadReferralCodes === 'function') {" ^
                "setTimeout(function() { loadReferralCodes(" ^ (match referral_codes_page with Some p -> string_of_int p.page | None -> "1") ^ "); }, 100);" ^
              "}" ^
            "} catch (e) {}" ^
          "}" ^

          "function fetchDashboardModels(brandName, selectedModel) {" ^
             "var modelSelect = document.getElementById('dashboard-model');" ^
             "if (!modelSelect || !brandName) {" ^
               "if (modelSelect) modelSelect.innerHTML = '<option value=\"\">Todos</option>';" ^
               "return;" ^
             "}" ^
            "fetch('/api/vehicles/models/' + encodeURIComponent(brandName))" ^
              ".then(function(r) { return r.json(); })" ^
              ".then(function(data) {" ^
                "if (data.success && data.data) {" ^
                  "modelSelect.innerHTML = '<option value=\"\">Todos</option>';" ^
                  "var models = data.data.models || [];" ^
                  "models.forEach(function(modelName) {" ^
                    "var option = document.createElement('option');" ^
                    "option.value = modelName;" ^
                    "option.textContent = modelName;" ^
                    "if (selectedModel && modelName === selectedModel) option.selected = true;" ^
                    "modelSelect.appendChild(option);" ^
                  "});" ^
                "}" ^
              "})" ^
              ".catch(function(e) {});" ^
           "}" ^

          "initTabs();" ^

          "var brandSelect = document.getElementById('dashboard-brand');" ^
          "var modelSelect = document.getElementById('dashboard-model');" ^
          "if (brandSelect) {" ^
            "brandSelect.addEventListener('change', function() {" ^
              "var selectedOption = this.selectedOptions[0];" ^
              "var brandName = selectedOption ? selectedOption.value : null;" ^
              "fetchDashboardModels(brandName, null);" ^
            "});" ^
            "var selectedOption = brandSelect.selectedOptions[0];" ^
            "var brandName = selectedOption ? selectedOption.value : null;" ^
            "if (brandName && modelSelect) {" ^
              "fetchDashboardModels(brandName, null);" ^
            "}" ^
          "}" ^

          "var filterForm = document.getElementById('dashboard-vehicle-filters');" ^
          "if (filterForm) {" ^
            "filterForm.addEventListener('submit', function(e) {" ^
              "var pageInput = document.getElementById('filter-page-input');" ^
              "if (pageInput) pageInput.value = '1';" ^
            "});" ^
          "}" ^

          "window.deleteVehicle = function(vehicleId, slug) {" ^
             "if (!confirm('Tem certeza que deseja excluir este anúncio? Esta ação não pode ser desfeita.')) {" ^
               "return false;" ^
             "}" ^
             "var form = document.createElement('form');" ^
             "form.method = 'POST';" ^
             "form.action = '/dashboard/delete/' + vehicleId;" ^
             "form.style.display = 'none';" ^
             "document.body.appendChild(form);" ^
             "form.submit();" ^
             "return false;" ^
           "};" ^

           "window.deactivateStaleVehicles = function() {" ^
             "var btn = document.getElementById('deactivate-stale-btn');" ^
             "var resultDiv = document.getElementById('deactivate-stale-result');" ^
             "var daysSelect = document.getElementById('deactivate-days');" ^
             "if (!btn || !resultDiv || !daysSelect) return;" ^
             "var days = parseInt(daysSelect.value) || 3;" ^
             "var daysText = days === 1 ? '1 dia' : days + ' dias';" ^
             "if (!confirm('Tem certeza que deseja executar a sanitização de anúncios agora? Esta ação desativará todos os anúncios de terceiros que não foram atualizados há mais de ' + daysText + '.')) {" ^
               "return;" ^
             "}" ^
             "btn.disabled = true;" ^
             "btn.textContent = 'Executando...';" ^
             "resultDiv.style.display = 'none';" ^
             "fetch('/api/maintenance/deactivate-stale-vehicles', {" ^
               "method: 'POST'," ^
               "credentials: 'include'," ^
               "headers: { 'Content-Type': 'application/json' }," ^
               "body: JSON.stringify({ days: days })" ^
             "})" ^
             ".then(function(response) { return response.json(); })" ^
             ".then(function(data) {" ^
               "btn.disabled = false;" ^
               "btn.textContent = 'Executar Sanitização Agora';" ^
               "resultDiv.style.display = 'block';" ^
               "if (data.success) {" ^
                 "resultDiv.innerHTML = '<div style=\"background: var(--accent); color: white; padding: 1rem; border-radius: 0.5rem; margin-top: 1rem;\">' +" ^
                   "'<strong>✓ Sucesso!</strong><br>' +" ^
                   "(data.message || ('Foram desativados ' + data.data.deactivated_count + ' veículo(s) de terceiros que não foram atualizados há mais de ' + daysText + '.')) +" ^
                   "'</div>';" ^
               "} else {" ^
                 "resultDiv.innerHTML = '<div style=\"background: #ef4444; color: white; padding: 1rem; border-radius: 0.5rem; margin-top: 1rem;\">' +" ^
                   "'<strong>✗ Erro:</strong> ' + (data.message || 'Erro desconhecido') +" ^
                   "'</div>';" ^
               "}" ^
             "})" ^
             ".catch(function(error) {" ^
               "btn.disabled = false;" ^
               "btn.textContent = 'Executar Sanitização Agora';" ^
               "resultDiv.style.display = 'block';" ^
               "resultDiv.innerHTML = '<div style=\"background: #ef4444; color: white; padding: 1rem; border-radius: 0.5rem; margin-top: 1rem;\">' +" ^
                 "'<strong>✗ Erro:</strong> Não foi possível executar a sanitização. Tente novamente mais tarde.' +" ^
                 "'</div>';" ^
               "console.error('Error:', error);" ^
             "});" ^
           "};" ^

           "if (!window.scraperJobsState) {" ^
             "window.scraperJobsState = {page: 1, perPage: 10, search: '', source: '', totalPages: 1, totalCount: 0};" ^
           "}" ^

           "window.loadScraperJobs = function(page) {" ^
             "try {" ^
               "var state = window.scraperJobsState || {page: 1, perPage: 10, search: '', source: '', totalPages: 1, totalCount: 0};" ^
               "if (typeof page === 'number') {" ^
                 "state.page = page;" ^
               "}" ^
               "var params = new URLSearchParams();" ^
               "params.append('page', String(state.page || 1));" ^
               "params.append('per_page', String(state.perPage || 10));" ^
               "if (state.search) {" ^
                 "params.append('search', state.search);" ^
               "}" ^
               "if (state.source) {" ^
                 "params.append('source', state.source);" ^
               "}" ^
               "var url = '/api/scraper-jobs?' + params.toString();" ^
               "fetch(url, {credentials: 'include', method: 'GET', headers: {'Accept': 'application/json'}})" ^
               ".then(function(response) {" ^
                 "if (!response.ok) throw new Error('Network response was not ok');" ^
                 "return response.json();" ^
               "})" ^
               ".then(function(data) {" ^
                 "try {" ^
                   "var listDiv = document.getElementById('scraper-jobs-list');" ^
                   "var paginationDiv = document.getElementById('scraper-jobs-pagination');" ^
                   "var countSpan = document.getElementById('scraper-jobs-count');" ^
                   "var pageInfoSpan = document.getElementById('scraper-jobs-page-info');" ^
                   "var prevBtn = document.getElementById('scraper-jobs-prev');" ^
                   "var nextBtn = document.getElementById('scraper-jobs-next');" ^
                   "if (!listDiv) return;" ^
                   "if (data && data.success && data.data) {" ^
                     "var resp = data.data;" ^
                     "var jobs = resp.jobs || [];" ^
                     "if (!window.scraperJobsState) {" ^
                       "window.scraperJobsState = {page: 1, perPage: 10, search: '', source: '', totalPages: 1, totalCount: 0};" ^
                     "}" ^
                     "window.scraperJobsState.totalCount = resp.total_count || 0;" ^
                     "window.scraperJobsState.totalPages = resp.total_pages || 1;" ^
                     "window.scraperJobsState.page = resp.page || 1;" ^
                     "if (jobs.length > 0) {" ^
                       "listDiv.innerHTML = jobs.map(function(job) {" ^
                         "var statusBadge = job.is_active ? " ^
                           "'<span style=\"background: var(--accent); color: white; padding: 0.25rem 0.75rem; border-radius: 0.25rem; font-size: 0.75rem; font-weight: 600;\">Ativo</span>' : " ^
                           "'<span style=\"background: #6b7280; color: white; padding: 0.25rem 0.75rem; border-radius: 0.25rem; font-size: 0.75rem; font-weight: 600;\">Inativo</span>';" ^
                         "var lastRun = job.last_run_at ? new Date(job.last_run_at).toLocaleString('pt-BR') : 'Nunca';" ^
                         "return '<div style=\"background: var(--bg-card); border: 1px solid var(--border-color); padding: 1.5rem; border-radius: 0.75rem; display: flex; justify-content: space-between; align-items: start; gap: 1rem;\">' +" ^
                           "'<div style=\"flex: 1;\">' +" ^
                             "'<div style=\"display: flex; align-items: center; gap: 0.75rem; margin-bottom: 0.5rem;\">' +" ^
                               "'<h5 style=\"color: var(--text-primary); font-weight: 700; margin: 0; font-size: 1.125rem;\">' + (job.brand || '') + ' ' + (job.model || '') + '</h5>' + statusBadge +" ^
                             "'</div>' +" ^
                             "'<p style=\"color: var(--text-muted); margin: 0.25rem 0; font-size: 0.875rem;\">Fonte: <strong>' + (job.source ? job.source.charAt(0).toUpperCase() + job.source.slice(1) : '') + '</strong></p>' +" ^
                             "'<p style=\"color: var(--text-muted); margin: 0.25rem 0; font-size: 0.875rem;\">Última execução: ' + lastRun + '</p>' +" ^
                             "'<p style=\"color: var(--text-muted); margin: 0.25rem 0; font-size: 0.875rem;\">Execuções: ' + (job.run_count || 0) + ' | Sucessos: ' + (job.success_count || 0) + ' | Erros: ' + (job.error_count || 0) + '</p>' +" ^
                           "'</div>' +" ^
                           "'<div style=\"display: flex; gap: 0.5rem;\">' +" ^
                             "'<button onclick=\"if(window.editScraperJob){window.editScraperJob(' + (job.scraper_job_id || 0) + ');}\" style=\"background: var(--accent); color: white; padding: 0.5rem 1rem; border: none; border-radius: 0.5rem; cursor: pointer; font-size: 0.875rem;\">Editar</button>' +" ^
                             "'<button onclick=\"if(window.deleteScraperJob){window.deleteScraperJob(' + (job.scraper_job_id || 0) + ');}\" style=\"background: #ef4444; color: white; padding: 0.5rem 1rem; border: none; border-radius: 0.5rem; cursor: pointer; font-size: 0.875rem;\">Excluir</button>' +" ^
                           "'</div>' +" ^
                         "'</div>';" ^
                       "}).join('');" ^
                     "} else {" ^
                       "listDiv.innerHTML = '<p style=\"color: var(--text-muted); text-align: center; padding: 2rem;\">Nenhum scraper job encontrado com os filtros aplicados.</p>';" ^
                     "}" ^
                     "if (paginationDiv) {" ^
                       "var st = window.scraperJobsState;" ^
                       "var startIdx = ((st.page - 1) * st.perPage) + 1;" ^
                       "var endIdx = Math.min(st.page * st.perPage, st.totalCount);" ^
                       "if (countSpan) {" ^
                         "countSpan.textContent = 'Total: ' + st.totalCount + ' | Mostrando ' + (st.totalCount > 0 ? startIdx : 0) + '-' + endIdx;" ^
                       "}" ^
                       "if (pageInfoSpan) {" ^
                         "pageInfoSpan.textContent = 'Página ' + st.page + ' de ' + st.totalPages;" ^
                       "}" ^
                       "if (prevBtn) {" ^
                         "prevBtn.disabled = !resp.has_prev;" ^
                         "prevBtn.style.opacity = resp.has_prev ? '1' : '0.5';" ^
                         "prevBtn.style.cursor = resp.has_prev ? 'pointer' : 'not-allowed';" ^
                       "}" ^
                       "if (nextBtn) {" ^
                         "nextBtn.disabled = !resp.has_next;" ^
                         "nextBtn.style.opacity = resp.has_next ? '1' : '0.5';" ^
                         "nextBtn.style.cursor = resp.has_next ? 'pointer' : 'not-allowed';" ^
                       "}" ^
                     "}" ^
                   "} else {" ^
                     "if (listDiv) {" ^
                       "listDiv.innerHTML = '<p style=\"color: var(--text-muted); text-align: center; padding: 2rem;\">Nenhum scraper job configurado. Clique em \"Novo Scraper Job\" para criar um.</p>';" ^
                     "}" ^
                     "if (countSpan) countSpan.textContent = '';" ^
                     "if (pageInfoSpan) pageInfoSpan.textContent = '';" ^
                     "if (prevBtn) prevBtn.disabled = true;" ^
                     "if (nextBtn) nextBtn.disabled = true;" ^
                   "}" ^
                 "} catch(e) {" ^
                   "console.error('Error updating UI:', e);" ^
                 "}" ^
               "})" ^
               ".catch(function(error) {" ^
                 "console.error('Error loading scraper jobs:', error);" ^
                 "var listDiv = document.getElementById('scraper-jobs-list');" ^
                 "if (listDiv) {" ^
                   "listDiv.innerHTML = '<p style=\"color: #ef4444; text-align: center; padding: 2rem;\">Erro ao carregar scraper jobs. Tente recarregar a página.</p>';" ^
                 "}" ^
               "});" ^
             "} catch(e) {" ^
               "console.error('Error in loadScraperJobs:', e);" ^
             "}" ^
           "};" ^

           "window.scraperJobsPrevPage = function() {" ^
             "if (!window.scraperJobsState) {" ^
               "window.scraperJobsState = {page: 1, perPage: 10, search: '', source: '', totalPages: 1, totalCount: 0};" ^
             "}" ^
             "var st = window.scraperJobsState;" ^
             "if (st.page > 1 && window.loadScraperJobs) {" ^
               "window.loadScraperJobs(st.page - 1);" ^
             "}" ^
           "};" ^

           "window.scraperJobsNextPage = function() {" ^
             "if (!window.scraperJobsState) {" ^
               "window.scraperJobsState = {page: 1, perPage: 10, search: '', source: '', totalPages: 1, totalCount: 0};" ^
             "}" ^
             "var st = window.scraperJobsState;" ^
             "if (st.page < st.totalPages && window.loadScraperJobs) {" ^
               "window.loadScraperJobs(st.page + 1);" ^
             "}" ^
           "};" ^

           "window.setupScraperJobsListeners = function() {" ^
             "var searchInput = document.getElementById('scraper-jobs-search');" ^
             "var sourceFilter = document.getElementById('scraper-jobs-source-filter');" ^
             "var prevBtn = document.getElementById('scraper-jobs-prev');" ^
             "var nextBtn = document.getElementById('scraper-jobs-next');" ^
             "if (!searchInput || !sourceFilter) return false;" ^
             "try {" ^
               "searchInput.setAttribute('autocomplete', 'off');" ^
               "searchInput.setAttribute('data-lpignore', 'true');" ^
               "searchInput.setAttribute('data-form-type', 'other');" ^
               "searchInput.setAttribute('spellcheck', 'false');" ^
               "sourceFilter.setAttribute('autocomplete', 'off');" ^
               "sourceFilter.setAttribute('data-lpignore', 'true');" ^
               "sourceFilter.setAttribute('data-form-type', 'other');" ^
               "var preventExtensionInterference = function(e) {" ^
                 "try {" ^
                   "if (e.target && (e.target.id === 'scraper-jobs-search' || e.target.id === 'scraper-jobs-source-filter')) {" ^
                     "try {" ^
                       "Object.defineProperty(e.target, 'control', {value: null, writable: false, configurable: false});" ^
                     "} catch(err) {}" ^
                   "}" ^
                 "} catch(err) {}" ^
               "};" ^
               "searchInput.addEventListener('focus', preventExtensionInterference, true);" ^
               "sourceFilter.addEventListener('focus', preventExtensionInterference, true);" ^
             "} catch(err) {}" ^
             "var applyFilters = function() {" ^
               "if (!window.scraperJobsState) {" ^
                 "window.scraperJobsState = {page: 1, perPage: 10, search: '', source: '', totalPages: 1, totalCount: 0};" ^
               "}" ^
               "window.scraperJobsState.search = (searchInput.value || '').trim();" ^
               "window.scraperJobsState.source = (sourceFilter.value || '').trim();" ^
               "window.scraperJobsState.page = 1;" ^
               "if (window.loadScraperJobs) {" ^
                 "window.loadScraperJobs();" ^
               "}" ^
             "};" ^
             "var searchTimeout = null;" ^
             "var inputHandler = function(e) {" ^
               "e.stopPropagation();" ^
               "e.stopImmediatePropagation();" ^
               "if (searchTimeout) clearTimeout(searchTimeout);" ^
               "searchTimeout = setTimeout(applyFilters, 500);" ^
             "};" ^
             "var changeHandler = function(e) {" ^
               "e.stopPropagation();" ^
               "e.stopImmediatePropagation();" ^
               "applyFilters();" ^
             "};" ^
             "var prevHandler = function(e) {" ^
               "e.stopPropagation();" ^
               "e.stopImmediatePropagation();" ^
               "e.preventDefault();" ^
               "if (window.scraperJobsPrevPage) {" ^
                 "window.scraperJobsPrevPage();" ^
               "}" ^
             "};" ^
             "var nextHandler = function(e) {" ^
               "e.stopPropagation();" ^
               "e.stopImmediatePropagation();" ^
               "e.preventDefault();" ^
               "if (window.scraperJobsNextPage) {" ^
                 "window.scraperJobsNextPage();" ^
               "}" ^
             "};" ^
             "searchInput.removeEventListener('input', inputHandler, true);" ^
             "searchInput.addEventListener('input', inputHandler, true);" ^
             "sourceFilter.removeEventListener('change', changeHandler, true);" ^
             "sourceFilter.addEventListener('change', changeHandler, true);" ^
             "if (prevBtn) {" ^
               "prevBtn.removeEventListener('click', prevHandler, true);" ^
               "prevBtn.addEventListener('click', prevHandler, true);" ^
             "}" ^
             "if (nextBtn) {" ^
               "nextBtn.removeEventListener('click', nextHandler, true);" ^
               "nextBtn.addEventListener('click', nextHandler, true);" ^
             "}" ^
             "return true;" ^
           "};" ^

           "window.openCreateScraperJobModal = function() {" ^
             "document.getElementById('scraper-job-id').value = '';" ^
             "document.getElementById('scraper-job-modal-title').textContent = 'Novo Scraper Job';" ^
             "document.getElementById('scraper-job-brand').value = '';" ^
             "document.getElementById('scraper-job-model').value = '';" ^
             "document.getElementById('scraper-job-source').value = '';" ^
             "document.getElementById('scraper-job-is-active').checked = true;" ^
             "document.getElementById('scraper-job-modal').style.display = 'block';" ^
           "};" ^

           "window.closeScraperJobModal = function() {" ^
             "document.getElementById('scraper-job-modal').style.display = 'none';" ^
           "};" ^

           "window.editScraperJob = function(jobId) {" ^
             "fetch('/api/scraper-jobs/' + jobId, { credentials: 'include' })" ^
             ".then(function(response) { return response.json(); })" ^
             ".then(function(data) {" ^
               "if (data.success && data.data) {" ^
                 "var job = data.data;" ^
                 "document.getElementById('scraper-job-id').value = job.scraper_job_id;" ^
                 "document.getElementById('scraper-job-modal-title').textContent = 'Editar Scraper Job';" ^
                 "document.getElementById('scraper-job-brand').value = job.brand;" ^
                 "document.getElementById('scraper-job-model').value = job.model;" ^
                 "document.getElementById('scraper-job-source').value = job.source;" ^
                 "document.getElementById('scraper-job-is-active').checked = job.is_active;" ^
                 "document.getElementById('scraper-job-modal').style.display = 'block';" ^
               "}" ^
             "})" ^
             ".catch(function(error) {" ^
               "console.error('Error loading scraper job:', error);" ^
               "alert('Erro ao carregar scraper job');" ^
             "});" ^
           "};" ^

           "window.deleteScraperJob = function(jobId) {" ^
             "if (!confirm('Tem certeza que deseja excluir este scraper job?')) return;" ^
             "fetch('/api/scraper-jobs/' + jobId, {" ^
               "method: 'DELETE'," ^
               "credentials: 'include'" ^
             "})" ^
             ".then(function(response) { return response.json(); })" ^
             ".then(function(data) {" ^
               "if (data.success) {" ^
                 "window.loadScraperJobs();" ^
                 "alert('Scraper job excluído com sucesso');" ^
               "} else {" ^
                 "alert('Erro: ' + (data.message || 'Erro desconhecido'));" ^
               "}" ^
             "})" ^
             ".catch(function(error) {" ^
               "console.error('Error deleting scraper job:', error);" ^
               "alert('Erro ao excluir scraper job');" ^
             "});" ^
           "};" ^

           "var scraperJobForm = document.getElementById('scraper-job-form');" ^
           "if (scraperJobForm) {" ^
             "scraperJobForm.addEventListener('submit', function(e) {" ^
               "e.preventDefault();" ^
               "var jobId = document.getElementById('scraper-job-id').value;" ^
               "var brand = document.getElementById('scraper-job-brand').value;" ^
               "var model = document.getElementById('scraper-job-model').value;" ^
               "var source = document.getElementById('scraper-job-source').value;" ^
               "var isActive = document.getElementById('scraper-job-is-active').checked;" ^
               "if (!brand || !model || !source) {" ^
                 "alert('Por favor, preencha todos os campos obrigatórios');" ^
                 "return;" ^
               "}" ^
               "var url = '/api/scraper-jobs';" ^
               "var method = 'POST';" ^
               "if (jobId) {" ^
                 "url = '/api/scraper-jobs/' + jobId;" ^
                 "method = 'PUT';" ^
               "}" ^
               "fetch(url, {" ^
                 "method: method," ^
                 "credentials: 'include'," ^
                 "headers: { 'Content-Type': 'application/json' }," ^
                 "body: JSON.stringify({ brand: brand, model: model, source: source, is_active: isActive })" ^
               "})" ^
               ".then(function(response) { return response.json(); })" ^
               ".then(function(data) {" ^
                 "if (data.success) {" ^
                   "window.closeScraperJobModal();" ^
                   "window.loadScraperJobs();" ^
                   "alert('Scraper job salvo com sucesso');" ^
                 "} else {" ^
                   "alert('Erro: ' + (data.message || 'Erro desconhecido'));" ^
                 "}" ^
               "})" ^
               ".catch(function(error) {" ^
                 "console.error('Error saving scraper job:', error);" ^
                 "alert('Erro ao salvar scraper job');" ^
               "});" ^
             "});" ^
           "}" ^

           "var originalShowTab = window.showTab;" ^
           "window.showTab = function(tabName) {" ^
             "if (originalShowTab && typeof originalShowTab === 'function') {" ^
               "originalShowTab(tabName);" ^
             "}" ^
             "if (tabName === 'utilities') {" ^
               "var initScraperTab = function() {" ^
                 "var searchInput = document.getElementById('scraper-jobs-search');" ^
                 "var sourceFilter = document.getElementById('scraper-jobs-source-filter');" ^
                 "if (searchInput && sourceFilter) {" ^
                   "if (window.setupScraperJobsListeners) {" ^
                     "window.setupScraperJobsListeners();" ^
                   "}" ^
                   "if (window.loadScraperJobs) {" ^
                     "window.loadScraperJobs();" ^
                   "}" ^
                 "} else {" ^
                   "setTimeout(initScraperTab, 100);" ^
                 "}" ^
               "};" ^
               "setTimeout(initScraperTab, 100);" ^
             "}" ^
           "};" ^

          (* ---------------- Referral codes ---------------- *)

          "function loadReferralCodes(page) {" ^
          "var searchEl = document.getElementById('referral-code-search');" ^
          "var statusEl = document.getElementById('referral-code-status-filter');" ^
          "var search = (searchEl && searchEl.value) ? searchEl.value : '';" ^
          "var status = (statusEl && statusEl.value) ? statusEl.value : 'all';" ^
          "currentReferralPage = page;" ^
          "currentReferralSearch = search;" ^
          "currentReferralStatus = status;" ^
          "var params = new URLSearchParams();" ^
          "params.set('page', page.toString());" ^
          "params.set('per_page', '5');" ^
          "params.set('search', search);" ^
          "params.set('status', status);" ^
          "fetch('/api/referral-codes?' + params.toString())" ^
            ".then(function(response) { return response.json(); })" ^
            ".then(function(data) {" ^
              "if (data.success) {" ^
                "var codes = data.data.codes;" ^
                "var container = document.getElementById('referral-codes-list-container');" ^
                "var countEl = document.getElementById('referral-codes-count');" ^
                "var paginationEl = document.getElementById('referral-codes-pagination');" ^
                "if (codes.length === 0) {" ^
                  "container.innerHTML = '<div style=\\'text-align: center; padding: 4rem; color: var(--text-muted);\\'><h3>Nenhum código encontrado</h3></div>';" ^
                "} else {" ^
                  "container.innerHTML = codes.map(function(code) {" ^
                    "var status = !code.is_active ? " ^
                      "'<span style=\\'color: var(--text-muted); font-weight: 600;\\'>Desativado</span>' : " ^
                      "(code.used_by_user_id ? " ^
                        "'<span style=\\'color: #ef4444; font-weight: 600;\\'>Usado' + (code.used_by_user_name ? ' por ' + code.used_by_user_name : '') + '</span>' : " ^
                        "'<span style=\\'color: var(--accent); font-weight: 600;\\'>Disponível</span>');" ^
                    "var deactivateBtn = '';" ^
                    (if is_admin then
                      "if (code.is_active) { deactivateBtn = '<button onclick=\\'deactivateCode(' + code.referral_code_id + ')\\' class=\\'btn-outline btn\\' style=\\'margin-left: 0.5rem; font-size: 0.75rem; padding: 0.25rem 0.75rem;\\'>Desativar</button>'; }"
                    else "") ^
                    "return '<div class=\\'referral-code-item\\' style=\\'background: var(--bg-card); border: 1px solid var(--border-color); padding: 1.5rem; border-radius: 0.75rem; margin-bottom: 1rem;\\'>' +" ^
                      "'<div style=\\'display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem;\\'>' +" ^
                        "'<div>' +" ^
                          "'<div style=\\'font-weight: 700; color: var(--text-primary); font-size: 1.1rem; margin-bottom: 0.25rem;\\'>' + code.code + '</div>' +" ^
                          "'<div style=\\'color: var(--text-muted); font-size: 0.875rem;\\'>Criado em ' + code.created_at + '</div>' +" ^
                        "'</div>' +" ^
                        "'<div style=\\'text-align: right;\\'>' + status + deactivateBtn + '</div>' +" ^
                      "'</div>' +" ^
                    "'</div>';" ^
                  "}).join('');" ^
                "}" ^
                "countEl.textContent = data.data.total_count + ' código(s)';" ^
                "paginationEl.innerHTML = " ^
                  "(data.data.has_prev ? '<button onclick=\\'loadReferralCodes(' + (data.data.page - 1) + ')\\' class=\\'btn-outline btn\\'>Anterior</button>' : '<button disabled style=\\'opacity: 0.5; cursor: not-allowed;\\' class=\\'btn-outline btn\\'>Anterior</button>') +" ^
                  "'<span style=\\'color: var(--text-primary);\\'>Página ' + data.data.page + ' de ' + data.data.total_pages + '</span>' +" ^
                  "(data.data.has_next ? '<button onclick=\\'loadReferralCodes(' + (data.data.page + 1) + ')\\' class=\\'btn-outline btn\\'>Próxima</button>' : '<button disabled style=\\'opacity: 0.5; cursor: not-allowed;\\' class=\\'btn-outline btn\\'>Próxima</button>');" ^
              "} else {" ^
                "alert('Erro ao carregar códigos: ' + data.message);" ^
              "}" ^
            "})" ^
            ".catch(function(err) { alert('Erro ao carregar códigos: ' + err.message); });" ^
          "}" ^

          "window.loadReferralCodes = loadReferralCodes;" ^

        (* listeners referral search/status *)
        "var searchInput = document.getElementById('referral-code-search');" ^
        "if (searchInput) {" ^
          "searchInput.addEventListener('input', function() {" ^
            "clearTimeout(this.searchTimeout);" ^
            "this.searchTimeout = setTimeout(function() { loadReferralCodes(1); }, 500);" ^
          "});" ^
        "}" ^
        "var statusFilter = document.getElementById('referral-code-status-filter');" ^
        "if (statusFilter) {" ^
          "statusFilter.addEventListener('change', function() {" ^
            "loadReferralCodes(1);" ^
          "});" ^
        "}" ^

        (if is_admin then
          (* distribute codes / deactivate all / create code / deactivate single code... *)
          "var distributeForm = document.getElementById('distribute-codes-form');" ^
          "if (distributeForm) {" ^
            "distributeForm.addEventListener('submit', function(e) {" ^
              "e.preventDefault();" ^
              "var emailInput = document.getElementById('distribute-email');" ^
              "var countInput = document.getElementById('distribute-count');" ^
              "var email = emailInput.value.trim();" ^
              "var count = parseInt(countInput.value) || 1;" ^
              "if (count < 1 || count > 10) {" ^
                "alert('A quantidade deve ser entre 1 e 10');" ^
                "return;" ^
              "}" ^
              "var body = email === '' || email.toLowerCase() === 'all' ? " ^
                "JSON.stringify({ count: count }) : " ^
                "JSON.stringify({ email: email, count: count });" ^
              "var targetMsg = email === '' || email.toLowerCase() === 'all' ? 'todos os usuários' : 'o usuário ' + email;" ^
              "if (!confirm('Tem certeza que deseja distribuir ' + count + ' código(s) para ' + targetMsg + '?')) {" ^
                "return;" ^
              "}" ^
              "fetch('/api/referral-codes/distribute', {" ^
                "method: 'POST'," ^
                "headers: { 'Content-Type': 'application/json' }," ^
                "body: body" ^
              "})" ^
              ".then(function(response) { return response.json(); })" ^
              ".then(function(data) { " ^
                "if (data.success) { " ^
                  "var message = 'Convites distribuídos com sucesso!\\n';" ^
                  "if (data.data.codes_by_user) {" ^
                    "message += 'Total de usuários: ' + data.data.total_users + '\\n';" ^
                    "message += 'Códigos por usuário: ' + data.data.codes_per_user + '\\n';" ^
                    "message += 'Total de códigos criados: ' + data.data.total_codes;" ^
                  "} else if (data.data.codes) {" ^
                    "message += 'Códigos criados: ' + data.data.codes.join(', ');" ^
                  "}" ^
                  "alert(message);" ^
                  "emailInput.value = '';" ^
                  "countInput.value = '1';" ^
                  "loadReferralCodes(1);" ^
                "} else { " ^
                  "alert(data.message);" ^
                "} " ^
              "})" ^
              ".catch(function(err) { alert('Erro ao distribuir convites: ' + err.message); });" ^
            "});" ^
          "}" ^

          "var deactivateAllBtn = document.getElementById('deactivate-all-codes-btn');" ^
          "if (deactivateAllBtn) {" ^
            "deactivateAllBtn.addEventListener('click', function() {" ^
              "if (!confirm('Tem certeza que deseja desativar TODOS os códigos de acesso? Esta ação não pode ser desfeita.')) {" ^
                "return;" ^
              "}" ^
              "fetch('/api/referral-codes/deactivate-all', {" ^
                "method: 'POST'," ^
                "headers: { 'Content-Type': 'application/json' }" ^
              "})" ^
              ".then(function(response) { return response.json(); })" ^
              ".then(function(data) { " ^
                "if (data.success) { " ^
                  "var total = (data.data && data.data.total_deactivated) ? data.data.total_deactivated : 0;" ^
                  "alert('Todos os códigos foram desativados! Total: ' + total); " ^
                  "loadReferralCodes(1); " ^
                "} else { " ^
                  "alert(data.message); " ^
                "} " ^
              "})" ^
              ".catch(function(err) { alert('Erro ao desativar códigos: ' + err.message); });" ^
            "});" ^
          "}" ^

          "function deactivateCode(codeId) {" ^
            "if (confirm('Tem certeza que deseja desativar este código?')) {" ^
              "fetch('/api/referral-codes/' + codeId + '/deactivate', { method: 'POST', headers: { 'Content-Type': 'application/json' } })" ^
                ".then(function(response) { return response.json(); })" ^
                ".then(function(data) { " ^
                  "if (data.success) { " ^
                    "loadReferralCodes(currentReferralPage); " ^
                  "} else { " ^
                    "alert(data.message); " ^
                  "} " ^
                "});" ^
            "}" ^
          "}" ^
          "window.deactivateCode = deactivateCode;" ^

          "var createCodeForm = document.getElementById('create-code-form');" ^
          "if (createCodeForm) {" ^
            "createCodeForm.addEventListener('submit', function(e) {" ^
              "e.preventDefault();" ^
              "var codeInput = document.getElementById('new-code');" ^
              "var code = codeInput.value.trim();" ^
              "var body = code === '' ? '{}' : JSON.stringify({ code: code });" ^
              "fetch('/api/referral-codes', {" ^
                "method: 'POST'," ^
                "headers: { 'Content-Type': 'application/json' }," ^
                "body: body" ^
              "})" ^
              ".then(function(response) { return response.json(); })" ^
              ".then(function(data) { " ^
                "if (data.success) { " ^
                  "alert('Código criado: ' + data.data.code); " ^
                  "codeInput.value = ''; " ^
                  "loadReferralCodes(1); " ^
                "} else { " ^
                  "alert(data.message); " ^
                "} " ^
              "})" ^
              ".catch(function(err) { alert('Erro ao criar código: ' + err.message); });" ^
            "});" ^
          "}"
         else "") ^

        (* ---------------- Change password (user) ---------------- *)

        "function validatePassword(password) {" ^
          "if (password.length < 6) {" ^
            "return { valid: false, message: 'A senha deve ter no mínimo 6 caracteres' };" ^
          "}" ^
          "var specialChars = /[!@#$%^&*(),.?\":{}|<>]/;" ^
          "if (!specialChars.test(password)) {" ^
            "return { valid: false, message: 'A senha deve conter pelo menos 1 caractere especial (!@#$%^&*)' };" ^
          "}" ^
          "return { valid: true };" ^
        "}" ^

        "if (document.getElementById('change-password-form')) {" ^
          "document.getElementById('change-password-form').addEventListener('submit', function(e) {" ^
          "e.preventDefault();" ^
          "var oldPassword = document.getElementById('old-password').value;" ^
          "var newPassword = document.getElementById('new-password').value;" ^
          "var confirmPassword = document.getElementById('confirm-password').value;" ^
          "var passwordError = document.getElementById('new-password-error');" ^
          "var matchError = document.getElementById('password-match-error');" ^
          "var isValid = true;" ^

          "var passwordValidation = validatePassword(newPassword);" ^
          "if (!passwordValidation.valid) {" ^
            "if (passwordError) {" ^
              "passwordError.textContent = passwordValidation.message;" ^
              "passwordError.style.display = 'block';" ^
            "}" ^
            "isValid = false;" ^
          "} else {" ^
            "if (passwordError) passwordError.style.display = 'none';" ^
          "}" ^

          "if (newPassword !== confirmPassword) {" ^
            "if (matchError) {" ^
              "matchError.style.display = 'block';" ^
            "}" ^
            "isValid = false;" ^
          "} else {" ^
            "if (matchError) matchError.style.display = 'none';" ^
          "}" ^

          "if (!isValid) return;" ^

          "fetch('/api/auth/change-password', {" ^
            "method: 'POST'," ^
            "headers: { 'Content-Type': 'application/json' }," ^
            "body: JSON.stringify({ old_password: oldPassword, new_password: newPassword })" ^
          "})" ^
          ".then(function(response) { return response.json(); })" ^
          ".then(function(result) { " ^
            "if (result.success) { " ^
              "alert('Senha alterada com sucesso!'); " ^
              "document.getElementById('change-password-form').reset(); " ^
            "} else { " ^
              "alert(result.message); " ^
            "} " ^
          "})" ^
          ".catch(function(err) { alert('Erro ao alterar senha: ' + err.message); });" ^
        "});" ^
        "}" ^

        "if (document.getElementById('new-password')) {" ^
          "var newPasswordInput = document.getElementById('new-password');" ^
          "var passwordError = document.getElementById('new-password-error');" ^
          "newPasswordInput.addEventListener('blur', function() {" ^
            "var validation = validatePassword(this.value);" ^
            "if (!validation.valid && this.value) {" ^
              "if (passwordError) {" ^
                "passwordError.textContent = validation.message;" ^
                "passwordError.style.display = 'block';" ^
              "}" ^
            "} else {" ^
              "if (passwordError) passwordError.style.display = 'none';" ^
            "}" ^
          "});" ^
          "newPasswordInput.addEventListener('input', function() {" ^
            "var matchError = document.getElementById('password-match-error');" ^
            "var confirmPassword = document.getElementById('confirm-password');" ^
            "if (passwordError && passwordError.style.display === 'block') {" ^
              "var validation = validatePassword(this.value);" ^
              "if (validation.valid) {" ^
                "passwordError.style.display = 'none';" ^
              "}" ^
            "}" ^
            "if (this.value !== confirmPassword.value) {" ^
              "if (matchError) matchError.style.display = 'block';" ^
            "} else {" ^
              "if (matchError) matchError.style.display = 'none';" ^
            "}" ^
          "});" ^
        "}" ^

        "if (document.getElementById('confirm-password')) {" ^
          "document.getElementById('confirm-password').addEventListener('input', function() {" ^
            "var errorMsg = document.getElementById('password-match-error');" ^
            "if (this.value !== document.getElementById('new-password').value) {" ^
              "errorMsg.style.display = 'block';" ^
            "} else {" ^
              "errorMsg.style.display = 'none';" ^
            "}" ^
          "});" ^
        "}" ^

        (* ---------------- User info update ---------------- *)

        "if (document.getElementById('user-info-form')) {" ^
          "document.getElementById('user-info-form').addEventListener('submit', function(e) {" ^
          "e.preventDefault();" ^
          "var formData = new FormData(this);" ^
          "var data = Object.fromEntries(formData);" ^
          "fetch('/api/auth/me', {" ^
            "method: 'PUT'," ^
            "headers: { 'Content-Type': 'application/json' }," ^
            "body: JSON.stringify(data)" ^
          "})" ^
          ".then(function(response) { return response.json(); })" ^
          ".then(function(result) { " ^
            "if (result.success) { " ^
              "alert('Informações atualizadas!'); " ^
              "sessionStorage.setItem('activeTab', 'info'); " ^
              "location.reload(); " ^
            "} else { " ^
              "alert(result.message); " ^
            "} " ^
          "});" ^
          "});" ^
        "}" ^

        (* CEP autocomplete no modal de edição (admin) *)
        "var editZipcode = document.getElementById('edit-zipcode');" ^
        "if (editZipcode) {" ^
          "editZipcode.addEventListener('blur', function() {" ^
            "var cep = this.value.replace(/[^0-9]/g, '');" ^
            "if (cep.length === 8) {" ^
              "fetch('https://viacep.com.br/ws/' + cep + '/json/')" ^
                ".then(function(response) { return response.json(); })" ^
                ".then(function(data) {" ^
                  "if (!data.erro) {" ^
                    "document.getElementById('edit-street').value = data.logradouro || '';" ^
                    "document.getElementById('edit-neighborhood').value = data.bairro || '';" ^
                    "document.getElementById('edit-city').value = data.localidade || '';" ^
                    "document.getElementById('edit-state').value = data.uf || '';" ^
                  "}" ^
                "});" ^
            "}" ^
          "});" ^
        "}" ^

        (if is_admin then
          (* ------------ Users tab (admin) ------------ *)
          "var currentUsersPage = " ^ (match all_users_page with Some p -> string_of_int p.page | None -> "1") ^ ";" ^
          "var currentUsersSearch = '';" ^
          "var currentUsersRole = 'all';" ^
          "var currentUsersSort = 'created_desc';" ^

          "function loadUsers(page) {" ^
            "var searchEl = document.getElementById('users-search');" ^
            "var roleEl = document.getElementById('users-role-filter');" ^
            "var sortEl = document.getElementById('users-sort');" ^
            "var search = (searchEl && searchEl.value) ? searchEl.value : '';" ^
            "var role = (roleEl && roleEl.value) ? roleEl.value : 'all';" ^
            "var sort = (sortEl && sortEl.value) ? sortEl.value : 'created_desc';" ^
            "currentUsersPage = page;" ^
            "currentUsersSearch = search;" ^
            "currentUsersRole = role;" ^
            "currentUsersSort = sort;" ^
            "var params = new URLSearchParams();" ^
            "params.set('page', page.toString());" ^
            "params.set('per_page', '12');" ^
            "params.set('search', search);" ^
            "params.set('role', role);" ^
            "params.set('sort', sort);" ^
            "fetch('/api/users?' + params.toString())" ^
              ".then(function(response) { return response.json(); })" ^
              ".then(function(data) {" ^
                "if (data.success) {" ^
                  "var users = data.data.users;" ^
                  "var container = document.getElementById('users-list-container');" ^
                  "var countEl = document.getElementById('users-count');" ^
                  "var paginationEl = document.getElementById('users-pagination');" ^
                  "if (users.length === 0) {" ^
                    "container.innerHTML = '<div style=\\'text-align: center; padding: 4rem; color: var(--text-muted);\\'><h3>Nenhum usuário encontrado</h3></div>';" ^
                  "} else {" ^
                    "container.innerHTML = users.map(function(u) {" ^
                      "var adminBadge = u.is_admin ? ' <span style=\\'background: var(--accent); color: white; padding: 0.125rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem;\\'>ADMIN</span>' : '';" ^
                      "var phone = u.phone ? '<div style=\\'color: var(--text-muted); font-size: 0.875rem;\\'>' + u.phone + '</div>' : '';" ^
                      "return '<div class=\\'user-item\\' data-user-id=\\'' + u.user_id + '\\' style=\\'background: var(--bg-card); border: 1px solid var(--border-color); padding: 1.5rem; border-radius: 0.75rem; margin-bottom: 1rem; cursor: pointer;\\'>' +" ^
                        "'<div style=\\'display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 1rem;\\'>' +" ^
                          "'<div>' +" ^
                            "'<div style=\\'font-weight: 700; color: var(--text-primary); margin-bottom: 0.25rem;\\'>' + u.name + adminBadge + '</div>' +" ^
                            "'<div style=\\'color: var(--text-muted); font-size: 0.875rem;\\'>' + u.email + '</div>' +" ^
                            "phone +" ^
                          "'</div>' +" ^
                          "'<div style=\\'color: var(--text-muted); font-size: 0.875rem;\\'>Cadastrado em ' + u.created_at + '</div>' +" ^
                        "'</div>' +" ^
                      "'</div>';" ^
                    "}).join('');" ^
                    "var userItems = container.querySelectorAll('.user-item');" ^
                    "for (var i = 0; i < userItems.length; i++) {" ^
                      "userItems[i].addEventListener('click', function() {" ^
                        "var userId = parseInt(this.getAttribute('data-user-id'));" ^
                        "if (typeof openEditUserModal === 'function') {" ^
                          "openEditUserModal(userId);" ^
                        "}" ^
                      "});" ^
                    "}" ^
                  "}" ^
                  "countEl.textContent = data.data.total_count + ' usuário(s)';" ^
                  "paginationEl.innerHTML = " ^
                    "(data.data.has_prev ? '<button onclick=\\'loadUsers(' + (data.data.page - 1) + ')\\' class=\\'btn-outline btn\\'>Anterior</button>' : '<button disabled style=\\'opacity: 0.5; cursor: not-allowed;\\' class=\\'btn-outline btn\\'>Anterior</button>') +" ^
                    "'<span style=\\'color: var(--text-primary);\\'>Página ' + data.data.page + ' de ' + data.data.total_pages + '</span>' +" ^
                    "(data.data.has_next ? '<button onclick=\\'loadUsers(' + (data.data.page + 1) + ')\\' class=\\'btn-outline btn\\'>Próxima</button>' : '<button disabled style=\\'opacity: 0.5; cursor: not-allowed;\\' class=\\'btn-outline btn\\'>Próxima</button>');" ^
                "} else {" ^
                  "alert('Erro ao carregar usuários: ' + data.message);" ^
                "}" ^
              "})" ^
              ".catch(function(err) { alert('Erro ao carregar usuários: ' + err.message); });" ^
          "}" ^

          "var usersSearch = document.getElementById('users-search');" ^
          "if (usersSearch) {" ^
            "usersSearch.addEventListener('input', function() {" ^
              "clearTimeout(this.searchTimeout);" ^
              "this.searchTimeout = setTimeout(function() { loadUsers(1); }, 500);" ^
            "});" ^
          "}" ^
          "var usersRoleFilter = document.getElementById('users-role-filter');" ^
          "if (usersRoleFilter) {" ^
            "usersRoleFilter.addEventListener('change', function() {" ^
              "loadUsers(1);" ^
            "});" ^
          "}" ^
          "var usersSort = document.getElementById('users-sort');" ^
          "if (usersSort) {" ^
            "usersSort.addEventListener('change', function() {" ^
              "loadUsers(1);" ^
            "});" ^
          "}" ^

          "function openEditUserModal(userId) {" ^
            "var modal = document.getElementById('edit-user-modal');" ^
            "if (!modal) return;" ^
            "fetch('/api/users?page=1&per_page=1000&search=')" ^
              ".then(function(response) { return response.json(); })" ^
              ".then(function(data) {" ^
                "if (data.success) {" ^
                  "var user = data.data.users.find(function(u) { return u.user_id === userId; });" ^
                  "if (user) {" ^
                    "document.getElementById('edit-user-id').value = user.user_id;" ^
                    "document.getElementById('edit-user-password-id').value = user.user_id;" ^
                    "document.getElementById('edit-user-name').value = user.name || '';" ^
                    "document.getElementById('edit-user-email').value = user.email || '';" ^
                    "document.getElementById('edit-user-phone').value = user.phone || '';" ^
                    "document.getElementById('edit-user-document').value = user.document_number || '';" ^
                    "document.getElementById('edit-user-zipcode').value = user.address_zipcode || '';" ^
                    "document.getElementById('edit-user-street').value = user.address_street || '';" ^
                    "document.getElementById('edit-user-number').value = user.address_number || '';" ^
                    "document.getElementById('edit-user-complement').value = user.address_complement || '';" ^
                    "document.getElementById('edit-user-neighborhood').value = user.address_neighborhood || '';" ^
                    "document.getElementById('edit-user-city').value = user.address_city || '';" ^
                    "document.getElementById('edit-user-state').value = user.address_state || '';" ^
                    "modal.style.display = 'block';" ^
                  "}" ^
                "}" ^
              "});" ^
          "}" ^
          "window.openEditUserModal = openEditUserModal;" ^

          "function closeEditUserModal() {" ^
            "var modal = document.getElementById('edit-user-modal');" ^
            "if (modal) modal.style.display = 'none';" ^
          "}" ^
          "window.closeEditUserModal = closeEditUserModal;" ^
          "window.loadUsers = loadUsers;" ^

          "var editUserForm = document.getElementById('edit-user-form');" ^
          "if (editUserForm) {" ^
            "editUserForm.addEventListener('submit', function(e) {" ^
              "e.preventDefault();" ^
              "var userId = document.getElementById('edit-user-id').value;" ^
              "var formData = new FormData(this);" ^
              "var data = Object.fromEntries(formData);" ^
              "fetch('/api/users/' + userId, {" ^
                "method: 'PUT'," ^
                "headers: { 'Content-Type': 'application/json' }," ^
                "body: JSON.stringify(data)" ^
              "})" ^
              ".then(function(response) { return response.json(); })" ^
              ".then(function(result) {" ^
                "if (result.success) {" ^
                  "alert('Usuário atualizado com sucesso!');" ^
                  "closeEditUserModal();" ^
                  "loadUsers(currentUsersPage);" ^
                "} else {" ^
                  "alert(result.message);" ^
                "}" ^
              "})" ^
              ".catch(function(err) { alert('Erro ao atualizar usuário: ' + err.message); });" ^
            "});" ^
          "}" ^

          "var editUserPasswordForm = document.getElementById('edit-user-password-form');" ^
          "if (editUserPasswordForm) {" ^
            "editUserPasswordForm.addEventListener('submit', function(e) {" ^
              "e.preventDefault();" ^
              "var userId = document.getElementById('edit-user-password-id').value;" ^
              "var newPassword = document.getElementById('edit-user-new-password').value;" ^
              "var confirmPassword = document.getElementById('edit-user-confirm-password').value;" ^
              "var passwordError = document.getElementById('edit-user-new-password-error');" ^
              "var matchError = document.getElementById('edit-user-password-match-error');" ^
              "var isValid = true;" ^

              "var passwordValidation = validatePassword(newPassword);" ^
              "if (!passwordValidation.valid) {" ^
                "if (passwordError) {" ^
                  "passwordError.textContent = passwordValidation.message;" ^
                  "passwordError.style.display = 'block';" ^
                "}" ^
                "isValid = false;" ^
              "} else {" ^
                "if (passwordError) passwordError.style.display = 'none';" ^
              "}" ^

              "if (newPassword !== confirmPassword) {" ^
                "if (matchError) {" ^
                  "matchError.style.display = 'block';" ^
                "}" ^
                "isValid = false;" ^
              "} else {" ^
                "if (matchError) matchError.style.display = 'none';" ^
              "}" ^

              "if (!isValid) return;" ^

              "fetch('/api/users/' + userId + '/change-password', {" ^
                "method: 'POST'," ^
                "headers: { 'Content-Type': 'application/json' }," ^
                "body: JSON.stringify({ user_id: parseInt(userId), new_password: newPassword })" ^
              "})" ^
              ".then(function(response) { return response.json(); })" ^
              ".then(function(result) {" ^
                "if (result.success) {" ^
                  "alert('Senha alterada com sucesso!');" ^
                  "document.getElementById('edit-user-password-form').reset();" ^
                "} else {" ^
                  "alert(result.message);" ^
                "}" ^
              "})" ^
              ".catch(function(err) { alert('Erro ao alterar senha: ' + err.message); });" ^
            "});" ^
          "}" ^

          "var editUserNewPasswordInput = document.getElementById('edit-user-new-password');" ^
          "if (editUserNewPasswordInput) {" ^
            "var passwordError = document.getElementById('edit-user-new-password-error');" ^
            "editUserNewPasswordInput.addEventListener('blur', function() {" ^
              "var validation = validatePassword(this.value);" ^
              "if (!validation.valid && this.value) {" ^
                "if (passwordError) {" ^
                  "passwordError.textContent = validation.message;" ^
                  "passwordError.style.display = 'block';" ^
                "}" ^
              "} else {" ^
                "if (passwordError) passwordError.style.display = 'none';" ^
              "}" ^
            "});" ^
            "editUserNewPasswordInput.addEventListener('input', function() {" ^
              "var matchError = document.getElementById('edit-user-password-match-error');" ^
              "var confirmPassword = document.getElementById('edit-user-confirm-password');" ^
              "if (passwordError && passwordError.style.display === 'block') {" ^
                "var validation = validatePassword(this.value);" ^
                "if (validation.valid) {" ^
                  "passwordError.style.display = 'none';" ^
                "}" ^
              "}" ^
              "if (this.value !== confirmPassword.value) {" ^
                "if (matchError) matchError.style.display = 'block';" ^
              "} else {" ^
                "if (matchError) matchError.style.display = 'none';" ^
              "}" ^
            "});" ^
          "}" ^

          "var editUserConfirmPasswordInput = document.getElementById('edit-user-confirm-password');" ^
          "if (editUserConfirmPasswordInput) {" ^
            "editUserConfirmPasswordInput.addEventListener('input', function() {" ^
              "var errorMsg = document.getElementById('edit-user-password-match-error');" ^
              "if (this.value !== document.getElementById('edit-user-new-password').value) {" ^
                "errorMsg.style.display = 'block';" ^
              "} else {" ^
                "errorMsg.style.display = 'none';" ^
              "}" ^
            "});" ^
          "}" ^

          "if (typeof showTab === 'function') {" ^
            "var savedTab = sessionStorage.getItem('activeTab') || 'vehicles';" ^
            "if (savedTab === 'users' && typeof loadUsers === 'function') {" ^
              "setTimeout(function() { loadUsers(" ^ (match all_users_page with Some p -> string_of_int p.page | None -> "1") ^ "); }, 100);" ^
            "}" ^
          "}" ^

          "function attachUserItemListeners() {" ^
            "var userItems = document.querySelectorAll('.user-item');" ^
            "for (var i = 0; i < userItems.length; i++) {" ^
              "userItems[i].addEventListener('click', function() {" ^
                "var userId = parseInt(this.getAttribute('data-user-id'));" ^
                "if (typeof openEditUserModal === 'function') {" ^
                  "openEditUserModal(userId);" ^
                "}" ^
              "});" ^
            "}" ^
          "}" ^

          "if (document.readyState === 'loading') {" ^
            "document.addEventListener('DOMContentLoaded', function() {" ^
              "setTimeout(attachUserItemListeners, 200);" ^
            "});" ^
          "} else {" ^
            "setTimeout(attachUserItemListeners, 200);" ^
          "}"
        else "") ^

        "});" ^
      "</script>" ^
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
  
  (* Render description - detect if it's HTML (from Quill) or markdown *)
  let render_description () =
    let desc_content = Option.value ~default:"" vehicle.detailed_description_md in
    if desc_content = "" then
      "<p style='color: var(--text-secondary); line-height: 1.8;'>" ^ vehicle.description ^ "</p>"
    else
      (* Check if it's HTML (contains HTML tags like <p>, <div>, <img>, etc.) *)
      let html_pattern = Str.regexp "<[a-zA-Z][^>]*>" in
      if try ignore (Str.search_forward html_pattern desc_content 0); true with Not_found -> false then
        (* It's HTML from Quill - render directly with styling *)
        "<div class='quill-content' style='color: var(--text-primary); line-height: 1.8;'>" ^ desc_content ^ "</div>"
      else
        (* It's markdown - convert to HTML *)
        markdown_to_html desc_content
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
  
  (* Content for vehicle detail - base_template will be called by handler *)
  (
      "<style>" ^
        ".vehicle-detail-page { max-width: 1600px; margin: 0 auto; padding: 2rem; }" ^
        ".vehicle-detail-header { background: linear-gradient(135deg, var(--bg-card), var(--bg-secondary)); border: 1px solid var(--border-color); border-radius: 1.5rem; padding: 3rem; margin-bottom: 3rem; box-shadow: var(--shadow-lg); }" ^
        ".vehicle-detail-grid { display: grid; grid-template-columns: 1fr 400px; gap: 3rem; }" ^
        ".vehicle-detail-main { display: flex; flex-direction: column; gap: 2rem; }" ^
        ".vehicle-detail-sidebar { position: sticky; top: 6rem; height: fit-content; }" ^
        ".detail-section { background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1.5rem; padding: 2.5rem; box-shadow: var(--shadow); }" ^
        ".detail-section-title { font-size: 1.5rem; font-weight: 800; color: var(--text-primary); margin-bottom: 2rem; display: flex; align-items: center; gap: 1rem; padding-bottom: 1rem; border-bottom: 2px solid var(--border-color); }" ^
        ".quill-content img { max-width: 100%; height: auto; border-radius: 0.5rem; margin: 1rem 0; }" ^
        ".quill-content p { margin: 1rem 0; line-height: 1.8; }" ^
        ".quill-content h1, .quill-content h2, .quill-content h3 { color: var(--text-primary); margin: 1.5rem 0 1rem 0; }" ^
        ".quill-content ul, .quill-content ol { margin: 1rem 0; padding-left: 2rem; }" ^
        ".quill-content li { margin: 0.5rem 0; }" ^
        ".quill-content a { color: var(--accent); text-decoration: none; }" ^
        ".quill-content a:hover { text-decoration: underline; }" ^
        ".quill-content blockquote { border-left: 4px solid var(--accent); padding-left: 1rem; margin: 1rem 0; font-style: italic; color: var(--text-secondary); }" ^
        "@media (max-width: 1024px) { .vehicle-detail-grid { grid-template-columns: 1fr; } .vehicle-detail-sidebar { position: static; } }" ^
      "</style>" ^
      "<div class='vehicle-detail-page'>" ^
        "<nav style='margin-bottom: 2rem;'>" ^
          "<a href='" ^ return_url ^ "' style='color: var(--text-muted); text-decoration: none; font-size: 0.95rem; display: inline-flex; align-items: center; gap: 0.5rem; padding: 0.75rem 1.5rem; background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 0.75rem; transition: all 0.2s;' onmouseover='this.style.background=\"var(--bg-secondary)\"' onmouseout='this.style.background=\"var(--bg-card)\"'>" ^
            "<span>←</span> <span>Voltar aos resultados</span>" ^
          "</a>" ^
        "</nav>" ^
        
        "<!-- Vehicle Header -->" ^
        "<div class='vehicle-detail-header'>" ^
          "<div class='vehicle-header-content'>" ^
            "<div class='vehicle-header-info'>" ^
              "<h1 style='color: var(--text-primary); font-size: clamp(2rem, 5vw, 3.5rem); font-weight: 900; margin: 0 0 1rem 0; line-height: 1.2;'>" ^ vehicle.brand ^ " " ^ vehicle.model ^ " " ^ string_of_int vehicle.year ^ "</h1>" ^
              "<div style='display: flex; gap: 1.5rem; flex-wrap: wrap; margin-bottom: 1.5rem;'>" ^
                "<div style='display: flex; align-items: center; gap: 0.5rem; color: var(--text-muted);'>" ^
                  "<span style='font-size: 1.2rem;'>📍</span>" ^
                  "<span style='font-weight: 600;'>" ^ (normalize_city_name vehicle.location_city) ^ ", " ^ vehicle.location_state ^ "</span>" ^
          "</div>" ^
                "<div style='display: flex; align-items: center; gap: 0.5rem; color: var(--text-muted);'>" ^
                  "<span style='font-size: 1.2rem;'>🛣️</span>" ^
                  "<span style='font-weight: 600;'>" ^ vehicle.mileage ^ " km</span>" ^
          "</div>" ^
                "<div style='display: flex; align-items: center; gap: 0.5rem; color: var(--text-muted);'>" ^
                  "<span style='font-size: 1.2rem;'>🎨</span>" ^
                  "<span style='font-weight: 600;'>" ^ vehicle.color ^ "</span>" ^
                "</div>" ^
              "</div>" ^
              "<div style='display: flex; gap: 1rem; flex-wrap: wrap;'>" ^
                "<span style='background: linear-gradient(135deg, var(--accent), var(--accent-hover)); color: white; padding: 0.5rem 1.25rem; border-radius: 2rem; font-size: 0.875rem; font-weight: 700; box-shadow: 0 4px 6px rgba(16, 185, 129, 0.3);'>🏆 VERIFICADO BUSCARS</span>" ^
                (if vehicle.condition = "new" then 
                  "<span style='background: var(--accent); color: white; padding: 0.5rem 1.25rem; border-radius: 2rem; font-size: 0.875rem; font-weight: 700;'>✨ Novo</span>"
                 else "") ^
                (if vehicle.financing_available then "<span style='background: var(--bg-secondary); color: var(--accent); border: 2px solid var(--accent); padding: 0.5rem 1.25rem; border-radius: 2rem; font-size: 0.875rem; font-weight: 700;'>💳 Financiamento</span>" else "") ^
                (if vehicle.trade_accepted then "<span style='background: var(--bg-secondary); color: var(--text-primary); padding: 0.5rem 1.25rem; border-radius: 2rem; font-size: 0.875rem; font-weight: 700;'>🔄 Aceita Troca</span>" else "") ^
                (if vehicle.test_drive_available then "<span style='background: var(--bg-secondary); color: var(--text-primary); padding: 0.5rem 1.25rem; border-radius: 2rem; font-size: 0.875rem; font-weight: 700;'>🚗 Test Drive</span>" else "") ^
              "</div>" ^
            "</div>" ^
            "<div class='vehicle-price-container'>" ^
              "<div class='vehicle-price-card'>" ^
                "<div class='price-label'>Preço</div>" ^
                "<div class='price-value'>" ^ format_price_display vehicle.price vehicle.source ^ "</div>" ^
                "<div class='price-subtitle'>" ^ (if vehicle.condition = "new" then "Lançamento" else "À vista") ^ "</div>" ^
              "</div>" ^
            "</div>" ^
          "</div>" ^
        "</div>" ^
        
        "<div class='vehicle-detail-grid'>" ^
          "<div class='vehicle-detail-main'>" ^
            "<!-- Image Slideshow -->" ^
            "<div class='detail-section'>" ^
              "<div class='slideshow-container' style='position: relative; background: var(--bg-secondary); border-radius: 1rem; overflow: hidden; margin-bottom: 1.5rem; height: 600px; box-shadow: var(--shadow-lg);'>" ^
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
            "<div class='detail-section'>" ^
              "<div class='detail-section-title'>" ^
                "<span>📝</span> <span>Descrição Detalhada</span>" ^
              "</div>" ^
              "<div class='markdown-content quill-content'>" ^
                (render_description ()) ^
              "</div>" ^
            "</div>" ^
            
            "<!-- Technical Specifications -->" ^
            "<div class='detail-section'>" ^
              "<div class='detail-section-title'>" ^
                "<span>🔧</span> <span>Especificações Técnicas</span>" ^
              "</div>" ^
              "<div style='display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 2rem;'>" ^
                "<div style='background: var(--bg-secondary); padding: 2rem; border-radius: 1rem;'>" ^
                  "<h3 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1.5rem; font-size: 1.2rem;'>🚗 Motor & Performance</h3>" ^
                  "<div style='display: grid; gap: 1rem;'>" ^
                    "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                      "<span style='color: var(--text-muted); font-weight: 500;'>Motor</span>" ^
                      "<span style='color: var(--text-primary); font-weight: 700;'>" ^ (Option.value ~default:"" vehicle.engine) ^ "</span>" ^
                    "</div>" ^
                    "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                      "<span style='color: var(--text-muted); font-weight: 500;'>Combustível</span>" ^
                      "<span style='color: var(--text-primary); font-weight: 700;'>" ^ (normalize_fuel_type vehicle.fuel_type) ^ "</span>" ^
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
                      "<span style='color: var(--text-primary); font-weight: 700;'>" ^ (Option.value ~default:"" vehicle.body_style) ^ "</span>" ^
                    "</div>" ^
                  "</div>" ^
                "</div>" ^
                
                "<div style='background: var(--bg-secondary); padding: 2rem; border-radius: 1rem;'>" ^
                  "<h3 style='color: var(--text-primary); font-weight: 700; margin-bottom: 1.5rem; font-size: 1.2rem;'>🔍 Condições</h3>" ^
                  "<div style='display: grid; gap: 1rem;'>" ^
                  "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                    "<span style='color: var(--text-muted); font-weight: 500;'>Exterior</span>" ^
                    "<span style='color: var(--accent); font-weight: 700;'>" ^ (Option.value ~default:"Bom" vehicle.exterior_condition) ^ "</span>" ^
                  "</div>" ^
                  "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                    "<span style='color: var(--text-muted); font-weight: 500;'>Interior</span>" ^
                    "<span style='color: var(--accent); font-weight: 700;'>" ^ (Option.value ~default:"Bom" vehicle.interior_condition) ^ "</span>" ^
                  "</div>" ^
                  "<div style='display: flex; justify-content: space-between; padding: 0.75rem 0; border-bottom: 1px solid var(--border-color);'>" ^
                    "<span style='color: var(--text-muted); font-weight: 500;'>Mecânica</span>" ^
                    "<span style='color: var(--accent); font-weight: 700;'>" ^ (Option.value ~default:"Bom" vehicle.mechanical_condition) ^ "</span>" ^
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
              "<div class='detail-section'>" ^
                "<div class='detail-section-title'>" ^
                  "<span>⚙️</span> <span>Equipamentos & Opcionais</span>" ^
                "</div>" ^
                "<div style='display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1rem;'>" ^
                  features_list ^
                "</div>" ^
              "</div>"
             else "") ^
            
            "<!-- Service History -->" ^
            (if List.length vehicle.service_history > 0 then
              "<div class='detail-section'>" ^
                "<div class='detail-section-title'>" ^
                  "<span>📋</span> <span>Histórico de Manutenção</span>" ^
                "</div>" ^
                "<div style='max-width: 600px;'>" ^
                  service_timeline ^
                "</div>" ^
              "</div>"
             else "") ^
            
            "<!-- Inspection Report -->" ^
            (match vehicle.inspection_notes with
             | Some notes when notes <> "" ->
              "<div style='background: linear-gradient(135deg, var(--accent), var(--accent-hover)); color: white; padding: 3rem; border-radius: 1rem; margin-bottom: 3rem;'>" ^
                "<h2 style='font-weight: 800; margin-bottom: 1.5rem; font-size: 1.75rem;'>🔍 Relatório de Inspeção BusCars</h2>" ^
                "<p style='line-height: 1.8; font-size: 1.1rem; opacity: 0.95;'>" ^ notes ^ "</p>" ^
                "<div style='margin-top: 2rem; padding-top: 2rem; border-top: 1px solid rgba(255,255,255,0.3); display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; font-size: 0.9rem;'>" ^
                  "<div>✓ <strong>127 pontos verificados</strong></div>" ^
                  "<div>✓ <strong>Histórico limpo</strong></div>" ^
                  "<div>✓ <strong>Documentação completa</strong></div>" ^
                  "<div>✓ <strong>Procedência garantida</strong></div>" ^
                "</div>" ^
              "</div>"
             | _ -> "") ^
          "</div>" ^
          
          "<!-- Right Sidebar -->" ^
          "<div class='vehicle-detail-sidebar'>" ^
            "<!-- Contact Card -->" ^
            "<div class='detail-section' style='margin-bottom: 2rem;'>" ^
              "<!-- Seller Info -->" ^
              "<div style='text-align: center; margin-bottom: 2rem; padding-bottom: 2rem; border-bottom: 2px solid var(--border-color);'>" ^
                "<div style='width: 80px; height: 80px; background: linear-gradient(135deg, var(--accent), var(--accent-hover)); border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 1rem; font-size: 2rem; color: white; font-weight: 700;'>" ^
                  (String.sub (String.uppercase_ascii vehicle.seller_name) 0 1) ^
                "</div>" ^
                "<h3 style='color: var(--text-primary); font-weight: 700; margin-bottom: 0.5rem; font-size: 1.3rem;'>" ^ vehicle.seller_name ^ "</h3>" ^
                "<div style='display: flex; align-items: center; justify-content: center; gap: 0.5rem; color: var(--accent); font-size: 0.875rem; font-weight: 600; margin-bottom: 1rem;'>" ^
                  "<span>✓</span> <span>Vendedor Verificado</span>" ^
                "</div>" ^
                "<p style='color: var(--text-muted); font-size: 0.95rem; margin-bottom: 0.25rem;'>📞 " ^ vehicle.seller_phone ^ "</p>" ^
                "<p style='color: var(--text-muted); font-size: 0.95rem; margin-bottom: 0.5rem;'>✉️ " ^ vehicle.seller_email ^ "</p>" ^
                "<p style='color: var(--text-muted); font-size: 0.875rem;'>📍 " ^ (normalize_city_name vehicle.location_city) ^ ", " ^ vehicle.location_state ^ "</p>" ^
              "</div>" ^
              
              "<!-- Action Buttons -->" ^
              "<div style='display: flex; flex-direction: column; gap: 1rem;'>" ^
                (let normalized_phone = normalize_phone_for_whatsapp vehicle.seller_phone in
                 if normalized_phone <> "" then
                   "<a href='https://wa.me/" ^ normalized_phone ^ "' target='_blank' rel='noopener noreferrer' class='btn' style='width: 100%; padding: 1.25rem; font-size: 1.1rem; font-weight: 700; background: linear-gradient(135deg, var(--accent), var(--accent-hover)); box-shadow: 0 4px 12px rgba(16, 185, 129, 0.4); text-decoration: none; text-align: center; display: block; color: white; border: none; border-radius: 0.75rem; cursor: pointer; transition: all 0.2s;'>💬 Entrar em Contato</a>"
                 else
                   "<button class='btn' style='width: 100%; padding: 1.25rem; font-size: 1.1rem; font-weight: 700; background: linear-gradient(135deg, var(--accent), var(--accent-hover)); box-shadow: 0 4px 12px rgba(16, 185, 129, 0.4);' disabled>💬 Entrar em Contato (Telefone não disponível)</button>") ^
              "</div>" ^
            "</div>" ^
            
            "<!-- Vehicle Stats -->" ^
            "<div class='detail-section'>" ^
              "<div class='detail-section-title' style='font-size: 1.25rem; margin-bottom: 1.5rem; padding-bottom: 1rem;'>" ^
                "<span>📊</span> <span>Estatísticas</span>" ^
                "</div>" ^
              "<div style='display: grid; gap: 1.25rem;'>" ^
                "<div style='display: flex; justify-content: space-between; align-items: center; padding: 1rem; background: var(--bg-secondary); border-radius: 0.75rem;'>" ^
                  "<span style='color: var(--text-muted); font-weight: 500; font-size: 0.95rem;'>Publicado</span>" ^
                  "<span style='color: var(--text-primary); font-weight: 700; font-size: 1.1rem;'>" ^ (format_date vehicle.created_at) ^ "</span>" ^
                "</div>" ^
                "<div style='display: flex; justify-content: space-between; align-items: center; padding: 1rem; background: var(--bg-secondary); border-radius: 0.75rem;'>" ^
                  "<span style='color: var(--text-muted); font-weight: 500; font-size: 0.95rem;'>Atualizado</span>" ^
                  "<span style='color: var(--text-primary); font-weight: 700; font-size: 1.1rem;'>" ^ (format_date vehicle.updated_at) ^ "</span>" ^
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
  if (slideImages.length > 0) {
    changeSlide(0);
  }
});
</script>|}
    )

(* First page: Simple redirect page with countdown (no popup, full page content) *)
let advertisement_redirect_page ~slug ~source () =
  let platform_info = match source with
    | "localiza" -> ("Localiza Seminovos", "Seminovos certificados", "#059669")
    | "icarros" -> ("iCarros", "Avaliação e comparação", "#374151")
    | _ -> ("Parceiro", "Plataforma de carros", "#374151")
  in
  
  let (platform_name, platform_desc, _) = platform_info in
  
  (* Determine redirect URL based on source *)
  (* For iCarros: redirect directly to external URL (no iframe) *)
  (* For Localiza: redirect to iframe page *)
  let frame_url = match source with
    | "icarros" -> 
        (* iCarros: will redirect directly to external URL, but we need to get it from the vehicle *)
        (* For now, use a placeholder that will be handled by external_frame_handler *)
        "/external-frame/" ^ (Uri.pct_encode ~component:`Path slug) ^ "?direct=true"
    | "localiza" ->
        (* Localiza: redirect to iframe page *)
        "/external-frame/" ^ (Uri.pct_encode ~component:`Path slug)
    | _ ->
        (* Default: iframe page *)
        "/external-frame/" ^ (Uri.pct_encode ~component:`Path slug)
  in
  
  (
      "<div style='min-height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 2rem; background: var(--bg-primary);'>" ^
        "<div style='max-width: 600px; width: 100%; text-align: center;'>" ^
          "<div style='margin-bottom: 2rem;'>" ^
            "<h2 style='color: var(--text-primary); margin-bottom: 1rem; font-size: clamp(1.5rem, 4vw, 2rem);'>🚗 Resultado Encontrado!</h2>" ^
            "<p style='color: var(--text-muted); margin-bottom: 1rem; font-size: clamp(0.9rem, 3vw, 1rem);'>Encontramos veículos correspondentes em nossos parceiros</p>" ^
          "</div>" ^
          
          "<div style='background: var(--bg-card); border: 1px solid var(--border-color); padding: 2rem; border-radius: 1rem; margin-bottom: 2rem; text-align: center;'>" ^
            "<div style='background: white; padding: 1.5rem; border-radius: 0.75rem; margin-bottom: 1.5rem; display: inline-block;'>" ^
              "<div style='background: " ^ (let (_, _, color) = platform_info in color) ^ "; color: white; padding: 1rem 2rem; border-radius: 0.5rem; font-weight: 600;'>" ^ platform_name ^ "</div>" ^
            "</div>" ^
            "<p style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem;'>Redirecionando para " ^ platform_name ^ "</p>" ^
            "<p style='color: var(--text-muted); font-size: 0.9rem;'>" ^ platform_desc ^ "</p>" ^
          "</div>" ^
          
          "<div style='text-align: center;'>" ^
            "<p style='color: var(--text-muted); margin-bottom: 1rem; font-size: clamp(0.9rem, 3vw, 1rem);'>Você será redirecionado em</p>" ^
            "<span id='countdown' style='font-size: clamp(2rem, 8vw, 3rem); color: var(--accent); font-weight: 800; display: block; margin-bottom: 1rem;'>5</span>" ^
            "<p style='color: var(--text-muted); font-size: clamp(0.8rem, 2.5vw, 0.9rem); margin-bottom: 2rem;'>segundos</p>" ^
            "<div style='display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap;'>" ^
              "<button onclick='closeAd()' style='background: transparent; color: var(--text-muted); border: 1px solid var(--border-color); padding: 0.75rem 2rem; border-radius: 0.5rem; font-weight: 600; cursor: pointer; font-size: 1rem; transition: all 0.2s; min-width: 150px;' onmouseover='this.style.background=\"var(--bg-secondary)\"' onmouseout='this.style.background=\"transparent\"'>Voltar</button>" ^
            "</div>" ^
          "</div>" ^
          
          "<p style='color: var(--text-muted); font-size: 0.8rem; text-align: center; margin-top: 2rem; opacity: 0.7;'>" ^
            "Esta página é patrocinada. BusCars recebe comissão por direcionamentos.<br>" ^
            "<span style='font-size: 0.7rem; margin-top: 0.5rem; display: block;'>Atalho: Esc = Voltar</span>" ^
          "</p>" ^
        "</div>" ^
      "</div>" ^
      
      "<script>" ^
        "const frameUrl = '" ^ frame_url ^ "';" ^
        "let countdown = 5;" ^
        "const countdownElement = document.getElementById('countdown');" ^
        "let timer;" ^
        
        "function startCountdown() {" ^
          "timer = setInterval(function() {" ^
            "countdown--;" ^
            "if (countdownElement) countdownElement.textContent = countdown;" ^
            
            "if (countdown <= 0) {" ^
              "clearInterval(timer);" ^
              "goToFrame();" ^
            "}" ^
          "}, 1000);" ^
        "}" ^
        
        "function goToFrame() {" ^
          "if (timer) clearInterval(timer);" ^
          "window.location.href = frameUrl;" ^
        "}" ^
        
        "function closeAd() {" ^
          "if (timer) clearInterval(timer);" ^
          "window.history.back();" ^
        "}" ^
        
        "document.addEventListener('visibilitychange', function() {" ^
          "if (document.hidden) {" ^
            "if (timer) clearInterval(timer);" ^
          "} else {" ^
            "if (countdown > 0 && !timer) {" ^
              "startCountdown();" ^
            "}" ^
          "}" ^
        "});" ^
        
        "document.addEventListener('keydown', function(e) {" ^
          "if (e.key === 'Escape') closeAd();" ^
          "if (e.key === 'Enter' || e.key === ' ') goToFrame();" ^
        "});" ^
        
        "if (document.readyState === 'loading') {" ^
          "document.addEventListener('DOMContentLoaded', startCountdown);" ^
        "} else {" ^
          "startCountdown();" ^
        "}" ^
      "</script>"
  )

(* Second page: Frame page with iframe (like Google Translate) *)
let advertisement_frame_page ~redirect_url ~source () =
  let platform_info = match source with
    | "localiza" -> ("Localiza Seminovos", "Seminovos certificados", "#059669")
    | "icarros" -> ("iCarros", "Avaliação e comparação", "#374151")
    | _ -> ("Parceiro", "Plataforma de carros", "#374151")
  in
  
  let (platform_name, platform_desc, _) = platform_info in
  
  (* Escape URL for JavaScript - use data attribute instead of inline JS *)
  let encoded_url = Uri.pct_encode ~component:`Query redirect_url in
  let proxy_url = "/api/proxy?url=" ^ encoded_url in
  
  (* Content with banner frame and iframe - full page layout *)
  (* This is a standalone page, not wrapped in base_template *)
  (
      "<!DOCTYPE html>" ^
      "<html lang='pt-BR'>" ^
      "<head>" ^
        "<meta charset='UTF-8'>" ^
        "<meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'>" ^
        "<title>BusCars - " ^ platform_name ^ "</title>" ^
        "<style>" ^
          "* { margin: 0; padding: 0; box-sizing: border-box; }" ^
          "html, body { height: 100%; overflow: hidden; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; }" ^
          "#buscar-frame-banner {" ^
            "position: fixed; top: 0; left: 0; right: 0; z-index: 10000; " ^
            "background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%); " ^
            "border-bottom: 2px solid #e5e7eb; " ^
            "box-shadow: 0 4px 12px rgba(0,0,0,0.08); " ^
            "padding: 0.75rem 1rem; " ^
          "}" ^
          "#buscar-frame-content {" ^
            "display: flex; align-items: center; justify-content: space-between; " ^
            "max-width: 1400px; margin: 0 auto; gap: 1rem; flex-wrap: wrap; " ^
          "}" ^
          "#buscar-frame-left {" ^
            "display: flex; align-items: center; gap: 0.75rem; flex: 1; min-width: 0; " ^
          "}" ^
          "#buscar-frame-logo {" ^
            "height: 36px; width: auto; flex-shrink: 0; " ^
          "}" ^
          "#buscar-frame-info {" ^
            "display: flex; flex-direction: column; gap: 0.125rem; min-width: 0; " ^
          "}" ^
          "#buscar-frame-title {" ^
            "font-size: 0.875rem; font-weight: 600; color: #1f2937; " ^
            "white-space: nowrap; overflow: hidden; text-overflow: ellipsis; " ^
          "}" ^
          "#buscar-frame-subtitle {" ^
            "font-size: 0.75rem; color: #6b7280; " ^
            "white-space: nowrap; overflow: hidden; text-overflow: ellipsis; " ^
          "}" ^
          "#buscar-frame-actions {" ^
            "display: flex; gap: 0.5rem; align-items: center; flex-shrink: 0; " ^
          "}" ^
          ".buscar-frame-btn {" ^
            "padding: 0.5rem 1rem; border-radius: 0.5rem; " ^
            "font-size: 0.875rem; font-weight: 600; cursor: pointer; " ^
            "border: none; transition: all 0.2s ease; " ^
            "white-space: nowrap; display: inline-flex; align-items: center; gap: 0.25rem; " ^
          "}" ^
          "#buscar-btn-back {" ^
            "background: #f3f4f6; color: #1f2937; border: 1px solid #e5e7eb; " ^
          "}" ^
          "#buscar-btn-back:hover { background: #e5e7eb; }" ^
          "#buscar-btn-back:active { transform: scale(0.98); }" ^
          "#buscar-btn-direct {" ^
            "background: #10b981; color: white; " ^
          "}" ^
          "#buscar-btn-direct:hover { background: #059669; }" ^
          "#buscar-btn-direct:active { transform: scale(0.98); }" ^
          "#buscar-iframe-container {" ^
            "position: fixed; top: 70px; left: 0; right: 0; bottom: 0; " ^
            "width: 100%; height: calc(100vh - 70px); background: #f9fafb; " ^
          "}" ^
          "#buscar-external-iframe {" ^
            "width: 100%; height: 100%; border: none; display: block; " ^
            "pointer-events: auto; " ^
          "}" ^
          "#buscar-frame-banner { " ^
            "position: relative; z-index: 10001; pointer-events: auto !important; " ^
          "}" ^
          "#buscar-frame-actions { " ^
            "position: relative; z-index: 10002; pointer-events: auto !important; " ^
          "}" ^
          ".buscar-frame-btn { " ^
            "position: relative; z-index: 10003; pointer-events: auto !important; " ^
          "}" ^
          "#buscar-iframe-error {" ^
            "display: none; position: absolute; top: 50%; left: 50%; " ^
            "transform: translate(-50%, -50%); text-align: center; " ^
            "padding: 2rem; background: white; border-radius: 1rem; " ^
            "box-shadow: 0 10px 25px rgba(0,0,0,0.15); max-width: 90%; " ^
            "width: 400px; z-index: 10001; " ^
          "}" ^
          "#buscar-iframe-error h3 {" ^
            "color: #1f2937; margin-bottom: 0.75rem; font-size: 1.125rem; " ^
          "}" ^
          "#buscar-iframe-error p {" ^
            "color: #6b7280; margin-bottom: 1.5rem; font-size: 0.875rem; line-height: 1.5; " ^
          "}" ^
          "#buscar-error-actions {" ^
            "display: flex; gap: 0.75rem; justify-content: center; flex-wrap: wrap; " ^
          "}" ^
          "#buscar-error-actions button {" ^
            "padding: 0.75rem 1.5rem; border-radius: 0.5rem; font-weight: 600; " ^
            "cursor: pointer; border: none; transition: all 0.2s; font-size: 0.875rem; " ^
          "}" ^
          "#buscar-error-btn-direct {" ^
            "background: #10b981; color: white; " ^
          "}" ^
          "#buscar-error-btn-direct:hover { background: #059669; }" ^
          "#buscar-error-btn-back {" ^
            "background: #f3f4f6; color: #1f2937; border: 1px solid #e5e7eb; " ^
          "}" ^
          "#buscar-error-btn-back:hover { background: #e5e7eb; }" ^
          "@media (max-width: 768px) {" ^
            "#buscar-frame-banner { padding: 0.625rem 0.75rem; }" ^
            "#buscar-frame-content { flex-direction: column; align-items: stretch; gap: 0.75rem; }" ^
            "#buscar-frame-left { flex-direction: row; align-items: center; }" ^
            "#buscar-frame-logo { height: 32px; }" ^
            "#buscar-frame-title { font-size: 0.8125rem; }" ^
            "#buscar-frame-subtitle { font-size: 0.6875rem; }" ^
            "#buscar-frame-actions { width: 100%; justify-content: stretch; }" ^
            ".buscar-frame-btn { flex: 1; padding: 0.625rem 0.875rem; font-size: 0.8125rem; }" ^
            "#buscar-iframe-container { top: 100px; height: calc(100vh - 100px); }" ^
            "#buscar-iframe-error { padding: 1.5rem; max-width: 95%; width: auto; }" ^
            "#buscar-error-actions { flex-direction: column; }" ^
            "#buscar-error-actions button { width: 100%; }" ^
          "}" ^
          "@media (max-width: 480px) {" ^
            "#buscar-frame-title { font-size: 0.75rem; }" ^
            "#buscar-frame-subtitle { display: none; }" ^
            ".buscar-frame-btn { font-size: 0.75rem; padding: 0.5rem 0.75rem; }" ^
          "}" ^
        "</style>" ^
      "</head>" ^
      "<body>" ^
        "<div id='buscar-frame-banner'>" ^
          "<div id='buscar-frame-content'>" ^
            "<div id='buscar-frame-left'>" ^
              "<img src='/logo-buscar.png' alt='BusCars' id='buscar-frame-logo'>" ^
              "<div id='buscar-frame-info'>" ^
                "<div id='buscar-frame-title'>🚗 Visualizando: " ^ platform_name ^ "</div>" ^
                "<div id='buscar-frame-subtitle'>" ^ platform_desc ^ "</div>" ^
              "</div>" ^
            "</div>" ^
            "<div id='buscar-frame-actions'>" ^
              "<button id='buscar-btn-back' class='buscar-frame-btn'>← Voltar</button>" ^
              "<button id='buscar-btn-direct' class='buscar-frame-btn'>Ir direto →</button>" ^
            "</div>" ^
          "</div>" ^
        "</div>" ^
        "<div id='buscar-iframe-container'>" ^
          "<div id='buscar-iframe-error'>" ^
            "<h3>⚠️ Site não disponível</h3>" ^
            "<p>Este site não pode ser exibido aqui. Você pode abri-lo em uma nova aba ou voltar ao BusCars.</p>" ^
            "<div id='buscar-error-actions'>" ^
              "<button id='buscar-error-btn-direct'>Abrir em nova aba</button>" ^
              "<button id='buscar-error-btn-back'>Voltar ao BusCars</button>" ^
            "</div>" ^
          "</div>" ^
          "<iframe id='buscar-external-iframe' src='" ^ proxy_url ^ "' sandbox='allow-scripts allow-forms allow-popups allow-popups-to-escape-sandbox' allow='fullscreen'></iframe>" ^
        "</div>" ^
        "<script>" ^
          "(function() {" ^
            "var redirectUrl = " ^ (let escape_js_json s =
              let b = Buffer.create (String.length s * 2) in
              Buffer.add_char b '"';
              String.iter (function
                | '\\' -> Buffer.add_string b "\\\\"
                | '"' -> Buffer.add_string b "\\\""
                | '\n' -> Buffer.add_string b "\\n"
                | '\r' -> Buffer.add_string b "\\r"
                | '\t' -> Buffer.add_string b "\\t"
                | '\x00'..'\x1f' as c -> Buffer.add_string b (Printf.sprintf "\\u%04x" (Char.code c))
                | c -> Buffer.add_char b c
              ) s;
              Buffer.add_char b '"';
              Buffer.contents b
            in escape_js_json redirect_url) ^ ";" ^
            "var iframe = document.getElementById('buscar-external-iframe');" ^
            "var errorDiv = document.getElementById('buscar-iframe-error');" ^
            "var backBtn = document.getElementById('buscar-btn-back');" ^
            "var directBtn = document.getElementById('buscar-btn-direct');" ^
            "var errorBackBtn = document.getElementById('buscar-error-btn-back');" ^
            "var errorDirectBtn = document.getElementById('buscar-error-btn-direct');" ^
            "var iframeErrorTimeout = null;" ^
            "function goBack() { window.location.href = '/vehicles'; }" ^
            "function goDirect() { window.location.href = redirectUrl; }" ^
            "function showIframeError() {" ^
              "if (errorDiv) { errorDiv.style.display = 'block'; }" ^
              "if (iframe) { iframe.style.display = 'none'; }" ^
            "}" ^
            "function hideIframeError() {" ^
              "if (errorDiv) { errorDiv.style.display = 'none'; }" ^
              "if (iframe) { iframe.style.display = 'block'; }" ^
            "}" ^
            "if (backBtn) { " ^
              "backBtn.removeEventListener('click', goBack); " ^
              "backBtn.addEventListener('click', function(e) { e.stopPropagation(); e.preventDefault(); goBack(); }, true); " ^
            "}" ^
            "if (directBtn) { " ^
              "directBtn.removeEventListener('click', goDirect); " ^
              "directBtn.addEventListener('click', function(e) { e.stopPropagation(); e.preventDefault(); goDirect(); }, true); " ^
            "}" ^
            "if (errorBackBtn) { " ^
              "errorBackBtn.removeEventListener('click', goBack); " ^
              "errorBackBtn.addEventListener('click', function(e) { e.stopPropagation(); e.preventDefault(); goBack(); }, true); " ^
            "}" ^
            "if (errorDirectBtn) { " ^
              "errorDirectBtn.removeEventListener('click', goDirect); " ^
              "errorDirectBtn.addEventListener('click', function(e) { e.stopPropagation(); e.preventDefault(); goDirect(); }, true); " ^
            "}" ^
            "if (iframe) {" ^
              "iframe.addEventListener('error', function() { showIframeError(); });" ^
              "iframe.addEventListener('load', function() {" ^
                "if (iframeErrorTimeout) { clearTimeout(iframeErrorTimeout); }" ^
                "setTimeout(function() {" ^
                  "try {" ^
                    "var iframeDoc = iframe.contentDocument || iframe.contentWindow.document;" ^
                    "if (iframeDoc && iframeDoc.location.href === 'about:blank') {" ^
                      "showIframeError();" ^
                    "} else {" ^
                      "hideIframeError();" ^
                    "}" ^
                  "} catch (e) {" ^
                    "hideIframeError();" ^
                  "}" ^
                "}, 1000);" ^
              "});" ^
            "}" ^
            "var checkCount = 0;" ^
            "var maxChecks = 10;" ^
            "function checkIframeLoading() {" ^
              "checkCount++;" ^
              "try {" ^
                "if (iframe) {" ^
                  "var iframeDoc = iframe.contentDocument || iframe.contentWindow.document;" ^
                  "if (iframeDoc && iframeDoc.location.href !== 'about:blank' && iframeDoc.body && iframeDoc.body.innerHTML.trim() !== '') {" ^
                    "hideIframeError();" ^
                    "return;" ^
                  "}" ^
                "}" ^
              "} catch (e) {" ^
                "if (checkCount >= maxChecks) {" ^
                  "showIframeError();" ^
                "}" ^
              "}" ^
              "if (checkCount < maxChecks) {" ^
                "setTimeout(checkIframeLoading, 1000);" ^
              "} else {" ^
                "showIframeError();" ^
              "}" ^
            "}" ^
            "setTimeout(checkIframeLoading, 2000);" ^
            "document.addEventListener('keydown', function(e) {" ^
              "if (e.key === 'Escape') { goBack(); }" ^
            "});" ^
          "})();" ^
        "</script>" ^
      "</body>" ^
      "</html>"
    )

(* Modern add vehicle form template - identical to edit_vehicle_template *)
let add_vehicle_template ?error ~(user:Types.user) () =
  let error_msg = match error with
    | Some msg -> "<div class='error'>" ^ msg ^ "</div>"
    | None -> ""
  in
  let seller_name = user.name in
  let seller_phone = Option.value ~default:"" user.phone in
  
  (
      "<link href='https://cdn.jsdelivr.net/npm/quill@2.0.3/dist/quill.snow.css' rel='stylesheet' />" ^
      "<script src='https://cdn.jsdelivr.net/npm/quill@2.0.3/dist/quill.js'></script>" ^
      "<style>" ^
        ".form-section { background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem; padding: 2rem; margin-bottom: 2rem; box-shadow: var(--shadow); }" ^
        ".form-section-title { font-size: 1.25rem; font-weight: 700; color: var(--text-primary); margin-bottom: 1.5rem; display: flex; align-items: center; gap: 0.75rem; padding-bottom: 1rem; border-bottom: 2px solid var(--border-color); }" ^
        ".form-section-title::before { content: attr(data-icon); font-size: 1.5rem; }" ^
        ".form-container { max-width: 1000px !important; padding: 3rem !important; }" ^
        ".form-header { text-align: center; margin-bottom: 3rem; padding-bottom: 2rem; border-bottom: 2px solid var(--border-color); }" ^
        ".form-header h2 { font-size: 2rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0.5rem; background: linear-gradient(135deg, var(--accent), var(--accent-hover)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }" ^
        ".form-header p { color: var(--text-muted); font-size: 1.1rem; }" ^
        "#quill-editor .ql-container { background: var(--bg-primary) !important; color: var(--text-primary) !important; border-color: var(--border-color) !important; }" ^
        "#quill-editor .ql-editor { background: var(--bg-primary) !important; color: var(--text-primary) !important; }" ^
        "#quill-editor .ql-toolbar { background: var(--bg-secondary) !important; border-color: var(--border-color) !important; }" ^
        "#quill-editor .ql-stroke { stroke: var(--text-primary) !important; }" ^
        "#quill-editor .ql-fill { fill: var(--text-primary) !important; }" ^
        "#quill-editor .ql-picker-label { color: var(--text-primary) !important; }" ^
        "#quill-editor .ql-picker-options { background: var(--bg-card) !important; border-color: var(--border-color) !important; }" ^
        "#quill-editor .ql-picker-item { color: var(--text-primary) !important; }" ^
        "#quill-editor .ql-picker-item:hover { background: var(--bg-secondary) !important; }" ^
        "#quill-editor .ql-snow .ql-picker.ql-expanded .ql-picker-label { border-color: var(--border-color) !important; }" ^
        "@media (max-width: 768px) {" ^
          ".form-container { padding: 1.5rem !important; margin: 0.5rem !important; }" ^
          ".form-header { margin-bottom: 2rem !important; padding-bottom: 1.5rem !important; }" ^
          ".form-header h2 { font-size: 1.5rem !important; }" ^
          ".form-header p { font-size: 0.95rem !important; }" ^
          ".form-section { padding: 1.5rem !important; margin-bottom: 1.5rem !important; }" ^
          ".form-section-title { font-size: 1.1rem !important; padding-bottom: 0.75rem !important; margin-bottom: 1rem !important; }" ^
          ".form-group { margin-bottom: 1rem !important; }" ^
          ".form-group label { font-size: 0.875rem !important; }" ^
          ".form-group input, .form-group select, .form-group textarea { font-size: 0.95rem !important; padding: 0.75rem !important; }" ^
          ".btn { width: 100% !important; margin-top: 0.5rem !important; }" ^
          "#quill-editor .ql-toolbar { padding: 0.5rem !important; }" ^
          "#quill-editor .ql-container { min-height: 200px !important; }" ^
        "}" ^
        "@media (max-width: 480px) {" ^
          ".form-container { padding: 1rem !important; margin: 0.25rem !important; }" ^
          ".form-section { padding: 1.25rem !important; }" ^
          ".form-section-title { font-size: 1rem !important; }" ^
          ".form-header h2 { font-size: 1.25rem !important; }" ^
          ".form-header p { font-size: 0.875rem !important; }" ^
        "}" ^
      "</style>" ^
      "<div class='container'>" ^
        "<div class='form-container'>" ^
          "<div class='form-header'>" ^
            "<h2>🚗 Criar Novo Anúncio</h2>" ^
            "<p>Preencha todas as informações do seu veículo para criar um anúncio completo</p>" ^
          "</div>" ^
          error_msg ^
          
          "<form method='post' action='/dashboard/add-vehicle' id='add-vehicle-form'>" ^
            "<input type='hidden' name='seller_name' id='seller_name' value='" ^ seller_name ^ "'>" ^
            "<input type='hidden' name='seller_phone' id='seller_phone' value='" ^ seller_phone ^ "'>" ^
            "<input type='hidden' name='description' id='description-hidden'>" ^
            "<input type='hidden' name='images' id='images-hidden'>" ^
            
            "<div class='form-section'>" ^
              "<div class='form-section-title' data-icon='📋'>Informações Básicas</div>" ^
              "<div style='display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; margin-bottom: 1.5rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='brand'>Marca</label>" ^
                  "<input type='text' name='brand' id='brand' required placeholder='Ex: Porsche'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='model'>Modelo</label>" ^
                "<input type='text' name='model' id='model' required placeholder='Ex: 911 Carrera'>" ^
              "</div>" ^
            "</div>" ^
              "<div style='display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1.5rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='year'>Ano</label>" ^
                  "<input type='number' name='year' id='year' required min='1980' max='2025' value='2020'>" ^
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
            "</div>" ^
            
            "<div class='form-section'>" ^
              "<div class='form-section-title' data-icon='⚙️'>Especificações Técnicas</div>" ^
              "<div style='display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1.5rem; margin-bottom: 1.5rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='fuel_type'>Combustível</label>" ^
                "<select name='fuel_type' id='fuel_type' required>" ^
                  "<option value=''>Selecione</option>" ^
                  "<option value='Gasolina'>Gasolina</option>" ^
                    "<option value='Flex'>Flex (Gasolina/Álcool)</option>" ^
                  "<option value='Diesel'>Diesel</option>" ^
                  "<option value='Elétrico'>Elétrico</option>" ^
                  "<option value='Híbrido'>Híbrido</option>" ^
                    "<option value='GNV'>GNV</option>" ^
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
                    "<option value='Automatizada'>Automatizada</option>" ^
                  "<option value='CVT'>CVT</option>" ^
                    "<option value='DCT'>DCT (Dupla Embreagem)</option>" ^
                    "<option value='Sequencial'>Sequencial</option>" ^
                "</select>" ^
                "</div>" ^
              "</div>" ^
              "<div style='display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1.5rem;'>" ^
                "<div class='form-group'>" ^
                  "<label for='engine'>Motor</label>" ^
                  "<input type='text' name='engine' id='engine' placeholder='Ex: 3.0L V6 Turbo'>" ^
                "</div>" ^
                "<div class='form-group'>" ^
                  "<label for='doors'>Portas</label>" ^
                  "<select name='doors' id='doors'>" ^
                    "<option value=''>Selecione</option>" ^
                    "<option value='2'>2 Portas</option>" ^
                    "<option value='3'>3 Portas</option>" ^
                    "<option value='4' selected>4 Portas</option>" ^
                    "<option value='5'>5 Portas</option>" ^
                  "</select>" ^
                "</div>" ^
                "<div class='form-group'>" ^
                  "<label for='body_style'>Carroceria</label>" ^
                  "<input type='text' name='body_style' id='body_style' placeholder='Ex: Sedan, Hatchback, SUV'>" ^
                "</div>" ^
              "</div>" ^
            "</div>" ^
            
            "<div class='form-section'>" ^
              "<div class='form-section-title' data-icon='📍'>Localização</div>" ^
              "<div style='display: grid; grid-template-columns: 2fr 1fr; gap: 1.5rem;'>" ^
                "<div class='form-group'>" ^
                  "<label for='location_city'>Cidade</label>" ^
                  "<input type='text' name='location_city' id='location_city' required value='São Paulo' placeholder='Ex: São Paulo'>" ^
                "</div>" ^
                "<div class='form-group'>" ^
                  "<label for='location_state'>Estado</label>" ^
                  "<input type='text' name='location_state' id='location_state' required value='SP' placeholder='Ex: SP' maxlength='2'>" ^
                "</div>" ^
              "</div>" ^
            "</div>" ^
            
            "<div class='form-section'>" ^
              "<div class='form-section-title' data-icon='🔍'>Condições do Veículo</div>" ^
              "<div style='display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1.5rem; margin-bottom: 1.5rem;'>" ^
                "<div class='form-group'>" ^
                  "<label for='exterior_condition'>Condição do Exterior</label>" ^
                  "<select name='exterior_condition' id='exterior_condition'>" ^
                    "<option value=''>Selecione</option>" ^
                    "<option value='Excelente'>Excelente</option>" ^
                    "<option value='Muito Bom'>Muito Bom</option>" ^
                    "<option value='Bom'>Bom</option>" ^
                    "<option value='Regular'>Regular</option>" ^
                  "</select>" ^
                "</div>" ^
                "<div class='form-group'>" ^
                  "<label for='interior_condition'>Condição do Interior</label>" ^
                  "<select name='interior_condition' id='interior_condition'>" ^
                    "<option value=''>Selecione</option>" ^
                    "<option value='Excelente'>Excelente</option>" ^
                    "<option value='Muito Bom'>Muito Bom</option>" ^
                    "<option value='Bom'>Bom</option>" ^
                    "<option value='Regular'>Regular</option>" ^
                  "</select>" ^
                "</div>" ^
                "<div class='form-group'>" ^
                  "<label for='mechanical_condition'>Condição Mecânica</label>" ^
                  "<select name='mechanical_condition' id='mechanical_condition'>" ^
                    "<option value=''>Selecione</option>" ^
                    "<option value='Perfeito'>Perfeito</option>" ^
                    "<option value='Excelente'>Excelente</option>" ^
                    "<option value='Muito Bom'>Muito Bom</option>" ^
                    "<option value='Bom'>Bom</option>" ^
                  "</select>" ^
                "</div>" ^
              "</div>" ^
              "<div style='display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1.5rem;'>" ^
                "<div class='form-group'>" ^
                  "<label for='previous_owners'>Número de Proprietários</label>" ^
                  "<input type='number' name='previous_owners' id='previous_owners' min='0' value='1'>" ^
                "</div>" ^
                "<div class='form-group' style='display: flex; align-items: center; padding-top: 1.75rem;'>" ^
                  "<label style='display: flex; align-items: center; cursor: pointer; padding: 0.75rem; background: var(--bg-secondary); border-radius: 0.5rem; transition: all 0.2s;'>" ^
                    "<input type='checkbox' name='financing_available' id='financing_available' style='margin-right: 0.5rem; width: 18px; height: 18px; cursor: pointer;'>" ^
                    "<span style='font-weight: 600;'>💳 Financiamento Disponível</span>" ^
                  "</label>" ^
                "</div>" ^
                "<div class='form-group' style='display: flex; align-items: center; padding-top: 1.75rem;'>" ^
                  "<label style='display: flex; align-items: center; cursor: pointer; padding: 0.75rem; background: var(--bg-secondary); border-radius: 0.5rem; transition: all 0.2s;'>" ^
                    "<input type='checkbox' name='trade_accepted' id='trade_accepted' style='margin-right: 0.5rem; width: 18px; height: 18px; cursor: pointer;'>" ^
                    "<span style='font-weight: 600;'>🔄 Aceita Troca</span>" ^
                  "</label>" ^
                "</div>" ^
              "</div>" ^
              "<div class='form-group' style='margin-top: 1rem;'>" ^
                "<label style='display: flex; align-items: center; cursor: pointer; padding: 0.75rem; background: var(--bg-secondary); border-radius: 0.5rem; transition: all 0.2s;'>" ^
                  "<input type='checkbox' name='test_drive_available' id='test_drive_available' style='margin-right: 0.5rem; width: 18px; height: 18px; cursor: pointer;'>" ^
                  "<span style='font-weight: 600;'>🚗 Test Drive Disponível</span>" ^
                "</label>" ^
              "</div>" ^
            "</div>" ^
            
            "<div class='form-section'>" ^
              "<div class='form-section-title' data-icon='🖼️'>Imagens do Veículo</div>" ^
              "<div class='form-group' style='margin-bottom: 1.5rem;'>" ^
                "<label for='image'>URL da Imagem Principal</label>" ^
              "<input type='url' name='image' id='image' required placeholder='https://exemplo.com/imagem.jpg'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label>Imagens Adicionais</label>" ^
                "<div id='images-container'>" ^
                "</div>" ^
                "<button type='button' id='add-image-btn' style='background: var(--bg-secondary); border: 2px dashed var(--border-color); color: var(--text-primary); padding: 0.75rem 1.5rem; border-radius: 0.5rem; cursor: pointer; margin-top: 0.5rem; font-weight: 600; transition: all 0.2s; width: 100%;'>+ Adicionar Outra Imagem</button>" ^
              "</div>" ^
            "</div>" ^
            
            "<div class='form-section'>" ^
              "<div class='form-section-title' data-icon='📝'>Descrição Detalhada</div>" ^
              "<div class='form-group'>" ^
                "<label for='description'>Crie uma descrição rica e detalhada do seu veículo</label>" ^
                "<div id='quill-editor' style='min-height: 300px; background: var(--bg-primary); border-radius: 0.5rem;'></div>" ^
                "<small style='color: var(--text-muted); margin-top: 0.5rem; display: block;'>Use o editor acima para formatar texto, adicionar listas, links e muito mais</small>" ^
              "</div>" ^
            "</div>" ^
            
            "<div class='form-section'>" ^
              "<div class='form-section-title' data-icon='👤'>Informações do Vendedor</div>" ^
              "<div style='display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem;'>" ^
              "<div class='form-group'>" ^
                  "<label>Nome do Vendedor</label>" ^
                  "<input type='text' value='" ^ seller_name ^ "' readonly style='background: var(--bg-secondary); cursor: not-allowed; opacity: 0.7;'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                  "<label>Telefone</label>" ^
                  "<input type='tel' value='" ^ seller_phone ^ "' readonly style='background: var(--bg-secondary); cursor: not-allowed; opacity: 0.7;'>" ^
                "</div>" ^
              "</div>" ^
            "</div>" ^
            
            "<div style='display: flex; gap: 1rem; justify-content: center; margin-top: 2rem; padding-top: 2rem; border-top: 2px solid var(--border-color);'>" ^
              "<button type='submit' class='btn' style='padding: 1rem 3rem; font-size: 1.1rem; font-weight: 700;'>✅ Criar Anúncio</button>" ^
              "<a href='/dashboard' class='btn' style='background: #6c757d; text-decoration: none; display: inline-block; padding: 1rem 3rem; font-size: 1.1rem; font-weight: 700;'>Cancelar</a>" ^
            "</div>" ^
          "</form>" ^
        "</div>" ^
      "</div>" ^
      "<script>" ^
        "var quill;" ^
        "function initAddVehicleForm() {" ^
          "var quillEditor = document.getElementById('quill-editor');" ^
          "if (!quillEditor) {" ^
            "setTimeout(initAddVehicleForm, 100);" ^
            "return;" ^
          "}" ^
          "if (typeof Quill === 'undefined') {" ^
            "setTimeout(initAddVehicleForm, 100);" ^
            "return;" ^
          "}" ^
          "if (quill) return;" ^
          "try {" ^
            "quill = new Quill('#quill-editor', {" ^
              "theme: 'snow'," ^
              "modules: {" ^
                "toolbar: [" ^
                  "['bold', 'italic', 'underline', 'strike']," ^
                  "['blockquote', 'code-block']," ^
                  "[{ 'header': 1 }, { 'header': 2 }]," ^
                  "[{ 'list': 'ordered'}, { 'list': 'bullet' }]," ^
                  "[{ 'script': 'sub'}, { 'script': 'super' }]," ^
                  "[{ 'indent': '-1'}, { 'indent': '+1' }]," ^
                  "[{ 'direction': 'rtl' }]," ^
                  "[{ 'size': ['small', false, 'large', 'huge'] }]," ^
                  "[{ 'header': [1, 2, 3, 4, 5, 6, false] }]," ^
                  "[{ 'color': [] }, { 'background': [] }]," ^
                  "[{ 'font': [] }]," ^
                  "[{ 'align': [] }]," ^
                  "['clean']," ^
                  "['link', 'image']" ^
                "]" ^
              "}" ^
            "});" ^
          "} catch (e) {" ^
            "console.error('Error initializing Quill:', e);" ^
            "setTimeout(initAddVehicleForm, 200);" ^
            "return;" ^
          "}" ^
          "var imageCount = 1;" ^
          "var addImageBtn = document.getElementById('add-image-btn');" ^
          "if (addImageBtn) {" ^
            "addImageBtn.addEventListener('click', function() {" ^
              "var container = document.getElementById('images-container');" ^
              "if (!container) return;" ^
              "imageCount++;" ^
              "var newGroup = document.createElement('div');" ^
              "newGroup.className = 'image-input-group';" ^
              "newGroup.style.marginBottom = '0.5rem';" ^
              "newGroup.innerHTML = '<div style=\\'display: flex; gap: 0.5rem;\\'>' +" ^
                "'<input type=\\'url\\' class=\\'image-url\\' placeholder=\\'https://exemplo.com/imagem.jpg\\' style=\\'flex: 1; padding: 0.75rem; border: 2px solid #e1e5e9; border-radius: 8px; font-size: 1rem;\\'>' +" ^
                "'<button type=\\'button\\' class=\\'remove-image-btn\\' style=\\'background: #ef4444; color: white; border: none; padding: 0.5rem 1rem; border-radius: 0.5rem; cursor: pointer;\\'>Remover</button>' +" ^
                "'</div>';" ^
              "container.appendChild(newGroup);" ^
              "var removeBtn = newGroup.querySelector('.remove-image-btn');" ^
              "if (removeBtn) {" ^
                "removeBtn.addEventListener('click', function() {" ^
                  "newGroup.remove();" ^
                  "imageCount--;" ^
                "});" ^
              "}" ^
            "});" ^
          "}" ^
          "var form = document.getElementById('add-vehicle-form');" ^
          "if (form) {" ^
            "form.addEventListener('submit', function(e) {" ^
              "e.preventDefault();" ^
              "if (quill) {" ^
                "var descriptionText = quill.root.innerHTML;" ^
                "document.getElementById('description-hidden').value = descriptionText;" ^
              "}" ^
              "var imageInputs = document.querySelectorAll('.image-url');" ^
              "var images = [];" ^
              "for (var i = 0; i < imageInputs.length; i++) {" ^
                "var imgValue = imageInputs[i].value.trim();" ^
                "if (imgValue !== '') {" ^
                  "images.push(imgValue);" ^
                "}" ^
              "}" ^
              "var imagesField = document.getElementById('images-hidden');" ^
              "if (imagesField) {" ^
                "imagesField.value = images.join(',');" ^
              "}" ^
              "this.submit();" ^
            "});" ^
          "}" ^
        "}" ^
        "function waitForQuill() {" ^
          "if (typeof Quill !== 'undefined') {" ^
            "initAddVehicleForm();" ^
            "return;" ^
          "}" ^
          "setTimeout(waitForQuill, 100);" ^
        "}" ^
        "if (document.readyState === 'loading') {" ^
          "document.addEventListener('DOMContentLoaded', function() {" ^
            "setTimeout(waitForQuill, 200);" ^
          "});" ^
        "} else {" ^
          "setTimeout(waitForQuill, 200);" ^
        "}" ^
      "</script>"
    )

(* Edit vehicle form template - based on add_vehicle_template *)
let edit_vehicle_template ?error ~(user:Types.user) ~(vehicle:Types.vehicle) () =
  let error_msg = match error with
    | Some msg -> "<div class='error'>" ^ msg ^ "</div>"
    | None -> ""
  in
  let seller_name = user.name in
  let seller_phone = Option.value ~default:"" user.phone in
  
  (* Helper to create option with selected attribute *)
  let option_tag value text selected =
    if value = selected then
      "<option value='" ^ value ^ "' selected>" ^ text ^ "</option>"
    else
      "<option value='" ^ value ^ "'>" ^ text ^ "</option>"
  in
  
  let selected_fuel = vehicle.fuel_type in
  let selected_transmission = vehicle.transmission in
  let selected_doors = string_of_int vehicle.doors in
  let selected_exterior = Option.value ~default:"" vehicle.exterior_condition in
  let selected_interior = Option.value ~default:"" vehicle.interior_condition in
  let selected_mechanical = Option.value ~default:"" vehicle.mechanical_condition in
  let description_html = Option.value ~default:vehicle.description vehicle.detailed_description_md in
  
  (* Clean price and mileage for input fields (remove formatting) *)
  let clean_price = Str.global_replace (Str.regexp "R\\$\\s*\\|\\.") "" vehicle.price |> String.trim in
  let clean_mileage = Str.global_replace (Str.regexp "\\s*km\\s*\\|\\.") "" vehicle.mileage |> String.trim in
  
  (
      "<link href='https://cdn.jsdelivr.net/npm/quill@2.0.3/dist/quill.snow.css' rel='stylesheet' />" ^
      "<script src='https://cdn.jsdelivr.net/npm/quill@2.0.3/dist/quill.js'></script>" ^
      "<style>" ^
        ".form-section { background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem; padding: 2rem; margin-bottom: 2rem; box-shadow: var(--shadow); }" ^
        ".form-section-title { font-size: 1.25rem; font-weight: 700; color: var(--text-primary); margin-bottom: 1.5rem; display: flex; align-items: center; gap: 0.75rem; padding-bottom: 1rem; border-bottom: 2px solid var(--border-color); }" ^
        ".form-section-title::before { content: attr(data-icon); font-size: 1.5rem; }" ^
        ".form-container { max-width: 1000px !important; padding: 3rem !important; }" ^
        ".form-header { text-align: center; margin-bottom: 3rem; padding-bottom: 2rem; border-bottom: 2px solid var(--border-color); }" ^
        ".form-header h2 { font-size: 2rem; font-weight: 800; color: var(--text-primary); margin-bottom: 0.5rem; background: linear-gradient(135deg, var(--accent), var(--accent-hover)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text; }" ^
        ".form-header p { color: var(--text-muted); font-size: 1.1rem; }" ^
        "#quill-editor .ql-container { background: var(--bg-primary) !important; color: var(--text-primary) !important; border-color: var(--border-color) !important; }" ^
        "#quill-editor .ql-editor { background: var(--bg-primary) !important; color: var(--text-primary) !important; }" ^
        "#quill-editor .ql-toolbar { background: var(--bg-secondary) !important; border-color: var(--border-color) !important; }" ^
        "#quill-editor .ql-stroke { stroke: var(--text-primary) !important; }" ^
        "#quill-editor .ql-fill { fill: var(--text-primary) !important; }" ^
        "#quill-editor .ql-picker-label { color: var(--text-primary) !important; }" ^
        "#quill-editor .ql-picker-options { background: var(--bg-card) !important; border-color: var(--border-color) !important; }" ^
        "#quill-editor .ql-picker-item { color: var(--text-primary) !important; }" ^
        "#quill-editor .ql-picker-item:hover { background: var(--bg-secondary) !important; }" ^
        "#quill-editor .ql-snow .ql-picker.ql-expanded .ql-picker-label { border-color: var(--border-color) !important; }" ^
        "@media (max-width: 768px) {" ^
          ".form-container { padding: 1.5rem !important; margin: 0.5rem !important; }" ^
          ".form-header { margin-bottom: 2rem !important; padding-bottom: 1.5rem !important; }" ^
          ".form-header h2 { font-size: 1.5rem !important; }" ^
          ".form-header p { font-size: 0.95rem !important; }" ^
          ".form-section { padding: 1.5rem !important; margin-bottom: 1.5rem !important; }" ^
          ".form-section-title { font-size: 1.1rem !important; padding-bottom: 0.75rem !important; margin-bottom: 1rem !important; }" ^
          ".form-group { margin-bottom: 1rem !important; }" ^
          ".form-group label { font-size: 0.875rem !important; }" ^
          ".form-group input, .form-group select, .form-group textarea { font-size: 0.95rem !important; padding: 0.75rem !important; }" ^
          ".btn { width: 100% !important; margin-top: 0.5rem !important; }" ^
          "#quill-editor .ql-toolbar { padding: 0.5rem !important; }" ^
          "#quill-editor .ql-container { min-height: 200px !important; }" ^
        "}" ^
        "@media (max-width: 480px) {" ^
          ".form-container { padding: 1rem !important; margin: 0.25rem !important; }" ^
          ".form-section { padding: 1.25rem !important; }" ^
          ".form-section-title { font-size: 1rem !important; }" ^
          ".form-header h2 { font-size: 1.25rem !important; }" ^
          ".form-header p { font-size: 0.875rem !important; }" ^
        "}" ^
      "</style>" ^
      "<div class='container'>" ^
        "<div class='form-container'>" ^
          "<div class='form-header'>" ^
            "<h2>✏️ Editar Anúncio</h2>" ^
            "<p>Atualize as informações do seu veículo</p>" ^
          "</div>" ^
          error_msg ^
          
          "<form method='post' action='/dashboard/edit-vehicle/" ^ vehicle.slug ^ "' id='edit-vehicle-form'>" ^
            "<input type='hidden' name='vehicle_id' value='" ^ string_of_int vehicle.id ^ "'>" ^
            "<input type='hidden' name='seller_name' id='seller_name' value='" ^ seller_name ^ "'>" ^
            "<input type='hidden' name='seller_phone' id='seller_phone' value='" ^ seller_phone ^ "'>" ^
            "<input type='hidden' name='description' id='description-hidden'>" ^
            "<input type='hidden' name='images' id='images-hidden'>" ^
            
            "<div class='form-section'>" ^
              "<div class='form-section-title' data-icon='📋'>Informações Básicas</div>" ^
              "<div style='display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; margin-bottom: 1.5rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='brand'>Marca</label>" ^
                "<input type='text' name='brand' id='brand' required value='" ^ vehicle.brand ^ "' placeholder='Ex: Porsche'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='model'>Modelo</label>" ^
                "<input type='text' name='model' id='model' required value='" ^ vehicle.model ^ "' placeholder='Ex: 911 Carrera'>" ^
              "</div>" ^
            "</div>" ^
              "<div style='display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1.5rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='year'>Ano</label>" ^
                "<input type='number' name='year' id='year' required min='1980' max='2025' value='" ^ string_of_int vehicle.year ^ "'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='price'>Preço (R$)</label>" ^
                "<input type='text' name='price' id='price' required value='" ^ clean_price ^ "' placeholder='Ex: 150.000'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='mileage'>Quilometragem</label>" ^
                "<input type='text' name='mileage' id='mileage' required value='" ^ clean_mileage ^ "' placeholder='Ex: 25.000'>" ^
                "</div>" ^
              "</div>" ^
            "</div>" ^
            
            "<div class='form-section'>" ^
              "<div class='form-section-title' data-icon='⚙️'>Especificações Técnicas</div>" ^
              "<div style='display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1.5rem; margin-bottom: 1.5rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='fuel_type'>Combustível</label>" ^
                "<select name='fuel_type' id='fuel_type' required>" ^
                  "<option value=''>Selecione</option>" ^
                  (option_tag "Gasolina" "Gasolina" selected_fuel) ^
                  (option_tag "Flex" "Flex (Gasolina/Álcool)" selected_fuel) ^
                  (option_tag "Diesel" "Diesel" selected_fuel) ^
                  (option_tag "Elétrico" "Elétrico" selected_fuel) ^
                  (option_tag "Híbrido" "Híbrido" selected_fuel) ^
                  (option_tag "GNV" "GNV" selected_fuel) ^
                "</select>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='color'>Cor</label>" ^
                "<input type='text' name='color' id='color' required value='" ^ vehicle.color ^ "' placeholder='Ex: Branco'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='transmission'>Transmissão</label>" ^
                "<select name='transmission' id='transmission' required>" ^
                  "<option value=''>Selecione</option>" ^
                  (option_tag "Manual" "Manual" selected_transmission) ^
                  (option_tag "Automática" "Automática" selected_transmission) ^
                  (option_tag "Automatizada" "Automatizada" selected_transmission) ^
                  (option_tag "CVT" "CVT" selected_transmission) ^
                  (option_tag "DCT" "DCT (Dupla Embreagem)" selected_transmission) ^
                  (option_tag "Sequencial" "Sequencial" selected_transmission) ^
                "</select>" ^
              "</div>" ^
            "</div>" ^
              "<div style='display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1.5rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='engine'>Motor</label>" ^
                "<input type='text' name='engine' id='engine' value='" ^ (Option.value ~default:"" vehicle.engine) ^ "' placeholder='Ex: 3.0L V6 Turbo'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='doors'>Portas</label>" ^
                "<select name='doors' id='doors'>" ^
                  "<option value=''>Selecione</option>" ^
                  (option_tag "2" "2 Portas" selected_doors) ^
                  (option_tag "3" "3 Portas" selected_doors) ^
                  (option_tag "4" "4 Portas" selected_doors) ^
                  (option_tag "5" "5 Portas" selected_doors) ^
                "</select>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='body_style'>Carroceria</label>" ^
                "<input type='text' name='body_style' id='body_style' value='" ^ (Option.value ~default:"" vehicle.body_style) ^ "' placeholder='Ex: Sedan, Hatchback, SUV'>" ^
                "</div>" ^
              "</div>" ^
            "</div>" ^
            
            "<div class='form-section'>" ^
              "<div class='form-section-title' data-icon='📍'>Localização</div>" ^
              "<div style='display: grid; grid-template-columns: 2fr 1fr; gap: 1.5rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='location_city'>Cidade</label>" ^
                "<input type='text' name='location_city' id='location_city' required value='" ^ vehicle.location_city ^ "' placeholder='Ex: São Paulo'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='location_state'>Estado</label>" ^
                "<input type='text' name='location_state' id='location_state' required value='" ^ vehicle.location_state ^ "' placeholder='Ex: SP' maxlength='2'>" ^
                "</div>" ^
              "</div>" ^
            "</div>" ^
            
            "<div class='form-section'>" ^
              "<div class='form-section-title' data-icon='🔍'>Condições do Veículo</div>" ^
              "<div style='display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1.5rem; margin-bottom: 1.5rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='exterior_condition'>Condição do Exterior</label>" ^
                "<select name='exterior_condition' id='exterior_condition'>" ^
                  "<option value=''>Selecione</option>" ^
                  (option_tag "Excelente" "Excelente" selected_exterior) ^
                  (option_tag "Muito Bom" "Muito Bom" selected_exterior) ^
                  (option_tag "Bom" "Bom" selected_exterior) ^
                  (option_tag "Regular" "Regular" selected_exterior) ^
                "</select>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='interior_condition'>Condição do Interior</label>" ^
                "<select name='interior_condition' id='interior_condition'>" ^
                  "<option value=''>Selecione</option>" ^
                  (option_tag "Excelente" "Excelente" selected_interior) ^
                  (option_tag "Muito Bom" "Muito Bom" selected_interior) ^
                  (option_tag "Bom" "Bom" selected_interior) ^
                  (option_tag "Regular" "Regular" selected_interior) ^
                "</select>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label for='mechanical_condition'>Condição Mecânica</label>" ^
                "<select name='mechanical_condition' id='mechanical_condition'>" ^
                  "<option value=''>Selecione</option>" ^
                  (option_tag "Perfeito" "Perfeito" selected_mechanical) ^
                  (option_tag "Excelente" "Excelente" selected_mechanical) ^
                  (option_tag "Muito Bom" "Muito Bom" selected_mechanical) ^
                  (option_tag "Bom" "Bom" selected_mechanical) ^
                "</select>" ^
              "</div>" ^
            "</div>" ^
              "<div style='display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 1.5rem;'>" ^
              "<div class='form-group'>" ^
                "<label for='previous_owners'>Número de Proprietários</label>" ^
                "<input type='number' name='previous_owners' id='previous_owners' min='0' value='" ^ string_of_int vehicle.previous_owners ^ "'>" ^
              "</div>" ^
              "<div class='form-group' style='display: flex; align-items: center; padding-top: 1.75rem;'>" ^
                  "<label style='display: flex; align-items: center; cursor: pointer; padding: 0.75rem; background: var(--bg-secondary); border-radius: 0.5rem; transition: all 0.2s;'>" ^
                    "<input type='checkbox' name='financing_available' id='financing_available' " ^ (if vehicle.financing_available then "checked" else "") ^ " style='margin-right: 0.5rem; width: 18px; height: 18px; cursor: pointer;'>" ^
                    "<span style='font-weight: 600;'>💳 Financiamento Disponível</span>" ^
                "</label>" ^
              "</div>" ^
              "<div class='form-group' style='display: flex; align-items: center; padding-top: 1.75rem;'>" ^
                  "<label style='display: flex; align-items: center; cursor: pointer; padding: 0.75rem; background: var(--bg-secondary); border-radius: 0.5rem; transition: all 0.2s;'>" ^
                    "<input type='checkbox' name='trade_accepted' id='trade_accepted' " ^ (if vehicle.trade_accepted then "checked" else "") ^ " style='margin-right: 0.5rem; width: 18px; height: 18px; cursor: pointer;'>" ^
                    "<span style='font-weight: 600;'>🔄 Aceita Troca</span>" ^
                "</label>" ^
              "</div>" ^
            "</div>" ^
              "<div class='form-group' style='margin-top: 1rem;'>" ^
                "<label style='display: flex; align-items: center; cursor: pointer; padding: 0.75rem; background: var(--bg-secondary); border-radius: 0.5rem; transition: all 0.2s;'>" ^
                  "<input type='checkbox' name='test_drive_available' id='test_drive_available' " ^ (if vehicle.test_drive_available then "checked" else "") ^ " style='margin-right: 0.5rem; width: 18px; height: 18px; cursor: pointer;'>" ^
                  "<span style='font-weight: 600;'>🚗 Test Drive Disponível</span>" ^
              "</label>" ^
              "</div>" ^
            "</div>" ^
            
            "<div class='form-section'>" ^
              "<div class='form-section-title' data-icon='🖼️'>Imagens do Veículo</div>" ^
              "<div class='form-group' style='margin-bottom: 1.5rem;'>" ^
              "<label for='image'>URL da Imagem Principal</label>" ^
              "<input type='url' name='image' id='image' required value='" ^ vehicle.image ^ "' placeholder='https://exemplo.com/imagem.jpg'>" ^
            "</div>" ^
              "<div class='form-group'>" ^
              "<label>Imagens Adicionais</label>" ^
              "<div id='images-container'>" ^
                (List.map (fun img ->
                  "<div class='image-input-group' style='margin-bottom: 0.5rem;'>" ^
                    "<div style='display: flex; gap: 0.5rem;'>" ^
                      "<input type='url' class='image-url' value='" ^ img ^ "' placeholder='https://exemplo.com/imagem.jpg' style='flex: 1; padding: 0.75rem; border: 2px solid #e1e5e9; border-radius: 8px; font-size: 1rem;'>" ^
                      "<button type='button' class='remove-image-btn' style='background: #ef4444; color: white; border: none; padding: 0.5rem 1rem; border-radius: 0.5rem; cursor: pointer;'>Remover</button>" ^
                    "</div>" ^
                  "</div>"
                ) vehicle.images |> String.concat "") ^
              "</div>" ^
                "<button type='button' id='add-image-btn' style='background: var(--bg-secondary); border: 2px dashed var(--border-color); color: var(--text-primary); padding: 0.75rem 1.5rem; border-radius: 0.5rem; cursor: pointer; margin-top: 0.5rem; font-weight: 600; transition: all 0.2s; width: 100%;'>+ Adicionar Outra Imagem</button>" ^
              "</div>" ^
            "</div>" ^
            
            "<div class='form-section'>" ^
              "<div class='form-section-title' data-icon='📝'>Descrição Detalhada</div>" ^
              "<div class='form-group'>" ^
                "<label for='description'>Crie uma descrição rica e detalhada do seu veículo</label>" ^
                "<div id='quill-editor' style='min-height: 300px; background: var(--bg-primary); border-radius: 0.5rem;'>" ^ description_html ^ "</div>" ^
                "<small style='color: var(--text-muted); margin-top: 0.5rem; display: block;'>Use o editor acima para formatar texto, adicionar listas, links e muito mais</small>" ^
              "</div>" ^
            "</div>" ^
            
            "<div class='form-section'>" ^
              "<div class='form-section-title' data-icon='👤'>Informações do Vendedor</div>" ^
              "<div style='display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem;'>" ^
              "<div class='form-group'>" ^
                "<label>Nome do Vendedor</label>" ^
                  "<input type='text' value='" ^ seller_name ^ "' readonly style='background: var(--bg-secondary); cursor: not-allowed; opacity: 0.7;'>" ^
              "</div>" ^
              "<div class='form-group'>" ^
                "<label>Telefone</label>" ^
                  "<input type='tel' value='" ^ seller_phone ^ "' readonly style='background: var(--bg-secondary); cursor: not-allowed; opacity: 0.7;'>" ^
                "</div>" ^
              "</div>" ^
            "</div>" ^
            
            "<div style='display: flex; gap: 1rem; justify-content: center; margin-top: 2rem; padding-top: 2rem; border-top: 2px solid var(--border-color);'>" ^
              "<button type='submit' class='btn' id='submit-edit-btn' style='padding: 1rem 3rem; font-size: 1.1rem; font-weight: 700;'>💾 Salvar Alterações</button>" ^
              "<a href='/vehicle/" ^ vehicle.slug ^ "' class='btn' style='background: #6c757d; text-decoration: none; display: inline-block; padding: 1rem 3rem; font-size: 1.1rem; font-weight: 700;'>Cancelar</a>" ^
            "</div>" ^
          "</form>" ^
        "</div>" ^
      "</div>" ^
      "<script>" ^
        "var quill;" ^
        "function initEditVehicleForm() {" ^
          "var quillEditor = document.getElementById('quill-editor');" ^
          "if (!quillEditor) {" ^
            "setTimeout(initEditVehicleForm, 100);" ^
            "return;" ^
          "}" ^
          "if (typeof Quill === 'undefined') {" ^
            "setTimeout(initEditVehicleForm, 100);" ^
            "return;" ^
          "}" ^
          "if (quill) return;" ^
          "try {" ^
            (* Get content BEFORE initializing Quill, as Quill replaces the div content *)
            "var existingContent = quillEditor.innerHTML;" ^
            "quill = new Quill('#quill-editor', {" ^
              "theme: 'snow'," ^
              "modules: {" ^
                "toolbar: [" ^
                  "['bold', 'italic', 'underline', 'strike']," ^
                  "['blockquote', 'code-block']," ^
                  "[{ 'header': 1 }, { 'header': 2 }]," ^
                  "[{ 'list': 'ordered'}, { 'list': 'bullet' }]," ^
                  "[{ 'script': 'sub'}, { 'script': 'super' }]," ^
                  "[{ 'indent': '-1'}, { 'indent': '+1' }]," ^
                  "[{ 'direction': 'rtl' }]," ^
                  "[{ 'size': ['small', false, 'large', 'huge'] }]," ^
                  "[{ 'header': [1, 2, 3, 4, 5, 6, false] }]," ^
                  "[{ 'color': [] }, { 'background': [] }]," ^
                  "[{ 'font': [] }]," ^
                  "[{ 'align': [] }]," ^
                  "['clean']," ^
                  "['link', 'image']" ^
                "]" ^
              "}" ^
            "});" ^
            (* Set content after Quill is initialized *)
            "if (existingContent && existingContent.trim() !== '' && existingContent.trim() !== '<p><br></p>') {" ^
              "quill.root.innerHTML = existingContent;" ^
            "}" ^
          "} catch (e) {" ^
            "console.error('Error initializing Quill:', e);" ^
            "setTimeout(initEditVehicleForm, 200);" ^
            "return;" ^
          "}" ^
          "var imageCount = " ^ string_of_int (List.length vehicle.images + 1) ^ ";" ^
          "var addImageBtn = document.getElementById('add-image-btn');" ^
          "if (addImageBtn) {" ^
            "addImageBtn.addEventListener('click', function() {" ^
              "var container = document.getElementById('images-container');" ^
              "if (!container) return;" ^
              "imageCount++;" ^
              "var newGroup = document.createElement('div');" ^
              "newGroup.className = 'image-input-group';" ^
              "newGroup.style.marginBottom = '0.5rem';" ^
              "newGroup.innerHTML = '<div style=\\'display: flex; gap: 0.5rem;\\'>' +" ^
                "'<input type=\\'url\\' class=\\'image-url\\' placeholder=\\'https://exemplo.com/imagem.jpg\\' style=\\'flex: 1; padding: 0.75rem; border: 2px solid #e1e5e9; border-radius: 8px; font-size: 1rem;\\'>' +" ^
                "'<button type=\\'button\\' class=\\'remove-image-btn\\' style=\\'background: #ef4444; color: white; border: none; padding: 0.5rem 1rem; border-radius: 0.5rem; cursor: pointer;\\'>Remover</button>' +" ^
                "'</div>';" ^
              "container.appendChild(newGroup);" ^
              "var removeBtn = newGroup.querySelector('.remove-image-btn');" ^
              "if (removeBtn) {" ^
                "removeBtn.addEventListener('click', function() {" ^
                  "newGroup.remove();" ^
                  "imageCount--;" ^
                "});" ^
              "}" ^
            "});" ^
          "}" ^
          "var removeButtons = document.querySelectorAll('.remove-image-btn');" ^
          "removeButtons.forEach(function(btn) {" ^
            "btn.addEventListener('click', function() {" ^
              "this.closest('.image-input-group').remove();" ^
            "});" ^
          "});" ^
          "var form = document.getElementById('edit-vehicle-form');" ^
          "var submitBtn = document.getElementById('submit-edit-btn');" ^
          "if (form && submitBtn) {" ^
            "submitBtn.addEventListener('click', function(e) {" ^
              "e.preventDefault();" ^
              "var descField = document.getElementById('description-hidden');" ^
              "if (!descField) {" ^
                "console.error('description-hidden field not found');" ^
                "alert('Erro: campo de descrição não encontrado');" ^
                "return false;" ^
              "}" ^
              "var descriptionText = '';" ^
              "if (quill) {" ^
                "descriptionText = quill.root.innerHTML;" ^
              "} else {" ^
                "var quillDiv = document.getElementById('quill-editor');" ^
                "if (quillDiv && quillDiv.innerHTML) {" ^
                  "descriptionText = quillDiv.innerHTML;" ^
                "}" ^
              "}" ^
              "if (descriptionText && descriptionText.trim() !== '' && descriptionText.trim() !== '<p><br></p>' && descriptionText.trim() !== '<p></p>') {" ^
                "descField.value = descriptionText;" ^
              "} else {" ^
              "}" ^
              "var imageInputs = document.querySelectorAll('.image-url');" ^
              "var images = [];" ^
              "for (var i = 0; i < imageInputs.length; i++) {" ^
                "var imgValue = imageInputs[i].value.trim();" ^
                "if (imgValue !== '') {" ^
                  "images.push(imgValue);" ^
                "}" ^
              "}" ^
              "var imagesField = document.getElementById('images-hidden');" ^
              "if (imagesField) {" ^
                "imagesField.value = images.join(',');" ^
              "}" ^
              "form.submit();" ^
            "});" ^
          "}" ^
        "}" ^
        "function waitForQuill() {" ^
          "if (typeof Quill !== 'undefined') {" ^
            "initEditVehicleForm();" ^
            "return;" ^
          "}" ^
          "setTimeout(waitForQuill, 100);" ^
        "}" ^
        "if (document.readyState === 'loading') {" ^
          "document.addEventListener('DOMContentLoaded', function() {" ^
            "setTimeout(waitForQuill, 200);" ^
          "});" ^
        "} else {" ^
          "setTimeout(waitForQuill, 200);" ^
        "}" ^
      "</script>"
    )

(* FIPE Consult Page Template *)
let fipe_consult_template ~user:_ () =
  (
    "<div class='container' style='max-width: 1000px; margin: 2rem auto; padding: 0 1rem;'>" ^
      "<div style='text-align: center; margin-bottom: 3rem;'>" ^
        "<h1 style='color: var(--text-primary); font-size: 2.5rem; font-weight: 800; margin-bottom: 0.5rem;'>📊 Consulta FIPE</h1>" ^
        "<p style='color: var(--text-muted); font-size: 1.1rem;'>Consulte preços médios de veículos da Tabela FIPE</p>" ^
      "</div>" ^
      
      "<div style='background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem; padding: 2rem; margin-bottom: 2rem;'>" ^
        "<form id='fipe-form' style='display: flex; flex-direction: column; gap: 1.5rem;'>" ^
          "<div class='form-group'>" ^
            "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem; display: block;'>Tipo de Veículo</label>" ^
            "<select id='vehicle-type' name='vehicle_type' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);'>" ^
              "<option value='cars'>Carros</option>" ^
              "<option value='motorcycles'>Motos</option>" ^
              "<option value='trucks'>Caminhões</option>" ^
            "</select>" ^
          "</div>" ^
          
          "<div class='form-group'>" ^
            "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem; display: block;'>Marca</label>" ^
            "<select id='brand-select' name='brand' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);' disabled>" ^
              "<option value=''>Carregando marcas...</option>" ^
            "</select>" ^
          "</div>" ^
          
          "<div class='form-group'>" ^
            "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem; display: block;'>Modelo</label>" ^
            "<select id='model-select' name='model' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);' disabled>" ^
              "<option value=''>Selecione uma marca primeiro</option>" ^
            "</select>" ^
          "</div>" ^
          
          "<div class='form-group'>" ^
            "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem; display: block;'>Ano</label>" ^
            "<select id='year-select' name='year' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);' disabled>" ^
              "<option value=''>Selecione um modelo primeiro</option>" ^
            "</select>" ^
          "</div>" ^
          
          "<div class='form-group'>" ^
            "<label style='color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem; display: block;'>Referência (Mês)</label>" ^
            "<select id='reference-select' name='reference' style='width: 100%; padding: 0.75rem; border: 1px solid var(--border-color); border-radius: 0.5rem; background: var(--bg-primary); color: var(--text-primary);' disabled>" ^
              "<option value=''>Carregando referências...</option>" ^
            "</select>" ^
          "</div>" ^
          
          "<button type='submit' id='consult-btn' class='btn' style='width: 100%; padding: 1rem; font-size: 1.1rem; font-weight: 600;' disabled>" ^
            "🔍 Consultar Preço FIPE" ^
          "</button>" ^
        "</form>" ^
      "</div>" ^
      
      "<div id='result-container' style='display: none; background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 1rem; padding: 2rem;'>" ^
        "<h2 style='color: var(--text-primary); font-size: 1.5rem; font-weight: 700; margin-bottom: 1.5rem;'>📋 Resultado da Consulta</h2>" ^
        "<div id='result-content'></div>" ^
      "</div>" ^
      
      "<div id='error-container' style='display: none; background: #fee; border: 1px solid #fcc; border-radius: 1rem; padding: 1rem; margin-top: 1rem;'>" ^
        "<p id='error-message' style='color: #c33; margin: 0;'></p>" ^
      "</div>" ^
    "</div>" ^
    
    "<script>" ^
      "(function() {" ^
        "var vehicleTypeSelect = document.getElementById('vehicle-type');" ^
        "var brandSelect = document.getElementById('brand-select');" ^
        "var modelSelect = document.getElementById('model-select');" ^
        "var yearSelect = document.getElementById('year-select');" ^
        "var referenceSelect = document.getElementById('reference-select');" ^
        "var consultBtn = document.getElementById('consult-btn');" ^
        "var resultContainer = document.getElementById('result-container');" ^
        "var errorContainer = document.getElementById('error-container');" ^
        "var resultContent = document.getElementById('result-content');" ^
        "var errorMessage = document.getElementById('error-message');" ^
        
        "var currentBrands = [];" ^
        "var currentModels = [];" ^
        "var currentYears = [];" ^
        "var currentReferences = [];" ^
        
        "function showError(msg) {" ^
          "errorContainer.style.display = 'block';" ^
          "errorMessage.textContent = msg;" ^
          "resultContainer.style.display = 'none';" ^
        "}" ^
        
        "function hideError() {" ^
          "errorContainer.style.display = 'none';" ^
        "}" ^
        
        "function setLoading(element, loading) {" ^
          "if (loading) {" ^
            "element.disabled = true;" ^
            "element.style.opacity = '0.6';" ^
          "} else {" ^
            "element.disabled = false;" ^
            "element.style.opacity = '1';" ^
          "}" ^
        "}" ^
        
        "function loadReferences() {" ^
          "setLoading(referenceSelect, true);" ^
          "referenceSelect.innerHTML = '<option value=\"\">Carregando...</option>';" ^
          "fetch('/fipe/references').then(function(res) { return res.json(); }).then(function(data) {" ^
            "if (data.success && data.data && data.data.references) {" ^
              "currentReferences = data.data.references;" ^
              "referenceSelect.innerHTML = '<option value=\"\">Última disponível</option>';" ^
              "data.data.references.forEach(function(ref) {" ^
                "var option = document.createElement('option');" ^
                "option.value = ref.code;" ^
                "option.textContent = ref.month;" ^
                "referenceSelect.appendChild(option);" ^
              "});" ^
              "setLoading(referenceSelect, false);" ^
            "} else {" ^
              "referenceSelect.innerHTML = '<option value=\"\">Erro ao carregar</option>';" ^
              "setLoading(referenceSelect, false);" ^
            "}" ^
          "}).catch(function(err) {" ^
            "console.error('Error loading references:', err);" ^
            "referenceSelect.innerHTML = '<option value=\"\">Erro ao carregar</option>';" ^
            "setLoading(referenceSelect, false);" ^
          "});" ^
        "}" ^
        
        "function loadBrands() {" ^
          "setLoading(brandSelect, true);" ^
          "brandSelect.innerHTML = '<option value=\"\">Carregando marcas...</option>';" ^
          "var vehicleType = vehicleTypeSelect.value;" ^
          "fetch('/fipe/brands?vehicle_type=' + encodeURIComponent(vehicleType)).then(function(res) { return res.json(); }).then(function(data) {" ^
            "if (data.success && data.data && data.data.brands) {" ^
              "currentBrands = data.data.brands;" ^
              "brandSelect.innerHTML = '<option value=\"\">Selecione uma marca</option>';" ^
              "data.data.brands.forEach(function(brand) {" ^
                "var option = document.createElement('option');" ^
                "option.value = brand.code;" ^
                "option.textContent = brand.name;" ^
                "brandSelect.appendChild(option);" ^
              "});" ^
              "setLoading(brandSelect, false);" ^
            "} else {" ^
              "brandSelect.innerHTML = '<option value=\"\">Erro ao carregar marcas</option>';" ^
              "setLoading(brandSelect, false);" ^
            "}" ^
          "}).catch(function(err) {" ^
            "console.error('Error loading brands:', err);" ^
            "brandSelect.innerHTML = '<option value=\"\">Erro ao carregar marcas</option>';" ^
            "setLoading(brandSelect, false);" ^
          "});" ^
        "}" ^
        
        "function loadModels() {" ^
          "var brandCode = brandSelect.value;" ^
          "if (!brandCode) {" ^
            "modelSelect.innerHTML = '<option value=\"\">Selecione uma marca primeiro</option>';" ^
            "modelSelect.disabled = true;" ^
            "yearSelect.innerHTML = '<option value=\"\">Selecione um modelo primeiro</option>';" ^
            "yearSelect.disabled = true;" ^
            "return;" ^
          "}" ^
          "setLoading(modelSelect, true);" ^
          "modelSelect.innerHTML = '<option value=\"\">Carregando modelos...</option>';" ^
          "var vehicleType = vehicleTypeSelect.value;" ^
          "fetch('/fipe/brands/' + encodeURIComponent(brandCode) + '/models?vehicle_type=' + encodeURIComponent(vehicleType)).then(function(res) { return res.json(); }).then(function(data) {" ^
            "if (data.success && data.data && data.data.models) {" ^
              "currentModels = data.data.models;" ^
              "modelSelect.innerHTML = '<option value=\"\">Selecione um modelo</option>';" ^
              "data.data.models.forEach(function(model) {" ^
                "var option = document.createElement('option');" ^
                "option.value = model.code;" ^
                "option.textContent = model.name;" ^
                "modelSelect.appendChild(option);" ^
              "});" ^
              "setLoading(modelSelect, false);" ^
            "} else {" ^
              "modelSelect.innerHTML = '<option value=\"\">Erro ao carregar modelos</option>';" ^
              "setLoading(modelSelect, false);" ^
            "}" ^
          "}).catch(function(err) {" ^
            "console.error('Error loading models:', err);" ^
            "modelSelect.innerHTML = '<option value=\"\">Erro ao carregar modelos</option>';" ^
            "setLoading(modelSelect, false);" ^
          "});" ^
        "}" ^
        
        "function loadYears() {" ^
          "var brandCode = brandSelect.value;" ^
          "var modelCode = modelSelect.value;" ^
          "if (!brandCode || !modelCode) {" ^
            "yearSelect.innerHTML = '<option value=\"\">Selecione um modelo primeiro</option>';" ^
            "yearSelect.disabled = true;" ^
            "return;" ^
          "}" ^
          "setLoading(yearSelect, true);" ^
          "yearSelect.innerHTML = '<option value=\"\">Carregando anos...</option>';" ^
          "var vehicleType = vehicleTypeSelect.value;" ^
          "var reference = referenceSelect.value || '';" ^
          "var url = '/fipe/brands/' + encodeURIComponent(brandCode) + '/models/' + encodeURIComponent(modelCode) + '/years?vehicle_type=' + encodeURIComponent(vehicleType);" ^
          "if (reference) url += '&reference=' + encodeURIComponent(reference);" ^
          "fetch(url).then(function(res) { return res.json(); }).then(function(data) {" ^
            "if (data.success && data.data && data.data.years) {" ^
              "currentYears = data.data.years;" ^
              "yearSelect.innerHTML = '<option value=\"\">Selecione um ano</option>';" ^
              "data.data.years.forEach(function(year) {" ^
                "var option = document.createElement('option');" ^
                "option.value = year.code;" ^
                "option.textContent = year.name;" ^
                "yearSelect.appendChild(option);" ^
              "});" ^
              "setLoading(yearSelect, false);" ^
            "} else {" ^
              "yearSelect.innerHTML = '<option value=\"\">Erro ao carregar anos</option>';" ^
              "setLoading(yearSelect, false);" ^
            "}" ^
          "}).catch(function(err) {" ^
            "console.error('Error loading years:', err);" ^
            "yearSelect.innerHTML = '<option value=\"\">Erro ao carregar anos</option>';" ^
            "setLoading(yearSelect, false);" ^
          "});" ^
        "}" ^
        
        "function updateConsultButton() {" ^
          "var canConsult = brandSelect.value && modelSelect.value && yearSelect.value;" ^
          "consultBtn.disabled = !canConsult;" ^
        "}" ^
        
        "function formatPrice(priceStr) {" ^
          "if (!priceStr) return 'N/A';" ^
          "var num = parseFloat(priceStr.replace(/[^0-9,]/g, '').replace(',', '.'));" ^
          "if (isNaN(num)) return priceStr;" ^
          "return 'R$ ' + num.toLocaleString('pt-BR', {minimumFractionDigits: 2, maximumFractionDigits: 2});" ^
        "}" ^
        
        "function showResult(detail) {" ^
          "hideError();" ^
          "resultContent.innerHTML = " ^
            "'<div style=\"background: var(--bg-secondary); border-radius: 0.75rem; padding: 2rem;\">' +" ^
              "'<div style=\"margin-bottom: 1.5rem;\">' +" ^
                "'<h3 style=\"color: var(--text-primary); font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem;\">' + detail.brand + '</h3>' +" ^
                "'<p style=\"color: var(--text-secondary); font-size: 1.1rem; margin: 0;\">' + detail.model + '</p>' +" ^
                "'<p style=\"color: var(--text-muted); font-size: 0.9rem; margin-top: 0.25rem;\">Ano: ' + detail.modelYear + '</p>' +" ^
              "'</div>' +" ^
              "'<div style=\"background: var(--accent); color: white; border-radius: 0.75rem; padding: 1.5rem; text-align: center; margin-bottom: 1.5rem;\">' +" ^
                "'<div style=\"font-size: 0.9rem; opacity: 0.9; margin-bottom: 0.5rem;\">💰 Preço FIPE</div>' +" ^
                "'<div style=\"font-size: 2rem; font-weight: 800;\">' + formatPrice(detail.price) + '</div>' +" ^
              "'</div>' +" ^
              "'<div style=\"display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem;\">' +" ^
                "'<div style=\"background: var(--bg-primary); padding: 1rem; border-radius: 0.5rem;\">' +" ^
                  "'<div style=\"color: var(--text-muted); font-size: 0.85rem; margin-bottom: 0.25rem;\">📅 Referência</div>' +" ^
                  "'<div style=\"color: var(--text-primary); font-weight: 600;\">' + detail.referenceMonth + '</div>' +" ^
                "'</div>' +" ^
                "'<div style=\"background: var(--bg-primary); padding: 1rem; border-radius: 0.5rem;\">' +" ^
                  "'<div style=\"color: var(--text-muted); font-size: 0.85rem; margin-bottom: 0.25rem;\">⛽ Combustível</div>' +" ^
                  "'<div style=\"color: var(--text-primary); font-weight: 600;\">' + detail.fuel + '</div>' +" ^
                "'</div>' +" ^
                "'<div style=\"background: var(--bg-primary); padding: 1rem; border-radius: 0.5rem;\">' +" ^
                  "'<div style=\"color: var(--text-muted); font-size: 0.85rem; margin-bottom: 0.25rem;\">🆔 Código FIPE</div>' +" ^
                  "'<div style=\"color: var(--text-primary); font-weight: 600; font-family: monospace;\">' + detail.codeFipe + '</div>' +" ^
                "'</div>' +" ^
              "'</div>' +" ^
              "'<div style=\"margin-top: 1.5rem; padding: 1rem; background: var(--bg-secondary); border-radius: 0.5rem;\">' +" ^
                "'<p style=\"color: var(--text-muted); font-size: 0.9rem; margin: 0; text-align: center;\">' +" ^
                  "'💡 Este é o preço médio de mercado segundo a Tabela FIPE. ' +" ^
                  "'Preços de anúncios podem variar conforme estado de conservação, quilometragem e outros fatores.' +" ^
                "'</p>' +" ^
              "'</div>' +" ^
            "'</div>';" ^
          "resultContainer.style.display = 'block';" ^
        "}" ^
        
        "vehicleTypeSelect.addEventListener('change', function() {" ^
          "loadBrands();" ^
          "modelSelect.innerHTML = '<option value=\"\">Selecione uma marca primeiro</option>';" ^
          "modelSelect.disabled = true;" ^
          "yearSelect.innerHTML = '<option value=\"\">Selecione um modelo primeiro</option>';" ^
          "yearSelect.disabled = true;" ^
          "updateConsultButton();" ^
        "});" ^
        
        "brandSelect.addEventListener('change', function() {" ^
          "loadModels();" ^
          "yearSelect.innerHTML = '<option value=\"\">Selecione um modelo primeiro</option>';" ^
          "yearSelect.disabled = true;" ^
          "updateConsultButton();" ^
        "});" ^
        
        "modelSelect.addEventListener('change', function() {" ^
          "loadYears();" ^
          "updateConsultButton();" ^
        "});" ^
        
        "referenceSelect.addEventListener('change', function() {" ^
          "if (modelSelect.value) {" ^
            "loadYears();" ^
          "}" ^
        "});" ^
        
        "yearSelect.addEventListener('change', updateConsultButton);" ^
        
        "document.getElementById('fipe-form').addEventListener('submit', function(e) {" ^
          "e.preventDefault();" ^
          "var brandCode = brandSelect.value;" ^
          "var modelCode = modelSelect.value;" ^
          "var yearId = yearSelect.value;" ^
          "if (!brandCode || !modelCode || !yearId) {" ^
            "showError('Por favor, preencha todos os campos.');" ^
            "return;" ^
          "}" ^
          "setLoading(consultBtn, true);" ^
          "hideError();" ^
          "var vehicleType = vehicleTypeSelect.value;" ^
          "var reference = referenceSelect.value || '';" ^
          "var url = '/fipe/brands/' + encodeURIComponent(brandCode) + '/models/' + encodeURIComponent(modelCode) + '/years/' + encodeURIComponent(yearId) + '?vehicle_type=' + encodeURIComponent(vehicleType);" ^
          "if (reference) url += '&reference=' + encodeURIComponent(reference);" ^
          "fetch(url).then(function(res) { return res.json(); }).then(function(data) {" ^
            "setLoading(consultBtn, false);" ^
            "if (data.success && data.data) {" ^
              "showResult(data.data);" ^
            "} else {" ^
              "showError('Erro ao consultar preço FIPE. ' + (data.message || 'Tente novamente.'));" ^
            "}" ^
          "}).catch(function(err) {" ^
            "setLoading(consultBtn, false);" ^
            "console.error('Error consulting FIPE:', err);" ^
            "showError('Erro ao consultar preço FIPE. Tente novamente.');" ^
          "});" ^
        "});" ^
        
        "loadReferences();" ^
        "loadBrands();" ^
      "})();" ^
    "</script>"
  )


