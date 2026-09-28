import re

with open('templates/layout.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Add backdrop and id to sidebar
content = content.replace('  <!-- ══ SIDEBAR ══════════════════════════════ -->\n  <aside class="sidebar">', 
                          '  <!-- Sidebar Backdrop -->\n  <div class="sidebar-backdrop" id="sidebar-backdrop" onclick="toggleSidebar()"></div>\n\n  <!-- ══ SIDEBAR ══════════════════════════════ -->\n  <aside class="sidebar" id="sidebar">')

# Add hamburger button and notification bell
topbar_html = """    <!-- Topbar -->
    <header class="topbar">
      <div style="display: flex; align-items: center; gap: 12px;">
        <button class="mobile-menu-btn" onclick="toggleSidebar()" aria-label="Abrir menú">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="24" height="24">
            <line x1="3" y1="12" x2="21" y2="12"></line>
            <line x1="3" y1="6" x2="21" y2="6"></line>
            <line x1="3" y1="18" x2="21" y2="18"></line>
          </svg>
        </button>
        <span class="topbar-title">{% block page_title %}ProjectFlow ERP{% endblock %}</span>
      </div>

      <form class="topbar-search" action="{{ url_for('buscar') }}" method="GET" role="search">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
        </svg>
        <input type="text" name="q" placeholder="Buscar..."
               value="{{ request.args.get('q', '') }}"
               autocomplete="off">
      </form>

      <div class="topbar-actions">
        <!-- Notifications Bell -->
        <div class="dropdown" style="position: relative; display: inline-block;">
          <button class="btn btn-ghost" style="padding: 6px; position: relative; display: flex; align-items: center;" onclick="document.getElementById('notif-dropdown').style.display = document.getElementById('notif-dropdown').style.display === 'block' ? 'none' : 'block'">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="20" height="20">
              <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"></path>
              <path d="M13.73 21a2 2 0 0 1-3.46 0"></path>
            </svg>
            {% if alertas_vencimiento|length > 0 %}
            <span style="position: absolute; top: 0px; right: 2px; width: 8px; height: 8px; background: var(--c-danger); border-radius: 50%;"></span>
            {% endif %}
          </button>
          
          <div id="notif-dropdown" class="dropdown-content" style="display: none; position: absolute; right: 0; top: 100%; background: var(--c-card); min-width: 280px; max-width: 320px; box-shadow: var(--shadow); border-radius: var(--radius); border: 1px solid var(--c-border); z-index: 100; margin-top: 5px;">
            <div style="padding: 12px 16px; border-bottom: 1px solid var(--c-border); font-weight: 600; font-size: 0.9rem;">
              Notificaciones
            </div>
            <div style="max-height: 300px; overflow-y: auto;">
              {% if alertas_vencimiento|length > 0 %}
                {% for alerta in alertas_vencimiento %}
                <a href="{{ url_for('detalle_tarea', id_tarea=alerta.id_tarea) }}" style="display: block; padding: 12px 16px; border-bottom: 1px solid var(--c-border); text-decoration: none; color: inherit;">
                  <div style="font-weight: 600; font-size: 0.85rem; color: var(--c-text);">⚠️ Tarea por Vencer</div>
                  <div style="font-size: 0.8rem; margin-top: 4px; color: var(--c-text-2); white-space: normal; line-height: 1.2;">
                    <strong>{{ alerta.nombre_tarea }}</strong> ({{ alerta.nombre_proyecto }})
                  </div>
                  <div style="font-size: 0.75rem; margin-top: 4px; color: var(--c-danger); font-weight: 600;">
                    Vence: {{ alerta.fecha_vencimiento.strftime('%d %b %Y') }}
                  </div>
                </a>
                {% endfor %}
              {% else %}
                <div style="padding: 16px; text-align: center; font-size: 0.85rem; color: var(--c-text-3);">
                  No hay tareas por vencer pronto.
                </div>
              {% endif %}
            </div>
          </div>
        </div>

        <a href="{{ url_for('nuevo_proyecto') }}" class="btn btn-primary" style="font-size:.82rem;padding:7px 14px; display: flex; align-items: center; gap: 5px;">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" width="16" height="16">
            <path d="M12 5v14M5 12h14"/>
          </svg>
          <span class="hide-mobile">Nuevo Proyecto</span>
        </a>
      </div>
    </header>"""
content = re.sub(r'    <!-- Topbar -->.*?    </header>', topbar_html, content, flags=re.DOTALL)

# Add JS toggles
js_code = """
  <script>
    function toggleSidebar() {
      var sidebar = document.getElementById('sidebar');
      var backdrop = document.getElementById('sidebar-backdrop');
      sidebar.classList.toggle('show');
      backdrop.classList.toggle('show');
    }

    // Close the dropdown if the user clicks outside of it
    window.onclick = function(event) {
      if (!event.target.closest('.dropdown')) {
        var dropdowns = document.getElementsByClassName("dropdown-content");
        for (var i = 0; i < dropdowns.length; i++) {
          var openDropdown = dropdowns[i];
          if (openDropdown.style.display === 'block') {
            openDropdown.style.display = 'none';
          }
        }
      }
    }
  </script>
"""
if '<script>' not in content:
    content = content.replace('  {% block extra_scripts %}{% endblock %}\n</body>', js_code + '\n  {% block extra_scripts %}{% endblock %}\n</body>')

with open('templates/layout.html', 'w', encoding='utf-8') as f:
    f.write(content)
