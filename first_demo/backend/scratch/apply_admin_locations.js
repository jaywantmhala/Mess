const fs = require('fs');
const filePath = 'd:/flutter/first_demo/backend/admin/js/app.js';
let code = fs.readFileSync(filePath, 'utf8');

// Normalize line endings for replacement search
const isCRLF = code.includes('\r\n');
const nl = isCRLF ? '\r\n' : '\n';

function replaceBlock(source, targetLines, replacementLines, stepName) {
    const target = targetLines.join(nl);
    const replacement = replacementLines.join(nl);
    if (source.includes(target)) {
        console.log(`[SUCCESS] ${stepName}`);
        return source.replace(target, replacement);
    }
    const altTarget = targetLines.join('\n');
    const altReplacement = replacementLines.join('\n');
    if (source.includes(altTarget)) {
        console.log(`[SUCCESS alt] ${stepName}`);
        return source.replace(altTarget, altReplacement);
    }
    console.warn(`[WARNING] Target not found for: ${stepName}`);
    return source;
}

// 1. In loadVendorsView: wire up region & area selectors
code = replaceBlock(code, [
    '        const updateTalukaOptions = () => {',
    '            const district = districtSelect.value;',
    '            const talukas = LOCATION_DATA.talukasByDistrict[district] || [];',
    '            talukaSelect.innerHTML = \'<option value="all">🏘️ All Talukas</option>\' + ',
    '                talukas.map(t => `<option value="${t}" ${this.vendorQuery.taluka === t ? \'selected\' : \'\'}>${t}</option>`).join(\'\');',
    '        };'
], [
    '        const regionSelect   = document.getElementById(\'vendor-region-filter\');',
    '        const areaSelect     = document.getElementById(\'vendor-area-filter\');',
    '',
    '        const updateTalukaOptions = () => {',
    '            const district = districtSelect.value;',
    '            const talukas = (LOCATION_DATA.talukasByDistrict && LOCATION_DATA.talukasByDistrict[district]) || [];',
    '            talukaSelect.innerHTML = \'<option value="all">🏘️ All Talukas</option>\' + ',
    '                talukas.map(t => `<option value="${t}" ${this.vendorQuery.taluka === t ? \'selected\' : \'\'}>${t}</option>`).join(\'\');',
    '        };',
    '',
    '        const updateRegionOptions = () => {',
    '            if (!regionSelect) return;',
    '            const district = districtSelect.value;',
    '            const regions = (district !== \'all\' && typeof LOCATION_DATA.getRegions === \'function\') ? LOCATION_DATA.getRegions(district) : [];',
    '            regionSelect.innerHTML = \'<option value="all">🏙️ All Regions</option>\' + ',
    '                regions.map(r => `<option value="${r}" ${this.vendorQuery.region === r ? \'selected\' : \'\'}>${r}</option>`).join(\'\');',
    '        };',
    '',
    '        const updateAreaOptions = () => {',
    '            if (!areaSelect) return;',
    '            const district = districtSelect.value;',
    '            const region = regionSelect ? regionSelect.value : \'all\';',
    '            let areas = [];',
    '            if (district !== \'all\' && typeof LOCATION_DATA.getAreas === \'function\') {',
    '                areas = LOCATION_DATA.getAreas(district, region);',
    '            }',
    '            areaSelect.innerHTML = \'<option value="all">📍 All Areas</option>\' + ',
    '                areas.map(a => `<option value="${a}" ${this.vendorQuery.area === a ? \'selected\' : \'\'}>${a}</option>`).join(\'\');',
    '        };'
], '1. Vendor Region/Area wiring');

// 2. Cascade calls in vendor view
code = replaceBlock(code, [
    '        // Initial option cascade',
    '        updateStateOptions();',
    '        updateDistrictOptions();',
    '        updateTalukaOptions();'
], [
    '        // Initial option cascade',
    '        updateStateOptions();',
    '        updateDistrictOptions();',
    '        updateTalukaOptions();',
    '        updateRegionOptions();',
    '        updateAreaOptions();'
], '2. Vendor cascade init');

