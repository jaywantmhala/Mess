const fs = require('fs');
const mhJson = JSON.parse(fs.readFileSync('d:/flutter/first_demo/backend/admin/data/maharashtra_locations.json', 'utf8'));

const otherTalukas = {
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
};

const baseData = {
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
    'Maharashtra': Object.keys(mhJson.districts).sort(),
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar', 'Gandhinagar'],
    'Karnataka': ['Bengaluru Urban', 'Bengaluru Rural', 'Mysuru', 'Mangaluru', 'Hubballi-Dharwad', 'Belagavi'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Varanasi', 'Agra', 'Noida', 'Ghaziabad', 'Prayagraj'],
    'Delhi': ['New Delhi', 'North Delhi', 'South Delhi', 'East Delhi', 'West Delhi']
  },
  talukasByDistrict: { ...otherTalukas },
  regionsByDistrict: {},
  areasByDistrictAndRegion: {},
  allAreasByDistrict: {},
  areaToRegion: {},
  rawMaharashtra: mhJson
};

for (const [distName, distVal] of Object.entries(mhJson.districts)) {
  baseData.talukasByDistrict[distName] = distVal.talukas || [];
  baseData.regionsByDistrict[distName] = Object.keys(distVal.regions || {});
  baseData.areasByDistrictAndRegion[distName] = distVal.regions || {};
  
  const allAreas = new Set();
  for (const [regName, areas] of Object.entries(distVal.regions || {})) {
    for (const a of areas) {
      allAreas.add(a);
      baseData.areaToRegion[a.toLowerCase()] = {
        area: a,
        region: regName,
        district: distName,
        taluka: (distName === 'Pune' ? (regName === 'PMC' ? 'Pune City' : 'Haveli') : (distName === 'Palghar' ? 'Vasai' : (distName === 'Raigad' ? 'Panvel' : '')))
      };
    }
  }
  baseData.allAreasByDistrict[distName] = Array.from(allAreas).sort();
}

// Add legacy aliases
baseData.talukasByDistrict['Ahmednagar'] = baseData.talukasByDistrict['Ahilyanagar'];
baseData.talukasByDistrict['Aurangabad'] = baseData.talukasByDistrict['Chhatrapati Sambhajinagar'];
baseData.talukasByDistrict['Osmanabad'] = baseData.talukasByDistrict['Dharashiv'];

const jsContent = `/**
 * Omni Admin Panel - Comprehensive Location & Region Hierarchy
 * Generated from maharashtra_locations.json
 */
(function(window) {
    const data = ${JSON.stringify(baseData, null, 2)};

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
        return \`<span class="badge badge-area" style="background: rgba(37, 99, 235, 0.08); color: #1d4ed8; border: 1px solid rgba(59, 130, 246, 0.3); font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 10px; display: inline-flex; align-items: center; gap: 4px;" title="Area / Region"><i class="fa-solid fa-location-crosshairs" style="font-size: 9px;"></i> \${label}</span>\`;
    };

    window.LOCATION_DATA = data;
})(typeof window !== 'undefined' ? window : globalThis);
`;

fs.writeFileSync('d:/flutter/first_demo/backend/admin/js/locations.js', jsContent, 'utf8');
console.log('locations.js generated successfully! File size:', fs.statSync('d:/flutter/first_demo/backend/admin/js/locations.js').size);
