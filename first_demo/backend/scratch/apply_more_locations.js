const fs = require('fs');
const filePath = 'd:/flutter/first_demo/backend/admin/js/app.js';
let code = fs.readFileSync(filePath, 'utf8');

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

// 1. Add driver region & area filter HTML
code = replaceBlock(code, [
    '                <select id="driver-taluka-filter" class="filter-select" style="min-width: 150px;">',
    '                    <option value="all">🏘️ All Talukas</option>',
    '                </select>'
], [
    '                <select id="driver-taluka-filter" class="filter-select" style="min-width: 150px;">',
    '                    <option value="all">🏘️ All Talukas</option>',
    '                </select>',
    '',
    '                <select id="driver-region-filter" class="filter-select" style="min-width: 150px;">',
    '                    <option value="all">🏙️ All Regions</option>',
    '                </select>',
    '',
    '                <select id="driver-area-filter" class="filter-select" style="min-width: 150px;">',
    '                    <option value="all">📍 All Areas</option>',
    '                </select>'
], '1. Driver filter HTML');

// 2. Wire driver region & area selectors
code = replaceBlock(code, [
    '        const updateTalukaOptions = () => {',
    '            const district = districtSelect.value;',
    '            const talukas = LOCATION_DATA.talukasByDistrict[district] || [];',
    '            talukaSelect.innerHTML = \'<option value="all">🏘️ All Talukas</option>\' + ',
    '                talukas.map(t => `<option value="${t}" ${this.driverQuery.taluka === t ? \'selected\' : \'\'}>${t}</option>`).join(\'\');',
    '        };',
    '',
    '        // Initial option cascade',
    '        updateStateOptions();',
    '        updateDistrictOptions();',
    '        updateTalukaOptions();'
], [
    '        const regionSelect   = document.getElementById(\'driver-region-filter\');',
    '        const areaSelect     = document.getElementById(\'driver-area-filter\');',
    '',
    '        const updateTalukaOptions = () => {',
    '            const district = districtSelect.value;',
    '            const talukas = (LOCATION_DATA.talukasByDistrict && LOCATION_DATA.talukasByDistrict[district]) || [];',
    '            talukaSelect.innerHTML = \'<option value="all">🏘️ All Talukas</option>\' + ',
    '                talukas.map(t => `<option value="${t}" ${this.driverQuery.taluka === t ? \'selected\' : \'\'}>${t}</option>`).join(\'\');',
    '        };',
    '',
    '        const updateRegionOptions = () => {',
    '            if (!regionSelect) return;',
    '            const district = districtSelect.value;',
    '            const regions = (district !== \'all\' && typeof LOCATION_DATA.getRegions === \'function\') ? LOCATION_DATA.getRegions(district) : [];',
    '            regionSelect.innerHTML = \'<option value="all">🏙️ All Regions</option>\' + ',
    '                regions.map(r => `<option value="${r}" ${this.driverQuery.region === r ? \'selected\' : \'\'}>${r}</option>\`).join(\'\');',
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
    '                areas.map(a => `<option value="${a}" ${this.driverQuery.area === a ? \'selected\' : \'\'}>${a}</option>\`).join(\'\');',
    '        };',
    '',
    '        // Initial option cascade',
    '        updateStateOptions();',
    '        updateDistrictOptions();',
    '        updateTalukaOptions();',
    '        updateRegionOptions();',
    '        updateAreaOptions();'
], '2. Driver Region/Area wiring');

// 3. Driver event listeners
code = replaceBlock(code, [
    '        districtSelect.addEventListener(\'change\', (e) => {',
    '            this.driverQuery.district = e.target.value === \'all\' ? \'\' : e.target.value;',
    '            this.driverQuery.taluka = \'\';',
    '            this.driverQuery.page = 1;',
    '            updateTalukaOptions();',
    '            this.fetchDriversList();',
    '        });',
    '',
    '        talukaSelect.addEventListener(\'change\', (e) => {',
    '            this.driverQuery.taluka = e.target.value === \'all\' ? \'\' : e.target.value;',
    '            this.driverQuery.page = 1;',
    '            this.fetchDriversList();',
    '        });'
], [
    '        districtSelect.addEventListener(\'change\', (e) => {',
    '            this.driverQuery.district = e.target.value === \'all\' ? \'\' : e.target.value;',
    '            this.driverQuery.taluka = \'\';',
    '            this.driverQuery.region = \'\';',
    '            this.driverQuery.area = \'\';',
    '            this.driverQuery.page = 1;',
    '            updateTalukaOptions();',
    '            updateRegionOptions();',
    '            updateAreaOptions();',
    '            this.fetchDriversList();',
    '        });',
    '',
    '        talukaSelect.addEventListener(\'change\', (e) => {',
    '            this.driverQuery.taluka = e.target.value === \'all\' ? \'\' : e.target.value;',
    '            this.driverQuery.page = 1;',
    '            this.fetchDriversList();',
    '        });',
    '',
    '        if (regionSelect) {',
    '            regionSelect.addEventListener(\'change\', (e) => {',
    '                this.driverQuery.region = e.target.value === \'all\' ? \'\' : e.target.value;',
    '                this.driverQuery.area = \'\';',
    '                this.driverQuery.page = 1;',
    '                updateAreaOptions();',
    '                this.fetchDriversList();',
    '            });',
    '        }',
    '',
    '        if (areaSelect) {',
    '            areaSelect.addEventListener(\'change\', (e) => {',
    '                this.driverQuery.area = e.target.value === \'all\' ? \'\' : e.target.value;',
    '                this.driverQuery.page = 1;',
    '                this.fetchDriversList();',
    '            });',
    '        }'
], '3. Driver filter listeners');

