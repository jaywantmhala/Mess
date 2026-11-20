/**
 * Omni Admin Panel - API Integration Service
 * Base URL and reusable HTTP request client with authorization helper.
 */

class ApiService {
    constructor() {
        // Set to true to connect all Admin operations directly to the live production server (https://hungrilyfoods.com/api)
        // Set to false to run against local development server (http://10.44.177.233:8000/api or localhost:8000/api)
        this.useLiveProductionApi = true;
        this.liveProductionApiBase = 'https://hungrilyfoods.com/api';
        this.localIpApiBase = 'http://10.44.177.233:8000/api';

        if (this.useLiveProductionApi) {
            this.baseUrl = this.liveProductionApiBase;
        } else if (typeof window !== 'undefined' && window.location && window.location.origin && window.location.origin !== 'null' && window.location.protocol !== 'file:' && (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' || window.location.hostname.startsWith('10.') || window.location.hostname.startsWith('192.168.'))) {
            this.baseUrl = `${window.location.origin}/api`;
        } else {
            this.baseUrl = this.localIpApiBase;
        }
    }

    /**
     * Check if currently running in local development environment
     */
    isLocalEnv() {
        if (this.useLiveProductionApi) return false;
        if (typeof window === 'undefined' || !window.location) return true;
        const host = window.location.hostname;
        return host === 'localhost' || host === '127.0.0.1' || host.startsWith('192.168.') || host.startsWith('10.') || host.endsWith('.local') || window.location.port === '8000';
    }

    /**
     * Get local storage token
     */
    getToken() {
        let token = localStorage.getItem('omni_admin_token');
        if (this.isLocalEnv()) {
            if (!token || token === 'null' || token === 'undefined' || token === 'false') {
                token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjEsInJvbGUiOiJhZG1pbiIsImVtYWlsIjoiYWRtaW5AYWRtaW4uY29tIiwiZnVsbF9uYW1lIjoiU3VwZXIgQWRtaW4iLCJpYXQiOjE3OTE4MTE4MDYsImV4cCI6NDk0NTQxMTgwNn0.a6tEt2QRwizXHuzG_bKYDzd0H1Fc30kpTZCGbRKH_nc';
                this.setToken(token);
                if (!localStorage.getItem('omni_admin_user')) {
                    localStorage.setItem('omni_admin_user', JSON.stringify({ id: 1, full_name: 'Super Admin', email: 'admin@admin.com' }));
                }
            }
        } else {
            // Live production mode
            if (!token || token === 'null' || token === 'undefined' || token === 'false') {
                return null;
            }
            // Clear test dummy token if leftover from local testing
            if (token === 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjEsInJvbGUiOiJhZG1pbiIsImVtYWlsIjoiYWRtaW5AYWRtaW4uY29tIiwiZnVsbF9uYW1lIjoiU3VwZXIgQWRtaW4iLCJpYXQiOjE3OTE4MTE4MDYsImV4cCI6NDk0NTQxMTgwNn0.a6tEt2QRwizXHuzG_bKYDzd0H1Fc30kpTZCGbRKH_nc') {
                this.clearToken();
                localStorage.removeItem('omni_admin_user');
                return null;
            }
        }
        return token;
    }

    /**
     * Set local storage token
     */
    setToken(token) {
        localStorage.setItem('omni_admin_token', token);
    }

    clearToken() {
        localStorage.removeItem('omni_admin_token');
    }

    /**
     * Helper to perform fetch requests with auth headers and error handling
     */
    async request(endpoint, options = {}) {
        const url = `${this.baseUrl}${endpoint}`;
        
        // Prepare headers
        const headers = {
            'Content-Type': 'application/json',
            ...(options.headers || {})
        };

        const token = this.getToken();
        if (token) {
            headers['Authorization'] = `Bearer ${token}`;
        }

        const config = {
            ...options,
            headers
        };

        try {
            const response = await fetch(url, config);
            const responseText = await response.text();
            let result = {};
            try {
                result = responseText ? JSON.parse(responseText) : {};
            } catch (jsonErr) {
                throw new Error(responseText.trim() || `Server response invalid JSON (HTTP ${response.status})`);
            }

            if (!response.ok || !result.success) {
                // If token expired or unauthorized, automatically clear token and redirect
                if (response.status === 401 && endpoint !== '/admin/login') {
                    this.clearToken();
                    // Let the application route to login
                    window.dispatchEvent(new CustomEvent('unauthorized-api-call'));
                }
                throw new Error(result.message || 'Something went wrong.');
            }

            return result;
        } catch (error) {
            console.error(`API Error [${endpoint}]:`, error.message);
            throw error;
        }
    }

    /* ── Authentication ──────────────────────────────────────────────────── */

    async login(email, password) {
        const result = await this.request('/admin/login', {
            method: 'POST',
            body: JSON.stringify({ email, password })
        });
        if (result.success && result.data.token) {
            this.setToken(result.data.token);
            localStorage.setItem('omni_admin_user', JSON.stringify(result.data.admin));
        }
        return result;
    }

    async signup(fullName, email, password, confirmPassword) {
        const result = await this.request('/admin/signup', {
            method: 'POST',
            body: JSON.stringify({
                full_name: fullName,
                email,
                password,
                confirm_password: confirmPassword
            })
        });
        if (result.success && result.data.token) {
            this.setToken(result.data.token);
            localStorage.setItem('omni_admin_user', JSON.stringify(result.data.admin));
        }
        return result;
    }

    async getProfile() {
        return await this.request('/admin/me', { method: 'GET' });
    }

    async logout() {
        this.clearToken();
        localStorage.removeItem('omni_admin_user');
        return { success: true, message: 'Logged out successfully.' };
    }

    async getDashboardSummary() {
        return await this.request('/admin/dashboard/summary', { method: 'GET' });
    }

    /* ── Revenue Analytics Management ────────────────────────────────────── */

    async getRevenueReport({ search = '', status = 'all', country = '', state = '', district = '', taluka = '', page = 1, limit = 15 } = {}) {
        const queryParams = { search, status, page, limit };
        if (country)  queryParams.country = country;
        if (state)    queryParams.state = state;
        if (district) queryParams.district = district;
        if (taluka)   queryParams.taluka = taluka;
        const params = new URLSearchParams(queryParams);
        return await this.request(`/admin/revenue/list?${params.toString()}`, { method: 'GET' });
    }

    /* ── Delivery Drivers Management ─────────────────────────────────────── */

    async getDrivers({ search = '', status = 'all', sort = 'newest', date = '', vendor_id = 0, country = '', state = '', district = '', taluka = '', page = 1, limit = 10 } = {}) {
        const queryParams = { search, status, sort, page, limit };
        if (date) queryParams.date = date;
        if (vendor_id) queryParams.vendor_id = vendor_id;
        if (country && country !== 'all') queryParams.country = country;
        if (state && state !== 'all')     queryParams.state = state;
        if (district && district !== 'all') queryParams.district = district;
        if (taluka && taluka !== 'all')   queryParams.taluka = taluka;
        if (region && region !== 'all')   queryParams.region = region;
        if (area && area !== 'all')       queryParams.area = area;
        const params = new URLSearchParams(queryParams);
        return await this.request(`/admin/drivers?${params.toString()}`, { method: 'GET' });
    }

    async getDriverDetails(id) {
        return await this.request(`/admin/drivers/details?id=${id}`, { method: 'GET' });
    }

    async editDriver(driverData) {
        return await this.request('/admin/drivers/edit', {
            method: 'POST',
            body: JSON.stringify(driverData)
        });
    }

    /* ── Vendors Management ──────────────────────────────────────────────── */

    async getVendors({ search = '', status = 'all', sort = 'newest', date = '', country = '', state = '', district = '', taluka = '', region = '', area = '', page = 1, limit = 10 } = {}) {
        const queryParams = { search, status, sort, page, limit };
        if (date) queryParams.date = date;
        if (country && country !== 'all') queryParams.country = country;
        if (state && state !== 'all')     queryParams.state = state;
        if (district && district !== 'all') queryParams.district = district;
        if (taluka && taluka !== 'all')   queryParams.taluka = taluka;
        if (region && region !== 'all')   queryParams.region = region;
        if (area && area !== 'all')       queryParams.area = area;
        if (region && region !== 'all')   queryParams.region = region;
        if (area && area !== 'all')       queryParams.area = area;
        const params = new URLSearchParams(queryParams);
        return await this.request(`/admin/vendors?${params.toString()}`, { method: 'GET' });
    }

    async getVendorDetails(id, { date = '', orderPage = 1, menuPage = 1 } = {}) {
        const params = new URLSearchParams({ id, date, order_page: orderPage, menu_page: menuPage });
        return await this.request(`/admin/vendors/details?${params.toString()}`, { method: 'GET' });
    }

    async addVendor(fullName, email, password, confirmPassword) {
        return await this.request('/admin/vendors/add', {
            method: 'POST',
            body: JSON.stringify({
                full_name: fullName,
                email,
                password,
                confirm_password: confirmPassword
            })
        });
    }

    async editVendor(idOrObj, fullName, email, extra = {}) {
        let payload;
        if (typeof idOrObj === 'object' && idOrObj !== null) {
            payload = idOrObj;
        } else {
            payload = {
                id: idOrObj,
                full_name: fullName,
                email: email,
                ...extra
            };
        }
        return await this.request('/admin/vendors/edit', {
            method: 'POST',
            body: JSON.stringify(payload)
        });
    }

    async toggleVendorStatus(id, isActive) {
        return await this.request('/admin/vendors/status', {
            method: 'POST',
            body: JSON.stringify({ id, is_active: isActive })
        });
    }

    async deleteVendor(id) {
        return await this.request('/admin/vendors/delete', {
            method: 'POST',
            body: JSON.stringify({ id })
        });
    }

    async triggerVendorPayouts() {
        return await this.request('/admin/cron/vendor-payouts', {
            method: 'POST'
        });
    }

    async getPayouts({ search = '', status = 'all', page = 1, limit = 15 } = {}) {
        const queryParams = { search, status, page, limit };
        const params = new URLSearchParams(queryParams);
        return await this.request(`/admin/payouts?${params.toString()}`, { method: 'GET' });
    }

    async getRazorpayFundAccount({ fund_account_id = '', contact_id = '', vendor_id = '' } = {}) {
        const queryParams = {};
        if (fund_account_id) queryParams.fund_account_id = fund_account_id;
        if (contact_id) queryParams.contact_id = contact_id;
        if (vendor_id) queryParams.vendor_id = vendor_id;
        const params = new URLSearchParams(queryParams);
        try {
            return await this.request(`/admin/payouts/razorpay-fund-account?${params.toString()}`, { method: 'GET' });
        } catch (err) {
            return {
                success: false,
                fund_account: null,
                message: err.message
            };
        }
    }

    async syncVendorsRazorpay() {
        return await this.request('/admin/payouts/sync-vendors', { method: 'POST' });
    }

    async getRazorpayContacts({ count = 100, skip = 0, all = true } = {}) {
        const queryParams = { count, skip };
        if (all) queryParams.all = '1';
        const params = new URLSearchParams(queryParams);
        return await this.request(`/admin/payouts/razorpay-contacts?${params.toString()}`, { method: 'GET' });
    }

    async getRazorpayBankingBalances({ account_number = '', refresh = false } = {}) {
        const queryParams = {};
        if (account_number) queryParams.account_number = account_number;
        if (refresh) queryParams.refresh = '1';
        const params = new URLSearchParams(queryParams);
        const queryStr = params.toString() ? `?${params.toString()}` : '';
        try {
            return await this.request(`/admin/payouts/banking-balances${queryStr}`, { method: 'GET' });
        } catch (err) {
            return {
                success: false,
                items: [],
                count: 0,
                primary_balance: null,
                message: err.message
            };
        }
    }

    async getPayoutDashboard(cycle = '') {
        const queryStr = cycle ? `?cycle=${encodeURIComponent(cycle)}` : '';
        return await this.request(`/admin/payouts/dashboard${queryStr}`, { method: 'GET' });
    }

    async getPayoutSettings() {
        return await this.request('/admin/payouts/settings', { method: 'GET' });
    }

    async savePayoutSettings(settingsData) {
        return await this.request('/admin/payouts/settings', {
            method: 'POST',
            body: JSON.stringify(settingsData)
        });
    }

    async triggerPayoutNow(date = '') {
        return await this.request('/admin/payouts/trigger-now', {
            method: 'POST',
            body: JSON.stringify({ date })
        });
    }

    async getPayoutRecords(params = {}) {
        const query = new URLSearchParams();
        if (params.page) query.append('page', params.page);
        if (params.limit) query.append('limit', params.limit);
        if (params.search) query.append('search', params.search);
        if (params.status && params.status !== 'all') query.append('status', params.status);
        if (params.vendor_id) query.append('vendor_id', params.vendor_id);
        if (params.cycle) query.append('cycle', params.cycle);
        if (params.min_amount) query.append('min_amount', params.min_amount);
        if (params.max_amount) query.append('max_amount', params.max_amount);
        if (params.account_number) query.append('account_number', params.account_number);
        if (params.source) query.append('source', params.source);
        return await this.request(`/admin/payouts/records?${query.toString()}`, { method: 'GET' });
    }

    async getPayoutRecordDetails(id) {
        return await this.request(`/admin/payouts/record-details?id=${id}`, { method: 'GET' });
    }

    async reconcilePayout(id) {
        return await this.request('/admin/payouts/reconcile', {
            method: 'POST',
            body: JSON.stringify({ id })
        });
    }

    async addVendorEarning({ vendor_id, amount, description = '', order_id = null }) {
        return await this.request('/admin/payouts/add-earning', {
            method: 'POST',
            body: JSON.stringify({ vendor_id, amount, description, order_id })
        });
    }

    async getPayoutRuns(params = {}) {
        const query = new URLSearchParams();
        if (params.page) query.append('page', params.page);
        if (params.limit) query.append('limit', params.limit);
        return await this.request(`/admin/payouts/runs?${query.toString()}`, { method: 'GET' });
    }

    /* ── Users (Customers) Management ────────────────────────────────────── */

    async getUsers({ search = '', status = 'all', sort = 'newest', date = '', country = '', state = '', district = '', taluka = '', region = '', area = '', page = 1, limit = 10 } = {}) {
        const queryParams = { search, status, sort, page, limit };
        if (date) queryParams.date = date;
        if (country && country !== 'all') queryParams.country = country;
        if (state && state !== 'all')     queryParams.state = state;
        if (district && district !== 'all') queryParams.district = district;
        if (taluka && taluka !== 'all')   queryParams.taluka = taluka;
        if (region && region !== 'all')   queryParams.region = region;
        if (area && area !== 'all')       queryParams.area = area;
        const params = new URLSearchParams(queryParams);
        return await this.request(`/admin/users?${params.toString()}`, { method: 'GET' });
    }

    async getUserDetails(id, { orderPage = 1 } = {}) {
        const params = new URLSearchParams({ id, order_page: orderPage });
        return await this.request(`/admin/users/details?${params.toString()}`, { method: 'GET' });
    }

    async addUser(fullName, email, password, confirmPassword) {
        return await this.request('/admin/users/add', {
            method: 'POST',
            body: JSON.stringify({
                full_name: fullName,
                email,
                password,
                confirm_password: confirmPassword
            })
        });
    }

    async editUser(idOrObj, fullName, email, password = '', extra = {}) {
        let payload;
        if (typeof idOrObj === 'object' && idOrObj !== null) {
            payload = idOrObj;
        } else {
            payload = {
                id: idOrObj,
                full_name: fullName,
                email: email,
                password: password,
                ...extra
            };
        }
        return await this.request('/admin/users/edit', {
            method: 'POST',
            body: JSON.stringify(payload)
        });
    }

    async toggleUserStatus(id, isActive) {
        return await this.request('/admin/users/status', {
            method: 'POST',
            body: JSON.stringify({ id, is_active: isActive })
        });
    }

    async deleteUser(id) {
        return await this.request('/admin/users/delete', {
            method: 'POST',
            body: JSON.stringify({ id })
        });
    }

    /* ── Service Areas & Subscription Plans (legacy) ────────────────────── */

    async getLocations({ type = 'all', search = '', status = 'all' } = {}) {
        const params = new URLSearchParams({ type, search, status });
        return await this.request(`/admin/locations?${params.toString()}`, { method: 'GET' });
    }

    async saveLocation(payload) {
        return await this.request('/admin/locations/save', {
            method: 'POST',
            body: JSON.stringify(payload)
        });
    }

    async toggleLocationStatus(type, id, isActive) {
        return await this.request('/admin/locations/status', {
            method: 'POST',
            body: JSON.stringify({ type, id, is_active: isActive })
        });
    }

    async deleteLocation(type, id) {
        return await this.request('/admin/locations/delete', {
            method: 'POST',
            body: JSON.stringify({ type, id })
        });
    }

    /* ── Service Locations (new flat model with per-location radius) ─────── */

    async getServiceLocations({ search = '', status = 'all' } = {}) {
        const params = new URLSearchParams({ search, status });
        return await this.request(`/admin/service-locations?${params.toString()}`, { method: 'GET' });
    }

    async saveServiceLocation(payload) {
        return await this.request('/admin/service-locations/save', {
            method: 'POST',
            body: JSON.stringify(payload)
        });
    }

    async deleteServiceLocation(id) {
        return await this.request('/admin/service-locations/delete', {
            method: 'POST',
            body: JSON.stringify({ id })
        });
    }

    async replicatePlan(payload) {
        return await this.request('/admin/service-locations/replicate-plan', {
            method: 'POST',
            body: JSON.stringify(payload)
        });
    }

    async geocodeAddress(address) {
        return await this.request('/admin/locations/geocode', {
            method: 'POST',
            body: JSON.stringify({ address })
        });
    }

    async reverseGeocodeCoords(latitude, longitude) {
        return await this.request('/admin/locations/geocode', {
            method: 'POST',
            body: JSON.stringify({ latitude, longitude })
        });
    }

    async getCustomerAddresses(customerId) {
        return await this.request(`/admin/users/addresses?customer_id=${customerId}`, { method: 'GET' });
    }

    async getNearbyHotels(latitude, longitude, foodType = '') {
        let url = `/hotels/nearby?latitude=${latitude}&longitude=${longitude}`;
        if (foodType && foodType !== 'ALL') {
            url += `&food_type=${encodeURIComponent(foodType)}`;
        }
        return await this.request(url, { method: 'GET' });
    }

    async assignPlanManually(customerId, planId, notes = '') {
        return await this.request('/admin/subscriptions/assign', {
            method: 'POST',
            body: JSON.stringify({ customer_id: customerId, plan_id: planId, notes })
        });
    }

    async resolveServiceablePlans(latitude, longitude, pincode = '', customerAddress = '') {
        return await this.request('/customer/serviceable-plans', {
            method: 'POST',
            body: JSON.stringify({ latitude, longitude, pincode, customer_address: customerAddress })
        });
    }

    /* ── Subscriptions ───────────────────────────────────────────────────── */

    async getSubscriptions(params) {
        const query = new URLSearchParams(params).toString();
        return await this.request(`/admin/subscriptions/list?${query}`);
    }

    async performSubscriptionAction(payload) {
        return await this.request('/admin/subscriptions/action', {
            method: 'POST',
            body: JSON.stringify(payload)
        });
    }

    /* ── Push Notifications ────────────────────────────────────────────────── */

    async getNotificationTargets(params = {}) {
        const query = new URLSearchParams(params).toString();
        return await this.request(`/admin/notifications/targets?${query}`, {
            method: 'GET'
        });
    }

    async sendPushNotification(payload) {
        return await this.request('/admin/notifications/send', {
            method: 'POST',
            body: JSON.stringify(payload)
        });
    }

    async uploadNotificationImage(file) {
        const formData = new FormData();
        formData.append('image', file);
        const token = this.getToken();
        const headers = {};
        if (token) {
            headers['Authorization'] = 'Bearer ' + token;
        }
        const url = this.baseUrl + '/admin/notifications/upload_image';
        const response = await fetch(url, {
            method: 'POST',
            headers: headers,
            body: formData
        });
        const responseText = await response.text();
        let result = {};
        try {
            result = responseText ? JSON.parse(responseText) : {};
        } catch (e) {
            throw new Error('Upload response error: ' + (responseText || response.statusText));
        }
        if (!response.ok || !result.success) {
            throw new Error(result.message || ('Upload failed with HTTP ' + response.status));
        }
        return result;
    }

    /* ── WhatsApp Bulk Broadcast ───────────────────────────────────────────── */

    async getWhatsAppTargets(params = {}) {
        const query = new URLSearchParams(params).toString();
        return await this.request(`/admin/whatsapp/targets?${query}`, {
            method: 'GET'
        });
    }

    async sendWhatsAppBroadcast(payload) {
        return await this.request('/admin/whatsapp/send', {
            method: 'POST',
            body: JSON.stringify(payload)
        });
    }

    async getWhatsAppHistory(params = {}) {
        const query = new URLSearchParams(params).toString();
        return await this.request(`/admin/whatsapp/history?${query}`, {
            method: 'GET'
        });
    }

    /* ── Live Delivery Tracking ───────────────────────────────────────────── */

    async getDeliveryTracking(params = {}) {
        const query = new URLSearchParams(params).toString();
        return await this.request(`/admin/delivery_tracking/list.php?${query}`, {
            method: 'GET'
        });
    }

    /* ── Website Inquiries ─────────────────────────────────────────────────── */

    async getEnquiries(params = {}) {
        const query = new URLSearchParams();
        for (const [key, val] of Object.entries(params)) {
            if (val !== undefined && val !== null && val !== '') {
                query.append(key, val);
            }
        }
        return await this.request(`/admin/enquiries/list?${query.toString()}`, {
            method: 'GET'
        });
    }

    async updateEnquiryStatus(id, status, notes = null) {
        return await this.request('/admin/enquiries/status', {
            method: 'POST',
            body: JSON.stringify({ id, status, notes })
        });
    }

    async deleteEnquiry(id) {
        return await this.request('/admin/enquiries/delete', {
            method: 'POST',
            body: JSON.stringify({ id })
        });
    }

    /* ── Database Schema Migration & Auto-Refresh ───────────────────────────── */

    async migrateDatabase() {
        return await this.request('/migrate.php', {
            method: 'GET'
        });
    }
}

// Global instance
const api = new ApiService();
