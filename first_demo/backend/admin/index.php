<?php require_once __DIR__ . '/../config/database.php'; ?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard — Hungrily Food's</title>
    <!-- Favicon -->
    <link rel="icon" type="image/png" href="/admin/logo.png">
    <link rel="shortcut icon" href="/admin/logo.png">
    <link rel="apple-touch-icon" href="/admin/logo.png">
    <!-- Google Fonts: Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <!-- FontAwesome Icons: Local Offline Bundle + Multi-CDN Redundant Fallbacks -->
    <link rel="stylesheet" href="/admin/css/fontawesome.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" crossorigin="anonymous" referrerpolicy="no-referrer">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@fortawesome/fontawesome-free@6.5.2/css/all.min.css" crossorigin="anonymous">
    <!-- FontAwesome SVG Auto-replacement Engine (Renders vector icons even if webfonts are blocked) -->
    <script src="/admin/js/fontawesome.min.js" defer></script>
    <!-- Google Maps JS API with Places Library -->
    <script src="https://maps.googleapis.com/maps/api/js?key=<?php echo GOOGLE_MAPS_API_KEY; ?>&libraries=places&loading=async"></script>
    <!-- Ably Realtime Client SDK -->
    <script src="https://cdn.ably.com/lib/ably.min-1.js"></script>
    <!-- Custom Style Sheet -->
    <link rel="stylesheet" href="/admin/css/style.css?v=<?php echo time() . rand(1000,9999); ?>">