// 3. Vendor event listeners
code = replaceBlock(code, [
    '        districtSelect.addEventListener(\'change\', (e) => {',
    '            this.vendorQuery.district = e.target.value === \'all\' ? \'\' : e.target.value;',
    '            this.vendorQuery.taluka = \'\';',
    '            this.vendorQuery.page = 1;',
    '            updateTalukaOptions();',
    '            this.fetchVendorsList();',
    '        });',
    '',
    '        talukaSelect.addEventListener(\'change\', (e) => {',
    '            this.vendorQuery.taluka = e.target.value === \'all\' ? \'\' : e.target.value;',
    '            this.vendorQuery.page = 1;',
    '            this.fetchVendorsList();',
    '        });'
], [
    '        districtSelect.addEventListener(\'change\', (e) => {',
    '            this.vendorQuery.district = e.target.value === \'all\' ? \'\' : e.target.value;',
    '            this.vendorQuery.taluka = \'\';',
    '            this.vendorQuery.region = \'\';',
    '            this.vendorQuery.area = \'\';',
    '            this.vendorQuery.page = 1;',
    '            updateTalukaOptions();',
    '            updateRegionOptions();',
    '            updateAreaOptions();',
    '            this.fetchVendorsList();',
    '        });',
    '',
    '        talukaSelect.addEventListener(\'change\', (e) => {',
    '            this.vendorQuery.taluka = e.target.value === \'all\' ? \'\' : e.target.value;',
    '            this.vendorQuery.page = 1;',
    '            this.fetchVendorsList();',
    '        });',
    '',
    '        if (regionSelect) {',
    '            regionSelect.addEventListener(\'change\', (e) => {',
    '                this.vendorQuery.region = e.target.value === \'all\' ? \'\' : e.target.value;',
    '                this.vendorQuery.area = \'\';',
    '                this.vendorQuery.page = 1;',
    '                updateAreaOptions();',
    '                this.fetchVendorsList();',
    '            });',
    '        }',
    '',
    '        if (areaSelect) {',
    '            areaSelect.addEventListener(\'change\', (e) => {',
    '                this.vendorQuery.area = e.target.value === \'all\' ? \'\' : e.target.value;',
    '                this.vendorQuery.page = 1;',
    '                this.fetchVendorsList();',
    '            });',
    '        }'
], '3. Vendor event listeners');

// 4. In fetchVendorsList: add Area & Region badge to vendor rows
code = replaceBlock(code, [
    '                return `',
    '                    <tr style="${isOnline ? \'background: rgba(16, 185, 129, 0.02);\' : \'\'}">',
    '                        <td><strong>#${vendor.id}</strong></td>',
    '                        <td>',
    '                            <div style="display: flex; flex-direction: column;">',
    '                                <span class="font-semibold" style="display: flex; align-items: center; gap: 6px;">',
    '                                    ${this.escapeHtml(vendor.full_name)}',
    '                                </span>',
    '                                <span style="font-size: 11px; color: var(--text-muted);"><i class="fa-solid fa-phone"></i> ${this.escapeHtml(vendor.phone || \'N/A\')}</span>',
    '                            </div>',
    '                        </td>'
], [
    '                const hotelAddr = (vendor.hotels && vendor.hotels[0] && vendor.hotels[0].hotel_address) || vendor.business_name || \'\';',
    '                const hotelName = (vendor.hotels && vendor.hotels[0] && vendor.hotels[0].hotel_name) || \'\';',
    '                const resolvedLoc = (typeof LOCATION_DATA !== \'undefined\' && typeof LOCATION_DATA.resolveLocation === \'function\')',
    '                    ? LOCATION_DATA.resolveLocation(hotelAddr + \' \' + (vendor.taluka || \'\') + \' \' + hotelName, vendor.district, vendor.taluka)',
    '                    : { area: \'\', region: \'\' };',
    '                const areaBadge = (typeof LOCATION_DATA !== \'undefined\' && typeof LOCATION_DATA.renderAreaRegionBadge === \'function\')',
    '                    ? LOCATION_DATA.renderAreaRegionBadge(resolvedLoc.area, resolvedLoc.region)',
    '                    : \'\';',
    '',
    '                return `',
    '                    <tr style="${isOnline ? \'background: rgba(16, 185, 129, 0.02);\' : \'\'}">',
    '                        <td><strong>#${vendor.id}</strong></td>',
    '                        <td>',
    '                            <div style="display: flex; flex-direction: column; gap: 2px;">',
    '                                <span class="font-semibold" style="display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">',
    '                                    ${this.escapeHtml(vendor.full_name)}',
    '                                    ${areaBadge}',
    '                                </span>',
    '                                <span style="font-size: 11px; color: var(--text-muted);"><i class="fa-solid fa-phone"></i> ${this.escapeHtml(vendor.phone || \'N/A\')}</span>',
    '                                ${hotelAddr ? `<span style="font-size: 10px; color: var(--text-muted); max-width: 220px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;"><i class="fa-solid fa-location-dot" style="font-size: 9px; color: #fe750b;"></i> ${this.escapeHtml(hotelAddr)}</span>` : \'\'}',
    '                            </div>',
    '                        </td>'
], '4. Vendor row Area/Region badge');

