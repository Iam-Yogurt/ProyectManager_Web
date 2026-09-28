import re

with open('static/style.css', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the existing responsive block
new_responsive = """/* ═══════════════════════════════════════════════
   RESPONSIVE
   ═══════════════════════════════════════════════ */
.sidebar-backdrop { display: none; }
.mobile-menu-btn { display: none; background: transparent; border: none; cursor: pointer; color: var(--c-text); padding: 4px; }
.hide-mobile { display: inline; }

@media (max-width: 1024px) {
  .detail-layout { grid-template-columns: 1fr; }
  .project-grid { grid-template-columns: 1fr 1fr; }
}

@media (max-width: 768px) {
  :root { --sidebar-w: 0px; }
  .sidebar { 
    transform: translateX(-100%); 
    transition: transform 0.3s ease; 
    position: fixed; 
    z-index: 999; 
    width: 260px; 
    height: 100vh;
  }
  .sidebar.show {
    transform: translateX(0);
  }
  .sidebar-backdrop {
    display: none;
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(0,0,0,0.5);
    z-index: 998;
  }
  .sidebar-backdrop.show {
    display: block;
  }
  .mobile-menu-btn { display: block; }
  .hide-mobile { display: none; }
  .main-wrapper { margin-left: 0; }
  
  .topbar { padding: 0 16px; gap: 8px; }
  .topbar-search { max-width: 140px; }
  .topbar-search input { padding: 8px 12px 8px 36px; }
  
  .form-grid { grid-template-columns: 1fr; }
  .col-span-2 { grid-column: span 1; }
  .project-grid { grid-template-columns: 1fr; }
  .kpi-grid { grid-template-columns: 1fr; }
  .table-wrap { overflow-x: auto; }
}

@media (max-width: 480px) {
  .topbar-title { display: none; }
  .topbar-search { max-width: 100%; flex: 1; }
  .page-header { flex-direction: column; align-items: flex-start; gap: 12px; }
}
"""

content = re.sub(r'/\* ═══+\s+RESPONSIVE\s+═══+ \*/.*', new_responsive, content, flags=re.DOTALL)

with open('static/style.css', 'w', encoding='utf-8') as f:
    f.write(content)