// 4. In fetchDriversList: driver row Area/Region badge
code = replaceBlock(code, [
    '                const locationStr = [driver.taluka, driver.district, driver.state, driver.country].filter(Boolean).join(\', \') || \'Not set\';'
], [
    '                const locationStr = [driver.taluka, driver.district, driver.state, driver.country].filter(Boolean).join(\', \') || \'Not set\';',
    '                const resolvedDriverLoc = (typeof LOCATION_DATA !== \'undefined\' && typeof LOCATION_DATA.resolveLocation === \'function\')',
    '                    ? LOCATION_DATA.resolveLocation((driver.address || \'\') + \' \' + (driver.taluka || \'\'), driver.district, driver.taluka)',
    '                    : { area: \'\', region: \'\' };',
    '                const driverAreaBadge = (typeof LOCATION_DATA !== \'undefined\' && typeof LOCATION_DATA.renderAreaRegionBadge === \'function\')',
    '                    ? LOCATION_DATA.renderAreaRegionBadge(resolvedDriverLoc.area, resolvedDriverLoc.region)',
    '                    : \'\';'
], '4. Driver row resolved location');

// In driver row location cell: append badge
code = replaceBlock(code, [
    '                        <td><span style="font-size: 12px; color: var(--text-secondary);"><i class="fa-solid fa-location-dot" style="margin-right: 4px; color: #64748b;"></i>${this.escapeHtml(locationStr)}</span></td>'
], [
    '                        <td>',
    '                            <div style="display: flex; flex-direction: column; gap: 3px;">',
    '                                <span style="font-size: 12px; color: var(--text-secondary);"><i class="fa-solid fa-location-dot" style="margin-right: 4px; color: #64748b;"></i>${this.escapeHtml(locationStr)}</span>',
    '                                ${driverAreaBadge}',
    '                            </div>',
    '                        </td>'
], '4b. Driver row location cell');

// 5. In WhatsApp broadcast: add region and area selector dropdowns
code = replaceBlock(code, [
    '                        <div>',
    '                            <label class="wa-label" style="font-size: 11px;">Taluka</label>',
    '                            <select id="wa-taluka" class="wa-input" onchange="app.onWhatsAppLocationFilterChange(\'taluka\')">',
    '                                <option value="all">🏘️ All Talukas</option>',
    '                            </select>',
    '                        </div>'
], [
    '                        <div>',
    '                            <label class="wa-label" style="font-size: 11px;">Taluka</label>',
    '                            <select id="wa-taluka" class="wa-input" onchange="app.onWhatsAppLocationFilterChange(\'taluka\')">',
    '                                <option value="all">🏘️ All Talukas</option>',
    '                            </select>',
    '                        </div>',
    '                        <div>',
    '                            <label class="wa-label" style="font-size: 11px;">Region</label>',
    '                            <select id="wa-region" class="wa-input" onchange="app.onWhatsAppLocationFilterChange(\'region\')">',
    '                                <option value="all">🏙️ All Regions</option>',
    '                            </select>',
    '                        </div>',
    '                        <div>',
    '                            <label class="wa-label" style="font-size: 11px;">Area / Zone</label>',
    '                            <select id="wa-area" class="wa-input" onchange="app.onWhatsAppLocationFilterChange(\'area\')">',
    '                                <option value="all">📍 All Areas</option>',
    '                            </select>',
    '                        </div>'
], '5. WhatsApp region & area filter HTML');