// 5. In loadUsersView: add Region and Area dropdown filters
code = replaceBlock(code, [
    '                <select id="user-taluka-filter" class="filter-select" style="min-width: 150px;">',
    '                    <option value="all">🏘️ All Talukas</option>',
    '                </select>'
], [
    '                <select id="user-taluka-filter" class="filter-select" style="min-width: 150px;">',
    '                    <option value="all">🏘️ All Talukas</option>',
    '                </select>',
    '',
    '                <select id="user-region-filter" class="filter-select" style="min-width: 150px;">',
    '                    <option value="all">🏙️ All Regions</option>',
    '                </select>',
    '',
    '                <select id="user-area-filter" class="filter-select" style="min-width: 150px;">',
    '                    <option value="all">📍 All Areas</option>',
    '                </select>'
], '5. User filter HTML');

// 6. In loadUsersView: wiring for user region & area filters
code = replaceBlock(code, [
    '        const updateTalukaOptions = () => {',
    '            const district = districtSelect.value;',
    '            const talukas = LOCATION_DATA.talukasByDistrict[district] || [];',
    '            talukaSelect.innerHTML = \'<option value="all">🏘️ All Talukas</option>\' + ',
    '                talukas.map(t => `<option value="${t}" ${this.userQuery.taluka === t ? \'selected\' : \'\'}>${t}</option>`).join(\'\');',
    '        };',
    '',
    '        // Initial option cascade',
    '        updateStateOptions();',
    '        updateDistrictOptions();',
    '        updateTalukaOptions();'
], [
    '        const regionSelect   = document.getElementById(\'user-region-filter\');',
    '        const areaSelect     = document.getElementById(\'user-area-filter\');',
    '',
    '        const updateTalukaOptions = () => {',
    '            const district = districtSelect.value;',
    '            const talukas = (LOCATION_DATA.talukasByDistrict && LOCATION_DATA.talukasByDistrict[district]) || [];',
    '            talukaSelect.innerHTML = \'<option value="all">🏘️ All Talukas</option>\' + ',
    '                talukas.map(t => `<option value="${t}" ${this.userQuery.taluka === t ? \'selected\' : \'\'}>${t}</option>\`).join(\'\');',
    '        };',
    '',
    '        const updateRegionOptions = () => {',
    '            if (!regionSelect) return;',
    '            const district = districtSelect.value;',
    '            const regions = (district !== \'all\' && typeof LOCATION_DATA.getRegions === \'function\') ? LOCATION_DATA.getRegions(district) : [];',
    '            regionSelect.innerHTML = \'<option value="all">🏙️ All Regions</option>\' + ',
    '                regions.map(r => `<option value="${r}" ${this.userQuery.region === r ? \'selected\' : \'\'}>${r}</option>\`).join(\'\');',
    '        };',
    '',
    '        const updateAreaOptions = () => {',
    '            if (!areaSelect) return;',
    '            const district = districtSelect.value;',
    '            const region = regionSelect ? regionSelect.value : \'all\';',
    '            let areas = [];',
    '            if (district !== \'all\' && typeof LOCATION_DATA.getAreas === \'function\') {',
    '                areas = LOCATION_DATA.getAreas(district, region);',
    '            }',
    '            areaSelect.innerHTML = \'<option value="all">📍 All Areas</option>\' + ',
    '                areas.map(a => `<option value="${a}" ${this.userQuery.area === a ? \'selected\' : \'\'}>${a}</option>\`).join(\'\');',
    '        };',
    '',
    '        // Initial option cascade',
    '        updateStateOptions();',
    '        updateDistrictOptions();',
    '        updateTalukaOptions();',
    '        updateRegionOptions();',
    '        updateAreaOptions();'
], '6. User Region/Area wiring');

