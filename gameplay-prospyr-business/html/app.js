// ═════════════════════════════════════════════════════════════════════
// Prospyr Business Manager — NUI JavaScript
// Message routing, tab switching, CRUD operations, rendering
// ═════════════════════════════════════════════════════════════════════

let state = {
    businesses: [],
    selectedBusiness: null,
    currentTab: 'businesses',
    businessTypes: {},
    permissions: {},
    currency: '$%s',
    isAdmin: false,
};

// ═════════════════════════════════════════════════════════════════════
// NUI Message Handler
// ═════════════════════════════════════════════════════════════════════

window.addEventListener('message', function(event) {
    const data = event.data;
    if (!data.action) return;

    switch (data.action) {
        case 'open':
            state.businesses = data.businesses || [];
            state.businessTypes = data.config?.businessTypes || {};
            state.permissions = data.config?.permissions || {};
            state.currency = data.config?.currency || '$%s';
            document.getElementById('app').classList.remove('hidden');
            renderBusinessList();
            populateBusinessTypes();
            break;

        case 'close':
            document.getElementById('app').classList.add('hidden');
            break;

        case 'openAdmin':
            state.isAdmin = true;
            document.getElementById('app').classList.remove('hidden');
            document.querySelector('.tab-admin').classList.remove('hidden');
            populateBusinessTypes(data.config?.businessTypes);
            fetch('https://prospyr-business-manager/adminGetAllBusinesses', {
                method: 'POST', headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({})
            });
            break;

        case 'updateData':
            if (data.business) {
                document.getElementById('currentBalance').textContent = formatCurrency(data.balance || data.business.balance);
                document.getElementById('totalRevenue').textContent = formatCurrency(data.business.revenue || 0);
                document.getElementById('totalExpenses').textContent = formatCurrency(data.business.expenses || 0);
            }
            if (data.employees) renderEmployees(data.employees);
            if (data.transactions) renderTransactions(data.transactions);
            break;

        case 'updateBusinessList':
            state.businesses = data.businesses || [];
            renderBusinessList();
            break;

        case 'updateEmployees':
            renderEmployees(data.employees);
            break;

        case 'adminData':
            renderAdminTable(data.businesses);
            break;

        case 'showCreateForm':
            state.businessTypes = data.businessTypes || state.businessTypes;
            populateBusinessTypes();
            document.getElementById('app').classList.remove('hidden');
            switchTab('create');
            break;

        case 'showHireDialog':
            showHireDialog(data);
            break;
    }
});

// ═════════════════════════════════════════════════════════════════════
// Helpers
// ═════════════════════════════════════════════════════════════════════

function formatCurrency(amount) {
    const num = parseFloat(amount) || 0;
    return state.currency.replace('%s', num.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }));
}

