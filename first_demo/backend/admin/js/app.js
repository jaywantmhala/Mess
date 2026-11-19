const LOCATION_DATA = (typeof window !== 'undefined' && window.LOCATION_DATA) ? window.LOCATION_DATA : {
  defaultCountry: 'India',
  countries: ['India', 'United States', 'United Kingdom', 'Canada', 'Australia', 'United Arab Emirates'],
  statesByCountry: {
    'India': [
      'Maharashtra', 'Gujarat', 'Karnataka', 'Tamil Nadu', 'Uttar Pradesh', 'Rajasthan',
      'Madhya Pradesh', 'Delhi', 'Kerala', 'Telangana', 'Andhra Pradesh', 'Punjab',
      'Haryana', 'Bihar', 'West Bengal', 'Goa', 'Himachal Pradesh', 'Uttarakhand',
      'Jharkhand', 'Odisha', 'Assam', 'Jammu & Kashmir'
    ],
    'United States': ['California', 'Texas', 'Florida', 'New York', 'Illinois'],
    'United Kingdom': ['England', 'Scotland', 'Wales', 'Northern Ireland'],
    'Canada': ['Ontario', 'Quebec', 'British Columbia', 'Alberta'],
    'Australia': ['New South Wales', 'Victoria', 'Queensland', 'Western Australia'],
    'United Arab Emirates': ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman']
  },
  districtsByState: {
    'Maharashtra': [
      'Mumbai City', 'Mumbai Suburban', 'Thane', 'Palghar', 'Raigad', 'Ratnagiri', 'Sindhudurg',
      'Pune', 'Satara', 'Sangli', 'Kolhapur', 'Solapur', 'Nashik', 'Dhule', 'Nandurbar',
      'Jalgaon', 'Ahilyanagar', 'Chhatrapati Sambhajinagar', 'Jalna', 'Beed', 'Dharashiv',
      'Latur', 'Nanded', 'Parbhani', 'Hingoli', 'Amravati', 'Akola', 'Washim', 'Buldhana',
      'Yavatmal', 'Wardha', 'Nagpur', 'Bhandara', 'Gondia', 'Chandrapur', 'Gadchiroli'
    ],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar', 'Gandhinagar'],
    'Karnataka': ['Bengaluru Urban', 'Bengaluru Rural', 'Mysuru', 'Mangaluru', 'Hubballi-Dharwad', 'Belagavi'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Varanasi', 'Agra', 'Noida', 'Ghaziabad', 'Prayagraj'],
    'Delhi': ['New Delhi', 'North Delhi', 'South Delhi', 'East Delhi', 'West Delhi']
  },
  talukasByDistrict: {
    'Mumbai City': ['Mumbai City'],
    'Mumbai Suburban': ['Andheri', 'Borivali', 'Kurla'],
    'Thane': ['Thane', 'Kalyan', 'Bhiwandi', 'Shahapur', 'Murbad', 'Ulhasnagar', 'Ambernath'],
    'Palghar': ['Palghar', 'Dahanu', 'Talasari', 'Jawhar', 'Mokhada', 'Vikramgad', 'Wada', 'Vasai'],
    'Raigad': ['Alibag', 'Pen', 'Panvel', 'Uran', 'Karjat', 'Khalapur', 'Roha', 'Mangaon', 'Tala', 'Murud', 'Mahad', 'Poladpur', 'Shrivardhan', 'Mhasla'],
    'Ratnagiri': ['Ratnagiri', 'Sangameshwar', 'Chiplun', 'Guhagar', 'Dapoli', 'Khed', 'Mandangad', 'Lanja', 'Rajapur'],
    'Sindhudurg': ['Kankavli', 'Vaibhavwadi', 'Kudal', 'Malvan', 'Sawantwadi', 'Vengurla', 'Dodamarg', 'Devgad'],
    'Pune': ['Pune City', 'Haveli', 'Maval', 'Mulshi', 'Khed', 'Shirur', 'Purandar', 'Bhor', 'Velhe', 'Junnar', 'Ambegaon', 'Daund', 'Indapur', 'Baramati'],
    'Satara': ['Satara', 'Jaoli', 'Koregaon', 'Wai', 'Mahabaleshwar', 'Khandala', 'Phaltan', 'Man', 'Khatav', 'Karad', 'Patan'],
    'Sangli': ['Miraj', 'Kavathe Mahankal', 'Jat', 'Tasgaon', 'Khanapur', 'Atpadi', 'Palus', 'Kadegaon', 'Walwa', 'Shirala'],
    'Kolhapur': ['Karvir', 'Panhala', 'Shahuwadi', 'Kagal', 'Hatkanangale', 'Shirol', 'Radhanagari', 'Gaganbawada', 'Bhudargad', 'Ajra', 'Chandgad'],
    'Solapur': ['North Solapur', 'South Solapur', 'Barshi', 'Akkalkot', 'Madha', 'Karmala', 'Mohol', 'Malshiras', 'Pandharpur', 'Sangole', 'Mangalvedhe'],
    'Nashik': ['Nashik', 'Igatpuri', 'Dindori', 'Peint', 'Trimbakeshwar', 'Kalwan', 'Deola', 'Baglan', 'Malegaon', 'Nandgaon', 'Chandwad', 'Niphad', 'Sinnar', 'Yeola', 'Surgana'],
    'Dhule': ['Dhule', 'Sakri', 'Shirpur', 'Shindkheda'],
    'Nandurbar': ['Nandurbar', 'Navapur', 'Shahada', 'Taloda', 'Akkalkuwa', 'Akrani'],
    'Jalgaon': ['Jalgaon', 'Jamner', 'Erandol', 'Dharangaon', 'Bhusawal', 'Raver', 'Muktainagar', 'Bodwad', 'Yawal', 'Amalner', 'Parola', 'Chopda', 'Pachora', 'Bhadgaon', 'Chalisgaon'],
    'Ahilyanagar': ['Ahilyanagar', 'Akole', 'Jamkhed', 'Karjat', 'Kopargaon', 'Nevasa', 'Parner', 'Pathardi', 'Rahata', 'Rahuri', 'Sangamner', 'Shevgaon', 'Shrigonda', 'Shrirampur'],
    'Ahmednagar': ['Ahilyanagar', 'Akole', 'Jamkhed', 'Karjat', 'Kopargaon', 'Nevasa', 'Parner', 'Pathardi', 'Rahata', 'Rahuri', 'Sangamner', 'Shevgaon', 'Shrigonda', 'Shrirampur'],
    'Chhatrapati Sambhajinagar': ['Chhatrapati Sambhajinagar', 'Kannad', 'Soegaon', 'Sillod', 'Phulambri', 'Khultabad', 'Vaijapur', 'Gangapur', 'Paithan'],
    'Aurangabad': ['Chhatrapati Sambhajinagar', 'Kannad', 'Soegaon', 'Sillod', 'Phulambri', 'Khultabad', 'Vaijapur', 'Gangapur', 'Paithan'],
    'Jalna': ['Jalna', 'Bhokardan', 'Jafrabad', 'Badnapur', 'Ambad', 'Ghansawangi', 'Partur', 'Mantha'],
    'Beed': ['Beed', 'Georai', 'Majalgaon', 'Dharur', 'Wadwani', 'Parli', 'Patoda', 'Ashti', 'Shirur Kasar', 'Ambajogai', 'Kaij'],
    'Dharashiv': ['Dharashiv', 'Tuljapur', 'Umarga', 'Lohara', 'Kalamb', 'Bhum', 'Paranda', 'Washi'],
    'Osmanabad': ['Dharashiv', 'Tuljapur', 'Umarga', 'Lohara', 'Kalamb', 'Bhum', 'Paranda', 'Washi'],
    'Latur': ['Latur', 'Ausa', 'Renapur', 'Nilanga', 'Deoni', 'Udgir', 'Ahmedpur', 'Jalkot', 'Shirur Anantpal', 'Chakur'],
    'Nanded': ['Nanded', 'Ardhapur', 'Mudkhed', 'Bhokar', 'Umri', 'Loha', 'Kandhar', 'Kinwat', 'Himayatnagar', 'Hadgaon', 'Mahur', 'Deglur', 'Mukhed', 'Dharmabad', 'Biloli', 'Naigaon'],
    'Parbhani': ['Parbhani', 'Sonpeth', 'Manwath', 'Pathri', 'Gangakhed', 'Palam', 'Purna', 'Jintur', 'Sailu'],
    'Hingoli': ['Hingoli', 'Basmath', 'Kalamnuri', 'Sengaon', 'Aundha Nagnath'],
    'Amravati': ['Amravati', 'Bhatkuli', 'Nandgaon Khandeshwar', 'Dharni', 'Chikhaldara', 'Achalpur', 'Chandurbazar', 'Morshi', 'Warud', 'Daryapur', 'Anjangaon Surji', 'Chandur Railway', 'Dhamangaon Railway', 'Tiosa'],
    'Akola': ['Akola', 'Akot', 'Telhara', 'Balapur', 'Patur', 'Murtizapur', 'Barshitakli'],
    'Washim': ['Washim', 'Malegaon', 'Risod', 'Mangrulpir', 'Karanja', 'Manora'],
    'Buldhana': ['Buldhana', 'Chikhli', 'Deulgaon Raja', 'Jalgaon Jamod', 'Sangrampur', 'Malkapur', 'Motala', 'Nandura', 'Khamgaon', 'Shegaon', 'Mehkar', 'Sindkhed Raja', 'Lonar'],
    'Yavatmal': ['Yavatmal', 'Arni', 'Babhulgaon', 'Darwha', 'Digras', 'Ghatanji', 'Kalamb', 'Kelapur', 'Mahagaon', 'Maregaon', 'Ner', 'Pusad', 'Ralegaon', 'Umarkhed', 'Wani', 'Zari-Jamani'],
    'Wardha': ['Wardha', 'Seloo', 'Deoli', 'Hinganghat', 'Samudrapur', 'Arvi', 'Ashti', 'Karanja'],
    'Nagpur': ['Nagpur Urban', 'Nagpur Rural', 'Kamptee', 'Hingna', 'Katol', 'Narkhed', 'Saoner', 'Kalmeshwar', 'Ramtek', 'Parseoni', 'Kuhi', 'Umred', 'Bhiwapur', 'Mouda'],
    'Bhandara': ['Bhandara', 'Tumsar', 'Pauni', 'Mohadi', 'Sakoli', 'Lakhani', 'Lakhandur'],
    'Gondia': ['Gondia', 'Tirora', 'Goregaon', 'Arjuni Morgaon', 'Deori', 'Sadak Arjuni', 'Salekasa', 'Amgaon'],
    'Chandrapur': ['Chandrapur', 'Ballarpur', 'Warora', 'Chimur', 'Brahmapuri', 'Nagbhid', 'Sindewahi', 'Mul', 'Saoli', 'Gondpipri', 'Rajura', 'Korpana', 'Jiwati', 'Bhadravati', 'Pombhurna'],
    'Gadchiroli': ['Gadchiroli', 'Dhanora', 'Chamorshi', 'Mulchera', 'Desaiganj', 'Armori', 'Kurkheda', 'Korchi', 'Aheri', 'Etapalli', 'Bhamragad', 'Sironcha'],
    'Ahmedabad': ['Ahmedabad City', 'Daskroi', 'Sanand', 'Bavla', 'Dholka', 'Viramgam', 'Mandal', 'Detroj-Rampura', 'Dholera'],
    'Surat': ['Surat City', 'Chorasi', 'Olpad', 'Kamrej', 'Bardoli', 'Mahuva', 'Mandvi', 'Mangrol', 'Palsana', 'Umarpada'],
    'Vadodara': ['Vadodara', 'Dabhoi', 'Karjan', 'Padra', 'Savli', 'Vaghodia', 'Sinor', 'Desar'],
    'Rajkot': ['Rajkot', 'Gondal', 'Jetpur', 'Jasdan', 'Dhoraji', 'Morbi', 'Kotda Sangani', 'Paddhari', 'Lodhika'],
    'Bengaluru Urban': ['Bengaluru North', 'Bengaluru South', 'Bengaluru East', 'Anekal', 'Yelahanka'],
    'Mysuru': ['Mysuru', 'Nanjangud', 'Hunsur', 'Piriyapatna', 'T. Narasipura', 'KR Nagar', 'Saragur'],
    'Chennai': ['Egmore', 'Mylapore', 'Tondiarpet', 'Guindy', 'Velachery', 'Ambattur', 'Ayanavaram', 'Aminjikarai'],
    'Coimbatore': ['Coimbatore North', 'Coimbatore South', 'Pollachi', 'Mettupalayam', 'Annur', 'Sulur', 'Valparai'],
    'Lucknow': ['Lucknow', 'Mohanlalganj', 'Malihabad', 'Bakshi Ka Talab', 'Sarojani Nagar'],
    'Varanasi': ['Varanasi', 'Pindra', 'Raja Talab']
  }
};

/**
 * Omni Admin Panel - Application Framework
 * Handles SPA Routing, Page Templates, Event Handlers, Input Validation, and State Management.
 */

class App {
    constructor() {
        this.currentPath = '';
        this.selectedDeleteId = null;
        this.selectedDeleteType = null; // 'vendor' or 'user'
        this.debouncedSearchTimeout = null;

        // Current area coordinates state
        this.currentMainAreaLat = null;
        this.currentMainAreaLng = null;
        this.currentMainAreaBounds = null;
        this.currentMainAreaCity = '';

        // Live delivery tracking state
        this.deliveryTrackingQuery = { search: '', status: 'active', page: 1, limit: 50 };
        this.deliveryTrackingTimer = null;
        this.deliveryTrackingModalMap = null;
        this.deliveryTrackingMarkers = [];
        this.deliveryTrackingDirectionsRenderer = null;
        this.currentDeliveryOrders = [];
        this.activeTrackedOrder = null;

        // Current page query state
        this.vendorQuery = { search: '', status: 'all', sort: 'newest', date: '', country: 'India', state: '', district: '', taluka: '', region: '', area: '', page: 1, limit: 8 };
        this.userQuery = { search: '', status: 'all', sort: 'newest', date: '', country: 'India', state: '', district: '', taluka: '', region: '', area: '', page: 1, limit: 8 };
        this.subscriptionQuery = { search: '', status: 'all', page: 1, limit: 8 };
        this.driverQuery = { search: '', status: 'all', sort: 'newest', date: '', country: 'India', state: '', district: '', taluka: '', region: '', area: '', page: 1, limit: 8 };
        this.revenueQuery = { search: '', status: 'all', country: 'India', state: '', district: '', taluka: '', region: '', area: '', page: 1, limit: 15 };
        this.payoutQuery = { search: '', status: 'all', page: 1, limit: 15 };
        this.enquiriesQuery = { search: '', status: 'all', state: 'all', district: 'all', taluka: 'all', area: 'all', date_filter: 'all', start_date: '', end_date: '', page: 1, limit: 15 };
        this.currentEnquiries = [];
        this.activePayoutSubTab = 'contacts';
        this.currentRazorpayContacts = [];
        
        // Decoded URL parameters state
        this.decodedQuery = new URLSearchParams();

        this.init();
    }

    init() {
        // Intercept all link clicks for custom routing
        document.body.addEventListener('click', (e) => {
            const link = e.target.closest('[data-link]');
            if (link) {
                e.preventDefault();
                const path = link.getAttribute('href');
                this.navigateTo(path);
            }
        });

        // Listen for history popstate events
        window.addEventListener('popstate', () => {
            this.handleRoute();
        });

        // Listen for global unauthorized API errors
        window.addEventListener('unauthorized-api-call', () => {
            this.showToast('Session expired. Please log in again.', 'error');
            this.navigateTo('/admin/login');
        });

        // Set up UI general triggers
        try {
            this.setupGeneralEvents();
        } catch (e) {
            console.warn("setupGeneralEvents warning:", e);
        }

        // Initialize Ably Realtime listener
        try {
            this.initAblyRealtime();
        } catch (e) {
            console.warn("initAblyRealtime warning:", e);
        }

        // Initial Routing
        this.handleRoute();
    }

    /**
     * SPA navigation entrypoint
     */
    navigateTo(path) {
        let cleanPath = path;
        if (!cleanPath.startsWith("/admin")) {
            cleanPath = "/admin" + (cleanPath.startsWith("/") ? "" : "/") + cleanPath;
        }
        
        let relPath = cleanPath.replace(/^\/admin\/?/, "").replace(/^\//, "");
        if (relPath === "") relPath = "dashboard";
        const encryptedToken = btoa(relPath).replace(/=/g, "");
        
        try {
            history.pushState(null, "", "/admin/index.php?session=" + encryptedToken);
        } catch (e) {
            history.pushState(null, "", cleanPath);
        }
        
        this.handleRoute();
    }

    /**
     * Route handler: parses pathname and renders views
     */
    async handleRoute() {
        const urlParams = new URLSearchParams(window.location.search);
        const sessionToken = urlParams.get("session");
        
        let path = "";
        let decodedQueryString = "";
        if (sessionToken) {
            try {
                let base64 = sessionToken;
                while (base64.length % 4 !== 0) {
                    base64 += "=";
                }
                const relPath = atob(base64);
                if (relPath.includes("?")) {
                    const parts = relPath.split("?");
                    path = "/admin/" + parts[0];
                    decodedQueryString = parts[1];
                } else {
                    path = "/admin/" + relPath;
                }
            } catch (e) {
                path = window.location.pathname;
            }
        } else {
            path = window.location.pathname.replace(/\/$/, "");
            if (path === "/admin" || path === "/admin/" || path === "" || path === "/" || path === "/index.php" || path === "/admin/index.php") {
                path = "/admin/dashboard";
            } else if (!path.startsWith("/admin/")) {
                path = "/admin/" + path;
            }
        }

        path = path.replace(/\/+/g, "/");

        this.currentPath = path;
        this.decodedQuery = new URLSearchParams(decodedQueryString);

        const isAuthenticated = (typeof api !== "undefined" && api !== null) ? !!api.getToken() : false;
        const isAuthRoute = this.currentPath === "/admin/login" || this.currentPath === "/admin/signup";

        const appContainer = document.getElementById("app-container");
        const authContainer = document.getElementById("auth-container");

        if (!isAuthenticated && !isAuthRoute) {
            this.currentPath = "/admin/login";
            if (appContainer) appContainer.classList.add("hidden");
            if (authContainer) authContainer.classList.remove("hidden");
            this.renderAuthView();
            return;
        }

        if (isAuthenticated && isAuthRoute) {
            this.currentPath = "/admin/dashboard";
            if (authContainer) authContainer.classList.add("hidden");
            if (appContainer) appContainer.classList.remove("hidden");
            this.updateSidebarActiveState();
            this.updateProfileTopbar();
            await this.renderContentView();
            return;
        }

        if (isAuthRoute) {
            if (appContainer) appContainer.classList.add("hidden");
            if (authContainer) authContainer.classList.remove("hidden");
            this.renderAuthView();
        } else {
            if (authContainer) authContainer.classList.add("hidden");
            if (appContainer) appContainer.classList.remove("hidden");
            this.updateSidebarActiveState();
            this.updateProfileTopbar();
            await this.renderContentView();
        }

        const sidebar = document.getElementById("sidebar");
        if (sidebar) sidebar.classList.remove("open");
    }

    /**
     * Highlight current route in sidebar
     */
    updateSidebarActiveState() {
        const links = document.querySelectorAll('.nav-link');
        links.forEach(link => {
            const href = link.getAttribute('href');
            const cleanPath = this.currentPath.replace(/^\/admin/, '');
            const cleanHref = href.replace(/^\/admin/, '');
            if (cleanPath.startsWith(cleanHref) && cleanHref !== '' && cleanHref !== '/') {
                link.classList.add('active');
            } else if ((cleanPath === '/dashboard' || cleanPath === '') && (cleanHref === '/dashboard' || cleanHref === '')) {
                link.classList.add('active');
            } else {
                link.classList.remove('active');
            }
        });
    }

    /**
     * Populate profile avatar & name in topbar
     */
    updateProfileTopbar() {
        const adminData = localStorage.getItem('omni_admin_user');
        if (adminData) {
            try {
                const admin = JSON.parse(adminData);
                document.getElementById('admin-display-name').textContent = admin.full_name || 'Admin';
                const firstChar = (admin.full_name || 'A').charAt(0).toUpperCase();
                document.getElementById('admin-avatar-char').textContent = firstChar;
            } catch (e) {
                console.error(e);
            }
        }
    }

    /**
     * UI Element Event Bindings
     */
    setupGeneralEvents() {
        // Sidebar Toggles
        const toggleBtn = document.getElementById('sidebar-toggle-btn');
        const closeBtn = document.getElementById('sidebar-close-btn');

        if (toggleBtn) {
            toggleBtn.addEventListener('click', () => {
                const sb = document.getElementById('sidebar');
                if (sb) sb.classList.add('open');
            });
        }

        if (closeBtn) {
            closeBtn.addEventListener('click', () => {
                const sb = document.getElementById('sidebar');
                if (sb) sb.classList.remove('open');
            });
        }

        // Sign Out trigger
        const logoutBtn = document.getElementById('logout-btn');
        if (logoutBtn) {
            logoutBtn.addEventListener('click', async () => {
                this.showLoader(true);
                try {
                    await api.logout();
                    this.showToast('Logged out successfully.', 'success');
                    this.navigateTo('/admin/login');
                } catch (e) {
                    this.showToast('Error logging out.', 'error');
                } finally {
                    this.showLoader(false);
                }
            });
        }

        // Delete Confirm trigger in modal
        const confirmDeleteBtn = document.getElementById('confirm-delete-btn');
        if (confirmDeleteBtn) {
            confirmDeleteBtn.addEventListener('click', async () => {
                await this.executeDelete();
            });
        }
    }

    /* -- Views Rendering --------------------------------------------------- */

    /**
     * Renders Auth Views (Login & Signup)
     */
    renderAuthView() {
        const authViewContainer = document.getElementById('auth-view');
        
        if (this.currentPath === '/admin/login') {
            authViewContainer.innerHTML = `
                <div class="auth-card">
                    <div class="auth-header">
                        <div class="auth-logo" style="background: none; width: 64px; height: 64px; margin: 0 auto 16px;">
                            <img src="/admin/logo.png" alt="Hungrily Logo" style="width: 100%; height: 100%; border-radius: 50%; object-fit: cover; box-shadow: 0 0 10px rgba(0,0,0,0.5);">
                        </div>
                        <h2 class="auth-title">Hungrily Food's</h2>
                        <p class="auth-subtitle">Log in to manage service locations and meals</p>
                    </div>
                    <form id="login-form" onsubmit="app.handleLogin(event)">
                        <div class="form-group">
                            <label class="form-label" for="login-email">Email Address</label>
                            <input type="email" id="login-email" class="form-control" placeholder="admin@hungrily.com" required>
                            <div class="form-error hidden" id="error-email"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="login-password">Password</label>
                            <input type="password" id="login-password" class="form-control" placeholder="••••••••" required>
                            <div class="form-error hidden" id="error-password"></div>
                        </div>
                        <button type="submit" class="btn btn-primary" style="width: 100%; margin-top: 10px;">
                            <span>Log In</span>
                            <i class="fa-solid fa-arrow-right-to-bracket"></i>
                        </button>
                    </form>
                    <div class="auth-footer">
                        <p>Need a system account? <a href="/admin/signup" class="auth-link" data-link>Create Admin Account</a></p>
                    </div>
                </div>
            `;
        } else if (this.currentPath === '/admin/signup') {
            authViewContainer.innerHTML = `
                <div class="auth-card">
                    <div class="auth-header">
                        <div class="auth-logo" style="background: none; width: 64px; height: 64px; margin: 0 auto 16px;">
                            <img src="/admin/logo.png" alt="Hungrily Logo" style="width: 100%; height: 100%; border-radius: 50%; object-fit: cover; box-shadow: 0 0 10px rgba(0,0,0,0.5);">
                        </div>
                        <h2 class="auth-title">Hungrily Food's</h2>
                        <p class="auth-subtitle">Register a new system administrator</p>
                    </div>
                    <form id="signup-form" onsubmit="app.handleSignup(event)">
                        <div class="form-group">
                            <label class="form-label" for="signup-name">Full Name</label>
                            <input type="text" id="signup-name" class="form-control" placeholder="Administrator Name" required>
                            <div class="form-error hidden" id="error-name"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="signup-email">Email Address</label>
                            <input type="email" id="signup-email" class="form-control" placeholder="admin@hungrily.com" required>
                            <div class="form-error hidden" id="error-email"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="signup-password">Password</label>
                            <input type="password" id="signup-password" class="form-control" placeholder="At least 8 chars, letter & number" required>
                            <div class="form-error hidden" id="error-password"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="signup-confirm-password">Confirm Password</label>
                            <input type="password" id="signup-confirm-password" class="form-control" placeholder="••••••••" required>
                            <div class="form-error hidden" id="error-confirm-password"></div>
                        </div>
                        <button type="submit" class="btn btn-primary" style="width: 100%; margin-top: 10px;">
                            <span>Register Admin</span>
                            <i class="fa-solid fa-user-plus"></i>
                        </button>
                    </form>
                    <div class="auth-footer">
                        <p>Already registered? <a href="/admin/login" class="auth-link" data-link>Log In</a></p>
                    </div>
                </div>
            `;
        }
    }

    /**
     * Renders Content Views
     */
    async renderContentView() {
        const viewContainer = document.getElementById('content-view');
        const pageTitle = document.getElementById('page-title');
        
        this.showLoader(true);

        const rawPath = this.currentPath.replace(/\/+$/, '');
        let cleanRoute = rawPath.replace(/^\/admin/, '');
        if (cleanRoute === '' || cleanRoute === '/') cleanRoute = '/dashboard';

        if (cleanRoute !== '/delivery-tracking') {
            this.clearDeliveryTrackingTimer();
        }

        try {
            if (cleanRoute === '/dashboard') {
                pageTitle.textContent = 'Dashboard';
                await this.loadDashboardView(viewContainer);
            } 
            else if (cleanRoute === '/vendors') {
                pageTitle.textContent = 'Vendor Management';
                await this.loadVendorsView(viewContainer);
            } 
            else if (cleanRoute === '/payouts') {
                pageTitle.textContent = 'Vendor Payouts & Settlements';
                await this.loadPayoutsView(viewContainer);
            } 
            else if (cleanRoute === '/vendors/add') {
                pageTitle.textContent = 'Add New Vendor';
                this.loadAddVendorView(viewContainer);
            }
            else if (cleanRoute === '/vendors/edit') {
                pageTitle.textContent = 'Edit Vendor Account';
                await this.loadEditVendorView(viewContainer);
            }
            else if (cleanRoute === '/drivers') {
                pageTitle.textContent = 'Delivery Drivers Directory';
                await this.loadDriversView(viewContainer);
            }
            else if (cleanRoute === '/drivers/edit') {
                pageTitle.textContent = 'Edit Delivery Driver';
                await this.loadEditDriverView(viewContainer);
            }
            else if (cleanRoute === '/delivery-tracking') {
                pageTitle.textContent = 'Live Delivery Tracking';
                await this.loadDeliveryTrackingView(viewContainer);
            }
            else if (cleanRoute === '/revenue') {
                pageTitle.textContent = 'Location Revenue Analytics';
                await this.loadRevenueView(viewContainer);
            }
            else if (cleanRoute === '/users') {
                pageTitle.textContent = 'Customer Management';
                await this.loadUsersView(viewContainer);
            } 
            else if (cleanRoute === '/users/add') {
                pageTitle.textContent = 'Add New Customer';
                this.loadAddUserView(viewContainer);
            }
            else if (cleanRoute === '/users/edit') {
                pageTitle.textContent = 'Edit Customer Profile';
                await this.loadEditUserView(viewContainer);
            }
            else if (cleanRoute === '/profile') {
                pageTitle.textContent = 'Administrator Profile';
                await this.loadProfileView(viewContainer);
            }
            else if (cleanRoute === '/areas') {
                pageTitle.textContent = 'Location & Plan Management';
                await this.loadAreasView(viewContainer);
            }
            else if (cleanRoute === '/subscriptions') {
                pageTitle.textContent = 'Subscription Management';
                await this.loadSubscriptionsView(viewContainer);
            }
            else if (cleanRoute === '/notifications') {
                pageTitle.textContent = 'Push Notification Broadcast';
                await this.loadNotificationsView(viewContainer);
            }
            else if (cleanRoute === '/whatsapp') {
                pageTitle.textContent = 'WhatsApp Bulk Broadcast';
                await this.loadWhatsAppBroadcastView(viewContainer);
            }
            else if (cleanRoute === '/enquiries') {
                pageTitle.textContent = 'Website Customer Enquiries';
                await this.loadEnquiriesView(viewContainer);
            }
            else {
                // fallback
                pageTitle.textContent = 'Dashboard';
                this.navigateTo('/dashboard');
            }
        } catch (error) {
            this.showToast('Failed to load page. ' + error.message, 'error');
            viewContainer.innerHTML = `<div class="text-center text-danger" style="margin-top: 40px;"><h3>Error loading view</h3><p>${error.message}</p></div>`;
        } finally {
            this.showLoader(false);
        }
    }
    /* -- View Loaders ------------------------------------------------------ */

    /**
     * Dashboard View
     */
    async loadDashboardView(container) {
        // Render skeleton cards first
        container.innerHTML = `
            <div class="dashboard-banner">
                <h2 class="banner-title">Welcome to Hungrily Foods Panel</h2>
            </div>
            <div class="dashboard-grid">
                ${'<div class="stat-card skeleton" style="height: 104px;"></div>'.repeat(5)}
            </div>
        `;

        try {
            const result = await api.getDashboardSummary();
            const stats = result.data.summary;
            
            container.innerHTML = `
                <div class="dashboard-banner">
                    <h2 class="banner-title">Welcome to Hungrily Foods Panel</h2>
                </div>
                
                <div class="dashboard-grid">
                    <a href="/vendors" data-link class="stat-card clickable-card" style="cursor: pointer; text-decoration: none; color: inherit; transition: all 0.2s ease;" title="Click to view Vendors Directory">
                        <div class="stat-info">
                            <span class="stat-label">Total Vendors</span>
                            <span class="stat-value">${stats.total_vendors}</span>
                        </div>
                        <div class="stat-icon" style="background: rgba(254, 117, 11, 0.15); color: var(--accent-primary);"><i class="fa-solid fa-shop"></i></div>
                    </a>
                    <a href="/users" data-link class="stat-card clickable-card" style="cursor: pointer; text-decoration: none; color: inherit; transition: all 0.2s ease;" title="Click to view Active Users Directory">
                        <div class="stat-info">
                            <span class="stat-label">Active Users</span>
                            <span class="stat-value">${stats.total_users}</span>
                        </div>
                        <div class="stat-icon" style="background: rgba(59, 130, 246, 0.15); color: #3b82f6;"><i class="fa-solid fa-users"></i></div>
                    </a>
                    <a href="/drivers" data-link class="stat-card clickable-card" style="cursor: pointer; text-decoration: none; color: inherit; transition: all 0.2s ease;" title="Click to view Delivery Drivers Directory">
                        <div class="stat-info">
                            <span class="stat-label">Delivery Drivers</span>
                            <span class="stat-value">${stats.total_drivers}</span>
                        </div>
                        <div class="stat-icon" style="background: rgba(16, 185, 129, 0.15); color: #10b981;"><i class="fa-solid fa-motorcycle"></i></div>
                    </a>
                    <div class="stat-card">
                        <div class="stat-info">
                            <span class="stat-label">Total Orders</span>
                            <span class="stat-value">${stats.total_orders}</span>
                        </div>
                        <div class="stat-icon"><i class="fa-solid fa-truck-ramp-box"></i></div>
                    </div>
                    <a href="/revenue" data-link class="stat-card clickable-card" style="cursor: pointer; text-decoration: none; color: inherit; transition: all 0.2s ease;" title="Click to view Location Revenue Analytics">
                        <div class="stat-info">
                            <span class="stat-label">Total Revenue</span>
                            <span class="stat-value">₹${stats.total_revenue}</span>
                        </div>
                        <div class="stat-icon" style="background: rgba(16, 185, 129, 0.15); color: #10b981;"><i class="fa-solid fa-wallet"></i></div>
                    </a>
                </div>

                <!-- Location Revenue Breakdown Widget -->
                <div class="dashboard-banner" style="background: var(--bg-card, #ffffff); border: 1px solid var(--border-color, #e2e8f0); border-radius: 20px; padding: 24px; margin-top: 24px; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.05);">
                    <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; flex-wrap: wrap; gap: 12px;">
                        <div>
                            <h3 class="font-extrabold" style="font-size: 18px; color: var(--text-color, #1e293b); display: flex; align-items: center; gap: 8px;">
                                <i class="fa-solid fa-map-location-dot text-primary" style="font-size: 20px;"></i>
                                Revenue by Location / City
                            </h3>
                            <p style="font-size: 12px; color: var(--text-secondary, #64748b); margin-top: 4px;">
                                Real-time order distribution and gross sales for active operating cities (Pune, Ahmednagar & regions).
                            </p>
                        </div>
                        <span class="badge badge-success" style="font-size: 12px; padding: 6px 12px;">
                            <i class="fa-solid fa-chart-pie" style="margin-right: 4px;"></i> Live City Metrics
                        </span>
                    </div>

                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px;">
                        ${(stats.location_revenue || []).map(loc => {
                            const totalRevVal = parseFloat(stats.total_revenue) || 1;
                            const locRevVal = parseFloat(loc.total_revenue) || 0;
                            const sharePct = totalRevVal > 0 ? Math.min(100, Math.round((locRevVal / totalRevVal) * 100)) : 0;
                            
                            let cityIcon = 'fa-city';
                            let cityColor = 'var(--accent-primary, #fe750b)';
                            if (loc.location_name.toLowerCase().includes('pune')) {
                                cityIcon = 'fa-building-columns';
                                cityColor = '#fe750b';
                            } else if (loc.location_name.toLowerCase().includes('ahmednagar')) {
                                cityIcon = 'fa-mountain-city';
                                cityColor = '#3b82f6';
                            } else if (loc.location_name.toLowerCase().includes('pimpri')) {
                                cityIcon = 'fa-building-user';
                                cityColor = '#10b981';
                            }

                            return `
                                <div style="background: var(--bg-surface, #f8fafc); border: 1px solid var(--border-color, #cbd5e1); border-radius: 16px; padding: 18px;" class="hover-lift">
                                    <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
                                        <div style="display: flex; align-items: center; gap: 10px;">
                                            <div style="width: 38px; height: 38px; border-radius: 12px; background: rgba(254, 117, 11, 0.1); color: ${cityColor}; display: flex; align-items: center; justify-content: center; font-size: 16px;">
                                                <i class="fa-solid ${cityIcon}"></i>
                                            </div>
                                            <div>
                                                <h4 style="font-weight: 800; font-size: 16px; color: var(--text-color, #0f172a); margin: 0;">${loc.location_name}</h4>
                                                <span style="font-size: 11px; color: var(--text-secondary, #64748b); font-weight: 600;">${loc.total_orders} Orders</span>
                                            </div>
                                        </div>
                                        <span style="font-weight: 800; font-size: 12px; background: rgba(0,0,0,0.05); padding: 4px 8px; border-radius: 8px;">
                                            ${sharePct}% share
                                        </span>
                                    </div>
                                    <div style="margin-top: 10px;">
                                        <div style="display: flex; justify-content: space-between; font-size: 12px; margin-bottom: 6px;">
                                            <span style="color: var(--text-secondary, #64748b); font-weight: 600;">Gross Revenue:</span>
                                            <span style="font-weight: 900; color: #10b981; font-size: 15px;">₹${loc.total_revenue}</span>
                                        </div>
                                        <div style="width: 100%; height: 6px; background: rgba(0,0,0,0.08); border-radius: 3px; overflow: hidden;">
                                            <div style="width: ${sharePct > 0 ? sharePct : 5}%; height: 100%; background: ${cityColor}; border-radius: 3px; transition: width 0.5s ease;"></div>
                                        </div>
                                    </div>
                                    <div style="display: flex; gap: 6px; margin-top: 14px; padding-top: 10px; border-top: 1px dashed var(--border-color, #cbd5e1); flex-wrap: wrap;">
                                        <a href="/revenue?district=${encodeURIComponent(loc.location_name)}" data-link class="btn btn-secondary btn-sm" style="font-size: 11px; padding: 4px 8px; font-weight: 700; background: rgba(16, 185, 129, 0.15); color: #059669; border: 1px solid rgba(16, 185, 129, 0.3);">
                                            <i class="fa-solid fa-chart-line" style="margin-right: 4px;"></i> Revenue
                                        </a>
                                        <a href="/users?district=${encodeURIComponent(loc.location_name)}" data-link class="btn btn-secondary btn-sm" style="font-size: 11px; padding: 4px 8px; font-weight: 700; background: rgba(59, 130, 246, 0.1); color: #2563eb; border: 1px solid rgba(59, 130, 246, 0.2);">
                                            <i class="fa-solid fa-users" style="margin-right: 4px;"></i> Users
                                        </a>
                                        <a href="/drivers?district=${encodeURIComponent(loc.location_name)}" data-link class="btn btn-secondary btn-sm" style="font-size: 11px; padding: 4px 8px; font-weight: 700; background: rgba(16, 185, 129, 0.1); color: #059669; border: 1px solid rgba(16, 185, 129, 0.2);">
                                            <i class="fa-solid fa-motorcycle" style="margin-right: 4px;"></i> Drivers
                                        </a>
                                        <a href="/vendors?district=${encodeURIComponent(loc.location_name)}" data-link class="btn btn-secondary btn-sm" style="font-size: 11px; padding: 4px 8px; font-weight: 700; background: rgba(254, 117, 11, 0.1); color: #ea580c; border: 1px solid rgba(254, 117, 11, 0.2);">
                                            <i class="fa-solid fa-shop" style="margin-right: 4px;"></i> Vendors
                                        </a>
                                    </div>
                                </div>
                            `;
                        }).join('')}
                    </div>
                </div>

                <div class="dashboard-banner" style="background: linear-gradient(135deg, rgba(31, 41, 55, 0.4), rgba(17, 24, 39, 0.4));">
                    <h3 class="font-semibold" style="margin-bottom: 12px;"><i class="fa-solid fa-gears text-primary"></i> Administrative Quick Actions</h3>
                    <div style="display: flex; gap: 12px; flex-wrap: wrap; margin-top: 12px;">
                        <a href="/admin/vendors/add" class="btn btn-primary" data-link><i class="fa-solid fa-plus"></i> Add Vendor Account</a>
                        <a href="/admin/users/add" class="btn btn-secondary" data-link><i class="fa-solid fa-user-plus"></i> Create Customer Profile</a>
                    </div>
                </div>
            `;
        } catch (error) {
            this.showToast('Error loading stats: ' + error.message, 'error');
        }
    }

    /**
     * Vendors List View
     */
    async loadVendorsView(container) {
        if (this.decodedQuery) {
            if (this.decodedQuery.has('country'))  this.vendorQuery.country  = this.decodedQuery.get('country');
            if (this.decodedQuery.has('state'))    this.vendorQuery.state    = this.decodedQuery.get('state');
            if (this.decodedQuery.has('district')) this.vendorQuery.district = this.decodedQuery.get('district');
            if (this.decodedQuery.has('taluka'))   this.vendorQuery.taluka   = this.decodedQuery.get('taluka');
        }

        if (this.vendorQuery.district && !this.vendorQuery.state) {
            for (const [st, dists] of Object.entries(LOCATION_DATA.districtsByState)) {
                if (dists.includes(this.vendorQuery.district)) {
                    this.vendorQuery.state = st;
                    this.vendorQuery.country = 'India';
                    break;
                }
            }
        }

        container.innerHTML = `
            <div class="view-header">
                <h2>Vendors Directory</h2>
                <div class="view-actions" style="display: flex; gap: 10px; align-items: center;">
                    <button id="trigger-payouts-btn" class="btn btn-success" style="background-color: #10B981; color: white; border: none; padding: 9px 16px; border-radius: 8px; font-weight: 600; cursor: pointer; display: inline-flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-money-bill-transfer"></i> Run Today's Payouts
                    </button>
                    <a href="/admin/vendors/add" class="btn btn-primary" data-link>
                        <i class="fa-solid fa-plus"></i> Add Vendor
                    </a>
                </div>
            </div>

                        <div class="filter-bar" style="display: flex; flex-wrap: wrap; gap: 12px; align-items: center; background: var(--bg-card, #ffffff); padding: 14px 18px; border-radius: var(--radius-md, 12px); border: 1px solid var(--border-color, #e2e8f0); margin-bottom: 16px;">
                <div class="search-input-wrapper" style="flex: 1; min-width: 220px;">
                    <i class="fa-solid fa-magnifying-glass search-icon"></i>
                    <input type="text" id="vendor-search" class="search-input" placeholder="Search by ID, name, email, phone, hotel..." value="${this.vendorQuery.search}">
                </div>

                <!-- Location Filters FIRST: State -> District -> Taluka -> Area -->
                <select id="vendor-state-filter" class="filter-select" style="min-width: 150px; font-weight: 600;">
                    <option value="all">All States</option>
                </select>

                <select id="vendor-district-filter" class="filter-select" style="min-width: 150px; font-weight: 600;">
                    <option value="all">All Districts</option>
                </select>

                <select id="vendor-taluka-filter" class="filter-select" style="min-width: 150px; font-weight: 600;">
                    <option value="all">All Talukas</option>
                </select>

                <select id="vendor-area-filter" class="filter-select" style="min-width: 150px; font-weight: 600;">
                    <option value="all">All Areas</option>
                </select>
                
                <select id="vendor-status-filter" class="filter-select" style="min-width: 130px;">
                    <option value="all" ${this.vendorQuery.status === 'all' ? 'selected' : ''}>All Vendors</option>
                    <option value="online" ${this.vendorQuery.status === 'online' ? 'selected' : ''}>Online Vendors</option>
                    <option value="offline" ${this.vendorQuery.status === 'offline' ? 'selected' : ''}>Offline Vendors</option>
                    <option value="active" ${this.vendorQuery.status === 'active' ? 'selected' : ''}>Active Accounts</option>
                    <option value="inactive" ${this.vendorQuery.status === 'inactive' ? 'selected' : ''}>Deactivated Accounts</option>
                </select>

                <select id="vendor-sort-filter" class="filter-select" style="min-width: 150px; font-weight: 700; color: #1e40af; border-color: #bfdbfe; background: #eff6ff;" title="Sort vendors date-wise">
                    <option value="newest" ${(this.vendorQuery.sort === 'newest' || !this.vendorQuery.sort) ? 'selected' : ''}>Newest Date First</option>
                    <option value="oldest" ${this.vendorQuery.sort === 'oldest' ? 'selected' : ''}>Oldest Date First</option>
                    <option value="online" ${this.vendorQuery.sort === 'online' ? 'selected' : ''}>Online First</option>
                </select>

                <div style="display: flex; align-items: center; gap: 6px; background: var(--bg-surface); border: 1px solid var(--border-color); border-radius: 8px; padding: 2px 8px;" title="Filter vendors by registration date">
                    <i class="fa-regular fa-calendar" style="color: #2563eb; font-size: 12px;"></i>
                    <input type="date" id="vendor-date-filter" class="form-control" value="${this.vendorQuery.date || ''}" style="border: none; padding: 4px; font-size: 12px; font-weight: 600; width: 130px; background: transparent;">
                </div>

                <select id="vendor-country-filter" class="filter-select" style="min-width: 130px; font-weight: 600;">
                    <option value="all" ${(!this.vendorQuery.country || this.vendorQuery.country === 'all') ? 'selected' : ''}>All Countries</option>
                    ${LOCATION_DATA.countries.map(c => `<option value="${c}" ${this.vendorQuery.country === c ? 'selected' : ''}>${c}</option>`).join('')}
                </select>

                <button id="vendor-reset-btn" class="btn btn-secondary" style="padding: 9px 14px; font-size: 13px; font-weight: 600; display: inline-flex; align-items: center; gap: 6px;" title="Reset all filters">
                    <i class="fa-solid fa-rotate-left"></i> Reset
                </button>
            </div>

            <div id="vendor-location-header" style="margin-bottom: 16px; display: flex; align-items: center; justify-content: space-between; background: var(--bg-surface, #f8fafc); border: 1px solid var(--border-color, #e2e8f0); border-radius: 12px; padding: 12px 18px; flex-wrap: wrap; gap: 12px;">
                <div style="display: flex; align-items: center; gap: 10px; font-size: 13px; font-weight: 700; color: var(--text-color, #1e293b);">
                    <i class="fa-solid fa-location-dot text-primary" style="font-size: 16px;"></i>
                    <span id="vendor-location-breadcrumb">Filter Location: India</span>
                </div>
                <span id="vendor-count-badge" class="badge badge-primary" style="font-size: 12px; font-weight: 800; padding: 6px 14px; border-radius: 20px;">
                    Loading Vendors...
                </span>
            </div>

            <div class="table-responsive">
                <table class="table" id="vendors-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Vendor Info</th>
                            <th>District</th>
                            <th>Taluka</th>
                            <th>Area</th>
                            <th>Online Status</th>
                            <th>Email Address</th>
                            <th class="text-center">Hotels / Mess</th>
                            <th class="text-center">Associated Drivers</th>
                            <th class="text-center">Revenue (Today / Week)</th>
                            <th>Account Status</th>
                            <th style="min-width: 140px;"><i class="fa-solid fa-arrow-down-wide-short text-primary" style="margin-right: 4px;"></i> Date Registered (Newest)</th>
                            <th class="text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="vendors-tbody">
                        <tr>
                            <td colspan="13" class="text-center">
                                <div style="padding: 30px;"><div class="spinner" style="margin: 0 auto; width: 30px; height: 30px;"></div></div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div id="vendor-pagination" class="pagination-wrapper"></div>
        `;

        const searchInput    = document.getElementById('vendor-search');
        const statusSelect   = document.getElementById('vendor-status-filter');
        const countrySelect  = document.getElementById('vendor-country-filter');
        const stateSelect    = document.getElementById('vendor-state-filter');
        const districtSelect = document.getElementById('vendor-district-filter');
        const talukaSelect   = document.getElementById('vendor-taluka-filter');

        const updateStateOptions = () => {
            const country = countrySelect.value;
            const states = LOCATION_DATA.statesByCountry[country] || [];
            stateSelect.innerHTML = '<option value="all">All States</option>' + 
                states.map(s => `<option value="${s}" ${this.vendorQuery.state === s ? 'selected' : ''}>${s}</option>`).join('');
        };

        const updateDistrictOptions = () => {
            const state = stateSelect.value;
            const districts = LOCATION_DATA.districtsByState[state] || [];
            districtSelect.innerHTML = '<option value="all">All Districts</option>' + 
                districts.map(d => `<option value="${d}" ${this.vendorQuery.district === d ? 'selected' : ''}>${d}</option>`).join('');
        };

        const regionSelect   = document.getElementById('vendor-region-filter');
        const areaSelect     = document.getElementById('vendor-area-filter');

        const updateTalukaOptions = () => {
            const district = districtSelect.value;
            const talukas = (LOCATION_DATA.talukasByDistrict && LOCATION_DATA.talukasByDistrict[district]) || [];
            talukaSelect.innerHTML = '<option value="all">All Talukas</option>' + 
                talukas.map(t => `<option value="${t}" ${this.vendorQuery.taluka === t ? 'selected' : ''}>${t}</option>`).join('');
        };

        const updateRegionOptions = () => {
            if (!regionSelect) return;
            const district = districtSelect.value;
            const regions = (district !== 'all' && typeof LOCATION_DATA.getRegions === 'function') ? LOCATION_DATA.getRegions(district) : [];
            regionSelect.innerHTML = '<option value="all">All Regions</option>' + 
                regions.map(r => `<option value="${r}" ${this.vendorQuery.region === r ? 'selected' : ''}>${r}</option>`).join('');
        };

        const updateAreaOptions = () => {
            if (!areaSelect) return;
            const district = districtSelect.value;
            const region = regionSelect ? regionSelect.value : 'all';
            let areas = [];
            if (district !== 'all' && typeof LOCATION_DATA.getAreas === 'function') {
                areas = LOCATION_DATA.getAreas(district, region);
            }
            areaSelect.innerHTML = '<option value="all">All Areas</option>' + 
                areas.map(a => `<option value="${a}" ${this.vendorQuery.area === a ? 'selected' : ''}>${a}</option>`).join('');
        };

        // Initial option cascade
        updateStateOptions();
        updateDistrictOptions();
        updateTalukaOptions();
        updateRegionOptions();
        updateAreaOptions();

        // Event listeners
        searchInput.addEventListener('input', (e) => {
            clearTimeout(this.debouncedSearchTimeout);
            this.debouncedSearchTimeout = setTimeout(() => {
                this.vendorQuery.search = e.target.value;
                this.vendorQuery.page = 1;
                this.fetchVendorsList();
            }, 400);
        });

        searchInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                clearTimeout(this.debouncedSearchTimeout);
                this.vendorQuery.search = e.target.value.trim();
                this.vendorQuery.page = 1;
                this.fetchVendorsList();
            }
        });

        statusSelect.addEventListener('change', (e) => {
            this.vendorQuery.status = e.target.value;
            this.vendorQuery.page = 1;
            this.fetchVendorsList();
        });

        const vendorSortSelect = document.getElementById('vendor-sort-filter');
        if (vendorSortSelect) {
            vendorSortSelect.addEventListener('change', (e) => {
                this.vendorQuery.sort = e.target.value;
                this.vendorQuery.page = 1;
                this.fetchVendorsList();
            });
        }

        const vendorDateInput = document.getElementById('vendor-date-filter');
        if (vendorDateInput) {
            vendorDateInput.addEventListener('change', (e) => {
                this.vendorQuery.date = e.target.value;
                this.vendorQuery.page = 1;
                this.fetchVendorsList();
            });
        }

        countrySelect.addEventListener('change', (e) => {
            this.vendorQuery.country = e.target.value === 'all' ? '' : e.target.value;
            this.vendorQuery.state = '';
            this.vendorQuery.district = '';
            this.vendorQuery.taluka = '';
            this.vendorQuery.page = 1;
            updateStateOptions();
            updateDistrictOptions();
            updateTalukaOptions();
            this.fetchVendorsList();
        });

        stateSelect.addEventListener('change', (e) => {
            this.vendorQuery.state = e.target.value === 'all' ? '' : e.target.value;
            this.vendorQuery.district = '';
            this.vendorQuery.taluka = '';
            this.vendorQuery.region = '';
            this.vendorQuery.area = '';
            this.vendorQuery.page = 1;
            updateDistrictOptions();
            updateTalukaOptions();
            updateRegionOptions();
            updateAreaOptions();
            this.fetchVendorsList();
        });

        districtSelect.addEventListener('change', (e) => {
            this.vendorQuery.district = e.target.value === 'all' ? '' : e.target.value;
            this.vendorQuery.taluka = '';
            this.vendorQuery.region = '';
            this.vendorQuery.area = '';
            this.vendorQuery.page = 1;
            updateTalukaOptions();
            updateRegionOptions();
            updateAreaOptions();
            this.fetchVendorsList();
        });

        talukaSelect.addEventListener('change', (e) => {
            this.vendorQuery.taluka = e.target.value === 'all' ? '' : e.target.value;
            this.vendorQuery.page = 1;
            this.fetchVendorsList();
        });

        if (regionSelect) {
            regionSelect.addEventListener('change', (e) => {
                this.vendorQuery.region = e.target.value === 'all' ? '' : e.target.value;
                this.vendorQuery.area = '';
                this.vendorQuery.page = 1;
                updateAreaOptions();
                this.fetchVendorsList();
            });
        }

        if (areaSelect) {
            areaSelect.addEventListener('change', (e) => {
                this.vendorQuery.area = e.target.value === 'all' ? '' : e.target.value;
                this.vendorQuery.page = 1;
                this.fetchVendorsList();
            });
        }

        const resetBtn = document.getElementById('vendor-reset-btn');
        if (resetBtn) {
            resetBtn.addEventListener('click', () => {
                this.vendorQuery = { search: '', status: 'all', sort: 'newest', date: '', country: 'India', state: '', district: '', taluka: '', region: '', area: '', page: 1, limit: 10 };
                const vSort = document.getElementById('vendor-sort-filter'); if (vSort) vSort.value = 'newest';
                const vDate = document.getElementById('vendor-date-filter'); if (vDate) vDate.value = '';
                searchInput.value = '';
                statusSelect.value = 'all';
                countrySelect.value = 'India';
                updateStateOptions();
                updateDistrictOptions();
                updateTalukaOptions();
                updateRegionOptions();
                updateAreaOptions();
                this.fetchVendorsList();
            });
        }

        const triggerBtn = document.getElementById('trigger-payouts-btn');
        if (triggerBtn) {
            triggerBtn.addEventListener('click', async () => {
                if (!confirm("Are you sure you want to trigger today's vendor payouts settlement via PayU?")) return;
                try {
                    this.showGlobalLoader(true);
                    const res = await API.triggerVendorPayouts();
                    this.showGlobalLoader(false);
                    if (res.success) {
                        this.showToast(res.message || "Vendor payouts processed successfully!", 'success');
                        await this.fetchVendorsList();
                    } else {
                        this.showToast(res.message || "Failed to process payouts", 'error');
                    }
                } catch (err) {
                    this.showGlobalLoader(false);
                    this.showToast("Error processing payouts: " + err.message, 'error');
                }
            });
        }

        // Trigger fetch
        await this.fetchVendorsList();
    }

    async fetchVendorsList() {
        const tbody = document.getElementById('vendors-tbody');
        if (!tbody) return;

        tbody.innerHTML = `
            <tr>
                <td colspan="10" class="text-center">
                    <div style="padding: 20px;"><div class="spinner" style="margin: 0 auto; width: 28px; height: 28px;"></div></div>
                </td>
            </tr>
        `;

        try {
            const result = await api.getVendors(this.vendorQuery);
            const vendors = result.data.vendors;
            this.vendors = vendors; // Cache vendors in state
            const pagination = result.data.pagination;

            // Update Location Breadcrumb & Count Badge
            const locBreadcrumb = document.getElementById('vendor-location-breadcrumb');
            const countBadge = document.getElementById('vendor-count-badge');

            if (locBreadcrumb) {
                const parts = [];
                if (this.vendorQuery.state) parts.push(this.vendorQuery.state);
                if (this.vendorQuery.district) parts.push(this.vendorQuery.district);
                if (this.vendorQuery.taluka) parts.push(this.vendorQuery.taluka);
                if (this.vendorQuery.region) parts.push(this.vendorQuery.region);
                if (this.vendorQuery.area) parts.push(this.vendorQuery.area);
                if (parts.length === 0) {
                    locBreadcrumb.innerHTML = 'Location Filter: <span style="color: var(--accent-primary, #fe750b);">' + (this.vendorQuery.country || 'All Locations') + '</span>';
                } else {
                    locBreadcrumb.innerHTML = 'Location Filter: <span style="color: var(--accent-primary, #fe750b);">' + parts.join(' &gt; ') + '</span>';
                }
            }

            if (countBadge) {
                const total = pagination ? pagination.total_records : vendors.length;
                countBadge.textContent = total + ' Vendor' + (total === 1 ? '' : 's') + ' Found';
            }

            if (vendors.length === 0) {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="13" class="text-center" style="padding: 40px; color: var(--text-secondary);">
                            <i class="fa-solid fa-inbox" style="font-size: 32px; margin-bottom: 12px; display: block;"></i>
                            No vendors found. Try adjusting your search query or filters.
                        </td>
                    </tr>
                `;
                document.getElementById('vendor-pagination').innerHTML = '';
                return;
            }

                        tbody.innerHTML = vendors.map(vendor => {
                const isOnline = vendor.is_online == 1;
                const onlineBadge = isOnline 
                    ? '<span class="badge" style="background:#dcfce7; color:#15803d; border:1px solid #86efac; font-size:11px; padding:3px 8px; font-weight:700;"><i class="fa-solid fa-circle" style="font-size:7px; color:#16a34a; margin-right:4px;"></i>Online</span>'
                    : '<span class="badge" style="background:#f1f5f9; color:#64748b; border:1px solid #cbd5e1; font-size:11px; padding:3px 8px; font-weight:600;"><i class="fa-regular fa-circle" style="font-size:7px; margin-right:4px;"></i>Offline</span>';

                const statusBadge = vendor.is_active 
                    ? '<span class="badge badge-success">Active</span>' 
                    : '<span class="badge badge-danger">Deactivated</span>';
                
                const toggleIcon = vendor.is_active ? 'fa-user-slash' : 'fa-user-check';
                const toggleTitle = vendor.is_active ? 'Deactivate Account' : 'Activate Account';
                const createdDate = new Date(vendor.created_at);
                const dateStr = !isNaN(createdDate.getTime()) ? createdDate.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' }) : 'N/A';
                const timeStr = !isNaN(createdDate.getTime()) ? createdDate.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true }) : '';
                const isToday = !isNaN(createdDate.getTime()) && (new Date().toDateString() === createdDate.toDateString());
                const isRecent = !isNaN(createdDate.getTime()) && (Date.now() - createdDate.getTime() < 48 * 3600 * 1000);

                const driverCount = vendor.driver_count || 0;
                const driverPill = `
                    <button class="btn btn-sm" style="background: #eef2ff; color: #4338ca; border: 1px solid #c7d2fe; border-radius: 20px; font-weight: 700; font-size: 11px; padding: 3px 10px; cursor: pointer; display: inline-flex; align-items: center; gap: 5px;" onclick="app.viewVendorDetails(${vendor.id}, 'drivers')" title="Click to view all ${driverCount} drivers associated with this vendor">
                        <i class="fa-solid fa-motorcycle"></i> ${driverCount} Driver${driverCount === 1 ? '' : 's'}
                    </button>
                `;

                const vendorDistrict = vendor.district || '';
                const vendorTaluka = vendor.taluka || '';
                let vendorArea = vendor.area || '';
                if (!vendorArea && typeof LOCATION_DATA !== 'undefined' && typeof LOCATION_DATA.resolveLocation === 'function') {
                    const hotelAddr = (vendor.hotels && vendor.hotels[0] && vendor.hotels[0].hotel_address) || '';
                    const hotelName = (vendor.hotels && vendor.hotels[0] && vendor.hotels[0].hotel_name) || '';
                    const resolvedLoc = LOCATION_DATA.resolveLocation(hotelAddr + ' ' + vendorTaluka + ' ' + hotelName, vendorDistrict, vendorTaluka);
                    if (resolvedLoc && resolvedLoc.area) {
                        vendorArea = resolvedLoc.area;
                    }
                }

                return `
                    <tr style="${isOnline ? 'background: rgba(16, 185, 129, 0.02);' : ''}">
                        <td><strong>#${vendor.id}</strong></td>
                        <td>
                            <div style="display: flex; flex-direction: column; gap: 2px;">
                                <span class="font-semibold">${this.escapeHtml(vendor.full_name)}</span>
                                <span style="font-size: 11px; color: var(--text-muted);"><i class="fa-solid fa-phone"></i> ${this.escapeHtml(vendor.phone || 'N/A')}</span>
                            </div>
                        </td>
                        <td>
                            ${vendorDistrict ? `
                                <span class="badge" style="background: rgba(59, 130, 246, 0.1); color: #1d4ed8; border: 1px solid rgba(59, 130, 246, 0.25); font-weight: 700; font-size: 11px; padding: 3px 8px; border-radius: 6px;">
                                    <i class="fa-solid fa-location-dot" style="font-size: 9px; margin-right: 4px;"></i>${this.escapeHtml(vendorDistrict)}
                                </span>
                            ` : '<span style="color: var(--text-muted); font-size: 11px;">—</span>'}
                        </td>
                        <td>
                            ${vendorTaluka ? `
                                <span class="badge" style="background: rgba(16, 185, 129, 0.1); color: #047857; border: 1px solid rgba(16, 185, 129, 0.25); font-weight: 700; font-size: 11px; padding: 3px 8px; border-radius: 6px;">
                                    <i class="fa-solid fa-city" style="font-size: 9px; margin-right: 4px;"></i>${this.escapeHtml(vendorTaluka)}
                                </span>
                            ` : '<span style="color: var(--text-muted); font-size: 11px;">—</span>'}
                        </td>
                        <td>
                            ${vendorArea ? `
                                <span class="badge" style="background: rgba(254, 117, 11, 0.1); color: #c2410c; border: 1px solid rgba(254, 117, 11, 0.3); font-weight: 700; font-size: 11px; padding: 3px 8px; border-radius: 6px;">
                                    <i class="fa-solid fa-map-pin" style="font-size: 9px; margin-right: 4px;"></i>${this.escapeHtml(vendorArea)}
                                </span>
                                ${vendor.region ? `<div style="font-size: 10px; color: var(--text-muted); margin-top: 2px;">${this.escapeHtml(vendor.region)}</div>` : ''}
                            ` : (vendor.region ? `<span class="badge" style="background: rgba(100, 116, 139, 0.1); color: #475569; border: 1px solid rgba(100, 116, 139, 0.25); font-weight: 600; font-size: 11px; padding: 3px 8px; border-radius: 6px;">${this.escapeHtml(vendor.region)}</span>` : '<span style="color: var(--text-muted); font-size: 11px;">—</span>')}
                        </td>
                        <td>${onlineBadge}</td>
                        <td>${this.escapeHtml(vendor.email)}</td>
                        <td class="text-center"><span class="badge" style="background-color: var(--bg-surface); font-weight: 600;">${vendor.hotel_count} hotels</span></td>
                        <td class="text-center">${driverPill}</td>
                        <td class="text-center">
                            <div style="display: flex; flex-direction: column; gap: 2px;">
                                <span style="font-size: 12px; font-weight: 700; color: var(--accent-success);">₹${vendor.daily_revenue || '0.00'} <small style="font-weight: 400; color: var(--text-muted);">today</small></span>
                                <span style="font-size: 11px; color: var(--text-secondary);">₹${vendor.weekly_revenue || '0.00'} week</span>
                            </div>
                        </td>
                        <td>${statusBadge}</td>
                        <td>
                            <div style="display: flex; flex-direction: column; gap: 2px;">
                                <span style="display: inline-flex; align-items: center; gap: 5px; font-weight: 700; font-size: 12px; color: var(--text-primary);">
                                    <i class="fa-regular fa-calendar-check text-primary" style="font-size: 11px;"></i> ${dateStr}
                                    ${isToday ? '<span class="badge" style="background:#dcfce7; color:#15803d; border:1px solid #86efac; font-size:9px; font-weight:800; padding:1px 5px; border-radius:10px;">TODAY</span>' : (isRecent ? '<span class="badge" style="background:#eff6ff; color:#1d4ed8; border:1px solid #bfdbfe; font-size:9px; font-weight:800; padding:1px 5px; border-radius:10px;">NEW</span>' : '')}
                                </span>
                                ${timeStr ? `<span style="font-size: 11px; color: var(--text-muted); padding-left: 16px;"><i class="fa-regular fa-clock" style="font-size: 10px;"></i> ${timeStr}</span>` : ''}
                            </div>
                        </td>
                        <td class="text-right">
                            <div class="table-actions" style="justify-content: flex-end;">
                                <button class="btn btn-secondary btn-icon" title="View Associated Drivers (${driverCount})" onclick="app.viewVendorDetails(${vendor.id}, 'drivers')">
                                    <i class="fa-solid fa-eye"></i>
                                </button>
                                <button class="btn btn-secondary btn-icon" title="View Associated Drivers (${driverCount})" style="color: #4f46e5;" onclick="app.viewVendorDetails(${vendor.id}, 'drivers')">
                                    <i class="fa-solid fa-motorcycle"></i>
                                </button>
                                <button class="btn btn-secondary btn-icon" title="Edit Vendor" onclick="app.editVendorRoute(${vendor.id})">
                                    <i class="fa-solid fa-pencil"></i>
                                </button>
                                <button class="btn btn-secondary btn-icon" title="${toggleTitle}" onclick="app.toggleVendorActiveState(${vendor.id}, ${vendor.is_active})">
                                    <i class="fa-solid ${toggleIcon}"></i>
                                </button>
                                <button class="btn btn-danger btn-icon" title="Delete Account" onclick="app.openDeleteModal(${vendor.id}, 'vendor')">
                                    <i class="fa-solid fa-trash-can"></i>
                                </button>
                            </div>
                        </td>
                    </tr>
                `;
            }).join('');

            this.renderPagination('vendor-pagination', pagination, (newPage) => {
                this.vendorQuery.page = newPage;
                this.fetchVendorsList();
            });

        } catch (error) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="13" class="text-center text-danger" style="padding: 24px;">
                        Failed to load vendors: ${error.message}
                    </td>
                </tr>
            `;
        }
    }

    /**
     * Add Vendor Form View
     */
    loadAddVendorView(container) {
        container.innerHTML = `
            <div class="view-header">
                <h2>Create Vendor Account</h2>
                <a href="/admin/vendors" class="btn btn-secondary" data-link>
                    <i class="fa-solid fa-arrow-left"></i> Back to List
                </a>
            </div>

            <div class="profile-card" style="margin: 0 auto; max-width: 500px;">
                <form id="add-vendor-form" onsubmit="app.handleAddVendor(event)">
                    <div class="form-group">
                        <label class="form-label" for="vendor-name">Full Name</label>
                        <input type="text" id="vendor-name" class="form-control" placeholder="Vendor Business Name" required>
                        <div class="form-error hidden" id="error-name"></div>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="vendor-email">Email Address</label>
                        <input type="email" id="vendor-email" class="form-control" placeholder="vendor@business.com" required>
                        <div class="form-error hidden" id="error-email"></div>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="vendor-password">Password</label>
                        <input type="password" id="vendor-password" class="form-control" placeholder="Password (min 8 chars, letter & number)" required>
                        <div class="form-error hidden" id="error-password"></div>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="vendor-confirm-password">Confirm Password</label>
                        <input type="password" id="vendor-confirm-password" class="form-control" placeholder="••••••••" required>
                        <div class="form-error hidden" id="error-confirm-password"></div>
                    </div>
                    
                    <div style="display: flex; gap: 12px; margin-top: 24px;">
                        <button type="submit" class="btn btn-primary" style="flex: 1;">
                            <i class="fa-solid fa-plus"></i> Add Vendor
                        </button>
                        <a href="/admin/vendors" class="btn btn-secondary" style="flex: 1; text-align: center;" data-link>Cancel</a>
                    </div>
                </form>
            </div>
        `;
    }

    /**
     * Edit Vendor view
     */
    async loadEditVendorView(container) {
        const id = parseInt(this.decodedQuery.get('id'));
        if (!id) {
            this.navigateTo('/admin/vendors');
            return;
        }

        container.innerHTML = `
            <div class="view-header">
                <h2>Modify Vendor Profile</h2>
                <a href="/admin/vendors" class="btn btn-secondary" data-link>
                    <i class="fa-solid fa-arrow-left"></i> Back to List
                </a>
            </div>
            <div style="display: flex; justify-content: center; padding: 40px;">
                <div class="spinner" style="width: 32px; height: 32px;"></div>
            </div>
        `;

        let vendor = null;
        let hotels = [];
        try {
            const result = await api.getVendorDetails(id);
            if (result && result.data && result.data.vendor) {
                vendor = result.data.vendor;
                hotels = result.data.hotels || [];
            }
        } catch (e) {
            console.error('Failed to load vendor details:', e);
        }

        if (!vendor) {
            vendor = (this.vendors || []).find(v => v.id === id);
        }

        if (!vendor) {
            this.showToast('Vendor profile not found.', 'error');
            this.navigateTo('/admin/vendors');
            return;
        }

        const primaryHotel = hotels.length > 0 ? hotels[0] : null;

        container.innerHTML = `
            <div class="view-header">
                <div>
                    <h2>Modify Vendor Profile: ${this.escapeHtml(vendor.full_name || '')}</h2>
                    <span style="font-size: 13px; color: var(--text-secondary);">Vendor ID: #${vendor.id}</span>
                </div>
                <a href="/admin/vendors" class="btn btn-secondary" data-link>
                    <i class="fa-solid fa-arrow-left"></i> Back to List
                </a>
            </div>

            <div class="profile-card" style="margin: 0 auto; max-width: 840px; padding: 28px;">
                <form id="edit-vendor-form" onsubmit="app.handleEditVendor(event, ${vendor.id})">
                    <!-- Basic Information -->
                    <h3 style="font-size: 16px; font-weight: 700; color: var(--text-primary); margin-bottom: 16px; display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-user-tie" style="color: var(--accent-primary);"></i> Basic Account Information
                    </h3>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px;">
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-name">Full Name / Owner Name *</label>
                            <input type="text" id="vendor-edit-name" class="form-control" value="${this.escapeHtml(vendor.full_name || '')}" required>
                            <div class="form-error hidden" id="error-name"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-email">Email Address *</label>
                            <input type="email" id="vendor-edit-email" class="form-control" value="${this.escapeHtml(vendor.email || '')}" required>
                            <div class="form-error hidden" id="error-email"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-phone">Phone / Mobile Number</label>
                            <input type="text" id="vendor-edit-phone" class="form-control" value="${this.escapeHtml(vendor.phone || '')}" placeholder="+91 9876543210">
                            <div class="form-error hidden" id="error-phone"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-password">Password / Reset Password</label>
                            <input type="text" id="vendor-edit-password" class="form-control" placeholder="Leave blank to keep current password">
                            <div class="form-error hidden" id="error-password"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-status">Account Status</label>
                            <select id="vendor-edit-status" class="form-control">
                                <option value="1" ${vendor.is_active ? 'selected' : ''}>Active (Enabled)</option>
                                <option value="0" ${!vendor.is_active ? 'selected' : ''}>Inactive (Disabled)</option>
                            </select>
                        </div>
                    </div>

                    <!-- Location Hierarchy -->
                    <h3 style="font-size: 16px; font-weight: 700; color: var(--text-primary); margin-top: 24px; margin-bottom: 16px; border-top: 1px solid var(--border-color); padding-top: 20px; display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-location-dot" style="color: var(--accent-primary);"></i> Location & Territory
                    </h3>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px;">
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-country">Country</label>
                            <select id="vendor-edit-country" class="form-control"></select>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-state">State</label>
                            <select id="vendor-edit-state" class="form-control"></select>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-district">District</label>
                            <select id="vendor-edit-district" class="form-control"></select>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-taluka">Taluka</label>
                            <select id="vendor-edit-taluka" class="form-control"></select>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-region">Region</label>
                            <select id="vendor-edit-region" class="form-control"></select>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-area">Area / Locality</label>
                            <select id="vendor-edit-area" class="form-control"></select>
                        </div>
                    </div>

                    <!-- Bank Account Details -->
                    <h3 style="font-size: 16px; font-weight: 700; color: var(--text-primary); margin-top: 24px; margin-bottom: 16px; border-top: 1px solid var(--border-color); padding-top: 20px; display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-building-columns" style="color: var(--accent-primary);"></i> Bank Settlement Details
                    </h3>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px;">
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-bank-name">Bank Name</label>
                            <input type="text" id="vendor-edit-bank-name" class="form-control" value="${this.escapeHtml(vendor.bank_name || '')}" placeholder="e.g. State Bank of India">
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-account-holder">Account Holder Name</label>
                            <input type="text" id="vendor-edit-account-holder" class="form-control" value="${this.escapeHtml(vendor.account_holder_name || '')}" placeholder="Name as per bank passbook">
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-account-number">Bank Account Number</label>
                            <input type="text" id="vendor-edit-account-number" class="form-control" value="${this.escapeHtml(vendor.account_number || '')}" placeholder="Account Number">
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-ifsc">IFSC Code</label>
                            <input type="text" id="vendor-edit-ifsc" class="form-control" value="${this.escapeHtml(vendor.ifsc_code || '')}" placeholder="e.g. SBIN0001234">
                        </div>
                    </div>

                    <!-- Primary Hotel / Mess Details -->
                    <h3 style="font-size: 16px; font-weight: 700; color: var(--text-primary); margin-top: 24px; margin-bottom: 16px; border-top: 1px solid var(--border-color); padding-top: 20px; display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-utensils" style="color: var(--accent-primary);"></i> Restaurant / Mess Information
                    </h3>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px;">
                        <div class="form-group" style="grid-column: 1 / -1;">
                            <label class="form-label" for="vendor-edit-hotel-name">Restaurant / Hotel Name</label>
                            <input type="text" id="vendor-edit-hotel-name" class="form-control" value="${this.escapeHtml(primaryHotel ? primaryHotel.hotel_name : '')}" placeholder="Restaurant or Mess Name">
                        </div>
                        <div class="form-group" style="grid-column: 1 / -1;">
                            <label class="form-label" for="vendor-edit-hotel-address">Physical Address</label>
                            <textarea id="vendor-edit-hotel-address" class="form-control" rows="2" placeholder="Full restaurant address">${this.escapeHtml(primaryHotel ? primaryHotel.hotel_address : '')}</textarea>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-fssai">FSSAI License Number</label>
                            <input type="text" id="vendor-edit-fssai" class="form-control" value="${this.escapeHtml(primaryHotel ? primaryHotel.fssai_number : '')}" placeholder="14-digit FSSAI Number">
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-gst">GST Number</label>
                            <input type="text" id="vendor-edit-gst" class="form-control" value="${this.escapeHtml(primaryHotel ? primaryHotel.gst_number : '')}" placeholder="GSTIN">
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-pan">PAN Number</label>
                            <input type="text" id="vendor-edit-pan" class="form-control" value="${this.escapeHtml(primaryHotel ? primaryHotel.pan_number : '')}" placeholder="PAN">
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="vendor-edit-aadhar">Aadhar Number</label>
                            <input type="text" id="vendor-edit-aadhar" class="form-control" value="${this.escapeHtml(primaryHotel ? primaryHotel.aadhar_number : '')}" placeholder="Aadhar Number">
                        </div>
                    </div>
                    
                    <div style="display: flex; gap: 12px; margin-top: 28px; border-top: 1px solid var(--border-color); padding-top: 20px;">
                        <button type="submit" class="btn btn-primary" style="flex: 1;">
                            <i class="fa-solid fa-check"></i> Save Vendor Changes
                        </button>
                        <a href="/admin/vendors" class="btn btn-secondary" style="flex: 1; text-align: center;" data-link>Cancel</a>
                    </div>
                </form>
            </div>
        `;

        this.initLocationDropdowns(
            document.getElementById('vendor-edit-country'),
            document.getElementById('vendor-edit-state'),
            document.getElementById('vendor-edit-district'),
            document.getElementById('vendor-edit-taluka'),
            {
                country: vendor.country || 'India',
                state: vendor.state || '',
                district: vendor.district || (primaryHotel ? primaryHotel.city : ''),
                taluka: vendor.taluka || (primaryHotel ? primaryHotel.taluka : ''),
                region: vendor.region || (primaryHotel ? primaryHotel.region : ''),
                area: vendor.area || (primaryHotel ? primaryHotel.area : '')
            },
            document.getElementById('vendor-edit-region'),
            document.getElementById('vendor-edit-area')
        );
    }

    /**
     * Customers List View
     */
    async loadUsersView(container) {
        if (this.decodedQuery) {
            if (this.decodedQuery.has('country'))  this.userQuery.country  = this.decodedQuery.get('country');
            if (this.decodedQuery.has('state'))    this.userQuery.state    = this.decodedQuery.get('state');
            if (this.decodedQuery.has('district')) this.userQuery.district = this.decodedQuery.get('district');
            if (this.decodedQuery.has('taluka'))   this.userQuery.taluka   = this.decodedQuery.get('taluka');
        }

        if (this.userQuery.district && !this.userQuery.state) {
            for (const [st, dists] of Object.entries(LOCATION_DATA.districtsByState)) {
                if (dists.includes(this.userQuery.district)) {
                    this.userQuery.state = st;
                    this.userQuery.country = 'India';
                    break;
                }
            }
        }

        container.innerHTML = `
            <div class="view-header">
                <h2>Customers Registry</h2>
                <div class="view-actions" style="display: flex; gap: 8px;">
                    <button class="btn btn-success" onclick="app.openAssignPlanModal()" style="background: #16a34a; border-color: #16a34a; color: white;">
                        <i class="fa-solid fa-calendar-plus"></i> Assign Plan Manually
                    </button>
                    <a href="/admin/users/add" class="btn btn-primary" data-link>
                        <i class="fa-solid fa-user-plus"></i> Create Customer
                    </a>
                </div>
            </div>

            <div class="filter-bar" style="display: flex; flex-wrap: wrap; gap: 12px; align-items: center; background: var(--bg-card, #ffffff); padding: 14px 18px; border-radius: var(--radius-md, 12px); border: 1px solid var(--border-color, #e2e8f0); margin-bottom: 16px;">
                <div class="search-input-wrapper" style="flex: 1; min-width: 220px;">
                    <i class="fa-solid fa-magnifying-glass search-icon"></i>
                    <input type="text" id="user-search" class="search-input" placeholder="Search by ID, name, email, phone, or address..." value="${this.userQuery.search}">
                </div>
                
                <select id="user-status-filter" class="filter-select" style="min-width: 140px; font-weight: 600;">
                    <option value="all" ${this.userQuery.status === 'all' ? 'selected' : ''}>All Customers</option>
                    <option value="online" ${this.userQuery.status === 'online' ? 'selected' : ''} style="color: #16a34a; font-weight: 700;">Online Now</option>
                    <option value="offline" ${this.userQuery.status === 'offline' ? 'selected' : ''}>Offline</option>
                    <option value="active" ${this.userQuery.status === 'active' ? 'selected' : ''}>Active Account</option>
                    <option value="inactive" ${this.userQuery.status === 'inactive' ? 'selected' : ''}>Deactivated</option>
                </select>

                <select id="user-sort-filter" class="filter-select" style="min-width: 160px; font-weight: 700; color: #1e40af; border-color: #bfdbfe; background: #eff6ff;" title="Sort customers date-wise">
                    <option value="newest" ${(this.userQuery.sort === 'newest' || !this.userQuery.sort) ? 'selected' : ''}>Newest Date First</option>
                    <option value="oldest" ${this.userQuery.sort === 'oldest' ? 'selected' : ''}>Oldest Date First</option>
                    <option value="online" ${this.userQuery.sort === 'online' ? 'selected' : ''}>Online First</option>
                </select>

                <div style="display: flex; align-items: center; gap: 6px; background: var(--bg-surface); border: 1px solid var(--border-color); border-radius: 8px; padding: 2px 8px;" title="Filter customers by join date">
                    <i class="fa-regular fa-calendar" style="color: #2563eb; font-size: 12px;"></i>
                    <input type="date" id="user-date-filter" class="form-control" value="${this.userQuery.date || ''}" style="border: none; padding: 4px; font-size: 12px; font-weight: 600; width: 130px; background: transparent;">
                </div>

                <select id="user-country-filter" class="filter-select" style="min-width: 140px; font-weight: 600;">
                    <option value="all">All Countries</option>
                    ${LOCATION_DATA.countries.map(c => `<option value="${c}" ${(this.userQuery.country || 'India') === c ? 'selected' : ''}>${c}</option>`).join('')}
                </select>

                <select id="user-state-filter" class="filter-select" style="min-width: 150px;">
                    <option value="all">All States</option>
                </select>

                <select id="user-district-filter" class="filter-select" style="min-width: 150px;">
                    <option value="all">All Districts</option>
                </select>

                <select id="user-taluka-filter" class="filter-select" style="min-width: 150px;">
                    <option value="all">All Talukas</option>
                </select>

                <select id="user-region-filter" class="filter-select" style="min-width: 150px;">
                    <option value="all">All Regions</option>
                </select>

                <select id="user-area-filter" class="filter-select" style="min-width: 160px; font-weight: 600;">
                    <option value="all">All Areas / Localities</option>
                </select>

                <button id="user-reset-filters-btn" class="btn btn-secondary" style="font-size: 13px; font-weight: 600; padding: 8px 14px; border-radius: var(--radius-md, 8px); display: inline-flex; align-items: center; gap: 6px;" title="Reset all search & location filters">
                    <i class="fa-solid fa-rotate-left"></i> Reset
                </button>
            </div>

            <div id="user-location-header" style="margin-bottom: 16px; display: flex; align-items: center; justify-content: space-between; background: var(--bg-surface, #f8fafc); border: 1px solid var(--border-color, #e2e8f0); border-radius: 12px; padding: 12px 18px; flex-wrap: wrap; gap: 12px;">
                <div style="display: flex; align-items: center; gap: 10px; font-size: 13px; font-weight: 700; color: var(--text-color, #1e293b);">
                    <i class="fa-solid fa-location-dot text-primary" style="font-size: 16px;"></i>
                    <span id="user-location-breadcrumb">Filter Location: India</span>
                </div>
                <div style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
                    <span id="user-online-badge" class="badge" style="background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; font-size: 12px; font-weight: 800; padding: 6px 14px; border-radius: 20px; display: inline-flex; align-items: center; gap: 6px;">
                        <span style="width: 8px; height: 8px; background: #10b981; border-radius: 50%;"></span>
                        0 Online Now
                    </span>
                    <span id="user-count-badge" class="badge badge-primary" style="font-size: 12px; font-weight: 800; padding: 6px 14px; border-radius: 20px;">
                        Loading Users...
                    </span>
                </div>
            </div>

            <div class="table-responsive">
                <table class="table" id="users-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Profile & Location</th>
                            <th>Email Address</th>
                            <th>Password</th>
                            <th class="text-right">Wallet Balance</th>
                            <th class="text-center">Orders Placed</th>
                            <th class="text-center">Live Status</th>
                            <th>Account Status</th>
                            <th style="min-width: 140px;"><i class="fa-solid fa-arrow-down-wide-short text-primary" style="margin-right: 4px;"></i> Join Date (Newest)</th>
                            <th class="text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="users-tbody">
                        <tr>
                            <td colspan="10" class="text-center">
                                <div style="padding: 30px;"><div class="spinner" style="margin: 0 auto; width: 30px; height: 30px;"></div></div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div id="user-pagination" class="pagination-wrapper"></div>
        `;

        const searchInput    = document.getElementById('user-search');
        const statusSelect   = document.getElementById('user-status-filter');
        const countrySelect  = document.getElementById('user-country-filter');
        const stateSelect    = document.getElementById('user-state-filter');
        const districtSelect = document.getElementById('user-district-filter');
        const talukaSelect   = document.getElementById('user-taluka-filter');
        const resetBtn       = document.getElementById('user-reset-filters-btn');

        const updateStateOptions = () => {
            const country = countrySelect.value;
            const states = LOCATION_DATA.statesByCountry[country] || [];
            stateSelect.innerHTML = '<option value="all">All States</option>' + 
                states.map(s => `<option value="${s}" ${this.userQuery.state === s ? 'selected' : ''}>${s}</option>`).join('');
        };

        const updateDistrictOptions = () => {
            const state = stateSelect.value;
            const districts = LOCATION_DATA.districtsByState[state] || [];
            districtSelect.innerHTML = '<option value="all">All Districts</option>' + 
                districts.map(d => `<option value="${d}" ${this.userQuery.district === d ? 'selected' : ''}>${d}</option>`).join('');
        };

        const regionSelect   = document.getElementById('user-region-filter');
        const areaSelect     = document.getElementById('user-area-filter');

        const updateTalukaOptions = () => {
            const district = districtSelect.value;
            const talukas = (LOCATION_DATA.talukasByDistrict && LOCATION_DATA.talukasByDistrict[district]) || [];
            talukaSelect.innerHTML = '<option value="all">All Talukas</option>' + 
                talukas.map(t => `<option value="${t}" ${this.userQuery.taluka === t ? 'selected' : ''}>${t}</option>`).join('');
        };

        const updateRegionOptions = () => {
            if (!regionSelect) return;
            const district = districtSelect.value;
            const regions = (district !== 'all' && typeof LOCATION_DATA.getRegions === 'function') ? LOCATION_DATA.getRegions(district) : [];
            regionSelect.innerHTML = '<option value="all">All Regions</option>' + 
                regions.map(r => `<option value="${r}" ${this.userQuery.region === r ? 'selected' : ''}>${r}</option>`).join('');
        };

        const updateAreaOptions = () => {
            if (!areaSelect) return;
            const district = districtSelect.value;
            const taluka = talukaSelect ? talukaSelect.value : 'all';
            const region = regionSelect ? regionSelect.value : 'all';
            let areas = [];
            if (district && district !== 'all') {
                if (typeof LOCATION_DATA.getAreas === 'function' && region && region !== 'all') {
                    areas = LOCATION_DATA.getAreas(district, region);
                } else if (taluka && taluka !== 'all' && LOCATION_DATA.areaToRegion) {
                    const talukaAreas = Object.values(LOCATION_DATA.areaToRegion)
                        .filter(item => item.district === district && item.taluka && item.taluka.toLowerCase() === taluka.toLowerCase())
                        .map(item => item.area);
                    if (talukaAreas.length > 0) {
                        areas = [...new Set(talukaAreas)].sort();
                    } else if (typeof LOCATION_DATA.getAllAreas === 'function') {
                        areas = LOCATION_DATA.getAllAreas(district);
                    }
                } else if (typeof LOCATION_DATA.getAllAreas === 'function') {
                    areas = LOCATION_DATA.getAllAreas(district);
                }
            }
            areaSelect.innerHTML = '<option value="all">All Areas / Localities</option>' + 
                areas.map(a => `<option value="${a}" ${this.userQuery.area === a ? 'selected' : ''}>${a}</option>`).join('');
        };

        // Initial option cascade
        updateStateOptions();
        updateDistrictOptions();
        updateTalukaOptions();
        updateRegionOptions();
        updateAreaOptions();

        // Event listeners
        searchInput.addEventListener('input', (e) => {
            clearTimeout(this.debouncedSearchTimeout);
            this.debouncedSearchTimeout = setTimeout(() => {
                this.userQuery.search = e.target.value;
                this.userQuery.page = 1;
                this.fetchUsersList();
            }, 400);
        });

        searchInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                clearTimeout(this.debouncedSearchTimeout);
                this.userQuery.search = e.target.value;
                this.userQuery.page = 1;
                this.fetchUsersList();
            }
        });

        statusSelect.addEventListener('change', (e) => {
            this.userQuery.status = e.target.value;
            this.userQuery.page = 1;
            this.fetchUsersList();
        });

        const userSortSelect = document.getElementById('user-sort-filter');
        if (userSortSelect) {
            userSortSelect.addEventListener('change', (e) => {
                this.userQuery.sort = e.target.value;
                this.userQuery.page = 1;
                this.fetchUsersList();
            });
        }

        const userDateInput = document.getElementById('user-date-filter');
        if (userDateInput) {
            userDateInput.addEventListener('change', (e) => {
                this.userQuery.date = e.target.value;
                this.userQuery.page = 1;
                this.fetchUsersList();
            });
        }

        countrySelect.addEventListener('change', (e) => {
            this.userQuery.country = e.target.value === 'all' ? '' : e.target.value;
            this.userQuery.state = '';
            this.userQuery.district = '';
            this.userQuery.taluka = '';
            this.userQuery.region = '';
            this.userQuery.area = '';
            this.userQuery.page = 1;
            updateStateOptions();
            updateDistrictOptions();
            updateTalukaOptions();
            updateRegionOptions();
            updateAreaOptions();
            this.fetchUsersList();
        });

        stateSelect.addEventListener('change', (e) => {
            this.userQuery.state = e.target.value === 'all' ? '' : e.target.value;
            this.userQuery.district = '';
            this.userQuery.taluka = '';
            this.userQuery.region = '';
            this.userQuery.area = '';
            this.userQuery.page = 1;
            updateDistrictOptions();
            updateTalukaOptions();
            updateRegionOptions();
            updateAreaOptions();
            this.fetchUsersList();
        });

        districtSelect.addEventListener('change', (e) => {
            this.userQuery.district = e.target.value === 'all' ? '' : e.target.value;
            this.userQuery.taluka = '';
            this.userQuery.region = '';
            this.userQuery.area = '';
            this.userQuery.page = 1;
            updateTalukaOptions();
            updateRegionOptions();
            updateAreaOptions();
            this.fetchUsersList();
        });

        talukaSelect.addEventListener('change', (e) => {
            this.userQuery.taluka = e.target.value === 'all' ? '' : e.target.value;
            this.userQuery.area = '';
            this.userQuery.page = 1;
            updateAreaOptions();
            this.fetchUsersList();
        });

        if (regionSelect) {
            regionSelect.addEventListener('change', (e) => {
                this.userQuery.region = e.target.value === 'all' ? '' : e.target.value;
                this.userQuery.area = '';
                this.userQuery.page = 1;
                updateAreaOptions();
                this.fetchUsersList();
            });
        }

        if (areaSelect) {
            areaSelect.addEventListener('change', (e) => {
                this.userQuery.area = e.target.value === 'all' ? '' : e.target.value;
                this.userQuery.page = 1;
                this.fetchUsersList();
            });
        }

        if (resetBtn) {
            resetBtn.addEventListener('click', () => {
                this.userQuery = { search: '', status: 'all', sort: 'newest', date: '', country: 'India', state: '', district: '', taluka: '', region: '', area: '', page: 1, limit: 10 };
                const uSort = document.getElementById('user-sort-filter'); if (uSort) uSort.value = 'newest';
                const uDate = document.getElementById('user-date-filter'); if (uDate) uDate.value = '';
                searchInput.value = '';
                statusSelect.value = 'all';
                countrySelect.value = 'India';
                updateStateOptions();
                updateDistrictOptions();
                updateTalukaOptions();
                updateRegionOptions();
                updateAreaOptions();
                this.fetchUsersList();
            });
        }

        // Trigger fetch
        await this.fetchUsersList();
    }

    async fetchUsersList() {
        const tbody = document.getElementById('users-tbody');
        if (!tbody) return;

        tbody.innerHTML = `
            <tr>
                <td colspan="10" class="text-center">
                    <div style="padding: 20px;"><div class="spinner" style="margin: 0 auto; width: 28px; height: 28px;"></div></div>
                </td>
            </tr>
        `;

        try {
            const result = await api.getUsers(this.userQuery);
            const users = result.data.users;
            this.users = users; // Cache users in state
            const pagination = result.data.pagination;

            // Update Location Breadcrumb & Count Badge
            const locBreadcrumb = document.getElementById('user-location-breadcrumb');
            const countBadge = document.getElementById('user-count-badge');

            if (locBreadcrumb) {
                const parts = [];
                if (this.userQuery.country && this.userQuery.country !== 'all') parts.push(this.userQuery.country);
                else parts.push('All Countries');
                if (this.userQuery.state && this.userQuery.state !== 'all') parts.push(this.userQuery.state);
                if (this.userQuery.district && this.userQuery.district !== 'all') parts.push(this.userQuery.district);
                if (this.userQuery.taluka && this.userQuery.taluka !== 'all') parts.push(this.userQuery.taluka);
                if (this.userQuery.region && this.userQuery.region !== 'all') parts.push(this.userQuery.region);
                if (this.userQuery.area && this.userQuery.area !== 'all') parts.push(this.userQuery.area);
                locBreadcrumb.innerHTML = 'Filter Location: <span style="color: var(--accent-primary, #fe750b);">' + parts.join(' &gt; ') + '</span>';
            }

            if (countBadge) {
                countBadge.textContent = `${pagination.total_records} Total ${pagination.total_records === 1 ? 'Customer' : 'Customers'}`;
            }
            const onlineBadge = document.getElementById('user-online-badge');
            if (onlineBadge) {
                const onlineCount = result.data.online_count !== undefined ? result.data.online_count : (users.filter(u => u.is_online).length);
                onlineBadge.innerHTML = `<span style="width: 8px; height: 8px; background: #10b981; border-radius: 50%;"></span> ${onlineCount} Online Now`;
            }

            if (users.length === 0) {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="13" class="text-center" style="padding: 40px; color: var(--text-secondary);">
                            <i class="fa-solid fa-circle-info" style="font-size: 32px; margin-bottom: 12px; display: block;"></i>
                            No customer users found matching the selected location filters.
                        </td>
                    </tr>
                `;
                document.getElementById('user-pagination').innerHTML = '';
                return;
            }

            tbody.innerHTML = users.map(user => {
                const isOnline = !!user.is_online;
                const liveStatusBadge = isOnline
                    ? '<span class="badge" style="background: #dcfce7; color: #15803d; border: 1px solid #86efac; font-weight: 700; padding: 4px 11px; border-radius: 20px; display: inline-flex; align-items: center; gap: 5px; box-shadow: 0 1px 2px rgba(16, 185, 129, 0.15);"><span style="width: 7px; height: 7px; background: #16a34a; border-radius: 50%; box-shadow: 0 0 0 2px rgba(22, 163, 74, 0.3);"></span> Online</span>'
                    : '<span class="badge" style="background: var(--bg-surface, #f8fafc); color: var(--text-muted, #64748b); border: 1px solid var(--border-color, #e2e8f0); font-weight: 500; padding: 4px 10px; border-radius: 20px; display: inline-flex; align-items: center; gap: 5px;"><span style="width: 6px; height: 6px; background: #94a3b8; border-radius: 50%;"></span> Offline</span>';

                const statusBadge = user.is_active 
                    ? '<span class="badge badge-success">Active</span>' 
                    : '<span class="badge badge-danger">Deactivated</span>';
                
                const toggleIcon = user.is_active ? 'fa-user-slash' : 'fa-user-check';
                const toggleTitle = user.is_active ? 'Deactivate Customer' : 'Activate Customer';
                const createdDate = new Date(user.created_at);
                const dateStr = !isNaN(createdDate.getTime()) ? createdDate.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' }) : 'N/A';
                const timeStr = !isNaN(createdDate.getTime()) ? createdDate.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true }) : '';
                const isToday = !isNaN(createdDate.getTime()) && (new Date().toDateString() === createdDate.toDateString());
                const isRecent = !isNaN(createdDate.getTime()) && (Date.now() - createdDate.getTime() < 48 * 3600 * 1000);

                const userLoc = [user.area, user.taluka, user.district, user.state, user.country || 'India'].filter(Boolean).join(', ');
                const resolvedUserLoc = (typeof LOCATION_DATA !== 'undefined' && typeof LOCATION_DATA.resolveLocation === 'function')
                    ? LOCATION_DATA.resolveLocation((user.area || '') + ' ' + (user.full_address || user.address || '') + ' ' + (user.taluka || '') + ' ' + (user.city || ''), user.district, user.taluka)
                    : { area: '', region: '' };
                const displayArea = user.area || resolvedUserLoc.area || '';
                const displayRegion = resolvedUserLoc.region || '';
                const userAreaBadge = (typeof LOCATION_DATA !== 'undefined' && typeof LOCATION_DATA.renderAreaRegionBadge === 'function')
                    ? LOCATION_DATA.renderAreaRegionBadge(displayArea, displayRegion)
                    : '';

                return `
                    <tr id="user-row-${user.id}" style="${isOnline ? 'background: rgba(16, 185, 129, 0.05);' : ''}">
                        <td><strong>#${user.id}</strong></td>
                        <td>
                            <div style="display: flex; align-items: center; gap: 10px;">
                                <div style="position: relative; display: inline-block;">
                                    <div class="avatar-fallback" style="width: 34px; height: 34px; font-size: 13px; background: linear-gradient(135deg, ${isOnline ? '#059669, #10b981' : '#2563eb, #3b82f6'}); color: white; border-radius: 50%;">
                                        ${user.full_name.charAt(0).toUpperCase()}
                                    </div>
                                    ${isOnline ? `
                                        <span title="Customer is online right now" style="position: absolute; bottom: 0; right: 0; width: 10px; height: 10px; background: #10b981; border: 2px solid #ffffff; border-radius: 50%; box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.4);"></span>
                                    ` : ''}
                                </div>
                                <div style="display: flex; flex-direction: column;">
                                    <div style="display: flex; align-items: center; gap: 6px;">
                                        <span class="font-semibold">${user.full_name}</span>
                                        ${isOnline ? `
                                            <span class="badge" style="background: #dcfce7; color: #15803d; border: 1px solid #86efac; font-size: 9px; font-weight: 800; padding: 1px 6px; border-radius: 8px;">ONLINE</span>
                                        ` : ''}
                                    </div>
                                    <span style="font-size: 11px; color: var(--text-muted);"><i class="fa-solid fa-phone"></i> ${user.phone_number || user.phone || 'N/A'}</span>
                                    <span style="font-size: 11px; color: #2563eb; font-weight: 500; display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">
                                        <i class="fa-solid fa-location-dot"></i> ${userLoc}
                                        ${userAreaBadge}
                                    </span>
                                </div>
                            </div>
                        </td>
                        <td>${user.email}</td>
                        <td>
                            <div style="display: inline-flex; align-items: center; gap: 6px; font-family: monospace; font-size: 11px; background: var(--bg-surface); padding: 3px 8px; border-radius: 6px; border: 1px solid var(--border-color);">
                                <span id="list-user-pwd-${user.id}">${user.password ? '••••••••' : 'N/A'}</span>
                                ${user.password ? `
                                    <button type="button" class="btn btn-secondary btn-icon" style="width: 22px; height: 22px; font-size: 10px;" title="Show/Hide Password" onclick="app.togglePasswordVisibility('list-user-pwd-${user.id}', '${(user.password || '').replace(/'/g, "\\'")}'); event.stopPropagation();">
                                        <i id="user-pwd-icon-list-user-pwd-${user.id}" class="fa-solid fa-eye"></i>
                                    </button>
                                ` : ''}
                            </div>
                        </td>
                        <td class="text-right font-semibold text-success">₹${user.wallet_balance}</td>
                        <td class="text-center"><span class="badge" style="background-color: var(--bg-surface);">${user.order_count} orders</span></td>
                        <td class="text-center">${liveStatusBadge}</td>
                        <td>${statusBadge}</td>
                        <td>
                            <div style="display: flex; flex-direction: column; gap: 2px;">
                                <span style="display: inline-flex; align-items: center; gap: 5px; font-weight: 700; font-size: 12px; color: var(--text-primary);">
                                    <i class="fa-regular fa-calendar-check text-primary" style="font-size: 11px;"></i> ${dateStr}
                                    ${isToday ? '<span class="badge" style="background:#dcfce7; color:#15803d; border:1px solid #86efac; font-size:9px; font-weight:800; padding:1px 5px; border-radius:10px;">TODAY</span>' : (isRecent ? '<span class="badge" style="background:#eff6ff; color:#1d4ed8; border:1px solid #bfdbfe; font-size:9px; font-weight:800; padding:1px 5px; border-radius:10px;">NEW</span>' : '')}
                                </span>
                                ${timeStr ? `<span style="font-size: 11px; color: var(--text-muted); padding-left: 16px;"><i class="fa-regular fa-clock" style="font-size: 10px;"></i> ${timeStr}</span>` : ''}
                            </div>
                        </td>
                        <td class="text-right">
                            <div class="table-actions" style="justify-content: flex-end;">
                                <button class="btn btn-secondary btn-icon btn-customer-hotels-toggle" id="view-hotels-btn-${user.id}" title="View Nearest Hotels & Chosen Location" onclick="app.toggleCustomerHotelsDropdown(${user.id}, this, event)" style="color: #ea580c; border-color: rgba(234, 88, 12, 0.35); background: rgba(234, 88, 12, 0.08);">
                                    <i class="fa-solid fa-hotel"></i>
                                </button>
                                <button class="btn btn-secondary btn-icon" title="View Full Profile" onclick="app.viewUserDetails(${user.id})">
                                    <i class="fa-solid fa-eye"></i>
                                </button>
                                <button class="btn btn-secondary btn-icon" title="Edit Profile" onclick="app.editUserRoute(${user.id})">
                                    <i class="fa-solid fa-pencil"></i>
                                </button>
                                <button class="btn btn-secondary btn-icon" title="${toggleTitle}" onclick="app.toggleUserActiveState(${user.id}, ${user.is_active})">
                                    <i class="fa-solid ${toggleIcon}"></i>
                                </button>
                                <button class="btn btn-danger btn-icon" title="Delete Profile" onclick="app.openDeleteModal(${user.id}, 'user')">
                                    <i class="fa-solid fa-trash-can"></i>
                                </button>
                            </div>
                        </td>
                    </tr>
                    <tr id="customer-hotels-dropdown-row-${user.id}" class="customer-hotels-dropdown-row" style="display: none;">
                        <td colspan="10" style="padding: 0; border: none; background: #fffcf7;">
                            <div class="customer-hotels-dropdown-wrapper" id="customer-hotels-dropdown-${user.id}"></div>
                        </td>
                    </tr>
                `;
            }).join('');

            this.renderPagination('user-pagination', pagination, (newPage) => {
                this.userQuery.page = newPage;
                this.fetchUsersList();
            });

        } catch (error) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="13" class="text-center text-danger" style="padding: 24px;">
                        Failed to fetch customer list: ${error.message}
                    </td>
                </tr>
            `;
        }
    }

    /**
     * Subscriptions Management List View
     */
    async loadSubscriptionsView(container) {
        container.innerHTML = `
            <div class="view-header">
                <h2>Subscriptions Control Panel</h2>
                <div class="view-actions" style="display: flex; gap: 8px;">
                    <button class="btn btn-success" onclick="app.openAssignPlanModal()" style="background: #16a34a; border-color: #16a34a; color: white;">
                        <i class="fa-solid fa-plus-circle"></i> Assign Plan Manually
                    </button>
                    <button class="btn btn-primary" onclick="app.runCronJob()">
                        <i class="fa-solid fa-arrows-rotate"></i> Run Daily Verification
                    </button>
                </div>
            </div>

            <div class="filter-bar">
                <div class="search-input-wrapper">
                    <i class="fa-solid fa-magnifying-glass search-icon"></i>
                    <input type="text" id="sub-search" class="search-input" placeholder="Search by customer, plan, or area..." value="${this.subscriptionQuery.search}">
                </div>
                <div class="filters-wrapper">
                    <select id="sub-status-filter" class="filter-select">
                        <option value="all" ${this.subscriptionQuery.status === 'all' ? 'selected' : ''}>All Statuses</option>
                        <option value="active" ${this.subscriptionQuery.status === 'active' ? 'selected' : ''}>Active</option>
                        <option value="paused" ${this.subscriptionQuery.status === 'paused' ? 'selected' : ''}>Paused</option>
                        <option value="expiring_soon" ${this.subscriptionQuery.status === 'expiring_soon' ? 'selected' : ''}>Expiring Soon</option>
                        <option value="expired" ${this.subscriptionQuery.status === 'expired' ? 'selected' : ''}>Expired</option>
                        <option value="completed" ${this.subscriptionQuery.status === 'completed' ? 'selected' : ''}>Completed</option>
                        <option value="cancelled" ${this.subscriptionQuery.status === 'cancelled' ? 'selected' : ''}>Cancelled</option>
                    </select>
                </div>
            </div>

            <div class="table-responsive">
                <table class="table" id="subscriptions-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Customer</th>
                            <th>Plan Details</th>
                            <th>Deliveries</th>
                            <th>Timeline</th>
                            <th>Status</th>
                            <th class="text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="subscriptions-tbody">
                        <tr>
                            <td colspan="7" class="text-center">
                                <div style="padding: 30px;"><div class="spinner" style="margin: 0 auto; width: 30px; height: 30px;"></div></div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div id="sub-pagination" class="pagination-wrapper"></div>
        `;

        const searchInput = document.getElementById('sub-search');
        const statusSelect = document.getElementById('sub-status-filter');

        searchInput.addEventListener('input', (e) => {
            clearTimeout(this.debouncedSearchTimeout);
            this.debouncedSearchTimeout = setTimeout(() => {
                this.subscriptionQuery.search = e.target.value;
                this.subscriptionQuery.page = 1;
                this.fetchSubscriptionsList();
            }, 400);
        });

        statusSelect.addEventListener('change', (e) => {
            this.subscriptionQuery.status = e.target.value;
            this.subscriptionQuery.page = 1;
            this.fetchSubscriptionsList();
        });

        await this.fetchSubscriptionsList();
    }

    async fetchSubscriptionsList() {
        const tbody = document.getElementById('subscriptions-tbody');
        if (!tbody) return;

        tbody.innerHTML = `
            <tr>
                <td colspan="7" class="text-center">
                    <div style="padding: 20px;"><div class="spinner" style="margin: 0 auto; width: 28px; height: 28px;"></div></div>
                </td>
            </tr>
        `;

        try {
            const result = await api.getSubscriptions(this.subscriptionQuery);
            const subscriptions = result.data.subscriptions;
            const pagination = result.data.pagination;

            if (subscriptions.length === 0) {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="7" class="text-center" style="padding: 40px; color: var(--text-secondary);">
                            <i class="fa-solid fa-circle-info" style="font-size: 32px; margin-bottom: 12px; display: block;"></i>
                            No subscriptions found.
                        </td>
                    </tr>
                `;
                document.getElementById('sub-pagination').innerHTML = '';
                return;
            }

            tbody.innerHTML = subscriptions.map(sub => {
                let statusClass = 'badge-secondary';
                if (sub.status === 'ACTIVE') statusClass = 'badge-success';
                else if (sub.status === 'PAUSED') statusClass = 'badge-warning';
                else if (sub.status === 'EXPIRED') statusClass = 'badge-danger';
                else if (sub.status === 'COMPLETED') statusClass = 'badge-info';

                const statusBadge = `<span class="badge ${statusClass}">${sub.status}</span>`;
                const isPaused = sub.status === 'PAUSED';
                const isCancelled = sub.status === 'CANCELLED' || sub.status === 'EXPIRED' || sub.status === 'COMPLETED';

                const startDateStr = new Date(sub.start_date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
                const endDateStr = new Date(sub.end_date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });

                return `
                    <tr>
                        <td><strong>#${sub.id}</strong></td>
                        <td>
                            <div style="display: flex; flex-direction: column;">
                                <span class="font-semibold">${sub.customer_name}</span>
                                <span style="font-size: 11px; color: var(--text-muted);">${sub.customer_email}</span>
                            </div>
                        </td>
                        <td>
                            <div style="display: flex; flex-direction: column;">
                                <span class="font-semibold">${sub.plan_name}</span>
                                <span style="font-size: 11px; color: var(--text-muted);">${sub.area_name} > ${sub.sub_area_name}</span>
                            </div>
                        </td>
                        <td>
                            <div style="display: flex; flex-direction: column;">
                                <span>${sub.completed_deliveries} / ${sub.total_deliveries}</span>
                                <div style="width: 80px; height: 4px; background-color: var(--bg-surface); border-radius: 2px; overflow: hidden; margin-top: 4px;">
                                    <div style="width: ${sub.total_deliveries > 0 ? (sub.completed_deliveries / sub.total_deliveries * 100) : 0}%; height: 100%; background-color: var(--accent-success);"></div>
                                </div>
                            </div>
                        </td>
                        <td>
                            <div style="font-size: 12px;">
                                <span>${startDateStr} to ${endDateStr}</span>
                            </div>
                        </td>
                        <td>${statusBadge}</td>
                        <td class="text-right">
                            <div class="table-actions" style="justify-content: flex-end;">
                                ${!isCancelled ? `
                                    <button class="btn btn-secondary btn-icon" title="${isPaused ? 'Resume Plan' : 'Pause Plan'}" onclick="app.handleSubscriptionAction(${sub.id}, '${isPaused ? 'resume' : 'pause'}')">
                                        <i class="fa-solid ${isPaused ? 'fa-play' : 'fa-pause'}"></i>
                                    </button>
                                    <button class="btn btn-secondary btn-icon" title="Extend Plan" onclick="app.handleSubscriptionAction(${sub.id}, 'extend')">
                                        <i class="fa-solid fa-clock-rotate-left"></i>
                                    </button>
                                    <button class="btn btn-secondary btn-icon" title="Change Plan" onclick="app.handleSubscriptionAction(${sub.id}, 'change_plan')">
                                        <i class="fa-solid fa-shuffle"></i>
                                    </button>
                                    <button class="btn btn-danger btn-icon" title="Cancel Subscription" onclick="app.handleSubscriptionAction(${sub.id}, 'cancel')">
                                        <i class="fa-solid fa-ban"></i>
                                    </button>
                                ` : `
                                    <span style="font-size: 11px; color: var(--text-muted);">No actions available</span>
                                `}
                            </div>
                        </td>
                    </tr>
                `;
            }).join('');

            this.renderPagination('sub-pagination', pagination, (newPage) => {
                this.subscriptionQuery.page = newPage;
                this.fetchSubscriptionsList();
            });

        } catch (error) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="7" class="text-center text-danger" style="padding: 24px;">
                        Failed to fetch subscription list: ${error.message}
                    </td>
                </tr>
            `;
        }
    }

    async handleSubscriptionAction(subId, action) {
        let payload = { subscription_id: subId, action };

        if (action === 'extend') {
            const days = prompt('Enter the number of days to extend the subscription:');
            if (days === null) return;
            const daysInt = parseInt(days);
            if (isNaN(daysInt) || daysInt <= 0) {
                this.showToast('Please enter a valid number of days greater than 0.', 'error');
                return;
            }
            payload.days = daysInt;
        } else if (action === 'change_plan') {
            const planId = prompt('Enter the target Subscription Plan ID to upgrade/downgrade:');
            if (planId === null) return;
            const planIdInt = parseInt(planId);
            if (isNaN(planIdInt) || planIdInt <= 0) {
                this.showToast('Please enter a valid Plan ID.', 'error');
                return;
            }
            payload.new_plan_id = planIdInt;
        } else {
            const confirm = window.confirm(`Are you sure you want to perform action '${action}' on subscription #${subId}?`);
            if (!confirm) return;
        }

        this.showLoader(true);
        try {
            await api.performSubscriptionAction(payload);
            this.showToast(`Action '${action}' executed successfully on subscription #${subId}.`, 'success');
            await this.fetchSubscriptionsList();
        } catch (error) {
            this.showToast(error.message, 'error');
        } finally {
            this.showLoader(false);
        }
    }
    async runCronJob() {
        this.showLoader(true);
        try {
            const response = await fetch(`${api.baseUrl}/cron/verify_subscriptions`);
            const result = await response.json();
            if (result.success) {
                this.showToast('Daily cron verification ran successfully.', 'success');
                await this.fetchSubscriptionsList();
            } else {
                this.showToast('Cron Job completed but returned failure status.', 'error');
            }
        } catch (error) {
            this.showToast('Error running cron job API: ' + error.message, 'error');
        } finally {
            this.showLoader(false);
        }
    }
    /**
     * Add User View
     */
    loadAddUserView(container) {
        container.innerHTML = `
            <div class="view-header">
                <h2>Create Customer Account</h2>
                <a href="/admin/users" class="btn btn-secondary" data-link>
                    <i class="fa-solid fa-arrow-left"></i> Back to List
                </a>
            </div>

            <div class="profile-card" style="margin: 0 auto; max-width: 500px;">
                <form id="add-user-form" onsubmit="app.handleAddUser(event)">
                    <div class="form-group">
                        <label class="form-label" for="user-name">Full Name</label>
                        <input type="text" id="user-name" class="form-control" placeholder="Customer Name" required>
                        <div class="form-error hidden" id="error-name"></div>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="user-email">Email Address</label>
                        <input type="email" id="user-email" class="form-control" placeholder="customer@email.com" required>
                        <div class="form-error hidden" id="error-email"></div>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="user-password">Password</label>
                        <input type="password" id="user-password" class="form-control" placeholder="Minimum 8 characters, letter & number" required>
                        <div class="form-error hidden" id="error-password"></div>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="user-confirm-password">Confirm Password</label>
                        <input type="password" id="user-confirm-password" class="form-control" placeholder="••••••••" required>
                        <div class="form-error hidden" id="error-confirm-password"></div>
                    </div>
                    
                    <div style="display: flex; gap: 12px; margin-top: 24px;">
                        <button type="submit" class="btn btn-primary" style="flex: 1;">
                            <i class="fa-solid fa-user-plus"></i> Create Profile
                        </button>
                        <a href="/admin/users" class="btn btn-secondary" style="flex: 1; text-align: center;" data-link>Cancel</a>
                    </div>
                </form>
            </div>
        `;
    }

    /**
     * Edit User View
     */
    async loadEditUserView(container) {
        const id = parseInt(this.decodedQuery.get('id'));
        if (!id) {
            this.navigateTo('/admin/users');
            return;
        }

        container.innerHTML = `
            <div class="view-header">
                <h2>Modify Customer Profile</h2>
                <a href="/admin/users" class="btn btn-secondary" data-link>
                    <i class="fa-solid fa-arrow-left"></i> Back to List
                </a>
            </div>
            <div style="display: flex; justify-content: center; padding: 40px;">
                <div class="spinner" style="width: 32px; height: 32px;"></div>
            </div>
        `;

        let customer = null;
        try {
            const result = await api.getUserDetails(id);
            if (result && result.data && result.data.customer) {
                customer = result.data.customer;
            }
        } catch (e) {
            console.error('Failed to fetch customer details:', e);
        }

        if (!customer) {
            customer = (this.users || []).find(u => u.id === id);
        }

        if (!customer) {
            this.showToast('Customer profile not found.', 'error');
            this.navigateTo('/admin/users');
            return;
        }

        const phoneVal = customer.phone_number || customer.phone || '';

        container.innerHTML = `
            <div class="view-header">
                <div>
                    <h2>Modify Customer Profile: ${this.escapeHtml(customer.full_name || '')}</h2>
                    <span style="font-size: 13px; color: var(--text-secondary);">Customer ID: #${customer.id} • Wallet: ₹${customer.wallet_balance || '0.00'}</span>
                </div>
                <a href="/admin/users" class="btn btn-secondary" data-link>
                    <i class="fa-solid fa-arrow-left"></i> Back to List
                </a>
            </div>

            <div class="profile-card" style="margin: 0 auto; max-width: 720px; padding: 28px;">
                <form id="edit-user-form" onsubmit="app.handleEditUser(event, ${customer.id})">
                    <h3 style="font-size: 16px; font-weight: 700; color: var(--text-primary); margin-bottom: 16px; display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-user" style="color: var(--accent-primary);"></i> Customer Personal Information
                    </h3>

                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px;">
                        <div class="form-group">
                            <label class="form-label" for="user-edit-name">Full Name *</label>
                            <input type="text" id="user-edit-name" class="form-control" value="${this.escapeHtml(customer.full_name || '')}" required>
                            <div class="form-error hidden" id="error-name"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="user-edit-email">Email Address *</label>
                            <input type="email" id="user-edit-email" class="form-control" value="${this.escapeHtml(customer.email || '')}" required>
                            <div class="form-error hidden" id="error-email"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="user-edit-phone">Phone Number</label>
                            <input type="text" id="user-edit-phone" class="form-control" value="${this.escapeHtml(phoneVal)}" placeholder="+91 9876543210">
                            <div class="form-error hidden" id="error-phone"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="user-edit-password">Password / Reset Password</label>
                            <input type="text" id="user-edit-password" class="form-control" value="${this.escapeHtml(customer.password || '')}" placeholder="Enter new password or leave as is">
                            <div class="form-error hidden" id="error-password"></div>
                        </div>
                        <div class="form-group" style="grid-column: 1 / -1;">
                            <label class="form-label" for="user-edit-status">Account Status</label>
                            <select id="user-edit-status" class="form-control">
                                <option value="1" ${customer.is_active ? 'selected' : ''}>Active (Enabled)</option>
                                <option value="0" ${!customer.is_active ? 'selected' : ''}>Inactive (Suspended)</option>
                            </select>
                        </div>
                    </div>

                    <h3 style="font-size: 16px; font-weight: 700; color: var(--text-primary); margin-top: 24px; margin-bottom: 16px; border-top: 1px solid var(--border-color); padding-top: 20px; display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-location-dot" style="color: var(--accent-primary);"></i> Location Details
                    </h3>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px;">
                        <div class="form-group">
                            <label class="form-label" for="user-edit-country">Country</label>
                            <select id="user-edit-country" class="form-control"></select>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="user-edit-state">State</label>
                            <select id="user-edit-state" class="form-control"></select>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="user-edit-district">District</label>
                            <select id="user-edit-district" class="form-control"></select>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="user-edit-taluka">Taluka</label>
                            <select id="user-edit-taluka" class="form-control"></select>
                        </div>
                    </div>
                    
                    <div style="display: flex; gap: 12px; margin-top: 28px; border-top: 1px solid var(--border-color); padding-top: 20px;">
                        <button type="submit" class="btn btn-primary" style="flex: 1;">
                            <i class="fa-solid fa-check"></i> Save Customer Changes
                        </button>
                        <a href="/admin/users" class="btn btn-secondary" style="flex: 1; text-align: center;" data-link>Cancel</a>
                    </div>
                </form>
            </div>
        `;

        this.initLocationDropdowns(
            document.getElementById('user-edit-country'),
            document.getElementById('user-edit-state'),
            document.getElementById('user-edit-district'),
            document.getElementById('user-edit-taluka'),
            {
                country: customer.country || 'India',
                state: customer.state || '',
                district: customer.district || '',
                taluka: customer.taluka || ''
            }
        );
    }

    /**
     * Profile View
     */
    async loadProfileView(container) {
        container.innerHTML = `
            <div class="profile-card">
                <div class="profile-avatar-row">
                    <div class="profile-avatar-large" id="profile-char">A</div>
                    <h3 class="profile-name" id="profile-name">Admin User</h3>
                    <span class="badge" style="background-color: var(--bg-surface); margin-top: 6px; color: var(--accent-primary);">System Admin</span>
                </div>

                <div class="profile-details-grid">
                    <div>
                        <span class="detail-item-label">Account ID</span>
                        <div class="detail-item-value" id="profile-id">#0</div>
                    </div>
                    <div>
                        <span class="detail-item-label">Account Role</span>
                        <div class="detail-item-value">Administrator</div>
                    </div>
                    <div style="grid-column: span 2;">
                        <span class="detail-item-label">Email Address</span>
                        <div class="detail-item-value" id="profile-email">admin@omni.com</div>
                    </div>
                    <div style="grid-column: span 2;">
                        <span class="detail-item-label">Date Created</span>
                        <div class="detail-item-value" id="profile-date">-</div>
                    </div>
                </div>
            </div>

            <div class="profile-card" style="margin-top: 24px;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; flex-wrap: wrap; gap: 12px;">
                    <div>
                        <h3 style="font-size: 16px; font-weight: 700; margin: 0; display: flex; align-items: center; gap: 8px;">
                            <i class="fa-solid fa-database" style="color: var(--accent-primary);"></i> Database Schema & Table Column Refresh
                        </h3>
                        <p style="font-size: 13px; color: var(--text-muted); margin: 4px 0 0 0;">
                            Automatically verifies all 40+ database tables, adds missing columns, updates column definitions, and refreshes the database.
                        </p>
                    </div>
                    <button id="btn-run-migration" class="btn btn-primary" style="display: flex; align-items: center; gap: 8px; cursor: pointer; padding: 10px 18px; border-radius: 8px; font-weight: 600;">
                        <i class="fa-solid fa-arrows-rotate" id="migration-btn-icon"></i>
                        <span id="migration-btn-text">Refresh All Table Columns</span>
                    </button>
                </div>
                <div id="migration-status-box" style="display: none; padding: 14px 18px; border-radius: 8px; font-size: 13px; font-family: monospace; background: #f8fafc; border: 1px solid #e2e8f0; line-height: 1.6;"></div>
            </div>
        `;

        try {
            const result = await api.getProfile();
            const admin = result.data.admin;

            document.getElementById('profile-name').textContent = admin.full_name;
            document.getElementById('profile-char').textContent = admin.full_name.charAt(0).toUpperCase();
            document.getElementById('profile-id').textContent = `#${admin.id}`;
            document.getElementById('profile-email').textContent = admin.email;
            
            const dateStr = new Date(admin.created_at).toLocaleString('en-IN', {
                dateStyle: 'medium', timeStyle: 'short'
            });
            document.getElementById('profile-date').textContent = dateStr;

        } catch (error) {
            this.showToast('Error loading profile: ' + error.message, 'error');
        }

        const migrateBtn = document.getElementById('btn-run-migration');
        const statusBox = document.getElementById('migration-status-box');
        const btnIcon = document.getElementById('migration-btn-icon');
        const btnText = document.getElementById('migration-btn-text');

        if (migrateBtn) {
            migrateBtn.addEventListener('click', async () => {
                if (!confirm('Are you sure you want to run the database table and column refresher now?')) return;
                
                migrateBtn.disabled = true;
                btnIcon.classList.add('fa-spin');
                btnText.textContent = 'Refreshing Database Tables...';
                statusBox.style.display = 'block';
                statusBox.style.borderColor = '#93c5fd';
                statusBox.style.background = '#eff6ff';
                statusBox.style.color = '#1e3a8a';
                statusBox.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Running schema verification on all 40+ tables & columns...';

                try {
                    const res = await api.migrateDatabase();
                    const report = res.data && res.data.migration_report ? res.data.migration_report : {};
                    const summary = report.summary || {};
                    
                    statusBox.style.borderColor = '#86efac';
                    statusBox.style.background = '#f0fdf4';
                    statusBox.style.color = '#14532d';
                    
                    let html = `<div style="font-weight: 700; margin-bottom: 6px; font-size: 14px;">✓ ${res.message || 'Database tables and columns refreshed successfully!'}</div>`;
                    html += `<div><strong>Environment:</strong> ${report.environment || 'Production'}</div>`;
                    html += `<div><strong>Database:</strong> ${report.database || '-'}</div>`;
                    html += `<div><strong>Tables Verified:</strong> ${summary.total_tables_verified || 40} tables</div>`;
                    html += `<div><strong>Columns Checked:</strong> ${summary.total_columns_checked || 287} columns</div>`;
                    html += `<div><strong>New Columns Added:</strong> ${summary.new_columns_added_cnt || 0}</div>`;
                    html += `<div><strong>Column Modifications:</strong> ${summary.modifications_cnt || 0}</div>`;
                    html += `<div><strong>Executed At:</strong> ${report.executed_at || new Date().toLocaleString()}</div>`;
                    
                    if (report.new_columns_added && Object.keys(report.new_columns_added).length > 0) {
                        html += `<div style="margin-top: 8px;"><strong>Added Columns Details:</strong><pre style="margin: 4px 0 0 0; background: #ffffff; padding: 8px; border-radius: 4px; border: 1px solid #bbf7d0;">${JSON.stringify(report.new_columns_added, null, 2)}</pre></div>`;
                    }
                    
                    statusBox.innerHTML = html;
                    this.showToast('Database migration & column refresh successful!', 'success');
                } catch (err) {
                    statusBox.style.borderColor = '#fca5a5';
                    statusBox.style.background = '#fef2f2';
                    statusBox.style.color = '#7f1d1d';
                    statusBox.innerHTML = `<div style="font-weight: 700;"><i class="fa-solid fa-triangle-exclamation text-danger" style="margin-right: 6px;"></i> Migration Error:</div><div>${err.message}</div>`;
                    this.showToast('Migration error: ' + err.message, 'error');
                } finally {
                    migrateBtn.disabled = false;
                    btnIcon.classList.remove('fa-spin');
                    btnText.textContent = 'Refresh All Table Columns';
                }
            });
        }
    }

    /* -- Pagination Renderer ----------------------------------------------- */
    
    renderPagination(containerId, pagination, onPageChange) {
        const container = document.getElementById(containerId);
        if (!container) return;

        if (!pagination) {
            container.innerHTML = '';
            return;
        }

        const current = pagination.current_page || 1;
        const total = pagination.total_pages || 1;
        const totalRecs = pagination.total_records || 0;

        if (total <= 1) {
            container.innerHTML = `<div class="pagination-info">Showing all ${totalRecs} entries</div>`;
            return;
        }

        let buttonsHTML = '';
        
        // Prev button
        buttonsHTML += `
            <button class="page-btn" ${current === 1 ? 'disabled' : ''} data-page="${current - 1}">
                <i class="fa-solid fa-angle-left"></i>
            </button>
        `;

        // Page buttons
        for (let i = 1; i <= total; i++) {
            if (i === 1 || i === total || (i >= current - 1 && i <= current + 1)) {
                buttonsHTML += `
                    <button class="page-btn ${i === current ? 'active' : ''}" data-page="${i}">
                        ${i}
                    </button>
                `;
            } else if (i === current - 2 || i === current + 2) {
                buttonsHTML += `<span style="padding: 0 4px; color: var(--text-muted);">...</span>`;
            }
        }

        // Next button
        buttonsHTML += `
            <button class="page-btn" ${current === total ? 'disabled' : ''} data-page="${current + 1}">
                <i class="fa-solid fa-angle-right"></i>
            </button>
        `;

        container.innerHTML = `
            <div class="pagination-info">Showing page <strong>${current}</strong> of <strong>${total}</strong> (${totalRecs} records)</div>
            <div class="pagination-controls">
                ${buttonsHTML}
            </div>
        `;

        container.onclick = (e) => {
            const btn = e.target.closest('[data-page]');
            if (btn && !btn.hasAttribute('disabled')) {
                const page = parseInt(btn.getAttribute('data-page'));
                if (page && page > 0 && typeof onPageChange === 'function') {
                    onPageChange(page);
                }
            }
        };
    }

    /* -- Action Handlers --------------------------------------------------- */

    /**
     * Auth - Handle Login Submit
     */
    async handleLogin(e) {
        e.preventDefault();
        
        const email = document.getElementById('login-email').value;
        const password = document.getElementById('login-password').value;

        // Clear errors
        this.clearFormErrors(['email', 'password']);

        // Front-end validations
        let valid = true;
        if (!this.validateEmail(email)) {
            this.showError('email', 'Please enter a valid email address.');
            valid = false;
        }
        if (password.length === 0) {
            this.showError('password', 'Password is required.');
            valid = false;
        }

        if (!valid) return;

        this.showLoader(true);
        try {
            await api.login(email, password);
            this.showToast('Login successful. Welcome!', 'success');
            this.navigateTo('/admin/dashboard');
        } catch (error) {
            this.showToast(error.message, 'error');
            this.showError('password', 'Invalid email or password.');
        } finally {
            this.showLoader(false);
        }
    }
    /**
     * Auth - Handle Signup Submit
     */
    async handleSignup(e) {
        e.preventDefault();
        
        const name = document.getElementById('signup-name').value;
        const email = document.getElementById('signup-email').value;
        const password = document.getElementById('signup-password').value;
        const confirmPassword = document.getElementById('signup-confirm-password').value;

        this.clearFormErrors(['name', 'email', 'password', 'confirm-password']);

        let valid = true;
        if (name.trim().length < 2) {
            this.showError('name', 'Full name must be at least 2 characters.');
            valid = false;
        }
        if (!this.validateEmail(email)) {
            this.showError('email', 'Please enter a valid email address.');
            valid = false;
        }
        if (!this.validatePasswordStrength(password)) {
            this.showError('password', 'Password must be at least 8 characters and contain both letters and numbers.');
            valid = false;
        }
        if (password !== confirmPassword) {
            this.showError('confirm-password', 'Passwords do not match.');
            valid = false;
        }

        if (!valid) return;

        this.showLoader(true);
        try {
            await api.signup(name, email, password, confirmPassword);
            this.showToast('Account registered successfully!', 'success');
            this.navigateTo('/admin/dashboard');
        } catch (error) {
            this.showToast(error.message, 'error');
            this.showError('email', 'Email might already be in use.');
        } finally {
            this.showLoader(false);
        }
    }
    /**
     * Add Vendor handler
     */
    async handleAddVendor(e) {
        e.preventDefault();
        
        const name = document.getElementById('vendor-name').value;
        const email = document.getElementById('vendor-email').value;
        const password = document.getElementById('vendor-password').value;
        const confirmPassword = document.getElementById('vendor-confirm-password').value;

        this.clearFormErrors(['name', 'email', 'password', 'confirm-password']);

        let valid = true;
        if (name.trim().length < 2) {
            this.showError('name', 'Full name must be at least 2 characters.');
            valid = false;
        }
        if (!this.validateEmail(email)) {
            this.showError('email', 'Please enter a valid email address.');
            valid = false;
        }
        if (!this.validatePasswordStrength(password)) {
            this.showError('password', 'Password must be at least 8 characters and contain both letters and numbers.');
            valid = false;
        }
        if (password !== confirmPassword) {
            this.showError('confirm-password', 'Passwords do not match.');
            valid = false;
        }

        if (!valid) return;

        this.showLoader(true);
        try {
            await api.addVendor(name, email, password, confirmPassword);
            this.showToast('Vendor added successfully!', 'success');
            this.navigateTo('/admin/vendors');
        } catch (error) {
            this.showToast(error.message, 'error');
            this.showError('email', 'This email is already registered.');
        } finally {
            this.showLoader(false);
        }
    }
    /**
     * Edit Vendor Route Redirect
     */
    editVendorRoute(id) {
        this.navigateTo('/admin/vendors/edit?id=' + id);
    }

    /**
     * Edit Vendor handler
     */
    async handleEditVendor(e, id) {
        e.preventDefault();
        
        const name = document.getElementById('vendor-edit-name').value.trim();
        const email = document.getElementById('vendor-edit-email').value.trim();
        const phone = document.getElementById('vendor-edit-phone') ? document.getElementById('vendor-edit-phone').value.trim() : '';
        const password = document.getElementById('vendor-edit-password') ? document.getElementById('vendor-edit-password').value.trim() : '';
        const isActive = document.getElementById('vendor-edit-status') ? document.getElementById('vendor-edit-status').value === '1' : true;

        const country = document.getElementById('vendor-edit-country') ? document.getElementById('vendor-edit-country').value : 'India';
        const state = document.getElementById('vendor-edit-state') ? document.getElementById('vendor-edit-state').value : '';
        const district = document.getElementById('vendor-edit-district') ? document.getElementById('vendor-edit-district').value : '';
        const taluka = document.getElementById('vendor-edit-taluka') ? document.getElementById('vendor-edit-taluka').value : '';
        const region = document.getElementById('vendor-edit-region') ? document.getElementById('vendor-edit-region').value : '';
        const area = document.getElementById('vendor-edit-area') ? document.getElementById('vendor-edit-area').value : '';

        const bankName = document.getElementById('vendor-edit-bank-name') ? document.getElementById('vendor-edit-bank-name').value.trim() : '';
        const accountHolder = document.getElementById('vendor-edit-account-holder') ? document.getElementById('vendor-edit-account-holder').value.trim() : '';
        const accountNumber = document.getElementById('vendor-edit-account-number') ? document.getElementById('vendor-edit-account-number').value.trim() : '';
        const ifscCode = document.getElementById('vendor-edit-ifsc') ? document.getElementById('vendor-edit-ifsc').value.trim().toUpperCase() : '';

        const hotelName = document.getElementById('vendor-edit-hotel-name') ? document.getElementById('vendor-edit-hotel-name').value.trim() : '';
        const hotelAddress = document.getElementById('vendor-edit-hotel-address') ? document.getElementById('vendor-edit-hotel-address').value.trim() : '';
        const fssai = document.getElementById('vendor-edit-fssai') ? document.getElementById('vendor-edit-fssai').value.trim() : '';
        const gst = document.getElementById('vendor-edit-gst') ? document.getElementById('vendor-edit-gst').value.trim() : '';
        const pan = document.getElementById('vendor-edit-pan') ? document.getElementById('vendor-edit-pan').value.trim().toUpperCase() : '';
        const aadhar = document.getElementById('vendor-edit-aadhar') ? document.getElementById('vendor-edit-aadhar').value.trim() : '';

        this.clearFormErrors(['name', 'email']);

        let valid = true;
        if (name.length < 2) {
            this.showError('name', 'Full name must be at least 2 characters.');
            valid = false;
        }
        if (!this.validateEmail(email)) {
            this.showError('email', 'Please enter a valid email address.');
            valid = false;
        }

        if (!valid) return;

        this.showLoader(true);
        try {
            await api.editVendor({
                id,
                full_name: name,
                email,
                phone,
                password,
                is_active: isActive,
                country,
                state,
                district,
                taluka,
                region,
                area,
                bank_name: bankName,
                account_holder_name: accountHolder,
                account_number: accountNumber,
                ifsc_code: ifscCode,
                hotel_name: hotelName,
                hotel_address: hotelAddress,
                fssai_number: fssai,
                gst_number: gst,
                pan_number: pan,
                aadhar_number: aadhar
            });
            this.showToast('Vendor profile updated successfully.', 'success');
            localStorage.removeItem('omni_admin_edit_vendor');
            this.navigateTo('/admin/vendors');
        } catch (error) {
            this.showToast(error.message, 'error');
            this.showError('email', error.message.includes('email') ? error.message : 'Failed to update vendor profile.');
        } finally {
            this.showLoader(false);
        }
    }
    /**
     * Active state toggle for Vendor
     */
    async toggleVendorActiveState(id, currentStatus) {
        this.showLoader(true);
        try {
            const nextStatus = !currentStatus;
            await api.toggleVendorStatus(id, nextStatus);
            this.showToast(`Vendor account updated successfully.`, 'success');
            await this.fetchVendorsList();
        } catch (error) {
            this.showToast('Failed to toggle vendor status: ' + error.message, 'error');
        } finally {
            this.showLoader(false);
        }
    }
    /**
     * Add User handler
     */
    async handleAddUser(e) {
        e.preventDefault();
        
        const name = document.getElementById('user-name').value;
        const email = document.getElementById('user-email').value;
        const password = document.getElementById('user-password').value;
        const confirmPassword = document.getElementById('user-confirm-password').value;

        this.clearFormErrors(['name', 'email', 'password', 'confirm-password']);

        let valid = true;
        if (name.trim().length < 2) {
            this.showError('name', 'Full name must be at least 2 characters.');
            valid = false;
        }
        if (!this.validateEmail(email)) {
            this.showError('email', 'Please enter a valid email address.');
            valid = false;
        }
        if (!this.validatePasswordStrength(password)) {
            this.showError('password', 'Password must be at least 8 characters and contain both letters and numbers.');
            valid = false;
        }
        if (password !== confirmPassword) {
            this.showError('confirm-password', 'Passwords do not match.');
            valid = false;
        }

        if (!valid) return;

        this.showLoader(true);
        try {
            await api.addUser(name, email, password, confirmPassword);
            this.showToast('Customer account created.', 'success');
            this.navigateTo('/admin/users');
        } catch (error) {
            this.showToast(error.message, 'error');
            this.showError('email', 'This email is already in use.');
        } finally {
            this.showLoader(false);
        }
    }
    /**
     * Edit User Route Redirect
     */
    editUserRoute(id) {
        this.navigateTo('/admin/users/edit?id=' + id);
    }

    /**
     * Edit User handler
     */
    async handleEditUser(e, id) {
        e.preventDefault();
        
        const name = document.getElementById('user-edit-name').value.trim();
        const email = document.getElementById('user-edit-email').value.trim();
        const phone = document.getElementById('user-edit-phone') ? document.getElementById('user-edit-phone').value.trim() : '';
        const password = document.getElementById('user-edit-password') ? document.getElementById('user-edit-password').value.trim() : '';
        const isActive = document.getElementById('user-edit-status') ? document.getElementById('user-edit-status').value === '1' : true;

        const country = document.getElementById('user-edit-country') ? document.getElementById('user-edit-country').value : 'India';
        const state = document.getElementById('user-edit-state') ? document.getElementById('user-edit-state').value : '';
        const district = document.getElementById('user-edit-district') ? document.getElementById('user-edit-district').value : '';
        const taluka = document.getElementById('user-edit-taluka') ? document.getElementById('user-edit-taluka').value : '';

        this.clearFormErrors(['name', 'email', 'password']);

        let valid = true;
        if (name.length < 2) {
            this.showError('name', 'Full name must be at least 2 characters.');
            valid = false;
        }
        if (!this.validateEmail(email)) {
            this.showError('email', 'Please enter a valid email address.');
            valid = false;
        }

        if (!valid) return;

        this.showLoader(true);
        try {
            await api.editUser({
                id,
                full_name: name,
                email,
                phone_number: phone,
                password,
                is_active: isActive,
                country,
                state,
                district,
                taluka
            });
            this.showToast('Customer profile updated successfully.', 'success');
            localStorage.removeItem('omni_admin_edit_user');
            this.navigateTo('/admin/users');
        } catch (error) {
            this.showToast(error.message, 'error');
            this.showError('email', error.message.includes('email') ? error.message : 'Failed to update customer profile.');
        } finally {
            this.showLoader(false);
        }
    }
    /**
     * Active state toggle for User
     */
    async toggleUserActiveState(id, currentStatus) {
        this.showLoader(true);
        try {
            const nextStatus = !currentStatus;
            await api.toggleUserStatus(id, nextStatus);
            this.showToast(`Customer account updated successfully.`, 'success');
            await this.fetchUsersList();
        } catch (error) {
            this.showToast('Failed to toggle customer status: ' + error.message, 'error');
        } finally {
            this.showLoader(false);
        }
    }
    /* -- Modals Controllers ------------------------------------------------ */
    
    openModal(modalId) {
        document.getElementById(modalId).classList.remove('hidden');
    }

    closeModal(modalId) {
        document.getElementById(modalId).classList.add('hidden');
    }

    async viewVendorDetails(id, activeTab = 'drivers', selectedDate = '', orderPage = 1, menuPage = 1) {
        this.showLoader(true);
        try {
            const res = await api.getVendorDetails(id, { date: selectedDate, orderPage, menuPage });
            const data = res.data;
            const vendor = data.vendor;
            const hotels = data.hotels || [];
            const drivers = data.drivers || [];
            const rev = data.revenue || {};
            const ordersData = data.orders || { data: [], pagination: {} };
            const menuData = data.menu || { data: [], pagination: {} };

            const title = document.getElementById('modal-title');
            const content = document.getElementById('modal-content');

            const statusBadge = vendor.is_active 
                ? '<span class="badge badge-success">Active Vendor</span>' 
                : '<span class="badge badge-danger">Deactivated</span>';

            const isOnline = vendor.is_online == 1;
            const onlineBadge = isOnline 
                ? '<span class="badge" style="background:#dcfce7; color:#15803d; border:1px solid #86efac; font-size:11px; padding:3px 8px; font-weight:700;"><i class="fa-solid fa-circle" style="font-size:7px; color:#16a34a; margin-right:4px;"></i>Online</span>' 
                : '<span class="badge" style="background:#f1f5f9; color:#64748b; border:1px solid #cbd5e1; font-size:11px; padding:3px 8px;"><i class="fa-regular fa-circle" style="font-size:7px; margin-right:4px;"></i>Offline</span>';

            title.innerHTML = `
                <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                    <i class="fa-solid fa-shop text-primary"></i>
                    <span>${this.escapeHtml(vendor.full_name)}</span>
                    ${onlineBadge}
                    ${statusBadge}
                </div>
            `;

            let tabsHtml = `
                <div class="modal-tabs">
                    <button class="modal-tab-btn ${activeTab === 'drivers' ? 'active' : ''}" onclick="app.viewVendorDetails(${id}, 'drivers', '${selectedDate}', 1, 1)">
                        <i class="fa-solid fa-motorcycle"></i> Associated Drivers (${drivers.length})
                    </button>
                    <button class="modal-tab-btn ${activeTab === 'profile' ? 'active' : ''}" onclick="app.viewVendorDetails(${id}, 'profile', '${selectedDate}', 1, 1)">
                        <i class="fa-solid fa-user"></i> Profile & Bank
                    </button>
                    <button class="modal-tab-btn ${activeTab === 'hotels' ? 'active' : ''}" onclick="app.viewVendorDetails(${id}, 'hotels', '${selectedDate}', 1, 1)">
                        <i class="fa-solid fa-hotel"></i> Hotels / Mess (${hotels.length})
                    </button>
                    <button class="modal-tab-btn ${activeTab === 'revenue' ? 'active' : ''}" onclick="app.viewVendorDetails(${id}, 'revenue', '${selectedDate}', 1, 1)">
                        <i class="fa-solid fa-chart-line"></i> Revenue Analytics
                    </button>
                    <button class="modal-tab-btn ${activeTab === 'orders' ? 'active' : ''}" onclick="app.viewVendorDetails(${id}, 'orders', '${selectedDate}', 1, 1)">
                        <i class="fa-solid fa-receipt"></i> Orders (${ordersData.pagination ? ordersData.pagination.total_records : 0})
                    </button>
                    <button class="modal-tab-btn ${activeTab === 'menu' ? 'active' : ''}" onclick="app.viewVendorDetails(${id}, 'menu', '${selectedDate}', 1, 1)">
                        <i class="fa-solid fa-utensils"></i> Today's Menu (${menuData.pagination ? menuData.pagination.total_records : 0})
                    </button>
                </div>
            `;

            // TAB: ASSOCIATED DRIVERS
            const onlineDriversCount = drivers.filter(d => d.is_online).length;
            const offlineDriversCount = drivers.length - onlineDriversCount;

            let driversTabHtml = `
                <div class="detail-tab-pane ${activeTab === 'drivers' ? 'active' : ''}">
                    <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; margin-bottom: 16px; background: var(--bg-surface); padding: 14px 18px; border-radius: var(--radius-md); border: 1px solid var(--border-color);">
                        <div style="display: flex; align-items: center; gap: 12px;">
                            <div style="width: 40px; height: 40px; border-radius: 50%; background: #e0e7ff; color: #4338ca; display: flex; align-items: center; justify-content: center; font-size: 18px;">
                                <i class="fa-solid fa-motorcycle"></i>
                            </div>
                            <div>
                                <h4 style="margin: 0; font-size: 15px; font-weight: 700;">Associated Delivery Fleet</h4>
                                <div style="font-size: 12px; color: var(--text-muted); margin-top: 2px;">
                                    Total ${drivers.length} driver${drivers.length === 1 ? '' : 's'} assigned to this vendor
                                </div>
                            </div>
                        </div>
                        <div style="display: flex; gap: 10px; align-items: center;">
                            <span class="badge" style="background:#dcfce7; color:#15803d; border:1px solid #86efac; font-size:12px; padding:4px 10px; font-weight:700;">
                                <i class="fa-solid fa-circle" style="font-size:7px; color:#16a34a; margin-right:5px;"></i>${onlineDriversCount} Online
                            </span>
                            <span class="badge" style="background:#f1f5f9; color:#64748b; border:1px solid #cbd5e1; font-size:12px; padding:4px 10px; font-weight:600;">
                                <i class="fa-regular fa-circle" style="font-size:7px; margin-right:5px;"></i>${offlineDriversCount} Offline
                            </span>
                        </div>
                    </div>

                    ${drivers.length === 0 ? `
                        <div class="text-center" style="padding: 48px 20px; color: var(--text-muted); background: var(--bg-surface); border-radius: var(--radius-md); border: 1px dashed var(--border-color);">
                            <i class="fa-solid fa-motorcycle" style="font-size: 40px; margin-bottom: 14px; display: block; opacity: 0.5;"></i>
                            <div style="font-size: 15px; font-weight: 600; color: var(--text-primary); margin-bottom: 6px;">No Associated Drivers</div>
                            <p style="font-size: 13px; max-width: 420px; margin: 0 auto;">There are currently no delivery drivers assigned to this vendor. You can assign drivers to this vendor from the Delivery Drivers Directory.</p>
                        </div>
                    ` : `
                        <div class="table-responsive">
                            <table class="table" style="font-size: 13px;">
                                <thead>
                                    <tr>
                                        <th>Driver ID</th>
                                        <th>Driver Info</th>
                                        <th>Status</th>
                                        <th>Vehicle Number</th>
                                        <th>Location / Region</th>
                                        <th class="text-center">Active Orders</th>
                                        <th>Registered Date</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${drivers.map(d => {
                                        const dIsOnline = d.is_online;
                                        const dOnlineBadge = dIsOnline 
                                            ? '<span class="badge" style="background:#dcfce7; color:#15803d; border:1px solid #86efac; font-size:11px; padding:3px 8px; font-weight:700;"><i class="fa-solid fa-circle" style="font-size:7px; color:#16a34a; margin-right:4px;"></i>Online</span>' 
                                            : '<span class="badge" style="background:#f1f5f9; color:#64748b; border:1px solid #cbd5e1; font-size:11px; padding:3px 8px;"><i class="fa-regular fa-circle" style="font-size:7px; margin-right:4px;"></i>Offline</span>';
                                        
                                        const dateRegistered = d.created_at ? new Date(d.created_at).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' }) : 'N/A';
                                        
                                        const cleanPhone = (d.phone_number || '').replace(/[^0-9]/g, '');
                                        const locationStr = [d.taluka, d.district, d.state].filter(Boolean).join(', ') || 'Not set';

                                        return `
                                            <tr style="${dIsOnline ? 'background: rgba(16, 185, 129, 0.02);' : ''}">
                                                <td><strong>#${d.id}</strong></td>
                                                <td>
                                                    <div style="display: flex; flex-direction: column;">
                                                        <span class="font-semibold" style="font-size: 13px;">${this.escapeHtml(d.full_name)}</span>
                                                        <div style="display: flex; gap: 8px; align-items: center; margin-top: 2px;">
                                                            <a href="tel:${d.phone_number}" style="font-size: 11px; color: var(--text-secondary); text-decoration: none;">
                                                                <i class="fa-solid fa-phone text-primary"></i> ${d.phone_number || 'No phone'}
                                                            </a>
                                                            ${cleanPhone ? `
                                                                <a href="https://wa.me/${cleanPhone.length === 10 ? '91' + cleanPhone : cleanPhone}" target="_blank" style="color: #25D366; font-size: 11px;" title="WhatsApp">
                                                                    <i class="fa-brands fa-whatsapp"></i>
                                                                </a>
                                                            ` : ''}
                                                        </div>
                                                        ${d.email ? `<span style="font-size: 11px; color: var(--text-muted);"><i class="fa-solid fa-envelope"></i> ${d.email}</span>` : ''}
                                                    </div>
                                                </td>
                                                <td>${dOnlineBadge}</td>
                                                <td>
                                                    <span style="font-family: monospace; font-weight: 700; background: var(--bg-surface); padding: 3px 8px; border-radius: 4px; border: 1px solid var(--border-color); font-size: 12px;">
                                                        <i class="fa-solid fa-motorcycle" style="margin-right: 4px; color: var(--text-muted);"></i>${d.vehicle_number || 'N/A'}
                                                    </span>
                                                </td>
                                                <td style="font-size: 12px; color: var(--text-secondary);">
                                                    <i class="fa-solid fa-location-dot text-primary"></i> ${locationStr}
                                                </td>
                                                <td class="text-center">
                                                    <span class="badge ${d.active_order_count > 0 ? 'badge-warning' : 'badge-secondary'}" style="font-weight: 700;">
                                                        ${d.active_order_count} active
                                                    </span>
                                                    <div style="font-size: 10px; color: var(--text-muted); margin-top: 2px;">Max: ${d.max_capacity || 3}</div>
                                                </td>
                                                <td style="font-size: 12px; color: var(--text-muted);">${dateRegistered}</td>
                                            </tr>
                                        `;
                                    }).join('')}
                                </tbody>
                            </table>
                        </div>
                    `}
                </div>
            `;

            // TAB 1: PROFILE & BANK
            let profileTabHtml = `
                <div class="detail-tab-pane ${activeTab === 'profile' ? 'active' : ''}">
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 20px;">
                        <div class="modal-detail-row">
                            <strong>Vendor ID</strong>
                            <span>#${vendor.id}</span>
                        </div>
                        <div class="modal-detail-row">
                            <strong>Account Status</strong>
                            <div>
                                ${statusBadge}
                                <button class="btn btn-secondary btn-sm" style="margin-left: 8px;" onclick="app.toggleVendorActiveState(${vendor.id}, ${vendor.is_active}).then(() => app.viewVendorDetails(${vendor.id}, 'profile'))">
                                    <i class="fa-solid ${vendor.is_active ? 'fa-user-slash' : 'fa-user-check'}"></i> ${vendor.is_active ? 'Deactivate' : 'Activate'}
                                </button>
                            </div>
                        </div>
                        <div class="modal-detail-row">
                            <strong>Full Name</strong>
                            <span>${vendor.full_name}</span>
                        </div>
                        <div class="modal-detail-row">
                            <strong>Email Address</strong>
                            <span>${vendor.email}</span>
                        </div>
                        <div class="modal-detail-row">
                            <strong>Phone Number</strong>
                            <span><i class="fa-solid fa-phone text-primary"></i> ${vendor.phone || 'Not set'}</span>
                        </div>
                        <div class="modal-detail-row">
                            <strong>Joined Date</strong>
                            <span>${new Date(vendor.created_at).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}</span>
                        </div>
                    </div>

                    <div style="background: var(--bg-surface); padding: 18px; border-radius: var(--radius-md); border: 1px solid var(--border-color); margin-bottom: 20px;">
                        <h4 style="font-size: 14px; font-weight: 700; color: var(--text-primary); margin-bottom: 14px; border-bottom: 1px solid var(--border-color); padding-bottom: 8px;">
                            <i class="fa-solid fa-location-dot text-primary"></i> Registered Location & Region
                        </h4>
                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                            <div class="modal-detail-row">
                                <strong>Country</strong>
                                <span><i class="fa-solid fa-globe text-primary"></i> ${vendor.country || 'India'}</span>
                            </div>
                            <div class="modal-detail-row">
                                <strong>State</strong>
                                <span>${vendor.state || '<em style="color: var(--text-muted)">Not set</em>'}</span>
                            </div>
                            <div class="modal-detail-row">
                                <strong>District</strong>
                                <span>${vendor.district || '<em style="color: var(--text-muted)">Not set</em>'}</span>
                            </div>
                            <div class="modal-detail-row">
                                <strong>Taluka</strong>
                                <span>${vendor.taluka || '<em style="color: var(--text-muted)">Not set</em>'}</span>
                            </div>
                            <div class="modal-detail-row">
                                <strong>Region</strong>
                                <span>${vendor.region || '<em style="color: var(--text-muted)">Not set</em>'}</span>
                            </div>
                            <div class="modal-detail-row">
                                <strong>Area / Locality</strong>
                                <span>${vendor.area || '<em style="color: var(--text-muted)">Not set</em>'}</span>
                            </div>
                        </div>
                    </div>

                    <div style="background: var(--bg-surface); padding: 18px; border-radius: var(--radius-md); border: 1px solid var(--border-color); margin-bottom: 20px;">
                        <h4 style="font-size: 14px; font-weight: 700; color: var(--text-primary); margin-bottom: 14px; border-bottom: 1px solid var(--border-color); padding-bottom: 8px;">
                            <i class="fa-solid fa-building-columns text-primary"></i> Bank Payout Account Details
                        </h4>
                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                            <div class="modal-detail-row">
                                <strong>Bank Name</strong>
                                <span>${vendor.bank_name || '<em style="color: var(--text-muted)">Not provided</em>'}</span>
                            </div>
                            <div class="modal-detail-row">
                                <strong>Account Holder Name</strong>
                                <span>${vendor.account_holder_name || '<em style="color: var(--text-muted)">Not provided</em>'}</span>
                            </div>
                            <div class="modal-detail-row">
                                <strong>Account Number</strong>
                                <span style="font-family: monospace; font-size: 13px;">${vendor.account_number || '<em style="color: var(--text-muted)">Not provided</em>'}</span>
                            </div>
                            <div class="modal-detail-row">
                                <strong>IFSC Code</strong>
                                <span style="font-weight: 700; color: var(--accent-primary);">${vendor.ifsc_code || '<em style="color: var(--text-muted)">Not provided</em>'}</span>
                            </div>
                        </div>
                    </div>

                    <div style="background: var(--bg-surface); padding: 18px; border-radius: var(--radius-md); border: 1px solid var(--border-color);">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; border-bottom: 1px solid var(--border-color); padding-bottom: 8px;">
                            <h4 style="font-size: 14px; font-weight: 700; color: var(--text-primary); margin: 0;">
                                <i class="fa-solid fa-motorcycle text-primary"></i> Associated Delivery Drivers (${drivers.length})
                            </h4>
                            <button class="btn btn-secondary btn-sm" onclick="app.viewVendorDetails(${id}, 'drivers', '${selectedDate}', 1, 1)">
                                View Full Fleet (${drivers.length})
                            </button>
                        </div>
                        ${drivers.length === 0 ? '<p style="font-size: 13px; color: var(--text-muted); margin: 0;">No drivers currently linked to this vendor.</p>' : `
                            <div style="display: flex; flex-wrap: wrap; gap: 8px;">
                                ${drivers.map(d => `
                                    <span style="display: inline-flex; align-items: center; gap: 6px; background: var(--bg-card); border: 1px solid var(--border-color); padding: 5px 10px; border-radius: 20px; font-size: 12px; font-weight: 600;">
                                        <i class="fa-solid fa-circle" style="font-size: 7px; color: ${d.is_online ? '#16a34a' : '#94a3b8'};"></i>
                                        ${this.escapeHtml(d.full_name)} (${d.vehicle_number || 'No Vehicle'})
                                    </span>
                                `).join('')}
                            </div>
                        `}
                    </div>
                </div>
            `;

            // TAB 2: HOTELS / MESS
            let hotelsTabHtml = `
                <div class="detail-tab-pane ${activeTab === 'hotels' ? 'active' : ''}">
                    ${hotels.length === 0 ? `
                        <div class="text-center" style="padding: 40px; color: var(--text-muted);">
                            <i class="fa-solid fa-hotel" style="font-size: 32px; margin-bottom: 12px; display: block;"></i>
                            No hotels or mess registered under this vendor.
                        </div>
                    ` : `
                        <div class="hotel-grid">
                            ${hotels.map(h => {
                                const docs = [
                                    { label: 'PAN', num: h.pan_number, photo: h.pan_photo_url },
                                    { label: 'Aadhaar', num: h.aadhar_number, photo: h.aadhar_photo_url },
                                    { label: 'FSSAI', num: h.fssai_number, photo: h.fssai_photo_url },
                                    { label: 'Shop Act', num: h.shop_act_number, photo: h.shop_act_photo_url },
                                    { label: 'Udyam', num: h.udyam_aadhar_number, photo: h.udyam_aadhar_photo_url }
                                ];
                                return `
                                    <div class="hotel-card">
                                        <div class="hotel-card-header">
                                            <div>
                                                <div class="hotel-name"><i class="fa-solid fa-utensils text-primary"></i> ${h.hotel_name}</div>
                                                <div class="hotel-owner"><i class="fa-solid fa-user-gear"></i> ${h.owner_name || 'Owner N/A'}</div>
                                            </div>
                                            <span class="badge ${h.is_active ? 'badge-success' : 'badge-danger'}">${h.is_active ? 'Active' : 'Inactive'}</span>
                                        </div>
                                        <div style="font-size: 12px; color: var(--text-secondary); margin-bottom: 8px;">
                                            <div><i class="fa-solid fa-location-dot text-primary"></i> ${h.hotel_address}</div>
                                            <div style="margin-top: 4px;"><i class="fa-solid fa-phone"></i> ${h.mobile_number || 'N/A'} | <i class="fa-solid fa-envelope"></i> ${h.email || 'N/A'}</div>
                                        </div>
                                        <div style="border-top: 1px dashed var(--border-color); padding-top: 8px;">
                                            <div style="font-size: 11px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; margin-bottom: 6px;">Legal Verification Documents</div>
                                            <div class="doc-pills">
                                                ${docs.map(d => {
                                                    if (d.photo) {
                                                        return `<a href="${d.photo}" target="_blank" class="doc-pill verified"><i class="fa-solid fa-file-check"></i> ${d.label}: ${d.num || 'View'}</a>`;
                                                    } else if (d.num) {
                                                        return `<span class="doc-pill verified"><i class="fa-solid fa-check"></i> ${d.label}: ${d.num}</span>`;
                                                    } else {
                                                        return `<span class="doc-pill missing"><i class="fa-solid fa-xmark"></i> ${d.label}</span>`;
                                                    }
                                                }).join('')}
                                            </div>
                                        </div>
                                    </div>
                                `;
                            }).join('')}
                        </div>
                    `}
                </div>
            `;

            // TAB 3: REVENUE
            let revenueTabHtml = `
                <div class="detail-tab-pane ${activeTab === 'revenue' ? 'active' : ''}">
                    <div class="rev-grid">
                        <div class="rev-card daily">
                            <div class="rev-icon"><i class="fa-solid fa-calendar-day"></i></div>
                            <div class="rev-info">
                                <span class="rev-label">Today's Revenue</span>
                                <span class="rev-value">₹${rev.daily || '0.00'}</span>
                            </div>
                        </div>
                        <div class="rev-card weekly">
                            <div class="rev-icon"><i class="fa-solid fa-calendar-week"></i></div>
                            <div class="rev-info">
                                <span class="rev-label">Weekly Revenue</span>
                                <span class="rev-value">₹${rev.weekly || '0.00'}</span>
                            </div>
                        </div>
                        <div class="rev-card lifetime">
                            <div class="rev-icon"><i class="fa-solid fa-vault"></i></div>
                            <div class="rev-info">
                                <span class="rev-label">Total Lifetime Revenue</span>
                                <span class="rev-value">₹${rev.lifetime || '0.00'}</span>
                            </div>
                        </div>
                    </div>

                    <div style="background: var(--bg-secondary); border: 1px solid var(--border-color); border-radius: var(--radius-md); padding: 18px;">
                        <h4 style="font-size: 14px; font-weight: 700; margin-bottom: 12px;"><i class="fa-solid fa-shop text-primary"></i> Hotel-wise Outlets Summary</h4>
                        ${hotels.length === 0 ? '<p style="font-size: 13px; color: var(--text-muted);">No hotels registered.</p>' : `
                            <div class="table-responsive">
                                <table class="table" style="font-size: 13px;">
                                    <thead>
                                        <tr>
                                            <th>Hotel Name</th>
                                            <th>Address</th>
                                            <th>Status</th>
                                            <th class="text-right">Outlets</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        ${hotels.map(h => `
                                            <tr>
                                                <td><strong>${h.hotel_name}</strong></td>
                                                <td>${h.hotel_address}</td>
                                                <td><span class="badge ${h.is_active ? 'badge-success' : 'badge-danger'}">${h.is_active ? 'Active' : 'Inactive'}</span></td>
                                                <td class="text-right font-semibold">1 Outlet</td>
                                            </tr>
                                        `).join('')}
                                    </tbody>
                                </table>
                            </div>
                        `}
                    </div>
                </div>
            `;

            // TAB 4: ORDERS (DATE FILTERED)
            const ordersList = ordersData.data || [];
            const now = new Date();
            const todayStr = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0') + '-' + String(now.getDate()).padStart(2, '0');
            let ordersTabHtml = `
                <div class="detail-tab-pane ${activeTab === 'orders' ? 'active' : ''}">
                    <div style="display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; margin-bottom: 16px; background: var(--bg-surface); padding: 12px 16px; border-radius: var(--radius-md); border: 1px solid var(--border-color);">
                        <div style="display: flex; align-items: center; gap: 10px;">
                            <i class="fa-solid fa-filter text-primary"></i>
                            <span style="font-size: 13px; font-weight: 600;">Filter Orders by Date:</span>
                            <input type="date" id="vendor-details-date-picker" class="form-control" style="padding: 6px 12px; font-size: 13px; width: auto;" value="${selectedDate}">
                        </div>
                        <div style="display: flex; gap: 8px;">
                            <button class="btn btn-secondary btn-sm" onclick="app.viewVendorDetails(${id}, 'orders', '${todayStr}', 1, 1)">Today's Orders</button>
                            <button class="btn btn-secondary btn-sm" onclick="app.viewVendorDetails(${id}, 'orders', '', 1, 1)">All Orders</button>
                        </div>
                    </div>

                    ${ordersList.length === 0 ? `
                        <div class="text-center" style="padding: 40px; color: var(--text-muted);">
                            <i class="fa-solid fa-inbox" style="font-size: 32px; margin-bottom: 12px; display: block;"></i>
                            No orders found for the selected date criteria.
                        </div>
                    ` : `
                        <div class="table-responsive">
                            <table class="table" style="font-size: 13px;">
                                <thead>
                                    <tr>
                                        <th>Order ID</th>
                                        <th>Customer Info</th>
                                        <th>Hotel</th>
                                        <th>Items Ordered</th>
                                        <th class="text-right">Grand Total</th>
                                        <th>Payment Method</th>
                                        <th>Status</th>
                                        <th>Date & Time</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${ordersList.map(o => {
                                        let sClass = 'badge-secondary';
                                        if (o.status === 'delivered') sClass = 'badge-success';
                                        else if (o.status === 'cancelled') sClass = 'badge-danger';
                                        else if (o.status === 'accepted' || o.status === 'cooking') sClass = 'badge-warning';

                                        const itemsText = (o.items || []).map(i => `<span class="order-item-tag">${i.food_name} x${i.quantity}</span>`).join(' ') || 'Items';
                                        const dateStr = this.formatOrderDateTime(o.created_at);

                                        return `
                                            <tr>
                                                <td><strong>#${o.order_id}</strong></td>
                                                <td>
                                                    <div style="display:flex; flex-direction:column;">
                                                        <span class="font-semibold">${o.customer_name}</span>
                                                        <span style="font-size: 11px; color: var(--text-muted);">${o.customer_phone || 'No phone'}</span>
                                                    </div>
                                                </td>
                                                <td>${o.hotel_name}</td>
                                                <td>${itemsText}</td>
                                                <td class="text-right font-semibold">₹${o.grand_total}</td>
                                                <td><span class="badge" style="background:var(--bg-surface);">${o.payment_method || 'ONLINE'}</span></td>
                                                <td><span class="badge ${sClass}">${o.status.toUpperCase()}</span></td>
                                                <td style="font-size:12px;">${dateStr}</td>
                                            </tr>
                                        `;
                                    }).join('')}
                                </tbody>
                            </table>
                        </div>
                        <div id="vendor-details-orders-pagination" class="pagination-wrapper" style="margin-top: 16px;"></div>
                    `}
                </div>
            `;

            // TAB 5: TODAY'S MENU CATALOG
            const menuList = menuData.data || [];
            let menuTabHtml = `
                <div class="detail-tab-pane ${activeTab === 'menu' ? 'active' : ''}">
                    ${menuList.length === 0 ? `
                        <div class="text-center" style="padding: 40px; color: var(--text-muted);">
                            <i class="fa-solid fa-utensils" style="font-size: 32px; margin-bottom: 12px; display: block;"></i>
                            No menu items found for this vendor's hotels.
                        </div>
                    ` : `
                        <div class="table-responsive">
                            <table class="table" style="font-size: 13px;">
                                <thead>
                                    <tr>
                                        <th>Item ID</th>
                                        <th>Food Item Name</th>
                                        <th>Hotel Name</th>
                                        <th>Category</th>
                                        <th>Type</th>
                                        <th class="text-right">Price</th>
                                        <th>Availability</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${menuList.map(m => {
                                        const typeBadge = m.meal_type === 'NON-VEG' 
                                            ? '<span class="badge badge-danger">NON-VEG</span>'
                                            : '<span class="badge badge-success">VEG</span>';
                                        const availBadge = m.is_available 
                                            ? '<span class="badge badge-success"><i class="fa-solid fa-check"></i> Available</span>'
                                            : '<span class="badge badge-secondary">Out of Stock</span>';
                                        const formattedPrice = (parseFloat(m.price) || 0).toFixed(2);
                                        return `
                                            <tr>
                                                <td><strong>#${m.id}</strong></td>
                                                <td>
                                                    <div style="display:flex; flex-direction:column;">
                                                        <span class="font-semibold">${m.food_name}</span>
                                                        <span style="font-size:11px; color:var(--text-muted);">${m.description || ''}</span>
                                                    </div>
                                                </td>
                                                <td>${m.hotel_name}</td>
                                                <td><span class="badge" style="background:var(--bg-surface);">${m.category_name}</span></td>
                                                <td>${typeBadge}</td>
                                                <td class="text-right font-semibold">₹${formattedPrice}</td>
                                                <td>${availBadge}</td>
                                            </tr>
                                        `;
                                    }).join('')}
                                </tbody>
                            </table>
                        </div>
                        <div id="vendor-details-menu-pagination" class="pagination-wrapper" style="margin-top: 16px;"></div>
                    `}
                </div>
            `;

            content.innerHTML = `
                ${tabsHtml}
                ${driversTabHtml}
                ${profileTabHtml}
                ${hotelsTabHtml}
                ${revenueTabHtml}
                ${ordersTabHtml}
                ${menuTabHtml}
            `;

            if (activeTab === 'orders' && ordersData.pagination) {
                this.renderPagination('vendor-details-orders-pagination', ordersData.pagination, (newPage) => {
                    this.viewVendorDetails(id, 'orders', selectedDate, newPage, menuPage);
                });
                const picker = document.getElementById('vendor-details-date-picker');
                if (picker) {
                    picker.addEventListener('change', (e) => {
                        this.viewVendorDetails(id, 'orders', e.target.value, 1, menuPage);
                    });
                }
            }

            if (activeTab === 'menu' && menuData.pagination) {
                this.renderPagination('vendor-details-menu-pagination', menuData.pagination, (newPage) => {
                    this.viewVendorDetails(id, 'menu', selectedDate, orderPage, newPage);
                });
            }

            this.openModal('details-modal');

        } catch (e) {
            this.showToast('Failed to load vendor details: ' + e.message, 'error');
        } finally {
            this.showLoader(false);
        }
    }
    async viewUserDetails(id, activeTab = 'profile', orderPage = 1) {
        this.showLoader(true);
        try {
            const res = await api.getUserDetails(id, { orderPage });
            const data = res.data;
            const customer = data.customer;
            const summary = data.summary || {};
            const ordersData = data.orders || { data: [], pagination: {} };
            const subscriptions = data.subscriptions || [];

            const title = document.getElementById('modal-title');
            const content = document.getElementById('modal-content');

            const statusBadge = customer.is_active 
                ? '<span class="badge badge-success">Active Customer</span>' 
                : '<span class="badge badge-danger">Deactivated</span>';
            title.innerHTML = `
                <div style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
                    <div class="avatar-fallback" style="width: 32px; height: 32px; font-size: 13px; background: linear-gradient(135deg, var(--accent-primary), var(--accent-warning)); color: white;">
                        ${customer.full_name.charAt(0).toUpperCase()}
                    </div>
                    <span>${customer.full_name}</span>
                    ${statusBadge}
                </div>
            `;

            let tabsHtml = `
                <div class="modal-tabs">
                    <button class="modal-tab-btn ${activeTab === 'profile' ? 'active' : ''}" onclick="app.viewUserDetails(${id}, 'profile', 1)">
                        <i class="fa-solid fa-user"></i> Profile & Wallet
                    </button>
                    <button class="modal-tab-btn ${activeTab === 'orders' ? 'active' : ''}" onclick="app.viewUserDetails(${id}, 'orders', 1)">
                        <i class="fa-solid fa-bag-shopping"></i> Order History (${ordersData.pagination ? ordersData.pagination.total_records : 0})
                    </button>
                    <button class="modal-tab-btn ${activeTab === 'subscriptions' ? 'active' : ''}" onclick="app.viewUserDetails(${id}, 'subscriptions', 1)">
                        <i class="fa-solid fa-calendar-check"></i> Subscriptions (${subscriptions.length})
                    </button>
                </div>
            `;

            // TAB 1: PROFILE & WALLET
            let profileTabHtml = `
                <div class="detail-tab-pane ${activeTab === 'profile' ? 'active' : ''}">
                    <div class="rev-grid" style="margin-bottom: 20px;">
                        <div class="rev-card lifetime">
                            <div class="rev-icon"><i class="fa-solid fa-wallet"></i></div>
                            <div class="rev-info">
                                <span class="rev-label">Wallet Balance</span>
                                <span class="rev-value">₹${customer.wallet_balance}</span>
                            </div>
                        </div>
                        <div class="rev-card daily">
                            <div class="rev-icon"><i class="fa-solid fa-cart-shopping"></i></div>
                            <div class="rev-info">
                                <span class="rev-label">Total Orders Placed</span>
                                <span class="rev-value">${summary.total_orders || 0}</span>
                            </div>
                        </div>
                        <div class="rev-card weekly">
                            <div class="rev-icon"><i class="fa-solid fa-indian-rupee-sign"></i></div>
                            <div class="rev-info">
                                <span class="rev-label">Total Money Spent</span>
                                <span class="rev-value">₹${summary.total_spent || '0.00'}</span>
                            </div>
                        </div>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
                        <div class="modal-detail-row">
                            <strong>Customer ID</strong>
                            <span>#${customer.id}</span>
                        </div>
                        <div class="modal-detail-row">
                            <strong>Account Status</strong>
                            <div>
                                ${statusBadge}
                                <button class="btn btn-secondary btn-sm" style="margin-left: 8px;" onclick="app.toggleUserActiveState(${customer.id}, ${customer.is_active}).then(() => app.viewUserDetails(${customer.id}, 'profile'))">
                                    <i class="fa-solid ${customer.is_active ? 'fa-user-slash' : 'fa-user-check'}"></i> ${customer.is_active ? 'Deactivate' : 'Activate'}
                                </button>
                            </div>
                        </div>
                        <div class="modal-detail-row">
                            <strong>Full Name</strong>
                            <span>${customer.full_name}</span>
                        </div>
                        <div class="modal-detail-row">
                            <strong>Email Address</strong>
                            <span>${customer.email} ${customer.email_verified ? '<i class="fa-solid fa-circle-check text-success" title="Verified"></i>' : ''}</span>
                        </div>
                        <div class="modal-detail-row">
                            <strong>Phone Number</strong>
                            <span><i class="fa-solid fa-phone text-primary"></i> ${customer.phone_number || customer.phone || 'Not set'}</span>
                        </div>
                        <div class="modal-detail-row">
                            <strong>Member Since</strong>
                            <span>${new Date(customer.created_at).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}</span>
                        </div>
                        <div class="modal-detail-row" style="grid-column: span 2; background: rgba(0,0,0,0.02); padding: 12px; border-radius: 12px; border: 1px dashed var(--border-color, #cbd5e1); margin-top: 8px;">
                            <strong style="display: flex; align-items: center; gap: 6px; color: var(--text-color, #1e293b);">
                                <i class="fa-solid fa-key text-warning"></i> Original Password
                            </strong>
                            <div style="display: flex; align-items: center; gap: 8px; font-family: monospace; background: var(--bg-card, #ffffff); padding: 8px 12px; border-radius: 8px; margin-top: 6px; border: 1px solid var(--border-color, #cbd5e1); width: 100%;">
                                <span id="user-pwd-val-${customer.id}" style="letter-spacing: 1px; font-size: 12px; word-break: break-all; color: var(--text-color, #0f172a); flex: 1;">
                                    ${customer.password ? '••••••••••••••••' : 'No password set'}
                                </span>
                                ${customer.password ? `
                                    <button type="button" class="btn btn-secondary btn-sm" title="Show/Hide Password" onclick="app.togglePasswordVisibility('user-pwd-val-${customer.id}', '${(customer.password || '').replace(/'/g, "\\'")}'); event.stopPropagation();">
                                        <i id="user-pwd-icon-user-pwd-val-${customer.id}" class="fa-solid fa-eye"></i> Show
                                    </button>
                                    <button type="button" class="btn btn-secondary btn-sm" title="Copy Password" onclick="navigator.clipboard.writeText('${(customer.password || '').replace(/'/g, "\\'")}'); app.showToast('Password copied to clipboard!', 'success'); event.stopPropagation();">
                                        <i class="fa-solid fa-copy"></i> Copy
                                    </button>
                                ` : ''}
                            </div>
                        </div>
                    </div>
                </div>
            `;

            // TAB 2: ORDER HISTORY
            const ordersList = ordersData.data || [];
            let ordersTabHtml = `
                <div class="detail-tab-pane ${activeTab === 'orders' ? 'active' : ''}">
                    ${ordersList.length === 0 ? `
                        <div class="text-center" style="padding: 40px; color: var(--text-muted);">
                            <i class="fa-solid fa-bag-shopping" style="font-size: 32px; margin-bottom: 12px; display: block;"></i>
                            This customer has not placed any food orders yet.
                        </div>
                    ` : `
                        <div class="table-responsive">
                            <table class="table" style="font-size: 13px;">
                                <thead>
                                    <tr>
                                        <th>Order ID</th>
                                        <th>Hotel Name</th>
                                        <th>Items Ordered</th>
                                        <th class="text-right">Grand Total</th>
                                        <th class="text-right">Wallet Used</th>
                                        <th>Status</th>
                                        <th>Date & Time</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${ordersList.map(o => {
                                        let sClass = 'badge-secondary';
                                        if (o.status === 'delivered') sClass = 'badge-success';
                                        else if (o.status === 'cancelled') sClass = 'badge-danger';
                                        else if (o.status === 'accepted' || o.status === 'cooking') sClass = 'badge-warning';

                                        const itemsText = (o.items || []).map(i => `<span class="order-item-tag">${i.food_name} x${i.quantity}</span>`).join(' ') || 'Items';
                                        const dateStr = this.formatOrderDateTime(o.created_at);

                                        return `
                                            <tr>
                                                <td><strong>#${o.order_id}</strong></td>
                                                <td>${o.hotel_name}</td>
                                                <td>${itemsText}</td>
                                                <td class="text-right font-semibold">₹${o.grand_total}</td>
                                                <td class="text-right text-success font-semibold">₹${o.wallet_deducted}</td>
                                                <td><span class="badge ${sClass}">${o.status.toUpperCase()}</span></td>
                                                <td style="font-size:12px;">${dateStr}</td>
                                            </tr>
                                        `;
                                    }).join('')}
                                </tbody>
                            </table>
                        </div>
                        <div id="user-details-orders-pagination" class="pagination-wrapper" style="margin-top: 16px;"></div>
                    `}
                </div>
            `;

            // TAB 3: SUBSCRIPTIONS
            let subscriptionsTabHtml = `
                <div class="detail-tab-pane ${activeTab === 'subscriptions' ? 'active' : ''}">
                    ${subscriptions.length === 0 ? `
                        <div class="text-center" style="padding: 40px; color: var(--text-muted);">
                            <i class="fa-solid fa-calendar-xmark" style="font-size: 32px; margin-bottom: 12px; display: block;"></i>
                            No active or past meal subscription plans found for this customer.
                        </div>
                    ` : `
                        <div class="table-responsive">
                            <table class="table" style="font-size: 13px;">
                                <thead>
                                    <tr>
                                        <th>Sub ID</th>
                                        <th>Plan Name</th>
                                        <th>Meal Type</th>
                                        <th>Deliveries</th>
                                        <th>Timeline</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${subscriptions.map(s => {
                                        let sClass = 'badge-secondary';
                                        if (s.status === 'ACTIVE') sClass = 'badge-success';
                                        else if (s.status === 'PAUSED') sClass = 'badge-warning';
                                        else if (s.status === 'EXPIRED' || s.status === 'CANCELLED') sClass = 'badge-danger';
                                        
                                        const startStr = new Date(s.start_date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
                                        const endStr = new Date(s.end_date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });

                                        return `
                                            <tr>
                                                <td><strong>#${s.id}</strong></td>
                                                <td><strong>${s.plan_name || 'Meal Plan'}</strong></td>
                                                <td><span class="badge" style="background:var(--bg-surface);">${s.meal_type || 'VEG'}</span></td>
                                                <td>${s.completed_deliveries} / ${s.total_deliveries} completed</td>
                                                <td style="font-size:12px;">${startStr} to ${endStr}</td>
                                                <td><span class="badge ${sClass}">${s.status}</span></td>
                                            </tr>
                                        `;
                                    }).join('')}
                                </tbody>
                            </table>
                        </div>
                    `}
                </div>
            `;

            content.innerHTML = `
                ${tabsHtml}
                ${profileTabHtml}
                ${ordersTabHtml}
                ${subscriptionsTabHtml}
            `;

            if (activeTab === 'orders' && ordersData.pagination) {
                this.renderPagination('user-details-orders-pagination', ordersData.pagination, (newPage) => {
                    this.viewUserDetails(id, 'orders', newPage);
                });
            }

            this.openModal('details-modal');

        } catch (e) {
            this.showToast('Failed to load customer profile: ' + e.message, 'error');
        } finally {
            this.showLoader(false);
        }
    }
/**
     * Toggle Customer Hotels & Location Dropdown in Customers Table
     */
    async toggleCustomerHotelsDropdown(customerId, btnEl, event) {
        if (event) event.stopPropagation();

        const dropdownRow = document.getElementById(`customer-hotels-dropdown-row-${customerId}`);
        const toggleBtn = btnEl || document.getElementById(`view-hotels-btn-${customerId}`);
        if (!dropdownRow) return;

        const isOpen = dropdownRow.style.display !== 'none';

        // Close any other open customer hotels dropdowns to keep UI clean
        document.querySelectorAll('.customer-hotels-dropdown-row').forEach(row => {
            if (row.id !== `customer-hotels-dropdown-row-${customerId}`) {
                row.style.display = 'none';
            }
        });
        document.querySelectorAll('.btn-customer-hotels-toggle').forEach(btn => {
            if (btn.id !== `view-hotels-btn-${customerId}`) {
                btn.classList.remove('active');
            }
        });

        if (isOpen) {
            dropdownRow.style.display = 'none';
            if (toggleBtn) toggleBtn.classList.remove('active');
            return;
        }

        dropdownRow.style.display = 'table-row';
        if (toggleBtn) toggleBtn.classList.add('active');

        // Initialize state for this customer
        if (!this.customerHotelsState) {
            this.customerHotelsState = {};
        }
        if (!this.customerHotelsState[customerId]) {
            this.customerHotelsState[customerId] = {
                activeAddressIndex: 0,
                foodFilter: 'ALL',
                addresses: null
            };
        }

        await this.loadCustomerHotelsData(customerId);
    }

    /**
     * Close specific customer hotel dropdown
     */
    closeCustomerHotelsDropdown(customerId) {
        const dropdownRow = document.getElementById(`customer-hotels-dropdown-row-${customerId}`);
        const toggleBtn = document.getElementById(`view-hotels-btn-${customerId}`);
        if (dropdownRow) dropdownRow.style.display = 'none';
        if (toggleBtn) toggleBtn.classList.remove('active');
    }

    /**
     * Fetch addresses and nearby hotels for the customer and render the dropdown
     */
    async loadCustomerHotelsData(customerId, addressIndex = null, foodFilter = null) {
        const wrapper = document.getElementById(`customer-hotels-dropdown-${customerId}`);
        if (!wrapper) return;

        if (!this.customerHotelsState) {
            this.customerHotelsState = {};
        }
        const state = this.customerHotelsState[customerId] || {
            activeAddressIndex: 0,
            foodFilter: 'ALL'
        };

        if (addressIndex !== null) state.activeAddressIndex = parseInt(addressIndex, 10);
        if (foodFilter !== null) state.foodFilter = foodFilter;
        this.customerHotelsState[customerId] = state;

        // Find customer in cached users or fallback
        const customer = (this.users && this.users.find(u => u.id === customerId)) || { id: customerId, full_name: 'Customer #' + customerId };

        // Show loading state
        wrapper.innerHTML = `
            <div class="customer-hotels-card" style="padding: 24px; text-align: center; background: #ffffff; border: 1.5px solid #fed7aa; border-radius: 12px; margin: 10px 14px 16px 14px; box-shadow: 0 4px 16px rgba(234, 88, 12, 0.08);">
                <div class="spinner" style="margin: 0 auto; width: 32px; height: 32px; border-color: #fdba74; border-top-color: #ea580c;"></div>
                <div style="margin-top: 12px; font-weight: 600; font-size: 13.5px; color: #9a3412;">
                    <i class="fa-solid fa-location-dot" style="color: #ea580c; margin-right: 4px;"></i>
                    Retrieving customer chosen location & searching nearest hotels...
                </div>
                <div style="font-size: 12px; color: var(--text-muted); margin-top: 4px;">
                    Using GPS coordinates and Haversine distance calculation
                </div>
            </div>
        `;

        try {
            // 1. Fetch addresses if not already cached
            let addresses = state.addresses;
            if (!addresses) {
                const addrRes = await api.getCustomerAddresses(customerId);
                addresses = (addrRes && addrRes.success && addrRes.data && Array.isArray(addrRes.data.addresses)) ? addrRes.data.addresses : [];
                state.addresses = addresses;
            }

            // Pick active address
            let activeAddress = null;
            if (addresses.length > 0) {
                if (state.activeAddressIndex < 0 || state.activeAddressIndex >= addresses.length) {
                    state.activeAddressIndex = 0;
                }
                activeAddress = addresses[state.activeAddressIndex];
            } else {
                // Synthesize from customer profile
                activeAddress = {
                    id: 0,
                    customer_id: customerId,
                    full_address: [customer.taluka, customer.district, customer.state, customer.country || 'India'].filter(Boolean).join(', ') || 'No Saved Address',
                    area: customer.taluka || '',
                    city: customer.district || '',
                    state: customer.state || '',
                    country: customer.country || 'India',
                    pincode: '',
                    latitude: 0,
                    longitude: 0,
                    is_default: true,
                    address_type: 'Profile Location',
                    tag: 'PROFILE'
                };
            }

            // Coordinates resolution
            let lat = parseFloat(activeAddress.latitude) || 0;
            let lng = parseFloat(activeAddress.longitude) || 0;

            // If coordinates are 0, try to geocode if address string is available
            if ((lat === 0 || lng === 0) && activeAddress.full_address && activeAddress.full_address !== 'No Saved Address') {
                try {
                    const geoRes = await api.geocodeAddress(activeAddress.full_address);
                    if (geoRes && geoRes.success && geoRes.data && geoRes.data.latitude && geoRes.data.longitude) {
                        lat = parseFloat(geoRes.data.latitude);
                        lng = parseFloat(geoRes.data.longitude);
                        activeAddress.latitude = lat;
                        activeAddress.longitude = lng;
                        activeAddress.geocoded = true;
                    }
                } catch (geoErr) {
                    // Geocoding error fallback
                }
            }

            // Fallback coordinates (Pune default) if still 0
            const usingFallbackCoords = (lat === 0 || lng === 0);
            if (usingFallbackCoords) {
                lat = 18.5204;
                lng = 73.8567;
            }

            // 2. Fetch nearby hotels using the existing API:
            // GET /api/hotels/nearby?latitude=...&longitude=...&food_type=...
            const hotelRes = await api.getNearbyHotels(lat, lng, state.foodFilter);
            const hotels = (hotelRes && hotelRes.success && hotelRes.data && Array.isArray(hotelRes.data.hotels)) ? hotelRes.data.hotels : [];

            // 3. Render the Dropdown View
            this.renderCustomerHotelsDropdown(customerId, customer, addresses, activeAddress, hotels, state.foodFilter, usingFallbackCoords, lat, lng);

        } catch (err) {
            wrapper.innerHTML = `
                <div class="customer-hotels-card" style="padding: 20px; background: #fff5f5; border: 1.5px solid #fecaca; border-radius: 12px; margin: 10px 14px 16px 14px;">
                    <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px;">
                        <span style="font-weight: 700; color: #dc2626;"><i class="fa-solid fa-triangle-exclamation"></i> Error Loading Data</span>
                        <button class="btn btn-secondary btn-sm" onclick="app.closeCustomerHotelsDropdown(${customerId})"><i class="fa-solid fa-xmark"></i></button>
                    </div>
                    <p style="color: #991b1b; font-size: 13px; margin: 0 0 12px 0;">${this.escapeHtml(err.message || 'Failed to load hotels and location.')}</p>
                    <button class="btn btn-secondary btn-sm" onclick="app.loadCustomerHotelsData(${customerId})">
                        <i class="fa-solid fa-arrows-rotate"></i> Retry
                    </button>
                </div>
            `;
        }
    }

    /**
     * Render Customer Hotels Dropdown Card
     */
    renderCustomerHotelsDropdown(customerId, customer, addresses, activeAddress, hotels, foodFilter, usingFallbackCoords, effectiveLat, effectiveLng) {
        const wrapper = document.getElementById(`customer-hotels-dropdown-${customerId}`);
        if (!wrapper) return;

        // Build addresses options if customer has multiple saved addresses
        let addressSelectorHtml = '';
        if (addresses.length > 1) {
            addressSelectorHtml = `
                <div style="margin-bottom: 12px;">
                    <label style="font-size: 12px; font-weight: 700; color: #475569; display: block; margin-bottom: 4px;">
                        <i class="fa-solid fa-list-check" style="color: #ea580c; margin-right: 4px;"></i> Select Customer's Saved Location (${addresses.length} available):
                    </label>
                    <select class="form-control" onchange="app.onCustomerHotelsAddressSelect(${customerId}, this.value)" style="width: 100%; padding: 7px 10px; font-size: 12.5px; border-radius: 8px; border: 1.5px solid #fed7aa; background: #ffffff; color: #1e293b; font-weight: 600;">
                        ${addresses.map((addr, idx) => `
                            <option value="${idx}" ${idx === this.customerHotelsState[customerId].activeAddressIndex ? 'selected' : ''}>
                                [${this.escapeHtml(addr.tag || addr.address_type || 'Saved Address')}] ${this.escapeHtml(addr.full_address || addr.area || 'Address')} ${addr.pincode ? `(${addr.pincode})` : ''} ${addr.is_default ? '★ (Default)' : ''}
                            </option>
                        `).join('')}
                    </select>
                </div>
            `;
        }

        // Active address details
        const addrTag = activeAddress.tag || activeAddress.address_type || 'SAVED ADDRESS';
        const isDefault = !!activeAddress.is_default;
        const addrText = activeAddress.full_address || [activeAddress.area, activeAddress.city, activeAddress.state, activeAddress.country].filter(Boolean).join(', ') || 'No saved address specified';
        const coordsText = (effectiveLat && effectiveLng) ? `${Number(effectiveLat).toFixed(5)}, ${Number(effectiveLng).toFixed(5)}` : 'N/A';
        const mapUrl = `https://www.google.com/maps/search/?api=1&query=${effectiveLat},${effectiveLng}`;

        // Food filter pills
        const filterPillsHtml = `
            <div style="display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">
                <button type="button" class="btn btn-sm ${foodFilter === 'ALL' ? 'btn-primary' : 'btn-secondary'}" onclick="app.onCustomerHotelsFoodFilter(${customerId}, 'ALL')" style="font-size: 11px; padding: 3px 9px; border-radius: 14px; font-weight: 700;">
                    All Food Types
                </button>
                <button type="button" class="btn btn-sm ${foodFilter === 'VEG' ? 'btn-success' : 'btn-secondary'}" onclick="app.onCustomerHotelsFoodFilter(${customerId}, 'VEG')" style="font-size: 11px; padding: 3px 9px; border-radius: 14px; font-weight: 700; ${foodFilter === 'VEG' ? 'background:#16a34a; border-color:#16a34a; color:white;' : ''}">
                    <i class="fa-solid fa-leaf" style="color: ${foodFilter === 'VEG' ? '#ffffff' : '#22c55e'}; margin-right: 3px;"></i> Veg Only
                </button>
                <button type="button" class="btn btn-sm ${foodFilter === 'NON-VEG' ? 'btn-danger' : 'btn-secondary'}" onclick="app.onCustomerHotelsFoodFilter(${customerId}, 'NON-VEG')" style="font-size: 11px; padding: 3px 9px; border-radius: 14px; font-weight: 700; ${foodFilter === 'NON-VEG' ? 'background:#dc2626; border-color:#dc2626; color:white;' : ''}">
                    <i class="fa-solid fa-drumstick-bite" style="color: ${foodFilter === 'NON-VEG' ? '#ffffff' : '#ef4444'}; margin-right: 3px;"></i> Non-Veg Only
                </button>
            </div>
        `;

        // Hotel cards or empty state
        let hotelsContentHtml = '';
        if (hotels.length === 0) {
            hotelsContentHtml = `
                <div style="grid-column: 1 / -1; text-align: center; padding: 36px 16px; background: #fafafa; border: 1.5px dashed #e2e8f0; border-radius: 10px;">
                    <i class="fa-solid fa-utensils" style="font-size: 32px; color: #cbd5e1; margin-bottom: 10px; display: block;"></i>
                    <h4 style="margin: 0 0 4px 0; color: #475569; font-size: 14px;">No Hotels or Messes Found Nearby</h4>
                    <p style="margin: 0; font-size: 12px; color: #94a3b8;">
                        No vendors registered within service radius for this customer location (${coordsText}).
                    </p>
                </div>
            `;
        } else {
            hotelsContentHtml = hotels.map(hotel => {
                const isOnline = !!hotel.is_vendor_online;
                const distNum = typeof hotel.distance === 'number' ? hotel.distance.toFixed(2) : hotel.distance;
                const directionsUrl = `https://www.google.com/maps/dir/?api=1&origin=${effectiveLat},${effectiveLng}&destination=${hotel.latitude},${hotel.longitude}`;

                const foodBadge = (hotel.food_type === 'VEG') 
                    ? '<span class="badge" style="background: #f0fdf4; color: #16a34a; border: 1px solid #bbf7d0; font-size: 10px; font-weight: 700;"><i class="fa-solid fa-leaf"></i> VEG</span>'
                    : ((hotel.food_type === 'NON-VEG' || hotel.food_type === 'NON_VEG')
                        ? '<span class="badge" style="background: #fef2f2; color: #dc2626; border: 1px solid #fecaca; font-size: 10px; font-weight: 700;"><i class="fa-solid fa-drumstick-bite"></i> NON-VEG</span>'
                        : '<span class="badge" style="background: #eff6ff; color: #2563eb; border: 1px solid #bfdbfe; font-size: 10px; font-weight: 700;"><i class="fa-solid fa-utensils"></i> BOTH VEG & NON-VEG</span>');

                const serviceBadge = (hotel.service_type === 'DINING')
                    ? '<span class="badge" style="background: #f8fafc; color: #475569; border: 1px solid #cbd5e1; font-size: 10px;">Dining Only</span>'
                    : ((hotel.service_type === 'DELIVERY')
                        ? '<span class="badge" style="background: #f8fafc; color: #475569; border: 1px solid #cbd5e1; font-size: 10px;">Delivery Only</span>'
                        : '<span class="badge" style="background: #f8fafc; color: #475569; border: 1px solid #cbd5e1; font-size: 10px;">Dining & Delivery</span>');

                const onlineBadge = isOnline
                    ? '<span class="badge" style="background: #dcfce7; color: #15803d; border: 1px solid #86efac; font-size: 10px; font-weight: 700; display: inline-flex; align-items: center; gap: 4px;"><span style="width: 6px; height: 6px; background: #16a34a; border-radius: 50%;"></span> Online</span>'
                    : '<span class="badge" style="background: #f1f5f9; color: #64748b; border: 1px solid #cbd5e1; font-size: 10px; display: inline-flex; align-items: center; gap: 4px;"><span style="width: 5px; height: 5px; background: #94a3b8; border-radius: 50%;"></span> Offline</span>';

                const photoUrl = hotel.photo_url || '';

                return `
                    <div class="customer-hotel-card">
                        <div style="display: flex; gap: 12px; align-items: flex-start;">
                            <div style="width: 52px; height: 52px; border-radius: 10px; overflow: hidden; background: #f1f5f9; flex-shrink: 0; display: flex; align-items: center; justify-content: center; border: 1px solid #e2e8f0;">
                                ${photoUrl ? `
                                    <img src="${photoUrl}" alt="${this.escapeHtml(hotel.hotel_name)}" style="width: 100%; height: 100%; object-fit: cover;" onerror="this.onerror=null; this.parentElement.innerHTML='<i class=\\'fa-solid fa-hotel\\' style=\\'color:#94a3b8; font-size:22px;\\'></i>';">
                                ` : `
                                    <i class="fa-solid fa-hotel" style="color: #ea580c; font-size: 22px;"></i>
                                `}
                            </div>
                            <div style="flex: 1; min-width: 0;">
                                <div style="display: flex; align-items: center; justify-content: space-between; gap: 6px; flex-wrap: wrap;">
                                    <h4 style="margin: 0; font-size: 13.5px; font-weight: 700; color: #0f172a;" title="${this.escapeHtml(hotel.hotel_name)}">
                                        ${this.escapeHtml(hotel.hotel_name)}
                                    </h4>
                                    <span class="badge" style="background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; font-size: 11px; font-weight: 800; padding: 2px 7px; border-radius: 12px; display: inline-flex; align-items: center; gap: 4px;" title="Straight-line distance from customer coordinates">
                                        <i class="fa-solid fa-route"></i> ${distNum} km
                                    </span>
                                </div>
                                <div style="display: flex; align-items: center; gap: 6px; margin-top: 4px; flex-wrap: wrap;">
                                    ${onlineBadge}
                                    ${foodBadge}
                                    ${serviceBadge}
                                </div>
                            </div>
                        </div>

                        <div style="margin-top: 10px; font-size: 11.5px; color: #334155; line-height: 1.4; background: #f8fafc; padding: 8px 10px; border-radius: 6px; border: 1px solid #f1f5f9;">
                            <div style="display: flex; align-items: flex-start; gap: 5px; margin-bottom: 4px;">
                                <i class="fa-solid fa-location-dot" style="color: #ea580c; margin-top: 2px; font-size: 11px;"></i>
                                <span>${this.escapeHtml(hotel.hotel_address || [hotel.area, hotel.city, hotel.pincode].filter(Boolean).join(', '))}</span>
                            </div>
                            ${hotel.owner_name || hotel.mobile_number ? `
                                <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap; color: #64748b; font-size: 11px; margin-top: 4px;">
                                    ${hotel.owner_name ? `<span><i class="fa-solid fa-user" style="font-size: 10px;"></i> ${this.escapeHtml(hotel.owner_name)}</span>` : ''}
                                    ${hotel.mobile_number ? `<a href="tel:${hotel.mobile_number}" style="color: #2563eb; text-decoration: none; font-weight: 600;"><i class="fa-solid fa-phone" style="font-size: 10px;"></i> ${this.escapeHtml(hotel.mobile_number)}</a>` : ''}
                                </div>
                            ` : ''}
                        </div>

                        <div style="margin-top: 10px; display: flex; align-items: center; justify-content: space-between; gap: 8px;">
                            <span style="font-size: 10.5px; color: #94a3b8; font-family: monospace;">
                                GPS: ${Number(hotel.latitude || 0).toFixed(4)}, ${Number(hotel.longitude || 0).toFixed(4)}
                            </span>
                            <a href="${directionsUrl}" target="_blank" rel="noopener noreferrer" class="btn btn-secondary btn-sm" style="font-size: 11px; padding: 4px 10px; border-radius: 6px; display: inline-flex; align-items: center; gap: 5px; background: #fff7ed; color: #c2410c; border: 1px solid #fed7aa; text-decoration: none; font-weight: 700;" title="Open driving directions in Google Maps from Customer location to this Hotel">
                                <i class="fa-solid fa-diamond-turn-right" style="color: #ea580c;"></i> Driving Route
                            </a>
                        </div>
                    </div>
                `;
            }).join('');
        }

        wrapper.innerHTML = `
            <div class="customer-hotels-card" style="background: #ffffff; border: 1.5px solid #fed7aa; border-radius: 12px; margin: 10px 14px 18px 14px; box-shadow: 0 10px 25px -5px rgba(234, 88, 12, 0.08), 0 8px 10px -6px rgba(0, 0, 0, 0.04); overflow: hidden;">
                <!-- Card Header -->
                <div class="customer-hotels-header" style="background: linear-gradient(135deg, #fff7ed 0%, #ffedd5 100%); padding: 12px 18px; border-bottom: 1.5px solid #fed7aa; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;">
                    <div style="display: flex; align-items: center; gap: 10px;">
                        <div style="width: 32px; height: 32px; border-radius: 8px; background: #ea580c; color: white; display: flex; align-items: center; justify-content: center; font-size: 15px; box-shadow: 0 2px 6px rgba(234, 88, 12, 0.3);">
                            <i class="fa-solid fa-hotel"></i>
                        </div>
                        <div>
                            <div style="font-size: 14px; font-weight: 800; color: #9a3412; display: flex; align-items: center; gap: 8px;">
                                <span>Customer Chosen Location & Nearest Hotels</span>
                                <span class="badge" style="background: #ffffff; color: #c2410c; border: 1px solid #fed7aa; font-size: 11px; font-weight: 700; padding: 2px 8px; border-radius: 12px;">
                                    ${this.escapeHtml(customer.full_name || 'Customer')} (#${customer.id})
                                </span>
                            </div>
                            <div style="font-size: 11px; color: #7c2d12; margin-top: 1px;">
                                Showing active chosen delivery location and all nearby registered messes sorted by proximity
                            </div>
                        </div>
                    </div>
                    <div style="display: flex; align-items: center; gap: 8px;">
                        <button class="btn btn-secondary btn-sm" onclick="app.loadCustomerHotelsData(${customerId})" title="Refresh nearby hotels list" style="font-size: 11px; padding: 4px 10px; background: #ffffff; border-color: #fdba74; color: #9a3412; font-weight: 600;">
                            <i class="fa-solid fa-arrows-rotate"></i> Refresh
                        </button>
                        <button class="btn btn-secondary btn-sm btn-icon" onclick="app.closeCustomerHotelsDropdown(${customerId})" title="Close dropdown" style="width: 28px; height: 28px; font-size: 12px; background: #ffffff; border-color: #fdba74; color: #9a3412;">
                            <i class="fa-solid fa-xmark"></i>
                        </button>
                    </div>
                </div>

                <!-- Card Body -->
                <div style="padding: 18px;">
                    <!-- Top Section: Customer Choosing Location -->
                    <div class="customer-chosen-location-box" style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 14px; margin-bottom: 18px;">
                        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; flex-wrap: wrap; gap: 8px;">
                            <div style="display: flex; align-items: center; gap: 6px;">
                                <i class="fa-solid fa-location-dot" style="color: #ea580c; font-size: 14px;"></i>
                                <strong style="color: #1e293b; font-size: 13px;">Customer Choosing Location:</strong>
                                <span class="badge" style="background: #e0e7ff; color: #3730a3; border: 1px solid #c7d2fe; font-size: 10.5px; font-weight: 700;">
                                    ${this.escapeHtml(addrTag)}
                                </span>
                                ${isDefault ? '<span class="badge badge-success" style="font-size: 10px; padding: 2px 6px;">DEFAULT ADDRESS</span>' : ''}
                            </div>
                            <a href="${mapUrl}" target="_blank" rel="noopener noreferrer" style="font-size: 11.5px; color: #2563eb; text-decoration: none; font-weight: 700; display: inline-flex; align-items: center; gap: 4px;">
                                <i class="fa-solid fa-arrow-up-right-from-square"></i> Open Coordinates in Google Maps
                            </a>
                        </div>

                        ${addressSelectorHtml}

                        <!-- Detailed Address Card -->
                        <div style="background: #ffffff; border: 1px dashed #cbd5e1; border-radius: 8px; padding: 10px 12px;">
                            <div style="font-size: 12.5px; font-weight: 600; color: #0f172a; line-height: 1.4; margin-bottom: 6px;">
                                ${this.escapeHtml(addrText)}
                            </div>
                            <div style="display: flex; gap: 14px; align-items: center; flex-wrap: wrap; font-size: 11.5px; color: #64748b;">
                                ${activeAddress.pincode ? `<span><i class="fa-solid fa-hashtag" style="color: #94a3b8;"></i> Pincode: <strong>${this.escapeHtml(activeAddress.pincode)}</strong></span>` : ''}
                                ${activeAddress.area ? `<span><i class="fa-solid fa-map-pin" style="color: #94a3b8;"></i> Area: <strong>${this.escapeHtml(activeAddress.area)}</strong></span>` : ''}
                                ${activeAddress.city ? `<span><i class="fa-solid fa-city" style="color: #94a3b8;"></i> City: <strong>${this.escapeHtml(activeAddress.city)}</strong></span>` : ''}
                                <span style="color: ${usingFallbackCoords ? '#ea580c' : '#16a34a'}; font-weight: 600;">
                                    <i class="fa-solid fa-crosshairs"></i> GPS: ${coordsText} ${usingFallbackCoords ? '(Default City Fallback)' : ''}
                                </span>
                            </div>
                        </div>
                    </div>

                    <!-- Bottom Section: Nearest Hotels Grid -->
                    <div>
                        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; flex-wrap: wrap; gap: 10px;">
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <i class="fa-solid fa-utensils" style="color: #ea580c; font-size: 14px;"></i>
                                <strong style="color: #1e293b; font-size: 13px;">Nearest Hotels & Messes:</strong>
                                <span class="badge" style="background: #ffedd5; color: #9a3412; border: 1px solid #fed7aa; font-weight: 800; font-size: 11px; padding: 2px 8px; border-radius: 12px;">
                                    ${hotels.length} ${hotels.length === 1 ? 'Hotel' : 'Hotels'} Found
                                </span>
                            </div>
                            ${filterPillsHtml}
                        </div>

                        <!-- Grid -->
                        <div class="customer-hotels-grid" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 14px;">
                            ${hotelsContentHtml}
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    onCustomerHotelsAddressSelect(customerId, selectedIndex) {
        this.loadCustomerHotelsData(customerId, selectedIndex, null);
    }

    onCustomerHotelsFoodFilter(customerId, foodFilter) {
        this.loadCustomerHotelsData(customerId, null, foodFilter);
    }

        async viewDriverDetails(id) {
        this.showLoader(true);
        try {
            const res = await api.getDriverDetails(id);
            const driver = res.data.driver;

            const title = document.getElementById('modal-title');
            const content = document.getElementById('modal-content');

            const isOnline = driver.is_online;
            const onlineBadge = isOnline 
                ? '<span class="badge" style="background:#dcfce7; color:#15803d; border:1px solid #86efac; font-size:12px; padding:4px 10px; font-weight:700;"><i class="fa-solid fa-circle" style="font-size:7px; color:#16a34a; margin-right:5px;"></i>Online</span>' 
                : '<span class="badge" style="background:#f1f5f9; color:#64748b; border:1px solid #cbd5e1; font-size:12px; padding:4px 10px; font-weight:600;"><i class="fa-regular fa-circle" style="font-size:7px; margin-right:5px;"></i>Offline</span>';

            const statusBadge = driver.status === 'active'
                ? '<span class="badge badge-success">Active Driver</span>'
                : '<span class="badge badge-danger">Inactive Driver</span>';

            title.innerHTML = `
                <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                    <i class="fa-solid fa-motorcycle text-primary"></i>
                    <span>${this.escapeHtml(driver.full_name)}</span>
                    ${onlineBadge}
                    ${statusBadge}
                </div>
            `;

            const cleanPhone = (driver.phone_number || '').replace(/[^0-9]/g, '');
            const dateStr = driver.created_at ? new Date(driver.created_at).toLocaleDateString('en-IN', {
                day: 'numeric', month: 'short', year: 'numeric'
            }) : 'N/A';

            const locationStr = [driver.taluka, driver.district, driver.state, driver.country].filter(Boolean).join(', ') || 'Not set';

            content.innerHTML = `
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 20px;">
                    <div class="modal-detail-row">
                        <strong>Driver ID</strong>
                        <span>#${driver.id}</span>
                    </div>
                    <div class="modal-detail-row">
                        <strong>Vehicle Number</strong>
                        <span style="font-family: monospace; font-weight: 700; background: var(--bg-surface); padding: 3px 8px; border-radius: 4px; border: 1px solid var(--border-color);">
                            ${this.escapeHtml(driver.vehicle_number || 'N/A')}
                        </span>
                    </div>
                    <div class="modal-detail-row">
                        <strong>Full Name</strong>
                        <span>${this.escapeHtml(driver.full_name)}</span>
                    </div>
                    <div class="modal-detail-row">
                        <strong>Email Address</strong>
                        <span>${this.escapeHtml(driver.email || 'N/A')}</span>
                    </div>
                    <div class="modal-detail-row">
                        <strong>Phone Number</strong>
                        <div style="display: flex; gap: 8px; align-items: center;">
                            <a href="tel:${driver.phone_number}" style="font-weight: 600; text-decoration: none; color: var(--accent-primary);">
                                <i class="fa-solid fa-phone"></i> ${driver.phone_number || 'N/A'}
                            </a>
                            ${cleanPhone ? `
                                <a href="https://wa.me/${cleanPhone.length === 10 ? '91' + cleanPhone : cleanPhone}" target="_blank" class="btn btn-sm" style="background: #25D366; color: white; padding: 2px 8px; font-size: 11px; border-radius: 4px; display: inline-flex; align-items: center; gap: 4px; text-decoration: none;">
                                    <i class="fa-brands fa-whatsapp"></i> WhatsApp
                                </a>
                            ` : ''}
                        </div>
                    </div>
                    <div class="modal-detail-row">
                        <strong>Max Order Capacity</strong>
                        <span><i class="fa-solid fa-box text-primary"></i> ${driver.max_capacity || 3} orders simultaneously</span>
                    </div>
                    <div class="modal-detail-row">
                        <strong>Operating Region</strong>
                        <span><i class="fa-solid fa-location-dot text-primary"></i> ${this.escapeHtml(locationStr)}</span>
                    </div>
                    <div class="modal-detail-row">
                        <strong>Date Registered</strong>
                        <span>${dateStr}</span>
                    </div>
                </div>

                <!-- ASSOCIATED VENDOR CARD -->
                <div style="background: var(--bg-surface); padding: 18px; border-radius: var(--radius-md); border: 1px solid var(--border-color); margin-bottom: 20px;">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; border-bottom: 1px solid var(--border-color); padding-bottom: 8px;">
                        <h4 style="font-size: 14px; font-weight: 700; color: var(--text-primary); margin: 0;">
                            <i class="fa-solid fa-shop text-primary"></i> Associated Vendor
                        </h4>
                        ${driver.vendor_id ? `
                            <button class="btn btn-secondary btn-sm" onclick="app.closeModal('details-modal'); app.viewVendorDetails(${driver.vendor_id}, 'drivers');">
                                <i class="fa-solid fa-arrow-up-right-from-square"></i> Open Vendor Profile & Fleet
                            </button>
                        ` : ''}
                    </div>
                    ${driver.vendor_id ? `
                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                            <div class="modal-detail-row">
                                <strong>Vendor Name</strong>
                                <span style="font-weight: 700; color: var(--accent-primary);">${this.escapeHtml(driver.vendor_name || 'Vendor #' + driver.vendor_id)}</span>
                            </div>
                            <div class="modal-detail-row">
                                <strong>Business / Hotel</strong>
                                <span>${this.escapeHtml(driver.vendor_business_name || 'N/A')}</span>
                            </div>
                            <div class="modal-detail-row">
                                <strong>Vendor Phone</strong>
                                <span><i class="fa-solid fa-phone"></i> ${this.escapeHtml(driver.vendor_phone || 'N/A')}</span>
                            </div>
                            <div class="modal-detail-row">
                                <strong>Vendor Email</strong>
                                <span><i class="fa-solid fa-envelope"></i> ${this.escapeHtml(driver.vendor_email || 'N/A')}</span>
                            </div>
                        </div>
                    ` : `
                        <div style="color: var(--text-muted); font-size: 13px; padding: 10px 0;">
                            <i class="fa-solid fa-info-circle"></i> This driver is currently registered as an <strong>Independent Driver</strong> and is not linked to any specific vendor.
                        </div>
                    `}
                </div>

                <div style="display: flex; justify-content: flex-end; gap: 10px;">
                    <button class="btn btn-secondary" onclick="app.closeModal('details-modal')">Close</button>
                    <button class="btn btn-primary" onclick="app.closeModal('details-modal'); app.editDriverRoute(${driver.id})">
                        <i class="fa-solid fa-pen-to-square"></i> Edit Driver
                    </button>
                </div>
            `;

            this.openModal('details-modal');
        } catch (e) {
            this.showToast('Failed to load driver details: ' + e.message, 'error');
        } finally {
            this.showLoader(false);
        }
    }
    openDeleteModal(id, type) {
        this.selectedDeleteId = id;
        this.selectedDeleteType = type;
        this.openModal('delete-modal');
    }

    async executeDelete() {
        this.closeModal('delete-modal');
        if (!this.selectedDeleteId || !this.selectedDeleteType) return;

        this.showLoader(true);
        try {
            if (this.selectedDeleteType === 'vendor') {
                await api.deleteVendor(this.selectedDeleteId);
                this.showToast('Vendor deleted successfully.', 'success');
                await this.fetchVendorsList();
            } else if (this.selectedDeleteType === 'user') {
                await api.deleteUser(this.selectedDeleteId);
                this.showToast('Customer profile deleted.', 'success');
                await this.fetchUsersList();
            } else if (this.selectedDeleteType === 'service_location') {
                await api.deleteServiceLocation(this.selectedDeleteId);
                this.showToast('Service location deleted successfully.', 'success');
                await this.fetchLocationList();
            } else if (this.selectedDeleteType === 'enquiry') {
                await api.deleteEnquiry(this.selectedDeleteId);
                this.showToast('Enquiry record deleted successfully.', 'success');
                await this.fetchEnquiries();
            } else if (['city', 'pincode', 'area', 'sub_area', 'plan'].includes(this.selectedDeleteType)) {
                await api.deleteLocation(this.selectedDeleteType, this.selectedDeleteId);
                this.showToast(`Deleted ${this.selectedDeleteType.replace('_', ' ')} successfully.`, 'success');
                await this.fetchLocationList();
            }
        } catch (error) {
            this.showToast('Deletion failed: ' + error.message, 'error');
        } finally {
            this.showLoader(false);
            this.selectedDeleteId = null;
            this.selectedDeleteType = null;
        }
    }

    /* -- Helper Methods ---------------------------------------------------- */

    showLoader(show) {
        const loader = document.getElementById('global-loader');
        if (show) {
            loader.classList.remove('hidden');
        } else {
            loader.classList.add('hidden');
        }
    }

    escapeHtml(str) {
        if (str === null || str === undefined) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    formatOrderDateTime(raw) {
        if (!raw) return 'N/A';
        const str = String(raw).trim();
        const parts = str.split(/[\sT]+/);
        if (parts.length >= 2) {
            const dateParts = parts[0].split('-').map(Number);
            const timeParts = parts[1].split(':').map(Number);
            if (dateParts.length === 3 && !dateParts.some(isNaN) && timeParts.length >= 2 && !timeParts.slice(0, 2).some(isNaN)) {
                const [year, month, day] = dateParts;
                const [hour, min] = timeParts;
                const h = hour % 12 || 12;
                const ampm = hour >= 12 ? 'PM' : 'AM';
                const pad = (n) => String(n).padStart(2, '0');
                return pad(day) + '/' + pad(month) + '/' + year + ', ' + pad(h) + ':' + pad(min) + ' ' + ampm;
            }
        }
        const parsed = new Date(str.replace(' ', 'T'));
        if (!isNaN(parsed.getTime())) {
            return parsed.toLocaleString('en-IN', {
                day: '2-digit', month: '2-digit', year: 'numeric',
                hour: '2-digit', minute: '2-digit', hour12: true
            });
        }
        return str;
    }

    togglePasswordVisibility(elementId, realPassword) {
        const el = document.getElementById(elementId);
        const icon = document.getElementById('user-pwd-icon-' + elementId);
        if (!el) return;

        if (el.dataset.isRevealed === 'true') {
            el.dataset.isRevealed = 'false';
            el.textContent = '••••••••••••••••';
            if (icon) {
                icon.className = 'fa-solid fa-eye';
            }
        } else {
            el.dataset.isRevealed = 'true';
            el.textContent = realPassword || 'No password set';
            if (icon) {
                icon.className = 'fa-solid fa-eye-slash';
            }
        }
    }

    showToast(message, type = 'success') {
        const container = document.getElementById('toast-container');
        if (!container) return;

        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        
        let iconClass = 'fa-circle-check';
        if (type === 'error') iconClass = 'fa-triangle-exclamation';
        if (type === 'warning') iconClass = 'fa-circle-exclamation';

        toast.innerHTML = `
            <i class="fa-solid ${iconClass} toast-icon"></i>
            <span>${message}</span>
            <i class="fa-solid fa-xmark toast-close" onclick="this.parentElement.remove()"></i>
        `;

        container.appendChild(toast);

        // Auto remove toast after 4s
        setTimeout(() => {
            toast.style.opacity = '0';
            toast.style.transform = 'translateY(-10px)';
            setTimeout(() => toast.remove(), 300);
        }, 4000);
    }

    showError(field, message) {
        const errorEl = document.getElementById(`error-${field}`);
        if (errorEl) {
            errorEl.textContent = message;
            errorEl.classList.remove('hidden');
        }
    }

    clearFormErrors(fields) {
        fields.forEach(field => {
            const errorEl = document.getElementById(`error-${field}`);
            if (errorEl) {
                errorEl.classList.add('hidden');
                errorEl.textContent = '';
            }
        });
    }

    validateEmail(email) {
        const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return re.test(String(email).toLowerCase());
    }

    validatePasswordStrength(password) {
        // At least 8 characters, one letter and one number
        return password.length >= 8 
            && /[A-Za-z]/.test(password) 
            && /[0-9]/.test(password);
    }

    initLocationDropdowns(countryEl, stateEl, districtEl, talukaEl, initial = {}, regionEl = null, areaEl = null) {
        if (!countryEl || !stateEl || !districtEl || !talukaEl) return;

        const initCountry = initial.country || (typeof LOCATION_DATA !== 'undefined' ? LOCATION_DATA.defaultCountry : 'India') || 'India';
        const initState = initial.state || '';
        const initDistrict = initial.district || '';
        const initTaluka = initial.taluka || '';
        const initRegion = initial.region || '';
        const initArea = initial.area || '';

        const countries = (typeof LOCATION_DATA !== 'undefined' && LOCATION_DATA.countries) ? LOCATION_DATA.countries : ['India'];
        countryEl.innerHTML = countries.map(c => `<option value="${c}" ${c === initCountry ? 'selected' : ''}>${c}</option>`).join('');

        const updateStates = (selectedState = '') => {
            const country = countryEl.value;
            const states = [...((typeof LOCATION_DATA !== 'undefined' && LOCATION_DATA.statesByCountry && LOCATION_DATA.statesByCountry[country]) || [])];
            if (selectedState && !states.includes(selectedState)) {
                states.unshift(selectedState);
            }
            stateEl.innerHTML = '<option value="">-- Select State --</option>' +
                states.map(s => `<option value="${s}" ${s === selectedState ? 'selected' : ''}>${s}</option>`).join('');
        };

        const updateRegions = (selectedRegion = '') => {
            if (!regionEl) return;
            const district = districtEl.value;
            const regions = (district && typeof LOCATION_DATA.getRegions === 'function') ? LOCATION_DATA.getRegions(district) : [];
            regionEl.innerHTML = '<option value="">-- Select Region (Optional) --</option>' +
                regions.map(r => `<option value="${r}" ${r === selectedRegion ? 'selected' : ''}>${r}</option>`).join('');
        };

        const updateAreas = (selectedArea = '') => {
            if (!areaEl) return;
            const district = districtEl.value;
            const region = regionEl ? regionEl.value : '';
            let areas = [];
            if (district && typeof LOCATION_DATA.getAreas === 'function') {
                areas = LOCATION_DATA.getAreas(district, region);
            }
            areaEl.innerHTML = '<option value="">-- Select Area (Optional) --</option>' +
                areas.map(a => `<option value="${a}" ${a === selectedArea ? 'selected' : ''}>${a}</option>`).join('');
        };

        const updateDistricts = (selectedDistrict = '') => {
            const state = stateEl.value;
            const districts = [...((typeof LOCATION_DATA !== 'undefined' && LOCATION_DATA.districtsByState && LOCATION_DATA.districtsByState[state]) || [])];
            if (selectedDistrict && !districts.includes(selectedDistrict)) {
                districts.unshift(selectedDistrict);
            }
            districtEl.innerHTML = '<option value="">-- Select District --</option>' +
                districts.map(d => `<option value="${d}" ${d === selectedDistrict ? 'selected' : ''}>${d}</option>`).join('');
            updateRegions(initRegion);
            updateAreas(initArea);
        };

        const updateTalukas = (selectedTaluka = '') => {
            const district = districtEl.value;
            const talukas = [...((typeof LOCATION_DATA !== 'undefined' && LOCATION_DATA.talukasByDistrict && LOCATION_DATA.talukasByDistrict[district]) || [])];
            if (selectedTaluka && !talukas.includes(selectedTaluka)) {
                talukas.unshift(selectedTaluka);
            }
            talukaEl.innerHTML = '<option value="">-- Select Taluka --</option>' +
                talukas.map(t => `<option value="${t}" ${t === selectedTaluka ? 'selected' : ''}>${t}</option>`).join('');
        };

        let effectiveState = initState;
        if (!effectiveState && initDistrict && typeof LOCATION_DATA !== 'undefined' && LOCATION_DATA.districtsByState) {
            for (const [st, dists] of Object.entries(LOCATION_DATA.districtsByState)) {
                if (dists.includes(initDistrict)) {
                    effectiveState = st;
                    break;
                }
            }
        }

        updateStates(effectiveState);
        updateDistricts(initDistrict);
        updateTalukas(initTaluka);
        updateRegions(initRegion);
        updateAreas(initArea);

        countryEl.addEventListener('change', () => {
            updateStates('');
            updateDistricts('');
            updateTalukas('');
            updateRegions('');
            updateAreas('');
        });

        stateEl.addEventListener('change', () => {
            updateDistricts('');
            updateTalukas('');
            updateRegions('');
            updateAreas('');
        });

        districtEl.addEventListener('change', () => {
            updateTalukas('');
            updateRegions('');
            updateAreas('');
        });

        if (regionEl) {
            regionEl.addEventListener('change', () => {
                updateAreas('');
            });
        }
    }

    /* -- Service Areas & Subscription Management ------------------------ */

    async loadAreasView(container) {
        if (!this.locationQuery) {
            this.locationQuery = { search: '', status: 'all' };
        }

        container.innerHTML = `
            <div class="view-header">
                <h2>Service Areas & Subscription Plans</h2>
                <div class="view-actions">
                    <button class="btn btn-primary" onclick="app.openLocationAddModal()" style="display: flex; align-items: center; gap: 6px;">
                        <i class="fa-solid fa-map-location-dot"></i> Add Service Area
                    </button>
                </div>
            </div>

            <div class="filter-bar">
                <div class="search-input-wrapper">
                    <i class="fa-solid fa-magnifying-glass search-icon"></i>
                    <input type="text" id="location-search" class="search-input" placeholder="Search areas by pincode or area name..." value="${this.locationQuery.search}">
                </div>
                <div class="filters-wrapper">
                    <select id="location-status-filter" class="filter-select">
                        <option value="all" ${this.locationQuery.status === 'all' ? 'selected' : ''}>All Statuses</option>
                        <option value="active" ${this.locationQuery.status === 'active' ? 'selected' : ''}>Active Only</option>
                        <option value="inactive" ${this.locationQuery.status === 'inactive' ? 'selected' : ''}>Deactivated Only</option>
                    </select>
                </div>
            </div>

            <div class="table-responsive">
                <table class="table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Pin Code / Area Name</th>
                            <th>Radius</th>
                            <th>Area Tiffin Charge</th>
                            <th>Plans</th>
                            <th>Status</th>
                            <th class="text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="location-table-body">
                        <tr>
                            <td colspan="7" class="text-center" style="padding: 40px;">
                                <div class="spinner" style="margin: 0 auto; width: 30px; height: 30px;"></div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        `;

        const searchInput = document.getElementById('location-search');
        const statusSelect = document.getElementById('location-status-filter');

        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                clearTimeout(this.debouncedSearchTimeout);
                this.debouncedSearchTimeout = setTimeout(() => {
                    this.locationQuery.search = e.target.value;
                    this.fetchLocationList();
                }, 400);
            });
        }

        if (statusSelect) {
            statusSelect.addEventListener('change', (e) => {
                this.locationQuery.status = e.target.value;
                this.fetchLocationList();
            });
        }

        await this.fetchLocationList();
    }

    async fetchLocationList() {
        const tbody = document.getElementById('location-table-body');
        if (!tbody) return;

        try {
            // Fetch service locations (new flat model with nested plans)
            const result = await api.getServiceLocations({
                search: this.locationQuery.search,
                status: this.locationQuery.status
            });
            const locations = result.data.list || [];
            this.currentLocationList = locations;

            if (locations.length === 0) {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="7" class="text-center" style="padding: 40px; color: var(--text-secondary);">
                            <i class="fa-solid fa-inbox" style="font-size: 32px; margin-bottom: 12px; display: block; color: var(--text-muted);"></i>
                            No service locations found. Click "+ Add Service Location" to create one.
                        </td>
                    </tr>
                `;
                return;
            }

            tbody.innerHTML = locations.map(item => {
                const isActive = item.status === 'active';
                const statusBadge = isActive
                    ? '<span class="badge badge-success">Active</span>'
                    : '<span class="badge badge-danger">Inactive</span>';
                const toggleIcon  = isActive ? 'fa-eye-slash' : 'fa-eye';
                const toggleTitle = isActive ? 'Deactivate' : 'Activate';
                const plansCount  = (item.plans || []).length;
                const distLabel   = item.radius_km ? `${item.radius_km} km radius` : '';
                const tiffinCharge = item.tiffin_charge !== undefined ? parseFloat(item.tiffin_charge).toFixed(2) : '50.00';
                const originalTiffinCharge = (item.original_tiffin_charge && parseFloat(item.original_tiffin_charge) > 0) ? parseFloat(item.original_tiffin_charge).toFixed(2) : null;
                const discountPct = (originalTiffinCharge && parseFloat(originalTiffinCharge) > parseFloat(tiffinCharge))
                    ? Math.round(((parseFloat(originalTiffinCharge) - parseFloat(tiffinCharge)) / parseFloat(originalTiffinCharge)) * 100)
                    : 0;

                return `
                    <tr>
                        <td><strong>#${item.id}</strong></td>
                        <td>
                            <div style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
                                <strong style="color: var(--accent-primary); font-size: 15px;">${item.location_name}</strong>
                                ${(function() {
                                    const rLoc = (typeof LOCATION_DATA !== 'undefined' && typeof LOCATION_DATA.resolveLocation === 'function')
                                        ? LOCATION_DATA.resolveLocation(item.location_name + ' ' + (item.address || '') + ' ' + (item.region || ''))
                                        : { area: '', region: '' };
                                    return (typeof LOCATION_DATA !== 'undefined' && typeof LOCATION_DATA.renderAreaRegionBadge === 'function')
                                        ? LOCATION_DATA.renderAreaRegionBadge(rLoc.area || item.location_name, rLoc.region || item.region)
                                        : '';
                                })()}
                            </div>
                            <small style="color:var(--text-muted);">${item.address || ''}</small>
                        </td>
                        <td><small>${distLabel}</small></td>
                        <td>
                            <div style="display: flex; flex-direction: column; gap: 3px;">
                                <span class="badge" style="background-color: #fef3c7; color: #b45309; font-weight: 700; border: 1px solid #fde68a; display: inline-flex; align-items: center; gap: 5px;">
                                    ${originalTiffinCharge && discountPct > 0 ? `<span style="text-decoration: line-through; opacity: 0.6; font-size: 11px;">₹${originalTiffinCharge}</span>` : ''}
                                    <span>₹${tiffinCharge} / order</span>
                                </span>
                                ${discountPct > 0 ? `<span class="badge" style="background: #dcfce7; color: #15803d; border: 1px solid #86efac; font-size: 10px; font-weight: 800; padding: 1px 6px; border-radius: 8px; width: fit-content;"><i class="fa-solid fa-tag"></i> ${discountPct}% OFF</span>` : ''}
                            </div>
                        </td>
                        <td><span class="badge" style="background-color: var(--bg-surface); color: var(--accent-primary); font-weight: 700;">${plansCount} Plans</span></td>
                        <td>${statusBadge}</td>
                        <td class="text-right">
                            <div class="table-actions" style="justify-content: flex-end;">
                                <button class="btn btn-secondary btn-icon" title="Edit Location & Plans" onclick="app.openLocationEditModal(${item.id})">
                                     <i class="fa-solid fa-pencil"></i>
                                </button>
                                <button class="btn btn-secondary btn-icon" title="${toggleTitle}" onclick="app.toggleLocationStatus(${item.id}, ${isActive})">
                                     <i class="fa-solid ${toggleIcon}"></i>
                                </button>
                                <button class="btn btn-danger btn-icon" title="Delete Location" onclick="app.openLocationDeleteModal(${item.id})">
                                     <i class="fa-solid fa-trash-can"></i>
                                </button>
                            </div>
                        </td>
                    </tr>
                `;
            }).join('');
        } catch (error) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="6" class="text-center text-danger" style="padding: 24px;">
                        Failed to fetch service locations: ${error.message}
                    </td>
                </tr>
            `;
        }
    }

    onQuickLocationDistrictChange() {
        const dSelect = document.getElementById('loc-quick-district');
        const rSelect = document.getElementById('loc-quick-region');
        const aSelect = document.getElementById('loc-quick-area');
        if (!dSelect || !rSelect || !aSelect) return;
        const district = dSelect.value;
        const regions = (district && typeof LOCATION_DATA.getRegions === 'function') ? LOCATION_DATA.getRegions(district) : [];
        rSelect.innerHTML = '<option value="">All Regions --</option>' + regions.map(r => `<option value="${r}">${r}</option>`).join('');
        this.onQuickLocationRegionChange();
    }

    onQuickLocationRegionChange() {
        const dSelect = document.getElementById('loc-quick-district');
        const rSelect = document.getElementById('loc-quick-region');
        const aSelect = document.getElementById('loc-quick-area');
        if (!dSelect || !aSelect) return;
        const district = dSelect.value;
        const region = rSelect ? rSelect.value : '';
        const areas = (district && typeof LOCATION_DATA.getAreas === 'function') ? LOCATION_DATA.getAreas(district, region) : [];
        aSelect.innerHTML = '<option value="">-- Pick Area --</option>' + areas.map(a => `<option value="${a}">${a}</option>`).join('');
    }

    onQuickLocationAreaSelect() {
        const aSelect = document.getElementById('loc-quick-area');
        const rSelect = document.getElementById('loc-quick-region');
        const dSelect = document.getElementById('loc-quick-district');
        if (!aSelect || !aSelect.value) return;
        const area = aSelect.value;
        const region = rSelect ? rSelect.value : '';
        const district = dSelect ? dSelect.value : 'Pune';

        const nameInput = document.getElementById('loc-location-name');
        const regionInput = document.getElementById('loc-region');
        const addressInput = document.getElementById('loc-address');

        if (nameInput) nameInput.value = area;
        if (regionInput) regionInput.value = (region ? region + ', ' : '') + district + ', Maharashtra';
        if (addressInput && !addressInput.value) {
            addressInput.value = area + ', ' + district + ', Maharashtra';
        }
        if (typeof this.geocodeAddressAndSetPin === 'function') {
            this.geocodeAddressAndSetPin(area + ', ' + district + ', Maharashtra');
        }
    }

    openLocationAddModal() {
        this.currentLocationEditId = null;
        document.getElementById('location-modal-title').textContent = 'Create Service Area & Subscription Plans';
        this.renderLocationForm();
        this.openModal('location-modal');
    }

    openLocationEditModal(id) {
        this.currentLocationEditId = id;
        document.getElementById('location-modal-title').textContent = 'Edit Service Location & Plans';

        const record = this.currentLocationList.find(x => x.id === id);
        const plans  = record ? (record.plans || []) : [];

        this.renderLocationForm(record, plans);
        this.openModal('location-modal');
    }

    renderLocationForm(record = null, plans = []) {
        const body = document.getElementById('location-modal-body');
        if (!body) return;

        const isEdit       = !!record;
        const locationName = isEdit ? (record.location_name || '') : '';
        const lat          = isEdit ? (record.latitude  || '') : '';
        const lng          = isEdit ? (record.longitude || '') : '';
        const radius       = isEdit ? (record.radius_km || '5.0') : '5.0';
        const tiffinCharge = isEdit ? (record.tiffin_charge !== undefined ? record.tiffin_charge : '50.00') : '50.00';
        const originalTiffinCharge = isEdit ? (record.original_tiffin_charge !== undefined && record.original_tiffin_charge !== '0.00' && record.original_tiffin_charge !== 0 ? record.original_tiffin_charge : '') : '';
        const address      = isEdit ? (record.address  || '') : '';
        const country      = isEdit ? (record.country  || 'IN') : 'IN';
        const region       = isEdit ? (record.region   || '') : '';
        const isActive     = isEdit ? (record.status === 'active' ? '1' : '0') : '1';

        body.innerHTML = `
            <!-- Maharashtra Locations Hierarchy Quick Picker -->
            <div style="background: linear-gradient(135deg, #f0fdf4 0%, #ecfdf5 100%); border: 1.5px solid #a7f3d0; border-radius: 12px; padding: 14px 16px; margin-bottom: 18px;">
                <label style="display: flex; align-items: center; justify-content: space-between; font-weight: 700; color: #065f46; font-size: 13px; margin-bottom: 8px;">
                    <span><i class="fa-solid fa-map-location-dot" style="margin-right: 6px; color: #059669;"></i> Select Area / Region from Maharashtra Locations</span>
                    <span class="badge" style="background: #10b981; color: white; font-size: 10px; font-weight: 800; padding: 2px 8px; border-radius: 12px;">Active JSON</span>
                </label>
                <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px;">
                    <div>
                        <span style="font-size: 11px; font-weight: 700; color: #047857; display: block; margin-bottom: 3px;">District</span>
                        <select id="loc-quick-district" class="form-control" style="font-size: 12px; height: 36px; border-color: #6ee7b7; background: #fff;" onchange="app.onQuickLocationDistrictChange()">
                            <option value="">-- Pick District --</option>
                            ${((typeof LOCATION_DATA !== 'undefined' && LOCATION_DATA.districtsByState && LOCATION_DATA.districtsByState['Maharashtra']) || []).map(d => `<option value="${d}" ${d === 'Pune' ? 'selected' : ''}>${d}</option>`).join('')}
                        </select>
                    </div>
                    <div>
                        <span style="font-size: 11px; font-weight: 700; color: #047857; display: block; margin-bottom: 3px;">Region (e.g. PMC, PCMC)</span>
                        <select id="loc-quick-region" class="form-control" style="font-size: 12px; height: 36px; border-color: #6ee7b7; background: #fff;" onchange="app.onQuickLocationRegionChange()">
                            <option value="">All Regions --</option>
                        </select>
                    </div>
                    <div>
                        <span style="font-size: 11px; font-weight: 700; color: #047857; display: block; margin-bottom: 3px;">Area / Locality</span>
                        <select id="loc-quick-area" class="form-control" style="font-size: 12px; height: 36px; border-color: #6ee7b7; background: #fff;" onchange="app.onQuickLocationAreaSelect()">
                            <option value="">-- Pick Area --</option>
                        </select>
                    </div>
                </div>
                <small style="color: #047857; font-size: 11px; margin-top: 6px; display: block; font-weight: 500;">
                    Picking an area automatically sets Location Name, Region, and geolocates coordinates on the map.
                </small>
            </div>

            <!-- Location Name -->
            <div class="form-group" style="margin-bottom: 16px;">
                <label class="form-label"><i class="fa-solid fa-tag text-primary" style="margin-right: 6px;"></i> Location Name / Service Zones (Comma-separated for multiple areas) <span style="color: var(--danger);">*</span></label>
                <input type="text" id="loc-location-name" class="form-control" placeholder="e.g. Baner, Kothrud, Pimpri, Hinjewadi" value="${locationName}" required>
                <small style="color: var(--text-muted); font-size: 11px;">Enter a single location name OR comma-separated names (e.g. Baner, Kothrud, Pimpri) to automatically create separate area-wise location cards with these plans.</small>
            </div>

            <!-- Google Maps Address Search with Autocomplete -->
            <div class="form-group" style="margin-bottom: 16px;">
                <label class="form-label"><i class="fa-solid fa-location-dot text-primary" style="margin-right: 6px;"></i> Service Zone Address (Google Places API)</label>
                <input type="text" id="loc-address" class="form-control" placeholder="Type address or landmark to auto-fill coordinates..." value="${address}">
                <small style="color: var(--text-muted); font-size: 11px;">Select from suggestions, then <b>drag the pin</b> to fine-tune. All plans under this location use this centre point + radius.</small>
            </div>

            <!-- Interactive Map with Draggable Pin -->
            <div id="loc-map" style="height: 300px; border-radius: var(--radius-md); margin-bottom: 16px; background: var(--bg-secondary); border: 1px solid var(--border-color); display: flex; align-items: center; justify-content: center; overflow: hidden; position: relative;">
                <div id="loc-map-placeholder" style="text-align: center; color: var(--text-muted); padding: 24px;">
                    <i class="fa-solid fa-map-location-dot" style="font-size: 40px; margin-bottom: 12px; display: block; opacity: 0.3;"></i>
                    <span style="font-size: 13px;">Search an address above or enter coordinates to display the map</span>
                </div>
            </div>

            <!-- Duplicate Warning Banner (hidden by default) -->
            <div id="loc-duplicate-warning" class="alert-banner" style="display: none; background: rgba(245, 158, 11, 0.1); border: 1px solid rgba(245, 158, 11, 0.4); border-radius: var(--radius-md); padding: 12px 16px; margin-bottom: 16px; color: #b45309; font-size: 13px;">
                <i class="fa-solid fa-triangle-exclamation" style="margin-right: 8px;"></i>
                <span id="loc-duplicate-text"></span>
            </div>

            <!-- Area Tiffin Charge, Original Charge & Live Discount Preview -->
            <div style="background: #fffdfa; border: 1.5px solid #fed7aa; border-radius: 12px; padding: 14px 16px; margin-bottom: 16px;">
                <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; flex-wrap: wrap; gap: 8px;">
                    <span style="font-weight: 700; font-size: 13px; color: #9a3412;">
                        <i class="fa-solid fa-box text-primary" style="margin-right: 6px; color: #ea580c;"></i> Area Tiffin Charge & Discount Configuration
                    </span>
                    <span id="loc-tiffin-discount-badge" style="font-size: 11px; font-weight: 800;"></span>
                </div>
                <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 14px;">
                    <div class="form-group" style="margin-bottom: 0;">
                        <label class="form-label" style="font-size: 12px; font-weight: 700; color: #475569;">
                            Original Tiffin Charge (₹)
                        </label>
                        <input type="number" step="any" id="loc-original-tiffin-charge" class="form-control" placeholder="e.g. 100.00" value="${originalTiffinCharge}" oninput="app.updateLocationTiffinDiscountPreview()" style="font-weight: 600; color: #475569; background: #ffffff; border-color: #cbd5e1;">
                        <small style="color: var(--text-muted); font-size: 10.5px;">Standard base rate before discount.</small>
                    </div>
                    <div class="form-group" style="margin-bottom: 0;">
                        <label class="form-label" style="font-size: 12px; font-weight: 700; color: #b45309;">
                            Area Tiffin Charge (₹) <span style="color:var(--danger);">*</span>
                        </label>
                        <input type="number" step="any" id="loc-tiffin-charge" class="form-control" placeholder="50.00" value="${tiffinCharge}" required oninput="app.updateLocationTiffinDiscountPreview()" style="font-weight: 800; color: #b45309; background: #fffbeb; border-color: #fde68a;">
                        <small style="color: var(--text-muted); font-size: 10.5px;">Discounted price customer actually pays.</small>
                    </div>
                    <div class="form-group" style="margin-bottom: 0;">
                        <label class="form-label" style="font-size: 12px; font-weight: 700; color: #475569;">
                            Radius KM <span style="color:var(--danger);">*</span>
                        </label>
                        <input type="number" step="0.1" id="loc-radius" class="form-control" placeholder="5.0" value="${radius}">
                        <small style="color: var(--text-muted); font-size: 10.5px;">Zone radius for all plans.</small>
                    </div>
                </div>
            </div>

            <!-- Lat / Lng -->
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 16px;">
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label">Latitude</label>
                    <input type="number" step="any" id="loc-lat" class="form-control" placeholder="e.g. 18.5204" value="${lat}">
                </div>
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label">Longitude</label>
                    <input type="number" step="any" id="loc-lng" class="form-control" placeholder="e.g. 73.8567" value="${lng}">
                </div>
            </div>

            <!-- Country / Region -->
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 16px;">
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label">Country Code</label>
                    <input type="text" id="loc-country" class="form-control" placeholder="e.g. IN" value="${country}" maxlength="10">
                </div>
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label">Region / State (Optional)</label>
                    <input type="text" id="loc-region" class="form-control" placeholder="e.g. Maharashtra" value="${region}">
                </div>
            </div>

            <!-- Status -->
            <div class="form-group" style="margin-bottom: 24px;">
                <label class="form-label">Location Status</label>
                <select id="loc-status" class="form-control">
                    <option value="1" ${isActive === '1' ? 'selected' : ''}>Active</option>
                    <option value="0" ${isActive === '0' ? 'selected' : ''}>Inactive</option>
                </select>
            </div>

            <!-- Subscription Plans Nested Section -->
            <div style="border-top: 1px solid var(--border-color); padding-top: 20px; margin-top: 20px;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
                    <h4 style="font-size: 15px; font-weight: 700; color: var(--text-primary);">
                        <i class="fa-solid fa-calendar-days text-primary" style="margin-right: 6px;"></i> Subscription Plans
                        <small style="font-size: 11px; font-weight: 400; color: var(--text-muted); margin-left: 6px;">All plans inherit the radius above</small>
                    </h4>
                    <div style="display: flex; gap: 8px; flex-wrap: wrap;">
                        <button type="button" class="btn btn-secondary btn-sm" onclick="app.openImportPlansModal()" style="padding: 6px 12px; font-size: 12px; width: auto; background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0;" title="Import/Copy plans from an existing location">
                            <i class="fa-solid fa-file-import"></i> Copy FROM Existing Location
                        </button>
                        <button type="button" class="btn btn-secondary btn-sm" onclick="app.openCopyAllPlansModal()" style="padding: 6px 12px; font-size: 12px; width: auto; background: #e0e7ff; color: #3730a3; border: 1px solid #c7d2fe;" title="Copy current form's plans to other target locations">
                            <i class="fa-solid fa-copy"></i> Copy TO Other Locations
                        </button>
                        <button type="button" class="btn btn-secondary btn-sm" onclick="app.addPlanRow()" style="padding: 6px 12px; font-size: 12px; width: auto;">
                            <i class="fa-solid fa-plus"></i> Add Plan
                        </button>
                    </div>
                </div>
                <div id="modal-plans-container" style="display: flex; flex-direction: column; gap: 16px;">
                    <!-- Plan rows loaded here -->
                </div>
            </div>
        `;

        // -- Map & Autocomplete State -------------------------------------
        this._locMap = null;
        this._locMarker = null;
        this._locCircle = null;

        /**
         * Initialize or update the interactive Google Map with a draggable pin
         * and a radius circle overlay.
         */
        const initOrUpdateMap = (latVal, lngVal) => {
            const mapDiv = document.getElementById('loc-map');
            if (!mapDiv || typeof google === 'undefined' || !google.maps) return;

            const center = { lat: latVal, lng: lngVal };
            const radiusVal = parseFloat(document.getElementById('loc-radius').value) || 5.0;

            // Hide placeholder
            const placeholder = document.getElementById('loc-map-placeholder');
            if (placeholder) placeholder.style.display = 'none';

            if (!this._locMap) {
                // First-time initialization
                this._locMap = new google.maps.Map(mapDiv, {
                    center: center,
                    zoom: 14,
                    mapTypeControl: false,
                    streetViewControl: false,
                    fullscreenControl: true,
                    styles: [
                        { featureType: 'poi', stylers: [{ visibility: 'simplified' }] }
                    ]
                });

                // Draggable marker - admin can drag to correct position
                this._locMarker = new google.maps.Marker({
                    position: center,
                    map: this._locMap,
                    draggable: true,
                    title: 'Drag to adjust exact location',
                    animation: google.maps.Animation.DROP,
                    icon: {
                        url: 'https://maps.google.com/mapfiles/ms/icons/red-dot.png',
                        scaledSize: new google.maps.Size(40, 40)
                    }
                });

                // Radius circle overlay
                this._locCircle = new google.maps.Circle({
                    map: this._locMap,
                    center: center,
                    radius: radiusVal * 1000,
                    strokeColor: '#4F46E5',
                    strokeWeight: 2,
                    strokeOpacity: 0.7,
                    fillColor: '#4F46E5',
                    fillOpacity: 0.08,
                    clickable: false
                });

                // -- On marker drag end - update lat/lng fields + reverse geocode --
                this._locMarker.addListener('dragend', (event) => {
                    const newLat = event.latLng.lat().toFixed(8);
                    const newLng = event.latLng.lng().toFixed(8);
                    document.getElementById('loc-lat').value = newLat;
                    document.getElementById('loc-lng').value = newLng;
                    this._locCircle.setCenter(event.latLng);

                    // Reverse geocode the new pin position to update address
                    this.reverseGeocodePin(parseFloat(newLat), parseFloat(newLng));
                });
            } else {
                // Update existing map
                this._locMap.setCenter(center);
                this._locMap.setZoom(14);
                this._locMarker.setPosition(center);
                this._locCircle.setCenter(center);
                this._locCircle.setRadius(radiusVal * 1000);
            }

            // Fit map to show the full radius circle
            this._locMap.fitBounds(this._locCircle.getBounds());
        };

        // -- Radius input change - update circle on map ------------------
        setTimeout(() => {
            const radiusInput = document.getElementById('loc-radius');
            if (radiusInput) {
                radiusInput.addEventListener('input', () => {
                    if (this._locCircle) {
                        const newRadius = parseFloat(radiusInput.value) || 5.0;
                        this._locCircle.setRadius(newRadius * 1000);
                        if (this._locMap) {
                            this._locMap.fitBounds(this._locCircle.getBounds());
                        }
                    }
                });
            }

            // -- Manual lat/lng input change - update map ------------------
            const latInput = document.getElementById('loc-lat');
            const lngInput = document.getElementById('loc-lng');
            const updateMapFromInputs = () => {
                const latV = parseFloat(latInput?.value);
                const lngV = parseFloat(lngInput?.value);
                if (latV && lngV && !isNaN(latV) && !isNaN(lngV) && latV !== 0 && lngV !== 0) {
                    initOrUpdateMap(latV, lngV);
                }
            };
            if (latInput) latInput.addEventListener('change', updateMapFromInputs);
            if (lngInput) lngInput.addEventListener('change', updateMapFromInputs);
        }, 100);

        // -- Initialize Google Places Autocomplete on address field -------
        setTimeout(() => {
            const addressInput = document.getElementById('loc-address');
            if (addressInput && typeof google !== 'undefined' && google.maps && google.maps.places) {
                const autocomplete = new google.maps.places.Autocomplete(addressInput, {
                    types: ['geocode', 'establishment'],
                });

                autocomplete.addListener('place_changed', () => {
                    const place = autocomplete.getPlace();
                    if (place && place.geometry && place.geometry.location) {
                        const latVal = place.geometry.location.lat();
                        const lngVal = place.geometry.location.lng();
                        
                        document.getElementById('loc-lat').value = latVal.toFixed(8);
                        document.getElementById('loc-lng').value = lngVal.toFixed(8);

                        if (place.address_components) {
                            const pinComp = place.address_components.find(c => c.types.includes('postal_code'));
                            if (pinComp && pinComp.long_name) {
                                document.getElementById('loc-pincode').value = pinComp.long_name;
                            }
                            const areaComp = place.address_components.find(c => c.types.includes('sublocality') || c.types.includes('locality'));
                            if (areaComp && areaComp.long_name && !document.getElementById('loc-location-name').value) {
                                document.getElementById('loc-location-name').value = areaComp.long_name;
                            }
                            const countryComp = place.address_components.find(c => c.types.includes('country'));
                            if (countryComp && countryComp.short_name) {
                                document.getElementById('loc-country').value = countryComp.short_name;
                            }
                            const stateComp = place.address_components.find(c => c.types.includes('administrative_area_level_1'));
                            if (stateComp && stateComp.long_name) {
                                document.getElementById('loc-region').value = stateComp.long_name;
                            }
                        }

                        // Initialize/update the interactive map with draggable pin
                        initOrUpdateMap(latVal, lngVal);
                    }
                });
            }

            // If editing an existing record with coordinates, show the map immediately
            if (lat && lng && parseFloat(lat) !== 0 && parseFloat(lng) !== 0) {
                initOrUpdateMap(parseFloat(lat), parseFloat(lng));
            }
        }, 200);

        // -- Load plan rows ----------------------------------------------
        const container = document.getElementById('modal-plans-container');
        container.innerHTML = '';

        if (plans.length > 0) {
            plans.forEach(p => this.addPlanRow(p));
        } else {
            container.innerHTML = '<p id="no-plans-msg" style="font-size: 12px; color: var(--text-secondary); margin: 8px 0;"><i class="fa-solid fa-circle-info" style="margin-right: 4px;"></i> No subscription plans added yet. Click "+ Add Subscription Plan" below if you wish to add a plan for this service area.</p>';
        }

        // Trigger live tiffin discount preview calculation
        this.updateLocationTiffinDiscountPreview();
    }

    /**
     * Calculate and display real-time discount percentage when original or area tiffin charge changes
     */
    updateLocationTiffinDiscountPreview() {
        const origInput = document.getElementById('loc-original-tiffin-charge');
        const currInput = document.getElementById('loc-tiffin-charge');
        const badge = document.getElementById('loc-tiffin-discount-badge');
        if (!origInput || !currInput || !badge) return;

        const orig = parseFloat(origInput.value) || 0.0;
        const curr = parseFloat(currInput.value) || 0.0;

        if (orig > curr && curr >= 0 && orig > 0) {
            const discountPct = Math.round(((orig - curr) / orig) * 100);
            const savings = (orig - curr).toFixed(2);
            badge.innerHTML = `
                <span class="badge" style="background: #dcfce7; color: #15803d; border: 1px solid #86efac; font-weight: 800; font-size: 11.5px; padding: 4px 10px; border-radius: 12px; display: inline-flex; align-items: center; gap: 4px;">
                    <i class="fa-solid fa-tag"></i> ${discountPct}% OFF (Customer saves ₹${savings})
                </span>
            `;
        } else if (orig > 0 && orig <= curr) {
            badge.innerHTML = `
                <span class="badge" style="background: #f1f5f9; color: #64748b; font-size: 11px; padding: 3px 8px; border-radius: 12px;">
                    No Discount
                </span>
            `;
        } else {
            badge.innerHTML = '';
        }
    }

    /**
     * Reverse geocode a dragged pin position and update the address field.
     * Uses the backend geocode API endpoint for server-side reverse geocoding.
     */
    async reverseGeocodePin(lat, lng) {
        try {
            const result = await api.reverseGeocodeCoords(lat, lng);
            if (result.success && result.data) {
                const d = result.data;
                if (d.formatted_address) {
                    document.getElementById('loc-address').value = d.formatted_address;
                }
                if (d.pincode) {
                    const pinInput = document.getElementById('loc-pincode');
                    if (pinInput && !pinInput.value) pinInput.value = d.pincode;
                }
                if (d.country) {
                    document.getElementById('loc-country').value = d.country;
                }
                if (d.region) {
                    document.getElementById('loc-region').value = d.region;
                }
            }
        } catch (e) {
            // Silently fail - reverse geocoding is a convenience, not critical
            console.warn('Reverse geocode failed:', e.message);
        }
    }

    addPlanRow(planData = null) {
        const container = document.getElementById('modal-plans-container');
        if (!container) return;

        const noPlansMsg = document.getElementById('no-plans-msg');
        if (noPlansMsg) noPlansMsg.remove();

        const index = container.querySelectorAll('.plan-form-card').length;
        const card = document.createElement('div');
        card.className = 'plan-form-card';
        card.id = `plan-card-${index}`;
        card.style = 'background: var(--bg-secondary); border: 1px solid var(--border-color); border-radius: var(--radius-md); padding: 16px; position: relative; margin-bottom: 12px;';

        const pId      = planData ? planData.id : '';
        const name     = planData ? planData.plan_name : '';
        const desc     = planData ? planData.description : '';
        const price    = planData ? planData.price : '1200.00';
        const duration   = planData ? planData.duration : '30';
        const deliveries = planData ? planData.total_deliveries : '30';
        const meals    = planData ? planData.meals_per_day : '1';
        const mealType = planData ? planData.meal_type : 'VEG';
        const slot     = planData ? (planData.delivery_time_slot || '12:00 PM - 02:00 PM') : '12:00 PM - 02:00 PM';
        const discount = planData ? planData.discount : '0.00';
        const charge   = planData ? planData.delivery_charge : '0.00';
        // Support both new (status='active') and old (is_active=true) formats
        const isActive = planData
            ? (planData.status === 'active' || planData.is_active === true || planData.is_active === 1 ? '1' : '0')
            : '1';

        card.innerHTML = `
            <button type="button" class="btn btn-secondary btn-sm" onclick="app.openReplicatePlanModal(${index})" style="position: absolute; top: 12px; right: 46px; font-size: 11px; padding: 3px 8px; height: 26px; display: inline-flex; align-items: center; gap: 4px; background: #e0e7ff; color: #3730a3; border: 1px solid #c7d2fe;" title="Replicate Plan to Other Locations">
                <i class="fa-solid fa-copy"></i> Replicate
            </button>
            <button type="button" class="btn btn-icon btn-danger btn-sm" onclick="app.removePlanRow(${index})" style="position: absolute; top: 12px; right: 12px; border-radius: 50%; width: 26px; height: 26px; min-width: 0; padding: 0; display: flex; align-items: center; justify-content: center;" title="Remove Plan">
                <i class="fa-solid fa-trash-can" style="font-size: 11px;"></i>
            </button>
            <h5 style="font-size: 12px; font-weight: 700; color: var(--accent-primary); margin-bottom: 12px;">Plan #${index + 1}</h5>
            
            <input type="hidden" class="plan-id" value="${pId}">
            
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 12px;">
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label" style="font-size: 11px; margin-bottom: 4px;">Plan Name</label>
                    <input type="text" class="form-control plan-name" placeholder="e.g. Standard Monthly" value="${name}" required style="padding: 8px 12px; font-size: 13px;">
                </div>
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label" style="font-size: 11px; margin-bottom: 4px;">Price (₹)</label>
                    <input type="number" class="form-control plan-price" value="${price}" required style="padding: 8px 12px; font-size: 13px;">
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 12px;">
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label" style="font-size: 11px; margin-bottom: 4px;">Duration (Days)</label>
                    <input type="number" class="form-control plan-duration" value="${duration}" required style="padding: 8px 12px; font-size: 13px;">
                </div>
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label" style="font-size: 11px; margin-bottom: 4px;">Total Deliveries</label>
                    <input type="number" class="form-control plan-deliveries" value="${deliveries}" required style="padding: 8px 12px; font-size: 13px;">
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 12px;">
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label" style="font-size: 11px; margin-bottom: 4px;">Meals Per Day</label>
                    <input type="number" class="form-control plan-meals" value="${meals}" required style="padding: 8px 12px; font-size: 13px;">
                </div>
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label" style="font-size: 11px; margin-bottom: 4px;">Meal Type</label>
                    <select class="form-control plan-meal-type" style="padding: 8px 12px; font-size: 13px;">
                        <option value="VEG" ${mealType === 'VEG' ? 'selected' : ''}>VEG</option>
                        <option value="NON-VEG" ${mealType === 'NON-VEG' ? 'selected' : ''}>NON-VEG</option>
                        <option value="BOTH" ${mealType === 'BOTH' ? 'selected' : ''}>BOTH</option>
                    </select>
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 12px;">
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label" style="font-size: 11px; margin-bottom: 4px;">Delivery Time Slot</label>
                    <input type="text" class="form-control plan-slot" value="${slot}" required style="padding: 8px 12px; font-size: 13px;">
                </div>
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label" style="font-size: 11px; margin-bottom: 4px;">Plan Status</label>
                    <select class="form-control plan-status" style="padding: 8px 12px; font-size: 13px;">
                        <option value="1" ${isActive === '1' ? 'selected' : ''}>Active</option>
                        <option value="0" ${isActive === '0' ? 'selected' : ''}>Deactivated</option>
                    </select>
                </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 12px;">
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label" style="font-size: 11px; margin-bottom: 4px;">Discount (%)</label>
                    <input type="number" step="any" class="form-control plan-discount" value="${discount}" required style="padding: 8px 12px; font-size: 13px;">
                </div>
                <div class="form-group" style="margin-bottom: 0;">
                    <label class="form-label" style="font-size: 11px; margin-bottom: 4px;">Delivery Charge (₹)</label>
                    <input type="number" step="any" class="form-control plan-charge" value="${charge}" required style="padding: 8px 12px; font-size: 13px;">
                </div>
            </div>

            <div class="form-group" style="margin-bottom: 0;">
                <label class="form-label" style="font-size: 11px; margin-bottom: 4px;">Plan Description (Optional)</label>
                <textarea class="form-control plan-desc" rows="1" placeholder="Describe inclusions..." style="padding: 8px 12px; font-size: 13px; resize: vertical;">${desc}</textarea>
            </div>
        `;

        container.appendChild(card);
    }

    removePlanRow(index) {
        const card = document.getElementById(`plan-card-${index}`);
        if (card) {
            card.remove();
            const container = document.getElementById('modal-plans-container');
            const remaining = container.querySelectorAll('.plan-form-card');
            remaining.forEach((child, i) => {
                child.id = `plan-card-${i}`;
                child.querySelector('h5').textContent = `Plan #${i + 1}`;
                child.querySelector('button').setAttribute('onclick', `app.removePlanRow(${i})`);
            });
            if (remaining.length === 0) {
                container.innerHTML = '<p id="no-plans-msg" style="font-size: 12px; color: var(--text-secondary); margin: 8px 0;"><i class="fa-solid fa-circle-info" style="margin-right: 4px;"></i> No subscription plans added yet. Click "+ Add Subscription Plan" below if you wish to add a plan for this service area.</p>';
            }
        }
    }

    async handleLocationFormSubmit(e) {
        e.preventDefault();

        const locationNameVal = (document.getElementById('loc-location-name')?.value || '').trim();
        const addressVal      = (document.getElementById('loc-address')?.value || '').trim();
        const latVal          = parseFloat(document.getElementById('loc-lat')?.value) || 0.0;
        const lngVal          = parseFloat(document.getElementById('loc-lng')?.value) || 0.0;
        const radiusVal               = parseFloat(document.getElementById('loc-radius')?.value) || 5.0;
        const tiffinChargeVal         = parseFloat(document.getElementById('loc-tiffin-charge')?.value) || 50.0;
        const originalTiffinChargeVal = parseFloat(document.getElementById('loc-original-tiffin-charge')?.value) || 0.0;
        const countryVal              = (document.getElementById('loc-country')?.value || 'IN').trim();
        const regionVal               = (document.getElementById('loc-region')?.value || '').trim();
        const statusVal               = document.getElementById('loc-status')?.value === '1' ? 'active' : 'inactive';

        if (!locationNameVal) {
            this.showToast('Location name is required.', 'error');
            return;
        }
        if (!latVal || !lngVal) {
            this.showToast('Please search and select an address to set coordinates.', 'error');
            return;
        }

        // Build payload for new service-locations/save endpoint
        const payload = {
            id:                     this.currentLocationEditId || undefined,
            location_name:          locationNameVal,
            address:                addressVal,
            latitude:               latVal,
            longitude:              lngVal,
            radius_km:              radiusVal,
            tiffin_charge:          tiffinChargeVal,
            original_tiffin_charge: originalTiffinChargeVal,
            country:                countryVal || 'IN',
            region:                 regionVal,
            status:                 statusVal,
            plans:                  []
        };

        // Gather plans
        const planCards = document.querySelectorAll('#modal-plans-container .plan-form-card');
        planCards.forEach(card => {
            const planId = card.querySelector('.plan-id').value;
            payload.plans.push({
                id:                     planId ? parseInt(planId) : null,
                plan_name:              card.querySelector('.plan-name').value,
                price:                  parseFloat(card.querySelector('.plan-price').value),
                duration:               parseInt(card.querySelector('.plan-duration').value),
                total_deliveries:       parseInt(card.querySelector('.plan-deliveries').value),
                meals_per_day:          parseInt(card.querySelector('.plan-meals').value),
                meal_type:              card.querySelector('.plan-meal-type').value,
                delivery_time_slot:     card.querySelector('.plan-slot').value,
                status:                 card.querySelector('.plan-status').value === '1' ? 'active' : 'inactive',
                discount:               parseFloat(card.querySelector('.plan-discount').value),
                delivery_charge:        parseFloat(card.querySelector('.plan-charge').value),
                tiffin_charge:          tiffinChargeVal,
                original_tiffin_charge: originalTiffinChargeVal,
                description:            card.querySelector('.plan-desc').value
            });
        });

        this.showLoader(true);
        try {
            const res = await api.saveServiceLocation(payload);
            const msg = res.message || 'Service location and plans saved successfully.';
            if (res.data && res.data.warning) {
                this.showToast(res.data.warning, 'warning');
            } else {
                this.showToast(msg, 'success');
            }
            this.closeModal('location-modal');
            await this.fetchLocationList();
        } catch (error) {
            this.showToast(error.message, 'error');
        } finally {
            this.showLoader(false);
        }
    }
    openImportPlansModal() {
        const select = document.getElementById('import-source-location-select');
        if (!select) return;

        select.innerHTML = '';
        const currentLocId = this.currentLocationEditId;

        // Filter locations that have plans
        const locsWithPlans = (this.currentLocationList || []).filter(l => l.id !== currentLocId && Array.isArray(l.plans) && l.plans.length > 0);

        if (locsWithPlans.length === 0) {
            this.showToast('No other existing locations with plans found to copy from.', 'warning');
            return;
        }

        locsWithPlans.forEach(loc => {
            const opt = document.createElement('option');
            opt.value = loc.id;
            opt.textContent = `${loc.location_name} (${loc.plans.length} plan(s) available)`;
            select.appendChild(opt);
        });

        this.openModal('import-plans-modal');
    }

    handleImportPlansSubmit(e) {
        e.preventDefault();

        const select = document.getElementById('import-source-location-select');
        const sourceLocId = parseInt(select?.value || '0');

        if (!sourceLocId) {
            this.showToast('Please select a source location.', 'warning');
            return;
        }

        const sourceLoc = (this.currentLocationList || []).find(l => l.id === sourceLocId);
        if (!sourceLoc || !Array.isArray(sourceLoc.plans) || sourceLoc.plans.length === 0) {
            this.showToast('No plans found in selected location.', 'error');
            return;
        }

        // Add each plan from source location into current form
        sourceLoc.plans.forEach(planData => {
            // Copy without plan.id so it creates new plan records for current location
            const planCopy = {
                plan_name:          planData.plan_name || '',
                description:        planData.description || '',
                price:             planData.price || '0.00',
                duration:          planData.duration || '30',
                total_deliveries:  planData.total_deliveries || '30',
                meals_per_day:     planData.meals_per_day || '1',
                meal_type:         planData.meal_type || 'VEG',
                delivery_time_slot: planData.delivery_time_slot || '12:00 PM - 02:00 PM',
                discount:          planData.discount || '0.00',
                delivery_charge:   planData.delivery_charge || '0.00',
                status:            planData.status || 'active'
            };
            this.addPlanRow(planCopy);
        });

        this.showToast(`Imported ${sourceLoc.plans.length} plan(s) from "${sourceLoc.location_name}" successfully.`, 'success');
        this.closeModal('import-plans-modal');
    }

    openCopyAllPlansModal() {
        const planCards = document.querySelectorAll('.plan-form-card');
        if (planCards.length === 0) {
            this.showToast('Please add at least one subscription plan to copy.', 'warning');
            return;
        }

        const plans = [];
        let missingName = false;

        planCards.forEach((card) => {
            const planName = (card.querySelector('.plan-name')?.value || '').trim();
            if (!planName) missingName = true;

            plans.push({
                plan_name:          planName,
                price:             parseFloat(card.querySelector('.plan-price')?.value) || 0,
                duration:          parseInt(card.querySelector('.plan-duration')?.value) || 30,
                total_deliveries:  parseInt(card.querySelector('.plan-deliveries')?.value) || 30,
                meals_per_day:     parseInt(card.querySelector('.plan-meals')?.value) || 1,
                meal_type:         card.querySelector('.plan-meal-type')?.value || 'VEG',
                delivery_time_slot: card.querySelector('.plan-slot')?.value || '',
                status:            card.querySelector('.plan-status')?.value === '1' ? 'active' : 'inactive',
                discount:          parseFloat(card.querySelector('.plan-discount')?.value) || 0,
                delivery_charge:   parseFloat(card.querySelector('.plan-charge')?.value) || 0,
                tiffin_charge:     parseFloat(document.getElementById('loc-tiffin-charge')?.value) || 50,
                description:       card.querySelector('.plan-desc')?.value || ''
            });
        });

        if (missingName) {
            this.showToast('Please enter a Plan Name for all defined plans before copying.', 'warning');
            return;
        }

        this.activeReplicatePlansData = plans;

        // Display banner details
        const nameDisp = document.getElementById('replicate-plan-name-display');
        const detailsDisp = document.getElementById('replicate-plan-details-display');
        if (nameDisp) nameDisp.textContent = `${plans.length} Subscription Plan(s) Ready to Copy`;
        if (detailsDisp) {
            detailsDisp.textContent = plans.map(p => `• ${p.plan_name} (₹${p.price}, ${p.duration}d, ${p.meal_type})`).join(' | ');
        }

        // Build target locations list - UNCHECKED BY DEFAULT
        const container = document.getElementById('replicate-target-locations-list');
        if (container) {
            container.innerHTML = '';

            const currentLocId = this.currentLocationEditId;
            const availableLocs = (this.currentLocationList || []).filter(l => l.id !== currentLocId && l.status === 'active');

            if (availableLocs.length === 0) {
                container.innerHTML = '<p style="font-size: 12px; color: var(--text-muted); grid-column: 1 / -1; text-align: center; margin: 12px 0;"><i class="fa-solid fa-circle-info" style="margin-right: 4px;"></i> No other active service locations found.</p>';
            } else {
                availableLocs.forEach(loc => {
                    const item = document.createElement('label');
                    item.style = 'display: flex; align-items: center; gap: 8px; font-size: 12.5px; cursor: pointer; background: var(--bg-primary); padding: 8px 10px; border-radius: 6px; border: 1px solid var(--border-color);';
                    item.innerHTML = `
                        <input type="checkbox" class="replicate-loc-checkbox" value="${loc.id}">
                        <span><strong>${loc.location_name}</strong> <small style="color: var(--text-muted); font-size: 11px;">(${loc.radius_km} km radius)</small></span>
                    `;
                    container.appendChild(item);
                });
            }
        }

        this.openModal('replicate-plan-modal');
    }

    openReplicatePlanModal(planIndex) {
        const card = document.getElementById(`plan-card-${planIndex}`);
        if (!card) return;

        const planName = (card.querySelector('.plan-name')?.value || '').trim();
        if (!planName) {
            this.showToast('Please enter a Plan Name before replicating.', 'warning');
            return;
        }

        const planData = {
            plan_name:          planName,
            price:             parseFloat(card.querySelector('.plan-price')?.value) || 0,
            duration:          parseInt(card.querySelector('.plan-duration')?.value) || 30,
            total_deliveries:  parseInt(card.querySelector('.plan-deliveries')?.value) || 30,
            meals_per_day:     parseInt(card.querySelector('.plan-meals')?.value) || 1,
            meal_type:         card.querySelector('.plan-meal-type')?.value || 'VEG',
            delivery_time_slot: card.querySelector('.plan-slot')?.value || '',
            status:            card.querySelector('.plan-status')?.value === '1' ? 'active' : 'inactive',
            discount:          parseFloat(card.querySelector('.plan-discount')?.value) || 0,
            delivery_charge:   parseFloat(card.querySelector('.plan-charge')?.value) || 0,
            tiffin_charge:     parseFloat(document.getElementById('loc-tiffin-charge')?.value) || 50,
            description:       card.querySelector('.plan-desc')?.value || ''
        };

        this.activeReplicatePlansData = [planData];

        // Display banner details
        const nameDisp = document.getElementById('replicate-plan-name-display');
        const detailsDisp = document.getElementById('replicate-plan-details-display');
        if (nameDisp) nameDisp.textContent = `1 Subscription Plan Ready to Copy: ${planData.plan_name}`;
        if (detailsDisp) {
            detailsDisp.textContent = `₹${planData.price} | ${planData.duration} Days | ${planData.total_deliveries} Deliveries | ${planData.meal_type} | ${planData.delivery_time_slot}`;
        }

        // Build target locations list - UNCHECKED BY DEFAULT
        const container = document.getElementById('replicate-target-locations-list');
        if (container) {
            container.innerHTML = '';

            const currentLocId = this.currentLocationEditId;
            const availableLocs = (this.currentLocationList || []).filter(l => l.id !== currentLocId && l.status === 'active');

            if (availableLocs.length === 0) {
                container.innerHTML = '<p style="font-size: 12px; color: var(--text-muted); grid-column: 1 / -1; text-align: center; margin: 12px 0;"><i class="fa-solid fa-circle-info" style="margin-right: 4px;"></i> No other active service locations found.</p>';
            } else {
                availableLocs.forEach(loc => {
                    const item = document.createElement('label');
                    item.style = 'display: flex; align-items: center; gap: 8px; font-size: 12.5px; cursor: pointer; background: var(--bg-primary); padding: 8px 10px; border-radius: 6px; border: 1px solid var(--border-color);';
                    item.innerHTML = `
                        <input type="checkbox" class="replicate-loc-checkbox" value="${loc.id}">
                        <span><strong>${loc.location_name}</strong> <small style="color: var(--text-muted); font-size: 11px;">(${loc.radius_km} km radius)</small></span>
                    `;
                    container.appendChild(item);
                });
            }
        }

        this.openModal('replicate-plan-modal');
    }

    toggleAllReplicateLocations(select) {
        const checkboxes = document.querySelectorAll('.replicate-loc-checkbox');
        checkboxes.forEach(cb => cb.checked = select);
    }

    async handleReplicatePlanSubmit(e) {
        e.preventDefault();

        if (!this.activeReplicatePlansData || this.activeReplicatePlansData.length === 0) {
            this.showToast('No plan data selected for copying.', 'error');
            return;
        }

        const checkboxes = document.querySelectorAll('.replicate-loc-checkbox:checked');
        const targetIds = Array.from(checkboxes).map(cb => parseInt(cb.value));

        if (targetIds.length === 0) {
            this.showToast('Please select at least one location name using checkboxes.', 'warning');
            return;
        }

        this.showLoader(true);
        try {
            const res = await api.replicatePlan({
                plans: this.activeReplicatePlansData,
                target_location_ids: targetIds
            });

            this.showToast(res.message || 'Plans copied successfully.', 'success');
            this.closeModal('replicate-plan-modal');
            await this.fetchLocationList();
        } catch (error) {
            this.showToast(error.message || 'Failed to copy plans.', 'error');
        } finally {
            this.showLoader(false);
        }
    }
    async toggleLocationStatus(id, currentStatus) {
        this.showLoader(true);
        try {
            const newStatus = currentStatus ? 'inactive' : 'active';
            await api.saveServiceLocation({ id, status: newStatus, plans: [] });
            this.showToast(`Service location status updated to ${newStatus}.`, 'success');
            await this.fetchLocationList();
        } catch (error) {
            this.showToast('Failed to change status: ' + error.message, 'error');
        } finally {
            this.showLoader(false);
        }
    }
    openLocationDeleteModal(id) {
        this.selectedDeleteId = id;
        this.selectedDeleteType = 'service_location';
        this.openModal('delete-modal');
    }

    getTabLabelSingle(tab) {
        return 'Service Area';
    }

    /* -- Push Notification Broadcast View (Zomato/Swiggy Style) ----------- */

    async loadNotificationsView(container) {
        container.innerHTML = `
        <style>
            .notif-section { background: var(--bg-card, #fff); border-radius: 18px; padding: 28px; box-shadow: 0 4px 24px rgba(0,0,0,0.07); margin-bottom: 24px; }
            .notif-label { font-size: 13px; font-weight: 700; color: var(--text-secondary, #64748b); text-transform: uppercase; letter-spacing: 0.8px; margin-bottom: 8px; display: block; }
            .notif-input { width: 100%; padding: 13px 16px; border: 2px solid #e2e8f0; border-radius: 12px; font-size: 14px; font-family: inherit; transition: border-color 0.2s, box-shadow 0.2s; box-sizing: border-box; background: #f8fafc; }
            .notif-input:focus { border-color: #FF6B35; box-shadow: 0 0 0 3px rgba(255,107,53,0.12); outline: none; background: #fff; }
            .target-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; }
            .target-pill { display: flex; align-items: center; gap: 10px; padding: 14px 16px; border: 2px solid #e2e8f0; border-radius: 12px; cursor: pointer; transition: all 0.2s; font-weight: 600; font-size: 13px; }
            .target-pill:has(input:checked) { border-color: #FF6B35; background: #fff5f0; color: #FF6B35; }
            .target-pill input { accent-color: #FF6B35; width: 16px; height: 16px; }
            .emoji-bar { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
            .emoji-btn { font-size: 20px; cursor: pointer; padding: 4px 8px; border-radius: 8px; border: 1.5px solid #e2e8f0; background: #f8fafc; transition: all 0.15s; line-height: 1; }
            .emoji-btn:hover { background: #fff5f0; border-color: #FF6B35; transform: scale(1.2); }
            .color-swatch { width: 32px; height: 32px; border-radius: 50%; cursor: pointer; border: 3px solid transparent; transition: all 0.15s; flex-shrink: 0; }
            .color-swatch.active { border-color: #1e293b; transform: scale(1.18); box-shadow: 0 2px 8px rgba(0,0,0,0.2); }
            .action-btn-row { display: grid; grid-template-columns: 1fr 1fr auto; gap: 8px; align-items: end; margin-bottom: 8px; }
            .add-action-btn { display: flex; align-items: center; gap: 6px; padding: 10px 14px; border: 2px dashed #e2e8f0; border-radius: 10px; background: transparent; color: #64748b; cursor: pointer; font-size: 13px; font-weight: 600; transition: all 0.2s; width: 100%; justify-content: center; }
            .add-action-btn:hover { border-color: #FF6B35; color: #FF6B35; background: #fff5f0; }
            .del-btn { padding: 10px 12px; background: #fee2e2; border: none; border-radius: 10px; color: #ef4444; cursor: pointer; font-size: 14px; transition: background 0.2s; }
            .del-btn:hover { background: #fca5a5; }
            /* Phone preview */
            .phone-wrap { position: relative; width: 280px; margin: 0 auto; }
            .phone-body { background: #1e293b; border-radius: 40px; padding: 16px; box-shadow: 0 20px 60px rgba(0,0,0,0.5), inset 0 0 0 2px rgba(255,255,255,0.08); }
            .phone-screen { background: linear-gradient(145deg, #0f172a, #1e293b); border-radius: 28px; overflow: hidden; min-height: 420px; padding: 12px; }
            .status-bar { display: flex; justify-content: space-between; align-items: center; padding: 8px 4px; margin-bottom: 8px; }
            .notch { width: 60px; height: 8px; background: #0f172a; border-radius: 10px; margin: 0 auto; }
            .notif-card-preview { background: rgba(255,255,255,0.13); backdrop-filter: blur(20px); border-radius: 18px; padding: 14px 16px; border: 1px solid rgba(255,255,255,0.18); animation: slideInDown 0.4s ease; }
            @keyframes slideInDown { from { opacity: 0; transform: translateY(-16px); } to { opacity: 1; transform: translateY(0); } }
            .notif-top-row { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; }
            .notif-app-info { display: flex; align-items: center; gap: 6px; }
            .notif-app-icon { width: 18px; height: 18px; border-radius: 6px; object-fit: cover; }
            .notif-app-name { font-size: 11px; font-weight: 800; color: #94a3b8; letter-spacing: 0.5px; text-transform: uppercase; }
            .notif-time { font-size: 11px; color: #64748b; }
            .notif-preview-title { font-size: 14px; font-weight: 800; color: #f8fafc; margin-bottom: 3px; line-height: 1.3; }
            .notif-preview-body { font-size: 12px; color: #cbd5e1; line-height: 1.4; margin-bottom: 10px; }
            .notif-preview-image { width: 100%; border-radius: 12px; object-fit: cover; display: none; margin-bottom: 10px; }
            .notif-action-btns { display: flex; gap: 6px; flex-wrap: wrap; }
            .notif-action-btn-preview { padding: 6px 12px; border-radius: 20px; font-size: 11px; font-weight: 700; border: none; cursor: default; letter-spacing: 0.3px; }
            .history-thumb { width: 44px; height: 44px; border-radius: 10px; object-fit: cover; }
        </style>

        <div class="dashboard-banner" style="margin-bottom: 24px;">
            <h2 class="banner-title"><i class="fa-solid fa-bullhorn" style="margin-right: 10px;"></i> Broadcast Notification Center</h2>
            <p class="banner-desc">Send rich push notifications filtered by Target Role, State, District, and Taluka to customers, vendors, or drivers.</p>
        </div>

        <div style="display: grid; grid-template-columns: 1fr 300px; gap: 24px; align-items: start;">
            <!-- LEFT: Composer -->
            <div>
                <!-- Target & Location Filters Section -->
                <div class="notif-section">
                    <span class="notif-label"><i class="fa-solid fa-users" style="margin-right: 6px;"></i> 1. Target Audience & Role</span>
                    <div class="target-grid" style="margin-bottom: 20px;">
                        <label class="target-pill"><input type="radio" name="notif-target" value="all" checked onchange="app.onNotifTargetChange()"> All App Users</label>
                        <label class="target-pill"><input type="radio" name="notif-target" value="customers" onchange="app.onNotifTargetChange()"> Customers Only</label>
                        <label class="target-pill"><input type="radio" name="notif-target" value="vendors" onchange="app.onNotifTargetChange()"> Vendors Only</label>
                        <label class="target-pill"><input type="radio" name="notif-target" value="drivers" onchange="app.onNotifTargetChange()"> Drivers Only</label>
                    </div>

                    <span class="notif-label"><i class="fa-solid fa-map-location-dot" style="margin-right: 6px;"></i> 2. Geographic Location Filters (State, District & Taluka)</span>
                    <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; margin-bottom: 20px;">
                        <div>
                            <label class="notif-label" style="font-size: 11px;">State</label>
                            <select id="notif-state" class="notif-input" onchange="app.onNotifLocationFilterChange('state')">
                                <option value="all">All States</option>
                                <option value="Maharashtra" selected>Maharashtra</option>
                                <option value="Gujarat">Gujarat</option>
                                <option value="Karnataka">Karnataka</option>
                                <option value="Tamil Nadu">Tamil Nadu</option>
                                <option value="Uttar Pradesh">Uttar Pradesh</option>
                                <option value="Rajasthan">Rajasthan</option>
                                <option value="Madhya Pradesh">Madhya Pradesh</option>
                                <option value="Delhi">Delhi</option>
                            </select>
                        </div>
                        <div>
                            <label class="notif-label" style="font-size: 11px;">District</label>
                            <select id="notif-district" class="notif-input" onchange="app.onNotifLocationFilterChange('district')">
                                <option value="all">All Districts</option>
                            </select>
                        </div>
                        <div>
                            <label class="notif-label" style="font-size: 11px;">Taluka</label>
                            <select id="notif-taluka" class="notif-input" onchange="app.onNotifLocationFilterChange('taluka')">
                                <option value="all">All Talukas</option>
                            </select>
                        </div>
                    </div>

                    <!-- Live Target Counter Card & View List Button -->
                    <div id="notif-target-counter-box" style="background: linear-gradient(135deg, #f8fafc 0%, #fff5f0 100%); border: 2px dashed #FF6B35; border-radius: 16px; padding: 18px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 14px; box-shadow: 0 4px 15px rgba(255,107,53,0.06);">
                        <div>
                            <div style="font-size: 14px; font-weight: 800; color: #1e293b; display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
                                <span style="font-size: 22px; color: #FF6B35; font-weight: 900;" id="notif-target-total-count">...</span> Targeted Recipients 
                                <span id="notif-target-fcm-count" style="font-size: 12px; background: #dcfce7; color: #15803d; padding: 4px 12px; border-radius: 20px; font-weight: 700; border: 1px solid #bbf7d0;">(0 Devices Registered for FCM)</span>
                            </div>
                            <div id="notif-target-breakdown" style="display: flex; gap: 12px; font-size: 12px; color: #64748b; margin-top: 8px; flex-wrap: wrap;">
                                <span><i class="fa-solid fa-users text-primary"></i> Customers: <b id="notif-count-cust">0</b></span>
                                <span><i class="fa-solid fa-store text-warning"></i> Vendors: <b id="notif-count-vend">0</b></span>
                                <span><i class="fa-solid fa-motorcycle text-success"></i> Drivers: <b id="notif-count-driv">0</b></span>
                            </div>
                        </div>
                        <button type="button" class="btn btn-secondary btn-sm" onclick="app.openNotificationRecipientsModal()" style="padding: 11px 20px; border-radius: 12px; font-weight: 800; display: flex; align-items: center; gap: 8px; font-size: 13px; background: #ffffff; color: #1e293b; border: 1.5px solid #cbd5e1; box-shadow: 0 2px 8px rgba(0,0,0,0.06); cursor: pointer; transition: all 0.2s;">
                            <i class="fa-solid fa-users-viewfinder" style="color: #FF6B35; font-size: 15px;"></i> View Recipient List
                        </button>
                    </div>
                </div>

                <!-- Content -->
                <div class="notif-section">
                    <span class="notif-label"><i class="fa-solid fa-envelope-open-text" style="margin-right: 6px;"></i> 3. Notification Content</span>

                    <div style="margin-bottom: 18px;">
                        <label class="notif-label" style="font-size: 12px;">Title</label>
                        <input type="text" id="notif-title" class="notif-input" placeholder="e.g. Flat 40% Off Today Only!" oninput="app.updateNotificationPreview()">
                        <div class="emoji-bar" style="margin-top: 8px;">
                            ${['🎉','🔥','📢','🛵','🍲','⏰','🍕','🍔','🥗','🎁','💬','❤️','👉','⏳','🍽️'].map(e => `<span class="emoji-btn" onclick="app.insertEmoji('notif-title','${e}')">${e}</span>`).join('')}
                        </div>
                    </div>

                    <div style="margin-bottom: 0;">
                        <label class="notif-label" style="font-size: 12px;">Message Body</label>
                        <textarea id="notif-body" class="notif-input" rows="3" placeholder="e.g. Use code HUNGRY40 and get 40% off on your next order. Limited time offer!" oninput="app.updateNotificationPreview()" style="resize: vertical;"></textarea>
                    </div>
                </div>

                <!-- Image -->
                <div class="notif-section">
                    <span class="notif-label"><i class="fa-solid fa-image" style="margin-right: 6px;"></i> 4. Banner Image (Big Picture Style)</span>
                    
                    <!-- File Upload & Drag-and-Drop Area -->
                    <div id="notif-image-dropzone" style="border: 2px dashed #cbd5e1; border-radius: 14px; padding: 18px; text-align: center; background: #f8fafc; cursor: pointer; transition: all 0.2s; margin-bottom: 12px;" onclick="document.getElementById('notif-image-file').click()" ondragover="event.preventDefault(); this.style.borderColor='#FF6B35'; this.style.background='#fff7ed';" ondragleave="this.style.borderColor='#cbd5e1'; this.style.background='#f8fafc';" ondrop="app.handleNotificationImageDrop(event)">
                        <input type="file" id="notif-image-file" accept="image/*" style="display: none;" onchange="app.handleNotificationImageFile(this)">
                        <div id="notif-upload-idle">
                            <i class="fa-solid fa-cloud-arrow-up" style="font-size: 26px; color: #FF6B35; margin-bottom: 8px;"></i>
                            <div style="font-size: 13px; font-weight: 700; color: #1e293b;">Click to upload image or drag & drop</div>
                            <div style="font-size: 11px; color: #64748b; margin-top: 2px;">Supports JPG, PNG, WEBP, GIF (Max 10MB)</div>
                        </div>
                        <div id="notif-upload-loading" style="display: none;">
                            <i class="fa-solid fa-spinner fa-spin" style="font-size: 24px; color: #FF6B35; margin-bottom: 6px;"></i>
                            <div style="font-size: 12px; font-weight: 700; color: #1e293b;">Uploading banner image...</div>
                        </div>
                    </div>

                    <!-- Image Preview & Status Badge -->
                    <div id="notif-uploaded-preview" style="display: none; align-items: center; justify-content: space-between; background: #f1f5f9; padding: 10px 14px; border-radius: 10px; margin-bottom: 12px;">
                        <div style="display: flex; align-items: center; gap: 10px; overflow: hidden;">
                            <img id="notif-uploaded-thumb" src="" style="width: 44px; height: 44px; object-fit: cover; border-radius: 8px; border: 1px solid #cbd5e1;">
                            <div style="overflow: hidden;">
                                <div id="notif-uploaded-filename" style="font-size: 12px; font-weight: 700; color: #0f172a; text-overflow: ellipsis; overflow: hidden; white-space: nowrap; max-width: 250px;">Image attached</div>
                                <div style="font-size: 11px; color: #10B981; font-weight: 600;"><i class="fa-solid fa-circle-check"></i> Ready to send</div>
                            </div>
                        </div>
                        <button type="button" class="btn btn-sm btn-secondary" onclick="app.clearNotificationImage()" style="font-size: 12px; color: #ef4444; padding: 5px 10px;">
                            <i class="fa-solid fa-trash-can"></i> Remove
                        </button>
                    </div>

                    <!-- Direct URL input & Preset Buttons -->
                    <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 6px;">
                        <label class="notif-label" style="font-size: 11px; margin-bottom: 0;">Or paste image URL</label>
                        <span style="font-size: 11px; color: #94a3b8;">Presets:</span>
                    </div>
                    <input type="url" id="notif-image-url" class="notif-input" placeholder="https://your-cdn.com/promo-banner.jpg" oninput="app.updateNotificationPreview()" style="margin-bottom: 10px;">
                    <div style="display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 4px;">
                        <button type="button" class="btn btn-sm btn-secondary" onclick="app.setPresetImage('https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80')" style="font-size: 12px;">Food</button>
                        <button type="button" class="btn btn-sm btn-secondary" onclick="app.setPresetImage('https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=80')" style="font-size: 12px;">Pizza</button>
                        <button type="button" class="btn btn-sm btn-secondary" onclick="app.setPresetImage('https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800&q=80')" style="font-size: 12px;">Salad</button>
                        <button type="button" class="btn btn-sm btn-secondary" onclick="app.setPresetImage('https://images.unsplash.com/photo-1607083206968-13611e3d76db?w=800&q=80')" style="font-size: 12px;">Offer</button>
                        <button type="button" class="btn btn-sm btn-secondary" onclick="app.clearNotificationImage()" style="font-size: 12px; color: #ef4444;">Clear</button>
                    </div>
                    <div style="margin-top: 14px;">
                        <label class="notif-label" style="font-size: 12px;">Image Size / Style</label>
                        <select id="notif-image-style" class="notif-input" onchange="app.updateNotificationPreview()">
                            <option value="banner">16:9 Landscape Banner - Android Big Picture Style</option>
                            <option value="square">1:1 Square Card</option>
                            <option value="compact">3:1 Compact Strip</option>
                        </select>
                    </div>
                </div>

                <!-- Brand Color -->
                <div class="notif-section">
                    <span class="notif-label"><i class="fa-solid fa-palette" style="margin-right: 6px;"></i> 5. Brand Accent Color</span>
                    <div style="display: flex; align-items: center; gap: 14px; flex-wrap: wrap;">
                        ${[
                            {hex:'#FF6B35',label:'Hungrily Orange'},
                            {hex:'#E23744',label:'Zomato Red'},
                            {hex:'#FC8019',label:'Swiggy Orange'},
                            {hex:'#00B176',label:'Fresh Green'},
                            {hex:'#6366F1',label:'Purple'},
                            {hex:'#F59E0B',label:'Golden'},
                            {hex:'#0EA5E9',label:'Sky Blue'},
                        ].map((c,i) => `<div class="color-swatch${i===0?' active':''}" style="background:${c.hex};" title="${c.label}" onclick="app.selectBrandColor('${c.hex}', this)"></div>`).join('')}
                        <input type="color" id="notif-brand-color-custom" value="#FF6B35" onchange="app.selectBrandColor(this.value, null)" style="width: 32px; height: 32px; border-radius: 50%; border: 3px solid #e2e8f0; cursor: pointer; padding: 0;">
                        <input type="hidden" id="notif-brand-color" value="#FF6B35">
                    </div>
                </div>

                <!-- Action Buttons -->
                <div class="notif-section">
                    <span class="notif-label"><i class="fa-solid fa-hand-pointer" style="margin-right: 6px;"></i> 6. Action Buttons (Max 2)</span>
                    <p style="font-size: 12px; color: #94a3b8; margin-bottom: 12px;">These appear below the notification text on Android. Like Zomato's "Order Now" / "View Menu" buttons.</p>
                    <div id="action-buttons-container"></div>
                    <button type="button" class="add-action-btn" id="add-action-btn" onclick="app.addActionButton()">
                        <i class="fa-solid fa-plus"></i> Add Action Button
                    </button>
                </div>

                <!-- Screen & Send -->
                <div class="notif-section">
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 20px;">
                        <div>
                            <label class="notif-label" style="font-size: 12px;">Click Action Screen</label>
                            <select id="notif-action" class="notif-input">
                                <option value="HOME">Home Screen</option>
                                <option value="OFFERS">Offers & Deals</option>
                                <option value="WALLET">Wallet</option>
                                <option value="ORDERS">My Orders</option>
                            </select>
                        </div>
                        <div>
                            <label class="notif-label" style="font-size: 12px;">Schedule</label>
                            <select class="notif-input" disabled style="opacity: 0.5; cursor: not-allowed;">
                                <option>Send Immediately</option>
                                <option>Schedule (Coming Soon)</option>
                            </select>
                        </div>
                    </div>
                    <button type="button" id="send-notif-btn" onclick="app.handleNotificationFormSubmit()" class="btn btn-primary" style="width: 100%; padding: 16px; border-radius: 14px; font-weight: 800; font-size: 15px; display: flex; align-items: center; justify-content: center; gap: 10px; background: linear-gradient(135deg, #FF6B35, #e85d2f); box-shadow: 0 4px 20px rgba(255,107,53,0.4); border: none; letter-spacing: 0.3px;">
                        <i class="fa-solid fa-paper-plane"></i> Send Filtered Notification Now
                    </button>
                </div>
            </div>

            <!-- RIGHT: Phone Preview -->
            <div style="position: sticky; top: 24px;">
                <div class="notif-section" style="background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); padding: 20px; text-align: center;">
                    <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1.5px; color: #475569; font-weight: 700; margin-bottom: 16px;">
LIVE PREVIEW
                    </div>
                    <div class="phone-wrap">
                        <div class="phone-body">
                            <div class="notch"></div>
                            <div class="phone-screen">
                                <div class="status-bar">
                                    <span style="font-size: 10px; color: #64748b; font-weight: 700;">9:41</span>
                                    <div style="display: flex; gap: 4px; align-items: center;">
                                        <i class="fa-solid fa-wifi" style="font-size: 9px; color: #64748b;"></i>
                                        <i class="fa-solid fa-signal" style="font-size: 9px; color: #64748b;"></i>
                                        <i class="fa-solid fa-battery-three-quarters" style="font-size: 9px; color: #64748b;"></i>
                                    </div>
                                </div>

                                <div class="notif-card-preview" id="preview-card">
                                    <div class="notif-top-row">
                                        <div class="notif-app-info">
                                            <img src="/admin/logo.png" class="notif-app-icon">
                                            <span class="notif-app-name">Hungrily Foods</span>
                                        </div>
                                        <span class="notif-time">now</span>
                                    </div>
                                    <div class="notif-preview-title" id="preview-title">Flat 40% Off Today Only!</div>
                                    <div class="notif-preview-body" id="preview-body">Use code HUNGRY40 and get 40% off on your next order. Limited time offer!</div>
                                    <img id="preview-image" class="notif-preview-image" src="" alt="">
                                    <div class="notif-action-btns" id="preview-action-btns"></div>
                                </div>

                                <div style="margin-top: 12px; text-align: center; opacity: 0.3;">
                                    <div style="width: 50px; height: 4px; background: #fff; border-radius: 3px; margin: 0 auto;"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div style="margin-top: 16px; font-size: 11px; color: #475569; font-weight: 600; text-align: center; letter-spacing: 0.5px;">
                        Updates as you type
                    </div>
                </div>
            </div>
        </div>

        <!-- Broadcast History -->
        <div class="notif-section">
            <h3 style="font-size: 17px; font-weight: 800; margin-bottom: 20px; color: var(--text-color, #1e293b); display: flex; align-items: center; gap: 10px;">
                <i class="fa-solid fa-clock-rotate-left" style="color: #FF6B35;"></i> Broadcast History
                <button onclick="app.loadNotificationHistory()" style="margin-left: auto; padding: 6px 12px; border-radius: 8px; border: 1.5px solid #e2e8f0; background: transparent; cursor: pointer; font-size: 12px; color: #64748b; font-weight: 600;">
                    <i class="fa-solid fa-rotate-right"></i> Refresh
                </button>
            </h3>
            <div id="notif-history-container">
                <div class="spinner"></div>
            </div>
        </div>
        `;

        // Init action buttons state
        this._actionButtons = [];
        this.initNotifLocationFilters();
        this.updateNotificationPreview();
        this.loadNotificationHistory();
    }

    initNotifLocationFilters() {
        const stateSelect    = document.getElementById('notif-state');
        const districtSelect = document.getElementById('notif-district');
        const talukaSelect   = document.getElementById('notif-taluka');

        if (!stateSelect || !districtSelect || !talukaSelect) return;

        // Default state: Maharashtra
        const state = stateSelect.value || 'Maharashtra';
        const districts = LOCATION_DATA.districtsByState[state] || [];

        districtSelect.innerHTML = '<option value="all">All Districts</option>' +
            districts.map(d => `<option value="${d}">${d}</option>`).join('');

        talukaSelect.innerHTML = '<option value="all">All Talukas</option>';

        this.fetchNotifTargetSummary();
    }

    
    insertEmoji(inputId, emoji) {
        const input = document.getElementById(inputId);
        if (!input) return;
        const start = input.selectionStart || input.value.length;
        const end = input.selectionEnd || input.value.length;
        input.value = input.value.substring(0, start) + emoji + input.value.substring(end);
        input.focus();
        input.selectionStart = input.selectionEnd = start + emoji.length;
        this.updateNotificationPreview();
    }

    setPresetImage(url) {
        const imgInput = document.getElementById('notif-image-url');
        if (imgInput) {
            imgInput.value = url;
            const previewEl = document.getElementById('notif-uploaded-preview');
            const thumbEl = document.getElementById('notif-uploaded-thumb');
            const nameEl = document.getElementById('notif-uploaded-filename');
            if (url) {
                if (previewEl) previewEl.style.display = 'flex';
                if (thumbEl) thumbEl.src = url;
                if (nameEl) nameEl.textContent = 'Preset image selected';
            } else {
                if (previewEl) previewEl.style.display = 'none';
            }
            this.updateNotificationPreview();
        }
    }

    async handleNotificationImageFile(input) {
        const file = input?.files?.[0];
        if (!file) return;
        await this._uploadNotificationImage(file);
    }

    async handleNotificationImageDrop(event) {
        event.preventDefault();
        const dropzone = document.getElementById('notif-image-dropzone');
        if (dropzone) {
            dropzone.style.borderColor = '#cbd5e1';
            dropzone.style.background = '#f8fafc';
        }
        const file = event.dataTransfer?.files?.[0];
        if (!file) return;
        await this._uploadNotificationImage(file);
    }

    async _uploadNotificationImage(file) {
        if (!file.type || !file.type.startsWith('image/')) {
            this.showToast('Please select a valid image file (JPG, PNG, WEBP, GIF).', 'error');
            return;
        }

        const idleEl = document.getElementById('notif-upload-idle');
        const loadingEl = document.getElementById('notif-upload-loading');
        if (idleEl) idleEl.style.display = 'none';
        if (loadingEl) loadingEl.style.display = 'block';

        try {
            const res = await api.uploadNotificationImage(file);
            if (res.success && res.data?.url) {
                const url = res.data.url;
                const urlInput = document.getElementById('notif-image-url');
                if (urlInput) urlInput.value = url;

                const previewEl = document.getElementById('notif-uploaded-preview');
                const thumbEl = document.getElementById('notif-uploaded-thumb');
                const nameEl = document.getElementById('notif-uploaded-filename');

                if (previewEl) previewEl.style.display = 'flex';
                if (thumbEl) thumbEl.src = url;
                if (nameEl) nameEl.textContent = file.name || res.data.filename || 'Attached image';

                this.updateNotificationPreview();
                this.showToast('Banner image uploaded successfully!', 'success');
            } else {
                this.showToast(res.message || 'Image upload failed.', 'error');
            }
        } catch (err) {
            this.showToast('Failed to upload image: ' + err.message, 'error');
        } finally {
            if (idleEl) idleEl.style.display = 'block';
            if (loadingEl) loadingEl.style.display = 'none';
        }
    }

    clearNotificationImage() {
        const urlInput = document.getElementById('notif-image-url');
        const fileInput = document.getElementById('notif-image-file');
        const previewEl = document.getElementById('notif-uploaded-preview');

        if (urlInput) urlInput.value = '';
        if (fileInput) fileInput.value = '';
        if (previewEl) previewEl.style.display = 'none';

        this.updateNotificationPreview();
    }

    selectBrandColor(hex, element) {
        const hiddenInput = document.getElementById('notif-brand-color');
        const customInput = document.getElementById('notif-brand-color-custom');
        if (hiddenInput) hiddenInput.value = hex;
        if (customInput && customInput !== element) customInput.value = hex;

        if (element) {
            document.querySelectorAll('.color-swatch').forEach(s => s.classList.remove('active'));
            element.classList.add('active');
        }
        this.updateNotificationPreview();
    }

    addActionButton() {
        if (!this._actionButtons) this._actionButtons = [];
        if (this._actionButtons.length >= 2) {
            this.showToast('Maximum 2 action buttons allowed.', 'warning');
            return;
        }
        this._actionButtons.push({ title: 'View Offer', action: 'OFFERS' });
        this._renderActionButtons();
        this.updateNotificationPreview();
    }

    _renderActionButtons() {
        const container = document.getElementById('action-buttons-container');
        const addBtn = document.getElementById('add-action-btn');
        if (!container) return;

        if (this._actionButtons.length >= 2 && addBtn) {
            addBtn.style.display = 'none';
        } else if (addBtn) {
            addBtn.style.display = 'flex';
        }

        container.innerHTML = (this._actionButtons || []).map((b, i) => `
            <div class="action-btn-row">
                <div>
                    <label class="notif-label" style="font-size: 11px;">Button ${i + 1} Label</label>
                    <input type="text" class="notif-input" value="${b.title}" placeholder="e.g. Order Now"
                        oninput="app._actionButtons[${i}].title = this.value; app.updateNotificationPreview();">
                </div>
                <div>
                    <label class="notif-label" style="font-size: 11px;">Target Screen</label>
                    <select class="notif-input" onchange="app._actionButtons[${i}].action = this.value; app.updateNotificationPreview();">
                        <option value="HOME" ${b.action === 'HOME' ? 'selected' : ''}>Home</option>
                        <option value="OFFERS" ${b.action === 'OFFERS' ? 'selected' : ''}>Offers</option>
                        <option value="WALLET" ${b.action === 'WALLET' ? 'selected' : ''}>Wallet</option>
                        <option value="ORDERS" ${b.action === 'ORDERS' ? 'selected' : ''}>Orders</option>
                    </select>
                </div>
                <button type="button" class="del-btn" onclick="app._actionButtons.splice(${i}, 1); app._renderActionButtons(); app.updateNotificationPreview();">
                    <i class="fa-solid fa-trash"></i>
                </button>
            </div>
        `).join('');
    }

    updateNotificationPreview() {
        const title    = document.getElementById('notif-title')?.value?.trim() || 'Flat 40% Off Today Only!';
        const body     = document.getElementById('notif-body')?.value?.trim() || 'Use code HUNGRY40 and get 40% off on your next order. Limited time offer!';
        const imageUrl = document.getElementById('notif-image-url')?.value?.trim() || '';
        const imageStyle = document.getElementById('notif-image-style')?.value || 'banner';
        const brandColor = document.getElementById('notif-brand-color')?.value || '#FF6B35';

        const pTitle = document.getElementById('preview-title');
        const pBody  = document.getElementById('preview-body');
        const pImg   = document.getElementById('preview-image');
        const pBtns  = document.getElementById('preview-action-btns');
        const pCard  = document.getElementById('preview-card');

        if (pTitle) pTitle.textContent = title;
        if (pBody)  pBody.textContent  = body;
        if (pCard)  pCard.style.borderLeft = `4px solid ${brandColor}`;

        if (pImg) {
            if (imageUrl) {
                pImg.src = imageUrl;
                pImg.style.display = 'block';
                if (imageStyle === 'square') {
                    pImg.style.aspectRatio = '1 / 1';
                } else if (imageStyle === 'compact') {
                    pImg.style.aspectRatio = '3 / 1';
                } else {
                    pImg.style.aspectRatio = '16 / 9';
                }
            } else {
                pImg.style.display = 'none';
            }
        }

        if (pBtns) {
            const btns = (this._actionButtons || []).filter(b => b.title.trim());
            pBtns.innerHTML = btns.map(b => `
                <button type="button" class="notif-action-btn-preview" style="background: rgba(255,255,255,0.2); color: #fff; border: 1px solid rgba(255,255,255,0.3);">
                    ${b.title}
                </button>
            `).join('');
        }
    }


    onNotifTargetChange() {
        this.updateNotificationPreview();
        this.fetchNotifTargetSummary();
    }

    onNotifLocationFilterChange(level) {
        const state    = document.getElementById('notif-state')?.value || 'all';
        const districtSelect = document.getElementById('notif-district');
        const talukaSelect   = document.getElementById('notif-taluka');

        if (level === 'state' && districtSelect) {
            const districts = (state !== 'all' && LOCATION_DATA.districtsByState[state]) ? LOCATION_DATA.districtsByState[state] : [];
            districtSelect.innerHTML = '<option value="all">All Districts</option>' +
                districts.map(d => `<option value="${d}">${d}</option>`).join('');
            if (talukaSelect) talukaSelect.innerHTML = '<option value="all">All Talukas</option>';
        }

        if (level === 'district' && districtSelect && talukaSelect) {
            const selectedDistrict = districtSelect.value;
            const talukas = (selectedDistrict !== 'all' && LOCATION_DATA.talukasByDistrict[selectedDistrict]) ? LOCATION_DATA.talukasByDistrict[selectedDistrict] : [];
            talukaSelect.innerHTML = '<option value="all">All Talukas</option>' +
                talukas.map(t => `<option value="${t}">${t}</option>`).join('');
        }

        this.fetchNotifTargetSummary();
    }

    async fetchNotifTargetSummary() {
        const target   = document.querySelector('input[name="notif-target"]:checked')?.value || 'all';
        const state    = document.getElementById('notif-state')?.value || '';
        const district = document.getElementById('notif-district')?.value || '';
        const taluka   = document.getElementById('notif-taluka')?.value || '';

        const totalEl  = document.getElementById('notif-target-total-count');
        const fcmEl    = document.getElementById('notif-target-fcm-count');
        const custEl   = document.getElementById('notif-count-cust');
        const vendEl   = document.getElementById('notif-count-vend');
        const drivEl   = document.getElementById('notif-count-driv');

        if (totalEl) totalEl.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>';

        try {
            const res = await api.getNotificationTargets({ target, state, district, taluka });
            if (res.success && res.data?.counts) {
                const c = res.data.counts;
                if (totalEl) totalEl.textContent = c.total_users;
                if (fcmEl)   fcmEl.textContent   = `(${c.total_fcm} Devices Registered for FCM Push)`;
                if (custEl)  custEl.innerHTML    = `<b>${c.customers_total}</b> (${c.customers_fcm} FCM)`;
                if (vendEl)  vendEl.innerHTML    = `<b>${c.vendors_total}</b> (${c.vendors_fcm} FCM)`;
                if (drivEl)  drivEl.innerHTML    = `<b>${c.drivers_total}</b> (${c.drivers_fcm} FCM)`;

                // Store last target counts state for modal
                this._lastNotifCounts = res.data.counts;
            }
        } catch (e) {
            if (totalEl) totalEl.textContent = '0';
        }
    }

    async openNotificationRecipientsModal(page = 1, userType = null) {
        const target   = document.querySelector('input[name="notif-target"]:checked')?.value || 'all';
        const state    = document.getElementById('notif-state')?.value || '';
        const district = document.getElementById('notif-district')?.value || '';
        const taluka   = document.getElementById('notif-taluka')?.value || '';
        const search   = document.getElementById('notif-modal-search')?.value?.trim() || '';

        const activeTab = userType || this._activeNotifTab || 'all';
        this._activeNotifTab = activeTab;

        // Existing modal cleanup
        this.closeNotificationRecipientsModal();

        const locSummary = [state, district !== 'all' ? district : '', taluka !== 'all' ? taluka : ''].filter(Boolean).join(' / ') || 'All Locations';

        const modalHtml = `
        <div class="modal-backdrop" id="notif-recipients-modal" style="display: flex; align-items: center; justify-content: center; position: fixed; inset: 0; background: rgba(15,23,42,0.65); backdrop-filter: blur(5px); z-index: 9999; animation: fadeIn 0.2s ease;">
            <div style="background: #ffffff; border-radius: 20px; width: 92%; max-width: 900px; max-height: 88vh; display: flex; flex-direction: column; overflow: hidden; box-shadow: 0 25px 60px rgba(0,0,0,0.3); border: 1px solid #e2e8f0;">
                <!-- Header -->
                <div style="padding: 20px 24px; border-bottom: 1px solid #e2e8f0; display: flex; align-items: center; justify-content: space-between; background: linear-gradient(135deg, #f8fafc 0%, #fff5f0 100%);">
                    <div>
                        <h3 style="margin: 0; font-size: 18px; font-weight: 800; color: #1e293b; display: flex; align-items: center; gap: 8px;">
                            <i class="fa-solid fa-users" style="color: #FF6B35;"></i> Filtered Notification Recipients List
                        </h3>
                        <p style="margin: 4px 0 0 0; font-size: 12px; color: #64748b; font-weight: 600;">
                            Filter: <b>${target.toUpperCase()}</b> &bull; Location: <b>${locSummary}</b>
                        </p>
                    </div>
                    <button onclick="app.closeNotificationRecipientsModal()" style="border: none; background: #fee2e2; color: #ef4444; width: 34px; height: 34px; border-radius: 50%; cursor: pointer; font-size: 15px; font-weight: 800; display: flex; align-items: center; justify-content: center; transition: all 0.15s;">✓</button>
                </div>

                <!-- Tabs & Search Toolbar -->
                <div style="padding: 14px 24px; border-bottom: 1px solid #f1f5f9; display: flex; align-items: center; justify-content: space-between; gap: 14px; flex-wrap: wrap; background: #ffffff;">
                    <div style="display: flex; gap: 6px; flex-wrap: wrap;">
                        <button type="button" class="btn btn-sm ${activeTab === 'all' ? 'btn-primary' : 'btn-secondary'}" onclick="app.openNotificationRecipientsModal(1, 'all')" style="font-weight: 700; padding: 6px 14px; font-size: 12px; border-radius: 8px;"> All Recipients</button>
                        <button type="button" class="btn btn-sm ${activeTab === 'customers' ? 'btn-primary' : 'btn-secondary'}" onclick="app.openNotificationRecipientsModal(1, 'customers')" style="font-weight: 700; padding: 6px 14px; font-size: 12px; border-radius: 8px;">Customers</button>
                        <button type="button" class="btn btn-sm ${activeTab === 'vendors' ? 'btn-primary' : 'btn-secondary'}" onclick="app.openNotificationRecipientsModal(1, 'vendors')" style="font-weight: 700; padding: 6px 14px; font-size: 12px; border-radius: 8px;">Vendors</button>
                        <button type="button" class="btn btn-sm ${activeTab === 'drivers' ? 'btn-primary' : 'btn-secondary'}" onclick="app.openNotificationRecipientsModal(1, 'drivers')" style="font-weight: 700; padding: 6px 14px; font-size: 12px; border-radius: 8px;">Drivers</button>
                    </div>

                    <div style="position: relative; width: 240px;">
                        <input type="text" id="notif-modal-search" value="${search}" placeholder=" Search name, phone..." class="notif-input" style="padding: 7px 12px 7px 32px; font-size: 12px; border-radius: 10px;" oninput="app.debounceNotifModalSearch()">
                        <i class="fa-solid fa-search" style="position: absolute; left: 10px; top: 50%; transform: translateY(-50%); color: #94a3b8; font-size: 11px;"></i>
                    </div>
                </div>

                <!-- Recipient Table Container -->
                <div style="padding: 0; overflow-y: auto; flex: 1; background: #ffffff;" id="notif-modal-table-body">
                    <div style="padding: 40px; text-align: center; color: #64748b;">
                        <i class="fa-solid fa-spinner fa-spin" style="font-size: 24px; color: #FF6B35; margin-bottom: 10px;"></i>
                        <div>Loading filtered recipients list...</div>
                    </div>
                </div>

                <!-- Footer Pagination -->
                <div style="padding: 12px 24px; border-top: 1px solid #e2e8f0; display: flex; align-items: center; justify-content: space-between; background: #f8fafc;" id="notif-modal-pagination">
                </div>
            </div>
        </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHtml);

        try {
            const res = await api.getNotificationTargets({
                target, state, district, taluka,
                user_type: activeTab,
                search, page, limit: 15
            });

            if (res.success && res.data?.recipients) {
                this.renderNotificationRecipientsTable(res.data.recipients, page, activeTab);
            } else {
                document.getElementById('notif-modal-table-body').innerHTML = `
                    <div style="padding: 40px; text-align: center; color: #ef4444;">Failed to load recipients list.</div>
                `;
            }
        } catch (err) {
            document.getElementById('notif-modal-table-body').innerHTML = `
                <div style="padding: 40px; text-align: center; color: #ef4444;">Error loading recipients: ${err.message}</div>
            `;
        }
    }

    renderNotificationRecipientsTable(recipientsData, currentPage, activeTab) {
        const tableBody = document.getElementById('notif-modal-table-body');
        const pagination = document.getElementById('notif-modal-pagination');
        if (!tableBody) return;

        const list       = recipientsData.list || [];
        const totalCount = recipientsData.total_count || 0;
        const totalPages = recipientsData.total_pages || 1;

        if (list.length === 0) {
            tableBody.innerHTML = `
                <div style="padding: 50px 20px; text-align: center; color: #94a3b8;">
                    <i class="fa-solid fa-users-slash" style="font-size: 36px; margin-bottom: 12px; color: #cbd5e1;"></i>
                    <div style="font-size: 15px; font-weight: 700; color: #475569;">No matching recipients found</div>
                    <div style="font-size: 12px; margin-top: 4px;">Try selecting a different district, taluka, or role filter tab.</div>
                </div>
            `;
            if (pagination) pagination.innerHTML = `<span>Total Records: 0</span>`;
            return;
        }

        const roleBadges = {
            'Customer': '<span style="background: #e0f2fe; color: #0369a1; padding: 3px 8px; border-radius: 6px; font-size: 11px; font-weight: 700;">Customer</span>',
            'Vendor':   '<span style="background: #ffedd5; color: #c2410c; padding: 3px 8px; border-radius: 6px; font-size: 11px; font-weight: 700;">Vendor</span>',
            'Driver': '<span style="background: #fef9c3; color: #854d0e; padding: 3px 8px; border-radius: 6px; font-size: 11px; font-weight: 700;">Driver</span>'
        };

        const rowsHtml = list.map((r, i) => {
            const rowNum = (currentPage - 1) * recipientsData.limit + i + 1;
            const fcmBadge = r.has_fcm == 1 
                ? '<span style="background: #dcfce7; color: #15803d; padding: 3px 8px; border-radius: 12px; font-size: 11px; font-weight: 700;">FCM Registered</span>'
                : '<span style="background: #f1f5f9; color: #94a3b8; padding: 3px 8px; border-radius: 12px; font-size: 11px; font-weight: 700;">No Token</span>';

            return `
                <tr style="border-bottom: 1px solid #f1f5f9; transition: background 0.15s;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='transparent'">
                    <td style="padding: 12px 16px; font-size: 12px; color: #64748b; font-weight: 600;">${rowNum}</td>
                    <td style="padding: 12px 16px; font-size: 13px; font-weight: 700; color: #1e293b;">${r.name || 'Unnamed'}</td>
                    <td style="padding: 12px 16px;">${roleBadges[r.role_type] || r.role_type}</td>
                    <td style="padding: 12px 16px; font-size: 12px; color: #475569;">
                        <div>${r.phone ? r.phone : ''}</div>
                        <div style="font-size: 11px; color: #94a3b8;">${r.email || ''}</div>
                    </td>
                    <td style="padding: 12px 16px; font-size: 12px; color: #334155; font-weight: 600;"> ${r.district || '-'}</td>
                    <td style="padding: 12px 16px; font-size: 12px; color: #334155;">${r.taluka || '-'}</td>
                    <td style="padding: 12px 16px;">${fcmBadge}</td>
                </tr>
            `;
        }).join('');

        tableBody.innerHTML = `
            <table style="width: 100%; border-collapse: collapse; text-align: left;">
                <thead>
                    <tr style="background: #f8fafc; border-bottom: 2px solid #e2e8f0; font-size: 11px; text-transform: uppercase; color: #64748b; letter-spacing: 0.5px;">
                        <th style="padding: 12px 16px; width: 40px;">#</th>
                        <th style="padding: 12px 16px;">Recipient Name</th>
                        <th style="padding: 12px 16px;">Role</th>
                        <th style="padding: 12px 16px;">Contact Details</th>
                        <th style="padding: 12px 16px;">District</th>
                        <th style="padding: 12px 16px;">Taluka</th>
                        <th style="padding: 12px 16px;">FCM Push Status</th>
                    </tr>
                </thead>
                <tbody>
                    ${rowsHtml}
                </tbody>
            </table>
        `;

        if (pagination) {
            pagination.innerHTML = `
                <span style="font-size: 12px; color: #64748b; font-weight: 600;">
                    Showing <b>${list.length}</b> of <b>${totalCount}</b> filtered recipients (Page ${currentPage} of ${totalPages})
                </span>
                <div style="display: flex; gap: 8px;">
                    <button class="btn btn-sm btn-secondary" ${currentPage <= 1 ? 'disabled style="opacity:0.5;"' : ''} onclick="app.openNotificationRecipientsModal(${currentPage - 1}, '${activeTab}')" style="font-size: 12px; font-weight: 700;"><i class="fa-solid fa-chevron-left"></i> Previous</button>
                    <button class="btn btn-sm btn-secondary" ${currentPage >= totalPages ? 'disabled style="opacity:0.5;"' : ''} onclick="app.openNotificationRecipientsModal(${currentPage + 1}, '${activeTab}')" style="font-size: 12px; font-weight: 700;">Next <i class="fa-solid fa-chevron-right"></i></button>
                </div>
            `;
        }
    }

    debounceNotifModalSearch() {
        if (this._notifSearchTimer) clearTimeout(this._notifSearchTimer);
        this._notifSearchTimer = setTimeout(() => {
            this.openNotificationRecipientsModal(1, this._activeNotifTab || 'all');
        }, 350);
    }

    closeNotificationRecipientsModal() {
        const modal = document.getElementById('notif-recipients-modal');
        if (modal) modal.remove();
    }

    
    async loadNotificationHistory() {
        const container = document.getElementById('notif-history-container');
        if (!container) return;

        try {
            container.innerHTML = '<div style="padding: 20px; text-align: center; color: #64748b;"><i class="fa-solid fa-spinner fa-spin" style="margin-right: 8px;"></i> Loading history...</div>';
            const response = await api.request('/admin/notifications/history', { method: 'GET' });
            const list = response.data?.notifications || [];

            if (list.length === 0) {
                container.innerHTML = '<div style="padding: 20px; text-align: center; color: #94a3b8; font-size: 13px;">No past notification broadcasts found.</div>';
                return;
            }

            const targetBadges = {
                'all': '<span style="background:#e0f2fe; color:#0369a1; padding:3px 8px; border-radius:6px; font-weight:700; font-size:11px;"> All Users</span>',
                'customers': '<span style="background:#fef3c7; color:#b45309; padding:3px 8px; border-radius:6px; font-weight:700; font-size:11px;">Customers</span>',
                'vendors': '<span style="background:#ffedd5; color:#c2410c; padding:3px 8px; border-radius:6px; font-weight:700; font-size:11px;">Vendors</span>',
                'drivers': '<span style="background:#dcfce7; color:#15803d; padding:3px 8px; border-radius:6px; font-weight:700; font-size:11px;">Drivers</span>'
            };

            const rows = list.map((item, index) => {
                const locSummary = [item.district, item.taluka].filter(Boolean).join(' / ') || 'All Locations';
                return `
                <tr style="border-bottom: 1px solid #f1f5f9;">
                    <td style="padding: 12px 14px; font-size: 12px; color: #64748b;">${index + 1}</td>
                    <td style="padding: 12px 14px;">
                        <div style="font-weight: 800; font-size: 13px; color: #1e293b;">${item.title}</div>
                        <div style="font-size: 12px; color: #64748b; margin-top: 2px;">${item.body}</div>
                    </td>
                    <td style="padding: 12px 14px;">${targetBadges[item.target] || item.target}</td>
                    <td style="padding: 12px 14px; font-size: 12px; color: #334155; font-weight: 600;">
                         ${locSummary}
                    </td>
                    <td style="padding: 12px 14px; font-size: 13px; font-weight: 800; color: #10b981;">
                        ${item.target_count} device(s)
                    </td>
                    <td style="padding: 12px 14px; font-size: 12px; color: #94a3b8;">${item.created_at || 'Recently'}</td>
                </tr>
                `;
            }).join('');

            container.innerHTML = `
                <div style="overflow-x: auto;">
                    <table style="width: 100%; border-collapse: collapse; text-align: left;">
                        <thead>
                            <tr style="background: #f8fafc; border-bottom: 2px solid #e2e8f0; font-size: 11px; text-transform: uppercase; color: #64748b;">
                                <th style="padding: 10px 14px;">#</th>
                                <th style="padding: 10px 14px;">Notification Details</th>
                                <th style="padding: 10px 14px;">Target Role</th>
                                <th style="padding: 10px 14px;">Location Filter</th>
                                <th style="padding: 10px 14px;">Devices Reached</th>
                                <th style="padding: 10px 14px;">Sent Date</th>
                            </tr>
                        </thead>
                        <tbody>${rows}</tbody>
                    </table>
                </div>
            `;
        } catch (error) {
            container.innerHTML = `<div style="color: #ef4444; padding: 20px; font-size: 13px;">Failed to load history: ${error.message}</div>`;
        }
    }

    async handleNotificationFormSubmit() {
        const submitBtn = document.getElementById('send-notif-btn');
        const title       = document.getElementById('notif-title')?.value?.trim();
        const body        = document.getElementById('notif-body')?.value?.trim();
        const imageUrl    = document.getElementById('notif-image-url')?.value?.trim() || '';
        const imageStyle  = document.getElementById('notif-image-style')?.value || 'banner';
        const clickAction = document.getElementById('notif-action')?.value || 'HOME';
        const brandColor  = document.getElementById('notif-brand-color')?.value || '#FF6B35';
        const target      = document.querySelector('input[name="notif-target"]:checked')?.value || 'all';
        const state       = document.getElementById('notif-state')?.value || '';
        const district    = document.getElementById('notif-district')?.value || '';
        const taluka      = document.getElementById('notif-taluka')?.value || '';
        const actionButtons = (this._actionButtons || []).filter(b => b.title.trim());

        if (!title) { this.showToast('Please enter a notification title.', 'error'); return; }
        if (!body)  { this.showToast('Please enter a notification message.', 'error'); return; }

        try {
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Broadcasting to Filtered Users...';

            const response = await api.sendPushNotification({
                title, body, target, state, district, taluka,
                click_action: clickAction,
                image_url: imageUrl, image_style: imageStyle,
                brand_color: brandColor,
                action_buttons: actionButtons,
            });

            if (response.success) {
                this.showToast(`${response.message}`, 'success');
                document.getElementById('notif-title').value = '';
                document.getElementById('notif-body').value = '';
                this.clearNotificationImage();
                this._actionButtons = [];
                this._renderActionButtons();
                this.updateNotificationPreview();
                this.fetchNotifTargetSummary();
                this.loadNotificationHistory();
            } else {
                this.showToast(response.message || 'Failed to send.', 'error');
            }
        } catch (error) {
            this.showToast('Error: ' + error.message, 'error');
        } finally {
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<i class="fa-solid fa-paper-plane"></i> Send Filtered Notification Now';
        }
    }

    /* -- WhatsApp Bulk Broadcast View (Click2Api / Meta Integration) ---- */

    async loadWhatsAppBroadcastView(container) {
        container.innerHTML = `
        <style>
            .wa-section { background: var(--bg-card, #fff); border-radius: 18px; padding: 28px; box-shadow: 0 4px 24px rgba(0,0,0,0.07); margin-bottom: 24px; }
            .wa-label { font-size: 13px; font-weight: 700; color: var(--text-secondary, #64748b); text-transform: uppercase; letter-spacing: 0.8px; margin-bottom: 8px; display: block; }
            .wa-input { width: 100%; padding: 13px 16px; border: 2px solid #e2e8f0; border-radius: 12px; font-size: 14px; font-family: inherit; transition: border-color 0.2s, box-shadow 0.2s; box-sizing: border-box; background: #f8fafc; }
            .wa-input:focus { border-color: #25D366; box-shadow: 0 0 0 3px rgba(37,211,102,0.15); outline: none; background: #fff; }
            .wa-target-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; }
            .wa-target-pill { display: flex; align-items: center; gap: 10px; padding: 14px 16px; border: 2px solid #e2e8f0; border-radius: 12px; cursor: pointer; transition: all 0.2s; font-weight: 600; font-size: 13px; }
            .wa-target-pill:has(input:checked) { border-color: #25D366; background: #f0fdf4; color: #15803d; }
            .wa-target-pill input { accent-color: #25D366; width: 16px; height: 16px; }
            .wa-emoji-bar { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 8px; }
            .wa-emoji-btn { font-size: 20px; cursor: pointer; padding: 4px 8px; border-radius: 8px; border: 1.5px solid #e2e8f0; background: #f8fafc; transition: all 0.15s; line-height: 1; }
            .wa-emoji-btn:hover { background: #f0fdf4; border-color: #25D366; transform: scale(1.2); }
            .wa-tag-pill { font-size: 11px; font-weight: 700; background: #e0e7ff; color: #3730a3; padding: 4px 10px; border-radius: 20px; cursor: pointer; border: 1px solid #c7d2fe; transition: all 0.15s; }
            .wa-tag-pill:hover { background: #4f46e5; color: #fff; }
            
            /* WhatsApp Phone Chat Preview Styling */
            .wa-phone-wrap { position: relative; width: 290px; margin: 0 auto; }
            .wa-phone-body { background: #0b141a; border-radius: 40px; padding: 14px; box-shadow: 0 20px 60px rgba(0,0,0,0.5), inset 0 0 0 2px rgba(255,255,255,0.08); }
            .wa-phone-screen { background: #0b141a url('https://user-images.githubusercontent.com/15075759/28719144-86dc0f70-73b1-11e7-911d-60d70fcded21.png') repeat; border-radius: 28px; overflow: hidden; min-height: 440px; padding: 12px; display: flex; flex-direction: column; justify-content: space-between; }
            .wa-chat-header { background: #1f2c34; padding: 10px 12px; margin: -12px -12px 12px -12px; display: flex; align-items: center; gap: 10px; color: #e9edef; border-bottom: 1px solid #2a3942; }
            .wa-chat-avatar { width: 32px; height: 32px; border-radius: 50%; background: #00a884; color: #fff; display: flex; align-items: center; justify-content: center; font-weight: 800; font-size: 14px; }
            .wa-bubble { background: #005c4b; color: #e9edef; padding: 10px 12px; border-radius: 12px 12px 2px 12px; font-size: 12.5px; line-height: 1.45; word-break: break-word; box-shadow: 0 1px 2px rgba(0,0,0,0.3); margin-left: 20px; position: relative; white-space: pre-wrap; }
            .wa-bubble-time { font-size: 10px; color: #8696a0; text-align: right; margin-top: 4px; display: flex; align-items: center; justify-content: flex-end; gap: 3px; }
        </style>

        <div class="dashboard-banner" style="margin-bottom: 24px; background: linear-gradient(135deg, #075E54 0%, #128C7E 100%);">
            <h2 class="banner-title" style="color: #ffffff;"><i class="fa-brands fa-whatsapp" style="margin-right: 10px; color: #25D366;"></i> WhatsApp Bulk Broadcast Center</h2>
            <p class="banner-desc" style="color: #e0f2fe;">Send instant direct WhatsApp messages in bulk to Customers, Vendors, and Drivers using official Click2Api / Meta REST API, filtered by State, District, and Taluka.</p>
        </div>

        <div style="display: grid; grid-template-columns: 1fr 310px; gap: 24px; align-items: start;">
            <!-- LEFT: WhatsApp Message Composer -->
            <div>
                <!-- Target & Location Filters Section -->
                <div class="wa-section">
                    <span class="wa-label">1. Target Audience & Role</span>
                    <div class="wa-target-grid" style="margin-bottom: 20px;">
                        <label class="wa-target-pill"><input type="radio" name="wa-target" value="all" checked onchange="app.onWhatsAppTargetChange()">  All Registered Users</label>
                        <label class="wa-target-pill"><input type="radio" name="wa-target" value="customers" onchange="app.onWhatsAppTargetChange()"> Customers Only</label>
                        <label class="wa-target-pill"><input type="radio" name="wa-target" value="vendors" onchange="app.onWhatsAppTargetChange()"> Vendors Only</label>
                        <label class="wa-target-pill"><input type="radio" name="wa-target" value="drivers" onchange="app.onWhatsAppTargetChange()"> Drivers Only</label>
                    </div>

                    <span class="wa-label"> 2. Geographic Location Filters (State, District & Taluka)</span>
                    <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; margin-bottom: 20px;">
                        <div>
                            <label class="wa-label" style="font-size: 11px;">State</label>
                            <select id="wa-state" class="wa-input" onchange="app.onWhatsAppLocationFilterChange('state')">
                                <option value="all">All States</option>
                                <option value="Maharashtra" selected>Maharashtra</option>
                                <option value="Gujarat">Gujarat</option>
                                <option value="Karnataka">Karnataka</option>
                                <option value="Tamil Nadu">Tamil Nadu</option>
                                <option value="Uttar Pradesh">Uttar Pradesh</option>
                                <option value="Rajasthan">Rajasthan</option>
                                <option value="Madhya Pradesh">Madhya Pradesh</option>
                                <option value="Delhi">Delhi</option>
                            </select>
                        </div>
                        <div>
                            <label class="wa-label" style="font-size: 11px;">District</label>
                            <select id="wa-district" class="wa-input" onchange="app.onWhatsAppLocationFilterChange('district')">
                                <option value="all">All Districts</option>
                            </select>
                        </div>
                        <div>
                            <label class="wa-label" style="font-size: 11px;">Taluka</label>
                            <select id="wa-taluka" class="wa-input" onchange="app.onWhatsAppLocationFilterChange('taluka')">
                                <option value="all">All Talukas</option>
                            </select>
                        </div>
                        <div>
                            <label class="wa-label" style="font-size: 11px;">Region</label>
                            <select id="wa-region" class="wa-input" onchange="app.onWhatsAppLocationFilterChange('region')">
                                <option value="all">All Regions</option>
                            </select>
                        </div>
                        <div>
                            <label class="wa-label" style="font-size: 11px;">Area / Zone</label>
                            <select id="wa-area" class="wa-input" onchange="app.onWhatsAppLocationFilterChange('area')">
                                <option value="all">All Areas</option>
                            </select>
                        </div>
                    </div>

                    <!-- Live Target Counter Card & View List Button -->
                    <div id="wa-target-counter-box" style="background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%); border: 2px dashed #25D366; border-radius: 16px; padding: 18px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 14px; box-shadow: 0 4px 15px rgba(37,211,102,0.08);">
                        <div>
                            <div style="font-size: 14px; font-weight: 800; color: #14532d; display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
                                <span style="font-size: 24px; color: #16a34a; font-weight: 900;" id="wa-target-total-count">...</span> Targeted Mobile Users 
                                <span id="wa-target-phone-count" style="font-size: 12px; background: #ffffff; color: #15803d; padding: 4px 12px; border-radius: 20px; font-weight: 700; border: 1px solid #86efac;">(With Valid WhatsApp Mobile No)</span>
                            </div>
                            <div id="wa-target-breakdown" style="display: flex; gap: 14px; font-size: 12px; color: #166534; margin-top: 8px; flex-wrap: wrap;">
                                <span><i class="fa-solid fa-users text-primary"></i> Customers: <b id="wa-count-cust">0</b></span>
                                <span><i class="fa-solid fa-store text-warning"></i> Vendors: <b id="wa-count-vend">0</b></span>
                                <span><i class="fa-solid fa-motorcycle text-success"></i> Drivers: <b id="wa-count-driv">0</b></span>
                            </div>
                        </div>
                        <button type="button" class="btn btn-secondary btn-sm" onclick="app.openWhatsAppRecipientsModal()" style="padding: 11px 20px; border-radius: 12px; font-weight: 800; display: flex; align-items: center; gap: 8px; font-size: 13px; background: #ffffff; color: #14532d; border: 1.5px solid #86efac; box-shadow: 0 2px 8px rgba(0,0,0,0.06); cursor: pointer; transition: all 0.2s;">
                            <i class="fa-solid fa-users-viewfinder" style="color: #25D366; font-size: 15px;"></i> View Phone Recipients List
                        </button>
                    </div>
                </div>

                <!-- Message Composer Section -->
                <div class="wa-section">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; flex-wrap: wrap; gap: 8px;">
                        <span class="wa-label" style="margin-bottom: 0;"><i class="fa-brands fa-whatsapp" style="margin-right: 6px;"></i> WhatsApp Delivery Method</span>
                        <select id="wa-template-name" class="wa-input" style="width: auto; padding: 6px 14px; font-size: 12px; font-weight: 700; border-radius: 8px; border: 1.5px solid #25D366; background: #f0fdf4; color: #14532d;">
                            <option value="text" selected>Direct Dynamic Message (Personalized text with {name}, {district}, etc.)</option>
                            <option value="hungrily_broadcast">hungrily_broadcast (Meta Template with Dynamic Parameters)</option>
                            <option value="welcome">welcome (Static Meta Welcome Notification)</option>
                            <option value="hungrily_otp">hungrily_otp (OTP Template)</option>
                        </select>
                    </div>

                    <!-- Dynamic Message Mode Switcher -->
                    <div style="margin-bottom: 16px;">
                        <span class="wa-label" style="margin-bottom: 8px;">3. Dynamic Message Strategy</span>
                        <div style="display: flex; gap: 8px; background: #f1f5f9; padding: 4px; border-radius: 12px; border: 1px solid #e2e8f0;">
                            <button type="button" id="wa-mode-single-btn" class="btn btn-sm btn-primary" onclick="app.setWhatsAppMessageMode('single')" style="flex: 1; border-radius: 9px; font-weight: 700; font-size: 12px; padding: 8px 12px;">
Universal Dynamic Message
                            </button>
                            <button type="button" id="wa-mode-role-btn" class="btn btn-sm btn-secondary" onclick="app.setWhatsAppMessageMode('per_role')" style="flex: 1; border-radius: 9px; font-weight: 700; font-size: 12px; padding: 8px 12px;">
                                Role-Specific Messages (Customer, Vendor, Driver)
                            </button>
                        </div>
                    </div>

                    <!-- Container A: Universal Message (Single) -->
                    <div id="wa-composer-single">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
                            <span class="wa-label" style="margin-bottom: 0;"><i class="fa-solid fa-envelope-open-text" style="margin-right: 6px;"></i> Message Body (Auto-Personalized for All Users)</span>
                            <span style="font-size: 11px; color: #94a3b8; font-weight: 600;" id="wa-char-count-single">0 characters</span>
                        </div>
                        <textarea id="wa-message-body" class="wa-input" rows="5" placeholder="Hello {name}! Special update from Hungrily Foods for our {role} in {district}. Enjoy fresh meals delivered on time! Check menu: https://hungrily.com" oninput="app.updateWhatsAppPreview()" style="resize: vertical; margin-bottom: 10px;"></textarea>

                        <!-- Dynamic Placeholders for Single -->
                        <div style="margin-bottom: 12px; display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">
                            <span style="font-size: 11px; font-weight: 700; color: #64748b;">Dynamic Tags:</span>
                            <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{name}', 'wa-message-body')">{name}</span>
                            <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{first_name}', 'wa-message-body')">{first_name}</span>
                            <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{role}', 'wa-message-body')">{role}</span>
                            <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{district}', 'wa-message-body')">{district}</span>
                            <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{taluka}', 'wa-message-body')">{taluka}</span>
                            <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{hotel_name}', 'wa-message-body')">{hotel_name}</span>
                            <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{phone}', 'wa-message-body')">{phone}</span>
                            <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{date}', 'wa-message-body')">{date}</span>
                        </div>

                        <!-- Presets for Single -->
                        <div style="margin-bottom: 14px; display: flex; gap: 6px; flex-wrap: wrap; align-items: center;">
                            <span style="font-size: 11px; font-weight: 700; color: #16a34a;">Quick Presets:</span>
                            <button type="button" class="btn btn-xs btn-secondary" onclick="app.loadWhatsAppPreset('promo', 'wa-message-body')" style="font-size: 11px; padding: 3px 8px;">20% Off Offer</button>
                            <button type="button" class="btn btn-xs btn-secondary" onclick="app.loadWhatsAppPreset('service', 'wa-message-body')" style="font-size: 11px; padding: 3px 8px;"> Service Alert</button>
                            <button type="button" class="btn btn-xs btn-secondary" onclick="app.loadWhatsAppPreset('greeting', 'wa-message-body')" style="font-size: 11px; padding: 3px 8px;">Warm Greeting</button>
                        </div>
                    </div>

                    <!-- Container B: Role-Specific Messages -->
                    <div id="wa-composer-role" style="display: none;">
                        <!-- Role Sub-tabs -->
                        <div style="display: flex; gap: 8px; margin-bottom: 12px;">
                            <button type="button" id="wa-role-tab-customer" class="btn btn-sm btn-primary" onclick="app.setWhatsAppRoleTab('customer')" style="font-weight: 700; font-size: 12px; border-radius: 8px;">
                                Customer Message (<span id="wa-subcount-cust">0</span>)
                            </button>
                            <button type="button" id="wa-role-tab-vendor" class="btn btn-sm btn-secondary" onclick="app.setWhatsAppRoleTab('vendor')" style="font-weight: 700; font-size: 12px; border-radius: 8px;"Vendor Message (<span id="wa-subcount-vend">0</span>)
                            </button>
                            <button type="button" id="wa-role-tab-driver" class="btn btn-sm btn-secondary" onclick="app.setWhatsAppRoleTab('driver')" style="font-weight: 700; font-size: 12px; border-radius: 8px;">
                                Driver Message (<span id="wa-subcount-driv">0</span>)
                            </button>
                        </div>

                        <!-- Customer Message Panel -->
                        <div id="wa-panel-customer">
                            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;">
                                <span class="wa-label" style="margin-bottom: 0; color: #0284c7;">Customer Message</span>
                                <span style="font-size: 11px; color: #94a3b8; font-weight: 600;" id="wa-char-count-cust">0 characters</span>
                            </div>
                            <textarea id="wa-message-customer" class="wa-input" rows="4" placeholder="Hello {name}! Delicious home-cooked tiffins in {district}. Enjoy 20% off today on Hungrily Foods! Order now: https://hungrily.com" oninput="app.updateWhatsAppPreview()" style="resize: vertical; margin-bottom: 8px;"></textarea>
                            <div style="margin-bottom: 10px; display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">
                                <span style="font-size: 11px; font-weight: 700; color: #64748b;">Tags:</span>
                                <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{name}', 'wa-message-customer')">{name}</span>
                                <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{first_name}', 'wa-message-customer')">{first_name}</span>
                                <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{district}', 'wa-message-customer')">{district}</span>
                                <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{taluka}', 'wa-message-customer')">{taluka}</span>
                                <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{date}', 'wa-message-customer')">{date}</span>
                                <button type="button" class="btn btn-xs btn-secondary" onclick="app.loadWhatsAppPreset('customer_default', 'wa-message-customer')" style="font-size: 11px; padding: 2px 8px; margin-left: 6px;">Load Customer Promo</button>
                            </div>
                        </div>

                        <!-- Vendor Message Panel -->
                        <div id="wa-panel-vendor" style="display: none;">
                            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;">
                                <span class="wa-label" style="margin-bottom: 0; color: #ea580c;">Vendor Message</span>
                                <span style="font-size: 11px; color: #94a3b8; font-weight: 600;" id="wa-char-count-vend">0 characters</span>
                            </div>
                            <textarea id="wa-message-vendor" class="wa-input" rows="4" placeholder="Hello {name} ({hotel_name})! Today's daily meal schedule is active for {district}. Please review meal counts & orders on your Vendor App: https://hungrily.com/vendor" oninput="app.updateWhatsAppPreview()" style="resize: vertical; margin-bottom: 8px;"></textarea>
                            <div style="margin-bottom: 10px; display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">
                                <span style="font-size: 11px; font-weight: 700; color: #64748b;">Tags:</span>
                                <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{name}', 'wa-message-vendor')">{name}</span>
                                <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{hotel_name}', 'wa-message-vendor')">{hotel_name}</span>
                                <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{district}', 'wa-message-vendor')">{district}</span>
                                <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{taluka}', 'wa-message-vendor')">{taluka}</span>
                                <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{date}', 'wa-message-vendor')">{date}</span>
                                <button type="button" class="btn btn-xs btn-secondary" onclick="app.loadWhatsAppPreset('vendor_default', 'wa-message-vendor')" style="font-size: 11px; padding: 2px 8px; margin-left: 6px;">Load Vendor Alert</button>
                            </div>
                        </div>

                        <!-- Driver Message Panel -->
                        <div id="wa-panel-driver" style="display: none;">
                            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px;">
                                <span class="wa-label" style="margin-bottom: 0; color: #ca8a04;">Driver Message</span>
                                <span style="font-size: 11px; color: #94a3b8; font-weight: 600;" id="wa-char-count-driv">0 characters</span>
                            </div>
                            <textarea id="wa-message-driver" class="wa-input" rows="4" placeholder="Hello {name}! Delivery orders are dispatched in {district}, {taluka}. Vehicle {vehicle_number} is scheduled. Open Driver App to accept trips: https://hungrily.com/driver" oninput="app.updateWhatsAppPreview()" style="resize: vertical; margin-bottom: 8px;"></textarea>
                            <div style="margin-bottom: 10px; display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">
                                <span style="font-size: 11px; font-weight: 700; color: #64748b;">Tags:</span>
                                <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{name}', 'wa-message-driver')">{name}</span>
                                <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{vehicle_number}', 'wa-message-driver')">{vehicle_number}</span>
                                <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{district}', 'wa-message-driver')">{district}</span>
                                <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{taluka}', 'wa-message-driver')">{taluka}</span>
                                <span class="wa-tag-pill" onclick="app.insertWhatsAppTag('{date}', 'wa-message-driver')">{date}</span>
                                <button type="button" class="btn btn-xs btn-secondary" onclick="app.loadWhatsAppPreset('driver_default', 'wa-message-driver')" style="font-size: 11px; padding: 2px 8px; margin-left: 6px;">Load Driver Alert</button>
                            </div>
                        </div>
                    </div>

                    <!-- Quick Emojis -->
                    <div class="wa-emoji-bar">
                        ${['🎉','🔥','📢','🛵','🍲','⏰','🍕','🍔','🥗','🎁','💬','❤️','👉','⏳','🍽️','✅','⭐'].map(e => `<span class="wa-emoji-btn" onclick="app.insertWhatsAppEmoji('${e}')">${e}</span>`).join('')}
                    </div>
                </div>

                <!-- Send Button Section -->
                <div class="wa-section">
                    <button type="button" id="send-wa-btn" onclick="app.handleWhatsAppFormSubmit()" class="btn btn-primary" style="width: 100%; padding: 16px; border-radius: 14px; font-weight: 800; font-size: 15px; display: flex; align-items: center; justify-content: center; gap: 10px; background: linear-gradient(135deg, #25D366, #128C7E); box-shadow: 0 4px 20px rgba(37,211,102,0.4); border: none; letter-spacing: 0.3px;">
                        <i class="fa-brands fa-whatsapp" style="font-size: 20px;"></i> Send Dynamic WhatsApp Broadcast Now
                    </button>
                </div>

                <!-- History Table Section -->
                <div class="wa-section">
                    <span class="wa-label" style="margin-bottom: 16px;"><i class="fa-solid fa-clock-rotate-left" style="margin-right: 6px;"></i> 4. Past WhatsApp Broadcast History</span>
                    <div id="wa-history-container">
                        <div style="padding: 20px; text-align: center; color: #64748b;"><i class="fa-solid fa-spinner fa-spin" style="margin-right: 8px;"></i> Loading history...</div>
                    </div>
                </div>
            </div>

            <!-- RIGHT: WhatsApp Live Chat Preview with Persona Switcher -->
            <div style="position: sticky; top: 24px;">
                <div class="wa-section" style="background: #0f172a; padding: 20px; text-align: center;">
                    <div style="font-size: 11px; text-transform: uppercase; letter-spacing: 1.5px; color: #64748b; font-weight: 700; margin-bottom: 12px;">
LIVE WHATSAPP PREVIEW
                    </div>

                    <!-- Persona Switcher -->
                    <div style="display: flex; gap: 4px; justify-content: center; margin-bottom: 14px; background: #1e293b; padding: 4px; border-radius: 10px;">
                        <button type="button" class="btn btn-xs btn-primary" id="wa-prev-btn-customer" onclick="app.setWhatsAppPreviewPersona('customer')" style="font-size: 10px; font-weight: 700; padding: 4px 8px; border-radius: 6px;">Customer</button>
                        <button type="button" class="btn btn-xs btn-secondary" id="wa-prev-btn-vendor" onclick="app.setWhatsAppPreviewPersona('vendor')" style="font-size: 10px; font-weight: 700; padding: 4px 8px; border-radius: 6px;">Vendor</button>
                        <button type="button" class="btn btn-xs btn-secondary" id="wa-prev-btn-driver" onclick="app.setWhatsAppPreviewPersona('driver')" style="font-size: 10px; font-weight: 700; padding: 4px 8px; border-radius: 6px;">Driver</button>
                    </div>

                    <div class="wa-phone-wrap">
                        <div class="wa-phone-body">
                            <div class="wa-phone-screen">
                                <div class="wa-chat-header">
                                    <div class="wa-chat-avatar">H</div>
                                    <div style="text-align: left;">
                                        <div style="font-size: 13px; font-weight: 700; color: #e9edef;">Hungrily Foods</div>
                                        <div style="font-size: 10px; color: #25D366; font-weight: 600;">Official Business Account ✓</div>
                                    </div>
                                </div>

                                <div>
                                    <div class="wa-bubble" id="wa-preview-text">
                                        Type your message on the left to see live WhatsApp preview...
                                        <div class="wa-bubble-time">
                                            <span>9:41 AM</span>
                                            <i class="fa-solid fa-check-double" style="color: #53bdeb; font-size: 10px;"></i>
                                        </div>
                                    </div>
                                </div>

                                <div style="margin-top: 12px; text-align: center; font-size: 10px; color: #64748b;">
                                    Delivered via Click2Api / Meta WhatsApp REST Cloud API
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        `;

        // Initialize Location Dropdowns, Counts & Dynamic Preview
        this.populateWhatsAppLocationDropdowns();
        this.fetchWhatsAppTargetSummary();
        this.loadWhatsAppHistory();
        this._waDynamicMode = 'single';
        this._waActiveRoleTab = 'customer';
        this._waPreviewPersona = 'customer';
        this.updateWhatsAppPreview();
    }

    populateWhatsAppLocationDropdowns() {
        const stateSelect = document.getElementById('wa-state');
        const districtSelect = document.getElementById('wa-district');
        const talukaSelect = document.getElementById('wa-taluka');

        if (!stateSelect || !districtSelect || !talukaSelect) return;

        const currentState = stateSelect.value || 'Maharashtra';
        const districts = (currentState !== 'all' && LOCATION_DATA.districtsByState[currentState]) ? LOCATION_DATA.districtsByState[currentState] : [];

        districtSelect.innerHTML = '<option value="all">All Districts</option>' +
            districts.map(d => `<option value="${d}">${d}</option>`).join('');

        talukaSelect.innerHTML = '<option value="all">All Talukas</option>';
    }

    onWhatsAppTargetChange() {
        const target = document.querySelector('input[name="wa-target"]:checked')?.value || 'all';
        if (target === 'customers') {
            this.setWhatsAppPreviewPersona('customer');
            if (this._waDynamicMode === 'per_role') this.setWhatsAppRoleTab('customer');
        } else if (target === 'vendors') {
            this.setWhatsAppPreviewPersona('vendor');
            if (this._waDynamicMode === 'per_role') this.setWhatsAppRoleTab('vendor');
        } else if (target === 'drivers') {
            this.setWhatsAppPreviewPersona('driver');
            if (this._waDynamicMode === 'per_role') this.setWhatsAppRoleTab('driver');
        }
        this.fetchWhatsAppTargetSummary();
    }

    onWhatsAppLocationFilterChange(level) {
        const stateSelect = document.getElementById('wa-state');
        const districtSelect = document.getElementById('wa-district');
        const talukaSelect = document.getElementById('wa-taluka');
        const regionSelect = document.getElementById('wa-region');
        const areaSelect = document.getElementById('wa-area');

        const state = stateSelect?.value || 'all';

        if (level === 'state' && districtSelect) {
            const districts = (state !== 'all' && LOCATION_DATA.districtsByState[state]) ? LOCATION_DATA.districtsByState[state] : [];
            districtSelect.innerHTML = '<option value="all">All Districts</option>' +
                districts.map(d => `<option value="${d}">${d}</option>`).join('');
            if (talukaSelect) talukaSelect.innerHTML = '<option value="all">All Talukas</option>';
            if (regionSelect) regionSelect.innerHTML = '<option value="all">All Regions</option>';
            if (areaSelect) areaSelect.innerHTML = '<option value="all">All Areas</option>';
        }

        if (level === 'district' && districtSelect) {
            const selectedDistrict = districtSelect.value;
            const talukas = (selectedDistrict !== 'all' && LOCATION_DATA.talukasByDistrict[selectedDistrict]) ? LOCATION_DATA.talukasByDistrict[selectedDistrict] : [];
            if (talukaSelect) {
                talukaSelect.innerHTML = '<option value="all">All Talukas</option>' +
                    talukas.map(t => `<option value="${t}">${t}</option>`).join('');
            }
            if (regionSelect && typeof LOCATION_DATA.getRegions === 'function') {
                const regions = selectedDistrict !== 'all' ? LOCATION_DATA.getRegions(selectedDistrict) : [];
                regionSelect.innerHTML = '<option value="all">All Regions</option>' +
                    regions.map(r => `<option value="${r}">${r}</option>`).join('');
            }
            if (areaSelect && typeof LOCATION_DATA.getAllAreas === 'function') {
                const areas = selectedDistrict !== 'all' ? LOCATION_DATA.getAllAreas(selectedDistrict) : [];
                areaSelect.innerHTML = '<option value="all">All Areas</option>' +
                    areas.map(a => `<option value="${a}">${a}</option>`).join('');
            }
        }

        if (level === 'region' && regionSelect && areaSelect && typeof LOCATION_DATA.getAreas === 'function') {
            const selectedDistrict = districtSelect?.value || '';
            const selectedRegion = regionSelect.value;
            const areas = selectedDistrict !== 'all' ? LOCATION_DATA.getAreas(selectedDistrict, selectedRegion) : [];
            areaSelect.innerHTML = '<option value="all">All Areas</option>' +
                areas.map(a => `<option value="${a}">${a}</option>`).join('');
        }

        this.fetchWhatsAppTargetSummary();
        this.updateWhatsAppPreview();
    }

    async fetchWhatsAppTargetSummary() {
        const target   = document.querySelector('input[name="wa-target"]:checked')?.value || 'all';
        const state    = document.getElementById('wa-state')?.value || '';
        const district = document.getElementById('wa-district')?.value || '';
        const taluka   = document.getElementById('wa-taluka')?.value || '';

        const totalEl   = document.getElementById('wa-target-total-count');
        const phoneEl   = document.getElementById('wa-target-phone-count');
        const custEl    = document.getElementById('wa-count-cust');
        const vendEl    = document.getElementById('wa-count-vend');
        const drivEl    = document.getElementById('wa-count-driv');
        const subCustEl = document.getElementById('wa-subcount-cust');
        const subVendEl = document.getElementById('wa-subcount-vend');
        const subDrivEl = document.getElementById('wa-subcount-driv');

        if (totalEl) totalEl.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>';

        try {
            const res = await api.getWhatsAppTargets({ target, state, district, taluka });
            if (res.success && res.data?.counts) {
                const c = res.data.counts;
                if (totalEl) totalEl.textContent = c.total_phones;
                if (phoneEl) phoneEl.textContent = `(${c.total_phones} Valid WhatsApp Mobile Numbers)`;
                if (custEl)  custEl.innerHTML   = `<b>${c.customers_total}</b> Phone(s)`;
                if (vendEl)  vendEl.innerHTML   = `<b>${c.vendors_total}</b> Phone(s)`;
                if (drivEl)  drivEl.innerHTML   = `<b>${c.drivers_total}</b> Phone(s)`;
                if (subCustEl) subCustEl.textContent = c.customers_total;
                if (subVendEl) subVendEl.textContent = c.vendors_total;
                if (subDrivEl) subDrivEl.textContent = c.drivers_total;
            }
        } catch (e) {
            if (totalEl) totalEl.textContent = '0';
        }
    }

    setWhatsAppMessageMode(mode) {
        this._waDynamicMode = mode;
        const singleBtn = document.getElementById('wa-mode-single-btn');
        const roleBtn   = document.getElementById('wa-mode-role-btn');
        const singleBox = document.getElementById('wa-composer-single');
        const roleBox   = document.getElementById('wa-composer-role');

        if (mode === 'per_role') {
            if (singleBtn) {
                singleBtn.classList.remove('btn-primary');
                singleBtn.classList.add('btn-secondary');
            }
            if (roleBtn) {
                roleBtn.classList.remove('btn-secondary');
                roleBtn.classList.add('btn-primary');
            }
            if (singleBox) singleBox.style.display = 'none';
            if (roleBox) singleBox ? (roleBox.style.display = 'block') : null;
            if (this._waActiveRoleTab) {
                this.setWhatsAppRoleTab(this._waActiveRoleTab);
            }
        } else {
            if (singleBtn) {
                singleBtn.classList.remove('btn-secondary');
                singleBtn.classList.add('btn-primary');
            }
            if (roleBtn) {
                roleBtn.classList.remove('btn-primary');
                roleBtn.classList.add('btn-secondary');
            }
            if (singleBox) singleBox.style.display = 'block';
            if (roleBox) roleBox.style.display = 'none';
        }
        this.updateWhatsAppPreview();
    }

    setWhatsAppRoleTab(role) {
        this._waActiveRoleTab = role;
        const tabs = ['customer', 'vendor', 'driver'];
        tabs.forEach(r => {
            const btn = document.getElementById(`wa-role-tab-${r}`);
            const panel = document.getElementById(`wa-panel-${r}`);
            if (btn) {
                if (r === role) {
                    btn.classList.remove('btn-secondary');
                    btn.classList.add('btn-primary');
                } else {
                    btn.classList.remove('btn-primary');
                    btn.classList.add('btn-secondary');
                }
            }
            if (panel) {
                panel.style.display = r === role ? 'block' : 'none';
            }
        });
        this.setWhatsAppPreviewPersona(role);
    }

    setWhatsAppPreviewPersona(persona) {
        this._waPreviewPersona = persona;
        const personas = ['customer', 'vendor', 'driver'];
        personas.forEach(p => {
            const btn = document.getElementById(`wa-prev-btn-${p}`);
            if (btn) {
                if (p === persona) {
                    btn.classList.remove('btn-secondary');
                    btn.classList.add('btn-primary');
                } else {
                    btn.classList.remove('btn-primary');
                    btn.classList.add('btn-secondary');
                }
            }
        });
        this.updateWhatsAppPreview();
    }

    getActiveWhatsAppInput(targetInputId = null) {
        if (targetInputId) {
            const el = document.getElementById(targetInputId);
            if (el) return el;
        }
        if (this._waDynamicMode === 'per_role') {
            const role = this._waActiveRoleTab || 'customer';
            return document.getElementById(`wa-message-${role}`) || document.getElementById('wa-message-customer');
        }
        return document.getElementById('wa-message-body');
    }

    insertWhatsAppEmoji(emoji, targetInputId = null) {
        const input = this.getActiveWhatsAppInput(targetInputId);
        if (!input) return;
        const start = input.selectionStart || input.value.length;
        const end = input.selectionEnd || input.value.length;
        input.value = input.value.substring(0, start) + emoji + input.value.substring(end);
        input.selectionStart = input.selectionEnd = start + emoji.length;
        input.focus();
        this.updateWhatsAppPreview();
    }

    insertWhatsAppTag(tag, targetInputId = null) {
        const input = this.getActiveWhatsAppInput(targetInputId);
        if (!input) return;
        const start = input.selectionStart || input.value.length;
        const end = input.selectionEnd || input.value.length;
        input.value = input.value.substring(0, start) + tag + input.value.substring(end);
        input.selectionStart = input.selectionEnd = start + tag.length;
        input.focus();
        this.updateWhatsAppPreview();
    }

    loadWhatsAppPreset(presetKey, targetInputId = null) {
        const presets = {
            'promo': "Hello {name}! Delicious home-style tiffin service is now active in {district}, {taluka}! Get 20% OFF on your monthly meal plan today. Check meals: https://hungrily.com",
            'service': "Service Announcement for {name} ({role}) in {district}: Today's lunch and dinner tiffin dispatch is on schedule for {date}. For live updates open Hungrily App.",
            'greeting': "Namaste {first_name}! Wishing you a great day from Hungrily Foods. We are delighted to serve healthy, hygienic meals at your doorstep in {district}!",
            'customer_default': "Hello {first_name}! Craving fresh hot food? Your favorite tiffins are available in {district}, {taluka}. Order or renew your subscription now: https://hungrily.com/menu",
            'vendor_default': "Hello {name} ({hotel_name})! Meal schedule update for {date}. Please prepare scheduled tiffin orders on time for delivery partners in {district}. Open vendor dashboard: https://hungrily.com/vendor",
            'driver_default': "Hello {name}! Delivery orders dispatched for {district}, {taluka}. Assigned vehicle: {vehicle_number}. Open Hungrily Driver App to accept and deliver tiffins on time: https://hungrily.com/driver"
        };

        const text = presets[presetKey];
        const input = this.getActiveWhatsAppInput(targetInputId);
        if (input && text) {
            input.value = text;
            input.focus();
        }
        this.updateWhatsAppPreview();
    }

    updateWhatsAppPreview() {
        const singleInput = document.getElementById('wa-message-body');
        const custInput   = document.getElementById('wa-message-customer');
        const vendInput   = document.getElementById('wa-message-vendor');
        const drivInput   = document.getElementById('wa-message-driver');

        const singleCount = document.getElementById('wa-char-count-single');
        const custCount   = document.getElementById('wa-char-count-cust');
        const vendCount   = document.getElementById('wa-char-count-vend');
        const drivCount   = document.getElementById('wa-char-count-driv');

        if (singleCount && singleInput) singleCount.textContent = `${singleInput.value.length} characters`;
        if (custCount && custInput)     custCount.textContent   = `${custInput.value.length} characters`;
        if (vendCount && vendInput)     vendCount.textContent   = `${vendInput.value.length} characters`;
        if (drivCount && drivInput)     drivCount.textContent   = `${drivInput.value.length} characters`;

        const previewEl = document.getElementById('wa-preview-text');
        if (!previewEl) return;

        const persona = this._waPreviewPersona || 'customer';
        const isRoleMode = (this._waDynamicMode === 'per_role');

        let rawText = '';
        if (isRoleMode) {
            if (persona === 'vendor') {
                rawText = vendInput?.value?.trim() || '';
            } else if (persona === 'driver') {
                rawText = drivInput?.value?.trim() || '';
            } else {
                rawText = custInput?.value?.trim() || '';
            }
        } else {
            rawText = singleInput?.value?.trim() || '';
        }

        const now = new Date();
        const timeStr = now.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true });

        if (!rawText) {
            previewEl.innerHTML = `
                Type your message on the left to see live WhatsApp preview...
                <div class="wa-bubble-time">
                    <span>${timeStr}</span>
                    <i class="fa-solid fa-check-double" style="color: #53bdeb; font-size: 10px;"></i>
                </div>
            `;
            return;
        }

        const selectedDist = document.getElementById('wa-district')?.value;
        const selectedTal  = document.getElementById('wa-taluka')?.value;
        const distName = (selectedDist && selectedDist !== 'all') ? selectedDist : 'Pune';
        const talName  = (selectedTal && selectedTal !== 'all') ? selectedTal : 'Haveli';
        const dateStr  = now.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });

        const personaData = {
            customer: {
                '{name}': 'Rahul Sharma',
                '{full_name}': 'Rahul Sharma',
                '{first_name}': 'Rahul',
                '{role}': 'Customer',
                '{role_type}': 'Customer',
                '{phone}': '9876543210',
                '{mobile}': '9876543210',
                '{district}': distName,
                '{taluka}': talName,
                '{state}': 'Maharashtra',
                '{hotel_name}': 'Hungrily Foods',
                '{hotel}': 'Hungrily Foods',
                '{business_name}': 'Hungrily Foods',
                '{vehicle_number}': 'MH-12-AB-1234',
                '{vehicle}': 'MH-12-AB-1234',
                '{date}': dateStr,
                '{time}': timeStr
            },
            vendor: {
                '{name}': 'Sanjay Patil',
                '{full_name}': 'Sanjay Patil',
                '{first_name}': 'Sanjay',
                '{role}': 'Vendor',
                '{role_type}': 'Vendor',
                '{phone}': '9822012345',
                '{mobile}': '9822012345',
                '{district}': distName,
                '{taluka}': (selectedTal && selectedTal !== 'all') ? selectedTal : 'Kothrud',
                '{state}': 'Maharashtra',
                '{hotel_name}': 'Shree Ganesh Dining',
                '{hotel}': 'Shree Ganesh Dining',
                '{business_name}': 'Shree Ganesh Dining',
                '{vehicle_number}': '',
                '{vehicle}': '',
                '{date}': dateStr,
                '{time}': timeStr
            },
            driver: {
                '{name}': 'Amit Kumar',
                '{full_name}': 'Amit Kumar',
                '{first_name}': 'Amit',
                '{role}': 'Driver',
                '{role_type}': 'Driver',
                '{phone}': '9970112233',
                '{mobile}': '9970112233',
                '{district}': distName,
                '{taluka}': (selectedTal && selectedTal !== 'all') ? selectedTal : 'Shivajinagar',
                '{state}': 'Maharashtra',
                '{hotel_name}': 'Hungrily Delivery',
                '{hotel}': 'Hungrily Delivery',
                '{business_name}': 'Hungrily Delivery',
                '{vehicle_number}': 'MH-12-DK-5678',
                '{vehicle}': 'MH-12-DK-5678',
                '{date}': dateStr,
                '{time}': timeStr
            }
        };

        const activeDict = personaData[persona] || personaData.customer;
        let renderedText = rawText;
        for (const [tag, replacement] of Object.entries(activeDict)) {
            const regex = new RegExp(tag.replace(/([{}])/g, '\\$1'), 'gi');
            renderedText = renderedText.replace(regex, replacement);
        }

        previewEl.innerHTML = `
            ${this.escapeHtml(renderedText)}
            <div class="wa-bubble-time">
                <span>${timeStr}</span>
                <i class="fa-solid fa-check-double" style="color: #53bdeb; font-size: 10px;"></i>
            </div>
        `;
    }

    async openWhatsAppRecipientsModal(page = 1, userType = null) {
        const target   = document.querySelector('input[name="wa-target"]:checked')?.value || 'all';
        const state    = document.getElementById('wa-state')?.value || '';
        const district = document.getElementById('wa-district')?.value || '';
        const taluka   = document.getElementById('wa-taluka')?.value || '';
        const search   = document.getElementById('wa-modal-search')?.value?.trim() || '';

        const activeTab = userType || this._activeWaTab || 'all';
        this._activeWaTab = activeTab;

        this.closeWhatsAppRecipientsModal();

        const locSummary = [state, district !== 'all' ? district : '', taluka !== 'all' ? taluka : ''].filter(Boolean).join(' / ') || 'All Locations';

        const modalHtml = `
        <div class="modal-backdrop" id="wa-recipients-modal" style="display: flex; align-items: center; justify-content: center; position: fixed; inset: 0; background: rgba(15,23,42,0.65); backdrop-filter: blur(5px); z-index: 9999; animation: fadeIn 0.2s ease;">
            <div style="background: #ffffff; border-radius: 20px; width: 92%; max-width: 900px; max-height: 88vh; display: flex; flex-direction: column; overflow: hidden; box-shadow: 0 25px 60px rgba(0,0,0,0.3); border: 1px solid #e2e8f0;">
                <!-- Header -->
                <div style="padding: 20px 24px; border-bottom: 1px solid #e2e8f0; display: flex; align-items: center; justify-content: space-between; background: linear-gradient(135deg, #f0fdf4 0%, #fff 100%);">
                    <div>
                        <h3 style="margin: 0; font-size: 18px; font-weight: 800; color: #14532d; display: flex; align-items: center; gap: 8px;">
                            <i class="fa-brands fa-whatsapp" style="color: #25D366; font-size: 22px;"></i> WhatsApp Recipients Phone List
                        </h3>
                        <p style="margin: 4px 0 0 0; font-size: 12px; color: #64748b; font-weight: 600;">
                            Target: <b>${target.toUpperCase()}</b> &bull; Location: <b>${locSummary}</b>
                        </p>
                    </div>
                    <button onclick="app.closeWhatsAppRecipientsModal()" style="border: none; background: #fee2e2; color: #ef4444; width: 34px; height: 34px; border-radius: 50%; cursor: pointer; font-size: 15px; font-weight: 800; display: flex; align-items: center; justify-content: center; transition: all 0.15s;">✓</button>
                </div>

                <!-- Tabs & Search Toolbar -->
                <div style="padding: 14px 24px; border-bottom: 1px solid #f1f5f9; display: flex; align-items: center; justify-content: space-between; gap: 14px; flex-wrap: wrap; background: #ffffff;">
                    <div style="display: flex; gap: 6px; flex-wrap: wrap;">
                        <button type="button" class="btn btn-sm ${activeTab === 'all' ? 'btn-primary' : 'btn-secondary'}" onclick="app.openWhatsAppRecipientsModal(1, 'all')" style="font-weight: 700; padding: 6px 14px; font-size: 12px; border-radius: 8px;"> All Recipients</button>
                        <button type="button" class="btn btn-sm ${activeTab === 'customers' ? 'btn-primary' : 'btn-secondary'}" onclick="app.openWhatsAppRecipientsModal(1, 'customers')" style="font-weight: 700; padding: 6px 14px; font-size: 12px; border-radius: 8px;">Customers</button>
                        <button type="button" class="btn btn-sm ${activeTab === 'vendors' ? 'btn-primary' : 'btn-secondary'}" onclick="app.openWhatsAppRecipientsModal(1, 'vendors')" style="font-weight: 700; padding: 6px 14px; font-size: 12px; border-radius: 8px;">Vendors</button>
                        <button type="button" class="btn btn-sm ${activeTab === 'drivers' ? 'btn-primary' : 'btn-secondary'}" onclick="app.openWhatsAppRecipientsModal(1, 'drivers')" style="font-weight: 700; padding: 6px 14px; font-size: 12px; border-radius: 8px;">Drivers</button>
                    </div>

                    <div style="position: relative; width: 240px;">
                        <input type="text" id="wa-modal-search" value="${search}" placeholder=" Search name, mobile..." class="wa-input" style="padding: 7px 12px 7px 32px; font-size: 12px; border-radius: 10px;" oninput="app.debounceWhatsAppModalSearch()">
                        <i class="fa-solid fa-search" style="position: absolute; left: 10px; top: 50%; transform: translateY(-50%); color: #94a3b8; font-size: 11px;"></i>
                    </div>
                </div>

                <!-- Recipient Table Container -->
                <div style="padding: 0; overflow-y: auto; flex: 1; background: #ffffff;" id="wa-modal-table-body">
                    <div style="padding: 40px; text-align: center; color: #64748b;">
                        <i class="fa-solid fa-spinner fa-spin" style="font-size: 24px; color: #25D366; margin-bottom: 10px;"></i>
                        <div>Loading WhatsApp phone recipients list...</div>
                    </div>
                </div>

                <!-- Footer Pagination -->
                <div style="padding: 12px 24px; border-top: 1px solid #e2e8f0; display: flex; align-items: center; justify-content: space-between; background: #f8fafc;" id="wa-modal-pagination">
                </div>
            </div>
        </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHtml);

        try {
            const res = await api.getWhatsAppTargets({
                target, state, district, taluka,
                user_type: activeTab,
                search, page, limit: 15
            });

            if (res.success && res.data?.recipients) {
                this.renderWhatsAppRecipientsTable(res.data.recipients, page, activeTab);
            } else {
                document.getElementById('wa-modal-table-body').innerHTML = `
                    <div style="padding: 40px; text-align: center; color: #ef4444;">Failed to load recipients list.</div>
                `;
            }
        } catch (err) {
            document.getElementById('wa-modal-table-body').innerHTML = `
                <div style="padding: 40px; text-align: center; color: #ef4444;">Error loading recipients: ${err.message}</div>
            `;
        }
    }

    renderWhatsAppRecipientsTable(recipientsData, currentPage, activeTab) {
        const tableBody = document.getElementById('wa-modal-table-body');
        const pagination = document.getElementById('wa-modal-pagination');
        if (!tableBody) return;

        const list       = recipientsData.list || [];
        const totalCount = recipientsData.total_count || 0;
        const totalPages = recipientsData.total_pages || 1;

        if (list.length === 0) {
            tableBody.innerHTML = `
                <div style="padding: 50px 20px; text-align: center; color: #94a3b8;">
                    <i class="fa-solid fa-phone-slash" style="font-size: 36px; margin-bottom: 12px; color: #cbd5e1;"></i>
                    <div style="font-size: 15px; font-weight: 700; color: #475569;">No matching phone recipients found</div>
                    <div style="font-size: 12px; margin-top: 4px;">Try selecting a different district, taluka, or role filter tab.</div>
                </div>
            `;
            if (pagination) pagination.innerHTML = `<span>Total Records: 0</span>`;
            return;
        }

        const roleBadges = {
            'Customer': '<span style="background: #e0f2fe; color: #0369a1; padding: 3px 8px; border-radius: 6px; font-size: 11px; font-weight: 700;">Customer</span>',
            'Vendor':   '<span style="background: #ffedd5; color: #c2410c; padding: 3px 8px; border-radius: 6px; font-size: 11px; font-weight: 700;">Vendor</span>',
            'Driver': '<span style="background: #fef9c3; color: #854d0e; padding: 3px 8px; border-radius: 6px; font-size: 11px; font-weight: 700;">Driver</span>'
        };

        const rowsHtml = list.map((r, i) => {
            const rowNum = (currentPage - 1) * recipientsData.limit + i + 1;
            const phoneBadge = r.phone 
                ? `<span style="background: #dcfce7; color: #15803d; padding: 3px 8px; border-radius: 12px; font-size: 11px; font-weight: 700;"> ${r.phone}</span>`
                : `<span style="background: #fee2e2; color: #ef4444; padding: 3px 8px; border-radius: 12px; font-size: 11px; font-weight: 700;"><i class="fa-solid fa-phone-slash" style="font-size: 10px; margin-right: 4px;"></i> Missing Phone</span>`;

            return `
                <tr style="border-bottom: 1px solid #f1f5f9; transition: background 0.15s;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='transparent'">
                    <td style="padding: 12px 16px; font-size: 12px; color: #64748b; font-weight: 600;">${rowNum}</td>
                    <td style="padding: 12px 16px; font-size: 13px; font-weight: 700; color: #1e293b;">${r.name || 'Unnamed'}</td>
                    <td style="padding: 12px 16px;">${roleBadges[r.role_type] || r.role_type}</td>
                    <td style="padding: 12px 16px;">${phoneBadge}</td>
                    <td style="padding: 12px 16px; font-size: 12px; color: #334155; font-weight: 600;"> ${r.district || '-'}</td>
                    <td style="padding: 12px 16px; font-size: 12px; color: #334155;">${r.taluka || '-'}</td>
                </tr>
            `;
        }).join('');

        tableBody.innerHTML = `
            <table style="width: 100%; border-collapse: collapse; text-align: left;">
                <thead>
                    <tr style="background: #f8fafc; border-bottom: 2px solid #e2e8f0; font-size: 11px; text-transform: uppercase; color: #64748b; letter-spacing: 0.5px;">
                        <th style="padding: 12px 16px; width: 40px;">#</th>
                        <th style="padding: 12px 16px;">Recipient Name</th>
                        <th style="padding: 12px 16px;">Role</th>
                        <th style="padding: 12px 16px;">WhatsApp Phone No.</th>
                        <th style="padding: 12px 16px;">District</th>
                        <th style="padding: 12px 16px;">Taluka</th>
                    </tr>
                </thead>
                <tbody>
                    ${rowsHtml}
                </tbody>
            </table>
        `;

        if (pagination) {
            pagination.innerHTML = `
                <span style="font-size: 12px; color: #64748b; font-weight: 600;">
                    Showing <b>${list.length}</b> of <b>${totalCount}</b> phone recipients (Page ${currentPage} of ${totalPages})
                </span>
                <div style="display: flex; gap: 8px;">
                    <button class="btn btn-sm btn-secondary" ${currentPage <= 1 ? 'disabled style="opacity:0.5;"' : ''} onclick="app.openWhatsAppRecipientsModal(${currentPage - 1}, '${activeTab}')" style="font-size: 12px; font-weight: 700;"><i class="fa-solid fa-chevron-left"></i> Previous</button>
                    <button class="btn btn-sm btn-secondary" ${currentPage >= totalPages ? 'disabled style="opacity:0.5;"' : ''} onclick="app.openWhatsAppRecipientsModal(${currentPage + 1}, '${activeTab}')" style="font-size: 12px; font-weight: 700;">Next <i class="fa-solid fa-chevron-right"></i></button>
                </div>
            `;
        }
    }

    debounceWhatsAppModalSearch() {
        if (this._waSearchTimer) clearTimeout(this._waSearchTimer);
        this._waSearchTimer = setTimeout(() => {
            this.openWhatsAppRecipientsModal(1, this._activeWaTab || 'all');
        }, 350);
    }

    closeWhatsAppRecipientsModal() {
        const modal = document.getElementById('wa-recipients-modal');
        if (modal) modal.remove();
    }

    async loadWhatsAppHistory() {
        const container = document.getElementById('wa-history-container');
        if (!container) return;

        try {
            container.innerHTML = '<div style="padding: 20px; text-align: center; color: #64748b;"><i class="fa-solid fa-spinner fa-spin" style="margin-right: 8px;"></i> Loading history...</div>';
            const response = await api.getWhatsAppHistory();
            const list = response.data?.logs || [];

            if (list.length === 0) {
                container.innerHTML = '<div style="padding: 20px; text-align: center; color: #94a3b8; font-size: 13px;">No past WhatsApp broadcasts found.</div>';
                return;
            }

            const targetBadges = {
                'all': '<span style="background:#e0f2fe; color:#0369a1; padding:3px 8px; border-radius:6px; font-weight:700; font-size:11px;"> All Users</span>',
                'customers': '<span style="background:#fef3c7; color:#b45309; padding:3px 8px; border-radius:6px; font-weight:700; font-size:11px;">Customers</span>',
                'vendors': '<span style="background:#ffedd5; color:#c2410c; padding:3px 8px; border-radius:6px; font-weight:700; font-size:11px;">Vendors</span>',
                'drivers': '<span style="background:#dcfce7; color:#15803d; padding:3px 8px; border-radius:6px; font-weight:700; font-size:11px;">Drivers</span>'
            };

            const rows = list.map((item, index) => {
                const locSummary = [item.district, item.taluka].filter(Boolean).join(' / ') || 'All Locations';
                return `
                <tr style="border-bottom: 1px solid #f1f5f9;">
                    <td style="padding: 12px 14px; font-size: 12px; color: #64748b;">${index + 1}</td>
                    <td style="padding: 12px 14px;">
                        <div style="font-weight: 700; font-size: 13px; color: #1e293b; white-space: pre-wrap;">${this.escapeHtml(item.message)}</div>
                    </td>
                    <td style="padding: 12px 14px;">${targetBadges[item.target] || item.target}</td>
                    <td style="padding: 12px 14px; font-size: 12px; color: #334155; font-weight: 600;"> ${locSummary}</td>
                    <td style="padding: 12px 14px; font-size: 13px; font-weight: 800; color: #16a34a;">
                         ${item.sent_count} phone(s)
                    </td>
                    <td style="padding: 12px 14px; font-size: 12px; color: #94a3b8;">${item.created_at || 'Recently'}</td>
                </tr>
                `;
            }).join('');

            container.innerHTML = `
                <div style="overflow-x: auto;">
                    <table style="width: 100%; border-collapse: collapse; text-align: left;">
                        <thead>
                            <tr style="background: #f8fafc; border-bottom: 2px solid #e2e8f0; font-size: 11px; text-transform: uppercase; color: #64748b;">
                                <th style="padding: 10px 14px;">#</th>
                                <th style="padding: 10px 14px;">Message Body</th>
                                <th style="padding: 10px 14px;">Target Role</th>
                                <th style="padding: 10px 14px;">Location Filter</th>
                                <th style="padding: 10px 14px;">WhatsApp Reached</th>
                                <th style="padding: 10px 14px;">Sent Date</th>
                            </tr>
                        </thead>
                        <tbody>${rows}</tbody>
                    </table>
                </div>
            `;
        } catch (error) {
            container.innerHTML = `<div style="color: #ef4444; padding: 20px; font-size: 13px;">Failed to load history: ${error.message}</div>`;
        }
    }

    async handleWhatsAppFormSubmit() {
        const submitBtn    = document.getElementById('send-wa-btn');
        const templateName = document.getElementById('wa-template-name')?.value || 'text';
        const target       = document.querySelector('input[name="wa-target"]:checked')?.value || 'all';
        const state        = document.getElementById('wa-state')?.value || '';
        const district     = document.getElementById('wa-district')?.value || '';
        const taluka       = document.getElementById('wa-taluka')?.value || '';

        const dynamicMode  = this._waDynamicMode || 'single';
        const singleMsg    = document.getElementById('wa-message-body')?.value?.trim() || '';
        const customerMsg  = document.getElementById('wa-message-customer')?.value?.trim() || '';
        const vendorMsg    = document.getElementById('wa-message-vendor')?.value?.trim() || '';
        const driverMsg    = document.getElementById('wa-message-driver')?.value?.trim() || '';

        if (dynamicMode === 'single') {
            if (!singleMsg && !templateName) {
                this.showToast('Please enter a WhatsApp message body or select a template.', 'error');
                return;
            }
        } else {
            // Role-specific validation
            if (target === 'customers' && !customerMsg) {
                this.showToast('Please enter a message in the Customer tab before broadcasting.', 'error');
                return;
            }
            if (target === 'vendors' && !vendorMsg) {
                this.showToast('Please enter a message in the Vendor tab before broadcasting.', 'error');
                return;
            }
            if (target === 'drivers' && !driverMsg) {
                this.showToast('Please enter a message in the Driver tab before broadcasting.', 'error');
                return;
            }
            if (target === 'all' && !customerMsg && !vendorMsg && !driverMsg && !singleMsg) {
                this.showToast('Please enter at least one role message before broadcasting.', 'error');
                return;
            }
        }

        try {
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Broadcasting Dynamic WhatsApp Messages...';

            const payload = {
                message: dynamicMode === 'per_role' ? (customerMsg || vendorMsg || driverMsg || singleMsg) : singleMsg,
                customer_message: customerMsg,
                vendor_message: vendorMsg,
                driver_message: driverMsg,
                dynamic_mode: dynamicMode,
                template_name: templateName,
                language_code: 'en',
                components: [],
                target,
                state,
                district,
                taluka
            };

            const response = await api.sendWhatsAppBroadcast(payload);

            if (response.success) {
                this.showToast(`${response.message}`, 'success');
                if (dynamicMode === 'single') {
                    const el = document.getElementById('wa-message-body');
                    if (el) el.value = '';
                } else {
                    const cEl = document.getElementById('wa-message-customer');
                    const vEl = document.getElementById('wa-message-vendor');
                    const dEl = document.getElementById('wa-message-driver');
                    if (cEl) cEl.value = '';
                    if (vEl) vEl.value = '';
                    if (dEl) dEl.value = '';
                }
                this.updateWhatsAppPreview();
                this.fetchWhatsAppTargetSummary();
                this.loadWhatsAppHistory();
            } else {
                this.showToast(response.message || 'Failed to send WhatsApp broadcast.', 'error');
            }
        } catch (error) {
            this.showToast('Error: ' + error.message, 'error');
        } finally {
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<i class="fa-brands fa-whatsapp" style="font-size: 20px;"></i> Send Dynamic WhatsApp Broadcast Now';
        }
    }
/* -- Manual Subscription Assignment Methods ------------------------------- */

    async openAssignPlanModal(preselectedCustomerId = null) {
        this.availableAssignPlans = [];
        this.activeAssignPlanAddress = null;
        this._assignPlanCustomersCache = [];
        this._assignPlanSearchTimer = null;

        const customerSelect = document.getElementById("assign-plan-customer-select");
        const searchInput = document.getElementById("assign-plan-customer-search");
        const searchResults = document.getElementById("assign-plan-search-results");
        const clearBtn = document.getElementById("assign-plan-search-clear");
        const spinner = document.getElementById("assign-plan-search-spinner");

        const addressBox = document.getElementById("assign-plan-address-box");
        const addressContainer = document.getElementById("assign-plan-address-container");
        const plansSection = document.getElementById("assign-plan-plans-section");
        const plansList = document.getElementById("assign-plan-plans-list");
        const summarySection = document.getElementById("assign-plan-summary-section");
        const submitBtn = document.getElementById("assign-plan-submit-btn");
        const selectedInput = document.getElementById("assign-plan-selected-id");

        if (!customerSelect) return;

        if (searchInput) searchInput.value = '';
        if (searchResults) { searchResults.innerHTML = ''; searchResults.style.display = 'none'; }
        if (clearBtn) clearBtn.style.display = 'none';
        if (spinner) spinner.style.display = 'none';

        customerSelect.innerHTML = '<option value="">-- Or Choose From List --</option>';
        addressBox.innerHTML = '';
        addressContainer.style.display = 'none';
        plansSection.style.display = 'none';
        plansList.innerHTML = '';
        summarySection.style.display = 'none';
        if (selectedInput) selectedInput.value = '';
        if (submitBtn) {
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fa-solid fa-check-circle" style="margin-right: 4px;"></i> Assign Plan & Credit Wallet';
        }

        document.getElementById("assign-plan-modal").classList.remove("hidden");

        if (!this._assignPlanClickOutsideBound) {
            this._assignPlanClickOutsideBound = true;
            document.addEventListener('click', (e) => {
                const wrapper = document.querySelector('.assign-customer-search-wrapper');
                const resultsEl = document.getElementById('assign-plan-search-results');
                if (resultsEl && wrapper && !wrapper.contains(e.target)) {
                    resultsEl.style.display = 'none';
                }
            });
        }

        try {
            this.showLoader(true);
            const result = await api.getUsers({ limit: 50 });
            const customers = (result && result.data) ? (result.data.users || result.data.data || (Array.isArray(result.data) ? result.data : [])) : [];
            this._assignPlanCustomersCache = Array.isArray(customers) ? customers : [];

            this._populateAssignPlanCustomerSelect(this._assignPlanCustomersCache);

            if (preselectedCustomerId) {
                const matched = this._assignPlanCustomersCache.find(c => c.id == preselectedCustomerId);
                if (matched) {
                    this.selectAssignPlanCustomer(matched.id);
                } else {
                    customerSelect.value = preselectedCustomerId;
                    await this.onAssignPlanCustomerChange();
                }
            }
        } catch (err) {
            this.showToast("Failed to load customers: " + err.message, "error");
        } finally {
            this.showLoader(false);
        }
    }

    _populateAssignPlanCustomerSelect(customers) {
        const customerSelect = document.getElementById("assign-plan-customer-select");
        if (!customerSelect) return;
        const currentVal = customerSelect.value;
        customerSelect.innerHTML = '<option value="">-- Or Choose From List --</option>';
        customers.forEach(c => {
            const opt = document.createElement("option");
            opt.value = c.id;
            const mobile = c.phone_number || c.phone || '';
            const email = c.email || '';
            const extra = [email, mobile].filter(Boolean).join(' | ');
            opt.textContent = `${c.full_name || "Customer #" + c.id}${extra ? ' (' + extra + ')' : ''}`;
            customerSelect.appendChild(opt);
        });
        if (currentVal) customerSelect.value = currentVal;
    }

    onAssignPlanSearchInput(query) {
        const trimmed = (query || '').trim();
        const clearBtn = document.getElementById("assign-plan-search-clear");
        const spinner = document.getElementById("assign-plan-search-spinner");
        const resultsEl = document.getElementById("assign-plan-search-results");

        if (clearBtn) clearBtn.style.display = trimmed ? 'block' : 'none';

        // 1. Instant client-side search across cached customers
        if (this._assignPlanCustomersCache && this._assignPlanCustomersCache.length > 0) {
            const localMatches = this._filterAssignCustomers(this._assignPlanCustomersCache, trimmed);
            this.renderAssignPlanSearchResults(localMatches, trimmed);
            if (resultsEl) resultsEl.style.display = 'block';
        }

        // 2. Debounced server-side query on indexed fields (name, email, phone)
        if (this._assignPlanSearchTimer) {
            clearTimeout(this._assignPlanSearchTimer);
        }

        if (!trimmed) {
            if (spinner) spinner.style.display = 'none';
            return;
        }

        if (spinner) spinner.style.display = 'block';
        this._assignPlanSearchTimer = setTimeout(async () => {
            try {
                const res = await api.getUsers({ search: trimmed, limit: 20 });
                const serverUsers = (res && res.data) ? (res.data.users || res.data.data || (Array.isArray(res.data) ? res.data : [])) : [];
                if (Array.isArray(serverUsers)) {
                    serverUsers.forEach(u => {
                        if (!this._assignPlanCustomersCache.some(c => c.id === u.id)) {
                            this._assignPlanCustomersCache.push(u);
                        }
                    });
                    this._populateAssignPlanCustomerSelect(this._assignPlanCustomersCache);
                    this.renderAssignPlanSearchResults(serverUsers, trimmed);
                    if (resultsEl) resultsEl.style.display = 'block';
                }
            } catch (err) {
                console.error("Assign plan customer search error:", err);
            } finally {
                if (spinner) spinner.style.display = 'none';
            }
        }, 280);
    }

    _filterAssignCustomers(list, query) {
        if (!query) return list.slice(0, 20);
        const q = query.toLowerCase();
        return list.filter(c => {
            const name = (c.full_name || '').toLowerCase();
            const email = (c.email || '').toLowerCase();
            const phone = (c.phone_number || c.phone || '').toLowerCase();
            const idStr = String(c.id || '');
            return name.includes(q) || email.includes(q) || phone.includes(q) || idStr === q;
        }).slice(0, 20);
    }

    showAssignPlanDropdown(show) {
        const resultsEl = document.getElementById("assign-plan-search-results");
        if (!resultsEl) return;
        if (show) {
            const searchInput = document.getElementById("assign-plan-customer-search");
            const query = (searchInput?.value || '').trim();
            const matches = this._filterAssignCustomers(this._assignPlanCustomersCache || [], query);
            this.renderAssignPlanSearchResults(matches, query);
            resultsEl.style.display = 'block';
        } else {
            resultsEl.style.display = 'none';
        }
    }

    renderAssignPlanSearchResults(customers, query = '') {
        const resultsEl = document.getElementById("assign-plan-search-results");
        if (!resultsEl) return;

        if (!Array.isArray(customers) || customers.length === 0) {
            resultsEl.innerHTML = `
                <div style="padding: 16px; text-align: center; color: #64748b; font-size: 0.88rem;">
                    <i class="fa-solid fa-user-slash" style="margin-bottom: 6px; font-size: 18px; color: #94a3b8; display: block;"></i>
                    No customers found matching "<strong>${this.escapeHtml(query)}</strong>"
                </div>
            `;
            return;
        }

        resultsEl.innerHTML = customers.map(c => {
            const initials = (c.full_name || 'C')
                .split(' ')
                .map(n => n[0])
                .slice(0, 2)
                .join('')
                .toUpperCase();
            const mobile = c.phone_number || c.phone || 'No mobile';
            const email = c.email || 'No email';
            const location = [c.taluka, c.district].filter(Boolean).join(', ');

            return `
                <div class="assign-customer-search-item" onclick="app.selectAssignPlanCustomer(${c.id})" style="display: flex; align-items: center; gap: 12px; padding: 10px 14px; border-bottom: 1px solid #f1f5f9; cursor: pointer; transition: background 0.15s;">
                    <div class="assign-customer-avatar" style="width: 36px; height: 36px; border-radius: 50%; background: #e0e7ff; color: #4f46e5; font-weight: 700; font-size: 13px; display: flex; align-items: center; justify-content: center; flex-shrink: 0;">
                        ${initials}
                    </div>
                    <div style="flex: 1; min-width: 0;">
                        <div style="display: flex; align-items: center; gap: 6px;">
                            <strong style="color: #0f172a; font-size: 0.92rem; text-overflow: ellipsis; overflow: hidden; white-space: nowrap;">
                                ${this.escapeHtml(c.full_name || 'Customer #' + c.id)}
                            </strong>
                            <span style="background: #f1f5f9; color: #64748b; font-size: 0.72rem; padding: 1px 6px; border-radius: 4px; font-weight: 600;">#${c.id}</span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 12px; font-size: 0.8rem; color: #64748b; margin-top: 2px;">
                            <span><i class="fa-solid fa-phone" style="color: #10b981; font-size: 11px; margin-right: 3px;"></i>${this.escapeHtml(mobile)}</span>
                            <span style="text-overflow: ellipsis; overflow: hidden; white-space: nowrap;"><i class="fa-solid fa-envelope" style="color: #6366f1; font-size: 11px; margin-right: 3px;"></i>${this.escapeHtml(email)}</span>
                        </div>
                    </div>
                    ${location ? `<div style="font-size: 0.75rem; color: #94a3b8; text-align: right; white-space: nowrap;"><i class="fa-solid fa-location-dot" style="font-size: 10px; margin-right: 2px;"></i>${this.escapeHtml(location)}</div>` : ''}
                </div>
            `;
        }).join('');
    }

    selectAssignPlanCustomer(customerId) {
        const customerSelect = document.getElementById("assign-plan-customer-select");
        const searchInput = document.getElementById("assign-plan-customer-search");
        const resultsEl = document.getElementById("assign-plan-search-results");
        const clearBtn = document.getElementById("assign-plan-search-clear");

        if (resultsEl) resultsEl.style.display = 'none';

        const customer = (this._assignPlanCustomersCache || []).find(c => c.id == customerId);

        if (customerSelect) {
            let opt = customerSelect.querySelector(`option[value="${customerId}"]`);
            if (!opt && customer) {
                opt = document.createElement("option");
                opt.value = customer.id;
                const mobile = customer.phone_number || customer.phone || '';
                const email = customer.email || '';
                const extra = [email, mobile].filter(Boolean).join(' | ');
                opt.textContent = `${customer.full_name || "Customer #" + customer.id}${extra ? ' (' + extra + ')' : ''}`;
                customerSelect.appendChild(opt);
            }
            customerSelect.value = customerId;
        }

        if (searchInput && customer) {
            const mobile = customer.phone_number || customer.phone || '';
            searchInput.value = `${customer.full_name || 'Customer #' + customerId} (${mobile || customer.email || '#' + customerId})`;
        } else if (searchInput) {
            searchInput.value = `Customer #${customerId}`;
        }

        if (clearBtn) clearBtn.style.display = 'block';

        this.onAssignPlanCustomerChange();
    }

    clearAssignPlanSearch() {
        const searchInput = document.getElementById("assign-plan-customer-search");
        const customerSelect = document.getElementById("assign-plan-customer-select");
        const resultsEl = document.getElementById("assign-plan-search-results");
        const clearBtn = document.getElementById("assign-plan-search-clear");

        if (searchInput) searchInput.value = '';
        if (customerSelect) customerSelect.value = '';
        if (resultsEl) { resultsEl.innerHTML = ''; resultsEl.style.display = 'none'; }
        if (clearBtn) clearBtn.style.display = 'none';

        this.onAssignPlanCustomerChange();
    }
    async onAssignPlanCustomerChange() {
        const customerId = document.getElementById("assign-plan-customer-select").value;
        const searchInput = document.getElementById("assign-plan-customer-search");
        const clearBtn = document.getElementById("assign-plan-search-clear");
        if (customerId && searchInput && !searchInput.value) {
            const matched = (this._assignPlanCustomersCache || []).find(c => c.id == customerId);
            if (matched) {
                const mobile = matched.phone_number || matched.phone || '';
                searchInput.value = `${matched.full_name || 'Customer #' + customerId} (${mobile || matched.email || '#' + customerId})`;
                if (clearBtn) clearBtn.style.display = 'block';
            }
        }
        const addressContainer = document.getElementById("assign-plan-address-container");
        const addressBox = document.getElementById("assign-plan-address-box");
        const plansSection = document.getElementById("assign-plan-plans-section");
        const summarySection = document.getElementById("assign-plan-summary-section");
        const submitBtn = document.getElementById("assign-plan-submit-btn");

        plansSection.style.display = "none";
        summarySection.style.display = "none";
        if (submitBtn) submitBtn.disabled = true;
        this.activeAssignPlanAddress = null;
        this.customerAssignAddresses = [];

        if (!customerId) {
            addressContainer.style.display = "none";
            return;
        }

        addressContainer.style.display = "block";
        addressBox.innerHTML = '<div style="text-align: center; padding: 10px; color: #64748b;"><i class="fa-solid fa-spinner fa-spin"></i> Fetching customer address...</div>';

        try {
            const res = await api.getCustomerAddresses(customerId);
            const addresses = (res.success && res.data && res.data.addresses) ? res.data.addresses : [];
            this.customerAssignAddresses = addresses;

            if (addresses.length > 0) {
                if (addresses.length === 1) {
                    const addr = addresses[0];
                    this.activeAssignPlanAddress = {
                        latitude: addr.latitude || 0,
                        longitude: addr.longitude || 0,
                        pincode: addr.pincode || "",
                        full_address: addr.full_address || ""
                    };

                    addressBox.innerHTML = `
                        <div style="font-weight: 600; color: #0f172a; margin-bottom: 4px;">
                            <span class="badge" style="background: #e0e7ff; color: #3730a3; margin-right: 6px;">${this.escapeHtml(addr.address_type || "Saved Address")}</span>
                            ${this.escapeHtml(addr.full_address)}
                        </div>
                        <div style="font-size: 0.8rem; color: #64748b; display: flex; gap: 12px; align-items: center;">
                            <span><i class="fa-solid fa-hashtag"></i> Pincode: <strong>${this.escapeHtml(addr.pincode || "N/A")}</strong></span>
                            ${addr.latitude && addr.longitude ? `<span style="color: #16a34a;"><i class="fa-solid fa-crosshairs"></i> GPS (${addr.latitude}, ${addr.longitude})</span>` : '<span style="color: #ea580c;"><i class="fa-solid fa-location-dot"></i> Text Location</span>'}
                        </div>
                    `;
                } else {
                    let selectHtml = `<label style="font-weight: 600; font-size: 0.85rem; color: #475569; margin-bottom: 4px; display: block;">Select Customer Address (${addresses.length} saved):</label>`;
                    selectHtml += `<select id="assign-plan-address-select" class="form-control" onchange="app.onAssignPlanAddressSelectChange()" style="width: 100%; padding: 8px; font-size: 0.88rem; border-radius: 6px; border: 1px solid #cbd5e1; margin-bottom: 6px;">`;
                    addresses.forEach((addr, idx) => {
                        const label = `[${addr.address_type || "Address"}] ${addr.full_address} ${addr.pincode ? "(" + addr.pincode + ")" : ""} ${addr.is_default ? "(Default)" : ""}`;
                        selectHtml += `<option value="${idx}">${this.escapeHtml(label)}</option>`;
                    });
                    selectHtml += `</select>`;

                    const firstAddr = addresses[0];
                    this.activeAssignPlanAddress = {
                        latitude: firstAddr.latitude || 0,
                        longitude: firstAddr.longitude || 0,
                        pincode: firstAddr.pincode || "",
                        full_address: firstAddr.full_address || ""
                    };

                    addressBox.innerHTML = selectHtml;
                }

                // Automatically load available plans for selected address
                await this.loadAvailablePlansForCustomer();
            } else {
                addressBox.innerHTML = `
                    <div style="color: #64748b; font-size: 0.88rem; margin-bottom: 8px;">
                        <i class="fa-solid fa-info-circle" style="color: #3b82f6;"></i> No saved address found for this customer. Enter address or pincode manually:
                    </div>
                    <input type="text" id="assign-plan-custom-addr" class="form-control" placeholder="Enter street, area, or pincode..." style="width: 100%; padding: 8px; font-size: 0.88rem; border-radius: 6px; border: 1px solid #cbd5e1;">
                `;
                this.activeAssignPlanAddress = { is_custom: true };
            }
        } catch (err) {
            addressBox.innerHTML = '<div style="color: #ef4444;">Failed to load address. You can still search available plans manually.</div>';
            this.activeAssignPlanAddress = { is_custom: true };
        }
    }

    onAssignPlanAddressSelectChange() {
        const select = document.getElementById("assign-plan-address-select");
        if (!select || !this.customerAssignAddresses) return;
        const idx = parseInt(select.value, 10);
        const addr = this.customerAssignAddresses[idx];
        if (addr) {
            this.activeAssignPlanAddress = {
                latitude: addr.latitude || 0,
                longitude: addr.longitude || 0,
                pincode: addr.pincode || "",
                full_address: addr.full_address || ""
            };
            this.loadAvailablePlansForCustomer();
        }
    }

    async loadAvailablePlansForCustomer() {
        const customerId = document.getElementById("assign-plan-customer-select").value;
        if (!customerId) {
            this.showToast("Please select a customer first.", "warning");
            return;
        }

        const plansSection = document.getElementById("assign-plan-plans-section");
        const plansList = document.getElementById("assign-plan-plans-list");
        const countBadge = document.getElementById("assign-plan-count-badge");
        const summarySection = document.getElementById("assign-plan-summary-section");
        const submitBtn = document.getElementById("assign-plan-submit-btn");

        plansSection.style.display = "block";
        summarySection.style.display = "none";
        if (submitBtn) submitBtn.disabled = true;
        plansList.innerHTML = '<div style="grid-column: 1 / -1; text-align: center; padding: 20px; color: #4f46e5;"><i class="fa-solid fa-spinner fa-spin fa-2x"></i><p style="margin-top: 8px; font-weight: 500;">Searching available plans for address...</p></div>';

        let lat = 0, lng = 0, pincode = "", customAddr = "";

        if (this.activeAssignPlanAddress) {
            if (this.activeAssignPlanAddress.is_custom) {
                const input = document.getElementById("assign-plan-custom-addr");
                if (input && input.value.trim() !== "") {
                    customAddr = input.value.trim();
                    pincode = customAddr;
                }
            } else {
                lat = this.activeAssignPlanAddress.latitude || 0;
                lng = this.activeAssignPlanAddress.longitude || 0;
                pincode = this.activeAssignPlanAddress.pincode || "";
                customAddr = this.activeAssignPlanAddress.full_address || "";
            }
        }

        // If lat/lng are 0 and customAddr string exists, geocode via Google Maps Geocoder if loaded in browser
        if ((lat === 0 || lng === 0) && customAddr && typeof google !== "undefined" && google.maps && google.maps.Geocoder) {
            try {
                const geocoder = new google.maps.Geocoder();
                const results = await new Promise((resolve) => {
                    geocoder.geocode({ address: customAddr }, (res, status) => {
                        if (status === "OK" && res && res[0]) resolve(res[0]);
                        else resolve(null);
                    });
                });
                if (results && results.geometry && results.geometry.location) {
                    lat = results.geometry.location.lat();
                    lng = results.geometry.location.lng();
                }
            } catch (e) {
                console.warn("Browser geocoding fallback warning:", e);
            }
        }

        try {
            const res = await api.resolveServiceablePlans(lat, lng, pincode, customAddr);
            const plans = (res.success && res.data && res.data.plans) ? res.data.plans : [];
            this.availableAssignPlans = plans;

            countBadge.textContent = `${plans.length} plan(s) available`;

            if (plans.length === 0) {
                plansList.innerHTML = `
                    <div style="grid-column: 1 / -1; background: #fff1f2; border: 1px solid #fecdd3; padding: 16px; border-radius: 8px; text-align: center; color: #be123c;">
                        <i class="fa-solid fa-triangle-exclamation" style="font-size: 1.5rem; margin-bottom: 6px;"></i>
                        <h4 style="margin: 0 0 4px 0;">No Active Subscription Plans Found</h4>
                        <p style="margin: 0; font-size: 0.88rem;">No active subscription plans are registered in the service area matching this customer address.</p>
                    </div>
                `;
                return;
            }

            plansList.innerHTML = "";
            plans.forEach(p => {
                const planCard = document.createElement("div");
                planCard.className = "assign-plan-card";
                planCard.setAttribute("data-plan-id", p.id);
                planCard.style.cssText = "background: #ffffff; border: 2px solid #e2e8f0; border-radius: 8px; padding: 14px; cursor: pointer; transition: all 0.2s ease; position: relative;";
                
                planCard.innerHTML = `
                    <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px;">
                        <span class="badge" style="background: #f1f5f9; color: #475569; font-size: 0.75rem; font-weight: 600; padding: 2px 8px; border-radius: 4px;">
                            ${this.escapeHtml(p.sub_area_name || p.location || "Service Area")}
                        </span>
                        <span style="font-size: 1.1rem; font-weight: 800; color: #16a34a;">
                            ₹${parseFloat(p.price).toFixed(2)}
                        </span>
                    </div>
                    <h5 style="margin: 0 0 6px 0; font-size: 0.95rem; font-weight: 700; color: #0f172a;">
                        ${this.escapeHtml(p.plan_name)}
                    </h5>
                    <div style="font-size: 0.82rem; color: #64748b; line-height: 1.4; margin-bottom: 12px;">
                        <div><i class="fa-solid fa-calendar-check" style="color: #4f46e5; width: 16px;"></i> Duration: <strong>${p.duration} Days</strong></div>
                        <div><i class="fa-solid fa-utensils" style="color: #ea580c; width: 16px;"></i> Total Deliveries: <strong>${p.total_deliveries} Meals</strong></div>
                    </div>
                    <button type="button" class="btn btn-secondary select-plan-btn" style="width: 100%; padding: 6px 12px; font-size: 0.85rem; font-weight: 600; border-radius: 6px; border: 1px solid #cbd5e1; background: #f8fafc; color: #334155;">
                        Select Plan
                    </button>
                `;

                planCard.onclick = () => this.selectAssignPlan(p.id);
                plansList.appendChild(planCard);
            });

        } catch (err) {
            plansList.innerHTML = `<div style="grid-column: 1 / -1; color: #ef4444; text-align: center;">Failed to fetch plans: ${err.message}</div>`;
        }
    }

    selectAssignPlan(planId) {
        const plan = this.availableAssignPlans.find(p => p.id == planId);
        if (!plan) return;

        document.querySelectorAll(".assign-plan-card").forEach(card => {
            if (card.getAttribute("data-plan-id") == planId) {
                card.style.borderColor = "#4f46e5";
                card.style.background = "#faf5ff";
                const btn = card.querySelector(".select-plan-btn");
                if (btn) {
                    btn.style.background = "#4f46e5";
                    btn.style.color = "#ffffff";
                    btn.style.borderColor = "#4f46e5";
                    btn.innerHTML = '<i class="fa-solid fa-circle-check"></i> Selected';
                }
            } else {
                card.style.borderColor = "#e2e8f0";
                card.style.background = "#ffffff";
                const btn = card.querySelector(".select-plan-btn");
                if (btn) {
                    btn.style.background = "#f8fafc";
                    btn.style.color = "#334155";
                    btn.style.borderColor = "#cbd5e1";
                    btn.innerHTML = "Select Plan";
                }
            }
        });

        document.getElementById("assign-plan-selected-id").value = planId;
        const summarySection = document.getElementById("assign-plan-summary-section");
        const creditAmount = document.getElementById("assign-plan-credit-amount");
        const submitBtn = document.getElementById("assign-plan-submit-btn");

        if (creditAmount) {
            creditAmount.textContent = `₹${parseFloat(plan.price).toFixed(2)}`;
        }

        summarySection.style.display = "block";
        if (submitBtn) {
            submitBtn.disabled = false;
        }
    }

    async handleAssignPlanSubmit(event) {
        event.preventDefault();

        const customerId = document.getElementById("assign-plan-customer-select").value;
        const planId = document.getElementById("assign-plan-selected-id").value;
        const submitBtn = document.getElementById("assign-plan-submit-btn");

        if (!customerId || !planId) {
            this.showToast("Please select customer and a plan to assign.", "warning");
            return;
        }

        try {
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Assigning & Crediting Wallet...';

            const res = await api.assignPlanManually(customerId, planId);

            if (res.success) {
                this.showToast(`Plan Assigned Successfully! ₹${res.data.price_credited} credited to customer wallet.`, "success");
                this.closeModal("assign-plan-modal");

                // Refresh current view if applicable
                if (this.currentPath === "/admin/subscriptions") {
                    this.fetchSubscriptionsList();
                } else if (this.currentPath === "/admin/users") {
                    this.fetchUsersList();
                }
            } else {
                this.showToast(res.message || "Failed to assign plan.", "error");
            }
        } catch (err) {
            this.showToast("Error assigning plan: " + err.message, "error");
        } finally {
            if (submitBtn) {
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<i class="fa-solid fa-check-circle" style="margin-right: 4px;"></i> Assign Plan & Credit Wallet';
            }
        }
    }

    /**
     * Delivery Drivers View
     */
    async loadDriversView(container) {
        if (this.decodedQuery) {
            if (this.decodedQuery.has('country'))  this.driverQuery.country  = this.decodedQuery.get('country');
            if (this.decodedQuery.has('state'))    this.driverQuery.state    = this.decodedQuery.get('state');
            if (this.decodedQuery.has('district')) this.driverQuery.district = this.decodedQuery.get('district');
            if (this.decodedQuery.has('taluka'))   this.driverQuery.taluka   = this.decodedQuery.get('taluka');
        }

        if (this.driverQuery.district && !this.driverQuery.state) {
            for (const [st, dists] of Object.entries(LOCATION_DATA.districtsByState)) {
                if (dists.includes(this.driverQuery.district)) {
                    this.driverQuery.state = st;
                    this.driverQuery.country = 'India';
                    break;
                }
            }
        }

        container.innerHTML = `
            <div class="view-header">
                <h2>Delivery Drivers Directory</h2>
                <div class="view-actions">
                    <span class="badge badge-success" style="font-size: 13px; padding: 8px 14px; border-radius: 20px;">
                        <i class="fa-solid fa-motorcycle"></i> Drivers Network
                    </span>
                </div>
            </div>

            <div class="filter-bar" style="display: flex; flex-wrap: wrap; gap: 12px; align-items: center; background: var(--bg-card, #ffffff); padding: 14px 18px; border-radius: var(--radius-md, 12px); border: 1px solid var(--border-color, #e2e8f0); margin-bottom: 16px;">
                <div class="search-input-wrapper" style="flex: 1; min-width: 220px;">
                    <i class="fa-solid fa-magnifying-glass search-icon"></i>
                    <input type="text" id="driver-search" class="search-input" placeholder="Search by ID, name, phone, email, vehicle, vendor..." value="${this.driverQuery.search}">
                </div>
                
                <select id="driver-status-filter" class="filter-select" style="min-width: 140px;">
                    <option value="all" ${this.driverQuery.status === 'all' ? 'selected' : ''}>All Drivers</option>
                    <option value="online" ${this.driverQuery.status === 'online' ? 'selected' : ''}>Online Drivers</option>
                    <option value="offline" ${this.driverQuery.status === 'offline' ? 'selected' : ''}>Offline Drivers</option>
                    <option value="active" ${this.driverQuery.status === 'active' ? 'selected' : ''}>Active Status</option>
                    <option value="inactive" ${this.driverQuery.status === 'inactive' ? 'selected' : ''}>Inactive Status</option>
                </select>

                <select id="driver-sort-filter" class="filter-select" style="min-width: 160px; font-weight: 700; color: #1e40af; border-color: #bfdbfe; background: #eff6ff;" title="Sort delivery drivers date-wise">
                    <option value="newest" ${(this.driverQuery.sort === 'newest' || !this.driverQuery.sort) ? 'selected' : ''}>Newest Date First</option>
                    <option value="oldest" ${this.driverQuery.sort === 'oldest' ? 'selected' : ''}>Oldest Date First</option>
                    <option value="online" ${this.driverQuery.sort === 'online' ? 'selected' : ''}>Online First</option>
                </select>

                <div style="display: flex; align-items: center; gap: 6px; background: var(--bg-surface); border: 1px solid var(--border-color); border-radius: 8px; padding: 2px 8px;" title="Filter delivery drivers by registration date">
                    <i class="fa-regular fa-calendar" style="color: #2563eb; font-size: 12px;"></i>
                    <input type="date" id="driver-date-filter" class="form-control" value="${this.driverQuery.date || ''}" style="border: none; padding: 4px; font-size: 12px; font-weight: 600; width: 130px; background: transparent;">
                </div>

                <select id="driver-country-filter" class="filter-select" style="min-width: 140px; font-weight: 600;">
                    <option value="all">All Countries</option>
                    ${LOCATION_DATA.countries.map(c => `<option value="${c}" ${(this.driverQuery.country || 'India') === c ? 'selected' : ''}>${c}</option>`).join('')}
                </select>

                <select id="driver-state-filter" class="filter-select" style="min-width: 150px;">
                    <option value="all">All States</option>
                </select>

                <select id="driver-district-filter" class="filter-select" style="min-width: 150px;">
                    <option value="all">All Districts</option>
                </select>

                <select id="driver-taluka-filter" class="filter-select" style="min-width: 150px;">
                    <option value="all">All Talukas</option>
                </select>

                <select id="driver-region-filter" class="filter-select" style="min-width: 150px;">
                    <option value="all">All Regions</option>
                </select>

                <select id="driver-area-filter" class="filter-select" style="min-width: 150px;">
                    <option value="all">All Areas</option>
                </select>

                <button id="driver-reset-filters-btn" class="btn btn-secondary" style="font-size: 13px; font-weight: 600; padding: 8px 14px; border-radius: var(--radius-md, 8px); display: inline-flex; align-items: center; gap: 6px;" title="Reset all search & location filters">
                    <i class="fa-solid fa-rotate-left"></i> Reset
                </button>
            </div>

            <div id="driver-location-header" style="margin-bottom: 16px; display: flex; align-items: center; justify-content: space-between; background: var(--bg-surface, #f8fafc); border: 1px solid var(--border-color, #e2e8f0); border-radius: 12px; padding: 12px 18px; flex-wrap: wrap; gap: 12px;">
                <div style="display: flex; align-items: center; gap: 10px; font-size: 13px; font-weight: 700; color: var(--text-color, #1e293b);">
                    <i class="fa-solid fa-location-dot text-primary" style="font-size: 16px;"></i>
                    <span id="driver-location-breadcrumb">Filter Location: India</span>
                </div>
                <span id="driver-count-badge" class="badge badge-primary" style="font-size: 12px; font-weight: 800; padding: 6px 14px; border-radius: 20px;">
                    Loading Drivers...
                </span>
            </div>

            <div class="table-responsive">
                <table class="table" id="drivers-table">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Driver Info</th>
                            <th>Vehicle</th>
                            <th>Online Status</th>
                            <th>Associated Vendor</th>
                            <th>Location Details</th>
                            <th style="min-width: 140px;"><i class="fa-solid fa-arrow-down-wide-short text-primary" style="margin-right: 4px;"></i> Registered (Newest)</th>
                            <th class="text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="drivers-tbody">
                        <tr>
                            <td colspan="8" class="text-center">
                                <div style="padding: 30px;"><div class="spinner" style="margin: 0 auto; width: 30px; height: 30px;"></div></div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div id="driver-pagination" class="pagination-wrapper"></div>
        `;

        const searchInput    = document.getElementById('driver-search');
        const statusSelect   = document.getElementById('driver-status-filter');
        const countrySelect  = document.getElementById('driver-country-filter');
        const stateSelect    = document.getElementById('driver-state-filter');
        const districtSelect = document.getElementById('driver-district-filter');
        const talukaSelect   = document.getElementById('driver-taluka-filter');
        const resetBtn       = document.getElementById('driver-reset-filters-btn');

        const updateStateOptions = () => {
            const country = countrySelect.value;
            const states = LOCATION_DATA.statesByCountry[country] || [];
            stateSelect.innerHTML = '<option value="all">All States</option>' + 
                states.map(s => `<option value="${s}" ${this.driverQuery.state === s ? 'selected' : ''}>${s}</option>`).join('');
        };

        const updateDistrictOptions = () => {
            const state = stateSelect.value;
            const districts = LOCATION_DATA.districtsByState[state] || [];
            districtSelect.innerHTML = '<option value="all">All Districts</option>' + 
                districts.map(d => `<option value="${d}" ${this.driverQuery.district === d ? 'selected' : ''}>${d}</option>`).join('');
        };

        const regionSelect   = document.getElementById('driver-region-filter');
        const areaSelect     = document.getElementById('driver-area-filter');

        const updateTalukaOptions = () => {
            const district = districtSelect.value;
            const talukas = (LOCATION_DATA.talukasByDistrict && LOCATION_DATA.talukasByDistrict[district]) || [];
            talukaSelect.innerHTML = '<option value="all">All Talukas</option>' + 
                talukas.map(t => `<option value="${t}" ${this.driverQuery.taluka === t ? 'selected' : ''}>${t}</option>`).join('');
        };

        const updateRegionOptions = () => {
            if (!regionSelect) return;
            const district = districtSelect.value;
            const regions = (district !== 'all' && typeof LOCATION_DATA.getRegions === 'function') ? LOCATION_DATA.getRegions(district) : [];
            regionSelect.innerHTML = '<option value="all">All Regions</option>' + 
                regions.map(r => `<option value="${r}" ${this.driverQuery.region === r ? 'selected' : ''}>${r}</option>`).join('');
        };

        const updateAreaOptions = () => {
            if (!areaSelect) return;
            const district = districtSelect.value;
            const region = regionSelect ? regionSelect.value : 'all';
            let areas = [];
            if (district !== 'all' && typeof LOCATION_DATA.getAreas === 'function') {
                areas = LOCATION_DATA.getAreas(district, region);
            }
            areaSelect.innerHTML = '<option value="all">All Areas</option>' + 
                areas.map(a => `<option value="${a}" ${this.driverQuery.area === a ? 'selected' : ''}>${a}</option>`).join('');
        };

        // Initial option cascade
        updateStateOptions();
        updateDistrictOptions();
        updateTalukaOptions();
        updateRegionOptions();
        updateAreaOptions();

        // Event listeners
        searchInput.addEventListener('input', (e) => {
            clearTimeout(this.debouncedDriverSearchTimeout);
            this.debouncedDriverSearchTimeout = setTimeout(() => {
                this.driverQuery.search = e.target.value;
                this.driverQuery.page = 1;
                this.fetchDriversList();
            }, 400);
        });

        searchInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                clearTimeout(this.debouncedDriverSearchTimeout);
                this.driverQuery.search = e.target.value;
                this.driverQuery.page = 1;
                this.fetchDriversList();
            }
        });

        statusSelect.addEventListener('change', (e) => {
            this.driverQuery.status = e.target.value;
            this.driverQuery.page = 1;
            this.fetchDriversList();
        });

        const driverSortSelect = document.getElementById('driver-sort-filter');
        if (driverSortSelect) {
            driverSortSelect.addEventListener('change', (e) => {
                this.driverQuery.sort = e.target.value;
                this.driverQuery.page = 1;
                this.fetchDriversList();
            });
        }

        const driverDateInput = document.getElementById('driver-date-filter');
        if (driverDateInput) {
            driverDateInput.addEventListener('change', (e) => {
                this.driverQuery.date = e.target.value;
                this.driverQuery.page = 1;
                this.fetchDriversList();
            });
        }

        countrySelect.addEventListener('change', (e) => {
            this.driverQuery.country = e.target.value === 'all' ? '' : e.target.value;
            this.driverQuery.state = '';
            this.driverQuery.district = '';
            this.driverQuery.taluka = '';
            this.driverQuery.page = 1;
            updateStateOptions();
            updateDistrictOptions();
            updateTalukaOptions();
            this.fetchDriversList();
        });

        stateSelect.addEventListener('change', (e) => {
            this.driverQuery.state = e.target.value === 'all' ? '' : e.target.value;
            this.driverQuery.district = '';
            this.driverQuery.taluka = '';
            this.driverQuery.page = 1;
            updateDistrictOptions();
            updateTalukaOptions();
            this.fetchDriversList();
        });

        districtSelect.addEventListener('change', (e) => {
            this.driverQuery.district = e.target.value === 'all' ? '' : e.target.value;
            this.driverQuery.taluka = '';
            this.driverQuery.region = '';
            this.driverQuery.area = '';
            this.driverQuery.page = 1;
            updateTalukaOptions();
            updateRegionOptions();
            updateAreaOptions();
            this.fetchDriversList();
        });

        talukaSelect.addEventListener('change', (e) => {
            this.driverQuery.taluka = e.target.value === 'all' ? '' : e.target.value;
            this.driverQuery.page = 1;
            this.fetchDriversList();
        });

        if (regionSelect) {
            regionSelect.addEventListener('change', (e) => {
                this.driverQuery.region = e.target.value === 'all' ? '' : e.target.value;
                this.driverQuery.area = '';
                this.driverQuery.page = 1;
                updateAreaOptions();
                this.fetchDriversList();
            });
        }

        if (areaSelect) {
            areaSelect.addEventListener('change', (e) => {
                this.driverQuery.area = e.target.value === 'all' ? '' : e.target.value;
                this.driverQuery.page = 1;
                this.fetchDriversList();
            });
        }

        if (resetBtn) {
            resetBtn.addEventListener('click', () => {
                this.driverQuery = { search: '', status: 'all', sort: 'newest', date: '', country: 'India', state: '', district: '', taluka: '', page: 1, limit: 10 };
                const dSort = document.getElementById('driver-sort-filter'); if (dSort) dSort.value = 'newest';
                const dDate = document.getElementById('driver-date-filter'); if (dDate) dDate.value = '';
                searchInput.value = '';
                statusSelect.value = 'all';
                countrySelect.value = 'India';
                updateStateOptions();
                updateDistrictOptions();
                updateTalukaOptions();
                this.fetchDriversList();
            });
        }

        // Trigger fetch
        await this.fetchDriversList();
    }

    async fetchDriversList() {
        const tbody = document.getElementById('drivers-tbody');
        if (!tbody) return;

        tbody.innerHTML = `
            <tr>
                <td colspan="8" class="text-center">
                    <div style="padding: 20px;"><div class="spinner" style="margin: 0 auto; width: 28px; height: 28px;"></div></div>
                </td>
            </tr>
        `;

        try {
            const result = await api.getDrivers(this.driverQuery);
            const drivers = result.data.drivers || [];
            const pagination = result.data.pagination;

            // Update Location Breadcrumb & Count Badge
            const locBreadcrumb = document.getElementById('driver-location-breadcrumb');
            const countBadge = document.getElementById('driver-count-badge');

            if (locBreadcrumb) {
                const parts = [];
                if (this.driverQuery.country) parts.push(this.driverQuery.country);
                else parts.push('All Countries');
                if (this.driverQuery.state) parts.push(this.driverQuery.state);
                if (this.driverQuery.district) parts.push(this.driverQuery.district);
                if (this.driverQuery.taluka) parts.push(this.driverQuery.taluka);
                locBreadcrumb.innerHTML = 'Location Filter: <span style="color: var(--accent-primary, #fe750b);">' + parts.join(' &gt; ') + '</span>';
            }

            if (countBadge) {
                const total = pagination ? pagination.total_records : drivers.length;
                countBadge.textContent = total + ' Delivery Driver' + (total === 1 ? '' : 's') + ' Found';
            }

            if (drivers.length === 0) {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="8" class="text-center" style="padding: 40px; color: var(--text-secondary);">
                            <i class="fa-solid fa-motorcycle" style="font-size: 32px; margin-bottom: 12px; display: block; color: var(--text-muted);"></i>
                            No delivery drivers found matching the selected location or search query.
                        </td>
                    </tr>
                `;
                document.getElementById('driver-pagination').innerHTML = '';
                return;
            }

            tbody.innerHTML = drivers.map(driver => {
                const isOnline = driver.is_online == 1;
                const onlineBadge = isOnline 
                    ? '<span class="badge" style="background:#dcfce7; color:#15803d; border:1px solid #86efac; font-size:11px; padding:3px 8px; font-weight:700;"><i class="fa-solid fa-circle" style="font-size:7px; color:#16a34a; margin-right:4px;"></i>Online</span>' 
                    : '<span class="badge" style="background:#f1f5f9; color:#64748b; border:1px solid #cbd5e1; font-size:11px; padding:3px 8px; font-weight:600;"><i class="fa-regular fa-circle" style="font-size:7px; margin-right:4px;"></i>Offline</span>';
                
                const createdDate = new Date(driver.created_at);
                const dateStr = !isNaN(createdDate.getTime()) ? createdDate.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' }) : 'N/A';
                const timeStr = !isNaN(createdDate.getTime()) ? createdDate.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true }) : '';
                const isToday = !isNaN(createdDate.getTime()) && (new Date().toDateString() === createdDate.toDateString());
                const isRecent = !isNaN(createdDate.getTime()) && (Date.now() - createdDate.getTime() < 48 * 3600 * 1000);

                const locationStr = [driver.taluka, driver.district, driver.state, driver.country].filter(Boolean).join(', ') || 'Not set';
                const resolvedDriverLoc = (typeof LOCATION_DATA !== 'undefined' && typeof LOCATION_DATA.resolveLocation === 'function')
                    ? LOCATION_DATA.resolveLocation((driver.address || '') + ' ' + (driver.taluka || ''), driver.district, driver.taluka)
                    : { area: '', region: '' };
                const driverAreaBadge = (typeof LOCATION_DATA !== 'undefined' && typeof LOCATION_DATA.renderAreaRegionBadge === 'function')
                    ? LOCATION_DATA.renderAreaRegionBadge(resolvedDriverLoc.area, resolvedDriverLoc.region)
                    : '';

                const vendorCell = driver.vendor_id > 0
                    ? `<button class="btn btn-sm" style="background:#eef2ff; color:#4338ca; border:1px solid #c7d2fe; border-radius:16px; font-weight:600; font-size:11px; padding:2px 8px; cursor:pointer;" onclick="app.viewVendorDetails(${driver.vendor_id}, 'drivers')" title="Click to view Vendor details & associated fleet"><i class="fa-solid fa-shop"></i> ${this.escapeHtml(driver.vendor_name || 'Vendor #' + driver.vendor_id)}</button>`
                    : `<span style="color:var(--text-muted); font-size:11px; font-style:italic;">Independent</span>`;

                return `
                    <tr style="${isOnline ? 'background: rgba(16, 185, 129, 0.02);' : ''}">
                        <td><strong>#${driver.id}</strong></td>
                        <td>
                            <div style="display: flex; flex-direction: column;">
                                <span class="font-semibold">${this.escapeHtml(driver.full_name || '')}</span>
                                <span style="font-size: 11px; color: var(--text-muted);"><i class="fa-solid fa-phone"></i> ${this.escapeHtml(driver.phone_number || 'N/A')}</span>
                            </div>
                        </td>
                        <td><span style="font-family: monospace; font-weight: 700; background: var(--bg-surface); padding: 3px 8px; border-radius: 4px; border: 1px solid var(--border-color); font-size: 12px;">${this.escapeHtml(driver.vehicle_number || 'N/A')}</span></td>
                        <td>${onlineBadge}</td>
                        <td>${vendorCell}</td>
                        <td>
                            <div style="display: flex; flex-direction: column; gap: 3px;">
                                <span style="font-size: 12px; color: var(--text-secondary);"><i class="fa-solid fa-location-dot text-primary"></i> ${this.escapeHtml(locationStr)}</span>
                                ${driverAreaBadge}
                            </div>
                        </td>
                        <td>
                            <div style="display: flex; flex-direction: column; gap: 2px;">
                                <span style="display: inline-flex; align-items: center; gap: 5px; font-weight: 700; font-size: 12px; color: var(--text-primary);">
                                    <i class="fa-regular fa-calendar-check text-primary" style="font-size: 11px;"></i> ${dateStr}
                                    ${isToday ? '<span class="badge" style="background:#dcfce7; color:#15803d; border:1px solid #86efac; font-size:9px; font-weight:800; padding:1px 5px; border-radius:10px;">TODAY</span>' : (isRecent ? '<span class="badge" style="background:#eff6ff; color:#1d4ed8; border:1px solid #bfdbfe; font-size:9px; font-weight:800; padding:1px 5px; border-radius:10px;">NEW</span>' : '')}
                                </span>
                                ${timeStr ? `<span style="font-size: 11px; color: var(--text-muted); padding-left: 16px;"><i class="fa-regular fa-clock" style="font-size: 10px;"></i> ${timeStr}</span>` : ''}
                            </div>
                        </td>
                        <td class="text-right">
                            <div class="table-actions" style="justify-content: flex-end;">
                                <button class="btn btn-secondary btn-icon" title="View Driver Details" onclick="app.viewDriverDetails(${driver.id})">
                                    <i class="fa-solid fa-eye"></i>
                                </button>
                                <button class="btn btn-secondary btn-icon" title="Edit Driver" onclick="app.editDriverRoute(${driver.id})">
                                    <i class="fa-solid fa-pen-to-square"></i>
                                </button>
                            </div>
                        </td>
                    </tr>
                `;
            }).join('');

            this.renderPagination('driver-pagination', pagination, (newPage) => {
                this.driverQuery.page = newPage;
                this.fetchDriversList();
            });

        } catch (error) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="13" class="text-center text-danger" style="padding: 24px;">
                        Failed to load delivery drivers: ${error.message}
                    </td>
                </tr>
            `;
        }
    }

    /**
     * Edit Driver Route Redirect
     */
    editDriverRoute(id) {
        this.navigateTo('/admin/drivers/edit?id=' + id);
    }

    /**
     * Edit Driver View
     */
    async loadEditDriverView(container) {
        const id = parseInt(this.decodedQuery.get('id'));
        if (!id) {
            this.navigateTo('/admin/drivers');
            return;
        }

        container.innerHTML = `
            <div class="view-header">
                <h2>Modify Delivery Driver</h2>
                <a href="/admin/drivers" class="btn btn-secondary" data-link>
                    <i class="fa-solid fa-arrow-left"></i> Back to List
                </a>
            </div>
            <div style="display: flex; justify-content: center; padding: 40px;">
                <div class="spinner" style="width: 32px; height: 32px;"></div>
            </div>
        `;

        let driver = null;
        try {
            const result = await api.getDriverDetails(id);
            if (result && result.data && result.data.driver) {
                driver = result.data.driver;
            }
        } catch (e) {
            console.error('Failed to fetch driver details:', e);
        }

        if (!driver) {
            this.showToast('Delivery driver not found.', 'error');
            this.navigateTo('/admin/drivers');
            return;
        }

        container.innerHTML = `
            <div class="view-header">
                <div>
                    <h2>Modify Delivery Driver: ${this.escapeHtml(driver.full_name || '')}</h2>
                    <span style="font-size: 13px; color: var(--text-secondary);">Driver ID: #${driver.id} • Vehicle: ${this.escapeHtml(driver.vehicle_number || 'N/A')}</span>
                </div>
                <a href="/admin/drivers" class="btn btn-secondary" data-link>
                    <i class="fa-solid fa-arrow-left"></i> Back to List
                </a>
            </div>

            <div class="profile-card" style="margin: 0 auto; max-width: 720px; padding: 28px;">
                <form id="edit-driver-form" onsubmit="app.handleEditDriver(event, ${driver.id})">
                    <h3 style="font-size: 16px; font-weight: 700; color: var(--text-primary); margin-bottom: 16px; display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-motorcycle" style="color: var(--accent-primary);"></i> Driver & Vehicle Information
                    </h3>

                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px;">
                        <div class="form-group">
                            <label class="form-label" for="driver-edit-name">Full Name *</label>
                            <input type="text" id="driver-edit-name" class="form-control" value="${this.escapeHtml(driver.full_name || '')}" required>
                            <div class="form-error hidden" id="error-name"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="driver-edit-email">Email Address *</label>
                            <input type="email" id="driver-edit-email" class="form-control" value="${this.escapeHtml(driver.email || '')}" required>
                            <div class="form-error hidden" id="error-email"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="driver-edit-phone">Phone Number *</label>
                            <input type="text" id="driver-edit-phone" class="form-control" value="${this.escapeHtml(driver.phone_number || '')}" placeholder="+91 9876543210" required>
                            <div class="form-error hidden" id="error-phone"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="driver-edit-vehicle">Vehicle Number *</label>
                            <input type="text" id="driver-edit-vehicle" class="form-control" value="${this.escapeHtml(driver.vehicle_number || '')}" placeholder="MH12AB1234" required>
                            <div class="form-error hidden" id="error-vehicle"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="driver-edit-password">Password / Reset Password</label>
                            <input type="text" id="driver-edit-password" class="form-control" value="${this.escapeHtml(driver.password || '')}" placeholder="Leave blank to keep current">
                            <div class="form-error hidden" id="error-password"></div>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="driver-edit-capacity">Max Delivery Capacity</label>
                            <input type="number" id="driver-edit-capacity" class="form-control" min="1" max="20" value="${driver.max_capacity || 3}">
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="driver-edit-online">Live Duty Status</label>
                            <select id="driver-edit-online" class="form-control">
                                <option value="1" ${driver.is_online ? 'selected' : ''}>Online (Ready for Orders)</option>
                                <option value="0" ${!driver.is_online ? 'selected' : ''}>Offline (Off Duty)</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="driver-edit-status">Account Status</label>
                            <select id="driver-edit-status" class="form-control">
                                <option value="active" ${driver.status === 'active' ? 'selected' : ''}>Active (Enabled)</option>
                                <option value="inactive" ${driver.status === 'inactive' ? 'selected' : ''}>Inactive (Blocked)</option>
                            </select>
                        </div>
                    </div>

                    <h3 style="font-size: 16px; font-weight: 700; color: var(--text-primary); margin-top: 24px; margin-bottom: 16px; border-top: 1px solid var(--border-color); padding-top: 20px; display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-location-dot" style="color: var(--accent-primary);"></i> Location & Operating Area
                    </h3>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px;">
                        <div class="form-group">
                            <label class="form-label" for="driver-edit-country">Country</label>
                            <select id="driver-edit-country" class="form-control"></select>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="driver-edit-state">State</label>
                            <select id="driver-edit-state" class="form-control"></select>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="driver-edit-district">District</label>
                            <select id="driver-edit-district" class="form-control"></select>
                        </div>
                        <div class="form-group">
                            <label class="form-label" for="driver-edit-taluka">Taluka</label>
                            <select id="driver-edit-taluka" class="form-control"></select>
                        </div>
                    </div>
                    
                    <div style="display: flex; gap: 12px; margin-top: 28px; border-top: 1px solid var(--border-color); padding-top: 20px;">
                        <button type="submit" class="btn btn-primary" style="flex: 1;">
                            <i class="fa-solid fa-check"></i> Save Driver Changes
                        </button>
                        <a href="/admin/drivers" class="btn btn-secondary" style="flex: 1; text-align: center;" data-link>Cancel</a>
                    </div>
                </form>
            </div>
        `;

        this.initLocationDropdowns(
            document.getElementById('driver-edit-country'),
            document.getElementById('driver-edit-state'),
            document.getElementById('driver-edit-district'),
            document.getElementById('driver-edit-taluka'),
            {
                country: driver.country || 'India',
                state: driver.state || '',
                district: driver.district || '',
                taluka: driver.taluka || ''
            }
        );
    }

    /**
     * Edit Driver handler
     */
    async handleEditDriver(e, id) {
        e.preventDefault();

        const name = document.getElementById('driver-edit-name').value.trim();
        const email = document.getElementById('driver-edit-email').value.trim();
        const phone = document.getElementById('driver-edit-phone').value.trim();
        const vehicle = document.getElementById('driver-edit-vehicle').value.trim().toUpperCase();
        const password = document.getElementById('driver-edit-password') ? document.getElementById('driver-edit-password').value.trim() : '';
        const isOnline = document.getElementById('driver-edit-online') ? document.getElementById('driver-edit-online').value === '1' : false;
        const status = document.getElementById('driver-edit-status') ? document.getElementById('driver-edit-status').value : 'active';
        const capacity = document.getElementById('driver-edit-capacity') ? parseInt(document.getElementById('driver-edit-capacity').value) || 3 : 3;

        const country = document.getElementById('driver-edit-country') ? document.getElementById('driver-edit-country').value : 'India';
        const state = document.getElementById('driver-edit-state') ? document.getElementById('driver-edit-state').value : '';
        const district = document.getElementById('driver-edit-district') ? document.getElementById('driver-edit-district').value : '';
        const taluka = document.getElementById('driver-edit-taluka') ? document.getElementById('driver-edit-taluka').value : '';

        this.clearFormErrors(['name', 'email', 'phone', 'vehicle', 'password']);

        let valid = true;
        if (name.length < 2) {
            this.showError('name', 'Full name must be at least 2 characters.');
            valid = false;
        }
        if (!this.validateEmail(email)) {
            this.showError('email', 'Please enter a valid email address.');
            valid = false;
        }
        if (vehicle.length < 2) {
            this.showError('vehicle', 'Please enter a valid vehicle number.');
            valid = false;
        }

        if (!valid) return;

        this.showLoader(true);
        try {
            await api.editDriver({
                id,
                full_name: name,
                email,
                phone_number: phone,
                vehicle_number: vehicle,
                password,
                is_online: isOnline,
                status,
                max_capacity: capacity,
                country,
                state,
                district,
                taluka
            });
            this.showToast('Delivery driver updated successfully.', 'success');
            this.navigateTo('/admin/drivers');
        } catch (error) {
            this.showToast(error.message, 'error');
            this.showError('email', error.message.includes('email') ? error.message : 'Failed to update driver.');
        } finally {
            this.showLoader(false);
        }
    }
    /**
     * Location Revenue Analytics View
     */
    async loadRevenueView(container) {
        if (this.decodedQuery) {
            if (this.decodedQuery.has('country'))  this.revenueQuery.country  = this.decodedQuery.get('country');
            if (this.decodedQuery.has('state'))    this.revenueQuery.state    = this.decodedQuery.get('state');
            if (this.decodedQuery.has('district')) this.revenueQuery.district = this.decodedQuery.get('district');
            if (this.decodedQuery.has('taluka'))   this.revenueQuery.taluka   = this.decodedQuery.get('taluka');
        }

        if (this.revenueQuery.district && !this.revenueQuery.state) {
            for (const [st, dists] of Object.entries(LOCATION_DATA.districtsByState)) {
                if (dists.includes(this.revenueQuery.district)) {
                    this.revenueQuery.state = st;
                    this.revenueQuery.country = 'India';
                    break;
                }
            }
        }

        container.innerHTML = `
            <div class="view-header">
                <h2>Location Revenue & Order Analytics</h2>
                <div class="view-actions">
                    <span class="badge badge-success" style="font-size: 13px; padding: 8px 14px; border-radius: 20px; background: rgba(16, 185, 129, 0.15); color: #059669; border: 1px solid rgba(16, 185, 129, 0.3);">
                        <i class="fa-solid fa-wallet"></i> Live Revenue Tracking
                    </span>
                </div>
            </div>

            <div class="filter-bar" style="display: flex; flex-wrap: wrap; gap: 12px; align-items: center; background: var(--bg-card, #ffffff); padding: 14px 18px; border-radius: var(--radius-md, 12px); border: 1px solid var(--border-color, #e2e8f0); margin-bottom: 16px;">
                <div class="search-input-wrapper" style="flex: 1; min-width: 220px;">
                    <i class="fa-solid fa-magnifying-glass search-icon"></i>
                    <input type="text" id="revenue-search" class="search-input" placeholder="Search customer, email, phone, or hotel..." value="${this.revenueQuery.search}">
                </div>
                
                <select id="revenue-status-filter" class="filter-select" style="min-width: 130px;">
                    <option value="all" ${this.revenueQuery.status === 'all' ? 'selected' : ''}>All Statuses</option>
                    <option value="completed" ${this.revenueQuery.status === 'completed' ? 'selected' : ''}>Completed</option>
                    <option value="delivered" ${this.revenueQuery.status === 'delivered' ? 'selected' : ''}>Delivered</option>
                    <option value="pending" ${this.revenueQuery.status === 'pending' ? 'selected' : ''}>Pending</option>
                    <option value="cancelled" ${this.revenueQuery.status === 'cancelled' ? 'selected' : ''}>Cancelled</option>
                </select>

                <select id="revenue-country-filter" class="filter-select" style="min-width: 140px; font-weight: 600;">
                    <option value="all">All Countries</option>
                    ${LOCATION_DATA.countries.map(c => `<option value="${c}" ${(this.revenueQuery.country || 'India') === c ? 'selected' : ''}>${c}</option>`).join('')}
                </select>

                <select id="revenue-state-filter" class="filter-select" style="min-width: 150px;">
                    <option value="all">All States</option>
                </select>

                <select id="revenue-district-filter" class="filter-select" style="min-width: 150px;">
                    <option value="all">All Districts</option>
                </select>

                <select id="revenue-taluka-filter" class="filter-select" style="min-width: 150px;">
                    <option value="all">All Talukas</option>
                </select>
            </div>

            <!-- Location Summary Cards -->
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 20px;">
                <div class="stat-card" style="padding: 16px; border-left: 4px solid #10b981;">
                    <div class="stat-info">
                        <span class="stat-label">Filtered Gross Revenue</span>
                        <span class="stat-value" id="rev-summary-total" style="color: #10b981; font-size: 22px;">₹0.00</span>
                    </div>
                    <div class="stat-icon" style="background: rgba(16, 185, 129, 0.15); color: #10b981;"><i class="fa-solid fa-indian-rupee-sign"></i></div>
                </div>
                <div class="stat-card" style="padding: 16px; border-left: 4px solid #3b82f6;">
                    <div class="stat-info">
                        <span class="stat-label">Total Orders</span>
                        <span class="stat-value" id="rev-summary-orders" style="color: #3b82f6; font-size: 22px;">0</span>
                    </div>
                    <div class="stat-icon" style="background: rgba(59, 130, 246, 0.15); color: #3b82f6;"><i class="fa-solid fa-receipt"></i></div>
                </div>
                <div class="stat-card" style="padding: 16px; border-left: 4px solid #8b5cf6;">
                    <div class="stat-info">
                        <span class="stat-label">Average Order Value</span>
                        <span class="stat-value" id="rev-summary-aov" style="color: #8b5cf6; font-size: 22px;">₹0.00</span>
                    </div>
                    <div class="stat-icon" style="background: rgba(139, 92, 246, 0.15); color: #8b5cf6;"><i class="fa-solid fa-calculator"></i></div>
                </div>
                <div class="stat-card" style="padding: 16px; border-left: 4px solid #f59e0b;">
                    <div class="stat-info">
                        <span class="stat-label">Unique Customers</span>
                        <span class="stat-value" id="rev-summary-customers" style="color: #f59e0b; font-size: 22px;">0</span>
                    </div>
                    <div class="stat-icon" style="background: rgba(245, 158, 11, 0.15); color: #f59e0b;"><i class="fa-solid fa-user-group"></i></div>
                </div>
            </div>

            <div id="revenue-location-header" style="margin-bottom: 16px; display: flex; align-items: center; justify-content: space-between; background: var(--bg-surface, #f8fafc); border: 1px solid var(--border-color, #e2e8f0); border-radius: 12px; padding: 12px 18px; flex-wrap: wrap; gap: 12px;">
                <div style="display: flex; align-items: center; gap: 10px; font-size: 13px; font-weight: 700; color: var(--text-color, #1e293b);">
                    <i class="fa-solid fa-location-dot text-primary" style="font-size: 16px;"></i>
                    <span id="revenue-location-breadcrumb">Filter Location: India</span>
                </div>
                <span id="revenue-count-badge" class="badge badge-primary" style="font-size: 12px; font-weight: 800; padding: 6px 14px; border-radius: 20px;">
                    Loading Revenue Data...
                </span>
            </div>

            <div class="table-responsive">
                <table class="table" id="revenue-table">
                    <thead>
                        <tr>
                            <th>Order ID</th>
                            <th>Customer & Contact</th>
                            <th>Customer Delivery Address</th>
                            <th>Hotel / Restaurant</th>
                            <th>Payment & Status</th>
                            <th>Order Amount</th>
                            <th>Order Date</th>
                        </tr>
                    </thead>
                    <tbody id="revenue-tbody">
                        <tr>
                            <td colspan="7" class="text-center">
                                <div style="padding: 30px;"><div class="spinner" style="margin: 0 auto; width: 30px; height: 30px;"></div></div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <div id="revenue-pagination" class="pagination-wrapper"></div>
        `;

        const searchInput    = document.getElementById('revenue-search');
        const statusSelect   = document.getElementById('revenue-status-filter');
        const countrySelect  = document.getElementById('revenue-country-filter');
        const stateSelect    = document.getElementById('revenue-state-filter');
        const districtSelect = document.getElementById('revenue-district-filter');
        const talukaSelect   = document.getElementById('revenue-taluka-filter');

        const updateStateOptions = () => {
            const country = countrySelect.value;
            const states = LOCATION_DATA.statesByCountry[country] || [];
            stateSelect.innerHTML = '<option value="all">All States</option>' + 
                states.map(s => `<option value="${s}" ${this.revenueQuery.state === s ? 'selected' : ''}>${s}</option>`).join('');
        };

        const updateDistrictOptions = () => {
            const state = stateSelect.value;
            const districts = LOCATION_DATA.districtsByState[state] || [];
            districtSelect.innerHTML = '<option value="all">All Districts</option>' + 
                districts.map(d => `<option value="${d}" ${this.revenueQuery.district === d ? 'selected' : ''}>${d}</option>`).join('');
        };

        const updateTalukaOptions = () => {
            const district = districtSelect.value;
            const talukas = LOCATION_DATA.talukasByDistrict[district] || [];
            talukaSelect.innerHTML = '<option value="all">All Talukas</option>' + 
                talukas.map(t => `<option value="${t}" ${this.revenueQuery.taluka === t ? 'selected' : ''}>${t}</option>`).join('');
        };

        // Initial option cascade
        updateStateOptions();
        updateDistrictOptions();
        updateTalukaOptions();

        // Event listeners
        searchInput.addEventListener('input', (e) => {
            clearTimeout(this.debouncedSearchTimeout);
            this.debouncedSearchTimeout = setTimeout(() => {
                this.revenueQuery.search = e.target.value;
                this.revenueQuery.page = 1;
                this.fetchRevenueList();
            }, 400);
        });

        statusSelect.addEventListener('change', (e) => {
            this.revenueQuery.status = e.target.value;
            this.revenueQuery.page = 1;
            this.fetchRevenueList();
        });

        countrySelect.addEventListener('change', (e) => {
            this.revenueQuery.country = e.target.value === 'all' ? '' : e.target.value;
            this.revenueQuery.state = '';
            this.revenueQuery.district = '';
            this.revenueQuery.taluka = '';
            this.revenueQuery.page = 1;
            updateStateOptions();
            updateDistrictOptions();
            updateTalukaOptions();
            this.fetchRevenueList();
        });

        stateSelect.addEventListener('change', (e) => {
            this.revenueQuery.state = e.target.value === 'all' ? '' : e.target.value;
            this.revenueQuery.district = '';
            this.revenueQuery.taluka = '';
            this.revenueQuery.page = 1;
            updateDistrictOptions();
            updateTalukaOptions();
            this.fetchRevenueList();
        });

        districtSelect.addEventListener('change', (e) => {
            this.revenueQuery.district = e.target.value === 'all' ? '' : e.target.value;
            this.revenueQuery.taluka = '';
            this.revenueQuery.page = 1;
            updateTalukaOptions();
            this.fetchRevenueList();
        });

        talukaSelect.addEventListener('change', (e) => {
            this.revenueQuery.taluka = e.target.value === 'all' ? '' : e.target.value;
            this.revenueQuery.page = 1;
            this.fetchRevenueList();
        });

        // Trigger fetch
        await this.fetchRevenueList();
    }

    async fetchRevenueList() {
        const tbody = document.getElementById('revenue-tbody');
        if (!tbody) return;

        tbody.innerHTML = `
            <tr>
                <td colspan="7" class="text-center">
                    <div style="padding: 20px;"><div class="spinner" style="margin: 0 auto; width: 28px; height: 28px;"></div></div>
                </td>
            </tr>
        `;

        try {
            const result = await api.getRevenueReport(this.revenueQuery);
            const data = result.data;
            const metrics = data.metrics;
            const orders = data.orders;
            const pagination = data.pagination;

            // Update Summary Metric Cards
            const summaryTotal = document.getElementById('rev-summary-total');
            const summaryOrders = document.getElementById('rev-summary-orders');
            const summaryAov = document.getElementById('rev-summary-aov');
            const summaryCustomers = document.getElementById('rev-summary-customers');

            if (summaryTotal) summaryTotal.textContent = `₹${metrics.total_revenue}`;
            if (summaryOrders) summaryOrders.textContent = metrics.total_orders;
            if (summaryAov) summaryAov.textContent = `₹${metrics.avg_order_value}`;
            if (summaryCustomers) summaryCustomers.textContent = metrics.unique_customers;

            // Update Location Breadcrumb & Count Badge
            const locBreadcrumb = document.getElementById('revenue-location-breadcrumb');
            const countBadge = document.getElementById('revenue-count-badge');

            if (locBreadcrumb) {
                const parts = [];
                if (this.revenueQuery.country) parts.push(this.revenueQuery.country);
                else parts.push('All Countries');
                if (this.revenueQuery.state) parts.push(this.revenueQuery.state);
                if (this.revenueQuery.district) parts.push(this.revenueQuery.district);
                if (this.revenueQuery.taluka) parts.push(this.revenueQuery.taluka);
                locBreadcrumb.innerHTML = 'Filter Location: <span style="color: var(--accent-primary, #fe750b);">' + parts.join(' &gt; ') + '</span>';
            }

            if (countBadge) {
                countBadge.textContent = `Total Revenue: ₹${metrics.total_revenue} (${pagination.total_records} Orders)`;
            }

            if (orders.length === 0) {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="7" class="text-center" style="padding: 40px; color: var(--text-secondary);">
                            <i class="fa-solid fa-circle-info" style="font-size: 32px; margin-bottom: 12px; display: block;"></i>
                            No revenue or order records found matching the selected location filters.
                        </td>
                    </tr>
                `;
                document.getElementById('revenue-pagination').innerHTML = '';
                return;
            }

            tbody.innerHTML = orders.map(ord => {
                let statusBadge = '<span class="badge badge-secondary">' + ord.status + '</span>';
                if (ord.status === 'completed' || ord.status === 'delivered') {
                    statusBadge = '<span class="badge badge-success">' + ord.status + '</span>';
                } else if (ord.status === 'cancelled') {
                    statusBadge = '<span class="badge badge-danger">' + ord.status + '</span>';
                } else if (ord.status === 'pending') {
                    statusBadge = '<span class="badge badge-warning">' + ord.status + '</span>';
                }

                const dateStr = new Date(ord.created_at).toLocaleDateString('en-IN', {
                    day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit'
                });

                const custLoc = [ord.taluka, ord.district, ord.state, ord.country].filter(Boolean).join(', ') || 'Not set';

                return `
                    <tr>
                        <td><strong>#${ord.order_id}</strong></td>
                        <td>
                            <div style="display: flex; flex-direction: column;">
                                <span class="font-semibold">${this.escapeHtml(ord.customer_name)}</span>
                                <span style="font-size: 11px; color: var(--text-muted);"><i class="fa-solid fa-phone"></i> ${this.escapeHtml(ord.customer_phone || 'N/A')}</span>
                            </div>
                        </td>
                        <td>
                            <div style="display: flex; flex-direction: column;">
                                <span style="font-size: 12px; font-weight: 600; color: #2563eb;"><i class="fa-solid fa-location-dot"></i> ${this.escapeHtml(custLoc)}</span>
                                <span style="font-size: 10px; color: var(--text-secondary);">${ord.customer_email ? this.escapeHtml(ord.customer_email) : ''}</span>
                            </div>
                        </td>
                        <td><strong>${this.escapeHtml(ord.hotel_name)}</strong></td>
                        <td>
                            <div style="display: flex; flex-direction: column; gap: 4px;">
                                ${statusBadge}
                                <span style="font-size: 10px; color: var(--text-secondary); font-weight: 600;">Via ${ord.payment_method}</span>
                            </div>
                        </td>
                        <td>
                            <span style="font-weight: 900; color: #10b981; font-size: 15px;">₹${ord.grand_total}</span>
                        </td>
                        <td>${dateStr}</td>
                    </tr>
                `;
            }).join('');

            this.renderPagination('revenue-pagination', pagination, (newPage) => {
                this.revenueQuery.page = newPage;
                this.fetchRevenueList();
            });

        } catch (error) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="7" class="text-center text-danger" style="padding: 24px;">
                        Failed to load location revenue analytics: ${error.message}
                    </td>
                </tr>
            `;
        }
    }

    async loadPayoutsView(container) {
        this.payoutRecordQuery = { search: '', status: 'all', cycle: '', min_amount: '', max_amount: '', page: 1, limit: 15 };
        this.payoutRunQuery = { page: 1, limit: 10 };
        this.activePayoutSubTab = 'records';
        this.currentRazorpayContacts = [];
        this.currentPayoutRecords = [];
        const now = new Date();
        this.payoutSliderYear = now.getFullYear();
        this.payoutSliderMonth = now.getMonth();
        if (!this.payoutDatesWithRecords) this.payoutDatesWithRecords = new Set();
        if (!this.payoutDateSummaries) this.payoutDateSummaries = {};

        // Build 12-hour selectors
        const hourOptions = Array.from({ length: 12 }, (_, i) => {
            const h = String(i + 1).padStart(2, '0');
            return `<option value="${i + 1}">${h}</option>`;
        }).join('');

        const minuteOptions = Array.from({ length: 60 }, (_, i) => {
            const m = String(i).padStart(2, '0');
            return `<option value="${i}">${m}</option>`;
        }).join('');

        container.innerHTML = `
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; flex-wrap: wrap; gap: 15px;">
                <div>
                    <h2 style="font-size: 22px; font-weight: 800; margin: 0; color: var(--text-primary);">Vendor Payout Management</h2>
                    <p style="font-size: 13px; color: var(--text-muted); margin: 4px 0 0 0;">Automated RazorpayX Vendor Settlement System (Dynamic Schedule • Instant Batch Execution • Real-time Reconciliations)</p>
                </div>
                <div style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
                    <div style="display: flex; align-items: center; gap: 10px; background: #f0fdf4; border: 1.5px solid #86efac; padding: 6px 14px; border-radius: 10px;">
                        <div style="width: 32px; height: 32px; background: #15803d; border-radius: 8px; display: flex; align-items: center; justify-content: center; color: white;">
                            <i class="fa-solid fa-wallet" style="font-size: 15px;"></i>
                        </div>
                        <div>
                            <div style="font-size: 10px; color: #166534; font-weight: 700; text-transform: uppercase;">RazorpayX Balance</div>
                            <div style="font-size: 15px; color: #15803d; font-weight: 900; line-height: 1.1;" id="header-rzp-balance"><i class="fa-solid fa-spinner fa-spin" style="font-size: 12px;"></i></div>
                        </div>
                    </div>
                    <button id="btn-add-vendor-earning" class="btn btn-secondary" onclick="app.openAddVendorEarningModal()" style="display: flex; align-items: center; gap: 8px; font-weight: 800; padding: 10px 18px; border-radius: 8px; background: #ffffff; border: 1.5px solid #10b981; color: #047857;" title="Credit daily order earnings for a vendor">
                        <i class="fa-solid fa-circle-plus" style="color: #10b981;"></i>
                        <span>Add Today's Earning</span>
                    </button>
                    <button id="btn-trigger-payout-now" class="btn btn-primary" onclick="app.handleManualPayoutTrigger()" style="display: flex; align-items: center; gap: 8px; font-weight: 800; padding: 10px 18px; border-radius: 8px; box-shadow: 0 4px 12px rgba(254, 117, 11, 0.3);">
                        <i class="fa-solid fa-play"></i>
                        <span>Start Payout Now</span>
                    </button>
                </div>
            </div>

            <!-- Razorpay Banking Balances Live Card (GET /v1/banking_balances) -->
            <div id="rzp-banking-balances-card" class="card" style="margin-bottom: 24px; padding: 18px 20px; border: 1.5px solid #93c5fd; background: linear-gradient(135deg, #f8fafc 0%, #eff6ff 100%); border-radius: 14px; box-shadow: 0 4px 16px rgba(37, 99, 235, 0.06);">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; border-bottom: 1px solid #bfdbfe; padding-bottom: 12px; flex-wrap: wrap; gap: 12px;">
                    <div style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
                        <div style="width: 38px; height: 38px; background: #2563eb; color: white; border-radius: 10px; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 10px rgba(37, 99, 235, 0.3);">
                            <i class="fa-solid fa-building-columns" style="font-size: 18px;"></i>
                        </div>
                        <div>
                            <div style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">
                                <h3 style="font-size: 16px; font-weight: 800; color: #1e3a8a; margin: 0;">Razorpay Banking Balances</h3>
                                <span style="font-family: monospace; font-size: 11px; background: #dbeafe; color: #1d4ed8; padding: 2px 8px; border-radius: 6px; font-weight: 700;">GET /v1/banking_balances</span>
                                <span id="rzp-balance-latency-pill" style="font-size: 11px; background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; padding: 2px 8px; border-radius: 10px; font-weight: 800; display: none;"></span>
                            </div>
                            <div style="font-size: 12px; color: #64748b; margin-top: 2px;">
                                Live real-time balance of your RazorpayX Merchant Account for vendor payouts
                            </div>
                        </div>
                    </div>
                    <!-- Right side: Refresh Button & Raw JSON View -->
                    <div style="display: flex; align-items: center; gap: 10px;">
                        <button id="btn-view-balance-json" class="btn btn-secondary btn-sm" onclick="app.openBankingBalanceJsonModal()" style="display: inline-flex; align-items: center; gap: 6px; font-weight: 700;" title="View Raw Razorpay API Response">
                            <i class="fa-solid fa-code"></i>
                            <span>View JSON</span>
                        </button>
                        <button id="btn-refresh-banking-balance" class="btn btn-primary btn-sm" onclick="app.fetchRazorpayBankingBalances(true)" style="display: inline-flex; align-items: center; gap: 8px; font-weight: 800; padding: 8px 16px; border-radius: 8px; box-shadow: 0 4px 12px rgba(37, 99, 235, 0.25);">
                            <i class="fa-solid fa-arrows-rotate" id="refresh-balance-icon"></i>
                            <span id="refresh-balance-text">Refresh Balance</span>
                        </button>
                    </div>
                </div>

                <!-- Banking Balance Metrics Grid -->
                <div id="rzp-banking-balances-content">
                    <div style="text-align: center; padding: 20px;">
                        <div class="spinner" style="margin: 0 auto;"></div>
                        <p style="margin-top: 8px; color: #3b82f6; font-size: 12px; font-weight: 600;">
                            Calling Razorpay API: <code>GET https://api.razorpay.com/v1/banking_balances</code>...
                        </p>
                    </div>
                </div>
            </div>

            <!-- SECTION A: Automatic Payout Schedule Settings -->
            <div class="card" style="margin-bottom: 24px; padding: 20px; border: 1.5px solid var(--border-color); border-radius: 14px;">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 18px; border-bottom: 1px solid var(--border-color); padding-bottom: 14px; flex-wrap: wrap; gap: 12px;">
                    <div>
                        <h3 style="font-size: 16px; font-weight: 800; color: var(--text-primary); margin: 0; display: flex; align-items: center; gap: 8px;">
                            <i class="fa-solid fa-clock text-primary"></i> Automatic Vendor Payout Settings
                        </h3>
                        <div style="font-size: 12px; color: var(--text-muted); margin-top: 4px;">
                            Configure automated daily payouts. The persistent scheduler runs in the background even if admin panel is closed.
                        </div>
                    </div>
                    <div style="display: flex; align-items: center; gap: 12px; flex-wrap: wrap;">
                        <div style="background: var(--bg-secondary); border: 1px solid var(--border-color); padding: 6px 12px; border-radius: 8px; font-size: 12px;">
                            <span style="color: var(--text-muted); font-weight: 600;">Next Run:</span>
                            <strong style="color: #2563eb; margin-left: 4px;" id="cfg-display-next-run">Calculating...</strong>
                        </div>
                        <div style="background: var(--bg-secondary); border: 1px solid var(--border-color); padding: 6px 12px; border-radius: 8px; font-size: 12px;">
                            <span style="color: var(--text-muted); font-weight: 600;">Last Run Status:</span>
                            <span id="cfg-display-last-status" style="margin-left: 4px; font-weight: 700;">Idle</span>
                        </div>
                    </div>
                </div>

                <form id="payout-settings-form" onsubmit="event.preventDefault(); app.savePayoutSettings();">
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 18px; align-items: flex-end;">
                        <!-- 1. Enable Toggle -->
                        <div>
                            <label style="font-size: 12px; font-weight: 800; text-transform: uppercase; color: var(--text-muted); display: block; margin-bottom: 8px;">
                                Automatic Payouts
                            </label>
                            <label style="display: inline-flex; align-items: center; gap: 10px; cursor: pointer; user-select: none;">
                                <input type="checkbox" id="payout-auto-enabled" style="width: 20px; height: 20px; cursor: pointer; accent-color: #10b981;">
                                <span id="payout-auto-enabled-label" style="font-weight: 800; font-size: 14px; color: #10b981;">ENABLED (ON)</span>
                            </label>
                        </div>

                        <!-- 2. Payout Schedule Time (12-hour format) -->
                        <div style="grid-column: span 2; min-width: 280px;">
                            <label style="font-size: 12px; font-weight: 800; text-transform: uppercase; color: var(--text-muted); display: block; margin-bottom: 8px;">
                                Payout Schedule Time (12-Hour Clock)
                            </label>
                            <div style="display: flex; align-items: center; gap: 8px;">
                                <select id="payout-schedule-hour" class="form-control" style="width: 80px; font-weight: 700; text-align: center;">
                                    ${hourOptions}
                                </select>
                                <span style="font-weight: 900; font-size: 18px; color: var(--text-muted);">:</span>
                                <select id="payout-schedule-minute" class="form-control" style="width: 80px; font-weight: 700; text-align: center;">
                                    ${minuteOptions}
                                </select>
                                <select id="payout-schedule-ampm" class="form-control" style="width: 90px; font-weight: 800; color: #2563eb;">
                                    <option value="AM">AM</option>
                                    <option value="PM">PM</option>
                                </select>
                                <span style="font-size: 12px; color: var(--text-muted); margin-left: 6px;">(e.g. 12:00 AM)</span>
                            </div>
                        </div>

                        <!-- 3. Timezone -->
                        <div>
                            <label style="font-size: 12px; font-weight: 800; text-transform: uppercase; color: var(--text-muted); display: block; margin-bottom: 8px;">
                                Timezone
                            </label>
                            <div style="background: var(--bg-surface); border: 1px solid var(--border-color); border-radius: 8px; padding: 10px 14px; font-weight: 700; font-size: 13px; color: #334155;">
                                <i class="fa-solid fa-earth-asia" style="color: #2563eb; margin-right: 6px;"></i> Asia/Kolkata (IST)
                            </div>
                        </div>

                        <!-- 4. Save Button -->
                        <div style="display: flex; gap: 10px;">
                            <button type="submit" id="btn-save-payout-settings" class="btn btn-primary" style="display: inline-flex; align-items: center; gap: 8px; font-weight: 800; padding: 10px 22px; border-radius: 8px;">
                                <i class="fa-solid fa-floppy-disk"></i>
                                <span>Save Settings</span>
                            </button>
                        </div>
                    </div>
                </form>
            </div>

            <!-- SECTION C: Vendor Payout Summary Cards (From Real Database Records) -->
            <div class="dashboard-grid" style="grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 14px; margin-bottom: 24px;">
                <!-- Total Eligible Vendors -->
                <div class="stat-card" style="padding: 16px; border-radius: 12px; border: 1.5px solid #86efac; background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%);">
                    <div class="stat-info">
                        <span class="stat-label" style="color: #166534; font-weight: 700;">Eligible Vendors</span>
                        <span class="stat-value" id="stat-eligible-vendors" style="color: #15803d; font-size: 24px; font-weight: 900;"><i class="fa-solid fa-spinner fa-spin" style="font-size: 18px;"></i></span>
                        <span style="font-size: 11px; color: #166534; font-weight: 600; margin-top: 2px;">Active with earnings</span>
                    </div>
                    <div class="stat-icon" style="background: #15803d; color: #ffffff;"><i class="fa-solid fa-users-gear"></i></div>
                </div>

                <!-- Total Eligible Amount -->
                <div class="stat-card" style="padding: 16px; border-radius: 12px;">
                    <div class="stat-info">
                        <span class="stat-label">Eligible Amount</span>
                        <span class="stat-value" id="stat-eligible-amount" style="color: #10b981; font-size: 22px; font-weight: 900;">₹ 0.00</span>
                        <span style="font-size: 11px; color: var(--text-muted); margin-top: 2px;">Net payable today</span>
                    </div>
                    <div class="stat-icon" style="background: rgba(16, 185, 129, 0.15); color: #10b981;"><i class="fa-solid fa-money-bill-wave"></i></div>
                </div>

                <!-- Successful Payouts -->
                <div class="stat-card" style="padding: 16px; border-radius: 12px;">
                    <div class="stat-info">
                        <span class="stat-label">Successful Payouts</span>
                        <span class="stat-value" id="stat-successful-payouts" style="color: #059669; font-size: 22px; font-weight: 900;">0</span>
                        <span style="font-size: 11px; color: #059669; font-weight: 600; margin-top: 2px;" id="stat-successful-amount">₹ 0.00</span>
                    </div>
                    <div class="stat-icon" style="background: rgba(5, 150, 105, 0.15); color: #059669;"><i class="fa-solid fa-circle-check"></i></div>
                </div>

                <!-- Processing / Queued -->
                <div class="stat-card" style="padding: 16px; border-radius: 12px;">
                    <div class="stat-info">
                        <span class="stat-label">Processing / Queued</span>
                        <span class="stat-value" id="stat-processing-payouts" style="color: #2563eb; font-size: 22px; font-weight: 900;">0</span>
                        <span style="font-size: 11px; color: #2563eb; font-weight: 600; margin-top: 2px;" id="stat-processing-amount">₹ 0.00</span>
                    </div>
                    <div class="stat-icon" style="background: rgba(37, 99, 235, 0.15); color: #2563eb;"><i class="fa-solid fa-spinner"></i></div>
                </div>

                <!-- Pending Payouts -->
                <div class="stat-card" style="padding: 16px; border-radius: 12px;">
                    <div class="stat-info">
                        <span class="stat-label">Pending Payouts</span>
                        <span class="stat-value" id="stat-pending-payouts" style="color: #d97706; font-size: 22px; font-weight: 900;">0</span>
                        <span style="font-size: 11px; color: #d97706; font-weight: 600; margin-top: 2px;" id="stat-pending-amount">₹ 0.00</span>
                    </div>
                    <div class="stat-icon" style="background: rgba(217, 119, 6, 0.15); color: #d97706;"><i class="fa-solid fa-clock-rotate-left"></i></div>
                </div>

                <!-- Failed Payouts -->
                <div class="stat-card" style="padding: 16px; border-radius: 12px;">
                    <div class="stat-info">
                        <span class="stat-label">Failed Payouts</span>
                        <span class="stat-value" id="stat-failed-payouts" style="color: #dc2626; font-size: 22px; font-weight: 900;">0</span>
                        <span style="font-size: 11px; color: #dc2626; font-weight: 600; margin-top: 2px;" id="stat-failed-amount">₹ 0.00</span>
                    </div>
                    <div class="stat-icon" style="background: rgba(220, 38, 38, 0.15); color: #dc2626;"><i class="fa-solid fa-circle-xmark"></i></div>
                </div>

                <!-- Unknown / Needs Reconciliation -->
                <div class="stat-card" style="padding: 16px; border-radius: 12px;">
                    <div class="stat-info">
                        <span class="stat-label">Requires Reconcile</span>
                        <span class="stat-value" id="stat-unknown-payouts" style="color: #7c3aed; font-size: 22px; font-weight: 900;">0</span>
                        <span style="font-size: 11px; color: #7c3aed; font-weight: 600; margin-top: 2px;">Ambiguous state</span>
                    </div>
                    <div class="stat-icon" style="background: rgba(124, 58, 237, 0.15); color: #7c3aed;"><i class="fa-solid fa-triangle-exclamation"></i></div>
                </div>

                <!-- Total Amount Successfully Paid -->
                <div class="stat-card" style="padding: 16px; border-radius: 12px; background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%); border: 1.5px solid #a7f3d0;">
                    <div class="stat-info">
                        <span class="stat-label" style="color: #047857; font-weight: 700;">Total Paid Out</span>
                        <span class="stat-value" id="stat-total-paid" style="color: #047857; font-size: 22px; font-weight: 900;">₹ 0.00</span>
                        <span style="font-size: 11px; color: #047857; font-weight: 600; margin-top: 2px;">Cumulative Settled</span>
                    </div>
                    <div class="stat-icon" style="background: #047857; color: #ffffff;"><i class="fa-solid fa-building-columns"></i></div>
                </div>
            </div>

            <!-- Tab Navigation Header -->
            <div style="display: flex; gap: 8px; margin-bottom: 20px; border-bottom: 2px solid var(--border-color); padding-bottom: 0;">
                <button id="tab-payout-records-btn" class="modal-tab-btn active" onclick="app.switchPayoutSubTab('records')" style="display: flex; align-items: center; gap: 8px; padding: 12px 20px; font-weight: 700; font-size: 14px;">
                    <i class="fa-solid fa-table-list"></i>
                    <span>Vendor Payout Records</span>
                    <span id="payout-records-pill" style="background: #2563eb; color: white; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 800;">...</span>
                </button>
                <button id="tab-payout-runs-btn" class="modal-tab-btn" onclick="app.switchPayoutSubTab('runs')" style="display: flex; align-items: center; gap: 8px; padding: 12px 20px; font-weight: 700; font-size: 14px;">
                    <i class="fa-solid fa-timeline"></i>
                    <span>Admin Run History</span>
                    <span id="payout-runs-pill" style="background: var(--bg-hover); color: var(--text-secondary); padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 800;">Batches</span>
                </button>
                <button id="tab-rzp-contacts-btn" class="modal-tab-btn" onclick="app.switchPayoutSubTab('contacts')" style="display: flex; align-items: center; gap: 8px; padding: 12px 20px; font-weight: 700; font-size: 14px;">
                    <i class="fa-solid fa-address-book"></i>
                    <span>Razorpay Contacts</span>
                    <span id="rzp-contacts-pill" style="background: #15803d; color: white; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 800;">...</span>
                </button>
            </div>

            <!-- SUBTAB 1: VENDOR PAYOUT RECORDS -->
            <div id="payout-subtab-records" style="display: block;">
                <!-- HORIZONTAL SLIDING DATE CALENDAR BOXES -->
                <div class="payout-calendar-slider-card" id="payout-calendar-slider-card">
                    <div class="payout-slider-header">
                        <div class="payout-slider-title-group">
                            <div class="payout-slider-month-badge">
                                <i class="fa-regular fa-calendar-days" style="color: #2563eb; font-size: 16px;"></i>
                                <h3 id="payout-slider-month-label">October 2026</h3>
                            </div>
                            <div class="payout-slider-month-nav">
                                <button type="button" class="payout-slider-month-btn" onclick="app.navigatePayoutSliderMonth(-1)" title="Previous Month">
                                    <i class="fa-solid fa-chevron-left" style="font-size: 11px;"></i>
                                </button>
                                <button type="button" class="payout-slider-month-btn" onclick="app.navigatePayoutSliderMonth(1)" title="Next Month">
                                    <i class="fa-solid fa-chevron-right" style="font-size: 11px;"></i>
                                </button>
                            </div>
                            <select id="payout-slider-month-select" class="form-control" onchange="app.changePayoutSliderMonthFromSelect()" style="width: auto; height: 32px; font-weight: 700; font-size: 12px; padding: 2px 8px; border-radius: 6px; cursor: pointer;" title="Select Month">
                            </select>
                            <select id="payout-slider-year-select" class="form-control" onchange="app.changePayoutSliderYearFromSelect()" style="width: auto; height: 32px; font-weight: 700; font-size: 12px; padding: 2px 8px; border-radius: 6px; cursor: pointer;" title="Select Year">
                            </select>
                        </div>
                        <div class="payout-slider-actions">
                            <button type="button" class="btn btn-sm btn-secondary" onclick="app.jumpPayoutSliderToToday()" style="display: inline-flex; align-items: center; gap: 6px; font-weight: 700; font-size: 12px; padding: 6px 12px; border-radius: 8px;">
                                <i class="fa-solid fa-calendar-day" style="color: #2563eb;"></i> Today
                            </button>
                            <button type="button" class="btn btn-sm btn-secondary" onclick="app.selectPayoutSliderDate('')" style="display: inline-flex; align-items: center; gap: 6px; font-weight: 700; font-size: 12px; padding: 6px 12px; border-radius: 8px;">
                                <i class="fa-solid fa-layer-group"></i> All Records
                            </button>
                            <span id="payout-slider-active-pill" class="badge" style="display: none; background: #2563eb; color: #fff; padding: 6px 14px; border-radius: 20px; font-weight: 700; font-size: 12px; cursor: pointer; align-items: center; gap: 6px;" onclick="app.selectPayoutSliderDate('')" title="Click to clear date filter">
                                <i class="fa-solid fa-calendar-check"></i>
                                <span id="payout-slider-active-text">22 Oct 2026</span>
                                <i class="fa-solid fa-xmark" style="margin-left: 2px;"></i>
                            </span>
                        </div>
                    </div>

                    <!-- Horizontal Slide Track with Slide Buttons -->
                    <div class="payout-slider-wrapper">
                        <button type="button" class="payout-slider-nav-btn left" onclick="app.slidePayoutCalendar(-1)" title="Slide Left">
                            <i class="fa-solid fa-chevron-left" style="font-size: 12px;"></i>
                        </button>

                        <div class="payout-slider-track" id="payout-calendar-slider-track">
                            <!-- Dynamic Day Cards: ALL, 1, 2, 3, 4, ... N -->
                        </div>

                        <button type="button" class="payout-slider-nav-btn right" onclick="app.slidePayoutCalendar(1)" title="Slide Right">
                            <i class="fa-solid fa-chevron-right" style="font-size: 12px;"></i>
                        </button>
                    </div>

                    <!-- Summary & Guidance Footer -->
                    <div class="payout-slider-summary-bar">
                        <div style="color: var(--text-muted); font-size: 12px; display: flex; align-items: center; gap: 6px;">
                            <span style="display: inline-block; width: 8px; height: 8px; border-radius: 50%; background: #10b981;"></span>
                            <span id="payout-slider-footer-info">Showing all vendor settlement payout records. Click any date box to filter.</span>
                        </div>
                        <div style="font-size: 12px; font-weight: 700; color: #1e3a8a;" id="payout-slider-month-summary">
                        </div>
                    </div>
                </div>

                <!-- Filter & Search Controls -->
                <div class="card" style="margin-bottom: 20px; padding: 16px;">
                    <div style="display: flex; gap: 12px; flex-wrap: wrap; align-items: center; justify-content: space-between;">
                        <div style="display: flex; gap: 10px; flex-wrap: wrap; flex: 1; max-width: 820px;">
                            <div style="flex: 1; min-width: 220px; position: relative;">
                                <i class="fa-solid fa-magnifying-glass" style="position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: var(--text-muted); font-size: 13px;"></i>
                                <input type="text" id="payout-records-search" class="form-control" placeholder="Search by vendor, phone, email, payout ID (pout_...), or ref..." style="padding-left: 34px;">
                            </div>
                            <div style="width: 140px;">
                                <select id="payout-records-status-filter" class="form-control">
                                    <option value="all">All Statuses</option>
                                    <option value="processed">Processed (Paid)</option>
                                    <option value="processing">Processing</option>
                                    <option value="queued">Queued</option>
                                    <option value="pending">Pending</option>
                                    <option value="failed">Failed</option>
                                    <option value="reversed">Reversed</option>
                                    <option value="unknown">Unknown</option>
                                </select>
                            </div>
                            <!-- Custom Interactive Calendar Filter Dropdown -->
                            <div style="position: relative; min-width: 180px;" id="payout-custom-calendar-container">
                                <div id="payout-calendar-trigger-btn" onclick="app.togglePayoutCustomCalendar(event)" style="display: flex; align-items: center; justify-content: space-between; gap: 8px; background: var(--bg-surface); border: 1px solid var(--border-color); border-radius: 6px; padding: 6px 10px; cursor: pointer; transition: all 0.2s ease; height: 35px; box-sizing: border-box;" title="Filter payout records by date using custom calendar">
                                    <div style="display: flex; align-items: center; gap: 7px; overflow: hidden; white-space: nowrap;">
                                        <i class="fa-regular fa-calendar-days" style="color: #2563eb; font-size: 13px;"></i>
                                        <span id="payout-calendar-selected-text" style="font-size: 12px; font-weight: 700; color: var(--text-primary);">All Dates</span>
                                    </div>
                                    <div style="display: flex; align-items: center; gap: 4px;">
                                        <button type="button" id="payout-calendar-clear-btn" onclick="app.clearPayoutCalendarFilter(event)" title="Clear date filter" style="display: none; background: none; border: none; padding: 2px 4px; color: #94a3b8; cursor: pointer; border-radius: 4px; font-size: 11px;">
                                            <i class="fa-solid fa-xmark"></i>
                                        </button>
                                        <i class="fa-solid fa-chevron-down" id="payout-calendar-chevron" style="color: var(--text-muted); font-size: 11px; transition: transform 0.2s ease;"></i>
                                    </div>
                                </div>
                                <input type="hidden" id="payout-records-cycle-filter" value="">

                                <!-- Custom Calendar Popup -->
                                <div id="payout-custom-calendar-dropdown" style="display: none; position: absolute; top: calc(100% + 6px); left: 0; z-index: 1050; width: 320px; background: var(--bg-secondary, #ffffff); border: 1px solid var(--border-color, #e2e8f0); border-radius: 12px; box-shadow: 0 12px 30px -4px rgba(0, 0, 0, 0.15), 0 8px 12px -6px rgba(0, 0, 0, 0.08); padding: 12px; user-select: none;">
                                    <!-- Quick Presets -->
                                    <div style="display: flex; gap: 4px; flex-wrap: wrap; margin-bottom: 10px; padding-bottom: 8px; border-bottom: 1px solid var(--border-color, #f1f5f9);">
                                        <button type="button" class="btn btn-sm" onclick="app.selectPayoutCalendarPreset('all')" style="font-size: 11px; padding: 3px 8px; border-radius: 5px; background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0; font-weight: 600; cursor: pointer;">All</button>
                                        <button type="button" class="btn btn-sm" onclick="app.selectPayoutCalendarPreset('today')" style="font-size: 11px; padding: 3px 8px; border-radius: 5px; background: #eff6ff; color: #2563eb; border: 1px solid #bfdbfe; font-weight: 700; cursor: pointer;">Today</button>
                                        <button type="button" class="btn btn-sm" onclick="app.selectPayoutCalendarPreset('yesterday')" style="font-size: 11px; padding: 3px 8px; border-radius: 5px; background: #f8fafc; color: #475569; border: 1px solid #e2e8f0; font-weight: 600; cursor: pointer;">Yesterday</button>
                                        <button type="button" class="btn btn-sm" onclick="app.selectPayoutCalendarPreset('this_month')" style="font-size: 11px; padding: 3px 8px; border-radius: 5px; background: #f8fafc; color: #475569; border: 1px solid #e2e8f0; font-weight: 600; cursor: pointer;">This Month</button>
                                    </div>

                                    <!-- Navigation Header -->
                                    <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px;">
                                        <button type="button" onclick="app.navigatePayoutCalendarMonth(-1)" style="background: var(--bg-surface, #f8fafc); border: 1px solid var(--border-color, #e2e8f0); border-radius: 6px; width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; cursor: pointer; color: var(--text-primary); transition: background 0.15s ease;">
                                            <i class="fa-solid fa-chevron-left" style="font-size: 10px;"></i>
                                        </button>
                                        <div id="payout-calendar-month-year" style="font-weight: 800; font-size: 13px; color: var(--text-primary);">
                                        </div>
                                        <button type="button" onclick="app.navigatePayoutCalendarMonth(1)" style="background: var(--bg-surface, #f8fafc); border: 1px solid var(--border-color, #e2e8f0); border-radius: 6px; width: 28px; height: 28px; display: flex; align-items: center; justify-content: center; cursor: pointer; color: var(--text-primary); transition: background 0.15s ease;">
                                            <i class="fa-solid fa-chevron-right" style="font-size: 10px;"></i>
                                        </button>
                                    </div>

                                    <!-- Weekdays -->
                                    <div style="display: grid; grid-template-columns: repeat(7, 1fr); text-align: center; margin-bottom: 4px;">
                                        <span style="font-size: 11px; font-weight: 800; color: #ef4444;">Su</span>
                                        <span style="font-size: 11px; font-weight: 700; color: #64748b;">Mo</span>
                                        <span style="font-size: 11px; font-weight: 700; color: #64748b;">Tu</span>
                                        <span style="font-size: 11px; font-weight: 700; color: #64748b;">We</span>
                                        <span style="font-size: 11px; font-weight: 700; color: #64748b;">Th</span>
                                        <span style="font-size: 11px; font-weight: 700; color: #64748b;">Fr</span>
                                        <span style="font-size: 11px; font-weight: 800; color: #2563eb;">Sa</span>
                                    </div>

                                    <!-- Days Grid -->
                                    <div id="payout-calendar-days-grid" style="display: grid; grid-template-columns: repeat(7, 1fr); gap: 2px;">
                                    </div>

                                    <!-- Footer -->
                                    <div style="display: flex; align-items: center; justify-content: space-between; margin-top: 10px; padding-top: 8px; border-top: 1px solid var(--border-color, #f1f5f9); font-size: 11px;">
                                        <div style="display: flex; align-items: center; gap: 4px; color: #059669; font-weight: 600;">
                                            <span style="display: inline-block; width: 6px; height: 6px; border-radius: 50%; background: #10b981;"></span>
                                            <span>Has Payouts</span>
                                        </div>
                                        <div style="display: flex; align-items: center; gap: 6px;">
                                            <button type="button" onclick="app.jumpPayoutCalendarToToday()" style="background: none; border: none; color: #2563eb; font-weight: 700; cursor: pointer; padding: 2px 4px; font-size: 11px;">Today</button>
                                            <span style="color: var(--border-color, #cbd5e1);">|</span>
                                            <button type="button" onclick="app.closePayoutCustomCalendar()" style="background: none; border: none; color: var(--text-muted); font-weight: 600; cursor: pointer; padding: 2px 4px; font-size: 11px;">Close</button>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div style="width: 100px;">
                                <input type="number" id="payout-records-min-amt" class="form-control" placeholder="Min ₹">
                            </div>
                            <div style="width: 100px;">
                                <input type="number" id="payout-records-max-amt" class="form-control" placeholder="Max ₹">
                            </div>
                            <div style="display: flex; align-items: center; gap: 6px; background: var(--bg-surface); border: 1px solid var(--border-color); padding: 3px 8px; border-radius: 6px;" title="RazorpayX Source Account Number for Live API (curl GET /v1/payouts?account_number=...)">
                                <i class="fa-solid fa-building-columns" style="color: #2563eb; font-size: 11px;"></i>
                                <span style="font-size: 11px; font-weight: 700; color: var(--text-muted);">Acc:</span>
                                <input type="text" id="payout-records-account-number" class="form-control" value="2323230074781323" placeholder="7878780080316316" style="width: 140px; height: 28px; font-size: 11px; font-family: monospace; padding: 2px 6px;">
                            </div>
                        </div>
                        <div style="display: flex; align-items: center; gap: 10px;">
                            <button class="btn btn-outline-primary btn-sm" id="btn-toggle-live-razorpay" onclick="app.toggleLiveRazorpayPayouts()" style="display: flex; align-items: center; gap: 5px;" title="Fetch all payouts directly via RazorpayX API: GET /v1/payouts?account_number=...">
                                <i class="fa-brands fa-razorpay" style="color: #2563eb;"></i> <span id="live-rzp-btn-text">Razorpay Live API</span>
                            </button>
                            <button class="btn btn-secondary btn-sm" onclick="app.fetchPayoutRecords(true)" title="Refresh Records">
                                <i class="fa-solid fa-arrows-rotate"></i> Refresh
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Payout Records Data Table -->
                <div class="card" style="padding: 0; overflow: hidden;">
                    <div id="payout-records-api-banner" style="display: flex; padding: 10px 16px; background: #eff6ff; border-bottom: 1px solid #bfdbfe; font-size: 12px; color: #1e40af; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 8px;">
                        <div style="display: flex; align-items: center; gap: 8px;">
                            <i class="fa-brands fa-razorpay" style="color: #2563eb; font-size: 16px;"></i>
                            <span>Live Razorpay API: <code id="banner-api-url" style="background: #dbeafe; padding: 2px 6px; border-radius: 4px; font-size: 11px; color: #1d4ed8;">GET https://api.razorpay.com/v1/payouts?account_number=2323230074781323</code></span>
                        </div>
                        <div style="display: flex; align-items: center; gap: 8px;">
                            <span id="banner-api-date-filter" class="badge" style="display: none; background: #4338ca; color: #fff; font-size: 11px; cursor: pointer; align-items: center; gap: 5px;" onclick="app.clearPayoutCalendarFilter(event)" title="Click to clear date filter"></span>
                            <span id="banner-api-acc" class="badge" style="background: #1e40af; color: #fff; font-size: 11px; font-family: monospace;">Account: 2323230074781323</span>
                            <span id="banner-api-count" class="badge" style="background: #10b981; color: #fff; font-size: 11px;">Live Connected</span>
                        </div>
                    </div>
                    <div style="overflow-x: auto;">
                        <table class="table" style="width: 100%; border-collapse: collapse;">
                            <thead>
                                <tr style="background: var(--bg-hover); text-align: left; font-size: 12px; font-weight: 700; color: var(--text-muted); text-transform: uppercase;">
                                    <th style="padding: 12px 16px;">Payout Ref / ID</th>
                                    <th style="padding: 12px 16px;">Vendor Details</th>
                                    <th style="padding: 12px 16px;">Eligible Earnings</th>
                                    <th style="padding: 12px 16px;">Net Payout Amount</th>
                                    <th style="padding: 12px 16px;">Payout Cycle</th>
                                    <th style="padding: 12px 16px;">RazorpayX Payout ID</th>
                                    <th style="padding: 12px 16px;">Status</th>
                                    <th style="padding: 12px 16px;">Created / Processed</th>
                                    <th style="padding: 12px 16px; text-align: right;">Actions</th>
                                </tr>
                            </thead>
                            <tbody id="payout-records-table-body">
                                <tr>
                                    <td colspan="9" class="text-center" style="padding: 30px;">
                                        <div class="spinner" style="margin: 0 auto;"></div>
                                        <p style="margin-top: 10px; color: var(--text-muted);">Loading payout records...</p>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    <div id="payout-records-pagination" class="pagination-container" style="padding: 16px; display: flex; justify-content: flex-end;"></div>
                </div>
            </div>

            <!-- SUBTAB 2: ADMIN RUN HISTORY -->
            <div id="payout-subtab-runs" style="display: none;">
                <div class="card" style="padding: 0; overflow: hidden;">
                    <div style="padding: 16px; border-bottom: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center;">
                        <h4 style="margin: 0; font-size: 14px; font-weight: 800; color: var(--text-primary);">
                            <i class="fa-solid fa-timeline text-primary" style="margin-right: 6px;"></i> Batch Execution Run History
                        </h4>
                        <button class="btn btn-secondary btn-sm" onclick="app.fetchPayoutRuns()">
                            <i class="fa-solid fa-arrows-rotate"></i> Refresh History
                        </button>
                    </div>
                    <div style="overflow-x: auto;">
                        <table class="table" style="width: 100%; border-collapse: collapse;">
                            <thead>
                                <tr style="background: var(--bg-hover); text-align: left; font-size: 12px; font-weight: 700; color: var(--text-muted); text-transform: uppercase;">
                                    <th style="padding: 12px 16px;">Run Code</th>
                                    <th style="padding: 12px 16px;">Trigger Type</th>
                                    <th style="padding: 12px 16px;">Target Date</th>
                                    <th style="padding: 12px 16px;">Execution Timing</th>
                                    <th style="padding: 12px 16px;">Vendors Examined</th>
                                    <th style="padding: 12px 16px;">Payouts Breakdown</th>
                                    <th style="padding: 12px 16px;">Total Amount</th>
                                    <th style="padding: 12px 16px;">Run Status</th>
                                    <th style="padding: 12px 16px;">Summary Notes</th>
                                </tr>
                            </thead>
                            <tbody id="payout-runs-table-body">
                                <tr>
                                    <td colspan="9" class="text-center" style="padding: 30px;">
                                        <div class="spinner" style="margin: 0 auto;"></div>
                                        <p style="margin-top: 10px; color: var(--text-muted);">Loading run history...</p>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    <div id="payout-runs-pagination" class="pagination-container" style="padding: 16px; display: flex; justify-content: flex-end;"></div>
                </div>
            </div>

            <!-- SUBTAB 3: RAZORPAY CONTACTS -->
            <div id="payout-subtab-contacts" style="display: none;">
                <!-- Filter & Search Controls -->
                <div class="card" style="margin-bottom: 20px; padding: 16px;">
                    <div style="display: flex; gap: 12px; flex-wrap: wrap; align-items: center; justify-content: space-between;">
                        <div style="display: flex; gap: 12px; flex-wrap: wrap; flex: 1; max-width: 720px;">
                            <div style="flex: 1; min-width: 240px; position: relative;">
                                <i class="fa-solid fa-magnifying-glass" style="position: absolute; left: 12px; top: 50%; transform: translateY(-50%); color: var(--text-muted); font-size: 13px;"></i>
                                <input type="text" id="rzp-contact-search" class="form-control" placeholder="Search by name, contact phone, email, contact ID (cont_...)" style="padding-left: 34px;">
                            </div>
                            <div style="width: 140px;">
                                <select id="rzp-contact-type-filter" class="form-control">
                                    <option value="all">All Types</option>
                                    <option value="vendor">vendor</option>
                                    <option value="employee">employee</option>
                                    <option value="self">self</option>
                                </select>
                            </div>
                            <div style="width: 140px;">
                                <select id="rzp-contact-status-filter" class="form-control">
                                    <option value="all">All Status</option>
                                    <option value="active">Active</option>
                                    <option value="inactive">Inactive</option>
                                </select>
                            </div>
                        </div>
                        <div style="display: flex; align-items: center; gap: 10px;">
                            <button class="btn btn-primary btn-sm" onclick="app.syncAllVendorsRazorpay()" title="Auto-apply Razorpay Contacts & Fund Accounts for all existing vendors" style="display: inline-flex; align-items: center; gap: 6px; font-weight: 700;">
                                <i class="fa-solid fa-arrows-rotate"></i> Auto-Apply All Vendors
                            </button>
                            <button class="btn btn-secondary btn-sm" onclick="app.fetchRazorpayContacts(true)" title="Refresh from Razorpay API">
                                <i class="fa-solid fa-arrows-rotate"></i>
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Contacts Table -->
                <div class="card" style="padding: 0; overflow: hidden;">
                    <div style="overflow-x: auto;">
                        <table class="table" style="width: 100%; border-collapse: collapse;">
                            <thead>
                                <tr style="background: var(--bg-hover); text-align: left; font-size: 12px; font-weight: 700; color: var(--text-muted); text-transform: uppercase;">
                                    <th style="padding: 12px 16px;">Contact ID</th>
                                    <th style="padding: 12px 16px;">Contact Name</th>
                                    <th style="padding: 12px 16px;">Phone & Email</th>
                                    <th style="padding: 12px 16px;">Type</th>
                                    <th style="padding: 12px 16px;">Status</th>
                                    <th style="padding: 12px 16px;">Metadata Notes</th>
                                    <th style="padding: 12px 16px;">Created At</th>
                                    <th style="padding: 12px 16px; text-align: right;">Actions</th>
                                </tr>
                            </thead>
                            <tbody id="rzp-contacts-table-body">
                                <tr>
                                    <td colspan="8" class="text-center" style="padding: 30px;">
                                        <div class="spinner" style="margin: 0 auto;"></div>
                                        <p style="margin-top: 10px; color: var(--text-muted);">Fetching contacts from Razorpay API...</p>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        `;

        // Event listeners for Records filters
        const searchInput = document.getElementById('payout-records-search');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                clearTimeout(this.payoutSearchTimeout);
                this.payoutSearchTimeout = setTimeout(() => {
                    this.payoutRecordQuery.search = e.target.value.trim();
                    this.payoutRecordQuery.page = 1;
                    this.fetchPayoutRecords();
                }, 400);
            });
        }

        const statusSelect = document.getElementById('payout-records-status-filter');
        if (statusSelect) {
            statusSelect.addEventListener('change', (e) => {
                this.payoutRecordQuery.status = e.target.value;
                this.payoutRecordQuery.page = 1;
                this.fetchPayoutRecords();
            });
        }

        const cycleInput = document.getElementById('payout-records-cycle-filter');
        if (cycleInput) {
            cycleInput.addEventListener('change', (e) => {
                this.payoutRecordQuery.cycle = e.target.value;
                this.payoutRecordQuery.page = 1;
                this.fetchPayoutRecords();
            });
        }

        const minAmtInput = document.getElementById('payout-records-min-amt');
        const maxAmtInput = document.getElementById('payout-records-max-amt');
        const handleAmtChange = () => {
            this.payoutRecordQuery.min_amount = minAmtInput ? minAmtInput.value.trim() : '';
            this.payoutRecordQuery.max_amount = maxAmtInput ? maxAmtInput.value.trim() : '';
            this.payoutRecordQuery.page = 1;
            this.fetchPayoutRecords();
        };
        if (minAmtInput) minAmtInput.addEventListener('change', handleAmtChange);
        if (maxAmtInput) maxAmtInput.addEventListener('change', handleAmtChange);
        const accNumInput = document.getElementById('payout-records-account-number');
        if (accNumInput) {
            accNumInput.addEventListener('change', () => {
                this.payoutRecordQuery.account_number = accNumInput.value.trim();
                this.payoutRecordQuery.page = 1;
                this.fetchPayoutRecords(true);
            });
            accNumInput.addEventListener('keydown', (e) => {
                if (e.key === 'Enter') {
                    this.payoutRecordQuery.account_number = accNumInput.value.trim();
                    this.payoutRecordQuery.page = 1;
                    this.fetchPayoutRecords(true);
                }
            });
        }

        // Toggle checkbox label sync
        const autoToggle = document.getElementById('payout-auto-enabled');
        const autoLabel = document.getElementById('payout-auto-enabled-label');
        if (autoToggle && autoLabel) {
            autoToggle.addEventListener('change', () => {
                if (autoToggle.checked) {
                    autoLabel.textContent = 'ENABLED (ON)';
                    autoLabel.style.color = '#10b981';
                } else {
                    autoLabel.textContent = 'DISABLED (OFF)';
                    autoLabel.style.color = '#ef4444';
                }
            });
        }

        // Event listeners for Razorpay Contacts
        const rzpSearch = document.getElementById('rzp-contact-search');
        if (rzpSearch) {
            rzpSearch.addEventListener('input', () => this.renderRazorpayContactsList());
        }
        const rzpType = document.getElementById('rzp-contact-type-filter');
        if (rzpType) {
            rzpType.addEventListener('change', () => this.renderRazorpayContactsList());
        }
        const rzpStatus = document.getElementById('rzp-contact-status-filter');
        if (rzpStatus) {
            rzpStatus.addEventListener('change', () => this.renderRazorpayContactsList());
        }

        // Initial Data Fetching
        this.initPayoutCustomCalendar();
        this.initPayoutCalendarSlider();
        this.fetchRazorpayBankingBalances();
        this.loadPayoutDashboardData();
        this.fetchPayoutRecords();
        this.fetchRazorpayContacts();
    }

    async loadPayoutDashboardData() {
        try {
            const res = await api.getPayoutDashboard();
            if (!res || !res.success) return;

            const { settings, summary, banking_balance } = res;

            // Sync balance from dashboard response
            if (banking_balance && banking_balance.available_amount_formatted) {
                const headerBal = document.getElementById('header-rzp-balance');
                if (headerBal) {
                    headerBal.textContent = banking_balance.available_amount_formatted;
                }
            }

            // 1. Populate Settings Form
            if (settings) {
                const autoToggle = document.getElementById('payout-auto-enabled');
                const autoLabel = document.getElementById('payout-auto-enabled-label');
                const hourSel = document.getElementById('payout-schedule-hour');
                const minSel = document.getElementById('payout-schedule-minute');
                const ampmSel = document.getElementById('payout-schedule-ampm');
                const nextRunEl = document.getElementById('cfg-display-next-run');
                const lastStatusEl = document.getElementById('cfg-display-last-status');

                if (autoToggle) autoToggle.checked = !!settings.auto_payout_enabled;
                if (autoLabel) {
                    autoLabel.textContent = settings.auto_payout_enabled ? 'ENABLED (ON)' : 'DISABLED (OFF)';
                    autoLabel.style.color = settings.auto_payout_enabled ? '#10b981' : '#ef4444';
                }
                if (hourSel) hourSel.value = settings.schedule_hour || 12;
                if (minSel) minSel.value = settings.schedule_minute !== undefined ? settings.schedule_minute : 0;
                if (ampmSel) ampmSel.value = settings.schedule_ampm || 'AM';
                if (nextRunEl) nextRunEl.textContent = settings.next_run_formatted || 'N/A';
                if (lastStatusEl) {
                    lastStatusEl.textContent = settings.last_run_status || 'Idle';
                    if (settings.last_run_status === 'Completed') lastStatusEl.style.color = '#10b981';
                    else if (settings.last_run_status === 'Attention Required') lastStatusEl.style.color = '#f59e0b';
                    else if (settings.last_run_status === 'Failed') lastStatusEl.style.color = '#ef4444';
                    else lastStatusEl.style.color = '#64748b';
                }
            }

            // 2. Populate Real Summary Cards
            if (summary) {
                const elV = document.getElementById('stat-eligible-vendors');
                const elAmt = document.getElementById('stat-eligible-amount');
                const succV = document.getElementById('stat-successful-payouts');
                const succAmt = document.getElementById('stat-successful-amount');
                const procV = document.getElementById('stat-processing-payouts');
                const procAmt = document.getElementById('stat-processing-amount');
                const pendV = document.getElementById('stat-pending-payouts');
                const pendAmt = document.getElementById('stat-pending-amount');
                const failV = document.getElementById('stat-failed-payouts');
                const failAmt = document.getElementById('stat-failed-amount');
                const unkV = document.getElementById('stat-unknown-payouts');
                const totalPaid = document.getElementById('stat-total-paid');

                if (elV) elV.textContent = summary.total_eligible_vendors;
                if (elAmt) elAmt.textContent = summary.total_eligible_amount_formatted || `₹ ${summary.total_eligible_payout_amount.toFixed(2)}`;
                if (succV) succV.textContent = summary.successful_count;
                if (succAmt) succAmt.textContent = `₹ ${(summary.successful_amount || 0).toFixed(2)}`;
                if (procV) procV.textContent = summary.processing_count;
                if (procAmt) procAmt.textContent = `₹ ${(summary.processing_amount || 0).toFixed(2)}`;
                if (pendV) pendV.textContent = summary.pending_count;
                if (pendAmt) pendAmt.textContent = `₹ ${(summary.pending_amount || 0).toFixed(2)}`;
                if (failV) failV.textContent = summary.failed_count;
                if (failAmt) failAmt.textContent = `₹ ${(summary.failed_amount || 0).toFixed(2)}`;
                if (unkV) unkV.textContent = summary.unknown_count;
                if (totalPaid) totalPaid.textContent = summary.total_paid_formatted || `₹ ${(summary.total_amount_successfully_paid || 0).toFixed(2)}`;
            }
        } catch (err) {
            console.error("Failed to load payout dashboard data:", err);
        }
    }

    async savePayoutSettings() {
        const autoToggle = document.getElementById('payout-auto-enabled');
        const hourSel = document.getElementById('payout-schedule-hour');
        const minSel = document.getElementById('payout-schedule-minute');
        const ampmSel = document.getElementById('payout-schedule-ampm');
        const saveBtn = document.getElementById('btn-save-payout-settings');

        const payload = {
            auto_payout_enabled: autoToggle ? (autoToggle.checked ? 1 : 0) : 1,
            schedule_hour: hourSel ? parseInt(hourSel.value, 10) : 12,
            schedule_minute: minSel ? parseInt(minSel.value, 10) : 0,
            schedule_ampm: ampmSel ? ampmSel.value : 'AM',
        };

        if (saveBtn) {
            saveBtn.disabled = true;
            saveBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Saving...';
        }

        try {
            const res = await api.savePayoutSettings(payload);
            if (res && res.success) {
                this.showToast(res.message || "Payout schedule settings saved successfully!", "success");
                await this.loadPayoutDashboardData();
            } else {
                this.showToast("Failed to save settings: " + (res.message || "Unknown error"), "error");
            }
        } catch (err) {
            this.showToast("Error saving payout settings: " + err.message, "error");
        } finally {
            if (saveBtn) {
                saveBtn.disabled = false;
                saveBtn.innerHTML = '<i class="fa-solid fa-floppy-disk"></i> <span>Save Settings</span>';
            }
        }
    }

    async handleManualPayoutTrigger() {
        const confirmRun = confirm("Are you sure you want to trigger the Vendor Payout batch now for all eligible vendors?");
        if (!confirmRun) return;

        this.showLoader(true);
        try {
            const res = await api.triggerPayoutNow();
            if (res && res.success) {
                this.showToast(res.message || "Payout batch executed successfully!", "success");
                await this.loadPayoutDashboardData();
                await this.fetchPayoutRecords();
                if (this.activePayoutSubTab === 'runs') {
                    await this.fetchPayoutRuns();
                }
            } else {
                this.showToast(res.message || "Payout execution failed.", "error");
            }
        } catch (err) {
            this.showToast("Error executing payout batch: " + err.message, "error");
        } finally {
            this.showLoader(false);
        }
    }
    async fetchRazorpayBankingBalances(forceRefresh = false) {
        const contentEl = document.getElementById('rzp-banking-balances-content');
        const refreshIcon = document.getElementById('refresh-balance-icon');
        const refreshText = document.getElementById('refresh-balance-text');
        const latencyPill = document.getElementById('rzp-balance-latency-pill');
        const headerBal = document.getElementById('header-rzp-balance');

        if (refreshIcon) refreshIcon.classList.add('fa-spin');
        if (refreshText) refreshText.textContent = 'Refreshing...';

        try {
            const res = await api.getRazorpayBankingBalances({ refresh: forceRefresh });
            this.currentBankingBalances = res;

            if (refreshIcon) refreshIcon.classList.remove('fa-spin');
            if (refreshText) refreshText.textContent = 'Refresh Balance';

            if (!res.success || !res.items || res.items.length === 0) {
                if (headerBal) headerBal.textContent = 'Unavailable';
                if (contentEl) {
                    contentEl.innerHTML = `
                        <div style="padding: 16px; background: #fff; border: 1px dashed #cbd5e1; border-radius: 10px; text-align: center; color: var(--text-muted);">
                            <i class="fa-solid fa-circle-exclamation" style="font-size: 22px; color: #f59e0b; margin-bottom: 6px; display: block;"></i>
                            <div style="font-weight: 700; color: #334155;">${this.escapeHtml(res.message || 'No banking balances returned from Razorpay.')}</div>
                            <div style="font-size: 11px; color: #64748b; margin-top: 4px;">Ensure RazorpayX is activated on your account.</div>
                        </div>
                    `;
                }
                return;
            }

            const primary = res.primary_balance || res.items[0];
            const availRupees = primary.available_amount_rupees !== undefined ? primary.available_amount_rupees : ((primary.available_amount ?? primary.amount ?? 0) / 100);
            const formattedBal = `₹ ${availRupees.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

            if (headerBal) headerBal.textContent = formattedBal;
            if (latencyPill) {
                latencyPill.textContent = `${res.latency_ms || 0}ms`;
                latencyPill.style.display = 'inline-block';
            }

            const refreshedDateStr = primary.refreshed_at_formatted || (primary.refreshed_at ? new Date(primary.refreshed_at * 1000).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' }) : 'N/A');

            if (contentEl) {
                contentEl.innerHTML = `
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 14px;">
                        <!-- Primary Available Balance -->
                        <div style="background: #ffffff; border: 1.5px solid #86efac; border-radius: 10px; padding: 16px; position: relative; overflow: hidden; box-shadow: 0 2px 8px rgba(22, 101, 52, 0.05);">
                            <div style="position: absolute; right: 12px; top: 12px; width: 36px; height: 36px; background: #dcfce7; color: #15803d; border-radius: 8px; display: flex; align-items: center; justify-content: center;">
                                <i class="fa-solid fa-wallet" style="font-size: 16px;"></i>
                            </div>
                            <div style="font-size: 11px; text-transform: uppercase; color: #166534; font-weight: 800; letter-spacing: 0.5px;">Available Payout Balance</div>
                            <div style="font-size: 26px; font-weight: 900; color: #15803d; margin-top: 6px; line-height: 1.1;">${formattedBal}</div>
                            <div style="font-size: 11px; color: #64748b; margin-top: 6px; display: flex; align-items: center; gap: 4px;">
                                <i class="fa-solid fa-circle-check" style="color: #10b981;"></i> Ready for live vendor payouts
                            </div>
                        </div>

                        <!-- RazorpayX Account Number -->
                        <div style="background: #ffffff; border: 1.5px solid #bfdbfe; border-radius: 10px; padding: 16px; position: relative; box-shadow: 0 2px 8px rgba(37, 99, 235, 0.05);">
                            <div style="position: absolute; right: 12px; top: 12px; width: 36px; height: 36px; background: #dbeafe; color: #1d4ed8; border-radius: 8px; display: flex; align-items: center; justify-content: center;">
                                <i class="fa-solid fa-building-columns" style="font-size: 16px;"></i>
                            </div>
                            <div style="font-size: 11px; text-transform: uppercase; color: #1e40af; font-weight: 800; letter-spacing: 0.5px;">RazorpayX Account Number</div>
                            <div style="font-family: monospace; font-size: 17px; font-weight: 800; color: #1e293b; margin-top: 8px; display: flex; align-items: center; gap: 6px;">
                                <span>${this.escapeHtml(primary.account_number || 'N/A')}</span>
                                ${primary.account_number ? `
                                    <button onclick="app.copyToClipboard('${primary.account_number}')" title="Copy Account Number" style="background: none; border: none; cursor: pointer; color: #3b82f6; font-size: 12px; padding: 2px;">
                                        <i class="fa-regular fa-copy"></i>
                                    </button>
                                ` : ''}
                            </div>
                            <div style="font-size: 11px; color: #64748b; margin-top: 6px;">
                                Entity: <strong style="color: #334155;">${this.escapeHtml(primary.entity || 'banking_balance')}</strong>
                            </div>
                        </div>

                        <!-- Account Type & Currency -->
                        <div style="background: #ffffff; border: 1px solid var(--border-color); border-radius: 10px; padding: 16px; position: relative;">
                            <div style="position: absolute; right: 12px; top: 12px; width: 36px; height: 36px; background: #f3e8ff; color: #7e22ce; border-radius: 8px; display: flex; align-items: center; justify-content: center;">
                                <i class="fa-solid fa-tag" style="font-size: 16px;"></i>
                            </div>
                            <div style="font-size: 11px; text-transform: uppercase; color: var(--text-muted); font-weight: 800; letter-spacing: 0.5px;">Account Type / Currency</div>
                            <div style="font-size: 16px; font-weight: 800; color: #7e22ce; margin-top: 8px;">
                                ${this.escapeHtml(primary.account_type || 'razorpayx_lite')}
                            </div>
                            <div style="font-size: 11px; color: #64748b; margin-top: 6px;">
                                Currency: <strong style="color: #0f172a;">${this.escapeHtml(primary.currency || 'INR')}</strong>
                            </div>
                        </div>

                        <!-- Last Refreshed -->
                        <div style="background: #ffffff; border: 1px solid var(--border-color); border-radius: 10px; padding: 16px; position: relative;">
                            <div style="position: absolute; right: 12px; top: 12px; width: 36px; height: 36px; background: #f1f5f9; color: #475569; border-radius: 8px; display: flex; align-items: center; justify-content: center;">
                                <i class="fa-solid fa-clock-rotate-left" style="font-size: 16px;"></i>
                            </div>
                            <div style="font-size: 11px; text-transform: uppercase; color: var(--text-muted); font-weight: 800; letter-spacing: 0.5px;">Last Refreshed (Razorpay)</div>
                            <div style="font-size: 14px; font-weight: 700; color: #334155; margin-top: 8px;">
                                ${refreshedDateStr}
                            </div>
                            <div style="font-size: 11px; color: #64748b; margin-top: 6px;">
                                Unix Refreshed: <span style="font-family: monospace;">${primary.refreshed_at || 'N/A'}</span>
                            </div>
                        </div>
                    </div>
                `;
            }

            if (forceRefresh) {
                this.showToast("Razorpay Banking Balances refreshed successfully!", "success");
            }
        } catch (err) {
            console.error("Razorpay banking balances error:", err);
            if (refreshIcon) refreshIcon.classList.remove('fa-spin');
            if (refreshText) refreshText.textContent = 'Refresh Balance';
            if (headerBal) headerBal.textContent = 'Error';
            if (contentEl) {
                contentEl.innerHTML = `
                    <div style="padding: 14px; background: #fef2f2; border: 1px solid #fecaca; border-radius: 8px; color: #991b1b; font-size: 12px; text-align: center;">
                        <i class="fa-solid fa-triangle-exclamation" style="font-size: 18px; margin-bottom: 6px; display: block;"></i>
                        Failed to fetch Razorpay Banking Balances: ${this.escapeHtml(err.message || 'API error')}
                    </div>
                `;
            }
            if (forceRefresh) {
                this.showToast("Failed to refresh banking balances: " + err.message, "error");
            }
        }
    }

    openBankingBalanceJsonModal() {
        const modalTitle = document.getElementById('modal-title');
        const modalContent = document.getElementById('modal-content');
        if (!modalContent) return;

        if (modalTitle) {
            modalTitle.innerHTML = '<i class="fa-solid fa-code text-primary" style="margin-right: 8px;"></i> Razorpay Banking Balances (GET /v1/banking_balances)';
        }

        const data = this.currentBankingBalances || { message: 'No balance data loaded yet.' };

        modalContent.innerHTML = `
            <div style="display: flex; flex-direction: column; gap: 14px;">
                <div style="background: #f0fdf4; border: 1px solid #86efac; border-radius: 8px; padding: 12px 16px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;">
                    <div>
                        <div style="font-size: 11px; font-weight: 800; color: #166534; text-transform: uppercase;">Endpoint</div>
                        <div style="font-family: monospace; font-size: 13px; font-weight: 700; color: #15803d;">GET https://api.razorpay.com/v1/banking_balances</div>
                    </div>
                    <span style="font-family: monospace; font-size: 12px; background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; padding: 4px 10px; border-radius: 12px; font-weight: 800;">
                        HTTP 200 OK
                    </span>
                </div>
                <div style="background: #0f172a; border-radius: 8px; padding: 16px; overflow-x: auto; max-height: 380px;">
                    <pre style="margin: 0; color: #38bdf8; font-family: monospace; font-size: 12px; white-space: pre-wrap; word-break: break-all;">${this.escapeHtml(JSON.stringify(data.raw_payload || data, null, 2))}</pre>
                </div>
            </div>
        `;

        this.openModal('details-modal');
    }

    switchPayoutSubTab(tab) {
        this.activePayoutSubTab = tab;
        const btnRecords = document.getElementById('tab-payout-records-btn');
        const btnRuns = document.getElementById('tab-payout-runs-btn');
        const btnContacts = document.getElementById('tab-rzp-contacts-btn');

        const paneRecords = document.getElementById('payout-subtab-records');
        const paneRuns = document.getElementById('payout-subtab-runs');
        const paneContacts = document.getElementById('payout-subtab-contacts');

        btnRecords?.classList.remove('active');
        btnRuns?.classList.remove('active');
        btnContacts?.classList.remove('active');

        if (paneRecords) paneRecords.style.display = 'none';
        if (paneRuns) paneRuns.style.display = 'none';
        if (paneContacts) paneContacts.style.display = 'none';

        if (tab === 'records') {
            btnRecords?.classList.add('active');
            if (paneRecords) paneRecords.style.display = 'block';
            this.fetchPayoutRecords();
        } else if (tab === 'runs') {
            btnRuns?.classList.add('active');
            if (paneRuns) paneRuns.style.display = 'block';
            this.fetchPayoutRuns();
        } else if (tab === 'contacts') {
            btnContacts?.classList.add('active');
            if (paneContacts) paneContacts.style.display = 'block';
            this.fetchRazorpayContacts();
        }
    }

    async fetchPayoutRecords(showToast = false) {
        const tbody = document.getElementById('payout-records-table-body');
        if (!tbody) return;

        try {
            const accInput = document.getElementById('payout-records-account-number');
            if (accInput && accInput.value.trim()) {
                this.payoutRecordQuery.account_number = accInput.value.trim();
            }
            const res = await api.getPayoutRecords(this.payoutRecordQuery);
            const { records, pagination } = res;
            this.currentPayoutRecords = records || [];

            // Sync calendar payout dots with API response
            // Sync calendar payout dots and summaries with API response
            if (Array.isArray(res.payout_dates)) {
                this.payoutDatesWithRecords = new Set(res.payout_dates);
            }
            if (res.payout_date_summaries) {
                this.payoutDateSummaries = res.payout_date_summaries;
            }
            this.renderPayoutCustomCalendar();
            this.renderPayoutCalendarSliderTrack();

            // Sync date filter badge in banner
            const bannerDateBadge = document.getElementById('banner-api-date-filter');
            if (bannerDateBadge) {
                if (this.payoutRecordQuery.cycle) {
                    bannerDateBadge.style.display = 'inline-flex';
                    bannerDateBadge.innerHTML = '<i class="fa-regular fa-calendar-check" style="margin-right: 4px;"></i> <span>Date: ' + this.escapeHtml(this.payoutRecordQuery.cycle) + '</span> <i class="fa-solid fa-xmark" style="margin-left: 5px;"></i>';
                } else {
                    bannerDateBadge.style.display = 'none';
                }
            }

            const banner = document.getElementById('payout-records-api-banner');
            const bannerUrl = document.getElementById('banner-api-url');
            const bannerAcc = document.getElementById('banner-api-acc');
            const bannerCount = document.getElementById('banner-api-count');
            if (banner) {
                banner.style.display = 'flex';
                if (bannerUrl && res.api_endpoint) bannerUrl.textContent = res.api_endpoint;
                if (bannerAcc && res.account_number) bannerAcc.textContent = `Account: ${res.account_number}`;
                if (bannerCount) {
                    const liveCount = res.razorpay_live_count !== undefined ? res.razorpay_live_count : (records ? records.length : 0);
                    bannerCount.textContent = `${liveCount} Live Razorpay Payouts`;
                }
            }

            const pill = document.getElementById('payout-records-pill');
            if (pill) pill.textContent = `${pagination.total_items} Records`;

            if (!records || records.length === 0) {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="9" class="text-center" style="padding: 40px; color: var(--text-muted);">
                            <i class="fa-solid fa-receipt" style="font-size: 32px; margin-bottom: 8px; display: block; opacity: 0.5;"></i>
                            No vendor payout records found for the selected filters.
                        </td>
                    </tr>
                `;
                this.renderPagination('payout-records-pagination', pagination, (newPage) => {
                    this.payoutRecordQuery.page = newPage;
                    this.fetchPayoutRecords();
                });
                return;
            }

            tbody.innerHTML = records.map(item => {
                let badgeStyle = 'background: #f1f5f9; color: #475569; border: 1px solid #cbd5e1;';
                let iconClass = 'fa-solid fa-circle-minus';
                const st = (item.status || '').toLowerCase();

                if (st === 'processed' || st === 'success') {
                    badgeStyle = 'background: #dcfce7; color: #15803d; border: 1px solid #86efac;';
                    iconClass = 'fa-solid fa-circle-check';
                } else if (st === 'processing') {
                    badgeStyle = 'background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe;';
                    iconClass = 'fa-solid fa-spinner fa-spin';
                } else if (st === 'queued') {
                    badgeStyle = 'background: #f5f3ff; color: #6d28d9; border: 1px solid #ddd6fe;';
                    iconClass = 'fa-solid fa-layer-group';
                } else if (st === 'pending') {
                    badgeStyle = 'background: #fef3c7; color: #d97706; border: 1px solid #fde68a;';
                    iconClass = 'fa-solid fa-clock-rotate-left';
                } else if (st === 'failed' || st === 'rejected') {
                    badgeStyle = 'background: #fee2e2; color: #b91c1c; border: 1px solid #fca5a5;';
                    iconClass = 'fa-solid fa-circle-xmark';
                } else if (st === 'reversed') {
                    badgeStyle = 'background: #fff1f2; color: #be123c; border: 1px solid #fecdd3;';
                    iconClass = 'fa-solid fa-rotate-left';
                }

                const netAmtFormatted = '\u20B9 ' + (parseFloat(item.net_payout_amount) || 0).toFixed(2);
                const earnAmtFormatted = '\u20B9 ' + (parseFloat(item.eligible_earnings) || 0).toFixed(2);
                const createdDateStr = item.created_at ? new Date(item.created_at).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' }) : 'N/A';
                const processedDateStr = item.processed_at ? new Date(item.processed_at).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' }) : 'Pending';

                return `
                    <tr style="border-bottom: 1px solid var(--border-color);">
                        <td style="padding: 14px 16px;">
                            <div style="font-weight: 800; font-size: 13px; color: var(--text-primary);">#${item.id}</div>
                            <div style="font-family: monospace; font-size: 11px; color: #64748b;" title="${this.escapeHtml(item.internal_reference_id)}">${this.escapeHtml(item.internal_reference_id)}</div>
                        </td>
                        <td style="padding: 14px 16px;">
                            <div style="font-weight: 800; color: var(--text-primary); font-size: 13px;">${this.escapeHtml(item.vendor_name)}</div>
                            <div style="font-size: 11px; color: var(--text-muted);"><i class="fa-solid fa-phone" style="font-size: 10px;"></i> ${this.escapeHtml(item.vendor_phone || 'N/A')}</div>
                            ${item.vendor_email ? `<div style="font-size: 11px; color: var(--text-muted);">${this.escapeHtml(item.vendor_email)}</div>` : ''}
                        </td>
                        <td style="padding: 14px 16px; font-size: 13px;">
                            <div style="font-weight: 700; color: #334155;">${earnAmtFormatted}</div>
                            <div style="font-size: 11px; color: var(--text-muted);">Ded: ₹${(parseFloat(item.commission_deductions) || 0).toFixed(2)}</div>
                        </td>
                        <td style="padding: 14px 16px;">
                            <div style="font-size: 15px; font-weight: 900; color: #10b981;">${netAmtFormatted}</div>
                            <div style="font-size: 10px; color: #64748b; font-family: monospace;">${item.amount_paise} paise</div>
                        </td>
                        <td style="padding: 14px 16px; font-size: 12px; font-weight: 700;">
                            <span style="background: var(--bg-surface); border: 1px solid var(--border-color); padding: 3px 8px; border-radius: 6px;">
                                ${this.escapeHtml(item.payout_cycle || 'N/A')}
                            </span>
                        </td>
                        <td style="padding: 14px 16px;">
                            ${item.razorpay_payout_id ? `
                                <div style="display: flex; align-items: center; gap: 4px;">
                                    <span style="font-family: monospace; font-size: 12px; font-weight: 700; color: #2563eb;">${this.escapeHtml(item.razorpay_payout_id)}</span>
                                    <button onclick="app.copyToClipboard('${item.razorpay_payout_id}')" title="Copy Payout ID" style="background: none; border: none; cursor: pointer; color: #64748b; font-size: 11px; padding: 2px;">
                                        <i class="fa-regular fa-copy"></i>
                                    </button>
                                </div>
                                ${item.utr ? `<div style="font-size: 10px; color: #059669; font-family: monospace;">UTR: ${this.escapeHtml(item.utr)}</div>` : ''}
                            ` : '<span style="color: var(--text-muted); font-size: 12px;">Not Assigned</span>'}
                        </td>
                        <td style="padding: 14px 16px;">
                            <span style="display: inline-flex; align-items: center; gap: 5px; padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 800; text-transform: uppercase; ${badgeStyle}">
                                <i class="${iconClass}"></i> ${item.status}
                            </span>
                            ${item.failure_reason ? `<div style="font-size: 10px; color: #dc2626; margin-top: 4px; max-width: 170px;">${this.escapeHtml(item.failure_reason)}</div>` : ''}
                        </td>
                        <td style="padding: 14px 16px; font-size: 11px; color: var(--text-muted);">
                            <div><strong>Created:</strong> ${createdDateStr}</div>
                            <div><strong>Settled:</strong> ${processedDateStr}</div>
                        </td>
                        <td style="padding: 14px 16px; text-align: right; white-space: nowrap;">
                            <button class="btn btn-secondary btn-icon" title="View Payout Details" onclick="app.openRazorpayXPayoutDetailsModal(${item.id})">
                                <i class="fa-solid fa-eye"></i>
                            </button>
                            ${(st === 'processing' || st === 'queued' || st === 'pending' || st === 'unknown') ? `
                                <button class="btn btn-secondary btn-icon" title="Reconcile Status with Razorpay" onclick="app.reconcilePayoutRecord(${item.id})" style="margin-left: 4px; color: #2563eb;">
                                    <i class="fa-solid fa-arrows-rotate"></i>
                                </button>
                            ` : ''}
                        </td>
                    </tr>
                `;
            }).join('');

            this.renderPagination('payout-records-pagination', pagination, (newPage) => {
                this.payoutRecordQuery.page = newPage;
                this.fetchPayoutRecords();
            });

            if (showToast) {
                this.showToast(`Refreshed ${records.length} payout records.`, "info");
            }
        } catch (err) {
            console.error("Payout records fetch error:", err);
            if (tbody) {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="9" class="text-center text-danger" style="padding: 30px;">
                            <i class="fa-solid fa-triangle-exclamation" style="font-size: 24px; margin-bottom: 8px; display: block;"></i>
                            Failed to load payout records: ${this.escapeHtml(err.message || 'API error')}
                        </td>
                    </tr>
                `;
            }
        }
    }

    async toggleLiveRazorpayPayouts() {
        if (this.payoutRecordQuery.source === 'live') {
            this.payoutRecordQuery.source = 'auto';
            const btn = document.getElementById('btn-toggle-live-razorpay');
            if (btn) {
                btn.className = 'btn btn-outline-primary btn-sm';
                btn.innerHTML = '<i class="fa-brands fa-razorpay" style="color: #2563eb;"></i> <span id="live-rzp-btn-text">Razorpay Live API</span>';
            }
            this.showToast("Switched to Synchronized Database & Razorpay view.", "info");
        } else {
            this.payoutRecordQuery.source = 'live';
            const btn = document.getElementById('btn-toggle-live-razorpay');
            if (btn) {
                btn.className = 'btn btn-primary btn-sm';
                btn.innerHTML = '<i class="fa-solid fa-cloud-arrow-down"></i> <span id="live-rzp-btn-text">Live Razorpay Mode (Active)</span>';
            }
            this.showToast("Fetching live directly from Razorpay API: GET /v1/payouts...", "info");
        }
        this.payoutRecordQuery.page = 1;
        await this.fetchPayoutRecords(true);
    }

        initPayoutCalendarSlider() {
        const now = new Date();
        if (this.payoutSliderYear === undefined) this.payoutSliderYear = now.getFullYear();
        if (this.payoutSliderMonth === undefined) this.payoutSliderMonth = now.getMonth();
        if (!this.payoutDatesWithRecords) this.payoutDatesWithRecords = new Set();
        if (!this.payoutDateSummaries) this.payoutDateSummaries = {};

        // Populate month select dropdown
        const monthSelect = document.getElementById('payout-slider-month-select');
        const yearSelect = document.getElementById('payout-slider-year-select');
        const monthNames = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ];

        if (monthSelect) {
            monthSelect.innerHTML = monthNames.map((name, idx) => `
                <option value="${idx}" ${idx === this.payoutSliderMonth ? 'selected' : ''}>${name}</option>
            `).join('');
        }

        if (yearSelect) {
            const currentYear = now.getFullYear();
            const years = [currentYear - 2, currentYear - 1, currentYear, currentYear + 1];
            yearSelect.innerHTML = years.map(yr => `
                <option value="${yr}" ${yr === this.payoutSliderYear ? 'selected' : ''}>${yr}</option>
            `).join('');
        }

        // Attach wheel event for smooth horizontal scroll
        const track = document.getElementById('payout-calendar-slider-track');
        if (track && !this.payoutSliderWheelAttached) {
            track.addEventListener('wheel', (e) => {
                if (e.deltaY !== 0) {
                    e.preventDefault();
                    track.scrollLeft += e.deltaY;
                }
            }, { passive: false });
            this.payoutSliderWheelAttached = true;
        }

        this.renderPayoutCalendarSliderTrack();
    }

    slidePayoutCalendar(direction) {
        const track = document.getElementById('payout-calendar-slider-track');
        if (!track) return;
        track.scrollBy({ left: direction * 280, behavior: 'smooth' });
    }

    navigatePayoutSliderMonth(delta) {
        this.payoutSliderMonth += delta;
        if (this.payoutSliderMonth < 0) {
            this.payoutSliderMonth = 11;
            this.payoutSliderYear -= 1;
        } else if (this.payoutSliderMonth > 11) {
            this.payoutSliderMonth = 0;
            this.payoutSliderYear += 1;
        }

        // Sync dropdowns
        const monthSelect = document.getElementById('payout-slider-month-select');
        const yearSelect = document.getElementById('payout-slider-year-select');
        if (monthSelect) monthSelect.value = this.payoutSliderMonth;
        if (yearSelect) yearSelect.value = this.payoutSliderYear;

        this.renderPayoutCalendarSliderTrack();
    }

    changePayoutSliderMonthFromSelect() {
        const monthSelect = document.getElementById('payout-slider-month-select');
        if (!monthSelect) return;
        this.payoutSliderMonth = parseInt(monthSelect.value, 10);
        this.renderPayoutCalendarSliderTrack();
    }

    changePayoutSliderYearFromSelect() {
        const yearSelect = document.getElementById('payout-slider-year-select');
        if (!yearSelect) return;
        this.payoutSliderYear = parseInt(yearSelect.value, 10);
        this.renderPayoutCalendarSliderTrack();
    }

    jumpPayoutSliderToToday() {
        const now = new Date();
        this.payoutSliderYear = now.getFullYear();
        this.payoutSliderMonth = now.getMonth();
        const monthSelect = document.getElementById('payout-slider-month-select');
        const yearSelect = document.getElementById('payout-slider-year-select');
        if (monthSelect) monthSelect.value = this.payoutSliderMonth;
        if (yearSelect) yearSelect.value = this.payoutSliderYear;

        this.selectPayoutSliderDate(this.formatCalendarDate(now));
    }

    selectPayoutSliderDate(dateStr) {
        this.payoutRecordQuery.cycle = dateStr ? dateStr.trim() : '';
        this.payoutRecordQuery.page = 1;

        if (dateStr) {
            const parts = dateStr.split('-');
            if (parts.length >= 2) {
                this.payoutSliderYear = parseInt(parts[0], 10);
                this.payoutSliderMonth = parseInt(parts[1], 10) - 1;
                const monthSelect = document.getElementById('payout-slider-month-select');
                const yearSelect = document.getElementById('payout-slider-year-select');
                if (monthSelect) monthSelect.value = this.payoutSliderMonth;
                if (yearSelect) yearSelect.value = this.payoutSliderYear;
            }
        }

        // Sync secondary dropdown calendar UI
        const textEl = document.getElementById('payout-calendar-selected-text');
        const clearBtn = document.getElementById('payout-calendar-clear-btn');
        const hiddenInput = document.getElementById('payout-records-cycle-filter');
        const now = new Date();
        const todayStr = this.formatCalendarDate(now);
        const yest = new Date();
        yest.setDate(now.getDate() - 1);
        const yestStr = this.formatCalendarDate(yest);

        if (dateStr) {
            const parts = dateStr.split('-');
            if (parts.length === 3) {
                const dObj = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
                const formatted = dObj.toLocaleDateString('en-IN', { month: 'short', day: 'numeric', year: 'numeric' });
                if (textEl) {
                    textEl.textContent = (dateStr === todayStr) ? `Today (${formatted})` : (dateStr === yestStr ? `Yesterday (${formatted})` : formatted);
                }
            } else if (textEl) {
                textEl.textContent = dateStr;
            }
            if (clearBtn) clearBtn.style.display = 'inline-flex';
            if (hiddenInput) hiddenInput.value = dateStr;
        } else {
            if (textEl) textEl.textContent = 'All Dates';
            if (clearBtn) clearBtn.style.display = 'none';
            if (hiddenInput) hiddenInput.value = '';
        }

        this.renderPayoutCalendarSliderTrack();
        this.renderPayoutCustomCalendar();
        this.fetchPayoutRecords(true);
    }

    autoScrollPayoutCalendarToActive() {
        const track = document.getElementById('payout-calendar-slider-track');
        if (!track) return;
        const activeBox = track.querySelector('.payout-date-box.active') || track.querySelector('.payout-date-box.is-today');
        if (activeBox) {
            const scrollTarget = activeBox.offsetLeft - (track.clientWidth / 2) + (activeBox.clientWidth / 2);
            track.scrollTo({ left: Math.max(0, scrollTarget), behavior: 'smooth' });
        }
    }

    renderPayoutCalendarSliderTrack() {
        const track = document.getElementById('payout-calendar-slider-track');
        const monthLabel = document.getElementById('payout-slider-month-label');
        if (!track) return;

        const monthNames = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ];
        const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

        const year = this.payoutSliderYear;
        const month = this.payoutSliderMonth;
        const daysInMonth = new Date(year, month + 1, 0).getDate();

        if (monthLabel) {
            monthLabel.textContent = `${monthNames[month]} ${year}`;
        }

        const now = new Date();
        const todayStr = this.formatCalendarDate(now);
        const selectedDate = this.payoutRecordQuery.cycle || '';

        // Calculate summary for this month
        let monthPayoutCount = 0;
        let monthPayoutTotal = 0;
        if (this.payoutDateSummaries) {
            const ymPrefix = `${year}-${String(month + 1).padStart(2, '0')}`;
            for (const [dStr, info] of Object.entries(this.payoutDateSummaries)) {
                if (dStr.startsWith(ymPrefix)) {
                    monthPayoutCount += (info.count || 0);
                    monthPayoutTotal += (info.amount || 0);
                }
            }
        }

        const monthSummaryEl = document.getElementById('payout-slider-month-summary');
        if (monthSummaryEl) {
            if (monthPayoutCount > 0) {
                monthSummaryEl.innerHTML = `<i class="fa-solid fa-receipt text-success" style="margin-right: 4px;"></i> ${monthNames[month]} Activity: <strong style="color: #10b981;">₹ ${monthPayoutTotal.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</strong> (${monthPayoutCount} settlement${monthPayoutCount > 1 ? 's' : ''})`;
            } else {
                monthSummaryEl.innerHTML = `<span style="color: var(--text-muted); font-weight: 500;">No payouts recorded yet for ${monthNames[month]} ${year}</span>`;
            }
        }

        // Card 0: "ALL"
        const isAllActive = !selectedDate;
        let html = `
            <div class="payout-date-box all-card ${isAllActive ? 'active' : ''}"
                 onclick="app.selectPayoutSliderDate('')"
                 title="Show all settlement payout records across all dates">
                <span class="payout-day-name">ALL</span>
                <span class="payout-day-num"><i class="fa-solid fa-layer-group all-icon"></i></span>
                <span class="payout-day-badge">All Dates</span>
            </div>
        `;

        // Date Cards: 1, 2, 3, 4, ... daysInMonth
        for (let day = 1; day <= daysInMonth; day++) {
            const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
            const dayDate = new Date(year, month, day);
            const dayOfWeek = dayDate.getDay();
            const dayName = dayNames[dayOfWeek];
            const isWeekend = (dayOfWeek === 0 || dayOfWeek === 6);
            const isToday = (dateStr === todayStr);
            const isSelected = (selectedDate === dateStr);
            const hasPayouts = this.payoutDatesWithRecords && this.payoutDatesWithRecords.has(dateStr);
            const sumInfo = this.payoutDateSummaries && this.payoutDateSummaries[dateStr];

            let badgeHtml = '<span class="payout-day-badge" style="opacity: 0.35;">—</span>';
            if (hasPayouts) {
                if (sumInfo && sumInfo.count) {
                    const amtStr = sumInfo.amount >= 1000 ? `₹${(sumInfo.amount / 1000).toFixed(1)}k` : `₹${Math.round(sumInfo.amount)}`;
                    badgeHtml = `<span class="payout-day-badge" title="${sumInfo.count} payouts settled totaling ₹${(sumInfo.amount || 0).toFixed(2)}"><i class="fa-solid fa-receipt"></i> ${sumInfo.count > 1 ? sumInfo.count + ' rec' : amtStr}</span>`;
                } else {
                    badgeHtml = `<span class="payout-day-badge"><i class="fa-solid fa-circle" style="font-size: 5px;"></i> Paid</span>`;
                }
            } else if (isToday) {
                badgeHtml = `<span class="payout-day-badge">TODAY</span>`;
            }

            const tooltipText = `${dayName}, ${monthNames[month]} ${day}, ${year}${hasPayouts ? ' • Payouts Settled' : ''}${isToday ? ' (Today)' : ''}`;

            html += `
                <div class="payout-date-box ${isSelected ? 'active' : ''} ${hasPayouts ? 'has-payouts' : ''} ${isToday ? 'is-today' : ''}"
                     id="payout-date-box-${dateStr}"
                     data-date="${dateStr}"
                     onclick="app.selectPayoutSliderDate('${dateStr}')"
                     title="${tooltipText}">
                    <span class="payout-day-name ${isWeekend ? 'weekend' : ''}">${dayName}</span>
                    <span class="payout-day-num">${day}</span>
                    ${badgeHtml}
                </div>
            `;
        }

        track.innerHTML = html;

        // Active pill & footer text sync
        const activePill = document.getElementById('payout-slider-active-pill');
        const activeText = document.getElementById('payout-slider-active-text');
        const footerInfo = document.getElementById('payout-slider-footer-info');

        if (selectedDate) {
            const parts = selectedDate.split('-');
            let prettyDate = selectedDate;
            if (parts.length === 3) {
                const dObj = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
                prettyDate = dObj.toLocaleDateString('en-IN', { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' });
            }
            if (activePill) activePill.style.display = 'inline-flex';
            if (activeText) activeText.textContent = prettyDate;
            if (footerInfo) {
                const daySum = this.payoutDateSummaries && this.payoutDateSummaries[selectedDate];
                const recNote = daySum ? ` (${daySum.count} payout${daySum.count > 1 ? 's' : ''} • ₹${(daySum.amount || 0).toFixed(2)})` : '';
                footerInfo.innerHTML = `Showing payout records for <strong>${prettyDate}</strong>${recNote}. Click <strong>All Records</strong> to show everything.`;
            }
        } else {
            if (activePill) activePill.style.display = 'none';
            if (footerInfo) {
                footerInfo.textContent = 'Showing all vendor settlement payout records. Click any date box to filter by that day.';
            }
        }

        // Auto-center active/today card
        setTimeout(() => this.autoScrollPayoutCalendarToActive(), 60);
    }

    formatCalendarDate(d) {
        const y = d.getFullYear();
        const m = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        return `${y}-${m}-${day}`;
    }

    initPayoutCustomCalendar() {
        const now = new Date();
        this.payoutCalendarYear = now.getFullYear();
        this.payoutCalendarMonth = now.getMonth();
        if (!this.payoutDatesWithRecords) {
            this.payoutDatesWithRecords = new Set();
        }

        if (!this.payoutCalendarDocListenerAttached) {
            document.addEventListener('click', (e) => {
                const container = document.getElementById('payout-custom-calendar-container');
                if (container && !container.contains(e.target)) {
                    this.closePayoutCustomCalendar();
                }
            });
            this.payoutCalendarDocListenerAttached = true;
        }

        this.renderPayoutCustomCalendar();
    }

    togglePayoutCustomCalendar(e) {
        if (e) {
            e.stopPropagation();
            if (e.target && e.target.closest('#payout-calendar-clear-btn')) return;
        }
        const dropdown = document.getElementById('payout-custom-calendar-dropdown');
        const chevron = document.getElementById('payout-calendar-chevron');
        if (!dropdown) return;

        const isCurrentlyOpen = dropdown.style.display === 'block';
        if (isCurrentlyOpen) {
            this.closePayoutCustomCalendar();
        } else {
            dropdown.style.display = 'block';
            if (chevron) chevron.style.transform = 'rotate(180deg)';
            this.renderPayoutCustomCalendar();
        }
    }

    closePayoutCustomCalendar() {
        const dropdown = document.getElementById('payout-custom-calendar-dropdown');
        const chevron = document.getElementById('payout-calendar-chevron');
        if (dropdown) dropdown.style.display = 'none';
        if (chevron) chevron.style.transform = 'rotate(0deg)';
    }

    navigatePayoutCalendarMonth(delta) {
        this.payoutCalendarMonth += delta;
        if (this.payoutCalendarMonth < 0) {
            this.payoutCalendarMonth = 11;
            this.payoutCalendarYear -= 1;
        } else if (this.payoutCalendarMonth > 11) {
            this.payoutCalendarMonth = 0;
            this.payoutCalendarYear += 1;
        }
        this.renderPayoutCustomCalendar();
    }

    jumpPayoutCalendarToToday() {
        const now = new Date();
        this.payoutCalendarYear = now.getFullYear();
        this.payoutCalendarMonth = now.getMonth();
        this.selectPayoutCalendarDate(this.formatCalendarDate(now));
    }

    selectPayoutCalendarPreset(preset) {
        const now = new Date();
        if (preset === 'all') {
            this.selectPayoutCalendarDate('');
        } else if (preset === 'today') {
            this.selectPayoutCalendarDate(this.formatCalendarDate(now));
        } else if (preset === 'yesterday') {
            const yesterday = new Date();
            yesterday.setDate(now.getDate() - 1);
            this.selectPayoutCalendarDate(this.formatCalendarDate(yesterday));
        } else if (preset === 'this_month') {
            const ymStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
            this.payoutRecordQuery.cycle = ymStr;
            this.payoutRecordQuery.page = 1;

            const textEl = document.getElementById('payout-calendar-selected-text');
            const clearBtn = document.getElementById('payout-calendar-clear-btn');
            const hiddenInput = document.getElementById('payout-records-cycle-filter');
            if (textEl) {
                textEl.textContent = `Month: ${now.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}`;
            }
            if (clearBtn) clearBtn.style.display = 'inline-flex';
            if (hiddenInput) hiddenInput.value = ymStr;

            this.closePayoutCustomCalendar();
            this.renderPayoutCustomCalendar();
            this.fetchPayoutRecords(true);
        }
    }

    clearPayoutCalendarFilter(e) {
        if (e) e.stopPropagation();
        this.selectPayoutSliderDate('');
        this.showToast("Cleared date filter. Showing all payout records.", "info");
    }

    selectPayoutCalendarDate(dateStr) {
        this.payoutRecordQuery.cycle = dateStr ? dateStr.trim() : '';
        this.payoutRecordQuery.page = 1;

        const textEl = document.getElementById('payout-calendar-selected-text');
        const clearBtn = document.getElementById('payout-calendar-clear-btn');
        const hiddenInput = document.getElementById('payout-records-cycle-filter');

        const now = new Date();
        const todayStr = this.formatCalendarDate(now);
        const yest = new Date();
        yest.setDate(now.getDate() - 1);
        const yestStr = this.formatCalendarDate(yest);

        if (dateStr) {
            const parts = dateStr.split('-');
            if (parts.length === 3) {
                const dObj = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
                const formatted = dObj.toLocaleDateString('en-IN', { month: 'short', day: 'numeric', year: 'numeric' });
                if (dateStr === todayStr) {
                    if (textEl) textEl.textContent = `Today (${formatted})`;
                } else if (dateStr === yestStr) {
                    if (textEl) textEl.textContent = `Yesterday (${formatted})`;
                } else {
                    if (textEl) textEl.textContent = formatted;
                }
                this.payoutCalendarYear = parseInt(parts[0]);
                this.payoutCalendarMonth = parseInt(parts[1]) - 1;
            } else {
                if (textEl) textEl.textContent = dateStr;
            }
            if (clearBtn) clearBtn.style.display = 'inline-flex';
            if (hiddenInput) hiddenInput.value = dateStr;
        } else {
            if (textEl) textEl.textContent = 'All Dates';
            if (clearBtn) clearBtn.style.display = 'none';
            if (hiddenInput) hiddenInput.value = '';
        }

        this.closePayoutCustomCalendar();
        this.renderPayoutCustomCalendar();
        this.renderPayoutCalendarSliderTrack();
        this.fetchPayoutRecords(true);
    }

    renderPayoutCustomCalendar() {
        const titleEl = document.getElementById('payout-calendar-month-year');
        const gridEl = document.getElementById('payout-calendar-days-grid');
        if (!titleEl || !gridEl) return;

        const monthNames = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ];

        titleEl.textContent = `${monthNames[this.payoutCalendarMonth]} ${this.payoutCalendarYear}`;

        const todayStr = this.formatCalendarDate(new Date());
        const selectedDateStr = this.payoutRecordQuery.cycle || '';

        const year = this.payoutCalendarYear;
        const month = this.payoutCalendarMonth;

        const firstDayOfWeek = new Date(year, month, 1).getDay(); // 0 = Sun
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        const daysInPrevMonth = new Date(year, month, 0).getDate();

        let cellsHtml = '';

        // Previous month trailing days
        for (let i = firstDayOfWeek - 1; i >= 0; i--) {
            const dayNum = daysInPrevMonth - i;
            const prevMonthDate = new Date(year, month - 1, dayNum);
            const prevDateStr = this.formatCalendarDate(prevMonthDate);
            const hasPayouts = this.payoutDatesWithRecords && this.payoutDatesWithRecords.has(prevDateStr);

            cellsHtml += `
                <div onclick="app.navigatePayoutCalendarMonth(-1); setTimeout(() => app.selectPayoutCalendarDate('${prevDateStr}'), 50);"
                     style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 32px; border-radius: 6px; cursor: pointer; color: #cbd5e1; font-size: 11px; transition: background 0.15s ease;"
                     title="${prevDateStr}">
                    <span>${dayNum}</span>
                    <span style="width: 4px; height: 4px; border-radius: 50%; background: ${hasPayouts ? '#10b981' : 'transparent'}; margin-top: 1px;"></span>
                </div>
            `;
        }

        // Current month days
        for (let day = 1; day <= daysInMonth; day++) {
            const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
            const isToday = (dateStr === todayStr);
            const isSelected = (selectedDateStr === dateStr);
            const hasPayouts = this.payoutDatesWithRecords && this.payoutDatesWithRecords.has(dateStr);

            let cellBg = 'transparent';
            let cellColor = 'var(--text-primary)';
            let cellBorder = '1px solid transparent';
            let cellFontWeight = '600';
            let dotColor = hasPayouts ? '#10b981' : 'transparent';

            if (isSelected) {
                cellBg = '#2563eb';
                cellColor = '#ffffff';
                cellFontWeight = '800';
                dotColor = hasPayouts ? '#ffffff' : 'transparent';
            } else if (isToday) {
                cellBg = '#eff6ff';
                cellColor = '#2563eb';
                cellBorder = '1.5px solid #3b82f6';
                cellFontWeight = '800';
            }

            const tooltipText = hasPayouts ? `${dateStr} - Payout records found` : dateStr;

            cellsHtml += `
                <div onclick="app.selectPayoutCalendarDate('${dateStr}')"
                     style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 32px; border-radius: 6px; cursor: pointer; background: ${cellBg}; color: ${cellColor}; border: ${cellBorder}; font-weight: ${cellFontWeight}; font-size: 11px; transition: all 0.15s ease;"
                     onmouseover="if (!${isSelected}) this.style.background = '#f1f5f9';"
                     onmouseout="if (!${isSelected}) this.style.background = '${cellBg}';"
                     title="${tooltipText}">
                    <span>${day}</span>
                    <span style="width: 4px; height: 4px; border-radius: 50%; background: ${dotColor}; margin-top: 1px;"></span>
                </div>
            `;
        }

        // Next month leading days to complete row (up to multiple of 7)
        const totalRendered = firstDayOfWeek + daysInMonth;
        const remainder = totalRendered % 7;
        const nextDaysCount = remainder > 0 ? 7 - remainder : 0;

        for (let d = 1; d <= nextDaysCount; d++) {
            const nextMonthDate = new Date(year, month + 1, d);
            const nextDateStr = this.formatCalendarDate(nextMonthDate);
            const hasPayouts = this.payoutDatesWithRecords && this.payoutDatesWithRecords.has(nextDateStr);

            cellsHtml += `
                <div onclick="app.navigatePayoutCalendarMonth(1); setTimeout(() => app.selectPayoutCalendarDate('${nextDateStr}'), 50);"
                     style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 32px; border-radius: 6px; cursor: pointer; color: #cbd5e1; font-size: 11px; transition: background 0.15s ease;"
                     title="${nextDateStr}">
                    <span>${d}</span>
                    <span style="width: 4px; height: 4px; border-radius: 50%; background: ${hasPayouts ? '#10b981' : 'transparent'}; margin-top: 1px;"></span>
                </div>
            `;
        }

        gridEl.innerHTML = cellsHtml;
    }

    async fetchPayoutRuns() {
        const tbody = document.getElementById('payout-runs-table-body');
        if (!tbody) return;

        try {
            const res = await api.getPayoutRuns(this.payoutRunQuery);
            const { runs, pagination } = res;

            const pill = document.getElementById('payout-runs-pill');
            if (pill) pill.textContent = `${pagination.total_items} Batches`;

            if (!runs || runs.length === 0) {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="9" class="text-center" style="padding: 40px; color: var(--text-muted);">
                            <i class="fa-solid fa-timeline" style="font-size: 32px; margin-bottom: 8px; display: block; opacity: 0.5;"></i>
                            No payout execution batch history found.
                        </td>
                    </tr>
                `;
                this.renderPagination('payout-runs-pagination', pagination, (newPage) => {
                    this.payoutRunQuery.page = newPage;
                    this.fetchPayoutRuns();
                });
                return;
            }

            tbody.innerHTML = runs.map(r => {
                let statusBadge = 'background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe;';
                if (r.status === 'COMPLETED') statusBadge = 'background: #dcfce7; color: #15803d; border: 1px solid #86efac;';
                else if (r.status === 'COMPLETED_WITH_EXCEPTIONS') statusBadge = 'background: #fef3c7; color: #d97706; border: 1px solid #fde68a;';
                else if (r.status === 'FAILED') statusBadge = 'background: #fee2e2; color: #b91c1c; border: 1px solid #fca5a5;';

                const startStr = r.start_time ? new Date(r.start_time).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' }) : 'N/A';
                const compStr = r.completion_time ? new Date(r.completion_time).toLocaleTimeString('en-IN') : 'Running...';
                const amtFormatted = `₹ ${(parseFloat(r.total_amount) || 0).toFixed(2)}`;

                return `
                    <tr style="border-bottom: 1px solid var(--border-color);">
                        <td style="padding: 14px 16px; font-weight: 800; font-family: monospace; color: #1e3a8a;">
                            #${r.id} <span style="font-size: 11px; color: #64748b; display: block;">${this.escapeHtml(r.run_code)}</span>
                        </td>
                        <td style="padding: 14px 16px;">
                            <span style="background: ${r.trigger_type === 'scheduled' ? '#f0fdf4' : '#f5f3ff'}; color: ${r.trigger_type === 'scheduled' ? '#166534' : '#6d28d9'}; border: 1px solid ${r.trigger_type === 'scheduled' ? '#86efac' : '#ddd6fe'}; padding: 3px 10px; border-radius: 12px; font-size: 11px; font-weight: 800; text-transform: uppercase;">
                                <i class="${r.trigger_type === 'scheduled' ? 'fa-solid fa-clock' : 'fa-solid fa-hand'}"></i> ${r.trigger_type}
                            </span>
                        </td>
                        <td style="padding: 14px 16px; font-weight: 700; font-size: 13px;">
                            ${this.escapeHtml(r.target_date)}
                        </td>
                        <td style="padding: 14px 16px; font-size: 12px; color: var(--text-muted);">
                            <div><strong>Start:</strong> ${startStr}</div>
                            <div><strong>End:</strong> ${compStr}</div>
                        </td>
                        <td style="padding: 14px 16px; font-weight: 800; font-size: 13px; text-align: center;">
                            ${r.vendors_examined}
                        </td>
                        <td style="padding: 14px 16px; font-size: 12px;">
                            <div>Sub: <strong style="color: #2563eb;">${r.payouts_submitted}</strong> • Succ: <strong style="color: #10b981;">${r.successful_payouts}</strong></div>
                            <div>Pend: <strong style="color: #f59e0b;">${r.pending_payouts}</strong> • Fail: <strong style="color: #ef4444;">${r.failed_payouts}</strong></div>
                        </td>
                        <td style="padding: 14px 16px; font-weight: 900; font-size: 14px; color: #10b981;">
                            ${amtFormatted}
                        </td>
                        <td style="padding: 14px 16px;">
                            <span style="display: inline-flex; align-items: center; gap: 5px; padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 800; ${statusBadge}">
                                ${r.status}
                            </span>
                        </td>
                        <td style="padding: 14px 16px; font-size: 11px; color: var(--text-muted); max-width: 220px;">
                            ${this.escapeHtml(r.summary_notes || 'N/A')}
                        </td>
                    </tr>
                `;
            }).join('');

            this.renderPagination('payout-runs-pagination', pagination, (newPage) => {
                this.payoutRunQuery.page = newPage;
                this.fetchPayoutRuns();
            });
        } catch (err) {
            console.error("Payout runs fetch error:", err);
            if (tbody) {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="9" class="text-center text-danger" style="padding: 24px;">
                            Failed to load run history: ${this.escapeHtml(err.message || 'API error')}
                        </td>
                    </tr>
                `;
            }
        }
    }

    async reconcilePayoutRecord(id) {
        this.showLoader(true);
        try {
            const res = await api.reconcilePayout(id);
            if (res && res.success) {
                this.showToast(`Reconciled Payout #${id}: Status is now '${res.new_status}'.`, "success");
                await this.fetchPayoutRecords();
                await this.loadPayoutDashboardData();
            } else {
                this.showToast("Reconciliation failed: " + (res.message || 'Unknown error'), "error");
            }
        } catch (err) {
            this.showToast("Reconciliation error: " + err.message, "error");
        } finally {
            this.showLoader(false);
        }
    }
    async openAddVendorEarningModal() {
        const modalTitle = document.getElementById('modal-title');
        const modalContent = document.getElementById('modal-content');
        if (!modalContent) return;

        if (modalTitle) {
            modalTitle.innerHTML = '<i class="fa-solid fa-circle-dollar-to-slot text-success" style="margin-right: 8px;"></i> Add Today\'s Earning for Vendor Payout';
        }

        modalContent.innerHTML = `
            <div style="text-align: center; padding: 30px;">
                <div class="spinner" style="margin: 0 auto;"></div>
                <p style="margin-top: 10px; color: var(--text-muted);">Loading active vendors...</p>
            </div>
        `;
        this.openModal('details-modal');

        try {
            const vRes = await api.getVendors({ limit: 100, status: 'all' });
            let vendors = [];
            if (vRes) {
                if (vRes.data && Array.isArray(vRes.data.vendors)) {
                    vendors = vRes.data.vendors;
                } else if (Array.isArray(vRes.vendors)) {
                    vendors = vRes.vendors;
                } else if (Array.isArray(vRes.data)) {
                    vendors = vRes.data;
                } else if (Array.isArray(vRes.items)) {
                    vendors = vRes.items;
                }
            }

            const vendorOptions = vendors.length > 0 ? vendors.map(v => {
                const bal = (parseFloat(v.wallet_balance || v.balance || 0) || 0).toFixed(2);
                return `<option value="${v.id}">${this.escapeHtml(v.full_name || 'Vendor #' + v.id)} (ID: ${v.id} • Wallet: ₹${bal})</option>`;
            }).join('') : '<option value="" disabled>No active vendors found</option>';

            modalContent.innerHTML = `
                <form id="add-earning-form" onsubmit="event.preventDefault(); app.submitAddVendorEarning();" style="display: flex; flex-direction: column; gap: 16px;">
                    <div style="background: #f0fdf4; border: 1.5px solid #86efac; border-radius: 8px; padding: 12px 14px; font-size: 12px; color: #166534;">
                        <i class="fa-solid fa-circle-info" style="margin-right: 4px;"></i>
                        Crediting earnings will log a credit transaction into <strong>vendor_wallet_transactions</strong> for today (<strong>${new Date().toLocaleDateString('en-IN', { dateStyle: 'medium' })}</strong>). This vendor will immediately become eligible in today's payout batch.
                    </div>

                    <div>
                        <label style="font-size: 12px; font-weight: 800; text-transform: uppercase; color: var(--text-muted); display: block; margin-bottom: 6px;">
                            Select Vendor <span class="text-danger">*</span>
                        </label>
                        <select id="earning-vendor-id" class="form-control" required style="font-weight: 700;">
                            <option value="">-- Choose a Vendor --</option>
                            ${vendorOptions}
                        </select>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
                        <div>
                            <label style="font-size: 12px; font-weight: 800; text-transform: uppercase; color: var(--text-muted); display: block; margin-bottom: 6px;">
                                Earning Amount (₹) <span class="text-danger">*</span>
                            </label>
                            <input type="number" id="earning-amount" class="form-control" placeholder="e.g. 500.00" step="0.01" min="1" required style="font-weight: 800; font-size: 16px; color: #10b981;">
                        </div>
                        <div>
                            <label style="font-size: 12px; font-weight: 800; text-transform: uppercase; color: var(--text-muted); display: block; margin-bottom: 6px;">
                                Related Order # (Optional)
                            </label>
                            <input type="number" id="earning-order-id" class="form-control" placeholder="e.g. 101" style="font-family: monospace;">
                        </div>
                    </div>

                    <div>
                        <label style="font-size: 12px; font-weight: 800; text-transform: uppercase; color: var(--text-muted); display: block; margin-bottom: 6px;">
                            Description / Ledger Note
                        </label>
                        <input type="text" id="earning-description" class="form-control" placeholder="e.g. Daily order delivery earning credit" value="Daily order delivery earning credit">
                    </div>

                    <div style="display: flex; justify-content: flex-end; gap: 10px; margin-top: 10px; border-top: 1px solid var(--border-color); padding-top: 14px;">
                        <button type="button" class="btn btn-secondary" onclick="app.closeModal('details-modal')">Cancel</button>
                        <button type="submit" id="btn-submit-earning" class="btn btn-primary" style="display: inline-flex; align-items: center; gap: 8px; font-weight: 800; background: #10b981; border-color: #10b981;">
                            <i class="fa-solid fa-check"></i>
                            <span>Credit Earning Now</span>
                        </button>
                    </div>
                </form>
            `;
        } catch (err) {
            modalContent.innerHTML = `<div class="alert alert-danger">Failed to load vendors: ${this.escapeHtml(err.message)}</div>`;
        }
    }

    async submitAddVendorEarning() {
        const vendorId = parseInt(document.getElementById('earning-vendor-id')?.value, 10);
        const amount = parseFloat(document.getElementById('earning-amount')?.value);
        const orderIdVal = document.getElementById('earning-order-id')?.value.trim();
        const description = document.getElementById('earning-description')?.value.trim();
        const submitBtn = document.getElementById('btn-submit-earning');

        if (!vendorId) {
            this.showToast("Please choose a vendor.", "error");
            return;
        }
        if (!amount || amount <= 0) {
            this.showToast("Please enter a valid amount greater than ₹0.00.", "error");
            return;
        }

        if (submitBtn) {
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Crediting...';
        }

        try {
            const res = await api.addVendorEarning({
                vendor_id: vendorId,
                amount: amount,
                description: description || 'Daily order delivery earning credit',
                order_id: orderIdVal ? parseInt(orderIdVal, 10) : null
            });

            if (res && res.success) {
                this.showToast(res.message || `Successfully credited ₹${amount.toFixed(2)} to vendor!`, "success");
                this.closeModal('details-modal');
                await this.loadPayoutDashboardData();
                await this.fetchPayoutRecords();
            } else {
                this.showToast("Failed to add earning: " + (res.message || "Unknown error"), "error");
            }
        } catch (err) {
            this.showToast("Error adding vendor earning: " + err.message, "error");
        } finally {
            if (submitBtn) {
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<i class="fa-solid fa-check"></i> <span>Credit Earning Now</span>';
            }
        }
    }

    async openRazorpayXPayoutDetailsModal(id) {
        const modalTitle = document.getElementById('modal-title');
        const modalContent = document.getElementById('modal-content');
        if (!modalContent) return;

        if (modalTitle) {
            modalTitle.innerHTML = '<i class="fa-solid fa-receipt text-primary" style="margin-right: 8px;"></i> RazorpayX Payout & Ledger Details';
        }

        modalContent.innerHTML = `
            <div style="text-align: center; padding: 40px;">
                <div class="spinner" style="margin: 0 auto;"></div>
                <p style="margin-top: 10px; color: var(--text-muted);">Loading payout record and ledger breakdown...</p>
            </div>
        `;
        this.openModal('details-modal');

        try {
            const res = await api.getPayoutRecordDetails(id);
            if (!res || !res.success || !res.payout) {
                modalContent.innerHTML = `<div class="alert alert-danger">Payout record not found.</div>`;
                return;
            }

            const p = res.payout;
            const earnings = res.earning_allocations || [];
            const st = (p.status || '').toLowerCase();

            let badgeStyle = 'background: #f1f5f9; color: #475569; border: 1px solid #cbd5e1;';
            let iconClass = 'fa-solid fa-circle-minus';
            if (st === 'processed' || st === 'success') {
                badgeStyle = 'background: #dcfce7; color: #15803d; border: 1px solid #86efac;';
                iconClass = 'fa-solid fa-circle-check';
            } else if (st === 'processing') {
                badgeStyle = 'background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe;';
                iconClass = 'fa-solid fa-spinner fa-spin';
            } else if (st === 'queued') {
                badgeStyle = 'background: #f5f3ff; color: #6d28d9; border: 1px solid #ddd6fe;';
                iconClass = 'fa-solid fa-layer-group';
            } else if (st === 'pending') {
                badgeStyle = 'background: #fef3c7; color: #d97706; border: 1px solid #fde68a;';
                iconClass = 'fa-solid fa-clock-rotate-left';
            } else if (st === 'failed' || st === 'rejected') {
                badgeStyle = 'background: #fee2e2; color: #b91c1c; border: 1px solid #fca5a5;';
                iconClass = 'fa-solid fa-circle-xmark';
            }

            const netFormatted = `₹ ${(parseFloat(p.net_payout_amount) || 0).toFixed(2)}`;
            const earnFormatted = `₹ ${(parseFloat(p.eligible_earnings) || 0).toFixed(2)}`;
            const createdStr = p.created_at ? new Date(p.created_at).toLocaleString('en-IN', { dateStyle: 'full', timeStyle: 'medium' }) : 'N/A';
            const processedStr = p.processed_at ? new Date(p.processed_at).toLocaleString('en-IN', { dateStyle: 'full', timeStyle: 'medium' }) : 'Pending / Not Settled';

            // Earning order ledger rows
            const earningRows = earnings.length > 0 ? earnings.map(e => `
                <tr style="border-bottom: 1px solid var(--border-color); font-size: 12px;">
                    <td style="padding: 10px 12px; font-weight: 700;">#${e.order_id || 'N/A'}</td>
                    <td style="padding: 10px 12px;">${this.escapeHtml(e.description || 'Earning credit')}</td>
                    <td style="padding: 10px 12px; font-weight: 800; color: #10b981;">₹${(parseFloat(e.amount) || 0).toFixed(2)}</td>
                    <td style="padding: 10px 12px; color: var(--text-muted);">${e.created_at ? new Date(e.created_at).toLocaleTimeString('en-IN') : 'N/A'}</td>
                </tr>
            `).join('') : `
                <tr>
                    <td colspan="4" style="text-align: center; padding: 16px; color: var(--text-muted); font-size: 12px;">
                        No individual order ledger entries attached for this cycle date.
                    </td>
                </tr>
            `;

            // Status history timeline
            const historyTimeline = (p.status_history_parsed || []).map(h => `
                <div style="display: flex; gap: 10px; font-size: 12px; align-items: flex-start;">
                    <span style="font-weight: 800; text-transform: uppercase; color: #2563eb; width: 85px;">${this.escapeHtml(h.status || '')}</span>
                    <span style="color: var(--text-muted); width: 140px;">${h.timestamp ? new Date(h.timestamp * 1000).toLocaleString('en-IN') : 'N/A'}</span>
                    <span style="color: #334155;">${this.escapeHtml(h.note || (h.source ? 'Source: ' + h.source : 'Status update'))} ${h.utr ? '(UTR: ' + h.utr + ')' : ''}</span>
                </div>
            `).join('') || '<div style="font-size: 12px; color: var(--text-muted);">No transition history recorded.</div>';

            modalContent.innerHTML = `
                <div style="display: flex; flex-direction: column; gap: 18px;">
                    <!-- Top Status Banner -->
                    <div style="background: var(--bg-secondary); border-radius: var(--radius-md); padding: 16px; border: 1px solid var(--border-color); display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px;">
                        <div>
                            <div style="font-size: 11px; text-transform: uppercase; color: var(--text-muted); font-weight: 800; letter-spacing: 0.5px;">Net Payout Amount</div>
                            <div style="font-size: 28px; font-weight: 900; color: #10b981; margin-top: 2px;">${netFormatted}</div>
                            <div style="font-family: monospace; font-size: 12px; color: #64748b; margin-top: 2px;">Ref: <strong>${this.escapeHtml(p.internal_reference_id)}</strong></div>
                        </div>
                        <div style="display: flex; align-items: center; gap: 8px;">
                            <span style="display: inline-flex; align-items: center; gap: 6px; padding: 6px 14px; border-radius: 20px; font-size: 13px; font-weight: 800; text-transform: uppercase; ${badgeStyle}">
                                <i class="${iconClass}"></i> ${p.status}
                            </span>
                            ${(st === 'processing' || st === 'queued' || st === 'pending' || st === 'unknown') ? `
                                <button class="btn btn-primary btn-sm" onclick="app.reconcilePayoutRecord(${p.id})">
                                    <i class="fa-solid fa-arrows-rotate"></i> Reconcile Live
                                </button>
                            ` : ''}
                        </div>
                    </div>

                    <!-- 2-Col Details Layout -->
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 14px;">
                        <!-- Vendor & Bank Account -->
                        <div class="card" style="padding: 14px;">
                            <h4 style="font-size: 13px; font-weight: 800; color: var(--text-primary); border-bottom: 1px solid var(--border-color); padding-bottom: 8px; margin-bottom: 10px;">
                                <i class="fa-solid fa-shop text-primary" style="margin-right: 6px;"></i> Vendor & Beneficiary Account
                            </h4>
                            <div style="display: flex; flex-direction: column; gap: 6px; font-size: 12px;">
                                <div><strong style="color: var(--text-muted); font-size: 10px; display: block;">VENDOR NAME</strong> ${this.escapeHtml(p.vendor_name)}</div>
                                <div><strong style="color: var(--text-muted); font-size: 10px; display: block;">PHONE / EMAIL</strong> ${this.escapeHtml(p.vendor_phone || 'N/A')} • ${this.escapeHtml(p.vendor_email || 'N/A')}</div>
                                <div><strong style="color: var(--text-muted); font-size: 10px; display: block;">BANK NAME</strong> ${this.escapeHtml(p.bank_name || 'N/A')}</div>
                                <div><strong style="color: var(--text-muted); font-size: 10px; display: block;">ACCOUNT NUMBER (MASKED)</strong> <span style="font-family: monospace; font-weight: 700;">${this.escapeHtml(p.account_number_masked || p.account_number || 'N/A')}</span></div>
                                <div><strong style="color: var(--text-muted); font-size: 10px; display: block;">IFSC CODE</strong> <span style="font-family: monospace; font-weight: 700; color: #2563eb;">${this.escapeHtml(p.ifsc_code || 'N/A')}</span></div>
                                <div><strong style="color: var(--text-muted); font-size: 10px; display: block;">RAZORPAY FUND ACCOUNT ID</strong> <span style="font-family: monospace; font-size: 11px;">${this.escapeHtml(p.fund_account_id)}</span></div>
                            </div>
                        </div>

                        <!-- Amount Calculation & Razorpay Identifiers -->
                        <div class="card" style="padding: 14px;">
                            <h4 style="font-size: 13px; font-weight: 800; color: var(--text-primary); border-bottom: 1px solid var(--border-color); padding-bottom: 8px; margin-bottom: 10px;">
                                <i class="fa-solid fa-calculator text-primary" style="margin-right: 6px;"></i> Calculation & Razorpay Details
                            </h4>
                            <div style="display: flex; flex-direction: column; gap: 6px; font-size: 12px;">
                                <div><strong style="color: var(--text-muted); font-size: 10px; display: block;">ELIGIBLE DAILY EARNINGS</strong> ${earnFormatted}</div>
                                <div><strong style="color: var(--text-muted); font-size: 10px; display: block;">COMMISSION & DEDUCTIONS</strong> ₹ ${(parseFloat(p.commission_deductions) || 0).toFixed(2)}</div>
                                <div><strong style="color: var(--text-muted); font-size: 10px; display: block;">NET PAYOUT AMOUNT</strong> <span style="font-weight: 800; color: #10b981;">${netFormatted} (${p.amount_paise} paise)</span></div>
                                <div><strong style="color: var(--text-muted); font-size: 10px; display: block;">RAZORPAYX PAYOUT ID</strong> <span style="font-family: monospace; font-weight: 700; color: #2563eb;">${this.escapeHtml(p.razorpay_payout_id || 'Not Assigned')}</span></div>
                                <div><strong style="color: var(--text-muted); font-size: 10px; display: block;">BANK UTR NUMBER</strong> <span style="font-family: monospace; font-weight: 700; color: #059669;">${this.escapeHtml(p.utr || 'Pending')}</span></div>
                                <div><strong style="color: var(--text-muted); font-size: 10px; display: block;">MODE / PURPOSE</strong> ${this.escapeHtml(p.mode || 'IMPS')} • ${this.escapeHtml(p.purpose || 'payout')}</div>
                                <div><strong style="color: var(--text-muted); font-size: 10px; display: block;">SUBMISSION TIMING</strong> ${createdStr}</div>
                            </div>
                        </div>
                    </div>

                    ${p.failure_reason ? `
                        <!-- Failure Diagnostics -->
                        <div style="background: #fef2f2; border: 1.5px solid #fca5a5; border-radius: 8px; padding: 14px; color: #991b1b; font-size: 12px;">
                            <div style="font-weight: 800; display: flex; align-items: center; gap: 6px; font-size: 13px;">
                                <i class="fa-solid fa-triangle-exclamation"></i> Failure Code: ${this.escapeHtml(p.failure_code || 'PROVIDER_ERROR')}
                            </div>
                            <div style="margin-top: 4px; color: #7f1d1d;">${this.escapeHtml(p.failure_reason)}</div>
                        </div>
                    ` : ''}

                    <!-- Earning Order Ledger Allocations -->
                    <div class="card" style="padding: 14px;">
                        <h4 style="font-size: 13px; font-weight: 800; color: var(--text-primary); margin-bottom: 10px;">
                            <i class="fa-solid fa-list-check text-primary" style="margin-right: 6px;"></i> Related Eligible Orders & Wallet Credits (${earnings.length})
                        </h4>
                        <div style="overflow-x: auto; max-height: 200px;">
                            <table class="table" style="width: 100%; border-collapse: collapse;">
                                <thead>
                                    <tr style="background: var(--bg-hover); text-align: left; font-size: 11px; text-transform: uppercase;">
                                        <th style="padding: 8px 12px;">Order #</th>
                                        <th style="padding: 8px 12px;">Description</th>
                                        <th style="padding: 8px 12px;">Credit Amount</th>
                                        <th style="padding: 8px 12px;">Credited Time</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${earningRows}
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- Status History Audit Timeline -->
                    <div class="card" style="padding: 14px;">
                        <h4 style="font-size: 13px; font-weight: 800; color: var(--text-primary); margin-bottom: 10px;">
                            <i class="fa-solid fa-timeline text-primary" style="margin-right: 6px;"></i> Status Transition & Reconciliation Audit Timeline
                        </h4>
                        <div style="display: flex; flex-direction: column; gap: 8px; background: var(--bg-surface); padding: 12px; border-radius: 8px; border: 1px solid var(--border-color);">
                            ${historyTimeline}
                        </div>
                    </div>

                    <!-- Raw JSON Accordion -->
                    <details style="background: #0f172a; border-radius: 8px; padding: 12px; font-family: monospace; font-size: 11px; color: #7dd3fc;">
                        <summary style="cursor: pointer; font-weight: 700; color: #38bdf8; outline: none;">
                            <i class="fa-solid fa-code"></i> View Raw JSON Payload from RazorpayX
                        </summary>
                        <pre style="margin: 8px 0 0 0; white-space: pre-wrap; word-break: break-all; max-height: 200px; overflow-y: auto;">${this.escapeHtml(JSON.stringify(p.raw_response_parsed || {}, null, 2))}</pre>
                    </details>
                </div>
            `;

        } catch (err) {
            modalContent.innerHTML = `<div class="alert alert-danger">Error loading payout details: ${err.message}</div>`;
        }
    }

    async fetchPayoutsList() {
        const tbody = document.getElementById('payouts-table-body');
        if (!tbody) return;

        try {
            const res = await api.getPayouts(this.payoutQuery);
            const { summary, payouts, pagination } = res;
            this.currentPayoutsList = payouts || [];

            // Update stats
            const headerPayuBalEl = document.getElementById('header-payu-balance');
            const payuBalanceEl   = document.getElementById('stat-payu-balance');
            const totalSettledEl  = document.getElementById('stat-total-settled');
            const todaySettledEl  = document.getElementById('stat-today-settled');
            const pendingCountEl  = document.getElementById('stat-pending-count');
            const failedCountEl   = document.getElementById('stat-failed-count');

            const formattedPayuBal = `₹ ${(parseFloat(summary.payu_balance !== undefined ? summary.payu_balance : 250000) || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
            if (headerPayuBalEl) headerPayuBalEl.textContent = formattedPayuBal;
            if (payuBalanceEl)   payuBalanceEl.textContent   = formattedPayuBal;
            if (totalSettledEl) totalSettledEl.textContent = `₹ ${summary.total_settled_amount.toFixed(2)}`;
            if (todaySettledEl) todaySettledEl.textContent = `₹ ${summary.today_settled_amount.toFixed(2)}`;
            if (pendingCountEl) pendingCountEl.textContent = summary.total_pending_count;
            if (failedCountEl)  failedCountEl.textContent  = summary.total_failed_count;

            if (!payouts || payouts.length === 0) {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="10" class="text-center" style="padding: 40px; color: var(--text-muted);">
                            <i class="fa-solid fa-receipt" style="font-size: 32px; margin-bottom: 8px; display: block; opacity: 0.5;"></i>
                            No settlement payout records found for the selected filters.
                        </td>
                    </tr>
                `;
                this.renderPagination('payouts-pagination', pagination, (newPage) => {
                    this.payoutQuery.page = newPage;
                    this.fetchPayoutsList();
                });
                return;
            }

            tbody.innerHTML = payouts.map(item => {
                let badgeClass = 'background: #fef3c7; color: #d97706;';
                let iconClass = 'fa-solid fa-clock-rotate-left';
                if (item.status === 'SUCCESS') {
                    badgeClass = 'background: #d1fae5; color: #059669;';
                    iconClass = 'fa-solid fa-circle-check';
                } else if (item.status === 'FAILED') {
                    badgeClass = 'background: #fee2e2; color: #dc2626;';
                    iconClass = 'fa-solid fa-circle-xmark';
                }

                const amountFormatted = `₹ ${item.amount.toFixed(2)}`;
                const last4Formatted = item.account_last4 ? `A/C ****${item.account_last4}` : 'N/A';
                const createdDateStr = item.created_at ? new Date(item.created_at).toLocaleString() : 'N/A';

                return `
                    <tr style="border-bottom: 1px solid var(--border-color);">
                        <td style="padding: 14px 16px;">
                            <div style="font-weight: 700; font-size: 13px;">#${item.id}</div>
                            <div style="font-size: 11px; color: var(--text-muted);">${this.escapeHtml(item.reference_id || '')}</div>
                        </td>
                        <td style="padding: 14px 16px;">
                            <div style="font-weight: 700; color: var(--text-primary); font-size: 13px;">${this.escapeHtml(item.vendor_name)}</div>
                            <div style="font-size: 11px; color: var(--text-muted);">${this.escapeHtml(item.vendor_business_name || '')}</div>
                            <div style="font-size: 11px; color: var(--text-muted);"><i class="fa-solid fa-phone" style="font-size: 10px;"></i> ${this.escapeHtml(item.vendor_phone || '')}</div>
                        </td>
                        <td style="padding: 14px 16px; font-weight: 600; font-size: 13px;">${this.escapeHtml(item.target_date || '')}</td>
                        <td style="padding: 14px 16px; font-weight: 800; font-size: 14px; color: #10b981;">${amountFormatted}</td>
                        <td style="padding: 14px 16px;">
                            <div style="font-size: 12px; font-weight: 600; font-family: monospace;">PayU ID: ${this.escapeHtml(item.payu_payout_id || 'Pending')}</div>
                            ${item.payu_utr ? `<div style="font-size: 11px; color: var(--text-muted);">UTR: ${this.escapeHtml(item.payu_utr)}</div>` : ''}
                        </td>
                        <td style="padding: 14px 16px;">
                            <span style="display: inline-flex; align-items: center; gap: 5px; padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 700; ${badgeClass}">
                                <i class="${iconClass}"></i> ${item.status}
                            </span>
                            ${item.failure_reason ? `<div style="font-size: 10px; color: #dc2626; margin-top: 4px; max-width: 180px;">${this.escapeHtml(item.failure_reason)}</div>` : ''}
                        </td>
                        <td style="padding: 14px 16px; font-size: 12px; font-weight: 600; font-family: monospace;">
                            ${last4Formatted}
                        </td>
                        <td style="padding: 14px 16px; font-size: 11px; color: var(--text-muted);">${createdDateStr}</td>
                        <td style="padding: 14px 16px; text-align: right;">
                            <button class="btn btn-secondary btn-icon" title="View Full Settlement Details" onclick="app.openPayoutDetailsModal(${item.id})">
                                <i class="fa-solid fa-eye"></i>
                            </button>
                        </td>
                    </tr>
                `;
            }).join('');

            this.renderPagination('payouts-pagination', pagination, (newPage) => {
                this.payoutQuery.page = newPage;
                this.fetchPayoutsList();
            });

        } catch (err) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="13" class="text-center text-danger" style="padding: 24px;">
                        Failed to load vendor payout records: ${err.message}
                    </td>
                </tr>
            `;
        }
    }

    async handleLegacyPayuPayoutTrigger() {
        const confirmAction = confirm("Are you sure you want to run Today's Vendor Payouts now?\n\nThis will calculate today's earnings for each payout-enabled vendor, register beneficiaries if needed, and process settlement transfers via PayU Payouts.");
        if (!confirmAction) return;

        this.showLoader(true);
        try {
            const result = await api.triggerVendorPayouts();
            this.showToast(result.message || "Vendor payouts processed successfully!", "success");
            await this.fetchPayoutsList();
        } catch (error) {
            this.showToast("Failed to process payouts: " + error.message, "error");
        } finally {
            this.showLoader(false);
        }
    }
    openPayoutDetailsModal(id) {
        const item = (this.currentPayoutsList || []).find(x => x.id === id);
        if (!item) return;

        const modalTitle = document.getElementById('modal-title');
        const modalContent = document.getElementById('modal-content');
        if (!modalContent) return;

        if (modalTitle) {
            modalTitle.innerHTML = '<i class="fa-solid fa-receipt text-primary" style="margin-right: 8px;"></i> Vendor Payout & Bank Settlement Details';
        }

        let badgeClass = 'background: #fef3c7; color: #d97706; border: 1px solid #fde68a;';
        let iconClass = 'fa-solid fa-clock-rotate-left';
        if (item.status === 'SUCCESS') {
            badgeClass = 'background: #d1fae5; color: #059669; border: 1px solid #a7f3d0;';
            iconClass = 'fa-solid fa-circle-check';
        } else if (item.status === 'FAILED') {
            badgeClass = 'background: #fee2e2; color: #dc2626; border: 1px solid #fca5a5;';
            iconClass = 'fa-solid fa-circle-xmark';
        }

        const amountFormatted = `₹ ${(item.amount || 0).toFixed(2)}`;
        const createdDateStr = item.created_at ? new Date(item.created_at).toLocaleString() : 'N/A';
        const executedDateStr = item.executed_at ? new Date(item.executed_at).toLocaleString() : 'N/A';
        const completedDateStr = item.completed_at ? new Date(item.completed_at).toLocaleString() : 'N/A';

        modalContent.innerHTML = `
            <div style="display: flex; flex-direction: column; gap: 20px;">
                <!-- Top Status Header -->
                <div style="background: var(--bg-secondary); border-radius: var(--radius-md); padding: 16px; border: 1px solid var(--border-color); display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px;">
                    <div>
                        <div style="font-size: 11px; text-transform: uppercase; color: var(--text-muted); font-weight: 700; letter-spacing: 0.5px;">Settlement Amount</div>
                        <div style="font-size: 28px; font-weight: 900; color: #10b981; margin-top: 2px;">${amountFormatted}</div>
                    </div>
                    <div>
                        <span style="display: inline-flex; align-items: center; gap: 6px; padding: 6px 14px; border-radius: 20px; font-size: 13px; font-weight: 800; ${badgeClass}">
                            <i class="${iconClass}"></i> ${item.status}
                        </span>
                    </div>
                </div>

                <!-- 2-Column Details Layout -->
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
                    
                    <!-- Vendor Information Card -->
                    <div style="border: 1px solid var(--border-color); border-radius: var(--radius-md); padding: 16px; background: #fff;">
                        <h4 style="font-size: 14px; font-weight: 700; margin-bottom: 14px; color: var(--text-primary); border-bottom: 1px solid var(--border-color); padding-bottom: 8px;">
                            <i class="fa-solid fa-shop text-primary" style="margin-right: 6px;"></i> Vendor Information
                        </h4>
                        <div style="display: flex; flex-direction: column; gap: 8px; font-size: 13px;">
                            <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">FULL NAME</strong> ${this.escapeHtml(item.vendor_name || 'N/A')}</div>
                            <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">BUSINESS / HOLDER NAME</strong> ${this.escapeHtml(item.vendor_business_name || 'N/A')}</div>
                            <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">PHONE NUMBER</strong> ${this.escapeHtml(item.vendor_phone || 'N/A')}</div>
                            <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">EMAIL ADDRESS</strong> ${this.escapeHtml(item.vendor_email || 'N/A')}</div>
                        </div>
                    </div>

                    <!-- Full Bank Account Details Card -->
                    <div style="border: 1px solid var(--border-color); border-radius: var(--radius-md); padding: 16px; background: #fff;">
                        <h4 style="font-size: 14px; font-weight: 700; margin-bottom: 14px; color: var(--text-primary); border-bottom: 1px solid var(--border-color); padding-bottom: 8px;">
                            <i class="fa-solid fa-building-columns text-primary" style="margin-right: 6px;"></i> Full Bank Account Details
                        </h4>
                        <div style="display: flex; flex-direction: column; gap: 8px; font-size: 13px;">
                            <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">BANK NAME</strong> ${this.escapeHtml(item.bank_name || 'N/A')}</div>
                            <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">ACCOUNT HOLDER NAME</strong> ${this.escapeHtml(item.account_holder_name || 'N/A')}</div>
                            <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">FULL ACCOUNT NUMBER</strong> <span style="font-family: monospace; font-weight: 700; color: #1e293b; font-size: 14px; background: #f1f5f9; padding: 2px 6px; border-radius: 4px;">${this.escapeHtml(item.account_number || 'N/A')}</span></div>
                            <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">IFSC CODE</strong> <span style="font-family: monospace; font-weight: 700; color: var(--accent-primary);">${this.escapeHtml(item.ifsc_code || 'N/A')}</span></div>
                            <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">PAYU BENEFICIARY ID</strong> <span style="font-family: monospace; font-size: 12px; color: #475569;">${this.escapeHtml(item.payu_beneficiary_id || 'N/A')}</span></div>
                        </div>
                    </div>

                </div>

                <!-- PayU Transaction & Settlement Reference Card -->
                <div style="border: 1px solid var(--border-color); border-radius: var(--radius-md); padding: 16px; background: #fff;">
                    <h4 style="font-size: 14px; font-weight: 700; margin-bottom: 14px; color: var(--text-primary); border-bottom: 1px solid var(--border-color); padding-bottom: 8px;">
                        <i class="fa-solid fa-receipt text-primary" style="margin-right: 6px;"></i> PayU Transfer & Reference Details
                    </h4>
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px; font-size: 13px;">
                        <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">PAYOUT RECORD ID</strong> #${item.id}</div>
                        <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">MERCHANT REFERENCE ID</strong> <span style="font-family: monospace; font-size: 11px;">${this.escapeHtml(item.reference_id || 'N/A')}</span></div>
                        <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">PAYU PAYOUT ID / TRANSACTION ID</strong> <span style="font-family: monospace; font-weight: 600;">${this.escapeHtml(item.payu_payout_id || 'N/A')}</span></div>
                        <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">PAYU BATCH ID</strong> <span style="font-family: monospace; font-size: 11px;">${this.escapeHtml(item.payu_batch_id || 'N/A')}</span></div>
                        <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">BANK UTR / REF NUMBER</strong> <span style="font-family: monospace; font-weight: 700; color: #059669;">${this.escapeHtml(item.payu_utr || 'N/A')}</span></div>
                        <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">TARGET DATE</strong> ${this.escapeHtml(item.target_date || 'N/A')}</div>
                        <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">CREATED AT</strong> ${createdDateStr}</div>
                        <div><strong style="color: var(--text-muted); font-size: 11px; display: block;">COMPLETED AT</strong> ${completedDateStr}</div>
                    </div>
                    ${item.failure_reason ? `
                        <div style="margin-top: 14px; padding: 10px 14px; background: #fef2f2; border: 1px solid #fca5a5; border-radius: 8px; color: #991b1b; font-size: 12px;">
                            <strong><i class="fa-solid fa-triangle-exclamation"></i> Failure Reason:</strong> ${this.escapeHtml(item.failure_reason)}
                        </div>
                    ` : ''}
                </div>

                <!-- Razorpay Fund Account (Live GET /v1/fund_accounts/{id}) -->
                <div id="payout-rzp-fa-section" style="border: 1.5px solid #93c5fd; border-radius: var(--radius-md); padding: 18px; background: #f0f7ff;">
                    <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; border-bottom: 1px solid #bfdbfe; padding-bottom: 10px; flex-wrap: wrap; gap: 8px;">
                        <h4 style="font-size: 14px; font-weight: 800; color: #1e40af; margin: 0; display: flex; align-items: center; gap: 8px;">
                            <i class="fa-solid fa-bolt text-primary"></i> Razorpay Fund Account Entity
                            <span style="font-family: monospace; font-size: 11px; background: #dbeafe; color: #1d4ed8; padding: 2px 8px; border-radius: 6px; font-weight: 600;">GET /v1/fund_accounts/{id}</span>
                        </h4>
                        <div id="rzp-fa-badge-slot" style="font-size: 12px; font-weight: 700;">
                            <span style="background: #e0f2fe; color: #0369a1; padding: 3px 10px; border-radius: 12px; border: 1px solid #bae6fd;">
                                <i class="fa-solid fa-spinner fa-spin"></i> Hitting Razorpay API...
                            </span>
                        </div>
                    </div>
                    <div id="payout-rzp-fa-content">
                        <div style="text-align: center; padding: 20px; color: #3b82f6;">
                            <div class="spinner" style="margin: 0 auto;"></div>
                            <div style="margin-top: 8px; font-size: 12px;">Calling Razorpay API for vendor fund account...</div>
                        </div>
                    </div>
                </div>
            </div>
        `;

        this.openModal('details-modal');
        this.loadLiveFundAccount('payout-rzp-fa-content', 'rzp-fa-badge-slot', item.razorpay_fund_account_id, item.razorpay_contact_id, item.vendor_id);
    }

    switchPayoutSubTab(tab) {
        this.activePayoutSubTab = tab;
        const btnContacts = document.getElementById('tab-rzp-contacts-btn');
        const btnSettlements = document.getElementById('tab-payout-logs-btn');
        const paneContacts = document.getElementById('payout-subtab-contacts');
        const paneSettlements = document.getElementById('payout-subtab-settlements');

        if (tab === 'contacts') {
            btnContacts?.classList.add('active');
            btnSettlements?.classList.remove('active');
            if (paneContacts) paneContacts.style.display = 'block';
            if (paneSettlements) paneSettlements.style.display = 'none';
        } else {
            btnContacts?.classList.remove('active');
            btnSettlements?.classList.add('active');
            if (paneContacts) paneContacts.style.display = 'none';
            if (paneSettlements) paneSettlements.style.display = 'block';
        }
    }

    async syncAllVendorsRazorpay() {
        const confirmSync = confirm("Are you sure you want to automatically apply Razorpay Contacts and Fund Accounts for all existing vendors in the database?");
        if (!confirmSync) return;

        this.showLoader(true);
        try {
            const res = await api.syncVendorsRazorpay();
            this.showToast(res.message || "Vendors synchronized with Razorpay successfully!", "success");
            await this.fetchRazorpayContacts();
            await this.fetchPayoutsList();
        } catch (err) {
            this.showToast("Failed to sync vendors: " + err.message, "error");
        } finally {
            this.showLoader(false);
        }
    }
    async fetchRazorpayContacts(showToastNotification = false) {
        const tbody = document.getElementById('rzp-contacts-table-body');
        if (tbody) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="9" class="text-center" style="padding: 30px;">
                        <div class="spinner" style="margin: 0 auto;"></div>
                        <p style="margin-top: 10px; color: var(--text-muted);">Fetching contacts from Razorpay API (GET /v1/contacts)...</p>
                    </td>
                </tr>
            `;
        }

        try {
            const res = await api.getRazorpayContacts();
            const items = res.items || [];
            this.currentRazorpayContacts = items;

            // Update stats
            const countEl = document.getElementById('stat-rzp-contacts-count');
            const pillEl = document.getElementById('rzp-contacts-pill');
            if (countEl) countEl.textContent = res.count ?? items.length;
            if (pillEl) pillEl.textContent = `${items.length} Contacts`;

            this.renderRazorpayContactsList();

            if (showToastNotification) {
                this.showToast(`Fetched ${items.length} Razorpay contacts successfully!`, "success");
            }
        } catch (err) {
            console.error("Razorpay contacts fetch error:", err);
            if (tbody) {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="9" class="text-center text-danger" style="padding: 24px;">
                            <i class="fa-solid fa-triangle-exclamation" style="font-size: 24px; margin-bottom: 8px; display: block;"></i>
                            Failed to fetch Razorpay contacts: ${this.escapeHtml(err.message || 'API error')}
                        </td>
                    </tr>
                `;
            }
            if (showToastNotification) {
                this.showToast("Failed to fetch Razorpay contacts: " + err.message, "error");
            }
        }
    }

    renderRazorpayContactsList() {
        const tbody = document.getElementById('rzp-contacts-table-body');
        if (!tbody) return;

        const searchVal = (document.getElementById('rzp-contact-search')?.value || '').trim().toLowerCase();
        const typeVal = (document.getElementById('rzp-contact-type-filter')?.value || 'all').toLowerCase();
        const statusVal = (document.getElementById('rzp-contact-status-filter')?.value || 'all').toLowerCase();

        let filtered = (this.currentRazorpayContacts || []).filter(item => {
            if (typeVal !== 'all' && (item.type || '').toLowerCase() !== typeVal) return false;
            if (statusVal === 'active' && !item.active) return false;
            if (statusVal === 'inactive' && item.active) return false;

            if (searchVal) {
                const matchId = (item.id || '').toLowerCase().includes(searchVal);
                const matchName = (item.name || '').toLowerCase().includes(searchVal);
                const matchContact = (item.contact || '').toLowerCase().includes(searchVal);
                const matchEmail = (item.email || '').toLowerCase().includes(searchVal);
                const matchRef = (item.reference_id || '').toLowerCase().includes(searchVal);
                return matchId || matchName || matchContact || matchEmail || matchRef;
            }
            return true;
        });

        if (filtered.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="9" class="text-center" style="padding: 40px; color: var(--text-muted);">
                        <i class="fa-solid fa-address-book" style="font-size: 32px; margin-bottom: 8px; display: block; opacity: 0.4;"></i>
                        No Razorpay contacts found matching the filters.
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = filtered.map(item => {
            const isActive = !!item.active;
            const statusBadge = isActive
                ? `<span style="background: #dcfce7; color: #15803d; border: 1px solid #86efac; padding: 3px 8px; border-radius: 12px; font-size: 11px; font-weight: 700; display: inline-flex; align-items: center; gap: 4px;">
                     <i class="fa-solid fa-circle-check" style="font-size: 10px;"></i> Active
                   </span>`
                : `<span style="background: #fee2e2; color: #b91c1c; border: 1px solid #fca5a5; padding: 3px 8px; border-radius: 12px; font-size: 11px; font-weight: 700; display: inline-flex; align-items: center; gap: 4px;">
                     <i class="fa-solid fa-circle-xmark" style="font-size: 10px;"></i> Inactive
                   </span>`;

            let typeBadgeColor = 'background: #f3e8ff; color: #7e22ce; border: 1px solid #d8b4fe;';
            if (item.type === 'employee') {
                typeBadgeColor = 'background: #dbeafe; color: #1d4ed8; border: 1px solid #93c5fd;';
            } else if (item.type === 'self') {
                typeBadgeColor = 'background: #ccfbf1; color: #0f766e; border: 1px solid #5eead4;';
            }

            const cleanPhone = (item.contact || '').replace(/[^0-9]/g, '');
            const waPhone = cleanPhone.length === 10 ? '91' + cleanPhone : cleanPhone;

            let notesHtml = '<span style="color: var(--text-muted); font-size: 11px;">None</span>';
            if (item.notes && typeof item.notes === 'object' && Object.keys(item.notes).length > 0) {
                notesHtml = Object.entries(item.notes).slice(0, 3).map(([k, v]) => {
                    return `<span style="display: inline-block; background: var(--bg-surface-hover); border: 1px solid var(--border-color); border-radius: 4px; padding: 2px 6px; font-size: 10px; margin: 1px 2px; color: var(--text-secondary); max-width: 140px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" title="${this.escapeHtml(k)}: ${this.escapeHtml(String(v))}">
                        <strong>${this.escapeHtml(k)}:</strong> ${this.escapeHtml(String(v))}
                    </span>`;
                }).join('');
                if (Object.keys(item.notes).length > 3) {
                    notesHtml += `<span style="font-size: 10px; color: var(--text-muted);"> +${Object.keys(item.notes).length - 3}</span>`;
                }
            }

            const createdDateStr = item.created_at
                ? new Date(item.created_at * 1000).toLocaleString('en-IN', {
                    day: '2-digit', month: 'short', year: 'numeric',
                    hour: '2-digit', minute: '2-digit'
                  })
                : 'N/A';

            return `
                <tr style="border-bottom: 1px solid var(--border-color);">
                    <td style="padding: 12px 16px;">
                        <div style="font-family: monospace; font-weight: 700; font-size: 12px; color: var(--accent-primary); display: flex; align-items: center; gap: 6px;">
                            <span>${this.escapeHtml(item.id)}</span>
                            <button onclick="app.copyToClipboard('${item.id}')" title="Copy Contact ID" style="background: none; border: none; cursor: pointer; color: var(--text-muted); font-size: 11px; padding: 2px;">
                                <i class="fa-regular fa-copy"></i>
                            </button>
                        </div>
                        ${item.reference_id ? `<div style="font-size: 11px; color: var(--text-muted); margin-top: 2px;">Ref: <strong style="font-family: monospace;">${this.escapeHtml(item.reference_id)}</strong></div>` : ''}
                    </td>
                    <td style="padding: 12px 16px;">
                        <div style="font-weight: 700; color: var(--text-primary); font-size: 13px;">${this.escapeHtml(item.name || 'Unnamed')}</div>
                        <div style="font-size: 10px; color: var(--text-muted); text-transform: uppercase;">entity: ${this.escapeHtml(item.entity || 'contact')}</div>
                        ${item.matched_vendor ? `<div style="font-size: 11px; color: #15803d; font-weight: 600; margin-top: 2px;"><i class="fa-solid fa-store" style="font-size: 10px;"></i> Mess Vendor #${item.matched_vendor.id}</div>` : ''}
                    </td>
                    <td style="padding: 12px 16px;">
                        <div style="font-weight: 600; font-size: 12px; display: flex; align-items: center; gap: 6px;">
                            <span>${this.escapeHtml(item.contact || 'N/A')}</span>
                            ${cleanPhone ? `
                                <a href="https://wa.me/${waPhone}" target="_blank" title="Message on WhatsApp" style="color: #25D366; font-size: 13px;">
                                    <i class="fa-brands fa-whatsapp"></i>
                                </a>
                            ` : ''}
                        </div>
                    </td>
                    <td style="padding: 12px 16px;">
                        <div style="font-size: 12px;">
                            ${item.email ? `<a href="mailto:${this.escapeHtml(item.email)}" style="color: var(--text-secondary); text-decoration: none;">${this.escapeHtml(item.email)}</a>` : '<span style="color: var(--text-muted);">N/A</span>'}
                        </div>
                    </td>
                    <td style="padding: 12px 16px;">
                        <span style="${typeBadgeColor} padding: 3px 8px; border-radius: 12px; font-size: 11px; font-weight: 700; text-transform: lowercase;">
                            ${this.escapeHtml(item.type || 'vendor')}
                        </span>
                    </td>
                    <td style="padding: 12px 16px;">
                        ${statusBadge}
                    </td>
                    <td style="padding: 12px 16px; max-width: 220px;">
                        ${notesHtml}
                    </td>
                    <td style="padding: 12px 16px; font-size: 11px; color: var(--text-muted); white-space: nowrap;">
                        ${createdDateStr}
                    </td>
                    <td style="padding: 12px 16px; text-align: right;">
                        <button class="btn btn-secondary btn-icon" title="View Full Contact Info & JSON" onclick="app.openRazorpayContactDetailsModal('${item.id}')">
                            <i class="fa-solid fa-eye"></i>
                        </button>
                        <button class="btn btn-secondary btn-icon" title="View Razorpay Fund Account (GET /v1/fund_accounts)" onclick="app.openRazorpayFundAccountModal('', '${item.id}')" style="margin-left: 4px; color: #2563eb;">
                            <i class="fa-solid fa-building-columns"></i>
                        </button>
                    </td>
                </tr>
            `;
        }).join('');
    }

    openRazorpayContactDetailsModal(contactId) {
        const item = (this.currentRazorpayContacts || []).find(x => x.id === contactId);
        if (!item) return;

        const modalTitle = document.getElementById('modal-title');
        const modalContent = document.getElementById('modal-content');
        if (!modalContent) return;

        if (modalTitle) {
            modalTitle.innerHTML = '<i class="fa-solid fa-address-book text-primary" style="margin-right: 8px;"></i> Razorpay Contact Details';
        }

        const isActive = !!item.active;
        const statusBadge = isActive
            ? `<span style="background: #dcfce7; color: #15803d; border: 1px solid #86efac; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 700;"><i class="fa-solid fa-circle-check"></i> Active</span>`
            : `<span style="background: #fee2e2; color: #b91c1c; border: 1px solid #fca5a5; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 700;"><i class="fa-solid fa-circle-xmark"></i> Inactive</span>`;

        const createdDateStr = item.created_at
            ? new Date(item.created_at * 1000).toLocaleString('en-IN', {
                dateStyle: 'full', timeStyle: 'medium'
              })
            : 'N/A';

        let notesRows = '<tr><td colspan="2" style="color: var(--text-muted); font-size: 12px; padding: 8px 12px;">No custom notes attached</td></tr>';
        if (item.notes && typeof item.notes === 'object' && Object.keys(item.notes).length > 0) {
            notesRows = Object.entries(item.notes).map(([k, v]) => `
                <tr style="border-bottom: 1px solid var(--border-color);">
                    <td style="padding: 8px 12px; font-weight: 700; font-size: 12px; color: var(--text-secondary); width: 35%;">${this.escapeHtml(k)}</td>
                    <td style="padding: 8px 12px; font-size: 12px; font-family: monospace;">${this.escapeHtml(String(v))}</td>
                </tr>
            `).join('');
        }

        modalContent.innerHTML = `
            <div style="display: flex; flex-direction: column; gap: 18px;">
                <!-- Header Banner -->
                <div style="background: linear-gradient(135deg, #f0fdf4 0%, #dcfce7 100%); border: 1px solid #86efac; border-radius: var(--radius-md); padding: 18px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px;">
                    <div>
                        <div style="font-size: 11px; text-transform: uppercase; color: #166534; font-weight: 800; letter-spacing: 0.5px;">Razorpay Contact Entity</div>
                        <div style="font-size: 22px; font-weight: 900; color: #15803d; margin-top: 2px;">${this.escapeHtml(item.name || 'Unnamed')}</div>
                        <div style="font-family: monospace; font-size: 12px; color: #166534; margin-top: 4px;">ID: <strong>${this.escapeHtml(item.id)}</strong></div>
                    </div>
                    <div style="display: flex; gap: 8px; align-items: center;">
                        <span style="background: #f3e8ff; color: #7e22ce; border: 1px solid #d8b4fe; padding: 4px 10px; border-radius: 12px; font-size: 12px; font-weight: 700;">
                            Type: ${this.escapeHtml(item.type)}
                        </span>
                        ${statusBadge}
                    </div>
                </div>

                <!-- Info Grid -->
                <div class="card" style="padding: 16px;">
                    <h4 style="font-size: 13px; font-weight: 800; text-transform: uppercase; color: var(--text-muted); margin-bottom: 12px;">Contact Information</h4>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 14px;">
                        <div>
                            <span style="font-size: 11px; color: var(--text-muted); font-weight: 600; display: block;">CONTACT PHONE</span>
                            <span style="font-size: 13px; font-weight: 700;">${this.escapeHtml(item.contact || 'N/A')}</span>
                        </div>
                        <div>
                            <span style="font-size: 11px; color: var(--text-muted); font-weight: 600; display: block;">EMAIL ADDRESS</span>
                            <span style="font-size: 13px; font-weight: 700;">${this.escapeHtml(item.email || 'N/A')}</span>
                        </div>
                        <div>
                            <span style="font-size: 11px; color: var(--text-muted); font-weight: 600; display: block;">REFERENCE ID</span>
                            <span style="font-size: 13px; font-weight: 700; font-family: monospace;">${this.escapeHtml(item.reference_id || 'N/A')}</span>
                        </div>
                        <div>
                            <span style="font-size: 11px; color: var(--text-muted); font-weight: 600; display: block;">BATCH ID</span>
                            <span style="font-size: 13px; font-weight: 700;">${this.escapeHtml(item.batch_id || 'None')}</span>
                        </div>
                        <div>
                            <span style="font-size: 11px; color: var(--text-muted); font-weight: 600; display: block;">CREATED AT</span>
                            <span style="font-size: 12px;">${createdDateStr} (${item.created_at})</span>
                        </div>
                    </div>
                </div>

                <!-- Notes Breakdown -->
                <div class="card" style="padding: 16px;">
                    <h4 style="font-size: 13px; font-weight: 800; text-transform: uppercase; color: var(--text-muted); margin-bottom: 12px;">Metadata / Custom Notes</h4>
                    <table class="table" style="width: 100%; border-collapse: collapse;">
                        ${notesRows}
                    </table>
                </div>

                <!-- Linked Razorpay Fund Account Section -->
                <div id="contact-rzp-fa-card" style="border: 1.5px solid #93c5fd; border-radius: var(--radius-md); padding: 16px; background: #f0f7ff;">
                    <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px; border-bottom: 1px solid #bfdbfe; padding-bottom: 8px;">
                        <h4 style="font-size: 13px; font-weight: 800; color: #1e40af; margin: 0; display: flex; align-items: center; gap: 8px;">
                            <i class="fa-solid fa-building-columns text-primary"></i> Linked Razorpay Fund Account
                        </h4>
                        <div id="contact-fa-badge-slot"></div>
                    </div>
                    <div id="contact-rzp-fa-content">
                        <div class="spinner" style="margin: 8px auto;"></div>
                    </div>
                </div>

                <!-- Raw JSON Accordion -->
                <details style="background: var(--bg-surface); border: 1px solid var(--border-color); border-radius: 8px; padding: 12px;">
                    <summary style="cursor: pointer; font-size: 12px; font-weight: 700; color: var(--text-secondary); display: flex; align-items: center; gap: 6px;">
                        <i class="fa-solid fa-code"></i> View Raw JSON Payload from Razorpay
                    </summary>
                    <pre style="margin-top: 10px; background: #0f172a; color: #38bdf8; padding: 14px; border-radius: 8px; font-size: 11px; font-family: monospace; overflow-x: auto; max-height: 250px;">${this.escapeHtml(JSON.stringify(item, null, 2))}</pre>
                </details>
            </div>
        `;

        this.openModal('details-modal');
        this.loadLiveFundAccount('contact-rzp-fa-content', 'contact-fa-badge-slot', '', item.id);
    }


    async openRazorpayFundAccountModal(fundAccountId = '', contactId = '', vendorId = '') {
        const modalTitle = document.getElementById('modal-title');
        const modalContent = document.getElementById('modal-content');
        if (!modalContent) return;

        if (modalTitle) {
            modalTitle.innerHTML = '<i class="fa-solid fa-building-columns text-primary" style="margin-right: 8px;"></i> Razorpay Fund Account (GET /v1/fund_accounts/{id})';
        }

        modalContent.innerHTML = `
            <div style="text-align: center; padding: 40px;">
                <div class="spinner" style="margin: 0 auto;"></div>
                <p style="margin-top: 14px; font-weight: 600; color: var(--text-muted);">
                    Hitting Razorpay API...<br>
                    <code style="font-size: 12px; color: #2563eb;">GET https://api.razorpay.com/v1/fund_accounts/${fundAccountId || (contactId ? '?contact_id=' + contactId : '')}</code>
                </p>
            </div>
        `;
        this.openModal('details-modal');

        await this.loadLiveFundAccount(modalContent, null, fundAccountId, contactId, vendorId, true);
    }

    async loadLiveFundAccount(targetElOrId, badgeElOrId, fundAccountId = '', contactId = '', vendorId = '', isFullModal = false) {
        const container = typeof targetElOrId === 'string' ? document.getElementById(targetElOrId) : targetElOrId;
        const badgeSlot = typeof badgeElOrId === 'string' ? document.getElementById(badgeElOrId) : badgeElOrId;
        if (!container) return;

        try {
            const res = await api.getRazorpayFundAccount({
                fund_account_id: fundAccountId,
                contact_id: contactId,
                vendor_id: vendorId
            });

            if (!res || !res.success || !res.fund_account) {
                if (badgeSlot) {
                    badgeSlot.innerHTML = `<span style="background: #f1f5f9; color: #64748b; border: 1px solid #cbd5e1; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 700;"><i class="fa-solid fa-circle-minus"></i> Not Linked</span>`;
                }
                const msg = (res && res.message) ? res.message : 'No Razorpay Fund Account active for this vendor yet.';
                container.innerHTML = `
                    <div style="padding: 16px; background: #f8fafc; border: 1.5px dashed #cbd5e1; border-radius: 8px; text-align: center; color: var(--text-muted); font-size: 13px;">
                        <i class="fa-solid fa-building-columns" style="color: #94a3b8; font-size: 22px; margin-bottom: 8px; display: block;"></i>
                        <div style="font-weight: 700; color: #334155; font-size: 13px;">${this.escapeHtml(msg)}</div>
                        <div style="font-size: 11px; margin-top: 6px; color: #64748b;">(Generated automatically when valid bank details are added in the Vendor App)</div>
                    </div>
                `;
                return;
            }

            const fa = res.fund_account;
            const bank = fa.bank_account || {};
            const isActive = fa.active === true;
            const statusBadge = isActive
                ? `<span style="background: #dcfce7; color: #15803d; border: 1px solid #86efac; padding: 3px 10px; border-radius: 12px; font-size: 11px; font-weight: 700;"><i class="fa-solid fa-circle-check"></i> Active</span>`
                : `<span style="background: #fee2e2; color: #b91c1c; border: 1px solid #fca5a5; padding: 3px 10px; border-radius: 12px; font-size: 11px; font-weight: 700;"><i class="fa-solid fa-circle-xmark"></i> Inactive</span>`;

            if (badgeSlot) {
                badgeSlot.innerHTML = `
                    <div style="display: flex; align-items: center; gap: 6px;">
                        ${statusBadge}
                        ${res.latency_ms ? `<span style="background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; padding: 2px 8px; border-radius: 10px; font-size: 11px; font-weight: 800;">${res.latency_ms}ms</span>` : ''}
                    </div>
                `;
            }

            const createdDateStr = fa.created_at
                ? new Date(fa.created_at * 1000).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })
                : 'N/A';

            container.innerHTML = `
                <div style="display: flex; flex-direction: column; gap: 14px;">
                    <!-- Entity Header -->
                    <div style="background: #fff; border: 1px solid #bfdbfe; border-radius: var(--radius-sm); padding: 12px 16px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px;">
                        <div>
                            <div style="font-size: 10px; text-transform: uppercase; color: #64748b; font-weight: 800; letter-spacing: 0.5px;">Fund Account ID</div>
                            <div style="font-family: monospace; font-size: 16px; font-weight: 800; color: #1d4ed8;">${this.escapeHtml(fa.id)}</div>
                            <div style="font-size: 11px; color: #64748b; margin-top: 2px;">
                                Contact ID: <strong style="font-family: monospace;">${this.escapeHtml(fa.contact_id || 'N/A')}</strong> • Type: <strong>${this.escapeHtml(fa.account_type || 'bank_account')}</strong>
                            </div>
                        </div>
                        <div style="display: flex; align-items: center; gap: 8px;">
                            ${statusBadge}
                            ${res.latency_ms ? `<span style="background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; padding: 3px 8px; border-radius: 10px; font-size: 11px; font-weight: 800;">${res.latency_ms}ms</span>` : ''}
                        </div>
                    </div>

                    <!-- 2-Col Bank & Meta Layout -->
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 12px; font-size: 13px;">
                        <div style="background: #fff; border: 1px solid var(--border-color); border-radius: var(--radius-sm); padding: 12px;">
                            <div style="font-size: 11px; font-weight: 800; color: #64748b; text-transform: uppercase; margin-bottom: 8px;">
                                <i class="fa-solid fa-building-columns text-primary"></i> Bank Account
                            </div>
                            <div><strong style="color: var(--text-muted); font-size: 10px; display: block;">BANK NAME</strong> ${this.escapeHtml(bank.bank_name || 'N/A')}</div>
                            <div style="margin-top: 6px;"><strong style="color: var(--text-muted); font-size: 10px; display: block;">ACCOUNT HOLDER</strong> ${this.escapeHtml(bank.name || 'N/A')}</div>
                            <div style="margin-top: 6px;"><strong style="color: var(--text-muted); font-size: 10px; display: block;">ACCOUNT NUMBER</strong> <span style="font-family: monospace; font-weight: 700; color: #0f172a; background: #f1f5f9; padding: 2px 6px; border-radius: 4px;">${this.escapeHtml(bank.account_number || 'N/A')}</span></div>
                            <div style="margin-top: 6px;"><strong style="color: var(--text-muted); font-size: 10px; display: block;">IFSC CODE</strong> <span style="font-family: monospace; font-weight: 700; color: #2563eb;">${this.escapeHtml(bank.ifsc || 'N/A')}</span></div>
                        </div>

                        <div style="background: #fff; border: 1px solid var(--border-color); border-radius: var(--radius-sm); padding: 12px;">
                            <div style="font-size: 11px; font-weight: 800; color: #64748b; text-transform: uppercase; margin-bottom: 8px;">
                                <i class="fa-solid fa-circle-nodes text-primary"></i> Razorpay Entity Info
                            </div>
                            <div><strong style="color: var(--text-muted); font-size: 10px; display: block;">ENTITY</strong> ${this.escapeHtml(fa.entity || 'fund_account')}</div>
                            <div style="margin-top: 6px;"><strong style="color: var(--text-muted); font-size: 10px; display: block;">CONTACT ID</strong> <span style="font-family: monospace;">${this.escapeHtml(fa.contact_id || 'N/A')}</span></div>
                            <div style="margin-top: 6px;"><strong style="color: var(--text-muted); font-size: 10px; display: block;">BATCH ID</strong> <span style="font-family: monospace;">${fa.batch_id === null ? 'null' : this.escapeHtml(String(fa.batch_id))}</span></div>
                            <div style="margin-top: 6px;"><strong style="color: var(--text-muted); font-size: 10px; display: block;">CREATED AT</strong> ${createdDateStr} (${fa.created_at})</div>
                        </div>
                    </div>

                    <!-- Exact Success JSON Response Accordion -->
                    <details style="background: #0f172a; border-radius: var(--radius-sm); padding: 10px 14px; font-family: monospace; font-size: 11px; color: #7dd3fc;">
                        <summary style="cursor: pointer; font-weight: 700; color: #38bdf8; outline: none;">
                            <i class="fa-solid fa-code"></i> View Raw JSON (GET https://api.razorpay.com/v1/fund_accounts/${fa.id})
                        </summary>
                        <pre style="margin: 8px 0 0 0; white-space: pre-wrap; word-break: break-all; max-height: 200px; overflow-y: auto;">${this.escapeHtml(JSON.stringify(fa, null, 2))}</pre>
                    </details>
                </div>
            `;

        } catch (err) {
            if (badgeSlot) {
                badgeSlot.innerHTML = `<span style="background: #fee2e2; color: #b91c1c; border: 1px solid #fca5a5; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 700;">Notice</span>`;
            }
            container.innerHTML = `
                <div style="padding: 14px; background: #fef2f2; border: 1px solid #fecaca; border-radius: 8px; color: #991b1b; font-size: 12px; text-align: center;">
                    <i class="fa-solid fa-circle-exclamation" style="font-size: 18px; margin-bottom: 6px; display: block;"></i>
                    <strong style="color: #991b1b;">Razorpay Fund Account Notice:</strong>
                    <div style="margin-top: 4px; color: #7f1d1d;">${this.escapeHtml(err.message || 'Unable to retrieve fund account at this time.')}</div>
                </div>
            `;
        }
    }

    copyToClipboard(text) {
        if (navigator && navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).then(() => {
                this.showToast(`Copied: ${text}`, "info");
            }).catch(() => {
                this.showToast(`Copy failed`, "error");
            });
        } else {
            const input = document.createElement('input');
            input.value = text;
            document.body.appendChild(input);
            input.select();
            document.execCommand('copy');
            document.body.removeChild(input);
            this.showToast(`Copied: ${text}`, "info");
        }
    }


    /* -- Live Delivery Tracking Section ------------------------------------ */

    clearDeliveryTrackingTimer() {
        if (this.deliveryTrackingTimer) {
            clearInterval(this.deliveryTrackingTimer);
            this.deliveryTrackingTimer = null;
        }
    }

    toggleDeliveryTrackingAutoRefresh(enable) {
        if (enable) {
            this.startDeliveryTrackingAutoRefresh();
            this.showToast('Live 10-second auto-refresh enabled.', 'info');
        } else {
            this.clearDeliveryTrackingTimer();
            this.showToast('Auto-refresh paused.', 'info');
        }
    }

    startDeliveryTrackingAutoRefresh() {
        this.clearDeliveryTrackingTimer();
        this.deliveryTrackingTimer = setInterval(() => {
            if (this.currentPath && this.currentPath.includes('/delivery-tracking')) {
                this.fetchDeliveryTrackingData(true);
            } else {
                this.clearDeliveryTrackingTimer();
            }
        }, 10000);
    }

    async setDeliveryTrackingFilter(status) {
        this.deliveryTrackingQuery.status = status;
        const container = document.getElementById('content-view');
        if (container) {
            await this.loadDeliveryTrackingView(container);
        }
    }

    async loadDeliveryTrackingView(container) {
        this.clearDeliveryTrackingTimer();

        container.innerHTML = `
            <div class="delivery-tracking-wrapper">
                <!-- Filter & Search Toolbar -->
                <div class="card" style="padding: 16px; margin-bottom: 20px; border-radius: 16px; border: 1px solid var(--border-color);">
                    <div style="display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between; gap: 14px;">
                        <!-- Status Tabs -->
                        <div style="display: flex; gap: 8px; flex-wrap: wrap;">
                            <button class="btn ${this.deliveryTrackingQuery.status === 'active' ? 'btn-primary' : 'btn-secondary'}" onclick="app.setDeliveryTrackingFilter('active')">
                                <i class="fa-solid fa-bolt"></i> Active Orders
                            </button>
                            <button class="btn ${this.deliveryTrackingQuery.status === 'out_for_delivery' ? 'btn-primary' : 'btn-secondary'}" onclick="app.setDeliveryTrackingFilter('out_for_delivery')">
                                <i class="fa-solid fa-motorcycle"></i> Out for Delivery
                            </button>
                            <button class="btn ${this.deliveryTrackingQuery.status === 'all' ? 'btn-primary' : 'btn-secondary'}" onclick="app.setDeliveryTrackingFilter('all')">
                                <i class="fa-solid fa-list"></i> All Orders
                            </button>
                            <button class="btn ${this.deliveryTrackingQuery.status === 'completed' ? 'btn-primary' : 'btn-secondary'}" onclick="app.setDeliveryTrackingFilter('completed')">
                                <i class="fa-solid fa-circle-check"></i> Completed
                            </button>
                        </div>

                        <!-- Search & Live Controls -->
                        <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                            <div class="search-box" style="width: 280px; margin: 0;">
                                <i class="fa-solid fa-magnifying-glass search-icon"></i>
                                <input type="text" id="dt-search-input" class="form-control search-input" placeholder="Search Order #, Mess, Driver..." value="${this.escapeHtml(this.deliveryTrackingQuery.search)}">
                            </div>
                            <button class="btn btn-secondary btn-icon" title="Refresh Now" onclick="app.fetchDeliveryTrackingData()">
                                <i class="fa-solid fa-rotate-right"></i>
                            </button>
                            <label style="display: flex; align-items: center; gap: 6px; font-size: 13px; font-weight: 600; cursor: pointer; user-select: none; padding: 6px 12px; background: var(--bg-surface); border-radius: 8px;">
                                <input type="checkbox" id="dt-auto-refresh-check" checked onchange="app.toggleDeliveryTrackingAutoRefresh(this.checked)">
                                <span>Live 10s</span>
                            </label>
                        </div>
                    </div>
                </div>

                <!-- Vertical Orders List Container -->
                <div id="dt-orders-container" style="display: flex; flex-direction: column; gap: 16px;">
                    <div class="text-center text-muted" style="padding: 50px; background: white; border-radius: 16px; border: 1px solid var(--border-color);">
                        <i class="fa-solid fa-spinner fa-spin" style="font-size: 28px; color: var(--accent-primary);"></i>
                        <p style="margin-top: 10px; font-weight: 600;">Loading live delivery tracking list...</p>
                    </div>
                </div>
            </div>
        `;

        // Bind Search Input
        const searchInput = document.getElementById('dt-search-input');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                clearTimeout(this.debouncedSearchTimeout);
                this.debouncedSearchTimeout = setTimeout(() => {
                    this.deliveryTrackingQuery.search = e.target.value.trim();
                    this.fetchDeliveryTrackingData();
                }, 400);
            });
        }

        // Fetch Initial Data
        await this.fetchDeliveryTrackingData();

        // Start 10-second auto-refresh timer
        this.startDeliveryTrackingAutoRefresh();
    }

    async fetchDeliveryTrackingData(isSilent = false) {
        const container = document.getElementById('dt-orders-container');
        if (!container && !isSilent) return;

        try {
            const queryParams = new URLSearchParams({
                search: this.deliveryTrackingQuery.search,
                status: this.deliveryTrackingQuery.status,
                page: this.deliveryTrackingQuery.page,
                limit: 50
            });

            const res = await api.request(`/admin/delivery_tracking/list.php?${queryParams.toString()}`);
            if (res && res.success && res.data) {
                const orders = res.data.orders || [];
                this.currentDeliveryOrders = orders;
                this.renderDeliveryTrackingOrderCards(orders);
                this.updateDeliveryTrackingStats(orders);

                // If live tracking modal is currently open, refresh its map & driver location silently
                if (this.activeTrackedOrder) {
                    const updatedActiveOrder = orders.find(x => x.order_id === this.activeTrackedOrder.order_id);
                    if (updatedActiveOrder) {
                        this.activeTrackedOrder = updatedActiveOrder;
                        this.renderOrderRoadTrackingMap(updatedActiveOrder);
                    }
                }
            } else {
                if (container) {
                    container.innerHTML = `
                        <div class="text-center text-muted" style="grid-column: 1 / -1; padding: 40px; background: white; border-radius: 16px;">
                            <p style="margin: 0; font-weight: 600;">No active delivery orders found.</p>
                        </div>
                    `;
                }
            }
        } catch (err) {
            console.error('Error fetching live delivery tracking data:', err);
            if (container && !isSilent) {
                container.innerHTML = `
                    <div class="text-center text-danger" style="grid-column: 1 / -1; padding: 40px; background: white; border-radius: 16px;">
                        <p style="margin: 0;">Failed to fetch live orders: ${this.escapeHtml(err.message)}</p>
                    </div>
                `;
            }
        }
    }

    updateDeliveryTrackingStats(orders) {
        let activeCount = 0;
        let ofdCount = 0;
        let driversCount = 0;
        let pendingCount = 0;

        const driverIds = new Set();

        orders.forEach(o => {
            const st = (o.status || '').toLowerCase();
            if (st === 'created_order' || st === 'accepted' || st === 'preparing' || st === 'ready' || st === 'assigned' || st === 'accepted_by_driver' || st === 'picked_up' || st === 'arrived_at_customer') {
                activeCount++;
            }
            if (st === 'picked_up' || st === 'arrived_at_customer') {
                ofdCount++;
            }
            if (st === 'created_order' || st === 'accepted' || st === 'preparing') {
                pendingCount++;
            }
            if (o.driver && o.driver.id > 0) {
                driverIds.add(o.driver.id);
            }
        });
        driversCount = driverIds.size;

        const elActive = document.getElementById('dt-stat-active');
        const elOfd = document.getElementById('dt-stat-ofd');
        const elDrivers = document.getElementById('dt-stat-drivers');
        const elPending = document.getElementById('dt-stat-pending');

        if (elActive) elActive.textContent = activeCount;
        if (elOfd) elOfd.textContent = ofdCount;
        if (elDrivers) elDrivers.textContent = driversCount;
        if (elPending) elPending.textContent = pendingCount;
    }

    renderDeliveryTrackingOrderCards(orders) {
        const container = document.getElementById('dt-orders-container');
        if (!container) return;

        if (!orders || orders.length === 0) {
            container.innerHTML = `
                <div class="text-center text-muted" style="padding: 50px; background: white; border-radius: 16px; border: 1px solid var(--border-color);">
                    <i class="fa-solid fa-box-open" style="font-size: 36px; color: #CBD5E1; margin-bottom: 12px;"></i>
                    <h4 style="margin: 0; color: #334155;">No Orders Found</h4>
                    <p style="font-size: 13px; color: #64748B; margin-top: 4px;">No delivery orders matching current filters.</p>
                </div>
            `;
            return;
        }

        container.innerHTML = orders.map(o => {
            const statusFormatted = (o.status || '').replace(/_/g, ' ').toUpperCase();
            
            let statusBadgeClass = 'badge-secondary';
            if (o.status === 'picked_up' || o.status === 'arrived_at_customer') statusBadgeClass = 'badge-info';
            else if (o.status === 'completed') statusBadgeClass = 'badge-success';
            else if (o.status === 'preparing' || o.status === 'ready' || o.status === 'accepted') statusBadgeClass = 'badge-warning';
            else if (o.status.includes('rejected') || o.status === 'cancelled') statusBadgeClass = 'badge-danger';

            const formattedTime = new Date(o.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            const itemsText = (o.items || []).map(i => `${i.quantity}x ${i.food_name}`).join(', ');

            return `
                <div class="card order-tracking-item" style="padding: 20px; border-radius: 16px; border: 1px solid var(--border-color); background: white; box-shadow: 0 4px 12px rgba(0,0,0,0.02); transition: transform 0.2s ease;">
                    <!-- Top Header Row -->
                    <div style="display: flex; justify-content: space-between; align-items: center; padding-bottom: 12px; border-bottom: 1px solid #F1F5F9; margin-bottom: 14px;">
                        <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                            <span style="font-weight: 800; font-size: 16px; color: #0F172A;">Order #${o.order_id}</span>
                            <span class="badge badge-secondary" style="font-size: 11px; font-weight: 700;">${o.meal_type}</span>
                            <span style="font-size: 12px; color: #64748B;"><i class="fa-regular fa-clock" style="margin-right: 4px;"></i>${formattedTime}</span>
                        </div>
                        <span class="badge ${statusBadgeClass}" style="font-size: 12px; font-weight: 800; padding: 6px 12px; letter-spacing: 0.3px;">${statusFormatted}</span>
                    </div>

                    <!-- Main Content Grid -->
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(210px, 1fr)); gap: 16px; align-items: start;">
                        <!-- Mess & Vendor -->
                        <div style="display: flex; align-items: flex-start; gap: 10px;">
                            <div style="width: 34px; height: 34px; border-radius: 10px; background: rgba(239, 68, 68, 0.1); color: #EF4444; display: flex; align-items: center; justify-content: center; font-size: 14px; flex-shrink: 0;">
                                <i class="fa-solid fa-store"></i>
                            </div>
                            <div style="flex: 1;">
                                <span style="font-size: 11px; font-weight: 700; color: #94A3B8; text-transform: uppercase; letter-spacing: 0.5px;">Mess (Hotel) & Vendor</span>
                                <strong style="color: #0F172A; font-size: 14.5px; display: block; margin-top: 1px;">${this.escapeHtml(o.mess.name)}</strong>
                                <div style="margin-top: 4px; padding: 4px 8px; background: #F8FAFC; border-radius: 6px; border: 1px solid #E2E8F0; font-size: 12px; color: #334155;">
                                    <i class="fa-solid fa-user-tie" style="color: #475569; margin-right: 4px;"></i> <strong>Vendor:</strong> ${this.escapeHtml(o.vendor.name)}
                                    ${o.vendor.phone ? `<span style="font-size: 11px; color: #64748B; display: block; margin-top: 2px;"><i class="fa-solid fa-phone" style="font-size: 10px;"></i> ${this.escapeHtml(o.vendor.phone)}</span>` : ''}
                                </div>
                            </div>
                        </div>

                        <!-- Customer & Address -->
                        <div style="display: flex; align-items: flex-start; gap: 10px;">
                            <div style="width: 34px; height: 34px; border-radius: 10px; background: rgba(16, 185, 129, 0.1); color: #10B981; display: flex; align-items: center; justify-content: center; font-size: 14px; flex-shrink: 0;">
                                <i class="fa-solid fa-location-dot"></i>
                            </div>
                            <div>
                                <span style="font-size: 11px; font-weight: 700; color: #94A3B8; text-transform: uppercase;">Customer & Address</span>
                                <strong style="color: #0F172A; font-size: 14px; display: block; margin-top: 1px;">${this.escapeHtml(o.customer.name)}</strong>
                                <span style="font-size: 12px; color: #64748B; display: block; line-height: 1.3;">${this.escapeHtml(o.delivery_address)}</span>
                                ${o.customer.phone ? `<a href="tel:${o.customer.phone}" style="font-size: 11.5px; color: #2563EB; font-weight: 700; text-decoration: none; display: inline-block; margin-top: 2px;"><i class="fa-solid fa-phone"></i> ${this.escapeHtml(o.customer.phone)}</a>` : ''}
                            </div>
                        </div>

                        <!-- Driver Info -->
                        <div style="display: flex; align-items: flex-start; gap: 10px;">
                            <div style="width: 34px; height: 34px; border-radius: 10px; background: rgba(37, 99, 235, 0.1); color: #2563EB; display: flex; align-items: center; justify-content: center; font-size: 14px; flex-shrink: 0;">
                                <i class="fa-solid fa-motorcycle"></i>
                            </div>
                            <div>
                                <span style="font-size: 11px; font-weight: 700; color: #94A3B8; text-transform: uppercase;">Assigned Driver</span>
                                ${o.driver && o.driver.id > 0 ? `
                                    <strong style="color: #0F172A; font-size: 14px; display: block; margin-top: 1px;">${this.escapeHtml(o.driver.name)}</strong>
                                    <span style="font-size: 12px; color: #64748B; display: block;">Vehicle: ${this.escapeHtml(o.driver.vehicle_number || 'N/A')}</span>
                                    ${o.driver.phone ? `<a href="tel:${o.driver.phone}" style="font-size: 11.5px; color: #059669; font-weight: 700; text-decoration: none; display: inline-block; margin-top: 2px;"><i class="fa-solid fa-phone"></i> Call Driver</a>` : ''}
                                ` : `
                                    <span style="color: #94A3B8; font-style: italic; font-size: 13px; display: block; margin-top: 2px;">No Driver Assigned</span>
                                `}
                            </div>
                        </div>

                        <!-- Track Button -->
                        <div style="display: flex; flex-direction: column; align-items: flex-end; justify-content: center; gap: 8px;">
                            <button class="btn btn-primary" onclick="app.openOrderTrackingModal(${o.order_id})" style="font-weight: 700; padding: 9px 18px; border-radius: 10px; display: inline-flex; align-items: center; gap: 8px; background: linear-gradient(135deg, #2563EB, #1D4ED8); border: none; box-shadow: 0 4px 12px rgba(37, 99, 235, 0.25);">
                                <i class="fa-solid fa-route"></i> Track Live
                            </button>
                        </div>
                    </div>

                    <!-- Items Summary Footer -->
                    ${itemsText ? `
                        <div style="margin-top: 14px; padding-top: 10px; border-top: 1px dashed #E2E8F0; font-size: 12px; color: #475569; display: flex; align-items: center; gap: 6px;">
                            <i class="fa-solid fa-utensils" style="color: #94A3B8;"></i> <strong>Items:</strong> ${this.escapeHtml(itemsText)}
                        </div>
                    ` : ''}
                </div>
            `;
        }).join('');
    }

    openOrderTrackingModal(orderId) {
        const order = (this.currentDeliveryOrders || []).find(o => o.order_id === orderId);
        if (!order) {
            this.showToast('Order details not found.', 'error');
            return;
        }

        this.activeTrackedOrder = order;

        // Set modal titles & header values
        const titleEl = document.getElementById('dt-modal-title');
        const messNameEl = document.getElementById('dt-modal-mess-name');
        const driverNameEl = document.getElementById('dt-modal-driver-name');
        const custNameEl = document.getElementById('dt-modal-customer-name');
        const statusBadgeEl = document.getElementById('dt-modal-status-badge');
        const etaBadgeEl = document.getElementById('dt-modal-eta-badge');

        if (titleEl) titleEl.textContent = `Live Order Tracking #${order.order_id}`;
        if (messNameEl) messNameEl.textContent = order.mess.name;
        if (driverNameEl) driverNameEl.textContent = order.driver && order.driver.id > 0 ? order.driver.name : 'Unassigned';
        if (custNameEl) custNameEl.textContent = order.customer.name;

        if (statusBadgeEl) {
            statusBadgeEl.textContent = (order.status || '').replace(/_/g, ' ').toUpperCase();
        }
        if (etaBadgeEl) {
            etaBadgeEl.innerHTML = '<i class="fa-solid fa-spinner fa-spin" style="margin-right: 4px;"></i> Calculating route...';
        }

        // Render Status Progress Stepper Bar
        this.renderOrderStepper(order.status);

        this.openModal('dt-live-modal');

        // Render actual road polyline map
        setTimeout(() => {
            this.renderOrderRoadTrackingMap(order);
        }, 150);
    }

    closeDeliveryTrackingModal() {
        this.activeTrackedOrder = null;
        this.driverMarker = null;
        this.closeModal('dt-live-modal');
    }

    renderOrderRoadTrackingMap(order) {
        const mapContainer = document.getElementById('dt-modal-map');
        if (!mapContainer || typeof google === 'undefined' || !google.maps) return;

        const defaultLat = 18.5204;
        const defaultLng = 73.8567;

        if (!this.deliveryTrackingModalMap) {
            this.deliveryTrackingModalMap = new google.maps.Map(mapContainer, {
                center: { lat: defaultLat, lng: defaultLng },
                zoom: 13,
                mapTypeControl: false,
                streetViewControl: false,
                fullscreenControl: true,
            });
        }

        const map = this.deliveryTrackingModalMap;

        // Clear existing markers
        if (this.deliveryTrackingMarkers) {
            this.deliveryTrackingMarkers.forEach(m => m.setMap(null));
        }
        this.deliveryTrackingMarkers = [];
        this.driverMarker = null;

        // Clear existing polyline & directions
        if (this.deliveryTrackingPolyline) {
            this.deliveryTrackingPolyline.setMap(null);
            this.deliveryTrackingPolyline = null;
        }
        if (this.deliveryTrackingDirectionsRenderer) {
            this.deliveryTrackingDirectionsRenderer.setMap(null);
            this.deliveryTrackingDirectionsRenderer = null;
        }

        const bounds = new google.maps.LatLngBounds();
        let hasMess = false;
        let hasCustomer = false;
        let hasDriver = false;

        let messPos = null;
        let custPos = null;
        let driverPos = null;

        // 1. Mess Pin (Red)
        if (order.mess && order.mess.lat && order.mess.lng && parseFloat(order.mess.lat) !== 0) {
            messPos = { lat: parseFloat(order.mess.lat), lng: parseFloat(order.mess.lng) };
            hasMess = true;
            bounds.extend(messPos);

            const messMarker = new google.maps.Marker({
                position: messPos,
                map: map,
                title: `Mess: ${order.mess.name}`,
                icon: {
                    path: google.maps.SymbolPath.CIRCLE,
                    scale: 10,
                    fillColor: '#EF4444',
                    fillOpacity: 1,
                    strokeWeight: 3,
                    strokeColor: '#FFFFFF',
                }
            });

            const messInfo = new google.maps.InfoWindow({
                content: `<div style="padding: 6px; font-family: Inter, sans-serif;">
                    <strong style="color: #EF4444;"><i class="fa-solid fa-store" style="margin-right: 4px;"></i> Mess Pickup: ${this.escapeHtml(order.mess.name)}</strong><br>
                    <span style="font-size: 11px; color: #475569;">Vendor: ${this.escapeHtml(order.vendor.name)}</span>
                </div>`
            });
            messMarker.addListener('click', () => messInfo.open(map, messMarker));
            this.deliveryTrackingMarkers.push(messMarker);
        }

        // 2. Customer Pin (Green)
        if (order.customer && order.customer.lat && order.customer.lng && parseFloat(order.customer.lat) !== 0) {
            custPos = { lat: parseFloat(order.customer.lat), lng: parseFloat(order.customer.lng) };
            hasCustomer = true;
            bounds.extend(custPos);

            const custMarker = new google.maps.Marker({
                position: custPos,
                map: map,
                title: `Customer: ${order.customer.name}`,
                icon: {
                    path: google.maps.SymbolPath.CIRCLE,
                    scale: 10,
                    fillColor: '#10B981',
                    fillOpacity: 1,
                    strokeWeight: 3,
                    strokeColor: '#FFFFFF',
                }
            });

            const custInfo = new google.maps.InfoWindow({
                content: `<div style="padding: 6px; font-family: Inter, sans-serif;">
                    <strong style="color: #10B981;"><i class="fa-solid fa-user" style="margin-right: 4px;"></i> Customer: ${this.escapeHtml(order.customer.name)}</strong><br>
                    <span style="font-size: 11px; color: #475569;">${this.escapeHtml(order.delivery_address)}</span>
                </div>`
            });
            custMarker.addListener('click', () => custInfo.open(map, custMarker));
            this.deliveryTrackingMarkers.push(custMarker);
        }

        // 3. Driver Pin (Blue)
        if (order.driver && order.driver.lat && order.driver.lng && parseFloat(order.driver.lat) !== 0) {
            driverPos = { lat: parseFloat(order.driver.lat), lng: parseFloat(order.driver.lng) };
            hasDriver = true;
            bounds.extend(driverPos);

            const driverMarker = new google.maps.Marker({
                position: driverPos,
                map: map,
                title: `Driver: ${order.driver.name}`,
                icon: {
                    path: google.maps.SymbolPath.FORWARD_CLOSED_ARROW,
                    scale: 8,
                    fillColor: '#2563EB',
                    fillOpacity: 1,
                    strokeWeight: 2,
                    strokeColor: '#FFFFFF',
                }
            });

            const driverInfo = new google.maps.InfoWindow({
                content: `<div style="padding: 6px; font-family: Inter, sans-serif;">
                    <strong style="color: #2563EB;"><i class="fa-solid fa-motorcycle" style="margin-right: 4px;"></i> Driver: ${this.escapeHtml(order.driver.name)}</strong><br>
                    <span style="font-size: 11px; color: #475569;">Vehicle: ${this.escapeHtml(order.driver.vehicle_number || '')} • ${order.driver.phone || ''}</span>
                </div>`
            });
            driverMarker.addListener('click', () => driverInfo.open(map, driverMarker));
            this.deliveryTrackingMarkers.push(driverMarker);
            this.driverMarker = driverMarker;
        }

        // INSTANT FOCUS: Fit map to available markers immediately (0ms)
        if (hasMess || hasCustomer || hasDriver) {
            map.fitBounds(bounds);
            google.maps.event.trigger(map, 'resize');
        }

        // INSTANT POLYLINE & DISTANCE (0ms)
        const pathCoords = [];
        if (hasMess) pathCoords.push(messPos);
        if (hasDriver) pathCoords.push(driverPos);
        if (hasCustomer) pathCoords.push(custPos);

        if (pathCoords.length >= 2) {
            // Draw instant line immediately
            this.deliveryTrackingPolyline = new google.maps.Polyline({
                path: pathCoords,
                geodesic: true,
                strokeColor: '#2563EB',
                strokeOpacity: 0.85,
                strokeWeight: 5,
                map: map
            });

            // Instant Haversine Distance calculation
            let totalKm = 0;
            for (let i = 0; i < pathCoords.length - 1; i++) {
                const p1 = pathCoords[i];
                const p2 = pathCoords[i+1];
                const R = 6371;
                const dLat = (p2.lat - p1.lat) * Math.PI / 180;
                const dLon = (p2.lng - p1.lng) * Math.PI / 180;
                const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                          Math.cos(p1.lat * Math.PI / 180) * Math.cos(p2.lat * Math.PI / 180) *
                          Math.sin(dLon/2) * Math.sin(dLon/2);
                const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
                totalKm += R * c;
            }

            const estMinutes = Math.ceil(totalKm * 3.5); // ~3.5 mins per km driving estimate
            const etaBadgeEl = document.getElementById('dt-modal-eta-badge');
            if (etaBadgeEl) {
                etaBadgeEl.innerHTML = `<i class="fa-solid fa-route"></i> ${totalKm.toFixed(1)} km • ~${estMinutes} mins ETA`;
            }

            // Asynchronous Google Directions API road snap
            if (hasMess && hasCustomer) {
                const directionsService = new google.maps.DirectionsService();
                const waypoints = hasDriver ? [{ location: driverPos, stopover: true }] : [];

                directionsService.route({
                    origin: messPos,
                    destination: custPos,
                    waypoints: waypoints,
                    travelMode: google.maps.TravelMode.DRIVING,
                }, (result, status) => {
                    if (status === google.maps.DirectionsStatus.OK) {
                        // Remove initial straight polyline and render precise street directions
                        if (this.deliveryTrackingPolyline) {
                            this.deliveryTrackingPolyline.setMap(null);
                        }

                        const directionsRenderer = new google.maps.DirectionsRenderer({
                            map: map,
                            suppressMarkers: true,
                            polylineOptions: {
                                strokeColor: '#2563EB',
                                strokeOpacity: 0.9,
                                strokeWeight: 6,
                            }
                        });
                        this.deliveryTrackingDirectionsRenderer = directionsRenderer;
                        directionsRenderer.setDirections(result);

                        let roadDistanceMeters = 0;
                        let roadDurationSeconds = 0;
                        result.routes[0].legs.forEach(leg => {
                            roadDistanceMeters += leg.distance.value;
                            roadDurationSeconds += leg.duration.value;
                        });

                        const roadKm = (roadDistanceMeters / 1000).toFixed(1);
                        const roadMins = Math.ceil(roadDurationSeconds / 60);

                        if (etaBadgeEl) {
                            etaBadgeEl.innerHTML = `<i class="fa-solid fa-car"></i> ${roadKm} km • ~${roadMins} mins ETA`;
                        }
                    }
                });
            }
        }
    }

    initAblyRealtime() {
        if (typeof Ably === 'undefined') {
            console.warn('Ably Realtime SDK not loaded');
            return;
        }

        try {
            const apiKey = 'oSsZ2A.MVAVyA:EhxvHAEsSfx49DDHPqZ9_u3d7LzUETbyXpQl0sjW1Nk';
            this.ablyClient = new Ably.Realtime({ key: apiKey, clientId: 'admin-panel-' + Math.floor(Math.random() * 10000) });

            const channels = ['dev_global_events', 'global_events', 'prod_global_events'];
            channels.forEach(chName => {
                const ch = this.ablyClient.channels.get(chName);
                ch.subscribe(msg => {
                    if (msg.name === 'DRIVER_LOCATION_UPDATED') {
                        this.handleRealtimeDriverLocation(msg.data);
                    } else if (msg.name === 'ORDER_STATUS_UPDATED' || msg.name === 'ORDER_ASSIGNED' || msg.name === 'order_assigned' || msg.name === 'order_updated') {
                        this.handleRealtimeOrderStatus(msg.data);
                    }
                });
            });

            console.log('Admin Ably Realtime subscriber initialized.');
        } catch (err) {
            console.error('Ably Realtime init error:', err);
        }
    }

    handleRealtimeDriverLocation(data) {
        if (!data) return;
        const driverId = data.driver_id ? parseInt(data.driver_id) : null;
        const orderId = data.order_id ? parseInt(data.order_id) : null;
        const lat = parseFloat(data.latitude || data.lat);
        const lng = parseFloat(data.longitude || data.lng);

        if (isNaN(lat) || isNaN(lng) || lat === 0) return;

        // 1. Update in local currentDeliveryOrders
        if (this.currentDeliveryOrders) {
            this.currentDeliveryOrders.forEach(o => {
                if ((orderId && o.order_id === orderId) || (driverId && o.driver && parseInt(o.driver.id) === driverId)) {
                    if (!o.driver) o.driver = {};
                    o.driver.lat = lat;
                    o.driver.lng = lng;
                    if (data.driver_name) o.driver.name = data.driver_name;
                    if (data.driver_phone) o.driver.phone = data.driver_phone;
                    if (data.vehicle_number) o.driver.vehicle_number = data.vehicle_number;
                }
            });
        }

        // 2. If live tracking modal is currently open for this order or driver, update map marker seamlessly
        if (this.activeTrackedOrder) {
            const isActiveOrder = (orderId && this.activeTrackedOrder.order_id === orderId) ||
                                  (driverId && this.activeTrackedOrder.driver && parseInt(this.activeTrackedOrder.driver.id) === driverId);

            if (isActiveOrder) {
                if (!this.activeTrackedOrder.driver) this.activeTrackedOrder.driver = {};
                this.activeTrackedOrder.driver.lat = lat;
                this.activeTrackedOrder.driver.lng = lng;

                if (typeof google !== 'undefined' && google.maps) {
                    const newPos = new google.maps.LatLng(lat, lng);

                    if (this.driverMarker) {
                        this.driverMarker.setPosition(newPos);
                    } else if (this.deliveryTrackingMarkers) {
                        const dMarker = this.deliveryTrackingMarkers.find(m => m.getTitle() && m.getTitle().toLowerCase().includes('driver'));
                        if (dMarker) {
                            dMarker.setPosition(newPos);
                            this.driverMarker = dMarker;
                        }
                    }
                }

                // Update live ETA badge
                const etaBadgeEl = document.getElementById('dt-modal-eta-badge');
                if (etaBadgeEl) {
                    const distKm = data.distance ? (parseFloat(data.distance) / 1000).toFixed(1) : null;
                    const etaMins = data.eta ? Math.max(1, parseInt(data.eta)) : null;

                    if (distKm && etaMins) {
                        etaBadgeEl.innerHTML = `<i class="fa-solid fa-motorcycle" style="color: #60A5FA;"></i> Live Driver: ${distKm} km • ~${etaMins} mins ETA`;
                    }
                }
            }
        }
    }

    handleRealtimeOrderStatus(data) {
        if (!data || !data.order_id) return;
        const orderId = parseInt(data.order_id);
        const newStatus = data.status || data.order_status;

        if (this.currentDeliveryOrders) {
            const targetOrder = this.currentDeliveryOrders.find(o => o.order_id === orderId);
            if (targetOrder) {
                if (newStatus) targetOrder.status = newStatus;
                if (data.driver) targetOrder.driver = data.driver;
            }
            this.renderDeliveryTrackingOrderCards(this.currentDeliveryOrders);
            this.updateDeliveryTrackingStats(this.currentDeliveryOrders);
        }

        if (this.activeTrackedOrder && this.activeTrackedOrder.order_id === orderId) {
            if (newStatus) {
                this.activeTrackedOrder.status = newStatus;
                const statusBadgeEl = document.getElementById('dt-modal-status-badge');
                if (statusBadgeEl) {
                    statusBadgeEl.textContent = newStatus.replace(/_/g, ' ').toUpperCase();
                }
                this.renderOrderStepper(newStatus);
            }
        }
    }

    renderOrderStepper(status) {
        const container = document.getElementById('dt-modal-stepper-container');
        if (!container) return;

        const steps = [
            { key: 'created_order', label: 'Placed', icon: 'fa-receipt' },
            { key: 'accepted', label: 'Accepted', icon: 'fa-thumbs-up' },
            { key: 'preparing', label: 'Preparing', icon: 'fa-utensils' },
            { key: 'ready', label: 'Ready', icon: 'fa-box-archive' },
            { key: 'assigned', label: 'Driver Assigned', icon: 'fa-user-ninja' },
            { key: 'picked_up', label: 'Out for Delivery', icon: 'fa-motorcycle' },
            { key: 'completed', label: 'Delivered', icon: 'fa-circle-check' }
        ];

        const statusMap = {
            'created_order': 1,
            'accepted': 2,
            'preparing': 3,
            'ready': 4,
            'assigned': 5,
            'accepted_by_driver': 5,
            'picked_up': 6,
            'arrived_at_customer': 6,
            'completed': 7,
            'cancelled': -1,
            'rejected': -1,
            'rejected_by_driver': -1
        };

        const currentIdx = statusMap[(status || '').toLowerCase()] || 1;
        const isCancelled = currentIdx === -1;

        if (isCancelled) {
            container.innerHTML = `
                <div style="display: flex; align-items: center; justify-content: center; gap: 10px; color: #EF4444; padding: 6px 0; font-weight: 700; font-size: 14px;">
                    <i class="fa-solid fa-circle-xmark" style="font-size: 20px;"></i>
                    <span>This order was ${this.escapeHtml((status || 'CANCELLED').replace(/_/g, ' ').toUpperCase())}</span>
                </div>
            `;
            return;
        }

        const html = `
            <div style="display: flex; align-items: center; justify-content: space-between; min-width: 680px; position: relative; padding: 4px 10px;">
                ${steps.map((s, idx) => {
                    const stepNum = idx + 1;
                    const isPassed = currentIdx > stepNum;
                    const isActive = currentIdx === stepNum;

                    let nodeBg = '#1E293B';
                    let nodeColor = '#64748B';
                    let nodeBorder = '2px solid #334155';
                    let labelColor = '#64748B';

                    if (isPassed) {
                        nodeBg = '#10B981';
                        nodeColor = '#FFFFFF';
                        nodeBorder = '2px solid #10B981';
                        labelColor = '#34D399';
                    } else if (isActive) {
                        nodeBg = '#2563EB';
                        nodeColor = '#FFFFFF';
                        nodeBorder = '2px solid #60A5FA';
                        labelColor = '#60A5FA';
                    }

                    const isLast = idx === steps.length - 1;

                    return `
                        <div style="display: flex; flex-direction: column; align-items: center; flex: 1; position: relative; z-index: 2;">
                            <div style="width: 34px; height: 34px; border-radius: 50%; background: ${nodeBg}; color: ${nodeColor}; border: ${nodeBorder}; display: flex; align-items: center; justify-content: center; font-size: 13px; font-weight: 700; transition: all 0.3s ease; box-shadow: ${isActive ? '0 0 12px rgba(37, 99, 235, 0.6)' : 'none'};">
                                ${isPassed ? '<i class="fa-solid fa-check"></i>' : `<i class="fa-solid ${s.icon}"></i>`}
                            </div>
                            <span style="font-size: 11px; font-weight: ${isActive ? '800' : '600'}; color: ${labelColor}; margin-top: 6px; text-align: center; white-space: nowrap;">
                                ${s.label}
                            </span>
                        </div>
                        ${!isLast ? `
                            <div style="flex: 1; height: 3px; background: ${currentIdx > stepNum ? '#10B981' : '#334155'}; margin: 0 -10px 18px -10px; z-index: 1; transition: background 0.3s ease;"></div>
                        ` : ''}
                    `;
                }).join('')}
            </div>
        `;

        container.innerHTML = html;
    }

    /* -- Website Customer Enquiries Management ------------------------------ */

    async loadEnquiriesView(container) {
        if (!this.enquiriesQuery) {
            this.enquiriesQuery = {
                search: '',
                status: 'all',
                state: 'all',
                district: 'all',
                taluka: 'all',
                area: 'all',
                date_filter: 'all',
                start_date: '',
                end_date: '',
                page: 1,
                limit: 15
            };
        }

        container.innerHTML = `
            <div class="view-header" style="margin-bottom: 20px;">
                <div>
                    <h2 style="margin: 0; font-size: 1.5rem; font-weight: 800; color: var(--text-color, #1e293b); display: flex; align-items: center; gap: 10px;">
                        <i class="fa-solid fa-headset text-primary"></i>
                        Website Customer Enquiries
                    </h2>
                    <p style="margin: 4px 0 0 0; font-size: 0.85rem; color: var(--text-muted, #64748b);">
                        Manage, filter, and respond to incoming tiffin & meal customer inquiries from the website
                    </p>
                </div>
                <div class="view-actions" style="display: flex; gap: 10px; align-items: center;">
                    <button class="btn btn-secondary btn-sm" onclick="app.refreshEnquiries()" style="display: flex; align-items: center; gap: 6px;">
                        <i class="fa-solid fa-arrows-rotate"></i> Refresh
                    </button>
                    <button class="btn btn-primary btn-sm" onclick="app.exportEnquiriesCSV()" style="display: flex; align-items: center; gap: 6px;">
                        <i class="fa-solid fa-file-csv"></i> Export CSV
                    </button>
                </div>
            </div>

            <!-- Summary KPI Stat Cards -->
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(210px, 1fr)); gap: 16px; margin-bottom: 20px;">
                <div class="stat-card" style="padding: 16px; border-left: 4px solid #3b82f6;">
                    <div class="stat-info">
                        <span class="stat-label">Total Enquiries</span>
                        <span class="stat-value" id="enq-stat-total" style="color: #3b82f6; font-size: 22px;">0</span>
                    </div>
                    <div class="stat-icon" style="background: rgba(59, 130, 246, 0.15); color: #3b82f6;"><i class="fa-solid fa-clipboard-list"></i></div>
                </div>
                <div class="stat-card" style="padding: 16px; border-left: 4px solid #f59e0b;">
                    <div class="stat-info">
                        <span class="stat-label">New / Pending</span>
                        <span class="stat-value" id="enq-stat-new" style="color: #f59e0b; font-size: 22px;">0</span>
                    </div>
                    <div class="stat-icon" style="background: rgba(245, 158, 11, 0.15); color: #f59e0b;"><i class="fa-solid fa-bell"></i></div>
                </div>
                <div class="stat-card" style="padding: 16px; border-left: 4px solid #8b5cf6;">
                    <div class="stat-info">
                        <span class="stat-label">Contacted / Followed Up</span>
                        <span class="stat-value" id="enq-stat-contacted" style="color: #8b5cf6; font-size: 22px;">0</span>
                    </div>
                    <div class="stat-icon" style="background: rgba(139, 92, 246, 0.15); color: #8b5cf6;"><i class="fa-solid fa-phone-volume"></i></div>
                </div>
                <div class="stat-card" style="padding: 16px; border-left: 4px solid #10b981;">
                    <div class="stat-info">
                        <span class="stat-label">Today's Inquiries</span>
                        <span class="stat-value" id="enq-stat-today" style="color: #10b981; font-size: 22px;">0</span>
                    </div>
                    <div class="stat-icon" style="background: rgba(16, 185, 129, 0.15); color: #10b981;"><i class="fa-solid fa-calendar-day"></i></div>
                </div>
            </div>

            <!-- Filter Controls Panel -->
            <div class="filter-bar" style="display: flex; flex-direction: column; gap: 12px; background: var(--bg-card, #ffffff); padding: 16px 20px; border-radius: var(--radius-md, 12px); border: 1px solid var(--border-color, #e2e8f0); margin-bottom: 16px;">
                <!-- Row 1: Search and Location Filters (State, District, Taluka, Area) -->
                <div style="display: flex; flex-wrap: wrap; gap: 10px; align-items: center;">
                    <div class="search-input-wrapper" style="flex: 1; min-width: 220px;">
                        <i class="fa-solid fa-magnifying-glass search-icon"></i>
                        <input type="text" id="enq-search" class="search-input" placeholder="Search customer name, phone, area..." value="${this.enquiriesQuery.search}">
                    </div>

                    <select id="enq-state-filter" class="filter-select" style="min-width: 140px; font-weight: 600;">
                        <option value="all">All States</option>
                    </select>

                    <select id="enq-district-filter" class="filter-select" style="min-width: 140px; font-weight: 600;">
                        <option value="all">All Districts</option>
                    </select>

                    <select id="enq-taluka-filter" class="filter-select" style="min-width: 140px; font-weight: 600;">
                        <option value="all">All Talukas</option>
                    </select>

                    <select id="enq-area-filter" class="filter-select" style="min-width: 140px;">
                        <option value="all">All Areas</option>
                    </select>
                </div>

                <!-- Row 2: Date-wise and Status Filters -->
                <div style="display: flex; flex-wrap: wrap; gap: 10px; align-items: center; border-top: 1px solid var(--border-color, #f1f5f9); padding-top: 12px;">
                    <div style="display: flex; align-items: center; gap: 6px;">
                        <span style="font-size: 12px; font-weight: 700; color: var(--text-muted);"><i class="fa-solid fa-calendar-days"></i> Date:</span>
                        <select id="enq-date-filter" class="filter-select" style="min-width: 135px; font-weight: 600;">
                            <option value="all" ${this.enquiriesQuery.date_filter === 'all' ? 'selected' : ''}>All Dates</option>
                            <option value="today" ${this.enquiriesQuery.date_filter === 'today' ? 'selected' : ''}>Today</option>
                            <option value="yesterday" ${this.enquiriesQuery.date_filter === 'yesterday' ? 'selected' : ''}>Yesterday</option>
                            <option value="this_week" ${this.enquiriesQuery.date_filter === 'this_week' ? 'selected' : ''}>Last 7 Days</option>
                            <option value="this_month" ${this.enquiriesQuery.date_filter === 'this_month' ? 'selected' : ''}>This Month</option>
                            <option value="custom" ${this.enquiriesQuery.date_filter === 'custom' ? 'selected' : ''}>Custom Range</option>
                        </select>
                    </div>

                    <div id="enq-date-range-container" style="display: ${this.enquiriesQuery.date_filter === 'custom' ? 'flex' : 'none'}; align-items: center; gap: 6px;">
                        <input type="date" id="enq-start-date" class="form-control" style="padding: 6px 10px; font-size: 12px; width: 130px;" value="${this.enquiriesQuery.start_date}" title="Start Date">
                        <span style="font-size: 12px; color: var(--text-muted);">to</span>
                        <input type="date" id="enq-end-date" class="form-control" style="padding: 6px 10px; font-size: 12px; width: 130px;" value="${this.enquiriesQuery.end_date}" title="End Date">
                        <button type="button" id="enq-apply-date-btn" class="btn btn-secondary btn-sm" style="padding: 6px 10px; font-size: 11px;">Apply</button>
                    </div>

                    <div style="display: flex; align-items: center; gap: 6px; margin-left: auto;">
                        <span style="font-size: 12px; font-weight: 700; color: var(--text-muted);"><i class="fa-solid fa-tag"></i> Status:</span>
                        <select id="enq-status-filter" class="filter-select" style="min-width: 130px;">
                            <option value="all" ${this.enquiriesQuery.status === 'all' ? 'selected' : ''}>All Statuses</option>
                            <option value="New" ${this.enquiriesQuery.status === 'New' ? 'selected' : ''}>New</option>
                            <option value="Contacted" ${this.enquiriesQuery.status === 'Contacted' ? 'selected' : ''}>Contacted</option>
                            <option value="In Progress" ${this.enquiriesQuery.status === 'In Progress' ? 'selected' : ''}>In Progress</option>
                            <option value="Closed" ${this.enquiriesQuery.status === 'Closed' ? 'selected' : ''}>Closed</option>
                        </select>

                        <button id="enq-reset-filters" class="btn btn-secondary btn-sm" style="display: flex; align-items: center; gap: 6px;" title="Reset all filters to default">
                            <i class="fa-solid fa-filter-circle-xmark"></i> Clear
                        </button>
                    </div>
                </div>
            </div>

            <!-- Active Filter Breadcrumb & Live Count -->
            <div style="display: flex; align-items: center; justify-content: space-between; background: var(--bg-surface, #f8fafc); border: 1px solid var(--border-color, #e2e8f0); border-radius: 10px; padding: 10px 16px; margin-bottom: 16px; flex-wrap: wrap; gap: 10px;">
                <div style="display: flex; align-items: center; gap: 8px; font-size: 13px; font-weight: 600; color: var(--text-color, #1e293b);">
                    <i class="fa-solid fa-filter text-primary"></i>
                    <span id="enq-breadcrumb-text">Active Filter: All Records</span>
                </div>
                <span id="enq-count-badge" class="badge badge-primary" style="font-size: 12px; font-weight: 800; padding: 5px 12px; border-radius: 20px;">
                    Loading Enquiries...
                </span>
            </div>

            <!-- Enquiries Table -->
            <div class="table-responsive" style="background: var(--bg-card, #ffffff); border-radius: 12px; border: 1px solid var(--border-color, #e2e8f0); overflow: hidden;">
                <table class="table" id="enquiries-table" style="margin-bottom: 0;">
                    <thead>
                        <tr style="background: #f8fafc;">
                            <th style="width: 70px;"># ID</th>
                            <th>Received At</th>
                            <th>Customer Name & Contact</th>
                            <th>State & District</th>
                            <th>Taluka & Area</th>
                            <th>Status</th>
                            <th style="text-align: right; width: 140px;">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="enquiries-tbody">
                        <tr>
                            <td colspan="7" class="text-center" style="padding: 40px;">
                                <div class="spinner" style="margin: 0 auto; width: 32px; height: 32px;"></div>
                                <p style="margin-top: 12px; color: var(--text-muted); font-size: 13px;">Fetching website inquiries...</p>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- Pagination Container -->
            <div id="enq-pagination-container" style="display: flex; justify-content: space-between; align-items: center; margin-top: 16px; flex-wrap: wrap; gap: 12px;"></div>
        `;

        this.initEnquiriesFilterEvents();
        await this.fetchEnquiries();
    }

    initEnquiriesFilterEvents() {
        const stateSelect = document.getElementById('enq-state-filter');
        const districtSelect = document.getElementById('enq-district-filter');
        const talukaSelect = document.getElementById('enq-taluka-filter');
        const areaSelect = document.getElementById('enq-area-filter');
        const dateSelect = document.getElementById('enq-date-filter');
        const dateRangeContainer = document.getElementById('enq-date-range-container');
        const startDateInput = document.getElementById('enq-start-date');
        const endDateInput = document.getElementById('enq-end-date');
        const applyDateBtn = document.getElementById('enq-apply-date-btn');
        const statusSelect = document.getElementById('enq-status-filter');
        const searchInput = document.getElementById('enq-search');
        const resetBtn = document.getElementById('enq-reset-filters');

        if (!stateSelect || !districtSelect || !talukaSelect) return;

        // Populate States
        const states = (typeof LOCATION_DATA !== 'undefined' && LOCATION_DATA.statesByCountry && LOCATION_DATA.statesByCountry['India']) 
            ? LOCATION_DATA.statesByCountry['India'] 
            : ['Maharashtra', 'Gujarat', 'Karnataka'];

        stateSelect.innerHTML = '<option value="all">All States</option>' +
            states.map(s => `<option value="${s}" ${this.enquiriesQuery.state === s ? 'selected' : ''}>${s}</option>`).join('');

        const updateDistrictDropdown = (selectedState) => {
            let districts = [];
            if (selectedState && selectedState !== 'all' && typeof LOCATION_DATA !== 'undefined' && LOCATION_DATA.districtsByState && LOCATION_DATA.districtsByState[selectedState]) {
                districts = LOCATION_DATA.districtsByState[selectedState];
            } else if (typeof LOCATION_DATA !== 'undefined' && LOCATION_DATA.districtsByState && LOCATION_DATA.districtsByState['Maharashtra']) {
                districts = LOCATION_DATA.districtsByState['Maharashtra'];
            }
            districtSelect.innerHTML = '<option value="all">All Districts</option>' +
                districts.map(d => `<option value="${d}" ${this.enquiriesQuery.district === d ? 'selected' : ''}>${d}</option>`).join('');
            
            updateTalukaDropdown(districtSelect.value);
        };

        const updateTalukaDropdown = (selectedDistrict) => {
            let talukas = [];
            if (selectedDistrict && selectedDistrict !== 'all' && typeof LOCATION_DATA !== 'undefined' && LOCATION_DATA.talukasByDistrict && LOCATION_DATA.talukasByDistrict[selectedDistrict]) {
                talukas = LOCATION_DATA.talukasByDistrict[selectedDistrict];
            }
            talukaSelect.innerHTML = '<option value="all">All Talukas</option>' +
                talukas.map(t => `<option value="${t}" ${this.enquiriesQuery.taluka === t ? 'selected' : ''}>${t}</option>`).join('');

            updateAreaDropdown(selectedDistrict, talukaSelect.value);
        };

        const updateAreaDropdown = (selectedDistrict, selectedTaluka) => {
            let areas = [];
            if (selectedDistrict && selectedDistrict !== 'all' && typeof LOCATION_DATA !== 'undefined' && typeof LOCATION_DATA.getAllAreas === 'function') {
                areas = LOCATION_DATA.getAllAreas(selectedDistrict);
            }
            areaSelect.innerHTML = '<option value="all">All Areas</option>' +
                areas.map(a => `<option value="${a}" ${this.enquiriesQuery.area === a ? 'selected' : ''}>${a}</option>`).join('');
        };

        // Initialize state/district/taluka dropdowns
        updateDistrictDropdown(this.enquiriesQuery.state);

        // State Change Event
        stateSelect.addEventListener('change', () => {
            this.enquiriesQuery.state = stateSelect.value;
            this.enquiriesQuery.district = 'all';
            this.enquiriesQuery.taluka = 'all';
            this.enquiriesQuery.area = 'all';
            this.enquiriesQuery.page = 1;
            updateDistrictDropdown(stateSelect.value);
            this.fetchEnquiries();
        });

        // District Change Event
        districtSelect.addEventListener('change', () => {
            this.enquiriesQuery.district = districtSelect.value;
            this.enquiriesQuery.taluka = 'all';
            this.enquiriesQuery.area = 'all';
            this.enquiriesQuery.page = 1;
            updateTalukaDropdown(districtSelect.value);
            this.fetchEnquiries();
        });

        // Taluka Change Event
        talukaSelect.addEventListener('change', () => {
            this.enquiriesQuery.taluka = talukaSelect.value;
            this.enquiriesQuery.area = 'all';
            this.enquiriesQuery.page = 1;
            updateAreaDropdown(districtSelect.value, talukaSelect.value);
            this.fetchEnquiries();
        });

        // Area Change Event
        areaSelect.addEventListener('change', () => {
            this.enquiriesQuery.area = areaSelect.value;
            this.enquiriesQuery.page = 1;
            this.fetchEnquiries();
        });

        // Date Filter Change Event
        dateSelect.addEventListener('change', () => {
            const val = dateSelect.value;
            this.enquiriesQuery.date_filter = val;
            this.enquiriesQuery.page = 1;

            if (val === 'custom') {
                dateRangeContainer.style.display = 'flex';
            } else {
                dateRangeContainer.style.display = 'none';
                this.enquiriesQuery.start_date = '';
                this.enquiriesQuery.end_date = '';
                this.fetchEnquiries();
            }
        });

        // Custom Date Range Apply Button
        if (applyDateBtn) {
            applyDateBtn.addEventListener('click', () => {
                const sDate = startDateInput.value;
                const eDate = endDateInput.value;
                if (!sDate && !eDate) {
                    this.showToast('Please select at least a start date or end date.', 'warning');
                    return;
                }
                this.enquiriesQuery.start_date = sDate;
                this.enquiriesQuery.end_date = eDate;
                this.enquiriesQuery.page = 1;
                this.fetchEnquiries();
            });
        }

        // Status Change Event
        statusSelect.addEventListener('change', () => {
            this.enquiriesQuery.status = statusSelect.value;
            this.enquiriesQuery.page = 1;
            this.fetchEnquiries();
        });

        // Search Input (debounced)
        searchInput.addEventListener('input', () => {
            clearTimeout(this.debouncedSearchTimeout);
            this.debouncedSearchTimeout = setTimeout(() => {
                this.enquiriesQuery.search = searchInput.value.trim();
                this.enquiriesQuery.page = 1;
                this.fetchEnquiries();
            }, 350);
        });

        // Reset Filters Button
        resetBtn.addEventListener('click', () => {
            this.enquiriesQuery = {
                search: '',
                status: 'all',
                state: 'all',
                district: 'all',
                taluka: 'all',
                area: 'all',
                date_filter: 'all',
                start_date: '',
                end_date: '',
                page: 1,
                limit: 15
            };
            searchInput.value = '';
            statusSelect.value = 'all';
            dateSelect.value = 'all';
            dateRangeContainer.style.display = 'none';
            startDateInput.value = '';
            endDateInput.value = '';
            stateSelect.value = 'all';
            updateDistrictDropdown('all');
            this.fetchEnquiries();
        });
    }

    async refreshEnquiries() {
        await this.fetchEnquiries();
        this.showToast('Enquiries refreshed.', 'success');
    }

    async fetchEnquiries() {
        const tbody = document.getElementById('enquiries-tbody');
        const countBadge = document.getElementById('enq-count-badge');
        const breadcrumbText = document.getElementById('enq-breadcrumb-text');

        if (tbody) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="7" class="text-center" style="padding: 30px;">
                        <div class="spinner" style="margin: 0 auto; width: 28px; height: 28px;"></div>
                        <p style="margin-top: 10px; color: var(--text-muted); font-size: 13px;">Loading inquiries...</p>
                    </td>
                </tr>
            `;
        }

        // Update Breadcrumb
        if (breadcrumbText) {
            const locParts = [];
            if (this.enquiriesQuery.state && this.enquiriesQuery.state !== 'all') locParts.push(this.enquiriesQuery.state);
            if (this.enquiriesQuery.district && this.enquiriesQuery.district !== 'all') locParts.push(this.enquiriesQuery.district);
            if (this.enquiriesQuery.taluka && this.enquiriesQuery.taluka !== 'all') locParts.push(this.enquiriesQuery.taluka);
            if (this.enquiriesQuery.area && this.enquiriesQuery.area !== 'all') locParts.push(this.enquiriesQuery.area);

            const locStr = locParts.length > 0 ? `Location: ${locParts.join(' > ')}` : 'All Locations';
            const dateStr = this.enquiriesQuery.date_filter === 'custom' 
                ? `${this.enquiriesQuery.start_date || 'Start'} to ${this.enquiriesQuery.end_date || 'End'}` 
                : (this.enquiriesQuery.date_filter !== 'all' ? `${this.enquiriesQuery.date_filter.replace('_', ' ').toUpperCase()}` : 'All Dates');
            const statusStr = this.enquiriesQuery.status !== 'all' ? `${this.enquiriesQuery.status}` : '';

            breadcrumbText.innerHTML = [locStr, dateStr, statusStr].filter(Boolean).join(' &nbsp;•&nbsp; ');
        }

        try {
            const res = await api.getEnquiries(this.enquiriesQuery);
            if (!res || !res.success) {
                throw new Error(res?.message || 'Failed to fetch inquiries.');
            }

            const data = res.data || {};
            const inquiries = data.enquiries || [];
            this.currentEnquiries = inquiries;

            // Update KPI stats
            if (data.summary) {
                const totalEl = document.getElementById('enq-stat-total');
                const newEl = document.getElementById('enq-stat-new');
                const contactedEl = document.getElementById('enq-stat-contacted');
                const todayEl = document.getElementById('enq-stat-today');

                if (totalEl) totalEl.textContent = Number(data.summary.total_all || 0).toLocaleString();
                if (newEl) newEl.textContent = Number(data.summary.total_new || 0).toLocaleString();
                if (contactedEl) contactedEl.textContent = Number(data.summary.total_contacted || 0).toLocaleString();
                if (todayEl) todayEl.textContent = Number(data.summary.today_count || 0).toLocaleString();
            }

            // Update Count Badge
            if (countBadge) {
                const totalRecs = data.pagination?.total_records || inquiries.length;
                countBadge.textContent = `${totalRecs} Enquir${totalRecs === 1 ? 'y' : 'ies'} Found`;
            }

            // Render Table
            this.renderEnquiriesTable(inquiries);

            // Render Pagination
            this.renderEnquiriesPagination(data.pagination || { page: 1, limit: 15, total_records: inquiries.length, total_pages: 1 });

        } catch (err) {
            console.error('Error fetching enquiries:', err);
            if (tbody) {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="7" class="text-center text-danger" style="padding: 30px;">
                            <i class="fa-solid fa-triangle-exclamation" style="font-size: 24px; margin-bottom: 8px;"></i>
                            <p style="margin: 0; font-weight: 600;">Failed to load enquiries</p>
                            <small>${err.message}</small>
                            <div style="margin-top: 10px;">
                                <button class="btn btn-secondary btn-sm" onclick="app.fetchEnquiries()">Try Again</button>
                            </div>
                        </td>
                    </tr>
                `;
            }
            if (countBadge) countBadge.textContent = 'Error Loading';
        }
    }

    renderEnquiriesTable(inquiries) {
        const tbody = document.getElementById('enquiries-tbody');
        if (!tbody) return;

        if (!inquiries || inquiries.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="7" class="text-center" style="padding: 40px 20px;">
                        <div style="max-width: 380px; margin: 0 auto; color: var(--text-muted);">
                            <i class="fa-solid fa-inbox" style="font-size: 42px; color: #cbd5e1; margin-bottom: 12px; display: block;"></i>
                            <h4 style="font-size: 15px; font-weight: 700; color: var(--text-color, #1e293b); margin: 0 0 6px 0;">No Inquiries Found</h4>
                            <p style="font-size: 12.5px; margin: 0;">No visitor enquiries match your current location, date, or status filters. Try clearing or broadening your filters.</p>
                        </div>
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = inquiries.map(item => {
            const cleanPhone = (item.phone || '').trim();
            const phoneDigits = cleanPhone.replace(/[^\d]/g, '');
            const intlPhone = phoneDigits.startsWith('91') ? phoneDigits : ('91' + phoneDigits.replace(/^0+/, ''));
            const dateStr = item.created_at ? new Date(item.created_at).toLocaleDateString('en-IN', {
                day: '2-digit', month: 'short', year: 'numeric'
            }) : '-';
            const timeStr = item.created_at ? new Date(item.created_at).toLocaleTimeString('en-IN', {
                hour: '2-digit', minute: '2-digit', hour12: true
            }) : '';

            // Status Styling
            let statusBadge = '';
            switch (item.status) {
                case 'New':
                    statusBadge = `<span class="badge" style="background: rgba(245, 158, 11, 0.15); color: #d97706; border: 1px solid rgba(245, 158, 11, 0.3); font-weight: 800; padding: 4px 10px; border-radius: 12px; font-size: 11px;"><i class="fa-solid fa-circle-dot" style="font-size: 8px; margin-right: 4px;"></i> New</span>`;
                    break;
                case 'Contacted':
                    statusBadge = `<span class="badge" style="background: rgba(59, 130, 246, 0.15); color: #2563eb; border: 1px solid rgba(59, 130, 246, 0.3); font-weight: 800; padding: 4px 10px; border-radius: 12px; font-size: 11px;"><i class="fa-solid fa-phone-flip" style="font-size: 8px; margin-right: 4px;"></i> Contacted</span>`;
                    break;
                case 'In Progress':
                    statusBadge = `<span class="badge" style="background: rgba(139, 92, 246, 0.15); color: #7c3aed; border: 1px solid rgba(139, 92, 246, 0.3); font-weight: 800; padding: 4px 10px; border-radius: 12px; font-size: 11px;"><i class="fa-solid fa-spinner" style="font-size: 8px; margin-right: 4px;"></i> In Progress</span>`;
                    break;
                case 'Closed':
                    statusBadge = `<span class="badge" style="background: rgba(16, 185, 129, 0.15); color: #059669; border: 1px solid rgba(16, 185, 129, 0.3); font-weight: 800; padding: 4px 10px; border-radius: 12px; font-size: 11px;"><i class="fa-solid fa-check-circle" style="font-size: 8px; margin-right: 4px;"></i> Closed</span>`;
                    break;
                default:
                    statusBadge = `<span class="badge badge-secondary" style="font-weight: 700; padding: 4px 10px; border-radius: 12px; font-size: 11px;">${item.status || 'New'}</span>`;
            }

            return `
                <tr style="transition: background 0.15s ease;">
                    <td style="font-weight: 800; color: var(--text-muted); font-size: 12px;">#${item.id}</td>
                    <td>
                        <div style="font-weight: 700; font-size: 12.5px; color: var(--text-color, #1e293b);">${dateStr}</div>
                        <div style="font-size: 11px; color: var(--text-muted);"><i class="fa-regular fa-clock" style="font-size: 10px;"></i> ${timeStr}</div>
                    </td>
                    <td>
                        <div style="font-weight: 800; font-size: 13.5px; color: var(--text-color, #1e293b);">${item.name}</div>
                        <div style="display: flex; align-items: center; gap: 8px; margin-top: 4px;">
                            <span style="font-size: 12px; font-weight: 600; color: var(--text-muted);"><i class="fa-solid fa-phone" style="font-size: 10px; color: #10b981;"></i> ${item.phone}</span>
                            <a href="tel:${cleanPhone}" class="btn btn-secondary btn-sm" style="padding: 1px 7px; font-size: 10px; border-radius: 6px;" title="Call Customer">
                                <i class="fa-solid fa-phone"></i>
                            </a>
                            <a href="https://wa.me/${intlPhone}?text=${encodeURIComponent('Hello ' + item.name + ', greetings from Hungrily Foods! We received your tiffin enquiry.')}" target="_blank" class="btn btn-sm" style="padding: 1px 7px; font-size: 10px; background: #25D366; color: white; border: none; border-radius: 6px;" title="Chat on WhatsApp">
                                <i class="fa-brands fa-whatsapp"></i>
                            </a>
                        </div>
                    </td>
                    <td>
                        <div style="font-weight: 700; font-size: 12.5px; color: var(--text-color, #1e293b);">${item.district || '-'}</div>
                        <div style="font-size: 11px; color: var(--text-muted);">${item.state || 'Maharashtra'}</div>
                    </td>
                    <td>
                        <div style="display: flex; flex-direction: column; gap: 3px;">
                            <span class="badge" style="background: rgba(79, 70, 229, 0.08); color: #4338ca; border: 1px solid rgba(79, 70, 229, 0.25); font-weight: 700; padding: 2px 8px; border-radius: 6px; font-size: 11px; width: fit-content;">
                                <i class="fa-solid fa-location-crosshairs" style="font-size: 9px; margin-right: 4px;"></i>${item.taluka || '-'}
                            </span>
                            <span style="font-size: 12px; font-weight: 600; color: #0f172a;">${item.area || '-'}</span>
                        </div>
                    </td>
                    <td>
                        <div style="display: flex; flex-direction: column; gap: 4px;">
                            <div>${statusBadge}</div>
                            <select onchange="app.changeEnquiryStatus(${item.id}, this.value)" style="padding: 2px 6px; font-size: 10.5px; border-radius: 6px; border: 1px solid var(--border-color, #cbd5e1); background: white; cursor: pointer; color: var(--text-muted); width: 100px;">
                                <option value="New" ${item.status === 'New' ? 'selected' : ''}>Set: New</option>
                                <option value="Contacted" ${item.status === 'Contacted' ? 'selected' : ''}>Set: Contacted</option>
                                <option value="In Progress" ${item.status === 'In Progress' ? 'selected' : ''}>Set: In Progress</option>
                                <option value="Closed" ${item.status === 'Closed' ? 'selected' : ''}>Set: Closed</option>
                            </select>
                        </div>
                    </td>
                    <td style="text-align: right;">
                        <div style="display: flex; align-items: center; justify-content: flex-end; gap: 6px;">
                            <button class="btn btn-secondary btn-sm" onclick="app.openEnquiryDetailsModal(${item.id})" style="padding: 5px 8px; font-size: 12px;" title="View Complete Enquiry Details">
                                <i class="fa-solid fa-eye"></i>
                            </button>
                            <button class="btn btn-danger btn-sm" onclick="app.deleteEnquiryPrompt(${item.id})" style="padding: 5px 8px; font-size: 12px; background: rgba(239, 68, 68, 0.1); color: #ef4444; border-color: rgba(239, 68, 68, 0.2);" title="Delete Enquiry">
                                <i class="fa-solid fa-trash-can"></i>
                            </button>
                        </div>
                    </td>
                </tr>
            `;
        }).join('');
    }

    renderEnquiriesPagination(pagination) {
        const container = document.getElementById('enq-pagination-container');
        if (!container) return;

        const { page, total_pages, total_records } = pagination;
        if (!total_records || total_records === 0) {
            container.innerHTML = '';
            return;
        }

        const startIdx = (page - 1) * this.enquiriesQuery.limit + 1;
        const endIdx = Math.min(page * this.enquiriesQuery.limit, total_records);

        container.innerHTML = `
            <div style="font-size: 13px; color: var(--text-muted);">
                Showing <strong>${startIdx}</strong> to <strong>${endIdx}</strong> of <strong>${total_records}</strong> entries
            </div>
            <div style="display: flex; gap: 6px; align-items: center;">
                <button class="btn btn-secondary btn-sm" ${page <= 1 ? 'disabled' : ''} onclick="app.goToEnquiriesPage(${page - 1})" style="padding: 4px 10px; font-size: 12px;">
                    <i class="fa-solid fa-angle-left"></i> Previous
                </button>
                <span style="font-size: 12px; font-weight: 700; color: var(--text-color); padding: 0 6px;">
                    Page ${page} of ${total_pages || 1}
                </span>
                <button class="btn btn-secondary btn-sm" ${page >= total_pages ? 'disabled' : ''} onclick="app.goToEnquiriesPage(${page + 1})" style="padding: 4px 10px; font-size: 12px;">
                    Next <i class="fa-solid fa-angle-right"></i>
                </button>
            </div>
        `;
    }

    goToEnquiriesPage(targetPage) {
        this.enquiriesQuery.page = targetPage;
        this.fetchEnquiries();
    }

    async changeEnquiryStatus(id, newStatus) {
        try {
            const res = await api.updateEnquiryStatus(id, newStatus);
            if (res && res.success) {
                this.showToast(`Enquiry #${id} status updated to ${newStatus}.`, 'success');
                await this.fetchEnquiries();
            } else {
                throw new Error(res?.message || 'Status update failed.');
            }
        } catch (err) {
            this.showToast('Could not update status: ' + err.message, 'error');
            await this.fetchEnquiries();
        }
    }

    openEnquiryDetailsModal(id) {
        const item = this.currentEnquiries.find(e => Number(e.id) === Number(id));
        if (!item) {
            this.showToast('Enquiry record not found.', 'error');
            return;
        }

        const modalTitle = document.getElementById('modal-title');
        const modalContent = document.getElementById('modal-content');
        if (!modalTitle || !modalContent) return;

        modalTitle.innerHTML = `<i class="fa-solid fa-headset text-primary"></i> Customer Enquiry #${item.id}`;

        const cleanPhone = (item.phone || '').trim();
        const phoneDigits = cleanPhone.replace(/[^\d]/g, '');
        const intlPhone = phoneDigits.startsWith('91') ? phoneDigits : ('91' + phoneDigits.replace(/^0+/, ''));
        const dateFormatted = item.created_at ? new Date(item.created_at).toLocaleString('en-IN', {
            dateStyle: 'full', timeStyle: 'short'
        }) : '-';

        modalContent.innerHTML = `
            <div style="display: flex; flex-direction: column; gap: 16px;">
                <!-- Customer Contact Card -->
                <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px;">
                    <div style="display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: gap; gap: 10px;">
                        <div>
                            <span style="font-size: 11px; font-weight: 700; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px;">Customer Name</span>
                            <h3 style="margin: 2px 0 0 0; font-size: 1.15rem; font-weight: 800; color: #0f172a;">${item.name}</h3>
                            <div style="display: flex; align-items: center; gap: 8px; margin-top: 6px;">
                                <strong style="font-size: 13.5px; color: #1e293b;">${item.phone}</strong>
                            </div>
                        </div>
                        <div style="display: flex; gap: 8px;">
                            <a href="tel:${cleanPhone}" class="btn btn-secondary btn-sm" style="display: flex; align-items: center; gap: 6px;">
                                <i class="fa-solid fa-phone" style="color: #10b981;"></i> Call Customer
                            </a>
                            <a href="https://wa.me/${intlPhone}?text=${encodeURIComponent('Hello ' + item.name + ', thank you for your enquiry on Hungrily Foods!')}" target="_blank" class="btn btn-sm" style="display: flex; align-items: center; gap: 6px; background: #25D366; color: white; border: none; font-weight: 600;">
                                <i class="fa-brands fa-whatsapp"></i> Chat on WhatsApp
                            </a>
                        </div>
                    </div>
                </div>

                <!-- Location Hierarchy Card -->
                <div style="background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px;">
                    <h4 style="margin: 0 0 12px 0; font-size: 13px; font-weight: 800; color: #0f172a; display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-map-location-dot text-primary"></i> Customer Location Hierarchy
                    </h4>
                    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)); gap: 12px;">
                        <div style="background: #f8fafc; padding: 10px; border-radius: 8px; border: 1px solid #f1f5f9;">
                            <span style="font-size: 10.5px; font-weight: 700; color: var(--text-muted); display: block;">STATE</span>
                            <strong style="font-size: 13px; color: #1e293b;">${item.state || '-'}</strong>
                        </div>
                        <div style="background: #f8fafc; padding: 10px; border-radius: 8px; border: 1px solid #f1f5f9;">
                            <span style="font-size: 10.5px; font-weight: 700; color: var(--text-muted); display: block;">DISTRICT</span>
                            <strong style="font-size: 13px; color: #1e293b;">${item.district || '-'}</strong>
                        </div>
                        <div style="background: #f8fafc; padding: 10px; border-radius: 8px; border: 1px solid #f1f5f9;">
                            <span style="font-size: 10.5px; font-weight: 700; color: var(--text-muted); display: block;">TALUKA</span>
                            <strong style="font-size: 13px; color: #4338ca;">${item.taluka || '-'}</strong>
                        </div>
                        <div style="background: #f8fafc; padding: 10px; border-radius: 8px; border: 1px solid #f1f5f9;">
                            <span style="font-size: 10.5px; font-weight: 700; color: var(--text-muted); display: block;">AREA / LOCALITY</span>
                            <strong style="font-size: 13px; color: #0f172a;">${item.area || '-'}</strong>
                        </div>
                    </div>
                </div>

                <!-- Submission Details & Notes -->
                <div style="background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px;">
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                        <span style="font-size: 12px; color: var(--text-muted);">
                            <i class="fa-regular fa-calendar-check"></i> Submitted: <strong>${dateFormatted}</strong>
                        </span>
                    </div>

                    <div class="form-group" style="margin-bottom: 12px;">
                        <label class="form-label" style="font-weight: 700; font-size: 12px;">Update Status:</label>
                        <select id="modal-enquiry-status" class="form-control" style="padding: 8px 12px; font-size: 13px;">
                            <option value="New" ${item.status === 'New' ? 'selected' : ''}>New (Needs Follow-up)</option>
                            <option value="Contacted" ${item.status === 'Contacted' ? 'selected' : ''}>Contacted / Called</option>
                            <option value="In Progress" ${item.status === 'In Progress' ? 'selected' : ''}>In Progress / Trial Scheduled</option>
                            <option value="Closed" ${item.status === 'Closed' ? 'selected' : ''}>Closed / Subscribed</option>
                            <option value="Cancelled" ${item.status === 'Cancelled' ? 'selected' : ''}>Cancelled</option>
                        </select>
                    </div>

                    <div class="form-group" style="margin-bottom: 12px;">
                        <label class="form-label" style="font-weight: 700; font-size: 12px;">Admin Notes & Follow-up Remarks:</label>
                        <textarea id="modal-enquiry-notes" class="form-control" rows="3" placeholder="Enter notes from call with customer (meal preference, delivery timings, pricing discussed)..." style="font-size: 13px;">${item.notes || ''}</textarea>
                    </div>

                    <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 14px;">
                        <button type="button" class="btn btn-danger btn-sm" onclick="app.closeModal('details-modal'); app.deleteEnquiryPrompt(${item.id});" style="background: rgba(239, 68, 68, 0.1); color: #ef4444; border-color: rgba(239, 68, 68, 0.2);">
                            <i class="fa-solid fa-trash-can"></i> Delete Enquiry
                        </button>
                        <button type="button" class="btn btn-primary btn-sm" onclick="app.saveEnquiryModalData(${item.id})" style="padding: 8px 16px;">
                            <i class="fa-solid fa-floppy-disk"></i> Save Changes
                        </button>
                    </div>
                </div>
            </div>
        `;

        this.openModal('details-modal');
    }

    async saveEnquiryModalData(id) {
        const statusEl = document.getElementById('modal-enquiry-status');
        const notesEl = document.getElementById('modal-enquiry-notes');
        const status = statusEl ? statusEl.value : 'New';
        const notes = notesEl ? notesEl.value.trim() : '';

        try {
            const res = await api.updateEnquiryStatus(id, status, notes);
            if (res && res.success) {
                this.showToast('Enquiry updated successfully.', 'success');
                this.closeModal('details-modal');
                await this.fetchEnquiries();
            } else {
                throw new Error(res?.message || 'Update failed.');
            }
        } catch (err) {
            this.showToast('Failed to save enquiry: ' + err.message, 'error');
        }
    }

    deleteEnquiryPrompt(id) {
        this.selectedDeleteId = id;
        this.selectedDeleteType = 'enquiry';
        this.openModal('delete-modal');
    }

    exportEnquiriesCSV() {
        if (!this.currentEnquiries || this.currentEnquiries.length === 0) {
            this.showToast('No inquiries available to export.', 'warning');
            return;
        }

        const headers = ['ID', 'Received Date', 'Name', 'Phone', 'State', 'District', 'Taluka', 'Area', 'Status', 'Admin Notes'];
        const csvRows = [headers.join(',')];

        for (const item of this.currentEnquiries) {
            const row = [
                item.id,
                `"${(item.created_at || '').replace(/"/g, '""')}"`,
                `"${(item.name || '').replace(/"/g, '""')}"`,
                `"${(item.phone || '').replace(/"/g, '""')}"`,
                `"${(item.state || '').replace(/"/g, '""')}"`,
                `"${(item.district || '').replace(/"/g, '""')}"`,
                `"${(item.taluka || '').replace(/"/g, '""')}"`,
                `"${(item.area || '').replace(/"/g, '""')}"`,
                `"${(item.status || '').replace(/"/g, '""')}"`,
                `"${(item.notes || '').replace(/"/g, '""')}"`
            ];
            csvRows.push(row.join(','));
        }

        const csvContent = 'data:text/csv;charset=utf-8,' + encodeURIComponent(csvRows.join('\n'));
        const downloadLink = document.createElement('a');
        downloadLink.setAttribute('href', csvContent);
        downloadLink.setAttribute('download', `hungrily_enquiries_${new Date().toISOString().slice(0, 10)}.csv`);
        document.body.appendChild(downloadLink);
        downloadLink.click();
        document.body.removeChild(downloadLink);

        this.showToast('Enquiries exported to CSV.', 'success');
    }
}

// Instantiate App globally
const app = new App();
window.app = app;
