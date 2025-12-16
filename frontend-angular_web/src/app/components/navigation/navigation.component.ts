import { Component, OnInit } from '@angular/core';
import { Router, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs/operators';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-navigation',
  template: `
    <nav class="navbar">
      <div class="nav-container">
        <div class="nav-brand">
          <div class="brand-icon">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/>
            </svg>
          </div>
          <div class="brand-text-container">
            <span class="brand-text">Hospital</span>
            <span class="brand-subtext">Microgrid</span>
          </div>
        </div>
        
        <div class="nav-links">
          <a 
            *ngFor="let item of navItems" 
            [routerLink]="item.route"
            [class.active]="currentPage === item.id"
            class="nav-link">
            <span class="nav-label">{{ item.label }}</span>
          </a>
        </div>
        
        <div class="nav-actions">
          <button class="view-establishments-btn" (click)="viewEstablishments()" title="Mes établissements">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="3" width="7" height="7"></rect>
              <rect x="14" y="3" width="7" height="7"></rect>
              <rect x="3" y="14" width="7" height="7"></rect>
              <rect x="14" y="14" width="7" height="7"></rect>
            </svg>
            <span>Mes établissements</span>
          </button>
          <button class="create-establishment-btn" (click)="createEstablishment()" title="Créer un établissement">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="12" y1="5" x2="12" y2="19"></line>
              <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            <span>Nouvel établissement</span>
          </button>
          <button class="logout-btn" (click)="logout()">
            <svg class="logout-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
              <polyline points="16 17 21 12 16 7"></polyline>
              <line x1="21" y1="12" x2="9" y2="12"></line>
            </svg>
            <span>Déconnexion</span>
          </button>
        </div>
      </div>
    </nav>
  `,
  styleUrls: ['./navigation.component.scss']
})
export class NavigationComponent implements OnInit {
  currentPage = 'dashboard';
  
  navItems = [
    { id: 'dashboard', label: 'Dashboard', route: '/dashboard', icon: 'dashboard' },
    { id: 'ai-prediction', label: 'AI Prediction', route: '/ai-prediction', icon: 'brain' },
    { id: 'auto-learning', label: 'Auto-Learning', route: '/auto-learning', icon: 'bolt' },
    { id: 'history', label: 'History', route: '/history', icon: 'chart' }
  ];

  constructor(
    private router: Router,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    this.router.events
      .pipe(filter(event => event instanceof NavigationEnd))
      .subscribe((event: any) => {
        const url = event.urlAfterRedirects;
        const item = this.navItems.find(nav => url.includes(nav.id));
        if (item) {
          this.currentPage = item.id;
        }
      });
  }

  logout(): void {
    this.authService.logout();
  }

  createEstablishment(): void {
    this.router.navigate(['/create-establishment']);
  }

  viewEstablishments(): void {
    this.router.navigate(['/establishments']);
  }

  getIconSvg(iconName: string): string {
    const icons: { [key: string]: string } = {
      dashboard: '<path d="M3 3h8v8H3z"/><path d="M13 3h8v8h-8z"/><path d="M3 13h8v8H3z"/><path d="M13 13h8v8h-8z"/>',
      brain: '<path d="M9.5 2A2.5 2.5 0 0 0 7 4.5v15a2.5 2.5 0 0 0 2.5 2.5h5a2.5 2.5 0 0 0 2.5-2.5v-15A2.5 2.5 0 0 0 14.5 2h-5z"/><circle cx="12" cy="8" r="1.5"/><path d="M10 12h4M10 15h4"/>',
      bolt: '<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>',
      chart: '<line x1="18" y1="20" x2="18" y2="10"></line><line x1="12" y1="20" x2="12" y2="4"></line><line x1="6" y1="20" x2="6" y2="14"></line>'
    };
    return icons[iconName] || icons['dashboard'];
  }
}