// 7. In loadUsersView: user filter event listeners
code = replaceBlock(code, [
    '        districtSelect.addEventListener(\'change\', (e) => {',
    '            this.userQuery.district = e.target.value === \'all\' ? \'\' : e.target.value;',
    '            this.userQuery.taluka = \'\';',
    '            this.userQuery.page = 1;',
    '            updateTalukaOptions();',
    '            this.fetchUsersList();',
    '        });',
    '',
    '        talukaSelect.addEventListener(\'change\', (e) => {',
    '            this.userQuery.taluka = e.target.value === \'all\' ? \'\' : e.target.value;',
    '            this.userQuery.page = 1;',
    '            this.fetchUsersList();',
    '        });'
], [
    '        districtSelect.addEventListener(\'change\', (e) => {',
    '            this.userQuery.district = e.target.value === \'all\' ? \'\' : e.target.value;',
    '            this.userQuery.taluka = \'\';',
    '            this.userQuery.region = \'\';',
    '            this.userQuery.area = \'\';',
    '            this.userQuery.page = 1;',
    '            updateTalukaOptions();',
    '            updateRegionOptions();',
    '            updateAreaOptions();',
    '            this.fetchUsersList();',
    '        });',
    '',
    '        talukaSelect.addEventListener(\'change\', (e) => {',
    '            this.userQuery.taluka = e.target.value === \'all\' ? \'\' : e.target.value;',
    '            this.userQuery.page = 1;',
    '            this.fetchUsersList();',
    '        });',
    '',
    '        if (regionSelect) {',
    '            regionSelect.addEventListener(\'change\', (e) => {',
    '                this.userQuery.region = e.target.value === \'all\' ? \'\' : e.target.value;',
    '                this.userQuery.area = \'\';',
    '                this.userQuery.page = 1;',
    '                updateAreaOptions();',
    '                this.fetchUsersList();',
    '            });',
    '        }',
    '',
    '        if (areaSelect) {',
    '            areaSelect.addEventListener(\'change\', (e) => {',
    '                this.userQuery.area = e.target.value === \'all\' ? \'\' : e.target.value;',
    '                this.userQuery.page = 1;',
    '                this.fetchUsersList();',
    '            });',
    '        }'
], '7. User filter event listeners');

// 8. In fetchUsersList: show Area & Region badge in user table row
code = replaceBlock(code, [
    '                const userLoc = [user.taluka, user.district, user.state, user.country || \'India\'].filter(Boolean).join(\', \');',
    '',
    '                return `'
], [
    '                const userLoc = [user.taluka, user.district, user.state, user.country || \'India\'].filter(Boolean).join(\', \');',
    '                const resolvedUserLoc = (typeof LOCATION_DATA !== \'undefined\' && typeof LOCATION_DATA.resolveLocation === \'function\')',
    '                    ? LOCATION_DATA.resolveLocation((user.full_address || user.address || \'\') + \' \' + (user.taluka || \'\') + \' \' + (user.city || \'\'), user.district, user.taluka)',
    '                    : { area: \'\', region: \'\' };',
    '                const userAreaBadge = (typeof LOCATION_DATA !== \'undefined\' && typeof LOCATION_DATA.renderAreaRegionBadge === \'function\')',
    '                    ? LOCATION_DATA.renderAreaRegionBadge(resolvedUserLoc.area, resolvedUserLoc.region)',
    '                    : \'\';',
    '',
    '                return `'
], '8. User row resolved location');

// In user row markup: add userAreaBadge beside location dot
code = replaceBlock(code, [
    '                                    <span style="font-size: 11px; color: #2563eb; font-weight: 500;"><i class="fa-solid fa-location-dot"></i> ${userLoc}</span>'
], [
    '                                    <span style="font-size: 11px; color: #2563eb; font-weight: 500; display: flex; align-items: center; gap: 6px; flex-wrap: wrap;">',
    '                                        <i class="fa-solid fa-location-dot"></i> ${userLoc}',
    '                                        ${userAreaBadge}',
    '                                    </span>'
], '8b. User row badge display');

