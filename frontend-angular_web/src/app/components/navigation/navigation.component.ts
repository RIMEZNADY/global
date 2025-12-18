import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, NavigationEnd, RouterModule } from '@angular/router';
import { filter, Subscription } from 'rxjs';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-navigation',
  standalone: true,
  imports: [CommonModule, RouterModule],
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
            [routerLink]="'/home'"
            [class.active]="currentPage === 'home'"
            class="nav-link">
            <span class="nav-label">Accueil</span>
          </a>
          <a 
            (click)="scrollToFeatures()"
            class="nav-link">
            <span class="nav-label">Fonctionnalités</span>
          </a>
        </div>
        
        <div class="nav-actions">
          <ng-container *ngIf="isAuthenticated; else notAuthenticated">
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
          </ng-container>
          <ng-template #notAuthenticated>
            <button class="login-nav-btn" (click)="goToLogin()">
              <span>Se connecter</span>
            </button>
            <button class="register-nav-btn" (click)="goToRegister()">
              <span>S'inscrire</span>
            </button>
          </ng-template>
        </div>
      </div>
    </nav>
  `,
  styleUrls: ['./navigation.component.scss']
})
export class NavigationComponent implements OnInit, OnDestroy {
  currentPage = 'home';
  isAuthenticated = false;
  private authSubscription?: Subscription;
  
  navItems = [
    { id: 'home', label: 'Accueil', route: '/home', icon: 'home' }
  ];

  constructor(
    private router: Router,
    private authService: AuthService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    // S'abonner aux changements d'état d'authentification
    this.authSubscription = this.authService.isAuthenticated$.subscribe(
      (isAuth) => {
        this.isAuthenticated = isAuth;
        this.cdr.detectChanges();
      }
    );
    
    // Initialiser l'état d'authentification
    this.checkAuthStatus();
    
    this.router.events
      .pipe(filter(event => event instanceof NavigationEnd))
      .subscribe((event: any) => {
        const url = event.urlAfterRedirects;
        const item = this.navItems.find(nav => url.includes(nav.id));
        if (item) {
          this.currentPage = item.id;
        }
        // Vérifier l'état d'authentification à chaque changement de route
        this.checkAuthStatus();
      });
  }

  private checkAuthStatus(): void {
    // Vérifier directement dans le localStorage pour s'assurer de l'état réel
    const hasToken = !!localStorage.getItem('auth_token');
    const currentAuth = this.authService.isAuthenticated();
    
    // Utiliser l'état du service qui vérifie aussi l'observable
    this.isAuthenticated = currentAuth;
    
    // Forcer la détection de changement
    this.cdr.detectChanges();
  }

  ngOnDestroy(): void {
    if (this.authSubscription) {
      this.authSubscription.unsubscribe();
    }
  }

  logout(): void {
    this.authService.logout();
  }

  createEstablishment(): void {
    this.router.navigate(['/institution-choice']);
  }

  viewEstablishments(): void {
    this.router.navigate(['/establishments']);
  }

  goToLogin(): void {
    this.router.navigate(['/login']);
  }

  goToRegister(): void {
    this.router.navigate(['/register']);
  }

  scrollToFeatures(): void {
    // Si on est sur la page home, scroll vers la section
    if (this.router.url === '/home' || this.router.url.includes('/home')) {
      const featuresSection = document.querySelector('.features-section');
      if (featuresSection) {
        featuresSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    } else {
      // Sinon, naviguer vers home puis scroll
      this.router.navigate(['/home']).then(() => {
        setTimeout(() => {
          const featuresSection = document.querySelector('.features-section');
          if (featuresSection) {
            featuresSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
          }
        }, 100);
      });
    }
  }

  getIconSvg(iconName: string): string {
    const icons: { [key: string]: string } = {
      dashboard: '<path d="M3 3h8v8H3z"/><path d="M13 3h8v8h-8z"/><path d="M3 13h8v8H3z"/><path d="M13 13h8v8h-8z"/>',
      brain: '<path d="M9.5 2A2.5 2.5 0 0 0 7 4.5v15a2.5 2.5 0 0 0 2.5 2.5h5a2.5 2.5 0 0 0 2.5-2.5v-15A2.5 2.5 0 0 0 14.5 2h-5z"/><circle cx="12" cy="8" r="1.5"/><path d="M10 12h4M10 15h4"/>',
      bolt: '<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>',
      chart: '<line x1="18" y1="20" x2="18" y2="10"></line><line x1="12" y1="20" x2="12" y2="4"></line><line x1="6" y1="20" x2="6" y2="14"></line>',
      mobile: '<rect x="7" y="2" width="10" height="20" rx="2"/><line x1="11" y1="19" x2="13" y2="19"/>'
    };
    return icons[iconName] || icons['dashboard'];
  }
}
