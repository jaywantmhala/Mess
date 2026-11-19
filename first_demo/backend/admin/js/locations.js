/**
 * Omni Admin Panel - Comprehensive Location & Region Hierarchy
 * Generated from maharashtra_locations.json
 */
(function(window) {
    const data = {
  "defaultCountry": "India",
  "countries": [
    "India",
    "United States",
    "United Kingdom",
    "Canada",
    "Australia",
    "United Arab Emirates"
  ],
  "statesByCountry": {
    "India": [
      "Maharashtra",
      "Gujarat",
      "Karnataka",
      "Tamil Nadu",
      "Uttar Pradesh",
      "Rajasthan",
      "Madhya Pradesh",
      "Delhi",
      "Kerala",
      "Telangana",
      "Andhra Pradesh",
      "Punjab",
      "Haryana",
      "Bihar",
      "West Bengal",
      "Goa",
      "Himachal Pradesh",
      "Uttarakhand",
      "Jharkhand",
      "Odisha",
      "Assam",
      "Jammu & Kashmir"
    ],
    "United States": [
      "California",
      "Texas",
      "Florida",
      "New York",
      "Illinois"
    ],
    "United Kingdom": [
      "England",
      "Scotland",
      "Wales",
      "Northern Ireland"
    ],
    "Canada": [
      "Ontario",
      "Quebec",
      "British Columbia",
      "Alberta"
    ],
    "Australia": [
      "New South Wales",
      "Victoria",
      "Queensland",
      "Western Australia"
    ],
    "United Arab Emirates": [
      "Dubai",
      "Abu Dhabi",
      "Sharjah",
      "Ajman"
    ]
  },
  "districtsByState": {
    "Maharashtra": [
      "Ahilyanagar",
      "Akola",
      "Amravati",
      "Beed",
      "Bhandara",
      "Buldhana",
      "Chandrapur",
      "Chhatrapati Sambhajinagar",
      "Dharashiv",
      "Dhule",
      "Gadchiroli",
      "Gondia",
      "Hingoli",
      "Jalgaon",
      "Jalna",
      "Kolhapur",
      "Latur",
      "Mumbai City",
      "Mumbai Suburban",
      "Nagpur",
      "Nanded",
      "Nandurbar",
      "Nashik",
      "Palghar",
      "Parbhani",
      "Pune",
      "Raigad",
      "Ratnagiri",
      "Sangli",
      "Satara",
      "Sindhudurg",
      "Solapur",
      "Thane",
      "Wardha",
      "Washim",
      "Yavatmal"
    ],
    "Gujarat": [
      "Ahmedabad",
      "Surat",
      "Vadodara",
      "Rajkot",
      "Bhavnagar",
      "Jamnagar",
      "Gandhinagar"
    ],
    "Karnataka": [
      "Bengaluru Urban",
      "Bengaluru Rural",
      "Mysuru",
      "Mangaluru",
      "Hubballi-Dharwad",
      "Belagavi"
    ],
    "Tamil Nadu": [
      "Chennai",
      "Coimbatore",
      "Madurai",
      "Tiruchirappalli",
      "Salem"
    ],
    "Uttar Pradesh": [
      "Lucknow",
      "Kanpur",
      "Varanasi",
      "Agra",
      "Noida",
      "Ghaziabad",
      "Prayagraj"
    ],
    "Delhi": [
      "New Delhi",
      "North Delhi",
      "South Delhi",
      "East Delhi",
      "West Delhi"
    ]
  },
  "talukasByDistrict": {
    "Ahmedabad": [
      "Ahmedabad City",
      "Daskroi",
      "Sanand",
      "Bavla",
      "Dholka",
      "Viramgam",
      "Mandal",
      "Detroj-Rampura",
      "Dholera"
    ],
    "Surat": [
      "Surat City",
      "Chorasi",
      "Olpad",
      "Kamrej",
      "Bardoli",
      "Mahuva",
      "Mandvi",
      "Mangrol",
      "Palsana",
      "Umarpada"
    ],
    "Vadodara": [
      "Vadodara",
      "Dabhoi",
      "Karjan",
      "Padra",
      "Savli",
      "Vaghodia",
      "Sinor",
      "Desar"
    ],
    "Rajkot": [
      "Rajkot",
      "Gondal",
      "Jetpur",
      "Jasdan",
      "Dhoraji",
      "Morbi",
      "Kotda Sangani",
      "Paddhari",
      "Lodhika"
    ],
    "Bengaluru Urban": [
      "Bengaluru North",
      "Bengaluru South",
      "Bengaluru East",
      "Anekal",
      "Yelahanka"
    ],
    "Mysuru": [
      "Mysuru",
      "Nanjangud",
      "Hunsur",
      "Piriyapatna",
      "T. Narasipura",
      "KR Nagar",
      "Saragur"
    ],
    "Chennai": [
      "Egmore",
      "Mylapore",
      "Tondiarpet",
      "Guindy",
      "Velachery",
      "Ambattur",
      "Ayanavaram",
      "Aminjikarai"
    ],
    "Coimbatore": [
      "Coimbatore North",
      "Coimbatore South",
      "Pollachi",
      "Mettupalayam",
      "Annur",
      "Sulur",
      "Valparai"
    ],
    "Lucknow": [
      "Lucknow",
      "Mohanlalganj",
      "Malihabad",
      "Bakshi Ka Talab",
      "Sarojani Nagar"
    ],
    "Varanasi": [
      "Varanasi",
      "Pindra",
      "Raja Talab"
    ],
    "Ahilyanagar": [
      "Ahilyanagar",
      "Akole",
      "Jamkhed",
      "Karjat",
      "Kopargaon",
      "Nevasa",
      "Parner",
      "Pathardi",
      "Rahata",
      "Rahuri",
      "Sangamner",
      "Shevgaon",
      "Shrigonda",
      "Shrirampur"
    ],
    "Akola": [
      "Akola",
      "Akot",
      "Balapur",
      "Barshitakli",
      "Murtizapur",
      "Patur",
      "Telhara"
    ],
    "Amravati": [
      "Achalpur",
      "Amravati",
      "Anjangaon Surji",
      "Bhatkuli",
      "Chandur Railway",
      "Chandurbazar",
      "Chikhaldara",
      "Daryapur",
      "Dhamangaon Railway",
      "Dharni",
      "Morshi",
      "Nandgaon Khandeshwar",
      "Tiosa",
      "Warud"
    ],
    "Beed": [
      "Ambajogai",
      "Ashti",
      "Beed",
      "Dharur",
      "Georai",
      "Kaij",
      "Majalgaon",
      "Parli",
      "Patoda",
      "Shirur Kasar",
      "Wadwani"
    ],
    "Bhandara": [
      "Bhandara",
      "Lakhandur",
      "Lakhani",
      "Mohadi",
      "Pauni",
      "Sakoli",
      "Tumsar"
    ],
    "Buldhana": [
      "Buldhana",
      "Chikhli",
      "Deulgaon Raja",
      "Jalgaon Jamod",
      "Khamgaon",
      "Lonar",
      "Malkapur",
      "Mehkar",
      "Motala",
      "Nandura",
      "Sangrampur",
      "Shegaon",
      "Sindkhed Raja"
    ],
    "Chandrapur": [
      "Ballarpur",
      "Bhadravati",
      "Brahmapuri",
      "Chandrapur",
      "Chimur",
      "Gondpipri",
      "Jiwati",
      "Korpana",
      "Mul",
      "Nagbhid",
      "Pombhurna",
      "Rajura",
      "Saoli",
      "Sindewahi",
      "Warora"
    ],
    "Chhatrapati Sambhajinagar": [
      "Chhatrapati Sambhajinagar",
      "Gangapur",
      "Kannad",
      "Khultabad",
      "Paithan",
      "Phulambri",
      "Sillod",
      "Soegaon",
      "Vaijapur"
    ],
    "Dharashiv": [
      "Bhum",
      "Dharashiv",
      "Kalamb",
      "Lohara",
      "Paranda",
      "Tuljapur",
      "Umarga",
      "Washi"
    ],
    "Dhule": [
      "Dhule",
      "Sakri",
      "Shindkheda",
      "Shirpur"
    ],
    "Gadchiroli": [
      "Aheri",
      "Armori",
      "Bhamragad",
      "Chamorshi",
      "Desaiganj",
      "Dhanora",
      "Etapalli",
      "Gadchiroli",
      "Korchi",
      "Kurkheda",
      "Mulchera",
      "Sironcha"
    ],
    "Gondia": [
      "Amgaon",
      "Arjuni Morgaon",
      "Deori",
      "Gondia",
      "Goregaon",
      "Sadak Arjuni",
      "Salekasa",
      "Tirora"
    ],
    "Hingoli": [
      "Aundha Nagnath",
      "Basmath",
      "Hingoli",
      "Kalamnuri",
      "Sengaon"
    ],
    "Jalgaon": [
      "Amalner",
      "Bhadgaon",
      "Bhusawal",
      "Bodwad",
      "Chalisgaon",
      "Chopda",
      "Dharangaon",
      "Erandol",
      "Jalgaon",
      "Jamner",
      "Muktainagar",
      "Pachora",
      "Parola",
      "Raver",
      "Yawal"
    ],
    "Jalna": [
      "Ambad",
      "Badnapur",
      "Bhokardan",
      "Ghansawangi",
      "Jafrabad",
      "Jalna",
      "Mantha",
      "Partur"
    ],
    "Kolhapur": [
      "Ajra",
      "Bhudargad",
      "Chandgad",
      "Gaganbawada",
      "Hatkanangale",
      "Kagal",
      "Karvir",
      "Panhala",
      "Radhanagari",
      "Shahuwadi",
      "Shirol"
    ],
    "Latur": [
      "Ahmedpur",
      "Ausa",
      "Chakur",
      "Deoni",
      "Jalkot",
      "Latur",
      "Nilanga",
      "Renapur",
      "Shirur Anantpal",
      "Udgir"
    ],
    "Mumbai City": [
      "Mumbai City"
    ],
    "Mumbai Suburban": [
      "Andheri",
      "Borivali",
      "Kurla"
    ],
    "Nagpur": [
      "Bhiwapur",
      "Hingna",
      "Kalmeshwar",
      "Kamptee",
      "Katol",
      "Kuhi",
      "Mouda",
      "Nagpur Rural",
      "Nagpur Urban",
      "Narkhed",
      "Parseoni",
      "Ramtek",
      "Saoner",
      "Umred"
    ],
    "Nanded": [
      "Ardhapur",
      "Bhokar",
      "Biloli",
      "Deglur",
      "Dharmabad",
      "Hadgaon",
      "Himayatnagar",
      "Kandhar",
      "Kinwat",
      "Loha",
      "Mahur",
      "Mudkhed",
      "Mukhed",
      "Naigaon",
      "Nanded",
      "Umri"
    ],
    "Nandurbar": [
      "Akkalkuwa",
      "Akrani",
      "Nandurbar",
      "Navapur",
      "Shahada",
      "Taloda"
    ],
    "Nashik": [
      "Baglan",
      "Chandwad",
      "Deola",
      "Dindori",
      "Igatpuri",
      "Kalwan",
      "Malegaon",
      "Nandgaon",
      "Nashik",
      "Niphad",
      "Peint",
      "Sinnar",
      "Surgana",
      "Trimbakeshwar",
      "Yeola"
    ],
    "Palghar": [
      "Dahanu",
      "Jawhar",
      "Mokhada",
      "Palghar",
      "Talasari",
      "Vasai",
      "Vikramgad",
      "Wada"
    ],
    "Parbhani": [
      "Gangakhed",
      "Jintur",
      "Manwath",
      "Palam",
      "Parbhani",
      "Pathri",
      "Purna",
      "Selu",
      "Sonpeth"
    ],
    "Pune": [
      "Ambegaon",
      "Baramati",
      "Bhor",
      "Daund",
      "Haveli",
      "Indapur",
      "Junnar",
      "Khed",
      "Mawal",
      "Mulshi",
      "Pune City",
      "Purandar",
      "Shirur",
      "Velhe"
    ],
    "Raigad": [
      "Alibag",
      "Karjat",
      "Khalapur",
      "Mahad",
      "Mangaon",
      "Mhasla",
      "Murud",
      "Panvel",
      "Pen",
      "Poladpur",
      "Roha",
      "Shrivardhan",
      "Sudhagad",
      "Tala",
      "Uran"
    ],
    "Ratnagiri": [
      "Chiplun",
      "Dapoli",
      "Guhagar",
      "Khed",
      "Lanja",
      "Mandangad",
      "Sangameshwar",
      "Ratnagiri",
      "Rajapur"
    ],
    "Sangli": [
      "Atpadi",
      "Jat",
      "Kadegaon",
      "Kavathe Mahankal",
      "Khanapur",
      "Miraj",
      "Palus",
      "Shirala",
      "Tasgaon",
      "Walwa"
    ],
    "Satara": [
      "Jaoli",
      "Karad",
      "Khandala",
      "Khatav",
      "Koregaon",
      "Mahabaleshwar",
      "Man",
      "Patan",
      "Phaltan",
      "Satara",
      "Wai"
    ],
    "Sindhudurg": [
      "Devgad",
      "Dodamarg",
      "Kankavli",
      "Kudal",
      "Malvan",
      "Sawantwadi",
      "Vaibhavwadi",
      "Vengurla"
    ],
    "Solapur": [
      "Akkalkot",
      "Barshi",
      "Karmala",
      "Madha",
      "Malshiras",
      "Mangalvedhe",
      "Mohol",
      "North Solapur",
      "Pandharpur",
      "Sangole",
      "South Solapur"
    ],
    "Thane": [
      "Ambernath",
      "Bhiwandi",
      "Kalyan",
      "Murbad",
      "Shahapur",
      "Thane",
      "Ulhasnagar"
    ],
    "Wardha": [
      "Arvi",
      "Ashti",
      "Deoli",
      "Hinganghat",
      "Karanja",
      "Samudrapur",
      "Seloo",
      "Wardha"
    ],
    "Washim": [
      "Karanja",
      "Malegaon",
      "Mangrulpir",
      "Manora",
      "Risod",
      "Washim"
    ],
    "Yavatmal": [
      "Arni",
      "Babhulgaon",
      "Darwha",
      "Digras",
      "Ghatanji",
      "Kalamb",
      "Kelapur",
      "Mahagaon",
      "Maregaon",
      "Ner",
      "Pusad",
      "Ralegaon",
      "Umarkhed",
      "Wani",
      "Yavatmal",
      "Zari-Jamani"
    ],
    "Ahmednagar": [
      "Ahilyanagar",
      "Akole",
      "Jamkhed",
      "Karjat",
      "Kopargaon",
      "Nevasa",
      "Parner",
      "Pathardi",
      "Rahata",
      "Rahuri",
      "Sangamner",
      "Shevgaon",
      "Shrigonda",
      "Shrirampur"
    ],
    "Aurangabad": [
      "Chhatrapati Sambhajinagar",
      "Gangapur",
      "Kannad",
      "Khultabad",
      "Paithan",
      "Phulambri",
      "Sillod",
      "Soegaon",
      "Vaijapur"
    ],
    "Osmanabad": [
      "Bhum",
      "Dharashiv",
      "Kalamb",
      "Lohara",
      "Paranda",
      "Tuljapur",
      "Umarga",
      "Washi"
    ]
  },
  "regionsByDistrict": {
    "Ahilyanagar": [],
    "Akola": [],
    "Amravati": [],
    "Beed": [],
    "Bhandara": [],
    "Buldhana": [],
    "Chandrapur": [],
    "Chhatrapati Sambhajinagar": [],
    "Dharashiv": [],
    "Dhule": [],
    "Gadchiroli": [],
    "Gondia": [],
    "Hingoli": [],
    "Jalgaon": [],
    "Jalna": [],
    "Kolhapur": [],
    "Latur": [],
    "Mumbai City": [],
    "Mumbai Suburban": [],
    "Nagpur": [],
    "Nanded": [],
    "Nandurbar": [],
    "Nashik": [],
    "Palghar": [
      "Vasai-Virar and surrounding areas",
      "Other nearby urban and industrial localities"
    ],
    "Parbhani": [],
    "Pune": [
      "PMC",
      "PCMC",
      "Pune Rural and Outskirts"
    ],
    "Raigad": [
      "Navi Mumbai and Panvel region",
      "Karjat, Khopoli and nearby areas"
    ],
    "Ratnagiri": [],
    "Sangli": [],
    "Satara": [],
    "Sindhudurg": [],
    "Solapur": [],
    "Thane": [],
    "Wardha": [],
    "Washim": [],
    "Yavatmal": []
  },
  "areasByDistrictAndRegion": {
    "Ahilyanagar": {},
    "Akola": {},
    "Amravati": {},
    "Beed": {},
    "Bhandara": {},
    "Buldhana": {},
    "Chandrapur": {},
    "Chhatrapati Sambhajinagar": {},
    "Dharashiv": {},
    "Dhule": {},
    "Gadchiroli": {},
    "Gondia": {},
    "Hingoli": {},
    "Jalgaon": {},
    "Jalna": {},
    "Kolhapur": {},
    "Latur": {},
    "Mumbai City": {},
    "Mumbai Suburban": {},
    "Nagpur": {},
    "Nanded": {},
    "Nandurbar": {},
    "Nashik": {},
    "Palghar": {
      "Vasai-Virar and surrounding areas": [
        "Mira Road",
        "Bhayandar East",
        "Bhayandar West",
        "Uttan",
        "Dongri",
        "Rai",
        "Morva",
        "Pali",
        "Chena",
        "Bhayandar Station Road",
        "Vasai West",
        "Vasai East",
        "Vasai Road",
        "Nalasopara West",
        "Nalasopara East",
        "Virar West",
        "Virar East",
        "Virar Station area",
        "Naigaon East",
        "Naigaon West",
        "Achole",
        "Agashi",
        "Arnala",
        "Bolinj",
        "Sopara",
        "Pelhar",
        "Waliv",
        "Gokhivare",
        "Evershine City",
        "Chandansar",
        "Manickpur",
        "Papdy",
        "Bhuigaon",
        "Juchandra",
        "Rajodi",
        "Nirmal",
        "Umelman"
      ],
      "Other nearby urban and industrial localities": [
        "Dombivli MIDC",
        "Ambernath MIDC",
        "Badlapur MIDC",
        "Taloja MIDC",
        "Mahape MIDC",
        "TTC Industrial Area",
        "Tarapur-side industrial localities",
        "JNPT logistics areas"
      ]
    },
    "Parbhani": {},
    "Pune": {
      "PMC": [
        "Shivajinagar",
        "Deccan Gymkhana",
        "Kothrud",
        "Karve Nagar",
        "Erandwane",
        "Warje",
        "Bavdhan",
        "Aundh",
        "Baner",
        "Balewadi",
        "Pashan",
        "Sus",
        "Model Colony",
        "Senapati Bapat Road",
        "Khadki",
        "Yerawada",
        "Kalyani Nagar",
        "Viman Nagar",
        "Dhanori",
        "Lohegaon",
        "Wadgaon Sheri",
        "Kharadi",
        "Chandan Nagar",
        "Hadapsar",
        "Mundhwa",
        "Magarpatta City",
        "Amanora Park Town",
        "Wanowrie",
        "Fatima Nagar",
        "Kondhwa",
        "NIBM Road",
        "Undri",
        "Pisoli",
        "Dhankawadi",
        "Katraj",
        "Bibwewadi",
        "Sahakarnagar",
        "Parvati",
        "Sinhagad Road",
        "Dhayari",
        "Ambegaon",
        "Narhe",
        "Swargate",
        "Camp",
        "Nana Peth",
        "Bhawani Peth",
        "Rasta Peth",
        "Raviwar Peth",
        "Sadashiv Peth",
        "Narayan Peth",
        "Guruwar Peth",
        "Kasba Peth",
        "Ghorpade Peth",
        "Gultekdi",
        "Market Yard",
        "Ghorpuri",
        "Fursungi-side localities",
        "Khadki Bazar",
        "Dapodi-side localities"
      ],
      "PCMC": [
        "Pimpri",
        "Chinchwad",
        "Akurdi",
        "Nigdi",
        "Pradhikaran",
        "Ravet",
        "Kiwale",
        "Mamurdi",
        "Punawale",
        "Tathawade",
        "Wakad",
        "Thergaon",
        "Kalewadi",
        "Rahatani",
        "Pimple Saudagar",
        "Pimple Gurav",
        "Pimple Nilakh",
        "Sangvi",
        "Dapodi",
        "Bhosari",
        "Moshi",
        "Dighi",
        "Chikhali",
        "Charholi Budruk",
        "Dudulgaon",
        "Kudalwadi",
        "Nehrunagar",
        "Kasarwadi",
        "Phugewadi"
      ],
      "Pune Rural and Outskirts": [
        "Shewalewadi",
        "Fursungi",
        "Saswad",
        "Jejuri",
        "Bhor",
        "Velhe",
        "Pirangut",
        "Paud",
        "Mulshi",
        "Lavale",
        "Bhugaon",
        "Bhukum",
        "Hinjawadi",
        "Maan",
        "Marunji",
        "Nere",
        "Gahunje",
        "Talegaon Dabhade",
        "Vadgaon Maval",
        "Lonavala",
        "Kamshet",
        "Chakan",
        "Mahalunge",
        "Rajgurunagar",
        "Khed",
        "Narayangaon",
        "Junnar",
        "Shirur",
        "Daund",
        "Baramati",
        "Indapur",
        "Alandi",
        "Dehu",
        "Panshet",
        "Khadakwasla",
        "Ranjangaon",
        "Shikrapur",
        "Pabal",
        "Manchar",
        "Kalas",
        "Khed Shivapur",
        "Nasrapur",
        "Khandala",
        "Kanhe",
        "Somatane",
        "Varale",
        "Vadgaon Sheri outskirts"
      ]
    },
    "Raigad": {
      "Navi Mumbai and Panvel region": [
        "Vashi",
        "Sanpada",
        "Juinagar",
        "Nerul",
        "Seawoods",
        "CBD Belapur",
        "Belapur",
        "Kharghar",
        "Kopar Khairane",
        "Ghansoli",
        "Airoli",
        "Rabale",
        "Turbhe",
        "Pawane",
        "Mahape",
        "TTC Industrial Area",
        "Digha",
        "Bonkode",
        "Juhugaon",
        "Sector 17 Vashi",
        "Sector 15 CBD Belapur",
        "Nerul East",
        "Nerul West",
        "Palm Beach Road localities",
        "Kamothe",
        "Kalamboli",
        "Khandeshwar",
        "New Panvel East",
        "New Panvel West",
        "Pushpak Nagar",
        "Ulwe",
        "Dronagiri",
        "Taloja",
        "Roadpali",
        "Karanjade",
        "Navade",
        "Owe Camp",
        "Pendhar",
        "Rasayani",
        "Uran",
        "JNPT",
        "Nhava-Sheva",
        "Panvel",
        "Old Panvel",
        "Palaspe",
        "Adai",
        "Vichumbe",
        "Sukapur",
        "Khanda Colony",
        "Newale",
        "Chowk",
        "Nere",
        "Poyanje",
        "Chirle",
        "Jaskhar",
        "Bokadvira"
      ],
      "Karjat, Khopoli and nearby areas": [
        "Karjat",
        "Neral",
        "Bhivpuri Road",
        "Shelu",
        "Vangani",
        "Chowk",
        "Khopoli",
        "Khalapur",
        "Pali",
        "Rasayani"
      ]
    },
    "Ratnagiri": {},
    "Sangli": {},
    "Satara": {},
    "Sindhudurg": {},
    "Solapur": {},
    "Thane": {},
    "Wardha": {},
    "Washim": {},
    "Yavatmal": {}
  },
  "allAreasByDistrict": {
    "Ahilyanagar": [],
    "Akola": [],
    "Amravati": [],
    "Beed": [],
    "Bhandara": [],
    "Buldhana": [],
    "Chandrapur": [],
    "Chhatrapati Sambhajinagar": [],
    "Dharashiv": [],
    "Dhule": [],
    "Gadchiroli": [],
    "Gondia": [],
    "Hingoli": [],
    "Jalgaon": [],
    "Jalna": [],
    "Kolhapur": [],
    "Latur": [],
    "Mumbai City": [],
    "Mumbai Suburban": [],
    "Nagpur": [],
    "Nanded": [],
    "Nandurbar": [],
    "Nashik": [],
    "Palghar": [
      "Achole",
      "Agashi",
      "Ambernath MIDC",
      "Arnala",
      "Badlapur MIDC",
      "Bhayandar East",
      "Bhayandar Station Road",
      "Bhayandar West",
      "Bhuigaon",
      "Bolinj",
      "Chandansar",
      "Chena",
      "Dombivli MIDC",
      "Dongri",
      "Evershine City",
      "Gokhivare",
      "JNPT logistics areas",
      "Juchandra",
      "Mahape MIDC",
      "Manickpur",
      "Mira Road",
      "Morva",
      "Naigaon East",
      "Naigaon West",
      "Nalasopara East",
      "Nalasopara West",
      "Nirmal",
      "Pali",
      "Papdy",
      "Pelhar",
      "Rai",
      "Rajodi",
      "Sopara",
      "TTC Industrial Area",
      "Taloja MIDC",
      "Tarapur-side industrial localities",
      "Umelman",
      "Uttan",
      "Vasai East",
      "Vasai Road",
      "Vasai West",
      "Virar East",
      "Virar Station area",
      "Virar West",
      "Waliv"
    ],
    "Parbhani": [],
    "Pune": [
      "Akurdi",
      "Alandi",
      "Amanora Park Town",
      "Ambegaon",
      "Aundh",
      "Balewadi",
      "Baner",
      "Baramati",
      "Bavdhan",
      "Bhawani Peth",
      "Bhor",
      "Bhosari",
      "Bhugaon",
      "Bhukum",
      "Bibwewadi",
      "Camp",
      "Chakan",
      "Chandan Nagar",
      "Charholi Budruk",
      "Chikhali",
      "Chinchwad",
      "Dapodi",
      "Dapodi-side localities",
      "Daund",
      "Deccan Gymkhana",
      "Dehu",
      "Dhankawadi",
      "Dhanori",
      "Dhayari",
      "Dighi",
      "Dudulgaon",
      "Erandwane",
      "Fatima Nagar",
      "Fursungi",
      "Fursungi-side localities",
      "Gahunje",
      "Ghorpade Peth",
      "Ghorpuri",
      "Gultekdi",
      "Guruwar Peth",
      "Hadapsar",
      "Hinjawadi",
      "Indapur",
      "Jejuri",
      "Junnar",
      "Kalas",
      "Kalewadi",
      "Kalyani Nagar",
      "Kamshet",
      "Kanhe",
      "Karve Nagar",
      "Kasarwadi",
      "Kasba Peth",
      "Katraj",
      "Khadakwasla",
      "Khadki",
      "Khadki Bazar",
      "Khandala",
      "Kharadi",
      "Khed",
      "Khed Shivapur",
      "Kiwale",
      "Kondhwa",
      "Kothrud",
      "Kudalwadi",
      "Lavale",
      "Lohegaon",
      "Lonavala",
      "Maan",
      "Magarpatta City",
      "Mahalunge",
      "Mamurdi",
      "Manchar",
      "Market Yard",
      "Marunji",
      "Model Colony",
      "Moshi",
      "Mulshi",
      "Mundhwa",
      "NIBM Road",
      "Nana Peth",
      "Narayan Peth",
      "Narayangaon",
      "Narhe",
      "Nasrapur",
      "Nehrunagar",
      "Nere",
      "Nigdi",
      "Pabal",
      "Panshet",
      "Parvati",
      "Pashan",
      "Paud",
      "Phugewadi",
      "Pimple Gurav",
      "Pimple Nilakh",
      "Pimple Saudagar",
      "Pimpri",
      "Pirangut",
      "Pisoli",
      "Pradhikaran",
      "Punawale",
      "Rahatani",
      "Rajgurunagar",
      "Ranjangaon",
      "Rasta Peth",
      "Ravet",
      "Raviwar Peth",
      "Sadashiv Peth",
      "Sahakarnagar",
      "Sangvi",
      "Saswad",
      "Senapati Bapat Road",
      "Shewalewadi",
      "Shikrapur",
      "Shirur",
      "Shivajinagar",
      "Sinhagad Road",
      "Somatane",
      "Sus",
      "Swargate",
      "Talegaon Dabhade",
      "Tathawade",
      "Thergaon",
      "Undri",
      "Vadgaon Maval",
      "Vadgaon Sheri outskirts",
      "Varale",
      "Velhe",
      "Viman Nagar",
      "Wadgaon Sheri",
      "Wakad",
      "Wanowrie",
      "Warje",
      "Yerawada"
    ],
    "Raigad": [
      "Adai",
      "Airoli",
      "Belapur",
      "Bhivpuri Road",
      "Bokadvira",
      "Bonkode",
      "CBD Belapur",
      "Chirle",
      "Chowk",
      "Digha",
      "Dronagiri",
      "Ghansoli",
      "JNPT",
      "Jaskhar",
      "Juhugaon",
      "Juinagar",
      "Kalamboli",
      "Kamothe",
      "Karanjade",
      "Karjat",
      "Khalapur",
      "Khanda Colony",
      "Khandeshwar",
      "Kharghar",
      "Khopoli",
      "Kopar Khairane",
      "Mahape",
      "Navade",
      "Neral",
      "Nere",
      "Nerul",
      "Nerul East",
      "Nerul West",
      "New Panvel East",
      "New Panvel West",
      "Newale",
      "Nhava-Sheva",
      "Old Panvel",
      "Owe Camp",
      "Palaspe",
      "Pali",
      "Palm Beach Road localities",
      "Panvel",
      "Pawane",
      "Pendhar",
      "Poyanje",
      "Pushpak Nagar",
      "Rabale",
      "Rasayani",
      "Roadpali",
      "Sanpada",
      "Seawoods",
      "Sector 15 CBD Belapur",
      "Sector 17 Vashi",
      "Shelu",
      "Sukapur",
      "TTC Industrial Area",
      "Taloja",
      "Turbhe",
      "Ulwe",
      "Uran",
      "Vangani",
      "Vashi",
      "Vichumbe"
    ],
    "Ratnagiri": [],
    "Sangli": [],
    "Satara": [],
    "Sindhudurg": [],
    "Solapur": [],
    "Thane": [],
    "Wardha": [],
    "Washim": [],
    "Yavatmal": []
  },
  "areaToRegion": {
    "mira road": {
      "area": "Mira Road",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "bhayandar east": {
      "area": "Bhayandar East",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "bhayandar west": {
      "area": "Bhayandar West",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "uttan": {
      "area": "Uttan",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "dongri": {
      "area": "Dongri",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "rai": {
      "area": "Rai",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "morva": {
      "area": "Morva",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "pali": {
      "area": "Pali",
      "region": "Karjat, Khopoli and nearby areas",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "chena": {
      "area": "Chena",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "bhayandar station road": {
      "area": "Bhayandar Station Road",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "vasai west": {
      "area": "Vasai West",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "vasai east": {
      "area": "Vasai East",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "vasai road": {
      "area": "Vasai Road",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "nalasopara west": {
      "area": "Nalasopara West",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "nalasopara east": {
      "area": "Nalasopara East",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "virar west": {
      "area": "Virar West",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "virar east": {
      "area": "Virar East",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "virar station area": {
      "area": "Virar Station area",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "naigaon east": {
      "area": "Naigaon East",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "naigaon west": {
      "area": "Naigaon West",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "achole": {
      "area": "Achole",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "agashi": {
      "area": "Agashi",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "arnala": {
      "area": "Arnala",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "bolinj": {
      "area": "Bolinj",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "sopara": {
      "area": "Sopara",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "pelhar": {
      "area": "Pelhar",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "waliv": {
      "area": "Waliv",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "gokhivare": {
      "area": "Gokhivare",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "evershine city": {
      "area": "Evershine City",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "chandansar": {
      "area": "Chandansar",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "manickpur": {
      "area": "Manickpur",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "papdy": {
      "area": "Papdy",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "bhuigaon": {
      "area": "Bhuigaon",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "juchandra": {
      "area": "Juchandra",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "rajodi": {
      "area": "Rajodi",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "nirmal": {
      "area": "Nirmal",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "umelman": {
      "area": "Umelman",
      "region": "Vasai-Virar and surrounding areas",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "dombivli midc": {
      "area": "Dombivli MIDC",
      "region": "Other nearby urban and industrial localities",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "ambernath midc": {
      "area": "Ambernath MIDC",
      "region": "Other nearby urban and industrial localities",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "badlapur midc": {
      "area": "Badlapur MIDC",
      "region": "Other nearby urban and industrial localities",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "taloja midc": {
      "area": "Taloja MIDC",
      "region": "Other nearby urban and industrial localities",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "mahape midc": {
      "area": "Mahape MIDC",
      "region": "Other nearby urban and industrial localities",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "ttc industrial area": {
      "area": "TTC Industrial Area",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "tarapur-side industrial localities": {
      "area": "Tarapur-side industrial localities",
      "region": "Other nearby urban and industrial localities",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "jnpt logistics areas": {
      "area": "JNPT logistics areas",
      "region": "Other nearby urban and industrial localities",
      "district": "Palghar",
      "taluka": "Vasai"
    },
    "shivajinagar": {
      "area": "Shivajinagar",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "deccan gymkhana": {
      "area": "Deccan Gymkhana",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "kothrud": {
      "area": "Kothrud",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "karve nagar": {
      "area": "Karve Nagar",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "erandwane": {
      "area": "Erandwane",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "warje": {
      "area": "Warje",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "bavdhan": {
      "area": "Bavdhan",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "aundh": {
      "area": "Aundh",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "baner": {
      "area": "Baner",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "balewadi": {
      "area": "Balewadi",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "pashan": {
      "area": "Pashan",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "sus": {
      "area": "Sus",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "model colony": {
      "area": "Model Colony",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "senapati bapat road": {
      "area": "Senapati Bapat Road",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "khadki": {
      "area": "Khadki",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "yerawada": {
      "area": "Yerawada",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "kalyani nagar": {
      "area": "Kalyani Nagar",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "viman nagar": {
      "area": "Viman Nagar",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "dhanori": {
      "area": "Dhanori",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "lohegaon": {
      "area": "Lohegaon",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "wadgaon sheri": {
      "area": "Wadgaon Sheri",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "kharadi": {
      "area": "Kharadi",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "chandan nagar": {
      "area": "Chandan Nagar",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "hadapsar": {
      "area": "Hadapsar",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "mundhwa": {
      "area": "Mundhwa",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "magarpatta city": {
      "area": "Magarpatta City",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "amanora park town": {
      "area": "Amanora Park Town",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "wanowrie": {
      "area": "Wanowrie",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "fatima nagar": {
      "area": "Fatima Nagar",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "kondhwa": {
      "area": "Kondhwa",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "nibm road": {
      "area": "NIBM Road",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "undri": {
      "area": "Undri",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "pisoli": {
      "area": "Pisoli",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "dhankawadi": {
      "area": "Dhankawadi",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "katraj": {
      "area": "Katraj",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "bibwewadi": {
      "area": "Bibwewadi",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "sahakarnagar": {
      "area": "Sahakarnagar",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "parvati": {
      "area": "Parvati",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "sinhagad road": {
      "area": "Sinhagad Road",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "dhayari": {
      "area": "Dhayari",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "ambegaon": {
      "area": "Ambegaon",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "narhe": {
      "area": "Narhe",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "swargate": {
      "area": "Swargate",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "camp": {
      "area": "Camp",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "nana peth": {
      "area": "Nana Peth",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "bhawani peth": {
      "area": "Bhawani Peth",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "rasta peth": {
      "area": "Rasta Peth",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "raviwar peth": {
      "area": "Raviwar Peth",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "sadashiv peth": {
      "area": "Sadashiv Peth",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "narayan peth": {
      "area": "Narayan Peth",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "guruwar peth": {
      "area": "Guruwar Peth",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "kasba peth": {
      "area": "Kasba Peth",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "ghorpade peth": {
      "area": "Ghorpade Peth",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "gultekdi": {
      "area": "Gultekdi",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "market yard": {
      "area": "Market Yard",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "ghorpuri": {
      "area": "Ghorpuri",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "fursungi-side localities": {
      "area": "Fursungi-side localities",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "khadki bazar": {
      "area": "Khadki Bazar",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "dapodi-side localities": {
      "area": "Dapodi-side localities",
      "region": "PMC",
      "district": "Pune",
      "taluka": "Pune City"
    },
    "pimpri": {
      "area": "Pimpri",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "chinchwad": {
      "area": "Chinchwad",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "akurdi": {
      "area": "Akurdi",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "nigdi": {
      "area": "Nigdi",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "pradhikaran": {
      "area": "Pradhikaran",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "ravet": {
      "area": "Ravet",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "kiwale": {
      "area": "Kiwale",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "mamurdi": {
      "area": "Mamurdi",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "punawale": {
      "area": "Punawale",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "tathawade": {
      "area": "Tathawade",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "wakad": {
      "area": "Wakad",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "thergaon": {
      "area": "Thergaon",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "kalewadi": {
      "area": "Kalewadi",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "rahatani": {
      "area": "Rahatani",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "pimple saudagar": {
      "area": "Pimple Saudagar",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "pimple gurav": {
      "area": "Pimple Gurav",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "pimple nilakh": {
      "area": "Pimple Nilakh",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "sangvi": {
      "area": "Sangvi",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "dapodi": {
      "area": "Dapodi",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "bhosari": {
      "area": "Bhosari",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "moshi": {
      "area": "Moshi",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "dighi": {
      "area": "Dighi",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "chikhali": {
      "area": "Chikhali",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "charholi budruk": {
      "area": "Charholi Budruk",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "dudulgaon": {
      "area": "Dudulgaon",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "kudalwadi": {
      "area": "Kudalwadi",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "nehrunagar": {
      "area": "Nehrunagar",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "kasarwadi": {
      "area": "Kasarwadi",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "phugewadi": {
      "area": "Phugewadi",
      "region": "PCMC",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "shewalewadi": {
      "area": "Shewalewadi",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "fursungi": {
      "area": "Fursungi",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "saswad": {
      "area": "Saswad",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "jejuri": {
      "area": "Jejuri",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "bhor": {
      "area": "Bhor",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "velhe": {
      "area": "Velhe",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "pirangut": {
      "area": "Pirangut",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "paud": {
      "area": "Paud",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "mulshi": {
      "area": "Mulshi",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "lavale": {
      "area": "Lavale",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "bhugaon": {
      "area": "Bhugaon",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "bhukum": {
      "area": "Bhukum",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "hinjawadi": {
      "area": "Hinjawadi",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "maan": {
      "area": "Maan",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "marunji": {
      "area": "Marunji",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "nere": {
      "area": "Nere",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "gahunje": {
      "area": "Gahunje",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "talegaon dabhade": {
      "area": "Talegaon Dabhade",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "vadgaon maval": {
      "area": "Vadgaon Maval",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "lonavala": {
      "area": "Lonavala",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "kamshet": {
      "area": "Kamshet",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "chakan": {
      "area": "Chakan",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "mahalunge": {
      "area": "Mahalunge",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "rajgurunagar": {
      "area": "Rajgurunagar",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "khed": {
      "area": "Khed",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "narayangaon": {
      "area": "Narayangaon",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "junnar": {
      "area": "Junnar",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "shirur": {
      "area": "Shirur",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "daund": {
      "area": "Daund",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "baramati": {
      "area": "Baramati",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "indapur": {
      "area": "Indapur",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "alandi": {
      "area": "Alandi",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "dehu": {
      "area": "Dehu",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "panshet": {
      "area": "Panshet",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "khadakwasla": {
      "area": "Khadakwasla",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "ranjangaon": {
      "area": "Ranjangaon",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "shikrapur": {
      "area": "Shikrapur",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "pabal": {
      "area": "Pabal",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "manchar": {
      "area": "Manchar",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "kalas": {
      "area": "Kalas",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "khed shivapur": {
      "area": "Khed Shivapur",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "nasrapur": {
      "area": "Nasrapur",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "khandala": {
      "area": "Khandala",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "kanhe": {
      "area": "Kanhe",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "somatane": {
      "area": "Somatane",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "varale": {
      "area": "Varale",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "vadgaon sheri outskirts": {
      "area": "Vadgaon Sheri outskirts",
      "region": "Pune Rural and Outskirts",
      "district": "Pune",
      "taluka": "Haveli"
    },
    "vashi": {
      "area": "Vashi",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "sanpada": {
      "area": "Sanpada",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "juinagar": {
      "area": "Juinagar",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "nerul": {
      "area": "Nerul",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "seawoods": {
      "area": "Seawoods",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "cbd belapur": {
      "area": "CBD Belapur",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "belapur": {
      "area": "Belapur",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "kharghar": {
      "area": "Kharghar",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "kopar khairane": {
      "area": "Kopar Khairane",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "ghansoli": {
      "area": "Ghansoli",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "airoli": {
      "area": "Airoli",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "rabale": {
      "area": "Rabale",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "turbhe": {
      "area": "Turbhe",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "pawane": {
      "area": "Pawane",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "mahape": {
      "area": "Mahape",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "digha": {
      "area": "Digha",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "bonkode": {
      "area": "Bonkode",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "juhugaon": {
      "area": "Juhugaon",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "sector 17 vashi": {
      "area": "Sector 17 Vashi",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "sector 15 cbd belapur": {
      "area": "Sector 15 CBD Belapur",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "nerul east": {
      "area": "Nerul East",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "nerul west": {
      "area": "Nerul West",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "palm beach road localities": {
      "area": "Palm Beach Road localities",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "kamothe": {
      "area": "Kamothe",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "kalamboli": {
      "area": "Kalamboli",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "khandeshwar": {
      "area": "Khandeshwar",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "new panvel east": {
      "area": "New Panvel East",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "new panvel west": {
      "area": "New Panvel West",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "pushpak nagar": {
      "area": "Pushpak Nagar",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "ulwe": {
      "area": "Ulwe",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "dronagiri": {
      "area": "Dronagiri",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "taloja": {
      "area": "Taloja",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "roadpali": {
      "area": "Roadpali",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "karanjade": {
      "area": "Karanjade",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "navade": {
      "area": "Navade",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "owe camp": {
      "area": "Owe Camp",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "pendhar": {
      "area": "Pendhar",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "rasayani": {
      "area": "Rasayani",
      "region": "Karjat, Khopoli and nearby areas",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "uran": {
      "area": "Uran",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "jnpt": {
      "area": "JNPT",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "nhava-sheva": {
      "area": "Nhava-Sheva",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "panvel": {
      "area": "Panvel",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "old panvel": {
      "area": "Old Panvel",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "palaspe": {
      "area": "Palaspe",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "adai": {
      "area": "Adai",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "vichumbe": {
      "area": "Vichumbe",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "sukapur": {
      "area": "Sukapur",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "khanda colony": {
      "area": "Khanda Colony",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "newale": {
      "area": "Newale",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "chowk": {
      "area": "Chowk",
      "region": "Karjat, Khopoli and nearby areas",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "poyanje": {
      "area": "Poyanje",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "chirle": {
      "area": "Chirle",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "jaskhar": {
      "area": "Jaskhar",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "bokadvira": {
      "area": "Bokadvira",
      "region": "Navi Mumbai and Panvel region",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "karjat": {
      "area": "Karjat",
      "region": "Karjat, Khopoli and nearby areas",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "neral": {
      "area": "Neral",
      "region": "Karjat, Khopoli and nearby areas",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "bhivpuri road": {
      "area": "Bhivpuri Road",
      "region": "Karjat, Khopoli and nearby areas",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "shelu": {
      "area": "Shelu",
      "region": "Karjat, Khopoli and nearby areas",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "vangani": {
      "area": "Vangani",
      "region": "Karjat, Khopoli and nearby areas",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "khopoli": {
      "area": "Khopoli",
      "region": "Karjat, Khopoli and nearby areas",
      "district": "Raigad",
      "taluka": "Panvel"
    },
    "khalapur": {
      "area": "Khalapur",
      "region": "Karjat, Khopoli and nearby areas",
      "district": "Raigad",
      "taluka": "Panvel"
    }
  },
  "rawMaharashtra": {
    "state": "Maharashtra",
    "districts": {
      "Ahilyanagar": {
        "talukas": [
          "Ahilyanagar",
          "Akole",
          "Jamkhed",
          "Karjat",
          "Kopargaon",
          "Nevasa",
          "Parner",
          "Pathardi",
          "Rahata",
          "Rahuri",
          "Sangamner",
          "Shevgaon",
          "Shrigonda",
          "Shrirampur"
        ],
        "regions": {}
      },
      "Akola": {
        "talukas": [
          "Akola",
          "Akot",
          "Balapur",
          "Barshitakli",
          "Murtizapur",
          "Patur",
          "Telhara"
        ],
        "regions": {}
      },
      "Amravati": {
        "talukas": [
          "Achalpur",
          "Amravati",
          "Anjangaon Surji",
          "Bhatkuli",
          "Chandur Railway",
          "Chandurbazar",
          "Chikhaldara",
          "Daryapur",
          "Dhamangaon Railway",
          "Dharni",
          "Morshi",
          "Nandgaon Khandeshwar",
          "Tiosa",
          "Warud"
        ],
        "regions": {}
      },
      "Beed": {
        "talukas": [
          "Ambajogai",
          "Ashti",
          "Beed",
          "Dharur",
          "Georai",
          "Kaij",
          "Majalgaon",
          "Parli",
          "Patoda",
          "Shirur Kasar",
          "Wadwani"
        ],
        "regions": {}
      },
      "Bhandara": {
        "talukas": [
          "Bhandara",
          "Lakhandur",
          "Lakhani",
          "Mohadi",
          "Pauni",
          "Sakoli",
          "Tumsar"
        ],
        "regions": {}
      },
      "Buldhana": {
        "talukas": [
          "Buldhana",
          "Chikhli",
          "Deulgaon Raja",
          "Jalgaon Jamod",
          "Khamgaon",
          "Lonar",
          "Malkapur",
          "Mehkar",
          "Motala",
          "Nandura",
          "Sangrampur",
          "Shegaon",
          "Sindkhed Raja"
        ],
        "regions": {}
      },
      "Chandrapur": {
        "talukas": [
          "Ballarpur",
          "Bhadravati",
          "Brahmapuri",
          "Chandrapur",
          "Chimur",
          "Gondpipri",
          "Jiwati",
          "Korpana",
          "Mul",
          "Nagbhid",
          "Pombhurna",
          "Rajura",
          "Saoli",
          "Sindewahi",
          "Warora"
        ],
        "regions": {}
      },
      "Chhatrapati Sambhajinagar": {
        "talukas": [
          "Chhatrapati Sambhajinagar",
          "Gangapur",
          "Kannad",
          "Khultabad",
          "Paithan",
          "Phulambri",
          "Sillod",
          "Soegaon",
          "Vaijapur"
        ],
        "regions": {}
      },
      "Dharashiv": {
        "talukas": [
          "Bhum",
          "Dharashiv",
          "Kalamb",
          "Lohara",
          "Paranda",
          "Tuljapur",
          "Umarga",
          "Washi"
        ],
        "regions": {}
      },
      "Dhule": {
        "talukas": [
          "Dhule",
          "Sakri",
          "Shindkheda",
          "Shirpur"
        ],
        "regions": {}
      },
      "Gadchiroli": {
        "talukas": [
          "Aheri",
          "Armori",
          "Bhamragad",
          "Chamorshi",
          "Desaiganj",
          "Dhanora",
          "Etapalli",
          "Gadchiroli",
          "Korchi",
          "Kurkheda",
          "Mulchera",
          "Sironcha"
        ],
        "regions": {}
      },
      "Gondia": {
        "talukas": [
          "Amgaon",
          "Arjuni Morgaon",
          "Deori",
          "Gondia",
          "Goregaon",
          "Sadak Arjuni",
          "Salekasa",
          "Tirora"
        ],
        "regions": {}
      },
      "Hingoli": {
        "talukas": [
          "Aundha Nagnath",
          "Basmath",
          "Hingoli",
          "Kalamnuri",
          "Sengaon"
        ],
        "regions": {}
      },
      "Jalgaon": {
        "talukas": [
          "Amalner",
          "Bhadgaon",
          "Bhusawal",
          "Bodwad",
          "Chalisgaon",
          "Chopda",
          "Dharangaon",
          "Erandol",
          "Jalgaon",
          "Jamner",
          "Muktainagar",
          "Pachora",
          "Parola",
          "Raver",
          "Yawal"
        ],
        "regions": {}
      },
      "Jalna": {
        "talukas": [
          "Ambad",
          "Badnapur",
          "Bhokardan",
          "Ghansawangi",
          "Jafrabad",
          "Jalna",
          "Mantha",
          "Partur"
        ],
        "regions": {}
      },
      "Kolhapur": {
        "talukas": [
          "Ajra",
          "Bhudargad",
          "Chandgad",
          "Gaganbawada",
          "Hatkanangale",
          "Kagal",
          "Karvir",
          "Panhala",
          "Radhanagari",
          "Shahuwadi",
          "Shirol"
        ],
        "regions": {}
      },
      "Latur": {
        "talukas": [
          "Ahmedpur",
          "Ausa",
          "Chakur",
          "Deoni",
          "Jalkot",
          "Latur",
          "Nilanga",
          "Renapur",
          "Shirur Anantpal",
          "Udgir"
        ],
        "regions": {}
      },
      "Mumbai City": {
        "talukas": [
          "Mumbai City"
        ],
        "regions": {}
      },
      "Mumbai Suburban": {
        "talukas": [
          "Andheri",
          "Borivali",
          "Kurla"
        ],
        "regions": {}
      },
      "Nagpur": {
        "talukas": [
          "Bhiwapur",
          "Hingna",
          "Kalmeshwar",
          "Kamptee",
          "Katol",
          "Kuhi",
          "Mouda",
          "Nagpur Rural",
          "Nagpur Urban",
          "Narkhed",
          "Parseoni",
          "Ramtek",
          "Saoner",
          "Umred"
        ],
        "regions": {}
      },
      "Nanded": {
        "talukas": [
          "Ardhapur",
          "Bhokar",
          "Biloli",
          "Deglur",
          "Dharmabad",
          "Hadgaon",
          "Himayatnagar",
          "Kandhar",
          "Kinwat",
          "Loha",
          "Mahur",
          "Mudkhed",
          "Mukhed",
          "Naigaon",
          "Nanded",
          "Umri"
        ],
        "regions": {}
      },
      "Nandurbar": {
        "talukas": [
          "Akkalkuwa",
          "Akrani",
          "Nandurbar",
          "Navapur",
          "Shahada",
          "Taloda"
        ],
        "regions": {}
      },
      "Nashik": {
        "talukas": [
          "Baglan",
          "Chandwad",
          "Deola",
          "Dindori",
          "Igatpuri",
          "Kalwan",
          "Malegaon",
          "Nandgaon",
          "Nashik",
          "Niphad",
          "Peint",
          "Sinnar",
          "Surgana",
          "Trimbakeshwar",
          "Yeola"
        ],
        "regions": {}
      },
      "Palghar": {
        "talukas": [
          "Dahanu",
          "Jawhar",
          "Mokhada",
          "Palghar",
          "Talasari",
          "Vasai",
          "Vikramgad",
          "Wada"
        ],
        "regions": {
          "Vasai-Virar and surrounding areas": [
            "Mira Road",
            "Bhayandar East",
            "Bhayandar West",
            "Uttan",
            "Dongri",
            "Rai",
            "Morva",
            "Pali",
            "Chena",
            "Bhayandar Station Road",
            "Vasai West",
            "Vasai East",
            "Vasai Road",
            "Nalasopara West",
            "Nalasopara East",
            "Virar West",
            "Virar East",
            "Virar Station area",
            "Naigaon East",
            "Naigaon West",
            "Achole",
            "Agashi",
            "Arnala",
            "Bolinj",
            "Sopara",
            "Pelhar",
            "Waliv",
            "Gokhivare",
            "Evershine City",
            "Chandansar",
            "Manickpur",
            "Papdy",
            "Bhuigaon",
            "Juchandra",
            "Rajodi",
            "Nirmal",
            "Umelman"
          ],
          "Other nearby urban and industrial localities": [
            "Dombivli MIDC",
            "Ambernath MIDC",
            "Badlapur MIDC",
            "Taloja MIDC",
            "Mahape MIDC",
            "TTC Industrial Area",
            "Tarapur-side industrial localities",
            "JNPT logistics areas"
          ]
        }
      },
      "Parbhani": {
        "talukas": [
          "Gangakhed",
          "Jintur",
          "Manwath",
          "Palam",
          "Parbhani",
          "Pathri",
          "Purna",
          "Selu",
          "Sonpeth"
        ],
        "regions": {}
      },
      "Pune": {
        "talukas": [
          "Ambegaon",
          "Baramati",
          "Bhor",
          "Daund",
          "Haveli",
          "Indapur",
          "Junnar",
          "Khed",
          "Mawal",
          "Mulshi",
          "Pune City",
          "Purandar",
          "Shirur",
          "Velhe"
        ],
        "regions": {
          "PMC": [
            "Shivajinagar",
            "Deccan Gymkhana",
            "Kothrud",
            "Karve Nagar",
            "Erandwane",
            "Warje",
            "Bavdhan",
            "Aundh",
            "Baner",
            "Balewadi",
            "Pashan",
            "Sus",
            "Model Colony",
            "Senapati Bapat Road",
            "Khadki",
            "Yerawada",
            "Kalyani Nagar",
            "Viman Nagar",
            "Dhanori",
            "Lohegaon",
            "Wadgaon Sheri",
            "Kharadi",
            "Chandan Nagar",
            "Hadapsar",
            "Mundhwa",
            "Magarpatta City",
            "Amanora Park Town",
            "Wanowrie",
            "Fatima Nagar",
            "Kondhwa",
            "NIBM Road",
            "Undri",
            "Pisoli",
            "Dhankawadi",
            "Katraj",
            "Bibwewadi",
            "Sahakarnagar",
            "Parvati",
            "Sinhagad Road",
            "Dhayari",
            "Ambegaon",
            "Narhe",
            "Swargate",
            "Camp",
            "Nana Peth",
            "Bhawani Peth",
            "Rasta Peth",
            "Raviwar Peth",
            "Sadashiv Peth",
            "Narayan Peth",
            "Guruwar Peth",
            "Kasba Peth",
            "Ghorpade Peth",
            "Gultekdi",
            "Market Yard",
            "Ghorpuri",
            "Fursungi-side localities",
            "Khadki Bazar",
            "Dapodi-side localities"
          ],
          "PCMC": [
            "Pimpri",
            "Chinchwad",
            "Akurdi",
            "Nigdi",
            "Pradhikaran",
            "Ravet",
            "Kiwale",
            "Mamurdi",
            "Punawale",
            "Tathawade",
            "Wakad",
            "Thergaon",
            "Kalewadi",
            "Rahatani",
            "Pimple Saudagar",
            "Pimple Gurav",
            "Pimple Nilakh",
            "Sangvi",
            "Dapodi",
            "Bhosari",
            "Moshi",
            "Dighi",
            "Chikhali",
            "Charholi Budruk",
            "Dudulgaon",
            "Kudalwadi",
            "Nehrunagar",
            "Kasarwadi",
            "Phugewadi"
          ],
          "Pune Rural and Outskirts": [
            "Shewalewadi",
            "Fursungi",
            "Saswad",
            "Jejuri",
            "Bhor",
            "Velhe",
            "Pirangut",
            "Paud",
            "Mulshi",
            "Lavale",
            "Bhugaon",
            "Bhukum",
            "Hinjawadi",
            "Maan",
            "Marunji",
            "Nere",
            "Gahunje",
            "Talegaon Dabhade",
            "Vadgaon Maval",
            "Lonavala",
            "Kamshet",
            "Chakan",
            "Mahalunge",
            "Rajgurunagar",
            "Khed",
            "Narayangaon",
            "Junnar",
            "Shirur",
            "Daund",
            "Baramati",
            "Indapur",
            "Alandi",
            "Dehu",
            "Panshet",
            "Khadakwasla",
            "Ranjangaon",
            "Shikrapur",
            "Pabal",
            "Manchar",
            "Kalas",
            "Khed Shivapur",
            "Nasrapur",
            "Khandala",
            "Kanhe",
            "Somatane",
            "Varale",
            "Vadgaon Sheri outskirts"
          ]
        }
      },
      "Raigad": {
        "talukas": [
          "Alibag",
          "Karjat",
          "Khalapur",
          "Mahad",
          "Mangaon",
          "Mhasla",
          "Murud",
          "Panvel",
          "Pen",
          "Poladpur",
          "Roha",
          "Shrivardhan",
          "Sudhagad",
          "Tala",
          "Uran"
        ],
        "regions": {
          "Navi Mumbai and Panvel region": [
            "Vashi",
            "Sanpada",
            "Juinagar",
            "Nerul",
            "Seawoods",
            "CBD Belapur",
            "Belapur",
            "Kharghar",
            "Kopar Khairane",
            "Ghansoli",
            "Airoli",
            "Rabale",
            "Turbhe",
            "Pawane",
            "Mahape",
            "TTC Industrial Area",
            "Digha",
            "Bonkode",
            "Juhugaon",
            "Sector 17 Vashi",
            "Sector 15 CBD Belapur",
            "Nerul East",
            "Nerul West",
            "Palm Beach Road localities",
            "Kamothe",
            "Kalamboli",
            "Khandeshwar",
            "New Panvel East",
            "New Panvel West",
            "Pushpak Nagar",
            "Ulwe",
            "Dronagiri",
            "Taloja",
            "Roadpali",
            "Karanjade",
            "Navade",
            "Owe Camp",
            "Pendhar",
            "Rasayani",
            "Uran",
            "JNPT",
            "Nhava-Sheva",
            "Panvel",
            "Old Panvel",
            "Palaspe",
            "Adai",
            "Vichumbe",
            "Sukapur",
            "Khanda Colony",
            "Newale",
            "Chowk",
            "Nere",
            "Poyanje",
            "Chirle",
            "Jaskhar",
            "Bokadvira"
          ],
          "Karjat, Khopoli and nearby areas": [
            "Karjat",
            "Neral",
            "Bhivpuri Road",
            "Shelu",
            "Vangani",
            "Chowk",
            "Khopoli",
            "Khalapur",
            "Pali",
            "Rasayani"
          ]
        }
      },
      "Ratnagiri": {
        "talukas": [
          "Chiplun",
          "Dapoli",
          "Guhagar",
          "Khed",
          "Lanja",
          "Mandangad",
          "Sangameshwar",
          "Ratnagiri",
          "Rajapur"
        ],
        "regions": {}
      },
      "Sangli": {
        "talukas": [
          "Atpadi",
          "Jat",
          "Kadegaon",
          "Kavathe Mahankal",
          "Khanapur",
          "Miraj",
          "Palus",
          "Shirala",
          "Tasgaon",
          "Walwa"
        ],
        "regions": {}
      },
      "Satara": {
        "talukas": [
          "Jaoli",
          "Karad",
          "Khandala",
          "Khatav",
          "Koregaon",
          "Mahabaleshwar",
          "Man",
          "Patan",
          "Phaltan",
          "Satara",
          "Wai"
        ],
        "regions": {}
      },
      "Sindhudurg": {
        "talukas": [
          "Devgad",
          "Dodamarg",
          "Kankavli",
          "Kudal",
          "Malvan",
          "Sawantwadi",
          "Vaibhavwadi",
          "Vengurla"
        ],
        "regions": {}
      },
      "Solapur": {
        "talukas": [
          "Akkalkot",
          "Barshi",
          "Karmala",
          "Madha",
          "Malshiras",
          "Mangalvedhe",
          "Mohol",
          "North Solapur",
          "Pandharpur",
          "Sangole",
          "South Solapur"
        ],
        "regions": {}
      },
      "Thane": {
        "talukas": [
          "Ambernath",
          "Bhiwandi",
          "Kalyan",
          "Murbad",
          "Shahapur",
          "Thane",
          "Ulhasnagar"
        ],
        "regions": {}
      },
      "Wardha": {
        "talukas": [
          "Arvi",
          "Ashti",
          "Deoli",
          "Hinganghat",
          "Karanja",
          "Samudrapur",
          "Seloo",
          "Wardha"
        ],
        "regions": {}
      },
      "Washim": {
        "talukas": [
          "Karanja",
          "Malegaon",
          "Mangrulpir",
          "Manora",
          "Risod",
          "Washim"
        ],
        "regions": {}
      },
      "Yavatmal": {
        "talukas": [
          "Arni",
          "Babhulgaon",
          "Darwha",
          "Digras",
          "Ghatanji",
          "Kalamb",
          "Kelapur",
          "Mahagaon",
          "Maregaon",
          "Ner",
          "Pusad",
          "Ralegaon",
          "Umarkhed",
          "Wani",
          "Yavatmal",
          "Zari-Jamani"
        ],
        "regions": {}
      }
    }
  }
};

    data.getCountries = function() { return this.countries; };
    data.getStates = function(country) { return this.statesByCountry[country] || []; };
    data.getDistricts = function(state) { return this.districtsByState[state] || []; };
    data.getTalukas = function(district) { return this.talukasByDistrict[district] || []; };
    data.getRegions = function(district) { return this.regionsByDistrict[district] || []; };
    data.getAreas = function(district, region) {
        if (!district) return [];
        if (!region || region === 'all') return this.getAllAreas(district);
        return (this.areasByDistrictAndRegion[district] && this.areasByDistrictAndRegion[district][region]) || [];
    };
    data.getAllAreas = function(district) { return this.allAreasByDistrict[district] || []; };
    data.resolveLocation = function(text, districtHint, talukaHint) {
        if (!text) text = '';
        const lower = String(text).toLowerCase();
        for (const [areaKey, info] of Object.entries(this.areaToRegion)) {
            if (lower.includes(areaKey)) {
                return { area: info.area, region: info.region, district: info.district, taluka: info.taluka || talukaHint || '' };
            }
        }
        if (lower.includes('pcmc') || (districtHint === 'Pune' && lower.includes('pimpri'))) {
            return { area: '', region: 'PCMC', district: 'Pune', taluka: talukaHint || 'Haveli' };
        }
        if (lower.includes('pmc') || (districtHint === 'Pune' && lower.includes('pune city'))) {
            return { area: '', region: 'PMC', district: 'Pune', taluka: talukaHint || 'Pune City' };
        }
        return { area: '', region: '', district: districtHint || '', taluka: talukaHint || '' };
    };
    data.renderAreaRegionBadge = function(area, region) {
        if (!area && !region) return '';
        const label = [region, area].filter(Boolean).join(' • ');
        return `<span class="badge badge-area" style="background: rgba(37, 99, 235, 0.08); color: #1d4ed8; border: 1px solid rgba(59, 130, 246, 0.3); font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 10px; display: inline-flex; align-items: center; gap: 4px;" title="Area / Region"><i class="fa-solid fa-location-crosshairs" style="font-size: 9px;"></i> ${label}</span>`;
    };

    window.LOCATION_DATA = data;
})(typeof window !== 'undefined' ? window : globalThis);