// 9. In Service Areas view (fetchLocationList): show Area & Region badge
code = replaceBlock(code, [
    '                        <td><strong style="color: var(--accent-primary); font-size: 15px;">${item.location_name}</strong><br><small style="color:var(--text-muted);">${item.address || \'\'}</small></td>'
], [
    '                        <td>',
    '                            <div style="display: flex; align-items: center; gap: 8px; flex-wrap: wrap;">',
    '                                <strong style="color: var(--accent-primary); font-size: 15px;">${item.location_name}</strong>',
    '                                ${(function() {',
    '                                    const rLoc = (typeof LOCATION_DATA !== \'undefined\' && typeof LOCATION_DATA.resolveLocation === \'function\')',
    '                                        ? LOCATION_DATA.resolveLocation(item.location_name + \' \' + (item.address || \'\') + \' \' + (item.region || \'\'))',
    '                                        : { area: \'\', region: \'\' };',
    '                                    return (typeof LOCATION_DATA !== \'undefined\' && typeof LOCATION_DATA.renderAreaRegionBadge === \'function\')',
    '                                        ? LOCATION_DATA.renderAreaRegionBadge(rLoc.area || item.location_name, rLoc.region || item.region)',
    '                                        : \'\';',
    '                                })()}',
    '                            </div>',
    '                            <small style="color:var(--text-muted);">${item.address || \'\'}</small>',
    '                        </td>'
], '9. Service area row Area/Region badge');

// 10. In renderLocationForm: add quick hierarchy picker
code = replaceBlock(code, [
    '            <!-- Location Name -->',
    '            <div class="form-group" style="margin-bottom: 16px;">',
    '                <label class="form-label"><i class="fa-solid fa-tag text-primary" style="margin-right: 6px;"></i> Location Name / Service Zones (Comma-separated for multiple areas) <span style="color: var(--danger);">*</span></label>'
], [
    '            <!-- Maharashtra Locations Hierarchy Quick Picker -->',
    '            <div style="background: linear-gradient(135deg, #f0fdf4 0%, #ecfdf5 100%); border: 1.5px solid #a7f3d0; border-radius: 12px; padding: 14px 16px; margin-bottom: 18px;">',
    '                <label style="display: flex; align-items: center; justify-content: space-between; font-weight: 700; color: #065f46; font-size: 13px; margin-bottom: 8px;">',
    '                    <span><i class="fa-solid fa-map-location-dot" style="margin-right: 6px; color: #059669;"></i> Select Area / Region from Maharashtra Locations</span>',
    '                    <span class="badge" style="background: #10b981; color: white; font-size: 10px; font-weight: 800; padding: 2px 8px; border-radius: 12px;">Active JSON</span>',
    '                </label>',
    '                <div style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px;">',
    '                    <div>',
    '                        <span style="font-size: 11px; font-weight: 700; color: #047857; display: block; margin-bottom: 3px;">District</span>',
    '                        <select id="loc-quick-district" class="form-control" style="font-size: 12px; height: 36px; border-color: #6ee7b7; background: #fff;" onchange="app.onQuickLocationDistrictChange()">',
    '                            <option value="">-- Pick District --</option>',
    '                            ${((typeof LOCATION_DATA !== \'undefined\' && LOCATION_DATA.districtsByState && LOCATION_DATA.districtsByState[\'Maharashtra\']) || []).map(d => `<option value="${d}" ${d === \'Pune\' ? \'selected\' : \'\'}>${d}</option>`).join(\'\')}',
    '                        </select>',
    '                    </div>',
    '                    <div>',
    '                        <span style="font-size: 11px; font-weight: 700; color: #047857; display: block; margin-bottom: 3px;">Region (e.g. PMC, PCMC)</span>',
    '                        <select id="loc-quick-region" class="form-control" style="font-size: 12px; height: 36px; border-color: #6ee7b7; background: #fff;" onchange="app.onQuickLocationRegionChange()">',
    '                            <option value="">-- All Regions --</option>',
    '                        </select>',
    '                    </div>',
    '                    <div>',
    '                        <span style="font-size: 11px; font-weight: 700; color: #047857; display: block; margin-bottom: 3px;">Area / Locality</span>',
    '                        <select id="loc-quick-area" class="form-control" style="font-size: 12px; height: 36px; border-color: #6ee7b7; background: #fff;" onchange="app.onQuickLocationAreaSelect()">',
    '                            <option value="">-- Pick Area --</option>',
    '                        </select>',
    '                    </div>',
    '                </div>',
    '                <small style="color: #047857; font-size: 11px; margin-top: 6px; display: block; font-weight: 500;">',
    '                    Picking an area automatically sets Location Name, Region, and geolocates coordinates on the map.',
    '                </small>',
    '            </div>',
    '',
    '            <!-- Location Name -->',
    '            <div class="form-group" style="margin-bottom: 16px;">',
    '                <label class="form-label"><i class="fa-solid fa-tag text-primary" style="margin-right: 6px;"></i> Location Name / Service Zones (Comma-separated for multiple areas) <span style="color: var(--danger);">*</span></label>'
], '10. Quick picker in service area form');