// 6. In onWhatsAppLocationFilterChange: cascade region & area
code = replaceBlock(code, [
    '    onWhatsAppLocationFilterChange(level) {',
    '        const stateSelect = document.getElementById(\'wa-state\');',
    '        const districtSelect = document.getElementById(\'wa-district\');',
    '        const talukaSelect = document.getElementById(\'wa-taluka\');',
    '',
    '        const state = stateSelect?.value || \'all\';',
    '',
    '        if (level === \'state\' && districtSelect) {',
    '            const districts = (state !== \'all\' && LOCATION_DATA.districtsByState[state]) ? LOCATION_DATA.districtsByState[state] : [];',
    '            districtSelect.innerHTML = \'<option value="all">📍 All Districts</option>\' +',
    '                districts.map(d => `<option value="${d}">${d}</option>`).join(\'\');',
    '            if (talukaSelect) talukaSelect.innerHTML = \'<option value="all">🏘️ All Talukas</option>\';',
    '        }',
    '',
    '        if (level === \'district\' && districtSelect && talukaSelect) {',
    '            const selectedDistrict = districtSelect.value;',
    '            const talukas = (selectedDistrict !== \'all\' && LOCATION_DATA.talukasByDistrict[selectedDistrict]) ? LOCATION_DATA.talukasByDistrict[selectedDistrict] : [];',
    '            talukaSelect.innerHTML = \'<option value="all">🏘️ All Talukas</option>\' +',
    '                talukas.map(t => `<option value="${t}">${t}</option>`).join(\'\');',
    '        }',
    '',
    '        this.fetchWhatsAppTargetSummary();',
    '        this.updateWhatsAppPreview();',
    '    }'
], [
    '    onWhatsAppLocationFilterChange(level) {',
    '        const stateSelect = document.getElementById(\'wa-state\');',
    '        const districtSelect = document.getElementById(\'wa-district\');',
    '        const talukaSelect = document.getElementById(\'wa-taluka\');',
    '        const regionSelect = document.getElementById(\'wa-region\');',
    '        const areaSelect = document.getElementById(\'wa-area\');',
    '',
    '        const state = stateSelect?.value || \'all\';',
    '',
    '        if (level === \'state\' && districtSelect) {',
    '            const districts = (state !== \'all\' && LOCATION_DATA.districtsByState[state]) ? LOCATION_DATA.districtsByState[state] : [];',
    '            districtSelect.innerHTML = \'<option value="all">📍 All Districts</option>\' +',
    '                districts.map(d => `<option value="${d}">${d}</option>`).join(\'\');',
    '            if (talukaSelect) talukaSelect.innerHTML = \'<option value="all">🏘️ All Talukas</option>\';',
    '            if (regionSelect) regionSelect.innerHTML = \'<option value="all">🏙️ All Regions</option>\';',
    '            if (areaSelect) areaSelect.innerHTML = \'<option value="all">📍 All Areas</option>\';',
    '        }',
    '',
    '        if (level === \'district\' && districtSelect) {',
    '            const selectedDistrict = districtSelect.value;',
    '            const talukas = (selectedDistrict !== \'all\' && LOCATION_DATA.talukasByDistrict[selectedDistrict]) ? LOCATION_DATA.talukasByDistrict[selectedDistrict] : [];',
    '            if (talukaSelect) {',
    '                talukaSelect.innerHTML = \'<option value="all">🏘️ All Talukas</option>\' +',
    '                    talukas.map(t => `<option value="${t}">${t}</option>`).join(\'\');',
    '            }',
    '            if (regionSelect && typeof LOCATION_DATA.getRegions === \'function\') {',
    '                const regions = selectedDistrict !== \'all\' ? LOCATION_DATA.getRegions(selectedDistrict) : [];',
    '                regionSelect.innerHTML = \'<option value="all">🏙️ All Regions</option>\' +',
    '                    regions.map(r => `<option value="${r}">${r}</option>`).join(\'\');',
    '            }',
    '            if (areaSelect && typeof LOCATION_DATA.getAllAreas === \'function\') {',
    '                const areas = selectedDistrict !== \'all\' ? LOCATION_DATA.getAllAreas(selectedDistrict) : [];',
    '                areaSelect.innerHTML = \'<option value="all">📍 All Areas</option>\' +',
    '                    areas.map(a => `<option value="${a}">${a}</option>`).join(\'\');',
    '            }',
    '        }',
    '',
    '        if (level === \'region\' && regionSelect && areaSelect && typeof LOCATION_DATA.getAreas === \'function\') {',
    '            const selectedDistrict = districtSelect?.value || \'\';',
    '            const selectedRegion = regionSelect.value;',
    '            const areas = selectedDistrict !== \'all\' ? LOCATION_DATA.getAreas(selectedDistrict, selectedRegion) : [];',
    '            areaSelect.innerHTML = \'<option value="all">📍 All Areas</option>\' +',
    '                areas.map(a => `<option value="${a}">${a}</option>`).join(\'\');',
    '        }',
    '',
    '        this.fetchWhatsAppTargetSummary();',
    '        this.updateWhatsAppPreview();',
    '    }'
], '6. WhatsApp location cascade');

// Verify JavaScript syntax
new Function(code);
console.log('ALL CHECKS PASSED: Final app.js syntax is 100% VALID!');

fs.writeFileSync(filePath, code, 'utf8');
console.log('Successfully saved updated app.js! Size:', fs.statSync(filePath).size);