</head>
<body>

    <!-- Full Page Loading State -->
    <div id="global-loader" class="loader-overlay hidden">
        <div class="spinner"></div>
    </div>

    <!-- Toast Notifications -->
    <div id="toast-container" class="toast-container"></div>

    <!-- Auth Container -->
    <div id="auth-container" class="auth-layout hidden">
        <div id="auth-view" class="auth-wrapper"></div>
    </div>

    <!-- Main Container -->
    <div id="app-container" class="app-layout">
        <!-- Sidebar -->
        <aside id="sidebar" class="sidebar">
            <div class="sidebar-header">
                <div class="sidebar-logo" style="display: flex; align-items: center; gap: 10px;">
                    <img src="/admin/logo.png" alt="Hungrily Logo" style="width: 32px; height: 32px; border-radius: 50%; object-fit: cover;">
                    <span style="font-size: 16px; font-weight: 800; letter-spacing: 0.5px;">Hungrily Food's</span>
                </div>
                <button id="sidebar-close-btn" class="sidebar-close-btn">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
            
            <nav class="sidebar-nav">
                <ul>
                    <li>
                        <a href="/dashboard" class="nav-link active" data-link>
                            <i class="fa-solid fa-chart-pie"></i>
                            <span>Dashboard</span>
                        </a>
                    </li>
                    <li>
                        <a href="/vendors" class="nav-link" data-link>
                            <i class="fa-solid fa-shop"></i>
                            <span>Vendors</span>
                        </a>
                    </li>
                    <li>
                        <a href="/payouts" class="nav-link" data-link>
                            <i class="fa-solid fa-money-bill-transfer"></i>
                            <span>Vendor Payouts</span>
                        </a>
                    </li>
                    <li>
                        <a href="/revenue" class="nav-link" data-link>
                            <i class="fa-solid fa-chart-line"></i>
                            <span>Location Revenue</span>
                        </a>
                    </li>
                    <li>
                        <a href="/users" class="nav-link" data-link>
                            <i class="fa-solid fa-users"></i>
                            <span>Users</span>
                        </a>
                    </li>
                    <li>
                        <a href="/drivers" class="nav-link" data-link>
                            <i class="fa-solid fa-motorcycle"></i>
                            <span>Delivery Drivers</span>
                        </a>
                    </li>
                    <li>
                        <a href="/delivery-tracking" class="nav-link" data-link>
                            <i class="fa-solid fa-route"></i>
                            <span>Delivery Tracking</span>
                        </a>
                    </li>
                    <li>
                        <a href="/areas" class="nav-link" data-link>
                            <i class="fa-solid fa-map-location-dot"></i>
                            <span>Service Areas</span>
                        </a>
                    </li>
                    <li>
                        <a href="/subscriptions" class="nav-link" data-link>
                            <i class="fa-solid fa-calendar-days"></i>
                            <span>Subscriptions</span>
                        </a>
                    </li>
                    <li>
                        <a href="/enquiries" class="nav-link" data-link>
                            <i class="fa-solid fa-headset"></i>
                            <span>Website Enquiries</span>
                        </a>
                    </li>
                    <li>
                        <a href="/notifications" class="nav-link" data-link>
                            <i class="fa-solid fa-bell"></i>
                            <span>Push Notifications</span>
                        </a>
                    </li>
                    <li>
                        <a href="/whatsapp" class="nav-link" data-link>
                            <i class="fa-brands fa-whatsapp" style="color: #25D366;"></i>
                            <span>WhatsApp Broadcast</span>
                        </a>
                    </li>
                    <li>
                        <a href="/profile" class="nav-link" data-link>
                            <i class="fa-solid fa-user-gear"></i>
                            <span>Admin Profile</span>
                        </a>
                    </li>
                </ul>
            </nav>

            <div class="sidebar-footer">
                <button id="logout-btn" class="logout-btn">
                    <i class="fa-solid fa-right-from-bracket"></i>
                    <span>Sign Out</span>
                </button>
            </div>
        </aside>

        <!-- Content Area -->
        <main class="main-content">
            <!-- Navbar -->
            <header class="topbar">
                <div class="topbar-left">
                    <button id="sidebar-toggle-btn" class="sidebar-toggle-btn">
                        <i class="fa-solid fa-bars"></i>
                    </button>
                    <h1 id="page-title" class="page-title">Dashboard</h1>
                </div>
                <div class="topbar-right">
                    <div class="admin-profile-badge">
                        <div class="avatar-fallback" id="admin-avatar-char">A</div>
                        <div class="admin-info">
                            <span class="admin-name" id="admin-display-name">Admin User</span>
                            <span class="admin-role">System Administrator</span>
                        </div>
                    </div>
                </div>
            </header>

            <!-- Page Container (Views are injected here) -->
            <div id="content-view" class="content-view"></div>
        </main>
    </div>

    <!-- Auth Layout Container (For Login/Signup) -->
    <div id="auth-container" class="auth-layout hidden">
        <div class="auth-card-wrapper">
            <div id="auth-view" class="auth-view"></div>
        </div>
    </div>

    <!-- Modals Container -->
    <!-- View Modal -->
    <div id="details-modal" class="modal-overlay hidden">
        <div id="details-modal-card" class="modal-card modal-large">
            <div class="modal-header">
                <h3 id="modal-title">Record Details</h3>
                <button class="modal-close-btn" onclick="app.closeModal('details-modal')">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
            <div class="modal-body" id="modal-content">
                <!-- Injected details -->
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" onclick="app.closeModal('details-modal')">Close</button>
            </div>
        </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div id="delete-modal" class="modal-overlay hidden">
        <div class="modal-card modal-confirm">
            <div class="modal-header">
                <h3>Confirm Deletion</h3>
                <button class="modal-close-btn" onclick="app.closeModal('delete-modal')">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
            <div class="modal-body">
                <p>Are you sure you want to permanently delete this record? This action cannot be undone and will delete all associated data.</p>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" onclick="app.closeModal('delete-modal')">Cancel</button>
                <button class="btn btn-danger" id="confirm-delete-btn">Delete</button>
            </div>
        </div>
    </div>

    <!-- Location CRUD Modal -->
    <div id="location-modal" class="modal-overlay hidden">
        <div class="modal-card">
            <div class="modal-header">
                <h3 id="location-modal-title">Manage Location</h3>
                <button class="modal-close-btn" onclick="app.closeModal('location-modal')">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
            <form id="location-modal-form" onsubmit="app.handleLocationFormSubmit(event)">
                <div class="modal-body" id="location-modal-body" style="max-height: 70vh; overflow-y: auto;">
                    <!-- Fields injected dynamically -->
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" onclick="app.closeModal('location-modal')">Cancel</button>
                    <button type="submit" class="btn btn-primary" id="location-modal-submit-btn">Save Record</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Replicate Plan to Multiple Locations Modal -->
    <div id="replicate-plan-modal" class="modal-overlay hidden">
        <div class="modal-card" style="max-width: 600px;">
            <div class="modal-header">
                <div>
                    <h3 style="margin: 0; font-size: 1.15rem; display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-copy text-primary"></i>
                        Copy Plans to Other Locations
                    </h3>
                    <p style="margin: 4px 0 0 0; font-size: 0.8rem; color: var(--text-muted);">
                        Select which target service areas/locations you want to copy all created plans to. All checkboxes are unchecked by default.
                    </p>
                </div>
                <button class="modal-close-btn" onclick="app.closeModal('replicate-plan-modal')">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
            <form id="replicate-plan-form" onsubmit="app.handleReplicatePlanSubmit(event)">
                <div class="modal-body" style="max-height: 60vh; overflow-y: auto; padding: 16px 0;">
                    <!-- Plan Info Banner -->
                    <div id="replicate-plan-info-banner" style="background: rgba(79, 70, 229, 0.08); border: 1px solid rgba(79, 70, 229, 0.2); padding: 12px 16px; border-radius: 8px; margin-bottom: 16px;">
                        <strong id="replicate-plan-name-display" style="color: #4f46e5; font-size: 14px;"></strong>
                        <div id="replicate-plan-details-display" style="font-size: 12px; color: var(--text-muted); margin-top: 4px;"></div>
                    </div>

                    <!-- Target Location Selection -->
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                        <label class="form-label" style="margin: 0; font-weight: 700;">
                            Select Target Locations to Copy To:
                        </label>
                        <div style="display: flex; gap: 8px;">
                            <button type="button" class="btn btn-secondary btn-sm" onclick="app.toggleAllReplicateLocations(true)" style="padding: 2px 8px; font-size: 11px;">Select All</button>
                            <button type="button" class="btn btn-secondary btn-sm" onclick="app.toggleAllReplicateLocations(false)" style="padding: 2px 8px; font-size: 11px;">Deselect All</button>
                        </div>
                    </div>
                    <div id="replicate-target-locations-list" style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px; max-height: 240px; overflow-y: auto; border: 1px solid var(--border-color); padding: 12px; border-radius: 8px;">
                        <!-- Checkboxes populated dynamically (UNCHECKED by default) -->
                    </div>
                </div>
                <div class="modal-footer" style="border-top: 1px solid var(--border-color); padding-top: 14px;">
                    <button type="button" class="btn btn-secondary" onclick="app.closeModal('replicate-plan-modal')">Cancel</button>
                    <button type="submit" class="btn btn-primary" id="replicate-plan-submit-btn"><i class="fa-solid fa-copy" style="margin-right: 4px;"></i> Copy Plans</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Import / Copy Plans FROM Existing Location Modal -->
    <div id="import-plans-modal" class="modal-overlay hidden">
        <div class="modal-card" style="max-width: 540px;">
            <div class="modal-header">
                <div>
                    <h3 style="margin: 0; font-size: 1.15rem; display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-file-import text-primary"></i>
                        Copy Plans FROM Existing Location
                    </h3>
                    <p style="margin: 4px 0 0 0; font-size: 0.8rem; color: var(--text-muted);">
                        Select an existing service location to copy all of its subscription plans into your current location form.
                    </p>
                </div>
                <button class="modal-close-btn" onclick="app.closeModal('import-plans-modal')">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
            <form id="import-plans-form" onsubmit="app.handleImportPlansSubmit(event)">
                <div class="modal-body" style="padding: 16px 0;">
                    <div class="form-group" style="margin-bottom: 16px;">
                        <label class="form-label" style="font-weight: 700;">
                            Select Source Service Location:
                        </label>
                        <select id="import-source-location-select" class="form-control" style="padding: 10px 12px; font-size: 13.5px;" required>
                            <!-- Options populated dynamically -->
                        </select>
                        <small style="color: var(--text-muted); font-size: 11px; margin-top: 6px; display: block;">
                            All plans from the selected location will be populated into your current form. You can review or edit them before saving.
                        </small>
                    </div>
                </div>
                <div class="modal-footer" style="border-top: 1px solid var(--border-color); padding-top: 14px;">
                    <button type="button" class="btn btn-secondary" onclick="app.closeModal('import-plans-modal')">Cancel</button>
                    <button type="submit" class="btn btn-primary"><i class="fa-solid fa-file-import" style="margin-right: 4px;"></i> Import Plans</button>
                </div>
            </form>
        </div>
    </div>

    <!-- Manual Subscription Assignment Modal -->
    <div id="assign-plan-modal" class="modal-overlay hidden">
        <div class="modal-card modal-large" style="max-width: 800px;">
            <div class="modal-header" style="border-bottom: 1px solid var(--border-color, #e2e8f0); padding-bottom: 16px;">
                <div>
                    <h3 style="margin: 0; font-size: 1.25rem; color: var(--text-dark, #0f172a); display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-user-check" style="color: #4f46e5;"></i>
                        Assign Subscription Plan Manually
                    </h3>
                    <p style="margin: 4px 0 0 0; font-size: 0.85rem; color: var(--text-muted, #64748b);">
                        Select a customer, view available plans according to their address, and credit their wallet.
                    </p>
                </div>
                <button class="modal-close-btn" onclick="app.closeModal('assign-plan-modal')">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
            
            <form id="assign-plan-form" onsubmit="app.handleAssignPlanSubmit(event)">
                <div class="modal-body" style="max-height: 70vh; overflow-y: auto; padding: 20px 0;">
                    
                    <!-- Step 1: Customer Selection & Address -->
                    <div class="form-section" style="margin-bottom: 20px; background: #f8fafc; padding: 16px; border-radius: 8px; border: 1px solid #e2e8f0;">
                        <label for="assign-plan-customer-search" style="font-weight: 600; display: block; margin-bottom: 6px;">
                            Search & Select Customer <span style="color: #ef4444;">*</span>
                        </label>
                        
                        <!-- Search Bar with Name, Email, Mobile No Search -->
                        <div class="assign-customer-search-wrapper" style="position: relative; margin-bottom: 10px;">
                            <input type="text" id="assign-plan-customer-search" class="form-control" placeholder="Search customer by name, email, or mobile no..." autocomplete="off" oninput="app.onAssignPlanSearchInput(this.value)" onfocus="app.showAssignPlanDropdown(true)" style="width: 100%; padding: 11px 38px 11px 38px; border-radius: 8px; border: 1.5px solid #cbd5e1; font-size: 0.92rem; background: #ffffff; box-shadow: 0 1px 3px rgba(0,0,0,0.05);">
                            <i class="fa-solid fa-magnifying-glass" style="position: absolute; left: 13px; top: 50%; transform: translateY(-50%); color: #94a3b8; font-size: 14px;"></i>
                            <button type="button" id="assign-plan-search-clear" onclick="app.clearAssignPlanSearch()" style="position: absolute; right: 10px; top: 50%; transform: translateY(-50%); background: none; border: none; cursor: pointer; color: #94a3b8; display: none; padding: 4px;" title="Clear search">
                                <i class="fa-solid fa-xmark"></i>
                            </button>
                            <i id="assign-plan-search-spinner" class="fa-solid fa-spinner fa-spin" style="position: absolute; right: 13px; top: 50%; transform: translateY(-50%); color: #4f46e5; font-size: 14px; display: none;"></i>

                            <!-- Live Search Results Dropdown -->
                            <div id="assign-plan-search-results" style="position: absolute; top: calc(100% + 4px); left: 0; right: 0; background: #ffffff; border: 1.5px solid #cbd5e1; border-radius: 8px; box-shadow: 0 10px 25px -5px rgba(0,0,0,0.1), 0 8px 10px -6px rgba(0,0,0,0.1); max-height: 250px; overflow-y: auto; z-index: 1050; display: none;"></div>
                        </div>

                        <!-- Dropdown Select Fallback & Standard Form Binding -->
                        <select id="assign-plan-customer-select" class="form-control" onchange="app.onAssignPlanCustomerChange()" required style="width: 100%; padding: 10px; border-radius: 6px; border: 1px solid #cbd5e1;">
                            <option value="">-- Or Choose From List --</option>
                        </select>
                        
                        <!-- Customer Address Details Container -->
                        <div id="assign-plan-address-container" style="margin-top: 14px; display: none;">
                            <div style="font-weight: 600; font-size: 0.88rem; color: #334155; margin-bottom: 6px;">
                                <i class="fa-solid fa-location-dot" style="color: #ea580c; margin-right: 4px;"></i> Customer Saved Address:
                            </div>
                            <div id="assign-plan-address-box" style="background: #ffffff; padding: 12px; border-radius: 6px; border: 1px dashed #cbd5e1; font-size: 0.9rem; color: #1e293b;">
                                <!-- Injected via JS -->
                            </div>
                            
                            <div style="margin-top: 12px;">
                                <button type="button" class="btn btn-secondary" onclick="app.loadAvailablePlansForCustomer()" style="display: inline-flex; align-items: center; gap: 6px; background: #4f46e5; color: white; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer; font-weight: 500;">
                                    <i class="fa-solid fa-magnifying-glass-location"></i> View Available Plans for this Address
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Step 2: Available Plans Display Section -->
                    <div id="assign-plan-plans-section" style="display: none; margin-bottom: 20px;">
                        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;">
                            <h4 style="margin: 0; font-size: 1rem; font-weight: 700; color: #0f172a;">
                                Available Plans for Address
                            </h4>
                            <span id="assign-plan-count-badge" class="badge" style="background: #e0e7ff; color: #3730a3; padding: 4px 10px; border-radius: 12px; font-weight: 600; font-size: 0.8rem;">0 plans</span>
                        </div>
                        
                        <div id="assign-plan-plans-list" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 14px;">
                            <!-- Injected dynamically via JS -->
                        </div>
                        
                        <input type="hidden" id="assign-plan-selected-id" name="plan_id" required>
                    </div>

                    <!-- Step 3: Wallet Credit & Confirmation Summary -->
                    <div id="assign-plan-summary-section" style="display: none; background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px; padding: 16px;">
                        <div style="display: flex; align-items: flex-start; gap: 12px;">
                            <i class="fa-solid fa-wallet" style="font-size: 1.5rem; color: #16a34a; margin-top: 2px;"></i>
                            <div>
                                <h4 style="margin: 0 0 4px 0; color: #14532d; font-size: 0.95rem; font-weight: 700;">Wallet Credit Summary</h4>
                                <p id="assign-plan-summary-text" style="margin: 0; font-size: 0.88rem; color: #166534;">
                                    Assigning this plan will credit <strong id="assign-plan-credit-amount">₹0.00</strong> to the customer's wallet balance and activate their subscription immediately.
                                </p>
                            </div>
                        </div>
                    </div>

                </div>

                <div class="modal-footer" style="border-top: 1px solid #e2e8f0; padding-top: 14px;">
                    <button type="button" class="btn btn-secondary" onclick="app.closeModal('assign-plan-modal')">Cancel</button>
                    <button type="submit" class="btn btn-primary" id="assign-plan-submit-btn" disabled style="background: #16a34a; border-color: #16a34a; font-weight: 600;">
                        <i class="fa-solid fa-check-circle" style="margin-right: 4px;"></i> Assign Plan & Credit Wallet
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Live Order Road Tracking Modal -->
    <div id="dt-live-modal" class="modal-overlay hidden">
        <div class="modal-card modal-large" style="max-width: 950px; width: 95%; border-radius: 20px; overflow: hidden; padding: 0;">
            <div class="modal-header" style="background: #0F172A; color: white; padding: 18px 24px; border-bottom: 1px solid #1E293B;">
                <div style="display: flex; align-items: center; gap: 12px;">
                    <div style="width: 40px; height: 40px; border-radius: 12px; background: rgba(56, 189, 248, 0.15); color: #38BDF8; display: flex; align-items: center; justify-content: center; font-size: 18px;">
                        <i class="fa-solid fa-route"></i>
                    </div>
                    <div>
                        <h3 id="dt-modal-title" style="margin: 0; font-size: 1.15rem; font-weight: 800; color: #F8FAFC;">
                            Live Order Tracking
                        </h3>
                        <p id="dt-modal-subtitle" style="margin: 2px 0 0 0; font-size: 0.82rem; color: #94A3B8;">
                            Tracking Mess (Red), Driver (Blue), and Customer (Green) on actual driving road route
                        </p>
                    </div>
                </div>
                <button class="modal-close-btn" onclick="app.closeDeliveryTrackingModal()" style="color: #94A3B8; font-size: 20px;">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
            
            <div style="display: flex; flex-direction: column;">
                <!-- Live Order Summary & ETA Bar -->
                <div id="dt-modal-info-bar" style="background: #1E293B; color: white; padding: 14px 24px; border-bottom: 1px solid #334155; display: flex; flex-wrap: wrap; justify-content: space-between; align-items: center; gap: 14px;">
                    <div style="display: flex; align-items: center; gap: 16px; font-size: 13px;">
                        <div>
                            <span style="color: #94A3B8; font-size: 11px; font-weight: 600; display: block;">MESS / PICKUP</span>
                            <strong id="dt-modal-mess-name" style="color: #EF4444; font-weight: 800;">-</strong>
                        </div>
                        <i class="fa-solid fa-arrow-right" style="color: #475569; font-size: 12px;"></i>
                        <div>
                            <span style="color: #94A3B8; font-size: 11px; font-weight: 600; display: block;">DRIVER</span>
                            <strong id="dt-modal-driver-name" style="color: #38BDF8; font-weight: 800;">-</strong>
                        </div>
                        <i class="fa-solid fa-arrow-right" style="color: #475569; font-size: 12px;"></i>
                        <div>
                            <span style="color: #94A3B8; font-size: 11px; font-weight: 600; display: block;">CUSTOMER / DESTINATION</span>
                            <strong id="dt-modal-customer-name" style="color: #34D399; font-weight: 800;">-</strong>
                        </div>
                    </div>

                    <div style="display: flex; align-items: center; gap: 12px;">
                        <div id="dt-modal-eta-badge" style="background: rgba(37, 99, 235, 0.2); border: 1px solid rgba(59, 130, 246, 0.4); padding: 6px 14px; border-radius: 10px; font-size: 12px; font-weight: 700; color: #60A5FA;">
                            <i class="fa-solid fa-clock" style="margin-right: 4px;"></i> Calculating Route...
                        </div>
                        <span id="dt-modal-status-badge" class="badge badge-primary" style="font-size: 12px; font-weight: 800; padding: 6px 12px;">
                            ACTIVE
                        </span>
                    </div>
                </div>

                <!-- Live Status Timeline / Stepper Bar -->
                <div id="dt-modal-stepper-container" style="background: #0F172A; padding: 16px 24px; border-bottom: 1px solid #1E293B; overflow-x: auto;">
                    <!-- Dynamically rendered via app.renderOrderStepper(status) -->
                </div>

                <!-- Google Map Container -->
                <div id="dt-modal-map" style="width: 100%; height: 500px; background: #F1F5F9;"></div>
            </div>
        </div>
    </div>

    <!-- API and Application scripts -->
    <script src="/admin/js/locations.js?v=<?php echo time() . rand(1000,9999); ?>"></script>
    <script src="/admin/js/api.js?v=<?php echo time() . rand(1000,9999); ?>"></script>
    <script src="/admin/js/app.js?v=<?php echo time() . rand(1000,9999); ?>"></script>
</body>
</html>