// 11. Add helper methods on App prototype without trailing commas
code = replaceBlock(code, [
    '    openLocationAddModal() {'
], [
    '    onQuickLocationDistrictChange() {',
    '        const dSelect = document.getElementById(\'loc-quick-district\');',
    '        const rSelect = document.getElementById(\'loc-quick-region\');',
    '        const aSelect = document.getElementById(\'loc-quick-area\');',
    '        if (!dSelect || !rSelect || !aSelect) return;',
    '        const district = dSelect.value;',
    '        const regions = (district && typeof LOCATION_DATA.getRegions === \'function\') ? LOCATION_DATA.getRegions(district) : [];',
    '        rSelect.innerHTML = \'<option value="">-- All Regions --</option>\' + regions.map(r => `<option value="${r}">${r}</option>`).join(\'\');',
    '        this.onQuickLocationRegionChange();',
    '    }',
    '',
    '    onQuickLocationRegionChange() {',
    '        const dSelect = document.getElementById(\'loc-quick-district\');',
    '        const rSelect = document.getElementById(\'loc-quick-region\');',
    '        const aSelect = document.getElementById(\'loc-quick-area\');',
    '        if (!dSelect || !aSelect) return;',
    '        const district = dSelect.value;',
    '        const region = rSelect ? rSelect.value : \'\';',
    '        const areas = (district && typeof LOCATION_DATA.getAreas === \'function\') ? LOCATION_DATA.getAreas(district, region) : [];',
    '        aSelect.innerHTML = \'<option value="">-- Pick Area --</option>\' + areas.map(a => `<option value="${a}">${a}</option>`).join(\'\');',
    '    }',
    '',
    '    onQuickLocationAreaSelect() {',
    '        const aSelect = document.getElementById(\'loc-quick-area\');',
    '        const rSelect = document.getElementById(\'loc-quick-region\');',
    '        const dSelect = document.getElementById(\'loc-quick-district\');',
    '        if (!aSelect || !aSelect.value) return;',
    '        const area = aSelect.value;',
    '        const region = rSelect ? rSelect.value : \'\';',
    '        const district = dSelect ? dSelect.value : \'Pune\';',
    '',
    '        const nameInput = document.getElementById(\'loc-location-name\');',
    '        const regionInput = document.getElementById(\'loc-region\');',
    '        const addressInput = document.getElementById(\'loc-address\');',
    '',
    '        if (nameInput) nameInput.value = area;',
    '        if (regionInput) regionInput.value = (region ? region + \', \' : \'\') + district + \', Maharashtra\';',
    '        if (addressInput && !addressInput.value) {',
    '            addressInput.value = area + \', \' + district + \', Maharashtra\';',
    '        }',
    '        if (typeof this.geocodeAddressAndSetPin === \'function\') {',
    '            this.geocodeAddressAndSetPin(area + \', \' + district + \', Maharashtra\');',
    '        }',
    '    }',
    '',
    '    openLocationAddModal() {'
], '11. Quick picker helper methods');

// Verify JavaScript syntax
new Function(code);
console.log('ALL CHECKS PASSED: Modified app.js syntax is 100% VALID!');

fs.writeFileSync(filePath, code, 'utf8');
console.log('Successfully saved app.js! New size:', fs.statSync(filePath).size);