function post(callback, data = {}) {
    fetch(`https://prospyr-business-manager/${callback}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).then(r => r.json()).catch(() => {});
}

// ═════════════════════════════════════════════════════════════════════
// Tab Switching
// ═════════════════════════════════════════════════════════════════════

document.querySelectorAll('.tab').forEach(tab => {
    tab.addEventListener('click', () => switchTab(tab.dataset.tab));
});

function switchTab(tabName) {
    state.currentTab = tabName;
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
    document.querySelector(`.tab[data-tab="${tabName}"]`)?.classList.add('active');
    document.getElementById(`tab-${tabName}`)?.classList.add('active');
}

// ═════════════════════════════════════════════════════════════════════
// Business List Rendering
// ═════════════════════════════════════════════════════════════════════

function renderBusinessList() {
    const container = document.getElementById('businessList');
    if (state.businesses.length === 0) {
        container.innerHTML = '<div class="empty-state"><p>No businesses yet. Create one in the "Create Business" tab.</p></div>';
        return;
    }

    container.innerHTML = state.businesses.map(biz => `
        <div class="business-card ${state.selectedBusiness === biz.id ? 'active' : ''}" data-id="${biz.id}">
            <div class="biz-name">${biz.name}</div>
            <div class="biz-type">${state.businessTypes[biz.type]?.label || biz.type}</div>
            <div class="biz-balance">${formatCurrency(biz.balance)}</div>
        </div>
    `).join('');

    container.querySelectorAll('.business-card').forEach(card => {
        card.addEventListener('click', () => {
            const id = parseInt(card.dataset.id);
            state.selectedBusiness = id;
            post('selectBusiness', { businessId: id });
            renderBusinessList();
        });
    });
}

// ═════════════════════════════════════════════════════════════════════
// Employee Rendering
// ═════════════════════════════════════════════════════════════════════

function renderEmployees(employees) {
    const tbody = document.getElementById('employeeTableBody');
    if (!employees || employees.length === 0) {
        tbody.innerHTML = '<tr class="empty-row"><td colspan="5">No employees. Hire someone!</td></tr>';
        return;
    }

    tbody.innerHTML = employees.map(emp => `
        <tr data-emp-id="${emp.id}">
            <td>${emp.player_name}</td>
            <td><span class="role-badge role-${emp.role}">${emp.role}</span></td>
            <td>${formatCurrency(emp.salary)}</td>
            <td>${new Date(emp.hired_at).toLocaleDateString()}</td>
            <td>
                ${emp.role !== 'owner' ? `
                    <button class="btn btn-sm btn-danger" onclick="fireEmployee(${emp.id})">Fire</button>
                    <button class="btn btn-sm btn-secondary" onclick="editRole(${emp.id}, '${emp.role}')">Role</button>
                ` : '<span style="color: var(--text-muted);">—</span>'}
            </td>
        </tr>
    `).join('');
}

// ═════════════════════════════════════════════════════════════════════
// Transaction Rendering
// ═════════════════════════════════════════════════════════════════════

function renderTransactions(transactions) {
    const tbody = document.getElementById('transactionTableBody');
    if (!transactions || transactions.length === 0) {
        tbody.innerHTML = '<tr class="empty-row"><td colspan="5">No transactions yet.</td></tr>';
        return;
    }

    tbody.innerHTML = transactions.map(tx => `
        <tr>
            <td>${new Date(tx.created_at).toLocaleString()}</td>
            <td><span class="badge badge-${tx.type}">${tx.type}</span></td>
            <td style="color: ${tx.type === 'deposit' || tx.type === 'revenue' ? 'var(--success)' : 'var(--danger)'}">
                ${tx.type === 'deposit' || tx.type === 'revenue' ? '+' : '-'}${formatCurrency(tx.amount)}
            </td>
            <td>${tx.description || '—'}</td>
            <td>${tx.performed_name || tx.performed_by}</td>
        </tr>
    `).join('');
}

// ═════════════════════════════════════════════════════════════════════
// Admin Table
// ═════════════════════════════════════════════════════════════════════

function renderAdminTable(businesses) {
    const tbody = document.getElementById('adminTableBody');
    if (!businesses || businesses.length === 0) {
        tbody.innerHTML = '<tr class="empty-row"><td colspan="7">No businesses found.</td></tr>';
        return;
    }

    tbody.innerHTML = businesses.map(biz => `
        <tr>
            <td>${biz.id}</td>
            <td>${biz.name}</td>
            <td>${state.businessTypes[biz.type]?.label || biz.type}</td>
            <td>${biz.owner_cid}</td>
            <td>${formatCurrency(biz.balance)}</td>
            <td>${biz.employee_count || 0}</td>
            <td><button class="btn btn-sm btn-danger" onclick="adminDelete(${biz.id})">Delete</button></td>
        </tr>
    `).join('');
}

// ═════════════════════════════════════════════════════════════════════
// Business Type Selector
// ═════════════════════════════════════════════════════════════════════

function populateBusinessTypes() {
    const select = document.getElementById('bizType');
    const hireRoleSelect = document.getElementById('hireRole');
    if (!select) return;

    select.innerHTML = Object.entries(state.businessTypes).map(([key, val]) =>
        `<option value="${key}">${val.label}</option>`
    ).join('');

    // Populate hire roles based on first business type (general fallback)
    if (hireRoleSelect) {
        const roles = state.businessTypes['general']?.roles || ['owner', 'manager', 'employee'];
        hireRoleSelect.innerHTML = roles.map(r => `<option value="${r}">${r}</option>`).join('');
    }
}

// ═════════════════════════════════════════════════════════════════════
// Event Handlers
// ═════════════════════════════════════════════════════════════════════

// Close button
document.getElementById('closeBtn').addEventListener('click', () => {
    document.getElementById('app').classList.add('hidden');
    post('close');
});

// ESC key
document.addEventListener('keyup', (e) => {
    if (e.key === 'Escape') {
        document.getElementById('app').classList.add('hidden');
        post('close');
        closeHireModal();
    }
});

// Create business form
document.getElementById('createBusinessForm').addEventListener('submit', (e) => {
    e.preventDefault();
    const name = document.getElementById('bizName').value.trim();
    const type = document.getElementById('bizType').value;
    if (!name) return;
    post('submitCreateBusiness', { name, type, blipCoords: null });
    document.getElementById('bizName').value = '';
    switchTab('businesses');
});

// Deposit
document.getElementById('depositBtn').addEventListener('click', () => {
    const amount = parseFloat(document.getElementById('amountInput').value);
    const desc = document.getElementById('descInput').value.trim();
    if (!amount || amount <= 0) return;
    post('deposit', { businessId: state.selectedBusiness, amount, description: desc });
    document.getElementById('amountInput').value = '';
    document.getElementById('descInput').value = '';
});

// Withdraw
document.getElementById('withdrawBtn').addEventListener('click', () => {
    const amount = parseFloat(document.getElementById('amountInput').value);
    const desc = document.getElementById('descInput').value.trim();
    if (!amount || amount <= 0) return;
    post('withdraw', { businessId: state.selectedBusiness, amount, description: desc });
    document.getElementById('amountInput').value = '';
    document.getElementById('descInput').value = '';
});

// Hire button
document.getElementById('hireBtn').addEventListener('click', () => {
    document.getElementById('hireModal').classList.remove('hidden');
});

// Hire form
document.getElementById('hireForm').addEventListener('submit', (e) => {
    e.preventDefault();
    post('hireEmployee', {
        businessId: state.selectedBusiness,
        citizenid: document.getElementById('hireCid').value,
        playerName: document.getElementById('hireName').value,
        role: document.getElementById('hireRole').value,
        salary: parseFloat(document.getElementById('hireSalary').value) || undefined,
    });
    closeHireModal();
});

// Refresh admin
document.getElementById('refreshAdminBtn')?.addEventListener('click', () => {
    post('adminGetAllBusinesses');
});

// ═════════════════════════════════════════════════════════════════════
// Inline Actions
// ═════════════════════════════════════════════════════════════════════

window.fireEmployee = function(empId) {
    post('fireEmployee', { businessId: state.selectedBusiness, employeeId: empId });
};

window.editRole = function(empId, currentRole) {
    const roles = state.businessTypes['general']?.roles || ['owner', 'manager', 'employee'];
    const newRole = prompt('New role:', currentRole); // Simple prompt — could be modal
    if (newRole && newRole !== currentRole) {
        post('updateRole', { businessId: state.selectedBusiness, employeeId: empId, role: newRole });
    }
};

window.adminDelete = function(businessId) {
    if (confirm('Delete this business? This cannot be undone.')) {
        post('adminDeleteBusiness', { businessId });
    }
};

window.closeHireModal = function() {
    document.getElementById('hireModal').classList.add('hidden');
};